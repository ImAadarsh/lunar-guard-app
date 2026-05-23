import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../shell/telemetry_controller.dart';

class TrackingSettingsScreen extends StatelessWidget {
  const TrackingSettingsScreen({super.key});

  static const routeName = '/profile/tracking';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final telemetry = context.watch<TelemetryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking & battery'),
        actions: lunarAppBarActions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'While you are checked in, Lunar Security sends GPS updates to the command center every minute and when you move significantly.',
            style: t.bodyMedium?.copyWith(color: lunar.mutedText, height: 1.45),
          ),
          const SizedBox(height: 20),
          LunarSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live status',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _StatusLine(
                  label: 'Tracking',
                  value: telemetry.running ? 'Active' : 'Idle',
                  valueColor:
                      telemetry.running ? AppColors.success : lunar.mutedText,
                ),
                if (telemetry.activeShiftId != null)
                  _StatusLine(
                    label: 'Shift',
                    value: '#${telemetry.activeShiftId}',
                  ),
                if (telemetry.lastSentAt != null)
                  _StatusLine(
                    label: 'Last sent',
                    value:
                        telemetry.lastSentAt!.toLocal().toString().substring(0, 16),
                  ),
                if (telemetry.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    telemetry.error!,
                    style: t.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'On Android, a persistent notification appears during your shift. Allow “Always” location permission for reliable background updates.',
            style: t.bodySmall?.copyWith(color: lunar.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: t.bodySmall?.copyWith(color: lunar.mutedText)),
          ),
          Expanded(
            child: Text(
              value,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
