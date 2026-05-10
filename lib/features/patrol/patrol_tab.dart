import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import 'patrol_controller.dart';

class PatrolTab extends StatefulWidget {
  const PatrolTab({super.key});

  @override
  State<PatrolTab> createState() => _PatrolTabState();
}

class _PatrolTabState extends State<PatrolTab> {
  final _checkpointCtrl = TextEditingController();

  Future<void> _openScanner() async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 360,
          child: MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
              if (code == null || code.isEmpty) return;
              Navigator.of(ctx).pop(code);
            },
          ),
        ),
      ),
    );
    if (!mounted || scanned == null) return;
    _checkpointCtrl.text = scanned.trim();
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
  void dispose() {
    _checkpointCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final patrol = context.watch<PatrolController>();

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
              border: Border.all(color: AppColors.outline, width: 2),
              color: AppColors.surface,
            ),
            child: CustomPaint(
              painter: _ScanFramePainter(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.silver.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text(
                      'Scan checkpoint QR',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Camera + barcode scanner will mount here. Duplicate scans blocked via client message id.',
                        textAlign: TextAlign.center,
                        style: t.bodySmall?.copyWith(color: AppColors.silverMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          const SizedBox(height: 20),
          TextField(
            controller: _checkpointCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Checkpoint ID',
              hintText: 'Enter numeric checkpoint ID or scan QR',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
          onPressed: patrol.loading ? null : _openScanner,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.surfaceElevated,
          ),
          icon: const Icon(Icons.center_focus_strong_rounded),
          label: const Text('Open live QR scanner'),
        ),
        const SizedBox(height: 10),
          FilledButton.icon(
          onPressed: patrol.loading
              ? null
              : () async {
                  final id = int.tryParse(_checkpointCtrl.text.trim());
                  if (id == null || id <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid checkpoint ID.')),
                    );
                    return;
                  }
                  final err = await context.read<PatrolController>().submitCheckpointId(id);
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  } else {
                    _checkpointCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkpoint scan submitted.')),
                    );
                  }
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Submit patrol scan'),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent scans', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (patrol.scans.isEmpty)
                  Text('No scans yet.', style: t.labelSmall?.copyWith(color: AppColors.silverMuted))
                else
                  ...patrol.scans.take(6).map(
                        (s) => _ScanTile(
                          label: '${s.checkpointLabel ?? 'Checkpoint #${s.checkpointId}'}'
                              '${s.siteName == null ? '' : ' · ${s.siteName}'}',
                          time: s.scannedAt?.toLocal().toString().substring(11, 16) ?? '--:--',
                          done: true,
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  patrol.error ?? 'Live data from /patrols/scans',
                  style: t.labelSmall?.copyWith(color: AppColors.silverMuted),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.label, required this.time, required this.done});

  final String label;
  final String time;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: done ? AppColors.success : AppColors.silverMuted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(time, style: t.labelSmall?.copyWith(color: AppColors.silverMuted)),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.silver.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(24, 24, size.width - 48, size.height - 48),
      const Radius.circular(12),
    );
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
