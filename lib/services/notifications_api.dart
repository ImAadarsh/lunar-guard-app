import 'package:dio/dio.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list(
      {int limit = 50, bool unreadOnly = false}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'limit': limit, 'unreadOnly': unreadOnly},
    );
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<int> unreadCount() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/notifications/unread-count');
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['count']?.toString() ?? '') ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('/notifications/read-all');
  }
}
