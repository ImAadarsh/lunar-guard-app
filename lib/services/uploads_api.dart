import 'package:dio/dio.dart';

class UploadsApi {
  UploadsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String kind = 'incident',
  }) async {
    final form = FormData.fromMap({
      'kind': kind,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res =
        await _dio.post<Map<String, dynamic>>('/media/upload', data: form);
    final data = (res.data?['data'] as Map?) ?? {};
    return Map<String, dynamic>.from(data);
  }
}
