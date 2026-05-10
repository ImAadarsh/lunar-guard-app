import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
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
      final home = context.read<HomeController>();
      final shift = context.read<ShiftController>();
      home.refresh();
      shift.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final home = context.watch<HomeController>();
    final shifts = context.watch<ShiftController>();

    final nextShift = shifts.nextShift;
    final subtitle = nextShift == null
        ? 'No upcoming shifts'
        : 'Shift #${nextShift.id} · ${nextShift.startsAt?.toLocal().toString().substring(0, 16) ?? 'TBD'}';
    final badge = shifts.activeSession != null ? 'On duty' : 'Scheduled';

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
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'On duty',
                  value: shifts.activeSession != null ? 'YES' : 'NO',
                  hint: shifts.activeSession != null ? 'Session active' : 'Awaiting check-in',
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
                  color: AppColors.silver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick actions', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _QuickRow(
            icon: Icons.login_rounded,
            label: 'Check-in',
            sub: 'Use Shift tab for GPS check-in',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Open Shift tab to check in with live location.')),
            ),
          ),
          _QuickRow(
            icon: Icons.logout_rounded,
            label: 'Check-out',
            sub: 'Use Shift tab for GPS check-out',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Open Shift tab to check out with live location.')),
            ),
          ),
          _QuickRow(
            icon: Icons.camera_alt_outlined,
            label: 'Visual log',
            sub: 'Use Safety tab incident attachment',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use Safety tab to submit incident with photo.')),
            ),
          ),
          _QuickRow(
            icon: Icons.gps_fixed,
            label: 'Telemetry',
            sub: 'Available once shift session is active',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.silverMuted.withValues(alpha: 0.9)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      home.error ?? 'Live summary connected to /guard/summary.',
                      style: t.bodySmall?.copyWith(color: AppColors.silverMuted, height: 1.35),
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
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.primary.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.onDark, size: 26),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
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
          Text(title, style: t.labelLarge?.copyWith(color: AppColors.silverMuted)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            label2 != null ? '$label · $label2' : label,
            style: t.labelSmall?.copyWith(color: AppColors.silverMuted),
          ),
          const SizedBox(height: 4),
          Text(value, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(hint, style: t.labelSmall?.copyWith(color: AppColors.silverMuted.withValues(alpha: 0.75))),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.silver),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(sub, style: t.bodySmall?.copyWith(color: AppColors.silverMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.silverMuted.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
