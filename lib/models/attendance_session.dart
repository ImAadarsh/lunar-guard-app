class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.shiftId,
    required this.userId,
    this.checkInAt,
    this.checkOutAt,
    required this.status,
  });

  final int id;
  final int shiftId;
  final int userId;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String status;

  bool get isOpen => status == 'open';

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: _int(json['id']),
      shiftId: _int(json['shiftId']),
      userId: _int(json['userId']),
      checkInAt: _dt(json['checkInAt']),
      checkOutAt: _dt(json['checkOutAt']),
      status: json['status']?.toString() ?? 'open',
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}
