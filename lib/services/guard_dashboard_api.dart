import 'package:dio/dio.dart';

class GuardDashboardApi {
  GuardDashboardApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchTrainedSites(int userId) async {
    final res = await _dio.get<Map<String, dynamic>>('/dashboard/guards/$userId');
    final data = (res.data?['data'] as Map?) ?? {};
    final items = data['trainedSites'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
