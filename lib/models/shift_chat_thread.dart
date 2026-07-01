class ShiftChatThread {
  const ShiftChatThread({
    required this.id,
    required this.shiftId,
    required this.siteId,
    required this.status,
    this.siteName,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  final int id;
  final int shiftId;
  final int siteId;
  final String? siteName;
  final String status;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  String get siteLabel =>
      siteName?.trim().isNotEmpty == true ? siteName!.trim() : 'Site #$siteId';

  bool get isUpcoming => status == 'upcoming';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  factory ShiftChatThread.fromJson(Map<String, dynamic> json) {
    return ShiftChatThread(
      id: _int(json['id']),
      shiftId: _int(json['shiftId']),
      siteId: _int(json['siteId']),
      siteName: json['siteName']?.toString(),
      status: json['status']?.toString() ?? 'upcoming',
      unreadCount: _int(json['unreadCount']),
      lastMessageAt: _dt(json['lastMessageAt']),
      lastMessagePreview: json['lastMessagePreview']?.toString(),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
