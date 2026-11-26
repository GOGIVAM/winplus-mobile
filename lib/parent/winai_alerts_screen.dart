import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import 'child_activity_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';

class WinAIAlertsScreen extends StatefulWidget {
  const WinAIAlertsScreen({super.key});
  @override
  State<WinAIAlertsScreen> createState() => _WinAIAlertsScreenState();
}

class _WinAIAlertsScreenState extends State<WinAIAlertsScreen> {
  List<ApiPersistedAlert>? _alerts;
  List<ApiChild>? _children;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _failed = false;

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    try {
      final children = await ParentService.instance.getChildren();
      final alerts = await ParentService.instance
          .getAllPersistedAlerts(children.map((c) => c.id).toList());
      if (mounted)
        setState(() {
          _alerts = alerts;
          _children = children;
        });
    } catch (_) {
      // Lot 8 : panne du serveur, plus de chargement sans fin.
      if (mounted) setState(() => _failed = true);
    }
  }

  // La sévérité (Low/Medium/High), pas le type de signal, porte le niveau de gravité.
  Color _alertColor(String severity) => switch (severity) {
        'High' => WinColors.error,
        'Medium' => WinColors.warn,
        _ => WinColors.success,
      };

  Color _alertBg(String severity) => switch (severity) {
        'High' => WinColors.errorBg,
        'Medium' => WinColors.warnBg,
        _ => WinColors.successBg,
      };

  IconData _alertIcon(String severity) => switch (severity) {
        'High' => PhosphorIconsRegular.warningCircle,
        'Medium' => PhosphorIconsRegular.warning,
        _ => PhosphorIconsRegular.checkCircle,
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.commonWinaiAlerts),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.arrowClockwise, color: s.onStrong),
            onPressed: () {
              setState(() {
                _alerts = null;
                _children = null;
              });
              _load();
            },
          ),
        ],
      ),
      body: _failed
          ? WinErrorState(message: context.l10n.commonLoadError, onRetry: _load)
          : _alerts == null
          ? const WinLoading()
          : _buildBody(s),
    );
  }

  Widget _buildBody(WinScheme s) {
    final alerts = _alerts!;
    final children = _children ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        WinAlert(
          context.l10n.parentAlertsIntro,
          type: BadgeColor.teal,
          icon: winAIIconData,
        ),
        const SizedBox(height: 20),
        if (alerts.isEmpty) ...[
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(PhosphorIconsRegular.checkCircle,
                size: 56, color: WinColors.success),
            const SizedBox(height: 12),
            Text(context.l10n.parentAlertsNone, style: WinType.bodyM(s.onMuted)),
            Text(context.l10n.parentAlertsAllGood,
                style: WinType.bodyS(s.onFaint)),
          ])),
          const SizedBox(height: 24),
        ] else ...[
          Text(context.l10n.parentAlertsRecent, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            final color = _alertColor(alert.severity);
            final bg = _alertBg(alert.severity);
            final child =
                children.where((c) => c.id == alert.childId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (child != null) ...[
                      Row(children: [
                        WinAvatar(child.fullName, size: 28),
                        const SizedBox(width: 8),
                        Text(child.fullName, style: WinType.titleM(s.onStrong)),
                        const Spacer(),
                        Text(_formatDate(alert.detectedAt),
                            style: WinType.labelS(s.onFaint)),
                      ]),
                      const SizedBox(height: 6),
                    ],
                    // Bord arrondi : bordure uniforme dehors, bande de couleur dedans.
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(WinRadii.md),
                        border: Border.all(color: s.outline),
                        color: bg,
                      ),
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(WinRadii.md - 1),
                      child: Container(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: color, width: 4)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_alertIcon(alert.severity),
                                size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(alert.content,
                                    style: WinType.bodyS(s.onSurface))),
                          ]),
                          ),
                        ),
                    ),
                    if (child != null) ...[
                      const SizedBox(height: 6),
                      WinButton(context.l10n.parentAlertsSeeActivity,
                          small: true,
                          variant: WinButtonVariant.ghost,
                          icon: PhosphorIconsRegular.chartLine,
                          onTap: () => Navigator.push(
                              context,
                              WinPageRoute(
                                  builder: (_) =>
                                      ChildActivityScreen(child: child)))),
                    ],
                    const SizedBox(height: 12),
                  ]),
            );
          }),
          const WinDivider(),
          const SizedBox(height: 20),
        ],
        Text(context.l10n.parentAlertsTipsTitle, style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        ...[
          (
            PhosphorIconsRegular.timer,
            context.l10n.parentAlertsTip1Title,
            context.l10n.parentAlertsTip1Text
          ),
          (
            PhosphorIconsRegular.exam,
            context.l10n.parentAlertsTip2Title,
            context.l10n.parentAlertsTip2Text
          ),
          (
            PhosphorIconsRegular.flag,
            context.l10n.parentAlertsTip3Title,
            context.l10n.parentAlertsTip3Text
          ),
        ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WinCard(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tip.$1, size: 20, color: s.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(tip.$2, style: WinType.titleM(s.onStrong)),
                            const SizedBox(height: 4),
                            Text(tip.$3, style: WinType.bodyS(s.onMuted)),
                          ])),
                    ]),
              ),
            )),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return context.l10n.studentNotifMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.studentNotifHoursAgo(diff.inHours);
    return context.l10n.parentDaysAgo(diff.inDays);
  }
}
