import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'secure_token_store.dart';

class ApiClient {
  ApiClient._();

  static Dio createAuthorized(SecureTokenStore tokenStore) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiV1Base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }
}
