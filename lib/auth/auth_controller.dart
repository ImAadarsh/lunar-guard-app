import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/user_profile.dart';
import '../services/auth_api.dart';
import '../services/biometric_auth_service.dart';
import '../services/secure_token_store.dart';
import '../services/users_api.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiV1Base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await _store.readAccessToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          return handler.next(options);
        },
      ),
    );
    _auth = AuthApi(_dio);
    _users = UsersApi(_dio);
  }

  final SecureTokenStore _store = SecureTokenStore();
  final BiometricAuthService _biometric = BiometricAuthService();
  late final Dio _dio;
  late final AuthApi _auth;
  late final UsersApi _users;

  UserProfile? profile;
  String? _access;
  String? _refresh;
  bool _busy = false;
  bool needsTwoFactor = false;
  String? preAuthToken;

  bool get isAuthenticated => _access != null && _access!.isNotEmpty;
  bool get busy => _busy;

  /// Device owner check gate (Face ID / Touch ID / fingerprint / device credential).
  /// Returns null when unlocked, otherwise an error/cancel message.
  Future<String?> requireBiometricUnlock() async {
    if (!isAuthenticated) return 'Please sign in first.';
    return _biometric.authenticateGate();
  }

  Future<void> init() async {
    await tryRestoreSession();
  }

  Future<void> tryRestoreSession() async {
    _access = await _store.readAccessToken();
    _refresh = await _store.readRefreshToken();
    final cache = await _store.readUserCache();
    if (cache != null) {
      try {
        profile = UserProfile.fromJson(Map<String, dynamic>.from(cache));
      } catch (_) {
        profile = null;
      }
    }
    if (!isAuthenticated) {
      profile = null;
      notifyListeners();
      return;
    }
    if (profile == null || profile!.id == 0) {
      await _store.clear();
      _access = null;
      _refresh = null;
      profile = null;
      notifyListeners();
      return;
    }
    await refreshProfile();
  }

  Future<String?> signInWithPassword(String email, String password) async {
    needsTwoFactor = false;
    preAuthToken = null;
    _busy = true;
    notifyListeners();
    try {
      final body = await _auth.login(email: email.trim(), password: password);
      final data = _unwrapData(body);
      if (data == null) return 'Unexpected response';

      if (data['requiresTwoFactor'] == true) {
        needsTwoFactor = true;
        preAuthToken = data['preAuthToken'] as String?;
        applyPreAuthUser(data);
        return null;
      }

      return await _persistLoginData(data);
    } on DioException catch (e) {
      return _dioErr(e);
    } catch (e) {
      return e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> completeTwoFactor(String totp) async {
    if (preAuthToken == null) return 'Missing pre-auth';
    _busy = true;
    notifyListeners();
    try {
      final body =
          await _auth.login2fa(preAuthToken: preAuthToken!, token: totp.trim());
      final data = _unwrapData(body);
      if (data == null) return 'Unexpected response';
      needsTwoFactor = false;
      preAuthToken = null;
      return await _persistLoginData(data);
    } on DioException catch (e) {
      return _dioErr(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> _persistLoginData(Map<String, dynamic> data) async {
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    final userRaw = data['user'];
    if (access == null || refresh == null || userRaw is! Map) {
      return 'Invalid login payload';
    }
    final userMap = Map<String, dynamic>.from(userRaw);
    _access = access;
    _refresh = refresh;
    await _store.saveSession(
      accessToken: access,
      refreshToken: refresh,
      user: userMap,
    );
    profile = UserProfile.fromJson(_normalizeUserJson(userMap));
    await refreshProfile();
    return null;
  }

  /// After 2FA pre-auth step the API returns `user` but no tokens yet — merge into profile for display.
  void applyPreAuthUser(Map<String, dynamic> data) {
    final userRaw = data['user'];
    if (userRaw is Map) {
      profile = UserProfile.fromJson(
          _normalizeUserJson(Map<String, dynamic>.from(userRaw)));
      notifyListeners();
    }
  }

  /// GET /users/:id — full profile (camelCase + snake_case tolerant).
  Future<void> refreshProfile() async {
    final id = profile?.id;
    if (id == null || id == 0) return;
    final at = _access ?? await _store.readAccessToken();
    final rt = _refresh ?? await _store.readRefreshToken();
    if (at == null || rt == null || at.isEmpty) return;
    try {
      final body = await _users.getUser(id);
      final data = _unwrapData(body);
      if (data is Map<String, dynamic>) {
        profile = UserProfile.fromJson(_normalizeUserJson(data));
        await _store.saveSession(accessToken: at, refreshToken: rt, user: data);
        notifyListeners();
      }
    } catch (_) {
      /* keep cached profile */
    }
  }

  void applyRefreshedTokens(String accessToken, String refreshToken) {
    _access = accessToken;
    _refresh = refreshToken;
    notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    _access = null;
    _refresh = null;
    profile = null;
    needsTwoFactor = false;
    preAuthToken = null;
    await _store.clear();
    notifyListeners();
  }

  Future<String?> signOut() async {
    _busy = true;
    notifyListeners();
    try {
      final rt = await _store.readRefreshToken();
      if (_access != null && _access!.isNotEmpty) {
        try {
          await _auth.logout(refreshToken: rt);
        } catch (_) {}
      }
    } finally {
      _access = null;
      _refresh = null;
      profile = null;
      needsTwoFactor = false;
      preAuthToken = null;
      await _store.clear();
      _busy = false;
      notifyListeners();
    }
    return null;
  }

  Map<String, dynamic>? _unwrapData(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  String _dioErr(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final m = data['error']['message'];
      if (m is String) return m;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach API. Check API_BASE_URL / Wi‑Fi / server.';
    }
    return e.message ?? 'Request failed';
  }

  Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> j) {
    final out = Map<String, dynamic>.from(j);
    const pairs = [
      ('created_at', 'createdAt'),
      ('two_factor_enabled', 'twoFactorEnabled'),
      ('pay_rate_pence_hour', 'payRatePenceHour'),
      ('full_name', 'fullName'),
      ('given_names', 'givenNames'),
      ('sia_type', 'siaType'),
      ('sia_number', 'siaNumber'),
      ('sia_expiry_date', 'siaExpiryDate'),
    ];
    for (final (snake, camel) in pairs) {
      if (out[snake] != null && out[camel] == null) {
        out[camel] = out[snake];
      }
    }
    return out;
  }
}
