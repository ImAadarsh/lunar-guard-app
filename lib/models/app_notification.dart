class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String? body;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'generic',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.tryParse(json['readAt'].toString()),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
