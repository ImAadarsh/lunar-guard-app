import 'package:dio/dio.dart';

class ShiftChatApi {
  ShiftChatApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listThreads({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final res = await _dio.get<Map<String, dynamic>>(
      '/shift-chats',
      queryParameters: {'date': dateStr},
    );
    return _items(res.data);
  }

  Future<List<Map<String, dynamic>>> listMessages(
    int chatId, {
    int? sinceId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/shift-chats/$chatId/messages',
      queryParameters: {if (sinceId != null) 'sinceId': sinceId},
    );
    return _items(res.data);
  }

  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String body,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/shift-chats/$chatId/messages',
      data: {'body': body},
    );
    final data = res.data?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<Map<String, dynamic>> sendPing({
    required int chatId,
    required double lat,
    required double lng,
    String? body,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/shift-chats/$chatId/ping',
      data: {
        'lat': lat,
        'lng': lng,
        if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      },
    );
    final data = res.data?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<void> markRead(int chatId) async {
    await _dio.patch('/shift-chats/$chatId/read');
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final items = (data is Map ? data['items'] : null) ?? body?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
