import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/device_location_service.dart';
import '../../services/local_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../safety/incident_controller.dart';
import '../shell/notifications_controller.dart';
import '../shell/offline_queue_controller.dart';

class AlertsSosScreen extends StatefulWidget {
  const AlertsSosScreen({super.key});

  static const routeName = '/profile/alerts-sos';

  @override
  State<AlertsSosScreen> createState() => _AlertsSosScreenState();
}

class _AlertsSosScreenState extends State<AlertsSosScreen> {
  final _location = DeviceLocationService();
  bool _sosBusy = false;

  Future<void> _runSosTest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test SOS'),
        content: const Text(
          'This sends a real SOS alert to the command center with your current GPS. '
          'Only use for testing when your manager expects it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Send test SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sosBusy = true);
    final incidents = context.read<IncidentController>();
    final queue = context.read<OfflineQueueController>();
    try {
      final p = await _location.getCurrentLatLng();
      if (!mounted) return;
      final err = await incidents.triggerSos(
        lat: p.lat,
        lng: p.lng,
        message: 'SOS test from guard app profile',
      );
      await queue.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Test SOS sent successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sosBusy = false);
    }
  }

  Future<void> _testNotification() async {
    await LocalNotificationService.showVisualLogReminder(
      'Test alert — notifications are working on this device.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification shown.')),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationsController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final notifications = context.watch<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & SOS test'),
        actions: lunarAppBarActions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Verify push-style reminders and emergency SOS reach operations.',
            style: t.bodyMedium?.copyWith(color: lunar.mutedText, height: 1.45),
          ),
          const SizedBox(height: 20),
          LunarSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('In-app alerts',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Unread: ${notifications.unreadCount}',
                  style: t.bodyMedium,
                ),
                if (notifications.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    notifications.error!,
                    style: t.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: notifications.items.isEmpty
                      ? null
                      : () async {
                          await notifications.markAllRead();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('All alerts marked read.')),
                          );
                        },
                  child: const Text('Mark all alerts read'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Show test notification'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sosBusy ? null : _runSosTest,
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            icon: _sosBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sos_rounded),
            label: Text(_sosBusy ? 'Sending…' : 'Send test SOS'),
          ),
        ],
      ),
    );
  }
}
