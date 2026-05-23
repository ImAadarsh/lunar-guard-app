import 'package:dio/dio.dart';

class ShiftSwapsApi {
  ShiftSwapsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listMySwaps() async {
    final res = await _dio.get<Map<String, dynamic>>('/shift-swaps/mine');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listSwapCandidates(int shiftId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/shift-swaps/candidates',
      queryParameters: {'shiftId': shiftId},
    );
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<int> requestSwap({
    required int shiftId,
    int? targetUserId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/shift-swaps',
      data: {
        'shiftId': shiftId,
        if (targetUserId != null) 'targetUserId': targetUserId,
      },
    );
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }
}
