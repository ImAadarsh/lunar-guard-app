import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/device_position.dart';
import '../../services/device_location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../shell/offline_queue_controller.dart';
import 'patrol_controller.dart';

class PatrolTab extends StatefulWidget {
  const PatrolTab({super.key});

  @override
  State<PatrolTab> createState() => _PatrolTabState();
}

class _PatrolTabState extends State<PatrolTab> {
  final _location = DeviceLocationService();
  bool _scanning = false;

  Future<void> _submitScan(String raw) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final patrolController = context.read<PatrolController>();
    final queueController = context.read<OfflineQueueController>();
    DevicePosition position;
    try {
      position = await _location.getCurrentPosition();
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }
    final err = await patrolController.submitQrCode(
      raw,
      position: position,
    );
    await queueController.refresh();
    if (!mounted) return;
    setState(() => _scanning = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkpoint scan submitted.')),
      );
    }
  }

  Future<void> _openScanner() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'Scan checkpoint QR',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final code = capture.barcodes.isNotEmpty
                            ? capture.barcodes.first.rawValue
                            : null;
                        if (code == null || code.isEmpty) return;
                        Navigator.of(ctx).pop(code);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Hold your device steady within 5m of the checkpoint. GPS accuracy must be ≤5m.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: ctx.lunar.mutedText,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || scanned == null) return;
    await _submitScan(scanned.trim());
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<PatrolController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final patrol = context.watch<PatrolController>();
    final schedule = patrol.patrolSchedule();

    return RefreshIndicator(
      onRefresh: patrol.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lunar.border, width: 2),
                color: lunar.scanPanelBackground,
              ),
              child: CustomPaint(
                painter: _ScanFramePainter(lunar.scanFrame),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          size: 72,
                          color: lunar.mutedText.withValues(alpha: 0.45)),
                      const SizedBox(height: 16),
                      Text(
                        'Scan checkpoint QR',
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Scan the QR at the checkpoint while you are within range. Check in to your shift first.',
                          textAlign: TextAlign.center,
                          style: t.bodySmall?.copyWith(
                              color: lunar.mutedText, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: patrol.loading || _scanning ? null : _openScanner,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _scanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner_rounded),
            label: Text(_scanning ? 'Submitting scan…' : 'Scan & submit'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mandatory patrol schedule',
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...schedule.map(
                    (item) => _ScheduleTile(
                      label: item['label'] ?? 'Checkpoint',
                      time: item['due'] ?? '--:--',
                      done: item['status'] != 'Due soon',
                      status: item['status'] ?? '',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recent scans',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (patrol.scans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No scans yet. Scan a checkpoint QR to record your patrol.',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ),
              ),
            )
          else
            ...patrol.scans.take(10).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentScanCard(
                      label: s.checkpointLabel ??
                          'Checkpoint #${s.checkpointId}',
                      site: s.siteName,
                      scannedAt: s.scannedAt,
                    ),
                  ),
                ),
          if (patrol.error != null) ...[
            const SizedBox(height: 8),
            Text(
              patrol.error!,
              style: t.labelSmall?.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.label,
    required this.time,
    required this.done,
    required this.status,
  });

  final String label;
  final String time;
  final bool done;
  final String status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 20,
            color: done ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodyMedium),
                if (status.isNotEmpty)
                  Text(
                    status,
                    style: t.labelSmall?.copyWith(color: lunar.mutedText),
                  ),
              ],
            ),
          ),
          Text(time,
              style: t.labelSmall?.copyWith(color: lunar.mutedText)),
        ],
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({
    required this.label,
    this.site,
    this.scannedAt,
  });

  final String label;
  final String? site;
  final DateTime? scannedAt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (site != null && site!.trim().isNotEmpty)
                    Text(
                      site!,
                      style: t.bodySmall?.copyWith(color: lunar.mutedText),
                    ),
                  if (scannedAt != null)
                    Text(
                      formatUkDateTime(scannedAt),
                      style: t.labelSmall?.copyWith(
                        color: lunar.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(24, 24, size.width - 48, size.height - 48),
      const Radius.circular(12),
    );
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
