import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/shift/shift_controller.dart';
import '../features/shell/shell_navigation_controller.dart';
import '../models/guard_shift.dart';
import '../theme/lunar_theme_extension.dart';
import '../widgets/status_chip.dart';
import 'shift_calendar_header_button.dart';

Future<void> showShiftCalendarSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const ShiftCalendarSheet(),
  );
}

class ShiftCalendarSheet extends StatefulWidget {
  const ShiftCalendarSheet({super.key});

  @override
  State<ShiftCalendarSheet> createState() => _ShiftCalendarSheetState();
}

class _ShiftCalendarSheetState extends State<ShiftCalendarSheet> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = localDateOnly(now);
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShiftController>().refresh();
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  List<DateTime?> _buildMonthGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Monday = 0 … Sunday = 6
    final leading = (first.weekday + 6) % 7;
    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final cs = context.cs;
    final shifts = context.watch<ShiftController>();
    final grouped = groupShiftsByLocalDate(shifts.shifts);
    final selectedShifts = grouped[_selectedDay] ?? const <GuardShift>[];
    final today = localDateOnly(DateTime.now());
    final cells = _buildMonthGrid();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Shift calendar',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekdays
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: t.labelSmall?.copyWith(
                            color: lunar.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.05,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final day = cells[index];
                if (day == null) return const SizedBox.shrink();

                final key = localDateOnly(day);
                final dayShifts = grouped[key] ?? const [];
                final isToday = key == today;
                final isSelected = key == _selectedDay;
                final hasShift = dayShifts.isNotEmpty;

                Color? bg;
                Color textColor = cs.onSurface;
                Border? border;
                if (isSelected) {
                  bg = cs.primary;
                  textColor = cs.onPrimary;
                } else if (isToday) {
                  bg = cs.primary.withValues(alpha: 0.12);
                  border = Border.all(color: cs.primary.withValues(alpha: 0.45));
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedDay = key),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: border,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1,
                            ),
                          ),
                          if (hasShift) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                dayShifts.length.clamp(1, 3),
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.onPrimary
                                        : cs.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDay == today
                  ? 'Today'
                  : '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (selectedShifts.isEmpty)
              Text(
                'No shifts on this day.',
                style: t.bodyMedium?.copyWith(color: lunar.mutedText),
              )
            else
              ...selectedShifts.map(
                (shift) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ShiftDayTile(shift: shift),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.read<ShellNavigationController>().goToTab(1);
              },
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: const Text('Open My shift tab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftDayTile extends StatelessWidget {
  const _ShiftDayTile({required this.shift});

  final GuardShift shift;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final activeId = context.watch<ShiftController>().activeSession?.shiftId;
    final isActive = activeId == shift.id;
    final isDone =
        shift.status == 'completed' || shift.status == 'cancelled';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.siteLabel,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shiftTimeRange(shift),
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: isActive
                  ? 'On duty'
                  : isDone
                      ? 'Done'
                      : 'Scheduled',
              tone: isActive
                  ? StatusTone.success
                  : isDone
                      ? StatusTone.neutral
                      : StatusTone.warning,
            ),
          ],
        ),
      ),
    );
  }
}
