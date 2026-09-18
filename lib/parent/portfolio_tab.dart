import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../services/reports_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Portefeuille de compétences  portrait stable de l'apprenant, recalculé
/// une fois par mois. Trois textes descriptifs uniquement (Régularité /
/// Autonomie / Curiosité) : jamais de score, de jauge chiffrée, ni de
/// comparaison avec un autre enfant.
class PortfolioTab extends StatefulWidget {
  final ApiChild child;
  const PortfolioTab({super.key, required this.child});
  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  ApiPortfolio? _portfolio;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ReportsService.instance.getPortfolio(widget.child.id);
    if (mounted)
      setState(() {
        _portfolio = p;
        _loaded = true;
      });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    final p = _portfolio;
    if (p == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person_outline, size: 48, color: s.onFaint),
            const SizedBox(height: 12),
            Text(
                'Le portrait de ${widget.child.firstName} sera disponible après le premier calcul mensuel.',
                style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Portrait de ${widget.child.firstName}',
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 4),
        Text('Dernière mise à jour le ${_fmtDate(p.updatedAt)}',
            style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 16),
        _PortfolioCard(
            icon: Icons.calendar_today_outlined,
            title: 'Régularité',
            text: p.regularite ??
                "Pas encore de données de régularité pour ${widget.child.firstName}."),
        const SizedBox(height: 10),
        _PortfolioCard(
            icon: Icons.rocket_launch_outlined,
            title: 'Autonomie',
            text: p.autonomie ??
                "Pas encore de données d'autonomie pour ${widget.child.firstName}."),
        const SizedBox(height: 10),
        _PortfolioCard(
            icon: Icons.explore_outlined,
            title: 'Curiosité',
            text: p.curiosite ??
                "Pas encore de données de curiosité pour ${widget.child.firstName}."),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _PortfolioCard(
      {required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: WinColors.teal600),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: WinType.labelM(s.onMuted).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(text, style: WinType.bodyM(s.onStrong)),
          ]),
        ),
      ]),
    );
  }
}
