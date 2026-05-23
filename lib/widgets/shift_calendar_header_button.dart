import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/shift/shift_controller.dart';
import '../models/guard_shift.dart';
import '../theme/app_colors.dart';
import '../theme/lunar_theme_extension.dart';
import '../utils/format_datetime.dart';
import 'shift_calendar_sheet.dart';

/// Compact calendar tile for the home app bar leading slot.
class ShiftCalendarHeaderButton extends StatelessWidget {
  const ShiftCalendarHeaderButton({super.key});

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final lunar = context.lunar;
    final cs = context.cs;
    final shifts = context.watch<ShiftController>();
    final now = DateTime.now();
    final todayShifts = shiftsForLocalDate(shifts.shifts, now);
    final hasToday = todayShifts.isNotEmpty;
    final onDuty = shifts.activeSession != null;

    return IconButton(
      onPressed: () => showShiftCalendarSheet(context),
      tooltip: 'Shift calendar',
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: lunar.tileBackground,
              border: Border.all(
                color: onDuty
                    ? AppColors.success.withValues(alpha: 0.55)
                    : lunar.border,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _months[now.month - 1],
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: cs.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${now.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (hasToday)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: onDuty ? AppColors.success : cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: lunar.tileBackground, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Local calendar day (midnight) for grouping shifts.
DateTime localDateOnly(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day);

List<GuardShift> shiftsForLocalDate(List<GuardShift> shifts, DateTime day) {
  final key = localDateOnly(day);
  return shifts.where((s) {
    final start = s.startsAt?.toLocal();
    if (start == null) return false;
    return localDateOnly(start) == key;
  }).toList()
    ..sort((a, b) {
      final aa = a.startsAt?.millisecondsSinceEpoch ?? 0;
      final bb = b.startsAt?.millisecondsSinceEpoch ?? 0;
      return aa.compareTo(bb);
    });
}

Map<DateTime, List<GuardShift>> groupShiftsByLocalDate(List<GuardShift> shifts) {
  final map = <DateTime, List<GuardShift>>{};
  for (final shift in shifts) {
    final start = shift.startsAt?.toLocal();
    if (start == null) continue;
    final key = localDateOnly(start);
    map.putIfAbsent(key, () => []).add(shift);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      final aa = a.startsAt?.millisecondsSinceEpoch ?? 0;
      final bb = b.startsAt?.millisecondsSinceEpoch ?? 0;
      return aa.compareTo(bb);
    });
  }
  return map;
}

String shiftTimeRange(GuardShift shift) {
  final start = shift.startsAt?.toLocal();
  final end = shift.endsAt?.toLocal();
  if (start == null) return 'Time TBD';
  if (end == null) return formatUkDateTime(start);
  final endLabel =
      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  return '${formatUkDateTime(start)} – $endLabel';
}
