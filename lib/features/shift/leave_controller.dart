import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/leave_request.dart';
import '../../services/api_client.dart';
import '../../services/leave_requests_api.dart';
import '../../services/secure_token_store.dart';

class LeaveController extends ChangeNotifier {
  LeaveController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    _api = LeaveRequestsApi(ApiClient.createAuthorized(_tokenStore));
  }

  final SecureTokenStore _tokenStore;
  late final LeaveRequestsApi _api;

  bool loading = false;
  String? error;
  List<LeaveRequest> requests = const [];

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.listMine(limit: 50);
      requests = rows.map(LeaveRequest.fromJson).toList();
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> submit({
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      await _api.create(
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['error'] is Map &&
        data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Request failed';
  }
}
