class SwapCandidate {
  const SwapCandidate({
    required this.userId,
    required this.email,
    this.guardName,
  });

  final int userId;
  final String email;
  final String? guardName;

  String get displayName {
    final name = guardName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email;
  }

  factory SwapCandidate.fromJson(Map<String, dynamic> json) {
    return SwapCandidate(
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      email: json['email']?.toString() ?? '',
      guardName: json['guardName']?.toString(),
    );
  }
}
