import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../models/guard_training.dart';
import '../../services/api_client.dart';
import '../../services/guard_dashboard_api.dart';
import '../../services/secure_token_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  static const routeName = '/profile/training';

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  bool _loading = true;
  String? _error;
  List<GuardTraining> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthController>().profile?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Profile not loaded.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = GuardDashboardApi(
        ApiClient.createAuthorized(SecureTokenStore()),
      );
      final rows = await api.fetchTrainedSites(userId);
      if (!mounted) return;
      setState(() {
        _items = rows.map(GuardTraining.fromJson).toList();
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
    final lunar = context.lunar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site training'),
        actions: lunarAppBarActions,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    'Sites you are trained and cleared to work at.',
                    style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!,
                        style: t.bodySmall?.copyWith(color: AppColors.warning))
                  else if (_items.isEmpty)
                    LunarSurface(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No site training records yet. Contact your manager.',
                        style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                      ),
                    )
                  else
                    ..._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LunarSurface(
                          child: ListTile(
                            leading: const Icon(Icons.verified_outlined,
                                color: AppColors.success),
                            title: Text(
                              item.siteName,
                              style: t.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                if (item.trainedOn != null)
                                  'Trained ${formatUkDateOnly(item.trainedOn)}',
                                if (item.notes != null &&
                                    item.notes!.trim().isNotEmpty)
                                  item.notes!.trim(),
                              ].join('\n'),
                              style: t.bodySmall
                                  ?.copyWith(color: lunar.mutedText),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
