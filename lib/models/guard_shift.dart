class GuardShift {
  const GuardShift({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.siteName,
  });

  final int id;
  final int siteId;
  final int userId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;
  final String? siteName;

  String get siteLabel =>
      siteName?.trim().isNotEmpty == true ? siteName!.trim() : 'Site #$siteId';

  factory GuardShift.fromJson(Map<String, dynamic> json) {
    return GuardShift(
      id: _int(json['id']),
      siteId: _int(json['siteId']),
      userId: _int(json['userId']),
      startsAt: _dt(json['startsAt']),
      endsAt: _dt(json['endsAt']),
      status: json['status']?.toString() ?? 'scheduled',
      siteName: json['siteName']?.toString(),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
