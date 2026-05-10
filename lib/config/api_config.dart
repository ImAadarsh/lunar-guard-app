import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend base URL **without** trailing slash.
/// Override at build/run time: `--dart-define=API_BASE_URL=http://192.168.1.10:4000`
/// - Android **emulator**: defaults to `http://10.0.2.2:4000` (host machine loopback).
/// - iOS simulator / desktop: `http://127.0.0.1:4000`.
/// - **Physical device**: use your computer's LAN IP, e.g. `http://192.168.1.10:4000`.
class ApiConfig {
  ApiConfig._();

  static const String _defineKey = 'API_BASE_URL';
  static const String _mapsKeyDefine = 'GOOGLE_MAPS_API_KEY';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment(_defineKey, defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/$'), '');
    if (kIsWeb) return 'http://127.0.0.1:4000';
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://127.0.0.1:4000';
  }

  static String get apiV1Base => '$baseUrl/api/v1';

  /// Inject with `--dart-define=GOOGLE_MAPS_API_KEY=...`
  static String get googleMapsApiKey =>
      const String.fromEnvironment(_mapsKeyDefine, defaultValue: '');
}
