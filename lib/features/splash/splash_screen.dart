import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../shell/guard_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.65, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      var next = LoginScreen.routeName;
      if (auth.isAuthenticated) {
        final gateErr = await auth.requireBiometricUnlock();
        if (!mounted) return;
        if (gateErr == null) {
          next = GuardShell.routeName;
        } else {
          await auth.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(gateErr)));
        }
      }
      Navigator.of(context).pushReplacementNamed(next);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F3A4A),
              AppColors.primaryDark,
              Color(0xFF050F14),
            ],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_full.jpeg',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'FIELD OPERATIONS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 4,
                            color: AppColors.silverMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.silver.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
