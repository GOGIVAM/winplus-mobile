import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/teacher_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Alertes de décrochage (lot 7), comme le panneau du tableau de bord
/// professeur du site : les élèves de ses formations qui décrochent, avec les
/// signaux relevés ; « Relancer » envoie à l'élève un message (rédigé par
/// WinAI quand le plan le permet) et retire l'alerte.
class DropoutAlertsScreen extends StatefulWidget {
  const DropoutAlertsScreen({super.key});

  @override
  State<DropoutAlertsScreen> createState() => _DropoutAlertsScreenState();
}

class _DropoutAlertsScreenState extends State<DropoutAlertsScreen> {
  List<ApiDropoutAlert>? _alerts;
  bool _error = false;
  final Set<int> _sending = {};
  bool _sendingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final list = await TeacherService.instance.getDropoutAlerts();
      if (mounted) setState(() => _alerts = list);
    } catch (_) {
      if (mounted && _alerts == null) setState(() => _error = true);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _relaunch(ApiDropoutAlert a) async {
    try {
      await TeacherService.instance.relaunchDropoutAlert(a.id);
      if (mounted) setState(() => _alerts = _alerts?.where((x) => x.id != a.id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _relaunchOne(ApiDropoutAlert a) async {
    final l = context.l10n;
    setState(() => _sending.add(a.id));
    final ok = await _relaunch(a);
    if (mounted) setState(() => _sending.remove(a.id));
    _toast(ok ? l.dpSent(a.studentName) : l.dpSendError);
  }

  Future<void> _relaunchAll() async {
    final l = context.l10n;
    final all = List<ApiDropoutAlert>.from(_alerts ?? const []);
    if (all.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dpConfirmTitle),
        content: Text(l.dpConfirmAll(all.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.dpRelaunch)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _sendingAll = true);
    var sent = 0;
    // Une relance après l'autre : un échec n'arrête pas les suivantes.
    for (final a in all) {
      if (await _relaunch(a)) sent++;
    }
    if (mounted) setState(() => _sendingAll = false);
    _toast(sent == all.length ? l.dpSentMany(sent) : l.dpSentPartial(sent, all.length));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.dpTitle)),
      body: SafeArea(child: _body(s, l)),
    );
  }

  Widget _body(WinScheme s, AppLocalizations l) {
    if (_error) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    final alerts = _alerts;
    if (alerts == null) return const WinLoading();
    if (alerts.isEmpty) {
      return WinEmptyState(
          icon: PhosphorIconsRegular.checkCircle, title: l.dpEmpty, message: l.dpEmptyHint);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        WinButton(l.dpRelaunchAll(alerts.length),
            block: true,
            loading: _sendingAll,
            icon: PhosphorIconsRegular.paperPlaneTilt,
            onTap: _sendingAll ? null : _relaunchAll),
        const SizedBox(height: 16),
        for (final a in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  WinAvatar(a.studentName, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.studentName, style: WinType.titleM(s.onStrong)),
                      Text(a.courseTitle, style: WinType.labelM(s.onMuted)),
                    ]),
                  ),
                ]),
                if (a.signals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final sig in a.signals) WinChip(sig),
                  ]),
                ],
                if (a.detectedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(l.dpDetected(WinFormat.dateShort(a.detectedAt!)),
                      style: WinType.labelS(s.onFaint)),
                ],
                const SizedBox(height: 12),
                WinButton(l.dpRelaunch,
                    block: true,
                    small: true,
                    variant: WinButtonVariant.outline,
                    loading: _sending.contains(a.id),
                    onTap: _sending.contains(a.id) || _sendingAll ? null : () => _relaunchOne(a)),
              ]),
            ),
          ),
      ]),
    );
  }
}
