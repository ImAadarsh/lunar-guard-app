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
    });
  }

  @override
  void dispose() {
    context.read<NotificationsController>().stopPolling();
    super.dispose();
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
                      const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsController>();
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
              final home = context.read<HomeController>();
              final shift = context.read<ShiftController>();
              final patrol = context.read<PatrolController>();
              final incidents = context.read<IncidentController>();
              final notes = context.read<NotificationsController>();
              await home.refresh();
              await shift.refresh();
              await patrol.refresh();
              await incidents.refresh();
              await notes.refresh();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synced with backend')),
              );
            },
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
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
