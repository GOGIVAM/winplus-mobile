import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../services/reports_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../widgets/win_screen.dart';
import '../l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  bool _error = false;

  Future<void> _load() async {
    setState(() {
      _loaded = false;
      _error = false;
    });
    try {
      final p = await ReportsService.instance.getPortfolio(widget.child.id);
      if (mounted)
        setState(() {
          _portfolio = p;
          _loaded = true;
        });
    } catch (_) {
      // Panne : « Réessayer », pas « pas encore généré ».
      if (mounted)
        setState(() {
          _error = true;
          _loaded = true;
        });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (!_loaded) return const WinLoading();
    if (_error) {
      return WinErrorState(message: context.l10n.commonLoadError, onRetry: _load);
    }

    final p = _portfolio;
    if (p == null) {
      return WinEmptyState(title: context.l10n.parentPortfolioNotYet(widget.child.firstName), icon: PhosphorIconsRegular.user);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(context.l10n.parentPortfolioTitle(widget.child.firstName),
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 4),
        Text(context.l10n.parentPortfolioUpdatedOn(_fmtDate(p.updatedAt)),
            style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 16),
        _PortfolioCard(
            icon: PhosphorIconsRegular.calendarBlank,
            title: context.l10n.parentPortfolioRegularity,
            text: p.regularite ??
                context.l10n.parentPortfolioNoRegularity(widget.child.firstName)),
        const SizedBox(height: 10),
        _PortfolioCard(
            icon: PhosphorIconsRegular.rocketLaunch,
            title: context.l10n.parentPortfolioAutonomy,
            text: p.autonomie ??
                context.l10n.parentPortfolioNoAutonomy(widget.child.firstName)),
        const SizedBox(height: 10),
        _PortfolioCard(
            icon: PhosphorIconsRegular.compass,
            title: context.l10n.parentPortfolioCuriosity,
            text: p.curiosite ??
                context.l10n.parentPortfolioNoCuriosity(widget.child.firstName)),
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
