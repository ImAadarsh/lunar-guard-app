import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/guard_summary.dart';
import '../../services/api_client.dart';
import '../../services/guard_api.dart';
import '../../services/secure_token_store.dart';

class HomeController extends ChangeNotifier {
  HomeController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    _api = GuardApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  late final GuardApi _api;

  bool loading = false;
  String? error;
  GuardSummary summary = const GuardSummary(patrolScansLast24h: 0, openIncidentCount: 0);

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      summary = GuardSummary.fromJson(await _api.getSummary());
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map && data['error']['message'] is String) {
        error = data['error']['message'] as String;
      } else {
        error = e.message ?? 'Failed to load summary';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
