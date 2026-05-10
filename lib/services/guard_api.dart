import 'package:dio/dio.dart';

class GuardApi {
  GuardApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get<Map<String, dynamic>>('/guard/summary');
    final data = (res.data?['data'] as Map?) ?? {};
    return Map<String, dynamic>.from(data);
  }
}
