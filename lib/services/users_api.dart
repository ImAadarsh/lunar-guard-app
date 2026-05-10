import 'package:dio/dio.dart';

class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getUser(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/users/$id');
    return res.data ?? {};
  }
}
