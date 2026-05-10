import 'package:dio/dio.dart';

/// Maps `/auth/*` endpoints.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> login2fa({
    required String preAuthToken,
    required String token,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login/2fa',
      data: {'preAuthToken': preAuthToken, 'token': token},
    );
    return res.data ?? {};
  }

  Future<void> logout({String? refreshToken}) async {
    await _dio.post<void>(
      '/auth/logout',
      data: refreshToken != null ? {'refreshToken': refreshToken} : {},
    );
  }
}
