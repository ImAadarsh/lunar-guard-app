import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/patrol_scan.dart';
import '../../services/api_client.dart';
import '../../services/offline_queue_service.dart';
import '../../services/patrol_api.dart';
import '../../services/secure_token_store.dart';

class PatrolController extends ChangeNotifier {
  PatrolController({SecureTokenStore? tokenStore, OfflineQueueService? queue})
      : _tokenStore = tokenStore ?? SecureTokenStore(),
        _queue = queue ?? OfflineQueueService() {
    _api = PatrolApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  final OfflineQueueService _queue;
  late final PatrolApi _api;

  bool loading = false;
  String? error;
  List<PatrolScan> scans = const [];
  List<Map<String, dynamic>> schedule = const [];

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.listScans(limit: 50);
      scans = rows.map(PatrolScan.fromJson).toList();
      schedule = await _api.patrolSchedule();
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> submitCheckpointId(int checkpointId) async {
    final scannedAt = DateTime.now().toUtc();
    final clientMessageId =
        '${DateTime.now().millisecondsSinceEpoch}-$checkpointId';
    try {
      await _api.submitScan(
        checkpointId: checkpointId,
        scannedAt: scannedAt,
        clientMessageId: clientMessageId,
      );
      await refresh();
      return null;
    } on DioException catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(
          type: 'patrol_scan',
          payload: {
            'checkpointId': checkpointId,
            'scannedAt': scannedAt.toIso8601String(),
            'clientMessageId': clientMessageId,
          },
        );
        return 'Patrol scan queued. It will sync when connectivity returns.';
      }
      return _err(e);
    }
  }

  List<Map<String, String>> patrolSchedule() {
    if (schedule.isEmpty) {
      return const [
        {
          'label': 'No active patrol route',
          'due': '-',
          'status': 'Start a shift to load backend route',
        }
      ];
    }
    return schedule.map((item) {
      final dueAt = DateTime.tryParse(item['dueAt']?.toString() ?? '');
      return {
        'label': item['label']?.toString() ?? 'Checkpoint',
        'due': dueAt == null
            ? '-'
            : '${dueAt.toLocal().hour.toString().padLeft(2, '0')}:${dueAt.toLocal().minute.toString().padLeft(2, '0')}',
        'status': item['status']?.toString() ?? 'due',
      };
    }).toList();
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['error'] is Map &&
        data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Request failed';
  }

  bool _isOffline(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.response == null;
  }
}
