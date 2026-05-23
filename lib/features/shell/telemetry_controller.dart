import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/attendance_api.dart';
import '../../services/background_telemetry_service.dart';
import '../../services/device_location_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/secure_token_store.dart';

class TelemetryController extends ChangeNotifier {
  TelemetryController({
    SecureTokenStore? tokenStore,
    DeviceLocationService? location,
    OfflineQueueService? queue,
    BackgroundTelemetryService? background,
  })  : _tokenStore = tokenStore ?? SecureTokenStore(),
        _location = location ?? DeviceLocationService(),
        _queue = queue ?? OfflineQueueService(),
        _background = background ?? BackgroundTelemetryService.instance {
    _api = AttendanceApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  final DeviceLocationService _location;
  final OfflineQueueService _queue;
  final BackgroundTelemetryService _background;
  late final AttendanceApi _api;

  Timer? _timer;
  int? activeShiftId;
  DateTime? lastSentAt;
  String? error;
  bool sending = false;

  bool get running => activeShiftId != null && (_timer != null || _background.isTracking);

  void updateActiveShift(int? shiftId) {
    if (shiftId == activeShiftId && (shiftId == null || _timer != null)) return;
    activeShiftId = shiftId;
    if (shiftId == null) {
      _stopTracking();
      return;
    }
    _startTracking(shiftId);
    notifyListeners();
  }

  void stop() {
    activeShiftId = null;
    _stopTracking();
    notifyListeners();
  }

  Future<void> _startTracking(int shiftId) async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => sendNow());
    try {
      await _background.start(
        onPosition: (lat, lng, recordedAt) {
          unawaited(_submitPoints(shiftId, [
            {'lat': lat, 'lng': lng, 'recordedAt': recordedAt},
          ]));
        },
      );
    } catch (e) {
      error = e.toString();
    }
    unawaited(sendNow());
    notifyListeners();
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _timer = null;
    await _background.stop();
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
      await _submitPoints(shiftId, [
        {'lat': point.lat, 'lng': point.lng, 'recordedAt': recordedAt},
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> _submitPoints(
    int shiftId,
    List<Map<String, dynamic>> points,
  ) async {
    if (points.isEmpty) return;
    final payload = {'shiftId': shiftId, 'points': points};
    try {
      await _api.submitGpsTelemetry(shiftId: shiftId, points: points);
      lastSentAt = DateTime.now();
      error = null;
    } on DioException catch (e) {
      await _queue.enqueue(type: 'telemetry_gps', payload: payload);
      error = e.message ?? 'Telemetry queued for retry';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_background.stop());
    super.dispose();
  }
}
