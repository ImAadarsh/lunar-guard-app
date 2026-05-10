import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'api_client.dart';
import 'secure_token_store.dart';

class OfflineQueueItem {
  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });

  final int id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  factory OfflineQueueItem.fromRow(Map<String, Object?> row) {
    return OfflineQueueItem(
      id: row['id'] as int,
      type: row['type'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(row['created_at'] as String),
      attempts: row['attempts'] as int,
      lastError: row['last_error'] as String?,
    );
  }
}

class OfflineQueueService {
  OfflineQueueService({SecureTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? SecureTokenStore();

  final SecureTokenStore _tokenStore;
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dbPath, 'lunar_security_queue.db'),
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<int> pendingCount() async {
    final db = await _database;
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS count FROM offline_queue');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<List<OfflineQueueItem>> pendingItems({int limit = 100}) async {
    final db = await _database;
    final rows =
        await db.query('offline_queue', orderBy: 'id ASC', limit: limit);
    return rows.map(OfflineQueueItem.fromRow).toList();
  }

  Future<void> enqueue(
      {required String type, required Map<String, dynamic> payload}) async {
    final db = await _database;
    await db.insert('offline_queue', {
      'type': type,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<int> flush() async {
    final db = await _database;
    final dio = ApiClient.createAuthorized(_tokenStore);
    final items = await pendingItems(limit: 100);
    var synced = 0;
    for (final item in items) {
      try {
        await _replay(dio, item);
        await db.delete('offline_queue', where: 'id = ?', whereArgs: [item.id]);
        synced++;
      } catch (e) {
        await db.update(
          'offline_queue',
          {'attempts': item.attempts + 1, 'last_error': e.toString()},
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }
    return synced;
  }

  Future<void> _replay(Dio dio, OfflineQueueItem item) async {
    switch (item.type) {
      case 'patrol_scan':
        await dio.post<Map<String, dynamic>>('/patrols/scans',
            data: item.payload);
        break;
      case 'telemetry_gps':
        await dio.post<Map<String, dynamic>>('/telemetry/gps',
            data: item.payload);
        break;
      case 'sos':
        await dio.post<Map<String, dynamic>>('/sos', data: item.payload);
        break;
      case 'incident':
        await _replayIncident(dio, item.payload);
        break;
      case 'visual_log':
        await _replayVisualLog(dio, item.payload);
        break;
      default:
        throw StateError('Unsupported queued action: ${item.type}');
    }
  }

  Future<int> _createIncident(Dio dio, Map<String, dynamic> incident) async {
    final res =
        await dio.post<Map<String, dynamic>>('/incidents', data: incident);
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }

  Future<int> _uploadFile(
      Dio dio, Map<String, dynamic> file, String kind) async {
    final form = FormData.fromMap({
      'kind': kind,
      'file': await MultipartFile.fromFile(file['path'] as String,
          filename: file['name'] as String),
    });
    final res =
        await dio.post<Map<String, dynamic>>('/media/upload', data: form);
    final data = (res.data?['data'] as Map?) ?? {};
    return int.tryParse(data['id']?.toString() ?? '') ?? 0;
  }

  Future<void> _replayIncident(Dio dio, Map<String, dynamic> payload) async {
    final incident = Map<String, dynamic>.from(payload['incident'] as Map);
    final incidentId = await _createIncident(dio, incident);
    final files = (payload['files'] as List? ?? const []).whereType<Map>();
    for (final file in files) {
      final mediaId =
          await _uploadFile(dio, Map<String, dynamic>.from(file), 'incident');
      if (incidentId > 0 && mediaId > 0) {
        await dio.post<Map<String, dynamic>>(
            '/incidents/$incidentId/attachments',
            data: {'mediaId': mediaId});
      }
    }
  }

  Future<void> _replayVisualLog(Dio dio, Map<String, dynamic> payload) async {
    final mediaId = await _uploadFile(
      dio,
      {'path': payload['photoPath'], 'name': payload['photoName']},
      'visual_log',
    );
    final attendanceSessionId = payload['attendanceSessionId'];
    if (attendanceSessionId != null && mediaId > 0) {
      await dio.post<Map<String, dynamic>>('/visual-logs', data: {
        'attendanceSessionId': attendanceSessionId,
        'mediaId': mediaId,
        if (payload['note'] != null) 'note': payload['note'],
      });
    } else {
      final incident = {
        'siteId': payload['siteId'],
        'category': 'visual_log',
        'title': 'Hourly all-clear',
        'description': payload['note'] ?? 'All-clear visual log',
      };
      final incidentId = await _createIncident(dio, incident);
      if (incidentId > 0 && mediaId > 0) {
        await dio.post<Map<String, dynamic>>(
            '/incidents/$incidentId/attachments',
            data: {'mediaId': mediaId});
      }
    }
  }
}
