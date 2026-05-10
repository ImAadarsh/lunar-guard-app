import 'package:flutter/material.dart';

import 'features/auth/login_screen.dart';
import 'features/shell/guard_shell.dart';
import 'features/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class LunarSecurityApp extends StatelessWidget {
  const LunarSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunar Security',
      debugShowCheckedModeBanner: false,
      theme: buildLunarTheme(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        GuardShell.routeName: (_) => const GuardShell(),
      },
    );
  }
}
