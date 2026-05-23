import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/lunar_theme_extension.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final lunar = context.lunar;
    final (Color bg, Color fg) = switch (tone) {
      StatusTone.success => (
          AppColors.success.withValues(alpha: 0.18),
          AppColors.success,
        ),
      StatusTone.warning => (
          AppColors.warning.withValues(alpha: 0.18),
          AppColors.warning,
        ),
      StatusTone.danger => (
          AppColors.danger.withValues(alpha: 0.18),
          AppColors.danger,
        ),
      StatusTone.neutral => (
          lunar.mutedText.withValues(alpha: 0.12),
          lunar.mutedText,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

enum StatusTone { success, warning, danger, neutral }

StatusTone toneForRequestStatus(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'active':
    case 'completed':
      return StatusTone.success;
    case 'pending':
    case 'scheduled':
      return StatusTone.warning;
    case 'rejected':
    case 'cancelled':
      return StatusTone.danger;
    default:
      return StatusTone.neutral;
  }
}
