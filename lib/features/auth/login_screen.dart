import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../shell/guard_shell.dart';
import '../shell/offline_queue_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: '');
  final _password = TextEditingController(text: '');
  final _totp = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _totp.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final auth = context.read<AuthController>();
    final err = await auth.signInWithPassword(_email.text, _password.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (auth.needsTwoFactor) return;
    await _biometricGateThenOpen();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      try {
        context.read<OfflineQueueController>().refresh();
      } on ProviderNotFoundException {
        // Some widget tests mount LoginScreen without the full app provider tree.
      }
    });
  }

  Future<void> _submit2fa() async {
    final auth = context.read<AuthController>();
    final err = await auth.completeTwoFactor(_totp.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _biometricGateThenOpen();
  }

  Future<void> _biometricGateThenOpen() async {
    final auth = context.read<AuthController>();
    final gateErr = await auth.requireBiometricUnlock();
    if (!mounted) return;
    if (gateErr != null) {
      await auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gateErr)),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(GuardShell.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final lunar = context.lunar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthController>();
    OfflineQueueController? queue;
    try {
      queue = context.watch<OfflineQueueController>();
    } on ProviderNotFoundException {
      queue = null;
    }
    final loading = auth.busy;
    final needs2fa = auth.needsTwoFactor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppColors.primaryDark,
                    Color(0xFF0D2E3A),
                    AppColors.primaryDark,
                  ]
                : [
                    cs.surface,
                    const Color(0xFFE8F4F8),
                    cs.surfaceContainerHighest,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Align(
                  child: Image.asset(
                    'assets/images/logo_without_bg.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LUNAR SECURITY',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Guard sign in',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Work email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  enabled: !needs2fa,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (needs2fa) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _totp,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Authenticator code',
                      hintText: '6-digit code',
                      prefixIcon: Icon(Icons.security_rounded),
                      counterText: '',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: needs2fa ? null : () {},
                    child: Text(
                      'Forgot password?',
                      style: t.labelLarge?.copyWith(color: lunar.linkColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: loading ? null : (needs2fa ? _submit2fa : _signIn),
                  child: loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(needs2fa ? 'Verify & sign in' : 'Sign in'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: lunar.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Low-connectivity mode',
                        style:
                            t.labelSmall?.copyWith(color: lunar.mutedText),
                      ),
                    ),
                    Expanded(child: Divider(color: lunar.border)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: queue == null || queue.syncing
                      ? null
                      : () async {
                          final synced = await queue!.flush();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pending ${queue.pending}. Synced $synced queued actions.',
                              ),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.cloud_off_outlined, size: 20),
                  label: Text(
                    queue == null
                        ? 'Queue status (offline)'
                        : queue.pending == 0
                            ? 'Queue status: empty'
                            : 'Queue status: ${queue.pending} pending',
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Session uses secure storage and JWT against the Lunar Security API.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: lunar.mutedText),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: const LunarThemeToggle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
