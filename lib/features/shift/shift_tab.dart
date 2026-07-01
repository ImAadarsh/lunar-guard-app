import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/guard_shift.dart';
import '../../services/device_location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../utils/maps_links.dart';
import '../../widgets/status_chip.dart';
import 'shift_chat_panel.dart';
import 'shift_controller.dart';

class ShiftTab extends StatefulWidget {
  const ShiftTab({super.key});

  @override
  State<ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<ShiftTab> {
  final _location = DeviceLocationService();
  String? _geofenceHint;
  int? _selectedShiftId;

  int? _chatShiftId(ShiftController c) {
    final activeId = c.activeSession?.shiftId;
    if (activeId != null) return activeId;
    if (_selectedShiftId != null) {
      return c.shiftById(_selectedShiftId)?.id;
    }
    return c.attendanceShift?.id ?? c.nextShift?.id;
  }

  void _selectShift(int shiftId) {
    setState(() => _selectedShiftId = shiftId);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShiftController>().refresh();
    });
  }

  Future<void> _checkIn() async {
    final c = context.read<ShiftController>();
    final shift = c.checkInEligibleShift;
    if (shift == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check-in is only available during your shift window (15 min before start until end).',
          ),
        ),
      );
      return;
    }
    try {
      final p = await _location.getCurrentPosition();
      setState(() {
        _geofenceHint = c.geofenceHintFor(shift, lat: p.lat, lng: p.lng);
      });
      final blocked = c.checkInBlockedReason(shift, p.lat, p.lng);
      if (blocked != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(blocked)));
        return;
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
    final shift = c.attendanceShift ?? c.checkInEligibleShift;
    if (shift == null) return;
    try {
      final p = await _location.getCurrentPosition();
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

  Future<void> _openSiteMap(ShiftController c, GuardShift shift) async {
    final coords = c.siteLatLng(shift.siteId);
    if (coords == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site location not loaded yet.')),
      );
      return;
    }
    final ok = await openGoogleMaps(
      lat: coords.lat,
      lng: coords.lng,
      label: shift.siteLabel,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  String _shiftWindowLabel(GuardShift s) {
    final starts = s.startsAt?.toLocal();
    final ends = s.endsAt?.toLocal();
    if (starts == null || ends == null) return 'Time TBD';
    return '${formatUkDateTime(starts)} – ${ends.hour.toString().padLeft(2, '0')}:${ends.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final c = context.watch<ShiftController>();

    final dutyShift = c.attendanceShift;
    final canCheckIn = c.activeSession == null && c.checkInEligibleShift != null;
    final canCheckOut = c.activeSession != null;
    final chatShiftId = _chatShiftId(c);
    final chatShift = c.shiftById(chatShiftId);

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'My shifts',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (c.shifts.isEmpty)
            Text('No shifts available.',
                style: t.bodySmall?.copyWith(color: lunar.mutedText))
          else
            ...c.shifts.take(8).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShiftCard(
                      shift: s,
                      window: _shiftWindowLabel(s),
                      onOpenMap: () => _openSiteMap(c, s),
                      onSelect: () => _selectShift(s.id),
                      hasMap: c.siteLatLng(s.siteId) != null,
                      isActive: c.activeSession?.shiftId == s.id,
                      isInWindow: c.isWithinShiftWindow(s),
                      isSelected: chatShiftId == s.id,
                    ),
                  ),
                ),
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
                      Icon(
                        c.activeSession == null
                            ? Icons.radio_button_unchecked
                            : Icons.check_circle_rounded,
                        color: c.activeSession == null
                            ? lunar.mutedText
                            : AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.activeSession == null
                              ? 'Not checked in'
                              : 'Checked in · session #${c.activeSession!.id}',
                          style: t.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (dutyShift != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lunar.highlightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lunar.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.activeSession != null
                                ? 'Current shift'
                                : 'Checking in for',
                            style: t.labelSmall?.copyWith(
                              color: lunar.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dutyShift.siteLabel,
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Shift #${dutyShift.id} · ${_shiftWindowLabel(dutyShift)}',
                            style: t.bodySmall?.copyWith(
                              color: lunar.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    c.error ??
                        _geofenceHint ??
                        (dutyShift == null
                            ? 'Check-in opens 15 minutes before shift start and closes when the shift ends.'
                            : c.geofenceHintFor(dutyShift)),
                    style: t.bodySmall
                        ?.copyWith(color: lunar.mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: c.loading || !canCheckIn ? null : _checkIn,
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Check-in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              c.loading || !canCheckOut ? null : _checkOut,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Check-out'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: c.loading || dutyShift == null
                        ? null
                        : _previewGeofence,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Preview geofence with current GPS'),
                  ),
                ],
              ),
            ),
          ),
          if (chatShiftId != null)
            ShiftChatPanel(
              key: ValueKey(chatShiftId),
              shiftId: chatShiftId,
              siteLabel: chatShift?.siteLabel,
            ),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.shift,
    required this.window,
    required this.onOpenMap,
    required this.onSelect,
    required this.hasMap,
    required this.isActive,
    required this.isInWindow,
    required this.isSelected,
  });

  final GuardShift shift;
  final String window;
  final VoidCallback onOpenMap;
  final VoidCallback onSelect;
  final bool hasMap;
  final bool isActive;
  final bool isInWindow;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final isDone =
        shift.status == 'completed' || shift.status == 'cancelled';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: context.cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.siteLabel,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    window,
                    style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                  ),
                  Text(
                    'Shift #${shift.id}',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                  label: isActive
                      ? 'On duty'
                      : isDone
                          ? 'Completed'
                          : isInWindow
                              ? 'Check-in open'
                              : 'Upcoming',
                  tone: isActive
                      ? StatusTone.success
                      : isDone
                          ? StatusTone.neutral
                          : isInWindow
                              ? StatusTone.warning
                              : StatusTone.neutral,
                ),
                if (hasMap) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Map'),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
