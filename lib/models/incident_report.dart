import 'media_asset.dart';

class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.category,
    required this.title,
    this.description,
    required this.status,
    this.createdAt,
    this.attachments = const [],
  });

  final int id;
  final int siteId;
  final int userId;
  final String category;
  final String title;
  final String? description;
  final String status;
  final DateTime? createdAt;
  final List<MediaAsset> attachments;

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
            .whereType<Map>()
            .map((e) => MediaAsset.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <MediaAsset>[];

    return IncidentReport(
      id: _int(json['id']),
      siteId: _int(json['siteId']),
      userId: _int(json['userId']),
      category: json['category']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'open',
      createdAt: _dt(json['createdAt']),
      attachments: attachments,
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
