import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../shell/offline_queue_controller.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  static const routeName = '/profile/offline-queue';

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OfflineQueueController>().refresh();
    });
  }

  String _labelForType(String type) {
    switch (type) {
      case 'patrol_scan':
        return 'Patrol scan';
      case 'telemetry_gps':
        return 'GPS telemetry';
      case 'sos':
        return 'SOS';
      case 'incident':
        return 'Incident report';
      case 'visual_log':
        return 'Visual log';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final queue = context.watch<OfflineQueueController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline queue'),
        actions: lunarAppBarActions,
      ),
      body: RefreshIndicator(
        onRefresh: queue.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Actions saved on this device when the network was unavailable. '
              'They sync automatically when connectivity returns.',
              style: t.bodyMedium?.copyWith(color: lunar.mutedText, height: 1.45),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${queue.pending} pending',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton(
                  onPressed: queue.syncing || queue.pending == 0
                      ? null
                      : () async {
                          final synced = await queue.flush();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                synced > 0
                                    ? 'Synced $synced item(s).'
                                    : 'Nothing synced — check errors below.',
                              ),
                            ),
                          );
                        },
                  child: queue.syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sync now'),
                ),
              ],
            ),
            if (queue.error != null) ...[
              const SizedBox(height: 8),
              Text(queue.error!,
                  style: t.bodySmall?.copyWith(color: AppColors.warning)),
            ],
            if (queue.lastSyncedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: ${queue.lastSyncedAt!.toLocal().toString().substring(0, 16)}',
                style: t.bodySmall?.copyWith(color: lunar.mutedText),
              ),
            ],
            const SizedBox(height: 16),
            if (queue.items.isEmpty)
              LunarSurface(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Queue is empty.',
                  style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                ),
              )
            else
              ...queue.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LunarSurface(
                    child: ListTile(
                      title: Text(_labelForType(item.type)),
                      subtitle: Text(
                        [
                          'Queued ${item.createdAt.toLocal().toString().substring(0, 16)}',
                          if (item.attempts > 0) 'Attempts: ${item.attempts}',
                          if (item.lastError != null) item.lastError!,
                        ].join('\n'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: lunar.mutedText),
                      ),
                    ),
                  ),
                ),
              ),
            if (queue.history.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Recent activity',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...queue.history.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
