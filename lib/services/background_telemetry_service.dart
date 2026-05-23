import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Keeps GPS updates flowing during an active shift (foreground + background).
class BackgroundTelemetryService {
  BackgroundTelemetryService._();
  static final BackgroundTelemetryService instance = BackgroundTelemetryService._();

  static const _channel =
      MethodChannel('com.example.lunar_security_guard/location_service');

  StreamSubscription<Position>? _subscription;
  void Function(double lat, double lng, String recordedAt)? _onPosition;

  bool get isTracking => _subscription != null;

  Future<bool> ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }
    if (!kIsWeb && Platform.isAndroid) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
      }
    }
    return true;
  }

  Future<void> start({
    required void Function(double lat, double lng, String recordedAt) onPosition,
  }) async {
    await stop();
    await ensurePermissions();
    _onPosition = onPosition;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('start');
      } catch (_) {}
    }

    final settings = _locationSettings();
    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        final recordedAt = DateTime.now().toUtc().toIso8601String();
        _onPosition?.call(pos.latitude, pos.longitude, recordedAt);
      },
      onError: (_) {},
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _onPosition = null;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('stop');
      } catch (_) {}
    }
  }

  LocationSettings _locationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Lunar Security',
          notificationText: 'Location tracking is active during your shift.',
          notificationChannelName: 'Lunar Security location',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 25,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }
}
