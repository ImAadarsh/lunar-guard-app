class GuardTraining {
  const GuardTraining({
    required this.trainingId,
    required this.siteId,
    required this.siteName,
    this.trainedOn,
    this.notes,
  });

  final int trainingId;
  final int siteId;
  final String siteName;
  final DateTime? trainedOn;
  final String? notes;

  factory GuardTraining.fromJson(Map<String, dynamic> json) {
    return GuardTraining(
      trainingId: _int(json['trainingId']),
      siteId: _int(json['siteId']),
      siteName: json['siteName']?.toString() ?? 'Site',
      trainedOn: _dateOnly(json['trainedOn']),
      notes: json['notes']?.toString(),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  static DateTime? _dateOnly(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      return DateTime.tryParse('${s}T12:00:00');
    }
    return DateTime.tryParse(s);
  }
}
