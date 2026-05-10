import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showVisualLogReminder(String body) async {
    await _plugin.show(
      id: 2001,
      title: 'Hourly visual log due',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'visual_log_cadence',
          'Visual log reminders',
          channelDescription:
              'Reminds guards to submit hourly all-clear visual logs.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
