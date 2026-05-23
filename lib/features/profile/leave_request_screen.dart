import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../widgets/request_cards.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../shift/leave_controller.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  static const routeName = '/profile/leave-request';

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _leaveReason = TextEditingController();
  String _leaveType = 'annual';
  DateTime? _leaveStart;
  DateTime? _leaveEnd;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<LeaveController>().refresh();
    });
  }

  @override
  void dispose() {
    _leaveReason.dispose();
    super.dispose();
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
        content: Text('Leave request submitted for manager approval.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final leave = context.watch<LeaveController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave request'),
        actions: lunarAppBarActions,
      ),
      body: RefreshIndicator(
        onRefresh: leave.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Submit leave',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _leaveType,
                      decoration:
                          const InputDecoration(labelText: 'Leave type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'annual', child: Text('Annual')),
                        DropdownMenuItem(value: 'sick', child: Text('Sick')),
                        DropdownMenuItem(
                            value: 'unpaid', child: Text('Unpaid')),
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
                                  : _leaveEnd!
                                      .toIso8601String()
                                      .substring(0, 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _leaveReason,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: leave.loading ? null : _submitLeave,
                      child: const Text('Submit leave request'),
                    ),
                    if (leave.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        leave.error!,
                        style:
                            t.bodySmall?.copyWith(color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'My leave requests',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (leave.requests.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No leave requests yet.',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ),
              )
            else
              ...leave.requests.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LeaveRequestCard(request: r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
