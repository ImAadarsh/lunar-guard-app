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
    if (data is Map && data['error'] is Map && data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Request failed';
  }
}
