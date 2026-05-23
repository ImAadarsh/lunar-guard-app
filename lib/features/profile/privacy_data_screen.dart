import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../auth/login_screen.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  static const routeName = '/profile/privacy';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final auth = context.watch<AuthController>();
    final email = auth.profile?.email ?? 'your account';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & data'),
        actions: lunarAppBarActions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'How Lunar Security uses your data while you are on duty.',
            style: t.bodyMedium?.copyWith(color: lunar.mutedText, height: 1.45),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Location',
            body:
                'GPS is collected during active shifts for attendance, patrol verification, '
                'SOS, incidents, and command-center safety monitoring. Background location '
                'runs only while you are checked in.',
          ),
          const _Section(
            title: 'Photos & files',
            body:
                'Images and documents you attach to incidents or visual logs are uploaded '
                'to secure storage and linked to your user account.',
          ),
          const _Section(
            title: 'Offline queue',
            body:
                'If the network fails, certain actions are stored on this device and sent '
                'when connectivity returns. You can review the queue under Profile → Offline queue.',
          ),
          _Section(
            title: 'Your account',
            body:
                'Signed in as $email. Profile and licence details are managed by your employer. '
                'Contact your manager to correct payroll, training, or personal records.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        LoginScreen.routeName,
                        (r) => false,
                      );
                    }
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out on this device'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LunarSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              body,
              style: t.bodyMedium?.copyWith(
                color: lunar.mutedText,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
