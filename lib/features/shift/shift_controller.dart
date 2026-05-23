import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/attendance_session.dart';
import '../../models/guard_shift.dart';
import '../../services/api_client.dart';
import '../../services/attendance_api.dart';
import '../../services/secure_token_store.dart';
import '../../services/shifts_api.dart';
import '../../utils/geo_utils.dart';

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

  static const checkInGraceBefore = Duration(minutes: 15);

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

  bool isWithinShiftWindow(GuardShift shift) {
    final start = shift.startsAt;
    final end = shift.endsAt;
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final windowStart = start.subtract(checkInGraceBefore);
    return !now.isBefore(windowStart) && !now.isAfter(end);
  }

  GuardShift? get checkInEligibleShift {
    if (activeSession != null) return null;
    final sorted = [...shifts]..sort((a, b) {
        final aa = a.startsAt?.millisecondsSinceEpoch ?? 0;
        final bb = b.startsAt?.millisecondsSinceEpoch ?? 0;
        return aa.compareTo(bb);
      });
    for (final shift in sorted) {
      if (shift.status == 'completed' || shift.status == 'cancelled') continue;
      if (isWithinShiftWindow(shift)) return shift;
    }
    return null;
  }

  GuardShift? shiftById(int? id) {
    if (id == null) return null;
    try {
      return shifts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  GuardShift? get attendanceShift {
    final session = activeSession;
    if (session != null) {
      return shiftById(session.shiftId);
    }
    return checkInEligibleShift;
  }

  Map<String, dynamic>? siteFor(int siteId) => siteGeometry[siteId];

  ({double lat, double lng})? siteLatLng(int siteId) {
    final site = siteFor(siteId);
    if (site == null) return null;
    final lat = double.tryParse(site['centerLat']?.toString() ?? '');
    final lng = double.tryParse(site['centerLng']?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
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
      final siteIds = shifts.map((s) => s.siteId).where((id) => id > 0).toSet();
      for (final siteId in siteIds) {
        if (siteGeometry.containsKey(siteId)) continue;
        try {
          final site = await _shiftsApi.getSite(siteId);
          siteGeometry[siteId] = site;
        } catch (_) {}
      }
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool canCheckInAt(GuardShift shift, double lat, double lng) {
    final site = siteGeometry[shift.siteId];
    if (site == null) return false;
    return isInsideGeofence(site, lat, lng);
  }

  String? checkInBlockedReason(GuardShift shift, double lat, double lng) {
    if (!isWithinShiftWindow(shift)) {
      return 'Check-in opens 15 minutes before shift start and closes when the shift ends.';
    }
    final site = siteGeometry[shift.siteId];
    if (site == null) {
      return 'Site geofence not loaded yet. Pull to refresh and try again.';
    }
    if (canCheckInAt(shift, lat, lng)) return null;
    return 'You must be inside the site geofence to check in.';
  }

  Future<String?> checkIn({required double lat, required double lng}) async {
    final shift = checkInEligibleShift;
    if (shift == null) {
      return 'No shift in your check-in window right now.';
    }
    final blocked = checkInBlockedReason(shift, lat, lng);
    if (blocked != null) return blocked;
    try {
      await _attendanceApi.checkIn(shiftId: shift.id, lat: lat, lng: lng);
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  String geofenceHintFor(GuardShift shift, {double? lat, double? lng}) {
    if (!isWithinShiftWindow(shift)) {
      return 'Check-in for ${shift.siteLabel} opens 15 minutes before ${shift.startsAt?.toLocal().toString().substring(11, 16) ?? 'start'}.';
    }
    final site = siteGeometry[shift.siteId];
    if (site == null) {
      return 'Loading site geofence… pull to refresh if this persists.';
    }
    if (lat == null || lng == null) {
      final hasPolygon = site['geofencePolygon'] != null;
      if (hasPolygon) {
        return 'Site uses a polygon geofence. Use “Preview geofence” before check-in.';
      }
      final radius = double.tryParse(site['geofenceRadiusM']?.toString() ?? '');
      return radius == null
          ? 'No geofence configured for this site.'
          : 'Circular geofence: ${radius.round()}m from site center.';
    }
    if (canCheckInAt(shift, lat, lng)) {
      return 'Inside site geofence — you can check in.';
    }
    final centerLat = double.tryParse(site['centerLat']?.toString() ?? '');
    final centerLng = double.tryParse(site['centerLng']?.toString() ?? '');
    final radius = double.tryParse(site['geofenceRadiusM']?.toString() ?? '');
    if (centerLat != null && centerLng != null && radius != null) {
      final meters = distanceMeters(lat, lng, centerLat, centerLng);
      return 'Outside site geofence (${meters.round()}m from center, limit ${radius.round()}m).';
    }
    return 'Outside site geofence — move onto the site to check in.';
  }

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
