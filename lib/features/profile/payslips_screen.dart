import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/payslip.dart';
import '../../services/api_client.dart';
import '../../services/payslips_api.dart';
import '../../services/secure_token_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/lunar_surface.dart';
import '../../widgets/lunar_theme_toggle.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  static const routeName = '/profile/payslips';

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  bool _loading = true;
  String? _error;
  List<Payslip> _items = const [];
  int? _downloadingId;

  late final PayslipsApi _api =
      PayslipsApi(ApiClient.createAuthorized(SecureTokenStore()));

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
      final rows = await _api.listMyPayslips();
      if (!mounted) return;
      setState(() {
        _items = rows.map(Payslip.fromJson).toList();
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

  Future<void> _openPdf(Payslip payslip) async {
    setState(() => _downloadingId = payslip.id);
    try {
      final path = await _api.downloadPayslipPdf(payslip.id);
      final result = await OpenFilex.open(path, type: 'application/pdf');
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslips'),
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
                    'Download PDF payslips issued by payroll.',
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
                        'No payslips available yet.',
                        style: t.bodyMedium?.copyWith(color: lunar.mutedText),
                      ),
                    )
                  else
                    ..._items.map((p) {
                      final busy = _downloadingId == p.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LunarSurface(
                          child: ListTile(
                            title: Text(
                              p.periodLabel,
                              style: t.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                'Status: ${p.status}',
                                if (p.grossDisplay != null)
                                  'Gross: ${p.grossDisplay}',
                                if (p.issuedAt != null)
                                  'Issued ${formatUkDateTime(p.issuedAt)}',
                              ].join(' · '),
                              style: t.bodySmall
                                  ?.copyWith(color: lunar.mutedText),
                            ),
                            trailing: busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                        Icons.picture_as_pdf_outlined),
                                    onPressed: () => _openPdf(p),
                                    tooltip: 'Open PDF',
                                  ),
                            onTap: busy ? null : () => _openPdf(p),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
