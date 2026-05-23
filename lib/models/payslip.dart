class Payslip {
  const Payslip({
    required this.id,
    required this.payrollRunId,
    required this.status,
    this.periodStart,
    this.periodEnd,
    this.issuedAt,
    this.sentAt,
    this.readAt,
    this.payload,
  });

  final int id;
  final int payrollRunId;
  final String status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? issuedAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final Map<String, dynamic>? payload;

  String get periodLabel {
    if (periodStart == null && periodEnd == null) return 'Pay period';
    final fmt = (DateTime? d) =>
        d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(periodStart)} – ${fmt(periodEnd)}';
  }

  String? get grossDisplay {
    final p = payload;
    if (p == null) return null;
    final gross = p['grossPence'] ?? p['gross_pence'];
    if (gross == null) return null;
    final pence = int.tryParse(gross.toString()) ?? 0;
    return '£${(pence / 100).toStringAsFixed(2)}';
  }

  factory Payslip.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? payload;
    final raw = json['payload'];
    if (raw is Map) {
      payload = Map<String, dynamic>.from(raw);
    }

    return Payslip(
      id: _int(json['id']),
      payrollRunId: _int(json['payrollRunId']),
      status: json['status']?.toString() ?? 'draft',
      periodStart: _dt(json['periodStart']),
      periodEnd: _dt(json['periodEnd']),
      issuedAt: _dt(json['issuedAt']),
      sentAt: _dt(json['sentAt']),
      readAt: _dt(json['readAt']),
      payload: payload,
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
