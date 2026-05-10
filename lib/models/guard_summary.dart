class GuardSummary {
  const GuardSummary({
    required this.patrolScansLast24h,
    required this.openIncidentCount,
    this.activeSession,
    this.nextShift,
  });

  final int patrolScansLast24h;
  final int openIncidentCount;
  final Map<String, dynamic>? activeSession;
  final Map<String, dynamic>? nextShift;

  factory GuardSummary.fromJson(Map<String, dynamic> json) {
    return GuardSummary(
      patrolScansLast24h: int.tryParse(json['patrolScansLast24h']?.toString() ?? '') ?? 0,
      openIncidentCount: int.tryParse(json['openIncidentCount']?.toString() ?? '') ?? 0,
      activeSession: json['activeSession'] is Map
          ? Map<String, dynamic>.from(json['activeSession'] as Map)
          : null,
      nextShift: json['nextShift'] is Map ? Map<String, dynamic>.from(json['nextShift'] as Map) : null,
    );
  }
}
