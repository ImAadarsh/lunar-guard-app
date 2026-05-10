import 'package:dio/dio.dart';

class IncidentsApi {
  IncidentsApi(this._dio);

  final Dio _dio;

  Future<int> createIncident({
    required int siteId,
    required String category,
    required String title,
    String? description,
    int? shiftId,
    int? attendanceSessionId,
    double? lat,
    double? lng,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/incidents',
      data: {
        'siteId': siteId,
        'category': category,
        'title': title,
        if (shiftId != null) 'shiftId': shiftId,
        if (attendanceSessionId != null) 'attendanceSessionId': attendanceSessionId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> listIncidents() async {
    final res = await _dio.get<Map<String, dynamic>>('/incidents');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/incidents/$id');
    final data = (res.data?['data'] as Map?) ?? {};
    return Map<String, dynamic>.from(data);
  }

  Future<void> attachMedia(
      {required int incidentId, required int mediaId}) async {
    await _dio.post<Map<String, dynamic>>(
      '/incidents/$incidentId/attachments',
      data: {'mediaId': mediaId},
    );
  }

  Future<List<Map<String, dynamic>>> visualLogsDue() async {
    final res = await _dio.get<Map<String, dynamic>>('/visual-logs/due');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> completeVisualLog({
    required int attendanceSessionId,
    int? mediaId,
    String? note,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/visual-logs',
      data: {
        'attendanceSessionId': attendanceSessionId,
        if (mediaId != null) 'mediaId': mediaId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<int> triggerSos(
      {required double lat, required double lng, String? message}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/sos',
      data: {
        'lat': lat,
        'lng': lng,
        if (message != null && message.isNotEmpty) 'message': message
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }
}
