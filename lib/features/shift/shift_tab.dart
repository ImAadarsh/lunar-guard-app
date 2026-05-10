import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../services/device_location_service.dart';
import '../../theme/app_colors.dart';
import 'leave_controller.dart';
import 'shift_controller.dart';

class ShiftTab extends StatefulWidget {
  const ShiftTab({super.key});

  @override
  State<ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<ShiftTab> {
  final _location = DeviceLocationService();
  final _leaveReason = TextEditingController();
  String _leaveType = 'annual';
  DateTime? _leaveStart;
  DateTime? _leaveEnd;
  String? _geofenceHint;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShiftController>().refresh();
      context.read<LeaveController>().refresh();
    });
  }

  @override
  void dispose() {
    _leaveReason.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    final c = context.read<ShiftController>();
    try {
      final p = await _location.getCurrentLatLng();
      final shift = c.nextShift;
      if (shift != null) {
        setState(() {
          _geofenceHint = c.geofenceHintFor(shift, lat: p.lat, lng: p.lng);
        });
      }
      final err = await c.checkIn(lat: p.lat, lng: p.lng);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _previewGeofence() async {
    final c = context.read<ShiftController>();
    final shift = c.nextShift;
    if (shift == null) return;
    try {
      final p = await _location.getCurrentLatLng();
      if (!mounted) return;
      setState(() {
        _geofenceHint = c.geofenceHintFor(shift, lat: p.lat, lng: p.lng);
      });
    } catch (_) {
      setState(() {
        _geofenceHint = c.geofenceHintFor(shift);
      });
    }
  }

  Future<void> _checkOut() async {
    final c = context.read<ShiftController>();
    try {
      final p = await _location.getCurrentLatLng();
      final err = await c.checkOut(lat: p.lat, lng: p.lng);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickLeaveDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          start ? (_leaveStart ?? now) : (_leaveEnd ?? _leaveStart ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _leaveStart = picked;
      } else {
        _leaveEnd = picked;
      }
    });
  }

  Future<void> _submitLeave() async {
    if (_leaveStart == null || _leaveEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select leave start and end date.')),
      );
      return;
    }
    final leave = context.read<LeaveController>();
    final err = await leave.submit(
      leaveType: _leaveType,
      startDate: _leaveStart!.toIso8601String().substring(0, 10),
      endDate: _leaveEnd!.toIso8601String().substring(0, 10),
      reason: _leaveReason.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() {
      _leaveReason.clear();
      _leaveStart = null;
      _leaveEnd = null;
      _leaveType = 'annual';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Leave request submitted for manager approval.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.watch<ShiftController>();
    final leave = context.watch<LeaveController>();
    final shiftCards = c.shifts.take(5).map((s) {
      final starts = s.startsAt?.toLocal();
      final ends = s.endsAt?.toLocal();
      return _ShiftCard(
        site: 'Site #${s.siteId}',
        window: starts == null || ends == null
            ? 'Time TBD'
            : '${starts.toString().substring(0, 16)} – ${ends.toString().substring(11, 16)}',
        role: 'Shift #${s.id}',
        state:
            s.status == 'completed' ? _ShiftState.done : _ShiftState.upcoming,
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await c.refresh();
        await leave.refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'My shifts',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (shiftCards.isEmpty)
            Text('No shifts available.',
                style: t.bodySmall?.copyWith(color: AppColors.silverMuted))
          else
            ...shiftCards.expand((w) => [w, const SizedBox(height: 12)]),
          const SizedBox(height: 12),
          Text(
            'Attendance',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar,
                          color: AppColors.success.withValues(alpha: 0.9)),
                      const SizedBox(width: 10),
                      Text(
                        c.activeSession == null
                            ? 'Not checked in'
                            : 'Active session #${c.activeSession!.id}',
                        style:
                            t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.error ??
                        _geofenceHint ??
                        (c.nextShift == null
                            ? 'One-tap check-in uses live GPS and backend geofence validation.'
                            : c.geofenceHintFor(c.nextShift!)),
                    style: t.bodySmall
                        ?.copyWith(color: AppColors.silverMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: c.loading ? null : _checkIn,
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Check-in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: c.loading ? null : _checkOut,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onDark,
                            side: const BorderSide(color: AppColors.outline),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Check-out'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: c.loading ? null : _previewGeofence,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Preview geofence with current GPS'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Map preview',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (ApiConfig.googleMapsApiKey.isEmpty)
            Text(
              'Google Maps API key not configured yet.',
              style: t.bodySmall?.copyWith(color: AppColors.warning),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                height: 180,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(51.5074, -0.1278),
                    zoom: 12,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Leave request',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _leaveType,
                    decoration: const InputDecoration(labelText: 'Leave type'),
                    items: const [
                      DropdownMenuItem(value: 'annual', child: Text('Annual')),
                      DropdownMenuItem(value: 'sick', child: Text('Sick')),
                      DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) =>
                        setState(() => _leaveType = v ?? 'annual'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickLeaveDate(start: true),
                          child: Text(
                            _leaveStart == null
                                ? 'Start date'
                                : _leaveStart!
                                    .toIso8601String()
                                    .substring(0, 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickLeaveDate(start: false),
                          child: Text(
                            _leaveEnd == null
                                ? 'End date'
                                : _leaveEnd!.toIso8601String().substring(0, 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _leaveReason,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Reason (optional)'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: leave.loading ? null : _submitLeave,
                    child: const Text('Submit leave request'),
                  ),
                  if (leave.error != null) ...[
                    const SizedBox(height: 8),
                    Text(leave.error!,
                        style: t.bodySmall?.copyWith(color: AppColors.warning)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('My leave requests',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (leave.requests.isEmpty)
            Text('No leave requests yet.',
                style: t.bodySmall?.copyWith(color: AppColors.silverMuted))
          else
            ...leave.requests.take(6).map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        '${r.leaveType.toUpperCase()} · ${r.startDate} to ${r.endDate}'),
                    subtitle: Text(r.reason ?? 'No reason'),
                    trailing: Text(r.status),
                  ),
                ),
        ],
      ),
    );
  }
}

enum _ShiftState { upcoming, done }

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.site,
    required this.window,
    required this.role,
    required this.state,
  });

  final String site;
  final String window;
  final String role;
  final _ShiftState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isDone = state == _ShiftState.done;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(site,
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDone ? 'Completed' : 'Upcoming',
                    style: t.labelSmall?.copyWith(
                      color: isDone ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(window,
                style: t.bodyMedium?.copyWith(color: AppColors.silver)),
            const SizedBox(height: 4),
            Text(role,
                style: t.bodySmall?.copyWith(color: AppColors.silverMuted)),
          ],
        ),
      ),
    );
  }
}
