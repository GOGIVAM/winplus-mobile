import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'child_activity_screen.dart';

class WinAIAlertsScreen extends StatefulWidget {
  const WinAIAlertsScreen({super.key});
  @override
  State<WinAIAlertsScreen> createState() => _WinAIAlertsScreenState();
}

class _WinAIAlertsScreenState extends State<WinAIAlertsScreen> {
  List<ApiWinAIAlert>? _alerts;
  List<ApiChild>? _children;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alerts = await ParentService.instance.getAlerts();
    final children = await ParentService.instance.getChildren();
    if (mounted)
      setState(() {
        _alerts = alerts;
        _children = children;
      });
  }

  Color _alertColor(String type) => switch (type) {
        'danger' => WinColors.error,
        'warning' => WinColors.warn,
        _ => WinColors.success,
      };

  Color _alertBg(String type) => switch (type) {
        'danger' => WinColors.errorBg,
        'warning' => WinColors.warnBg,
        _ => WinColors.successBg,
      };

  IconData _alertIcon(String type) => switch (type) {
        'danger' => Icons.error_outline,
        'warning' => Icons.warning_amber_outlined,
        _ => Icons.check_circle_outline,
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
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Alertes WinAI', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
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
      body: _alerts == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(s),
    );
  }

  Widget _buildBody(WinScheme s) {
    final alerts = _alerts!;
    final children = _children ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const WinAlert(
          'WinAI surveille les progrès de vos enfants et vous alerte en temps réel.',
          type: BadgeColor.teal,
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 20),
        if (alerts.isEmpty) ...[
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: WinColors.success),
            const SizedBox(height: 12),
            Text('Aucune alerte active.', style: WinType.bodyM(s.onMuted)),
            Text('Tout va bien pour vos enfants !',
                style: WinType.bodyS(s.onFaint)),
          ])),
          const SizedBox(height: 24),
        ] else ...[
          Text('Alertes récentes', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            final color = _alertColor(alert.type);
            final bg = _alertBg(alert.type);
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
                        Text(_formatDate(alert.createdAt),
                            style: WinType.labelS(s.onFaint)),
                      ]),
                      const SizedBox(height: 6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: Border(
                          left: BorderSide(color: color, width: 4),
                          top: BorderSide(color: s.outline),
                          right: BorderSide(color: s.outline),
                          bottom: BorderSide(color: s.outline),
                        ),
                        color: bg,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_alertIcon(alert.type),
                                size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(alert.message,
                                    style: WinType.bodyS(s.onSurface))),
                          ]),
                    ),
                    if (child != null) ...[
                      const SizedBox(height: 6),
                      WinButton('Voir l\'activité',
                          small: true,
                          variant: WinButtonVariant.ghost,
                          icon: Icons.timeline_outlined,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
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
        Text('Conseils WinAI', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        ...[
          (
            Icons.timer_outlined,
            'Sessions courtes et régulières',
            'Encouragez les sessions courtes régulières plutôt que les longues sessions irrégulières. La rétention est bien meilleure.'
          ),
          (
            Icons.quiz_outlined,
            'Quiz quotidiens',
            'Les quiz quotidiens améliorent la rétention de 40% par rapport à la lecture passive.'
          ),
          (
            Icons.flag_outlined,
            'Objectif clair',
            'Fixez un objectif d\'examen précis avec votre enfant  une date et un examen concrets  pour le motiver efficacement.'
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
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}
