import 'package:dio/dio.dart';

class AttendanceApi {
  AttendanceApi(this._dio);

  final Dio _dio;

  Future<int> checkIn({required int shiftId, required double lat, required double lng}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/attendance/check-in',
      data: {'shiftId': shiftId, 'lat': lat, 'lng': lng},
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['sessionId']?.toString() ?? '') ?? 0;
  }

  Future<void> checkOut({required int sessionId, required double lat, required double lng}) async {
    await _dio.post<Map<String, dynamic>>(
      '/attendance/check-out',
      data: {'sessionId': sessionId, 'lat': lat, 'lng': lng},
    );
  }

  Future<List<Map<String, dynamic>>> listMySessions() async {
    final res = await _dio.get<Map<String, dynamic>>('/attendance/sessions');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
