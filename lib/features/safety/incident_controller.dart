import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/incident_report.dart';
import '../../services/api_client.dart';
import '../../services/incidents_api.dart';
import '../../services/secure_token_store.dart';
import '../../services/uploads_api.dart';

class IncidentController extends ChangeNotifier {
  IncidentController({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore() {
    final dio = ApiClient.createAuthorized(_tokenStore);
    _incidentsApi = IncidentsApi(dio);
    _uploadsApi = UploadsApi(dio);
  }

  final SecureTokenStore _tokenStore;
  late final IncidentsApi _incidentsApi;
  late final UploadsApi _uploadsApi;

  bool loading = false;
  String? error;
  List<IncidentReport> incidents = const [];

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _incidentsApi.listIncidents();
      incidents = rows.map(IncidentReport.fromJson).toList();
    } on DioException catch (e) {
      error = _err(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> createIncident({
    required int siteId,
    required String category,
    required String title,
    String? description,
    String? photoPath,
    String? photoName,
  }) async {
    try {
      final incidentId = await _incidentsApi.createIncident(
        siteId: siteId,
        category: category,
        title: title,
        description: description,
      );
      if (photoPath != null && photoName != null && photoPath.isNotEmpty && photoName.isNotEmpty) {
        final uploaded = await _uploadsApi.uploadFile(
          filePath: photoPath,
          fileName: photoName,
          kind: 'incident',
        );
        final mediaId = int.tryParse(uploaded['id']?.toString() ?? '') ?? 0;
        if (mediaId > 0) {
          await _incidentsApi.attachMedia(incidentId: incidentId, mediaId: mediaId);
        }
      }
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Future<String?> triggerSos({required double lat, required double lng, String? message}) async {
    try {
      await _incidentsApi.triggerSos(lat: lat, lng: lng, message: message);
      await refresh();
      return null;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map && data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Request failed';
  }
}
