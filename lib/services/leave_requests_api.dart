import 'package:dio/dio.dart';

class LeaveRequestsApi {
  LeaveRequestsApi(this._dio);

  final Dio _dio;

  Future<int> create({
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/leave-requests',
      data: {
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> listMine({int limit = 50}) async {
    final res = await _dio.get<Map<String, dynamic>>('/leave-requests',
        queryParameters: {'limit': limit});
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
