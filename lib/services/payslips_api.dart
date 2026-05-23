import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';

class PayslipsApi {
  PayslipsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listMyPayslips() async {
    final res = await _dio.get<Map<String, dynamic>>('/payslips');
    final items = (res.data?['data'] as Map?)?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Downloads payslip PDF to a temp file and returns the local path.
  Future<String> downloadPayslipPdf(int payslipId) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/payslip-$payslipId.pdf';
    await _dio.download(
      '${ApiConfig.apiV1Base}/payroll/payslips/$payslipId/file',
      path,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    final file = File(path);
    if (!await file.exists() || await file.length() < 32) {
      throw Exception('Payslip file could not be downloaded.');
    }
    return path;
  }
}
