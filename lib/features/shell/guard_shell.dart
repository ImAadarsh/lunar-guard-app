import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../../widgets/shift_calendar_header_button.dart';
import '../../widgets/status_chip.dart';
import '../home/dashboard_tab.dart';
import '../home/home_controller.dart';
import '../patrol/patrol_tab.dart';
import '../patrol/patrol_controller.dart';
import '../profile/profile_tab.dart';
import '../safety/safety_tab.dart';
import '../safety/incident_controller.dart';
import 'notifications_controller.dart';
import 'offline_queue_controller.dart';
import 'shell_navigation_controller.dart';
import 'telemetry_controller.dart';
import '../shift/shift_tab.dart';
import '../shift/shift_controller.dart';

class GuardShell extends StatefulWidget {
  const GuardShell({super.key});

  static const routeName = '/guard';

  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell> {
  int _index = 0;
  ShiftController? _shiftController;
  ShellNavigationController? _navController;

  static const _titles = [
    'Operations',
    'My shift',
    'Patrol',
    'Safety',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationsController>().startPolling();
      context.read<OfflineQueueController>().refresh();
      _shiftController = context.read<ShiftController>()
        ..addListener(_syncTelemetryState);
      _navController = context.read<ShellNavigationController>()
        ..addListener(_onNavChanged);
      _syncTelemetryState();
    });
  }

  void _onNavChanged() {
    if (!mounted || _navController == null) return;
    setState(() => _index = _navController!.selectedIndex);
  }

  @override
  void dispose() {
    _shiftController?.removeListener(_syncTelemetryState);
    _navController?.removeListener(_onNavChanged);
    context.read<NotificationsController>().stopPolling();
    context.read<TelemetryController>().stop();
    super.dispose();
  }

  void _syncTelemetryState() {
    if (!mounted) return;
    final activeShiftId = _shiftController?.activeSession?.shiftId;
    context.read<TelemetryController>().updateActiveShift(activeShiftId);
  }

  String _notificationTypeLabel(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  Future<void> _openNotifications() async {
    final notifications = context.read<NotificationsController>();
    await notifications.refresh();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer<NotificationsController>(
          builder: (_, n, __) {
            final t = Theme.of(ctx).textTheme;
            final lunar = ctx.lunar;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Notifications',
                            style: t.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (n.unreadCount > 0)
                          TextButton(
                            onPressed: () => n.markAllRead(),
                            child: const Text('Mark all read'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (n.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No notifications yet.',
                            style: t.bodyMedium
                                ?.copyWith(color: lunar.mutedText),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: n.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _NotificationCard(
                            item: n.items[i],
                            typeLabel: _notificationTypeLabel(n.items[i].type),
                            onMarkRead: () => n.markRead(n.items[i].id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSyncStatus() async {
    final offline = context.read<OfflineQueueController>();
    final synced = await offline.flush();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => Consumer<OfflineQueueController>(
        builder: (_, queue, __) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offline sync',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    'Pending: ${queue.pending} • Replayed now: $synced${queue.lastSyncedAt == null ? '' : ' • Last sync ${queue.lastSyncedAt!.toLocal().toString().substring(11, 16)}'}'),
                if (queue.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(queue.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                ...queue.history.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(entry,
                          style: Theme.of(context).textTheme.bodySmall),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsController>();
    final queue = context.watch<OfflineQueueController>();
    final telemetry = context.watch<TelemetryController>();
    return Scaffold(
      appBar: AppBar(
        leading: _index == 0 ? const ShiftCalendarHeaderButton() : null,
        automaticallyImplyLeading: _index != 0,
        leadingWidth: _index == 0 ? 48 : null,
        title: Text(_titles[_index]),
        actions: [
          ...lunarAppBarActions,
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: Badge(
              label: Text('${notifications.unreadCount}'),
              isLabelVisible: notifications.unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Sync status',
            onPressed: () async {
              await Future.wait([
                context.read<HomeController>().refresh(),
                context.read<ShiftController>().refresh(),
                context.read<PatrolController>().refresh(),
                context.read<IncidentController>().refresh(),
                context.read<NotificationsController>().refresh(),
              ]);
              if (!context.mounted) return;
              await _openSyncStatus();
            },
            icon: Badge(
              isLabelVisible: queue.pending > 0,
              label: Text('${queue.pending}'),
              child: const Icon(Icons.sync_rounded),
            ),
          ),
        ],
        bottom: telemetry.running
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: Colors.black.withValues(alpha: 0.18),
                  child: Text(
                    telemetry.lastSentAt == null
                        ? 'Active telemetry started'
                        : 'Telemetry last sent ${telemetry.lastSentAt!.toLocal().toString().substring(11, 16)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          ShiftTab(),
          PatrolTab(),
          SafetyTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          context.read<ShellNavigationController>().goToTab(i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Shift',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Patrol',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Safety',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.typeLabel,
    required this.onMarkRead,
  });

  final AppNotification item;
  final String typeLabel;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(
                            label: typeLabel,
                            tone: item.isRead
                                ? StatusTone.neutral
                                : StatusTone.warning,
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.createdAt != null)
                  Text(
                    formatUkDateTime(item.createdAt),
                    style: t.labelSmall?.copyWith(
                      color: lunar.mutedText,
                    ),
                  ),
              ],
            ),
            if (item.body != null && item.body!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.body!,
                style: t.bodySmall?.copyWith(
                  color: lunar.mutedText,
                  height: 1.4,
                ),
              ),
            ],
            if (!item.isRead) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onMarkRead,
                  child: const Text('Mark as read'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
