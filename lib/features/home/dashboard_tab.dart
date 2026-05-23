import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../utils/maps_links.dart';
import '../shell/offline_queue_controller.dart';
import '../shell/shell_navigation_controller.dart';
import '../shell/telemetry_controller.dart';
import '../shift/shift_controller.dart';
import 'home_controller.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeController>().refresh();
      context.read<ShiftController>().refresh();
    });
  }

  Future<void> _openNextShiftLocation(ShiftController shifts) async {
    final shift = shifts.nextShift;
    if (shift == null) return;
    final coords = shifts.siteLatLng(shift.siteId);
    if (coords == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site location not loaded yet.')),
      );
      return;
    }
    final ok = await openGoogleMaps(
      lat: coords.lat,
      lng: coords.lng,
      label: shift.siteLabel,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final home = context.watch<HomeController>();
    final shifts = context.watch<ShiftController>();
    final queue = context.watch<OfflineQueueController>();
    final telemetry = context.watch<TelemetryController>();
    final nav = context.read<ShellNavigationController>();

    final nextShift = shifts.nextShift;
    final subtitle = nextShift == null
        ? 'No upcoming shifts'
        : nextShift.startsAt == null
            ? nextShift.siteLabel
            : '${nextShift.siteLabel}\n${formatUkDateTime(nextShift.startsAt)}';
    final badge = shifts.activeSession != null ? 'On duty' : 'Scheduled';
    final canOpenMaps =
        nextShift != null && shifts.siteLatLng(nextShift.siteId) != null;

    return RefreshIndicator(
      onRefresh: () async {
        await home.refresh();
        await shifts.refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _StatusHero(
            title: 'Next shift',
            subtitle: subtitle,
            badge: badge,
            icon: Icons.nightlight_round,
            onTap: canOpenMaps ? () => _openNextShiftLocation(shifts) : null,
            trailing: canOpenMaps
                ? TextButton.icon(
                    onPressed: () => _openNextShiftLocation(shifts),
                    icon: Icon(Icons.map_outlined,
                        size: 16, color: lunar.linkColor),
                    label: Text(
                      'Open map',
                      style: t.labelSmall?.copyWith(
                        color: lunar.linkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'On duty',
                  value: shifts.activeSession != null ? 'YES' : 'NO',
                  hint: shifts.activeSession != null
                      ? 'Session active'
                      : 'Awaiting check-in',
                  icon: Icons.location_on_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Patrol',
                  label2: 'scans today',
                  value: '${home.summary.patrolScansLast24h}',
                  hint: 'Last 24h',
                  icon: Icons.qr_code_2,
                  color: lunar.iconMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick actions',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _QuickRow(
            icon: Icons.login_rounded,
            label: 'Check-in',
            sub: 'Go to Shift tab for GPS check-in',
            onTap: () => nav.goToTab(1),
          ),
          _QuickRow(
            icon: Icons.logout_rounded,
            label: 'Check-out',
            sub: 'Go to Shift tab for GPS check-out',
            onTap: () => nav.goToTab(1),
          ),
          _QuickRow(
            icon: Icons.camera_alt_outlined,
            label: 'Visual log',
            sub: 'Capture an all-clear on Safety tab',
            onTap: () => nav.goToTab(3),
          ),
          _QuickRow(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Patrol scan',
            sub: 'Scan checkpoint QR on Patrol tab',
            onTap: () => nav.goToTab(2),
          ),
          _QuickRow(
            icon: Icons.gps_fixed,
            label: 'Telemetry',
            sub: telemetry.running
                ? 'Active · ${telemetry.lastSentAt?.toLocal().toString().substring(11, 16) ?? 'sending soon'}'
                : 'Starts automatically after check-in',
            onTap: () async {
              final telemetryController = context.read<TelemetryController>();
              final queueController = context.read<OfflineQueueController>();
              await telemetryController.sendNow();
              await queueController.refresh();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(telemetryController.error ??
                        'Telemetry ping sent or queued.')),
              );
            },
          ),
          _QuickRow(
            icon: Icons.cloud_sync_outlined,
            label: 'Offline queue',
            sub:
                '${queue.pending} pending action${queue.pending == 1 ? '' : 's'}',
            onTap: () async {
              final queueController = context.read<OfflineQueueController>();
              final synced = await queueController.flush();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Replayed $synced queued actions.')),
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: lunar.mutedText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      home.error ?? 'Live summary connected to /guard/summary.',
                      style: t.bodySmall?.copyWith(
                          color: lunar.mutedText, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [lunar.heroGradientStart, lunar.heroGradientEnd],
            ),
            border: Border.all(color: lunar.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lunar.heroIconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: lunar.heroIconColor, size: 26),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badge,
                      style: t.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: t.labelLarge?.copyWith(color: lunar.mutedText)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    this.label2,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String label;
  final String? label2;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lunar.tileBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lunar.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            label2 != null ? '$label · $label2' : label,
            style: t.labelSmall?.copyWith(color: lunar.mutedText),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(hint,
              style: t.labelSmall?.copyWith(
                  color: lunar.mutedText.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: lunar.tileBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: lunar.iconMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: t.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(sub,
                          style: t.bodySmall?.copyWith(color: lunar.mutedText)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: lunar.mutedText.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
