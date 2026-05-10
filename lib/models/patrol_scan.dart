class PatrolScan {
  const PatrolScan({
    required this.id,
    required this.checkpointId,
    required this.userId,
    this.checkpointLabel,
    this.siteName,
    this.scannedAt,
  });

  final int id;
  final int checkpointId;
  final int userId;
  final String? checkpointLabel;
  final String? siteName;
  final DateTime? scannedAt;

  factory PatrolScan.fromJson(Map<String, dynamic> json) {
    return PatrolScan(
      id: _int(json['id']),
      checkpointId: _int(json['checkpointId']),
      userId: _int(json['userId']),
      checkpointLabel: json['checkpointLabel']?.toString(),
      siteName: json['siteName']?.toString(),
      scannedAt: _dt(json['scannedAt']),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
