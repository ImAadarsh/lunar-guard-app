import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/profile/alerts_sos_screen.dart';
import 'features/profile/leave_request_screen.dart';
import 'features/profile/offline_queue_screen.dart';
import 'features/profile/payslips_screen.dart';
import 'features/profile/privacy_data_screen.dart';
import 'features/profile/shift_swap_screen.dart';
import 'features/profile/tracking_settings_screen.dart';
import 'features/profile/training_screen.dart';
import 'features/shell/guard_shell.dart';
import 'features/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class LunarSecurityApp extends StatelessWidget {
  const LunarSecurityApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lunar Security',
      debugShowCheckedModeBanner: false,
      theme: buildLunarLightTheme(),
      darkTheme: buildLunarTheme(),
      themeMode: themeController.mode,
      themeAnimationDuration: const Duration(milliseconds: 420),
      themeAnimationCurve: Curves.easeInOutCubic,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        GuardShell.routeName: (_) => const GuardShell(),
        TrainingScreen.routeName: (_) => const TrainingScreen(),
        PayslipsScreen.routeName: (_) => const PayslipsScreen(),
        TrackingSettingsScreen.routeName: (_) => const TrackingSettingsScreen(),
        AlertsSosScreen.routeName: (_) => const AlertsSosScreen(),
        OfflineQueueScreen.routeName: (_) => const OfflineQueueScreen(),
        PrivacyDataScreen.routeName: (_) => const PrivacyDataScreen(),
        ShiftSwapScreen.routeName: (_) => const ShiftSwapScreen(),
        LeaveRequestScreen.routeName: (_) => const LeaveRequestScreen(),
      },
    );
  }
}
