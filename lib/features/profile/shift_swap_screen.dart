import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/guard_shift.dart';
import '../../models/shift_swap.dart';
import '../../models/swap_candidate.dart';
import '../../services/api_client.dart';
import '../../services/secure_token_store.dart';
import '../../services/shift_swaps_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/request_cards.dart';
import '../../widgets/lunar_theme_toggle.dart';
import '../shift/shift_controller.dart';

class ShiftSwapScreen extends StatefulWidget {
  const ShiftSwapScreen({super.key});

  static const routeName = '/profile/shift-swap';

  @override
  State<ShiftSwapScreen> createState() => _ShiftSwapScreenState();
}

class _ShiftSwapScreenState extends State<ShiftSwapScreen> {
  bool _swapsLoading = false;
  String? _swapsError;
  List<ShiftSwap> _swaps = const [];
  late final ShiftSwapsApi _swapsApi =
      ShiftSwapsApi(ApiClient.createAuthorized(SecureTokenStore()));

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShiftController>().refresh();
      _loadSwaps();
    });
  }

  Future<void> _loadSwaps() async {
    setState(() {
      _swapsLoading = true;
      _swapsError = null;
    });
    try {
      final rows = await _swapsApi.listMySwaps();
      if (!mounted) return;
      setState(() {
        _swaps = rows.map(ShiftSwap.fromJson).toList();
        _swapsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _swapsError = e.toString();
        _swapsLoading = false;
      });
    }
  }

  Future<void> _requestSwap(GuardShift shift) async {
    List<SwapCandidate> candidates = const [];
    String? loadErr;
    try {
      final rows = await _swapsApi.listSwapCandidates(shift.id);
      candidates = rows.map(SwapCandidate.fromJson).toList();
    } catch (e) {
      loadErr = e.toString();
    }
    if (!mounted) return;

    int? selectedTargetId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Request shift swap'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${shift.siteLabel} · ${formatUkDateTime(shift.startsAt)}',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shift #${shift.id}',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: ctx.lunar.mutedText,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (loadErr != null)
                      Text(
                        loadErr,
                        style: Theme.of(ctx)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.warning),
                      )
                    else if (candidates.isEmpty)
                      Text(
                        'No trained guards available for this site in this time window. You can still submit an open swap request.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: ctx.lunar.mutedText,
                              height: 1.35,
                            ),
                      )
                    else
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Swap with guard',
                        ),
                        initialValue: selectedTargetId,
                        selectedItemBuilder: (context) => [
                          const Text(
                            'Any trained guard',
                            overflow: TextOverflow.ellipsis,
                          ),
                          ...candidates.map(
                            (c) => Text(
                              c.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Open swap (any trained guard)'),
                          ),
                          ...candidates.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.userId,
                              child: Text(
                                c.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedTargetId = v),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit request'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await _swapsApi.requestSwap(
        shiftId: shift.id,
        targetUserId: selectedTargetId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swap request submitted.')),
      );
      await _loadSwaps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final c = context.watch<ShiftController>();

    final swappable = c.shifts
        .where((s) =>
            s.status == 'scheduled' &&
            s.startsAt != null &&
            s.startsAt!.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift swap'),
        actions: lunarAppBarActions,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await c.refresh();
          await _loadSwaps();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Request a swap',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a trained guard at the same site who is free in this time window.',
              style: t.bodySmall?.copyWith(color: lunar.mutedText, height: 1.35),
            ),
            const SizedBox(height: 14),
            if (swappable.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No upcoming shifts available to swap.',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ),
              )
            else
              ...swappable.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: c.loading ? null : () => _requestSwap(s),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${s.siteLabel} · ${formatUkDateTime(s.startsAt)}',
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'My swap requests',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_swapsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_swapsError != null)
              Text(_swapsError!,
                  style: t.bodySmall?.copyWith(color: AppColors.warning))
            else if (_swaps.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No swap requests yet.',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ),
              )
            else
              ..._swaps.map(
                (sw) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SwapRequestCard(swap: sw),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
