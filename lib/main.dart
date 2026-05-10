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
import 'features/shell/telemetry_controller.dart';
import 'features/shift/leave_controller.dart';
import 'features/shift/shift_controller.dart';
import 'services/local_notification_service.dart';
import 'theme/app_colors.dart';

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
      ],
      child: const LunarSecurityApp(),
    ),
  );
}
