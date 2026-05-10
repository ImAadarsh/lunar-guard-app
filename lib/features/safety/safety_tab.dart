import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/device_location_service.dart';
import '../../theme/app_colors.dart';
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
  String _category = 'theft';
  XFile? _picked;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final incidents = context.watch<IncidentController>();

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
                      final p = await _location.getCurrentLatLng();
                      final err = await controller.triggerSos(
                            lat: p.lat,
                            lng: p.lng,
                            message: 'SOS from guard app',
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err ?? 'SOS triggered successfully.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 32),
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
                            style: t.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Incident report', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                  decoration: const InputDecoration(labelText: 'Site ID'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'theft',
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'theft', child: Text('Theft')),
                    DropdownMenuItem(value: 'fire', child: Text('Fire')),
                    DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
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
                    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (!mounted) return;
                    setState(() => _picked = picked);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onDark,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(_picked == null ? 'Add photos / attachments' : 'Photo selected: ${_picked!.name}'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: incidents.loading
                      ? null
                      : () async {
                          final siteId = int.tryParse(_siteIdCtrl.text.trim());
                          if (siteId == null || siteId <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter a valid Site ID.')),
                            );
                            return;
                          }
                          final err = await context.read<IncidentController>().createIncident(
                                siteId: siteId,
                                category: _category,
                                title: _titleCtrl.text.trim(),
                                description: _descriptionCtrl.text.trim(),
                                photoPath: _picked?.path,
                                photoName: _picked?.name,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err ?? 'Incident submitted successfully.')),
                          );
                          if (err == null) {
                            _titleCtrl.clear();
                            _descriptionCtrl.clear();
                            setState(() => _picked = null);
                          }
                        },
                  child: const Text('Submit report'),
                ),
              ],
            ),
          ),
        ),
          const SizedBox(height: 18),
          Text('Recent incidents', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (incidents.incidents.isEmpty)
            Text('No incidents yet.', style: t.bodySmall?.copyWith(color: AppColors.silverMuted))
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
