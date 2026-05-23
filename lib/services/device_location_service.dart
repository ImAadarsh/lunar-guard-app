import 'package:geolocator/geolocator.dart';

import '../models/device_position.dart';

class DeviceLocationService {
  Future<DevicePosition> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    return DevicePosition(
      lat: pos.latitude,
      lng: pos.longitude,
      accuracyM: pos.accuracy >= 0 ? pos.accuracy : null,
    );
  }

  Future<({double lat, double lng})> getCurrentLatLng() async {
    final p = await getCurrentPosition();
    return (lat: p.lat, lng: p.lng);
  }
}
