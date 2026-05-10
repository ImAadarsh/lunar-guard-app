import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/attendance_api.dart';
import '../../services/device_location_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/secure_token_store.dart';

class TelemetryController extends ChangeNotifier {
  TelemetryController({
    SecureTokenStore? tokenStore,
    DeviceLocationService? location,
    OfflineQueueService? queue,
  })  : _tokenStore = tokenStore ?? SecureTokenStore(),
        _location = location ?? DeviceLocationService(),
        _queue = queue ?? OfflineQueueService() {
    _api = AttendanceApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  final DeviceLocationService _location;
  final OfflineQueueService _queue;
  late final AttendanceApi _api;

  Timer? _timer;
  int? activeShiftId;
  DateTime? lastSentAt;
  String? error;
  bool sending = false;

  bool get running => _timer != null;

  void updateActiveShift(int? shiftId) {
    if (shiftId == activeShiftId && running == (shiftId != null)) return;
    activeShiftId = shiftId;
    if (shiftId == null) {
      stop();
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => sendNow());
    sendNow();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    activeShiftId = null;
    notifyListeners();
  }

  Future<void> sendNow() async {
    final shiftId = activeShiftId;
    if (shiftId == null || sending) return;
    sending = true;
    error = null;
    notifyListeners();
    final recordedAt = DateTime.now().toUtc().toIso8601String();
    try {
      final point = await _location.getCurrentLatLng();
      final points = [
        {'lat': point.lat, 'lng': point.lng, 'recordedAt': recordedAt},
      ];
      final payload = {
        'shiftId': shiftId,
        'points': points,
      };
      try {
        await _api.submitGpsTelemetry(shiftId: shiftId, points: points);
        lastSentAt = DateTime.now();
      } on DioException catch (e) {
        await _queue.enqueue(type: 'telemetry_gps', payload: payload);
        error = e.message ?? 'Telemetry queued for retry';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
