import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'auth_api.dart';
import 'secure_token_store.dart';

typedef TokenRefreshCallback = void Function(
    String accessToken, String refreshToken);
typedef SessionExpiredCallback = Future<void> Function();

class ApiClient {
  ApiClient._();

  static TokenRefreshCallback? onTokensRefreshed;
  static SessionExpiredCallback? onSessionExpired;

  static final _RefreshLock _refreshLock = _RefreshLock();

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
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }
          final path = error.requestOptions.path;
          if (path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/logout')) {
            return handler.next(error);
          }
          if (error.requestOptions.extra['retriedAfterRefresh'] == true) {
            await onSessionExpired?.call();
            return handler.next(error);
          }

          final refreshed = await _refreshLock.run(() async {
            return _tryRefreshTokens(tokenStore);
          });
          if (!refreshed) {
            await onSessionExpired?.call();
            return handler.next(error);
          }

          final access = await tokenStore.readAccessToken();
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $access';
          opts.extra['retriedAfterRefresh'] = true;
          try {
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        },
      ),
    );
    return dio;
  }

  static Future<bool> _tryRefreshTokens(SecureTokenStore tokenStore) async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiV1Base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    try {
      final body =
          await AuthApi(refreshDio).refresh(refreshToken: refreshToken);
      final data = body['data'];
      if (data is! Map) return false;
      final access = data['accessToken']?.toString();
      final nextRefresh = data['refreshToken']?.toString();
      if (access == null ||
          access.isEmpty ||
          nextRefresh == null ||
          nextRefresh.isEmpty) {
        return false;
      }
      await tokenStore.updateTokens(
        accessToken: access,
        refreshToken: nextRefresh,
      );
      onTokensRefreshed?.call(access, nextRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _RefreshLock {
  bool _busy = false;
  Completer<void>? _waiter;

  Future<T> run<T>(Future<T> Function() action) async {
    while (_busy) {
      await _waiter?.future;
    }
    _busy = true;
    _waiter = Completer<void>();
    try {
      return await action();
    } finally {
      _busy = false;
      _waiter?.complete();
      _waiter = null;
    }
  }
}
