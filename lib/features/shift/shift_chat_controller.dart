import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/shift_chat_message.dart';
import '../../models/shift_chat_thread.dart';
import '../../services/api_client.dart';
import '../../services/device_location_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/secure_token_store.dart';
import '../../services/shift_chat_api.dart';

class ShiftChatController extends ChangeNotifier {
  ShiftChatController({
    SecureTokenStore? tokenStore,
    DeviceLocationService? location,
    OfflineQueueService? queue,
  })  : _tokenStore = tokenStore ?? SecureTokenStore(),
        _location = location ?? DeviceLocationService(),
        _queue = queue ?? OfflineQueueService() {
    _api = ShiftChatApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  final DeviceLocationService _location;
  final OfflineQueueService _queue;
  late final ShiftChatApi _api;

  int? _shiftId;
  int? _currentUserId;
  ShiftChatThread? thread;
  List<ShiftChatMessage> messages = const [];
  bool loading = false;
  bool sending = false;
  String? error;
  Timer? _poller;
  bool _visible = false;

  int? get shiftId => _shiftId;

  void setCurrentUserId(int? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    notifyListeners();
  }

  bool isOwnMessage(ShiftChatMessage message) =>
      _currentUserId != null && message.senderUserId == _currentUserId;

  Future<void> bindShift(int? shiftId) async {
    if (_shiftId == shiftId) return;
    _shiftId = shiftId;
    stopPolling();
    thread = null;
    messages = const [];
    error = null;
    notifyListeners();
    if (shiftId == null) return;
    await loadThread();
  }

  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (visible) {
      unawaited(_onBecameVisible());
    } else {
      stopPolling();
    }
  }

  Future<void> _onBecameVisible() async {
    if (_shiftId == null) return;
    if (thread == null) {
      await loadThread();
    } else {
      await _pollMessages();
      await _markReadIfNeeded();
    }
    _syncPolling();
  }

  Future<void> loadThread() async {
    final shiftId = _shiftId;
    if (shiftId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.listThreads();
      ShiftChatThread? match;
      for (final row in rows) {
        final t = ShiftChatThread.fromJson(row);
        if (t.shiftId == shiftId) {
          match = t;
          break;
        }
      }
      thread = match;
      if (match != null) {
        await _loadAllMessages(match.id);
        if (_visible) {
          await _markReadIfNeeded();
        }
      }
      error = null;
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
      _syncPolling();
    }
  }

  Future<void> _loadAllMessages(int chatId) async {
    try {
      final rows = await _api.listMessages(chatId);
      messages = rows.map(ShiftChatMessage.fromJson).toList()
        ..sort((a, b) {
          final aa = a.createdAt?.millisecondsSinceEpoch ?? a.id;
          final bb = b.createdAt?.millisecondsSinceEpoch ?? b.id;
          return aa.compareTo(bb);
        });
    } on DioException catch (e) {
      error = _err(e);
    }
  }

  Future<void> refresh() async {
    await loadThread();
  }

  void _syncPolling() {
    if (!_visible || thread == null || !thread!.isActive) {
      stopPolling();
      return;
    }
    startPolling();
  }

  void startPolling() {
    if (thread == null || !thread!.isActive) return;
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_pollMessages());
    });
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _pollMessages() async {
    final t = thread;
    if (t == null) return;
    try {
      final sinceId = messages.isEmpty
          ? null
          : messages
              .where((m) => !m.pending && m.id > 0)
              .map((m) => m.id)
              .fold<int?>(null, (prev, id) => prev == null || id > prev ? id : prev);
      final rows = await _api.listMessages(t.id, sinceId: sinceId);
      if (rows.isEmpty) return;
      final incoming = rows.map(ShiftChatMessage.fromJson).toList();
      final existingIds = messages.map((m) => m.id).toSet();
      var changed = false;
      for (final msg in incoming) {
        if (existingIds.contains(msg.id)) continue;
        messages = [...messages, msg];
        changed = true;
      }
      if (changed) {
        messages = [...messages]..sort((a, b) {
            final aa = a.createdAt?.millisecondsSinceEpoch ?? a.id;
            final bb = b.createdAt?.millisecondsSinceEpoch ?? b.id;
            return aa.compareTo(bb);
          });
        if (_visible) {
          await _markReadIfNeeded();
        }
        notifyListeners();
      }
    } on DioException catch (e) {
      if (_visible) {
        error = _err(e);
        notifyListeners();
      }
    }
  }

  Future<void> _markReadIfNeeded() async {
    final t = thread;
    if (t == null || t.unreadCount <= 0) return;
    try {
      await _api.markRead(t.id);
      thread = ShiftChatThread(
        id: t.id,
        shiftId: t.shiftId,
        siteId: t.siteId,
        siteName: t.siteName,
        status: t.status,
        unreadCount: 0,
        lastMessageAt: t.lastMessageAt,
        lastMessagePreview: t.lastMessagePreview,
      );
      notifyListeners();
    } on DioException catch (_) {}
  }

  Future<String?> sendMessage(String body) async {
    final text = body.trim();
    if (text.isEmpty) return 'Message cannot be empty.';
    final t = thread;
    if (t == null) return 'Shift chat is not available yet.';
    if (!t.isActive) return 'Chat is read-only for this shift.';
    if (sending) return 'Please wait…';

    sending = true;
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ShiftChatMessage(
      id: tempId,
      senderUserId: _currentUserId ?? 0,
      messageType: 'text',
      body: text,
      createdAt: DateTime.now(),
      senderName: 'You',
      pending: true,
    );
    messages = [...messages, optimistic];
    notifyListeners();

    try {
      final row = await _api.sendMessage(chatId: t.id, body: text);
      final sent = row.isNotEmpty
          ? ShiftChatMessage.fromJson(row)
          : optimistic.copyWith(pending: false, id: tempId.abs());
      messages = [
        for (final m in messages)
          if (m.id == tempId) sent else m,
      ];
      error = null;
      return null;
    } on DioException catch (e) {
      messages = messages.where((m) => m.id != tempId).toList();
      if (_isOffline(e)) {
        await _queue.enqueue(
          type: 'shift_chat_message',
          payload: {'chatId': t.id, 'body': text},
        );
        notifyListeners();
        return 'Message queued. It will send when connectivity returns.';
      }
      error = _err(e);
      notifyListeners();
      return _err(e);
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<String?> sendPing({String? body}) async {
    final t = thread;
    if (t == null) return 'Shift chat is not available yet.';
    if (!t.isActive) return 'Pings are only available during an active shift.';
    if (sending) return 'Please wait…';

    sending = true;
    notifyListeners();
    try {
      final pos = await _location.getCurrentPosition();
      final row = await _api.sendPing(
        chatId: t.id,
        lat: pos.lat,
        lng: pos.lng,
        body: body,
      );
      if (row.isNotEmpty) {
        final msg = ShiftChatMessage.fromJson(row);
        if (!messages.any((m) => m.id == msg.id)) {
          messages = [...messages, msg];
        }
      } else {
        await _pollMessages();
      }
      error = null;
      return null;
    } on DioException catch (e) {
      error = _err(e);
      return _err(e);
    } catch (e) {
      return e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map &&
          nested['error'] is Map &&
          nested['error']['message'] is String) {
        return nested['error']['message'] as String;
      }
      if (data['error'] is Map && data['error']['message'] is String) {
        return data['error']['message'] as String;
      }
    }
    return e.message ?? 'Request failed';
  }

  bool _isOffline(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.response == null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
