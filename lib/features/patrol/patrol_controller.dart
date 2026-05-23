import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/patrol_scan.dart';
import '../../services/api_client.dart';
import '../../services/offline_queue_service.dart';
import '../../models/device_position.dart';
import '../../services/patrol_api.dart';
import '../../services/secure_token_store.dart';
import '../../utils/checkpoint_qr.dart';
import '../../utils/geo_utils.dart';

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

  Map<String, dynamic>? checkpointFromSchedule(int checkpointId) {
    for (final item in schedule) {
      final id = item['checkpointId'];
      if (id == checkpointId || id.toString() == checkpointId.toString()) {
        return item;
      }
    }
    return null;
  }

  String? validateScanLocation(
    int checkpointId,
    DevicePosition position,
  ) {
    final item = checkpointFromSchedule(checkpointId);
    if (item == null) return null;
    final cpLat = double.tryParse(item['lat']?.toString() ?? '');
    final cpLng = double.tryParse(item['lng']?.toString() ?? '');
    if (cpLat == null || cpLng == null) return null;
    return validateCheckpointScan(
      lat: position.lat,
      lng: position.lng,
      checkpointLat: cpLat,
      checkpointLng: cpLng,
      accuracyM: position.accuracyM,
    );
  }

  Future<String?> submitQrCode(
    String raw, {
    required DevicePosition position,
  }) async {
    final checkpointId = parseCheckpointQr(raw);
    if (checkpointId == null) {
      return 'Could not read checkpoint from QR code.';
    }
    return submitCheckpointId(checkpointId, position: position);
  }

  Future<String?> submitCheckpointId(
    int checkpointId, {
    required DevicePosition position,
  }) async {
    final locationErr = validateScanLocation(checkpointId, position);
    if (locationErr != null) return locationErr;

    final scannedAt = DateTime.now().toUtc();
    final clientMessageId =
        '${DateTime.now().millisecondsSinceEpoch}-$checkpointId';
    try {
      await _api.submitScan(
        checkpointId: checkpointId,
        scannedAt: scannedAt,
        lat: position.lat,
        lng: position.lng,
        accuracyM: position.accuracyM,
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
            'lat': position.lat,
            'lng': position.lng,
            if (position.accuracyM != null) 'accuracyM': position.accuracyM,
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
