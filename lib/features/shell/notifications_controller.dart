import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';
import '../../services/api_client.dart';
import '../../services/notifications_api.dart';
import '../../services/secure_token_store.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    _api = NotificationsApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  late final NotificationsApi _api;

  List<AppNotification> items = const [];
  int unreadCount = 0;
  String? error;
  Timer? _poller;

  Future<void> refresh() async {
    try {
      final rows = await _api.list(limit: 30, unreadOnly: false);
      items = rows.map(AppNotification.fromJson).toList();
      unreadCount = await _api.unreadCount();
      error = null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map &&
          data['error'] is Map &&
          data['error']['message'] is String) {
        error = data['error']['message'] as String;
      } else {
        error = e.message ?? 'Failed loading notifications';
      }
    }
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    await _api.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _api.markAllRead();
    await refresh();
  }

  void startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh();
    });
    refresh();
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
