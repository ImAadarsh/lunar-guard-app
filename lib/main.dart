import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'auth/auth_controller.dart';
import 'features/home/home_controller.dart';
import 'features/patrol/patrol_controller.dart';
import 'features/safety/incident_controller.dart';
import 'features/shell/notifications_controller.dart';
import 'features/shell/offline_queue_controller.dart';
import 'features/shell/shell_navigation_controller.dart';
import 'features/shell/telemetry_controller.dart';
import 'features/shift/leave_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/shift/shift_controller.dart';
import 'services/api_client.dart';
import 'services/local_notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final auth = AuthController();
  final themeController = ThemeController();
  await themeController.init();
  final navigatorKey = GlobalKey<NavigatorState>();
  ApiClient.onTokensRefreshed = auth.applyRefreshedTokens;
  ApiClient.onSessionExpired = () async {
    await auth.handleSessionExpired();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (_) => false,
    );
  };
  await auth.init();
  await LocalNotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => ShiftController()),
        ChangeNotifierProvider(create: (_) => LeaveController()),
        ChangeNotifierProvider(create: (_) => PatrolController()),
        ChangeNotifierProvider(create: (_) => IncidentController()),
        ChangeNotifierProvider(create: (_) => NotificationsController()),
        ChangeNotifierProvider(create: (_) => OfflineQueueController()),
        ChangeNotifierProvider(create: (_) => TelemetryController()),
        ChangeNotifierProvider(create: (_) => ShellNavigationController()),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: LunarSecurityApp(navigatorKey: navigatorKey),
    ),
  );
}
