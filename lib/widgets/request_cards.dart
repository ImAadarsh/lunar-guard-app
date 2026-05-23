import 'package:flutter/material.dart';

import '../models/leave_request.dart';
import '../models/shift_swap.dart';
import '../theme/lunar_theme_extension.dart';
import '../utils/format_datetime.dart';
import 'status_chip.dart';

class SwapRequestCard extends StatelessWidget {
  const SwapRequestCard({super.key, required this.swap});

  final ShiftSwap swap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    swap.siteName,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusChip(
                  label: swap.status.toUpperCase(),
                  tone: toneForRequestStatus(swap.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Shift #${swap.shiftId} · ${formatUkDateTime(swap.startsAt)}',
              style: t.bodySmall?.copyWith(color: lunar.mutedText),
            ),
            if (swap.targetEmail != null) ...[
              const SizedBox(height: 4),
              Text('Requested with: ${swap.targetEmail}', style: t.bodySmall),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Open swap request',
                style: t.bodySmall?.copyWith(color: lunar.mutedText),
              ),
            ],
            if (swap.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Submitted ${formatUkDateTime(swap.createdAt)}',
                style: t.labelSmall?.copyWith(color: lunar.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({super.key, required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.leaveType.toUpperCase(),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusChip(
                  label: request.status.toUpperCase(),
                  tone: toneForRequestStatus(request.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${request.startDate} → ${request.endDate}',
              style: t.bodyMedium,
            ),
            if (request.reason != null && request.reason!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                request.reason!,
                style: t.bodySmall?.copyWith(
                  color: lunar.mutedText,
                  height: 1.35,
                ),
              ),
            ],
            if (request.managerComment != null &&
                request.managerComment!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lunar.highlightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lunar.border),
                ),
                child: Text(
                  'Manager: ${request.managerComment}',
                  style: t.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
