import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/incident_report.dart';
import '../../services/api_client.dart';
import '../../services/incidents_api.dart';
import '../../services/offline_queue_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/secure_token_store.dart';
import '../../services/uploads_api.dart';

class IncidentController extends ChangeNotifier {
  IncidentController({SecureTokenStore? tokenStore, OfflineQueueService? queue})
      : _tokenStore = tokenStore ?? SecureTokenStore(),
        _queue = queue ?? OfflineQueueService() {
    final dio = ApiClient.createAuthorized(_tokenStore);
    _incidentsApi = IncidentsApi(dio);
    _uploadsApi = UploadsApi(dio);
  }

  final SecureTokenStore _tokenStore;
  final OfflineQueueService _queue;
  late final IncidentsApi _incidentsApi;
  late final UploadsApi _uploadsApi;

  bool loading = false;
  String? error;
  List<IncidentReport> incidents = const [];
  List<Map<String, dynamic>> dueVisualLogs = const [];

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _incidentsApi.listIncidents();
      incidents = rows.map(IncidentReport.fromJson).toList();
      dueVisualLogs = await _incidentsApi.visualLogsDue();
      final due = dueVisualLogs.where((item) =>
          item['status']?.toString() == 'due' ||
          item['status']?.toString() == 'missed');
      if (due.isNotEmpty) {
        await LocalNotificationService.showVisualLogReminder(
            'Submit your hourly all-clear for the active shift.');
      }
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
    List<Map<String, String>> attachments = const [],
    int? shiftId,
    int? attendanceSessionId,
    double? lat,
    double? lng,
  }) async {
    final incidentPayload = {
      'siteId': siteId,
      'category': category,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (shiftId != null) 'shiftId': shiftId,
      if (attendanceSessionId != null) 'attendanceSessionId': attendanceSessionId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final files = [
      if (photoPath != null &&
          photoName != null &&
          photoPath.isNotEmpty &&
          photoName.isNotEmpty)
        {'path': photoPath, 'name': photoName},
      ...attachments,
    ];
    try {
      final incidentId = await _incidentsApi.createIncident(
        siteId: siteId,
        category: category,
        title: title,
        description: description,
        shiftId: shiftId,
        attendanceSessionId: attendanceSessionId,
        lat: lat,
        lng: lng,
      );
      for (final file in files) {
        final uploaded = await _uploadsApi.uploadFile(
          filePath: file['path']!,
          fileName: file['name']!,
          kind: 'incident',
        );
        final mediaId = int.tryParse(uploaded['id']?.toString() ?? '') ?? 0;
        if (mediaId > 0) {
          await _incidentsApi.attachMedia(
              incidentId: incidentId, mediaId: mediaId);
        }
      }
      await refresh();
      return null;
    } on DioException catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(
          type: 'incident',
          payload: {
            'incident': incidentPayload,
            'files': files,
          },
        );
        return 'Incident queued. It will sync when connectivity returns.';
      }
      return _err(e);
    }
  }

  Future<String?> triggerSos(
      {required double lat, required double lng, String? message}) async {
    try {
      await _incidentsApi.triggerSos(lat: lat, lng: lng, message: message);
      await refresh();
      return null;
    } on DioException catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(
          type: 'sos',
          payload: {
            'lat': lat,
            'lng': lng,
            if (message != null && message.isNotEmpty) 'message': message
          },
        );
        return 'SOS queued locally. Keep trying to sync as soon as a connection is available.';
      }
      return _err(e);
    }
  }

  Future<String?> submitVisualLog({
    required int siteId,
    int? attendanceSessionId,
    required String note,
    required String photoPath,
    required String photoName,
  }) async {
    try {
      final uploaded = await _uploadsApi.uploadFile(
        filePath: photoPath,
        fileName: photoName,
        kind: 'visual_log',
      );
      final mediaId = int.tryParse(uploaded['id']?.toString() ?? '') ?? 0;
      if (attendanceSessionId != null && mediaId > 0) {
        await _incidentsApi.completeVisualLog(
          attendanceSessionId: attendanceSessionId,
          mediaId: mediaId,
          note: note,
        );
      } else {
        final incidentId = await _incidentsApi.createIncident(
          siteId: siteId,
          category: 'visual_log',
          title: 'Hourly all-clear',
          description: note.isEmpty ? 'All-clear visual log' : note,
        );
        if (incidentId > 0 && mediaId > 0) {
          await _incidentsApi.attachMedia(
              incidentId: incidentId, mediaId: mediaId);
        }
      }
      await refresh();
      return null;
    } on DioException catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(
          type: 'visual_log',
          payload: {
            'siteId': siteId,
            if (attendanceSessionId != null)
              'attendanceSessionId': attendanceSessionId,
            'note': note,
            'photoPath': photoPath,
            'photoName': photoName,
          },
        );
        return 'Visual log queued. It will sync when connectivity returns.';
      }
      return _err(e);
    }
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['error'] is Map &&
        data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Request failed';
  }

  bool _isOffline(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.response == null;
  }
}
