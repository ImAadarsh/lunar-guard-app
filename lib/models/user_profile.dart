class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.phone,
    required this.status,
    required this.role,
    this.createdAt,
    this.twoFactorEnabled = false,
    this.payRatePenceHour,
  });

  final int id;
  final String email;
  final String? phone;
  final String status;
  final String role;
  final String? createdAt;
  final bool twoFactorEnabled;
  final int? payRatePenceHour;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return UserProfile(
      id: id,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      role: json['role'] as String? ?? 'guard',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      twoFactorEnabled: _bool(json['twoFactorEnabled'] ?? json['two_factor_enabled']),
      payRatePenceHour: json['payRatePenceHour'] == null ? null : int.tryParse(json['payRatePenceHour'].toString()),
    );
  }

  static bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return v == true || v == '1';
  }
}
