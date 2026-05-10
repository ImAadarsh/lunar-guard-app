import 'package:dio/dio.dart';

class IncidentsApi {
  IncidentsApi(this._dio);

  final Dio _dio;

  Future<int> createIncident({
    required int siteId,
    required String category,
    required String title,
    String? description,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/incidents',
      data: {
        'siteId': siteId,
        'category': category,
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> listIncidents() async {
    final res = await _dio.get<Map<String, dynamic>>('/incidents');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/incidents/$id');
    final data = (res.data?['data'] as Map?) ?? {};
    return Map<String, dynamic>.from(data);
  }

  Future<void> attachMedia({required int incidentId, required int mediaId}) async {
    await _dio.post<Map<String, dynamic>>(
      '/incidents/$incidentId/attachments',
      data: {'mediaId': mediaId},
    );
  }

  Future<int> triggerSos({required double lat, required double lng, String? message}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/sos',
      data: {'lat': lat, 'lng': lng, if (message != null && message.isNotEmpty) 'message': message},
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }
}
