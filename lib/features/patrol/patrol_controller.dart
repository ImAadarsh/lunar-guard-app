import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/patrol_scan.dart';
import '../../services/api_client.dart';
import '../../services/patrol_api.dart';
import '../../services/secure_token_store.dart';

class PatrolController extends ChangeNotifier {
  PatrolController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    _api = PatrolApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  late final PatrolApi _api;

  bool loading = false;
  String? error;
  List<PatrolScan> scans = const [];

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.listScans(limit: 50);
      scans = rows.map(PatrolScan.fromJson).toList();
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> submitCheckpointId(int checkpointId) async {
    try {
      await _api.submitScan(
        checkpointId: checkpointId,
        scannedAt: DateTime.now().toUtc(),
        clientMessageId: '${DateTime.now().millisecondsSinceEpoch}-$checkpointId',
      );
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
