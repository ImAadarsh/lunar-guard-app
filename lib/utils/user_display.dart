import '../models/user_profile.dart';

String roleLabel(String role) {
  switch (role) {
    case 'guard':
      return 'Staff';
    case 'supervisor':
      return 'Manager';
    case 'admin':
      return 'Admin';
    default:
      return role;
  }
}

String displayName(UserProfile profile) {
  final n = profile.fullName?.trim();
  if (n != null && n.isNotEmpty) return n;
  return profile.email;
}

String initialsFor(UserProfile profile) {
  final name = profile.fullName?.trim();
  if (name != null && name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.length >= 2) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
  }
  final email = profile.email;
  if (email.isEmpty) return '?';
  final local = email.split('@').first;
  if (local.length >= 2) return local.substring(0, 2).toUpperCase();
  return local.toUpperCase();
}

String formatPayRatePence(int? pence) {
  if (pence == null) return '—';
  return '£${(pence / 100).toStringAsFixed(2)}/hr';
}

String formatUkDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final day = d.day.toString().padLeft(2, '0');
  return '$day ${_monthName(d.month)} ${d.year}';
}

String _monthName(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  if (m < 1 || m > 12) return m.toString();
  return names[m - 1];
}

/// Days until SIA expiry; negative if expired; null if no date.
int? daysUntilSiaExpiry(UserProfile profile) {
  final raw = profile.siaExpiryDate;
  if (raw == null || raw.isEmpty) return null;
  final expiry = DateTime.tryParse(raw);
  if (expiry == null) return null;
  final today = DateTime.now();
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(expiry.year, expiry.month, expiry.day);
  return b.difference(a).inDays;
}
