import 'package:flutter/material.dart';

import '../../models/incident_report.dart';
import '../../services/api_client.dart';
import '../../services/incidents_api.dart';
import '../../services/secure_token_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../../utils/format_datetime.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final int incidentId;

  static const routeName = '/safety/incident';

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  bool _loading = true;
  String? _error;
  IncidentReport? _incident;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api =
          IncidentsApi(ApiClient.createAuthorized(SecureTokenStore()));
      final data = await api.getIncident(widget.incidentId);
      if (!mounted) return;
      setState(() {
        _incident = IncidentReport.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final inc = _incident;
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident #${widget.incidentId}'),
        actions: lunarAppBarActions,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: t.bodyMedium
                                ?.copyWith(color: AppColors.warning)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : inc == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        children: [
                          _InfoRow(label: 'Title', value: inc.title),
                          _InfoRow(label: 'Category', value: inc.category),
                          _InfoRow(label: 'Status', value: inc.status),
                          _InfoRow(label: 'Site', value: 'Site #${inc.siteId}'),
                          if (inc.createdAt != null)
                            _InfoRow(
                              label: 'Reported',
                              value: formatUkDateTime(inc.createdAt),
                            ),
                          const SizedBox(height: 16),
                          Text('Description',
                              style: t.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            inc.description?.trim().isNotEmpty == true
                                ? inc.description!.trim()
                                : 'No description provided.',
                            style: t.bodyMedium,
                          ),
                          if (inc.attachments.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Attachments',
                                style: t.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...inc.attachments.map(
                              (a) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.attach_file),
                                title: Text(a.kind ?? 'Attachment'),
                                subtitle: Text(a.publicUrl ?? a.storageKey),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: t.bodySmall?.copyWith(color: lunar.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
