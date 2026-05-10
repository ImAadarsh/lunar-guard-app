import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/device_location_service.dart';
import '../../theme/app_colors.dart';
import '../shell/offline_queue_controller.dart';
import '../shift/shift_controller.dart';
import 'incident_controller.dart';

class SafetyTab extends StatefulWidget {
  const SafetyTab({super.key});

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab> {
  final _location = DeviceLocationService();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _siteIdCtrl = TextEditingController(text: '1');
  final _visualNoteCtrl = TextEditingController();
  String _category = 'theft';
  XFile? _picked;
  final List<Map<String, String>> _attachments = [];
  XFile? _visualPicked;

  @override
  void initState() {
    super.initState();
    Future.microtask(context.read<IncidentController>().refresh);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _siteIdCtrl.dispose();
    _visualNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final incidents = context.watch<IncidentController>();
    final shifts = context.watch<ShiftController>();
    final activeShiftId = shifts.activeSession?.shiftId;
    int? activeSiteId;
    int? activeSessionId = shifts.activeSession?.id;
    if (activeShiftId != null) {
      for (final shift in shifts.shifts) {
        if (shift.id == activeShiftId) {
          activeSiteId = shift.siteId;
          break;
        }
      }
    }

    return RefreshIndicator(
      onRefresh: incidents.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: incidents.loading
                  ? null
                  : () async {
                      try {
                        final controller = context.read<IncidentController>();
                        final queueController =
                            context.read<OfflineQueueController>();
                        final p = await _location.getCurrentLatLng();
                        final err = await controller.triggerSos(
                          lat: p.lat,
                          lng: p.lng,
                          message: 'SOS from guard app',
                        );
                        await queueController.refresh();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(err ?? 'SOS triggered successfully.')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    },
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.danger.withValues(alpha: 0.95),
                      const Color(0xFF8B1313),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sosGlow.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emergency_share_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS — PANIC',
                              style: t.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Broadcasts emergency event to backend.',
                              style: t.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Hourly all-clear visual log',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (incidents.dueVisualLogs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: incidents.dueVisualLogs.take(4).map((log) {
                          return Chip(
                            label: Text(
                                '${log['status']} ${DateTime.tryParse(log['dueAt']?.toString() ?? '')?.toLocal().toString().substring(11, 16) ?? ''}'),
                          );
                        }).toList(),
                      ),
                    ),
                  Text(
                    activeSiteId == null
                        ? 'Check in to a shift to auto-bind visual logs to the active site.'
                        : 'Active site #$activeSiteId · visual log will be linked to command center.',
                    style: t.bodySmall?.copyWith(color: AppColors.silverMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _visualNoteCtrl,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'All-clear note'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                          source: ImageSource.camera, imageQuality: 85);
                      if (!mounted) return;
                      setState(() => _visualPicked = picked);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_visualPicked == null
                        ? 'Capture visual log photo'
                        : 'Photo selected: ${_visualPicked!.name}'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: incidents.loading ||
                            activeSiteId == null ||
                            _visualPicked == null
                        ? null
                        : () async {
                            final incidentController =
                                context.read<IncidentController>();
                            final queueController =
                                context.read<OfflineQueueController>();
                            final err =
                                await incidentController.submitVisualLog(
                              siteId: activeSiteId!,
                              attendanceSessionId: activeSessionId,
                              note: _visualNoteCtrl.text.trim(),
                              photoPath: _visualPicked!.path,
                              photoName: _visualPicked!.name,
                            );
                            await queueController.refresh();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(err ??
                                      'Visual log submitted successfully.')),
                            );
                            if (err == null) {
                              _visualNoteCtrl.clear();
                              setState(() => _visualPicked = null);
                            }
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit all-clear'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Incident report',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _siteIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Site ID',
                      helperText: activeSiteId == null
                          ? 'Manual fallback'
                          : 'Auto-filled from active shift: #$activeSiteId',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: 'theft',
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'theft', child: Text('Theft')),
                      DropdownMenuItem(value: 'fire', child: Text('Fire')),
                      DropdownMenuItem(
                          value: 'maintenance', child: Text('Maintenance')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'theft'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                          source: ImageSource.camera, imageQuality: 85);
                      if (!mounted) return;
                      setState(() => _picked = picked);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onDark,
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(_picked == null
                        ? 'Add photos / attachments'
                        : 'Photo selected: ${_picked!.name}'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        allowMultiple: true,
                        type: FileType.any,
                      );
                      if (result == null || !mounted) return;
                      setState(() {
                        _attachments
                          ..clear()
                          ..addAll(result.files
                              .where((file) => file.path != null)
                              .map((file) => {
                                    'path': file.path!,
                                    'name': file.name,
                                  }));
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onDark,
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_attachments.isEmpty
                        ? 'Attach videos/documents'
                        : '${_attachments.length} attachment(s) selected'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: incidents.loading
                        ? null
                        : () async {
                            final incidentController =
                                context.read<IncidentController>();
                            final queueController =
                                context.read<OfflineQueueController>();
                            final siteId = activeSiteId ??
                                int.tryParse(_siteIdCtrl.text.trim());
                            if (siteId == null || siteId <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter a valid Site ID.')),
                              );
                              return;
                            }
                            final err = await incidentController.createIncident(
                              siteId: siteId,
                              category: _category,
                              title: _titleCtrl.text.trim(),
                              description: _descriptionCtrl.text.trim(),
                              photoPath: _picked?.path,
                              photoName: _picked?.name,
                              attachments: _attachments,
                              shiftId: activeShiftId,
                              attendanceSessionId: activeSessionId,
                            );
                            await queueController.refresh();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(err ??
                                      'Incident submitted successfully.')),
                            );
                            if (err == null) {
                              _titleCtrl.clear();
                              _descriptionCtrl.clear();
                              setState(() {
                                _picked = null;
                                _attachments.clear();
                              });
                            }
                          },
                    child: const Text('Submit report'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Recent incidents',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (incidents.incidents.isEmpty)
            Text('No incidents yet.',
                style: t.bodySmall?.copyWith(color: AppColors.silverMuted))
          else
            ...incidents.incidents.take(5).map(
                  (i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.title),
                    subtitle: Text('Site ${i.siteId} · ${i.status}'),
                    trailing: Text(i.category),
                  ),
                ),
          if (incidents.error != null)
            Text(
              incidents.error!,
              style: t.bodySmall?.copyWith(color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}
