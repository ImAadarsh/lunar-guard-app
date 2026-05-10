import 'package:dio/dio.dart';

class ShiftsApi {
  ShiftsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listMyShifts() async {
    final res = await _dio.get<Map<String, dynamic>>('/shifts');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
