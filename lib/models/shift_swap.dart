class ShiftSwap {
  const ShiftSwap({
    required this.id,
    required this.shiftId,
    required this.siteId,
    required this.siteName,
    required this.status,
    this.targetUserId,
    this.targetEmail,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.resolvedAt,
  });

  final int id;
  final int shiftId;
  final int siteId;
  final String siteName;
  final String status;
  final int? targetUserId;
  final String? targetEmail;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  factory ShiftSwap.fromJson(Map<String, dynamic> json) {
    return ShiftSwap(
      id: _int(json['id']),
      shiftId: _int(json['shiftId']),
      siteId: _int(json['siteId']),
      siteName: json['siteName']?.toString() ?? 'Site',
      status: json['status']?.toString() ?? 'pending',
      targetUserId: json['targetUserId'] == null
          ? null
          : _int(json['targetUserId']),
      targetEmail: json['targetEmail']?.toString(),
      startsAt: _dt(json['startsAt']),
      endsAt: _dt(json['endsAt']),
      createdAt: _dt(json['createdAt']),
      resolvedAt: _dt(json['resolvedAt']),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
