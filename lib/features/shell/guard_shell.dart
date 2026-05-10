import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/dashboard_tab.dart';
import '../home/home_controller.dart';
import '../patrol/patrol_tab.dart';
import '../patrol/patrol_controller.dart';
import '../profile/profile_tab.dart';
import '../safety/safety_tab.dart';
import '../safety/incident_controller.dart';
import 'notifications_controller.dart';
import 'offline_queue_controller.dart';
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
      _syncTelemetryState();
    });
  }

  @override
  void dispose() {
    _shiftController?.removeListener(_syncTelemetryState);
    context.read<NotificationsController>().stopPolling();
    context.read<TelemetryController>().stop();
    super.dispose();
  }

  void _syncTelemetryState() {
    if (!mounted) return;
    final activeShiftId = _shiftController?.activeSession?.shiftId;
    context.read<TelemetryController>().updateActiveShift(activeShiftId);
  }

  Future<void> _openNotifications() async {
    final notifications = context.read<NotificationsController>();
    await notifications.refresh();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer<NotificationsController>(
          builder: (_, n, __) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => n.markAllRead(),
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: n.items
                          .map(
                            (it) => ListTile(
                              dense: true,
                              title: Text(it.title),
                              subtitle: Text(it.body ?? it.type),
                              trailing: it.isRead
                                  ? const Icon(Icons.done_all, size: 18)
                                  : TextButton(
                                      onPressed: () => n.markRead(it.id),
                                      child: const Text('Read'),
                                    ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        title: Text(_titles[_index]),
        actions: [
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
        onDestinationSelected: (i) => setState(() => _index = i),
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
