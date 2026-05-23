import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../services/offline_queue_service.dart';

export '../../services/offline_queue_service.dart' show OfflineQueueItem;

class OfflineQueueController extends ChangeNotifier {
  OfflineQueueController({OfflineQueueService? queue})
      : _queue = queue ?? OfflineQueueService() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) => _onConnectivityChanged(results));
  }

  final OfflineQueueService _queue;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  int _retrySeconds = 5;

  bool syncing = false;
  String? error;
  int pending = 0;
  List<OfflineQueueItem> items = const [];
  DateTime? lastSyncedAt;
  final List<String> history = <String>[];

  Future<void> refresh() async {
    pending = await _queue.pendingCount();
    items = await _queue.pendingItems();
    notifyListeners();
  }

  Future<int> flush() async {
    syncing = true;
    error = null;
    notifyListeners();
    try {
      final synced = await _queue.flush();
      pending = await _queue.pendingCount();
      items = await _queue.pendingItems();
      lastSyncedAt = DateTime.now();
      if (synced > 0) {
        _retrySeconds = 5;
        _addHistory('Synced $synced queued action(s).');
      }
      return synced;
    } catch (e) {
      error = e.toString();
      _addHistory('Sync failed: $error');
      _scheduleRetry();
      return 0;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return;
    await refresh();
    if (pending > 0 && !syncing) {
      _addHistory('Connectivity returned. Starting sync.');
      await flush();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retrySeconds), () {
      if (!syncing) flush();
    });
    _retrySeconds = (_retrySeconds * 2).clamp(5, 300);
  }

  void _addHistory(String entry) {
    history.insert(0, '${DateTime.now().toLocal().toIso8601String().substring(11, 19)}  $entry');
    if (history.length > 20) history.removeRange(20, history.length);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
