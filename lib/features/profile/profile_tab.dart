import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/user_display.dart';
import '../auth/login_screen.dart';
import 'alerts_sos_screen.dart';
import 'leave_request_screen.dart';
import 'offline_queue_screen.dart';
import 'payslips_screen.dart';
import 'privacy_data_screen.dart';
import 'shift_swap_screen.dart';
import 'tracking_settings_screen.dart';
import 'training_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();
    final lunar = context.lunar;
    final p = auth.profile;

    return RefreshIndicator(
      onRefresh: auth.refreshProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: lunar.tileBackground,
                child: p == null
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        initialsFor(p),
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: lunar.iconMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p == null ? '…' : displayName(p),
                      style:
                          t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      p?.email ?? '',
                      style: t.bodySmall?.copyWith(color: lunar.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabel(p?.role ?? '—').toUpperCase(),
                        style: t.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (p != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Status · ${p.status}',
                        style: t.bodySmall?.copyWith(color: lunar.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: 20),
            _DetailsCard(profile: p, lunar: lunar),
          ],
          const SizedBox(height: 20),
          _ProfileTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Shift swap request',
            onTap: () =>
                Navigator.of(context).pushNamed(ShiftSwapScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.event_busy_outlined,
            label: 'Leave request',
            onTap: () =>
                Navigator.of(context).pushNamed(LeaveRequestScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.badge_outlined,
            label: 'Training',
            onTap: () => Navigator.of(context).pushNamed(TrainingScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            label: 'Payslips',
            onTap: () => Navigator.of(context).pushNamed(PayslipsScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.notifications_outlined,
            label: 'Alerts & SOS test',
            onTap: () =>
                Navigator.of(context).pushNamed(AlertsSosScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.battery_charging_full_rounded,
            label: 'Tracking & battery',
            onTap: () =>
                Navigator.of(context).pushNamed(TrackingSettingsScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.storage_rounded,
            label: 'Offline queue',
            onTap: () =>
                Navigator.of(context).pushNamed(OfflineQueueScreen.routeName),
          ),
          _ProfileTile(
            icon: Icons.policy_outlined,
            label: 'Privacy & data',
            onTap: () =>
                Navigator.of(context).pushNamed(PrivacyDataScreen.routeName),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    await context.read<AuthController>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          LoginScreen.routeName, (r) => false);
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: lunar.mutedText,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(Icons.logout_rounded,
                color: AppColors.danger.withValues(alpha: 0.9)),
            label: Text('Sign out',
                style:
                    TextStyle(color: AppColors.danger.withValues(alpha: 0.95))),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile, required this.lunar});

  final UserProfile profile;
  final LunarThemeColors lunar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = profile;
    final siaDays = daysUntilSiaExpiry(p);
    String? siaBanner;
    Color? siaColor;
    if (siaDays != null) {
      if (siaDays < 0) {
        siaBanner = 'SIA licence expired';
        siaColor = AppColors.danger;
      } else if (siaDays <= 30) {
        siaBanner = 'SIA expires in $siaDays day${siaDays == 1 ? '' : 's'}';
        siaColor = AppColors.warning;
      }
    }

    return Material(
      color: lunar.tileBackground,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your details',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (siaBanner != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (siaColor ?? AppColors.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: (siaColor ?? AppColors.warning).withValues(alpha: 0.4)),
                ),
                child: Text(
                  siaBanner,
                  style: t.bodySmall?.copyWith(
                    color: siaColor ?? AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _DetailRow(label: 'Phone', value: p.phone?.trim().isNotEmpty == true ? p.phone! : '—'),
            _DetailRow(
              label: 'SIA number',
              value: p.siaNumber?.trim().isNotEmpty == true ? p.siaNumber! : '—',
            ),
            _DetailRow(
              label: 'SIA type',
              value: p.siaType?.trim().isNotEmpty == true ? p.siaType! : '—',
            ),
            _DetailRow(
              label: 'SIA expiry',
              value: formatUkDate(p.siaExpiryDate),
            ),
            if (p.payRatePenceHour != null)
              _DetailRow(
                label: 'Pay rate',
                value: formatPayRatePence(p.payRatePenceHour),
              ),
            if (p.twoFactorEnabled)
              _DetailRow(label: '2FA', value: 'Enabled'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: t.bodySmall?.copyWith(color: lunar.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                Icon(icon, color: lunar.iconMuted, size: 22),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: t.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500))),
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
