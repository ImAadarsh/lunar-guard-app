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
    this.fullName,
    this.givenNames,
    this.surname,
    this.siaType,
    this.siaNumber,
    this.siaExpiryDate,
  });

  final int id;
  final String email;
  final String? phone;
  final String status;
  final String role;
  final String? createdAt;
  final bool twoFactorEnabled;
  final int? payRatePenceHour;
  final String? fullName;
  final String? givenNames;
  final String? surname;
  final String? siaType;
  final String? siaNumber;
  final String? siaExpiryDate;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return UserProfile(
      id: id,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      role: json['role'] as String? ?? 'guard',
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      twoFactorEnabled:
          _bool(json['twoFactorEnabled'] ?? json['two_factor_enabled']),
      payRatePenceHour: _intOrNull(json['payRatePenceHour'] ?? json['pay_rate_pence_hour']),
      fullName: _str(json['fullName'] ?? json['full_name']),
      givenNames: _str(json['givenNames'] ?? json['given_names']),
      surname: _str(json['surname']),
      siaType: _str(json['siaType'] ?? json['sia_type']),
      siaNumber: _str(json['siaNumber'] ?? json['sia_number']),
      siaExpiryDate: json['siaExpiryDate']?.toString() ??
          json['sia_expiry_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (phone != null) 'phone': phone,
        'status': status,
        'role': role,
        if (createdAt != null) 'createdAt': createdAt,
        'twoFactorEnabled': twoFactorEnabled,
        if (payRatePenceHour != null) 'payRatePenceHour': payRatePenceHour,
        if (fullName != null) 'fullName': fullName,
        if (givenNames != null) 'givenNames': givenNames,
        if (surname != null) 'surname': surname,
        if (siaType != null) 'siaType': siaType,
        if (siaNumber != null) 'siaNumber': siaNumber,
        if (siaExpiryDate != null) 'siaExpiryDate': siaExpiryDate,
      };

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return v == true || v == '1';
  }
}
