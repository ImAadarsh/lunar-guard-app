import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    final local = email.split('@').first;
    if (local.length >= 2) return local.substring(0, 2).toUpperCase();
    return local.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();
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
                backgroundColor: AppColors.surfaceElevated,
                child: p == null
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _initials(p.email),
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.silver,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.email.split('@').first ?? '…',
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      p?.email ?? '',
                      style: t.bodySmall?.copyWith(color: AppColors.silverMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ROLE · ${(p?.role ?? '—').toUpperCase()}',
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
                        style: t.bodySmall?.copyWith(color: AppColors.silverMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ProfileTile(icon: Icons.badge_outlined, label: 'Certifications', onTap: () {}),
          _ProfileTile(icon: Icons.notifications_outlined, label: 'Alerts & SOS test', onTap: () {}),
          _ProfileTile(icon: Icons.battery_charging_full_rounded, label: 'Tracking & battery', onTap: () {}),
          _ProfileTile(icon: Icons.storage_rounded, label: 'Offline queue', onTap: () {}),
          _ProfileTile(icon: Icons.policy_outlined, label: 'Privacy & data', onTap: () {}),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    await context.read<AuthController>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (r) => false);
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.silverMuted,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(Icons.logout_rounded, color: AppColors.danger.withValues(alpha: 0.9)),
            label: Text('Sign out', style: TextStyle(color: AppColors.danger.withValues(alpha: 0.95))),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                Icon(icon, color: AppColors.silver, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
                Icon(Icons.chevron_right_rounded, color: AppColors.silverMuted.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
