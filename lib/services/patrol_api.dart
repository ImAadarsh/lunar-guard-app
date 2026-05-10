import 'package:dio/dio.dart';

class PatrolApi {
  PatrolApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> submitScan({
    required int checkpointId,
    required DateTime scannedAt,
    String? clientMessageId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/patrols/scans',
      data: {
        'checkpointId': checkpointId,
        'scannedAt': scannedAt.toIso8601String(),
        if (clientMessageId != null && clientMessageId.isNotEmpty)
          'clientMessageId': clientMessageId,
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listScans({int limit = 50}) async {
    final res = await _dio.get<Map<String, dynamic>>('/patrols/scans',
        queryParameters: {'limit': limit});
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> patrolSchedule() async {
    final res = await _dio.get<Map<String, dynamic>>('/patrols/schedule');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
