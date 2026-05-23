import 'dart:convert';

/// Parses checkpoint id from QR payload (numeric id, JSON, or lunar URL).
int? parseCheckpointQr(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final direct = int.tryParse(text);
  if (direct != null && direct > 0) return direct;

  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      for (final key in ['checkpointId', 'checkpoint_id', 'id']) {
        final v = decoded[key];
        final id = int.tryParse(v?.toString() ?? '');
        if (id != null && id > 0) return id;
      }
    }
  } catch (_) {}

  final lunar = RegExp(r'checkpoint[/:=](\d+)', caseSensitive: false).firstMatch(text);
  if (lunar != null) {
    return int.tryParse(lunar.group(1)!);
  }

  if (RegExp(r'^\d+$').hasMatch(text)) {
    return int.tryParse(text);
  }

  return null;
}
