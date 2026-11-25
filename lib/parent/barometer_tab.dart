import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/messaging_service.dart';
import '../services/parent_service.dart';
import '../shared/messaging/messaging_screen.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Baromètre de bien-être (lot 7), comme celui du site : les signaux de
/// comportement déjà relevés (baisse, inactivité, surmenage, anxiété
/// d'examen) et un état général descriptif. Volontairement sans score
/// chiffré (le site fait de même : ces repères ne sont pas une note).
class BarometerView extends StatefulWidget {
  final int childId;
  final String childName;
  const BarometerView({super.key, required this.childId, required this.childName});

  @override
  State<BarometerView> createState() => _BarometerViewState();
}

class _BarometerViewState extends State<BarometerView> {
  List<ApiBarometerSignal>? _signals;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BarometerView old) {
    super.didUpdateWidget(old);
    if (old.childId != widget.childId) {
      _signals = null;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final list = await ParentService.instance.getBarometer(widget.childId);
      if (mounted) setState(() => _signals = list);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _write() {
    Navigator.of(context).push(WinPageRoute(
        builder: (_) => ConversationScreen(
            conversation: ApiConversation(
                id: widget.childId, participantName: widget.childName, participantRole: 'student'))));
  }

  String _typeLabel(AppLocalizations l, String type) => switch (type) {
        'BaissePerformance' => l.barometerTypeDrop,
        'Inactivite' => l.barometerTypeInactive,
        'Surmenage' => l.barometerTypeOverwork,
        'AnxieteExamen' => l.barometerTypeAnxiety,
        _ => type,
      };

  IconData _typeIcon(String type) => switch (type) {
        'BaissePerformance' => PhosphorIconsRegular.trendDown,
        'Inactivite' => PhosphorIconsRegular.clock,
        'Surmenage' => PhosphorIconsRegular.moon,
        'AnxieteExamen' => PhosphorIconsRegular.warning,
        _ => PhosphorIconsRegular.info,
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    if (_error) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    final signals = _signals;
    if (signals == null) return const WinLoading();
    final high = signals.any((x) => x.severity == 'High');
    final medium = signals.any((x) => x.severity == 'Medium');
    final state = high
        ? l.barometerStateHigh
        : medium
            ? l.barometerStateMedium
            : l.barometerStateNone;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(PhosphorIconsRegular.heartbeat, color: s.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(state, style: WinType.titleM(s.onStrong))),
            ]),
            const SizedBox(height: 6),
            Text(high || medium ? l.barometerHintSignals : l.barometerHintNone(widget.childName),
                style: WinType.bodyM(s.onMuted)),
            if (high || medium) ...[
              const SizedBox(height: 12),
              WinButton(l.barometerWriteTo(widget.childName),
                  small: true, icon: PhosphorIconsRegular.chatCircle, onTap: _write),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Text(l.barometerRecent, style: WinType.titleM(s.onStrong)),
        Text(l.barometerRecentSub, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        if (signals.isEmpty)
          Text(l.barometerEmpty, style: WinType.bodyM(s.onMuted))
        else
          for (final sig in signals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WinCard(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(_typeIcon(sig.type), color: sig.alerting ? s.onStrong : s.onMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sig.message, style: WinType.bodyM(s.onStrong)),
                      const SizedBox(height: 2),
                      Text(
                          [
                            _typeLabel(l, sig.type),
                            if (sig.detectedAt != null) WinFormat.dateShort(sig.detectedAt!),
                          ].join(' · '),
                          style: WinType.labelS(s.onMuted)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Rouge seulement pour un vrai signal d'alerte, avec son mot.
                  WinBadge(
                      switch (sig.severity) {
                        'High' => l.barometerSeverityHigh,
                        'Medium' => l.barometerSeverityMedium,
                        _ => l.barometerSeverityLow,
                      },
                      color: sig.severity == 'High' ? BadgeColor.error : BadgeColor.neutral),
                ]),
              ),
            ),
      ]),
    );
  }
}

/// Page « Baromètre » ouverte depuis « Plus » du parent : choix de l'enfant
/// (puces) puis son baromètre.
class BarometerScreen extends StatefulWidget {
  const BarometerScreen({super.key});

  @override
  State<BarometerScreen> createState() => _BarometerScreenState();
}

class _BarometerScreenState extends State<BarometerScreen> {
  List<ApiChild>? _children;
  bool _error = false;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final kids = await ParentService.instance.getChildren();
      if (mounted) setState(() => _children = kids);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final kids = _children;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (kids == null) {
      body = const WinLoading();
    } else if (kids.isEmpty) {
      body = WinEmptyState(icon: PhosphorIconsRegular.users, title: l.parentDashNoChild);
    } else {
      final child = kids[_selected.clamp(0, kids.length - 1)];
      body = Column(children: [
        if (kids.length > 1)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              children: [
                for (var i = 0; i < kids.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: WinChip(kids[i].firstName,
                        active: i == _selected, onTap: () => setState(() => _selected = i)),
                  ),
              ],
            ),
          ),
        Expanded(child: BarometerView(childId: child.id, childName: child.firstName)),
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.barometerTitle)),
      body: SafeArea(child: body),
    );
  }
}
