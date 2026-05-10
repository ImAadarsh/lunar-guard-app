import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/attendance_session.dart';
import '../../models/guard_shift.dart';
import '../../services/api_client.dart';
import '../../services/attendance_api.dart';
import '../../services/secure_token_store.dart';
import '../../services/shifts_api.dart';

class ShiftController extends ChangeNotifier {
  ShiftController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    final dio = ApiClient.createAuthorized(_tokenStore);
    _shiftsApi = ShiftsApi(dio);
    _attendanceApi = AttendanceApi(dio);
  }

  final SecureTokenStore _tokenStore;
  late final ShiftsApi _shiftsApi;
  late final AttendanceApi _attendanceApi;

  bool loading = false;
  String? error;
  List<GuardShift> shifts = const [];
  List<AttendanceSession> sessions = const [];
  final Map<int, Map<String, dynamic>> siteGeometry = {};

  AttendanceSession? get activeSession {
    try {
      return sessions.firstWhere((s) => s.isOpen);
    } catch (_) {
      return null;
    }
  }

  GuardShift? get nextShift {
    final now = DateTime.now();
    final sorted = [...shifts]..sort((a, b) {
        final aa = a.startsAt?.millisecondsSinceEpoch ?? 0;
        final bb = b.startsAt?.millisecondsSinceEpoch ?? 0;
        return aa.compareTo(bb);
      });
    for (final s in sorted) {
      final endsAt = s.endsAt;
      if (endsAt == null || endsAt.isAfter(now)) return s;
    }
    return sorted.isEmpty ? null : sorted.first;
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final shiftRows = await _shiftsApi.listMyShifts();
      final sessionRows = await _attendanceApi.listMySessions();
      shifts = shiftRows.map(GuardShift.fromJson).toList();
      sessions = sessionRows.map(AttendanceSession.fromJson).toList();
      for (final shift in shifts.take(5)) {
        if (!siteGeometry.containsKey(shift.siteId) && shift.siteId > 0) {
          try {
            final site = await _shiftsApi.getSite(shift.siteId);
            siteGeometry[shift.siteId] = site;
          } catch (_) {}
        }
      }
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> checkIn({required double lat, required double lng}) async {
    final shift = nextShift;
    if (shift == null) return 'No upcoming shift found.';
    try {
      await _attendanceApi.checkIn(shiftId: shift.id, lat: lat, lng: lng);
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  String geofenceHintFor(GuardShift shift, {double? lat, double? lng}) {
    final site = siteGeometry[shift.siteId];
    if (site == null) return 'Site geofence will be validated by the backend.';
    final centerLat = double.tryParse(site['centerLat']?.toString() ?? '');
    final centerLng = double.tryParse(site['centerLng']?.toString() ?? '');
    final radius = double.tryParse(site['geofenceRadiusM']?.toString() ?? '');
    if (centerLat == null || centerLng == null || radius == null) {
      return 'Polygon geofence configured. Backend will validate precise boundary.';
    }
    if (lat == null || lng == null) {
      return 'Geofence radius ${radius.round()}m around $centerLat, $centerLng.';
    }
    final meters = _distanceMeters(lat, lng, centerLat, centerLng);
    return meters <= radius
        ? 'You appear inside the site geofence (${meters.round()}m from center).'
        : 'You appear outside the site geofence (${meters.round()}m from center, radius ${radius.round()}m).';
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const earth = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180;

  Future<String?> checkOut({required double lat, required double lng}) async {
    final session = activeSession;
    if (session == null) return 'No open attendance session.';
    try {
      await _attendanceApi.checkOut(sessionId: session.id, lat: lat, lng: lng);
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
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
}
