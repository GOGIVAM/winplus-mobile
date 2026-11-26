import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../services/parent_follow_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Onglet « Suivi » de la fiche d'un enfant (lot 7) : ce qui l'attend
/// (quiz pas encore faits, fiches de révision) et les achats récents faits
/// pour lui, avec s'il les a déjà ouverts, comme RecommendedContentCard et
/// PurchaseImpactCard du site.
class ChildFollowTab extends StatefulWidget {
  final int childId;
  final String childName;
  const ChildFollowTab({super.key, required this.childId, required this.childName});

  @override
  State<ChildFollowTab> createState() => _ChildFollowTabState();
}

class _ChildFollowTabState extends State<ChildFollowTab> {
  final _svc = ParentFollowService.instance;
  List<ChildQuiz> _quizzes = const [];
  List<ChildSheet> _sheets = const [];
  List<PurchaseImpact> _purchases = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Trois sources indépendantes : une panne n'efface pas les autres.
    final r = await Future.wait([
      _svc.quizzes(widget.childId).catchError((_) => <ChildQuiz>[]),
      _svc.sheets(widget.childId).catchError((_) => <ChildSheet>[]),
      _svc.purchases(widget.childId).catchError((_) => <PurchaseImpact>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _quizzes = r[0] as List<ChildQuiz>;
      _sheets = r[1] as List<ChildSheet>;
      _purchases = r[2] as List<PurchaseImpact>;
      _loaded = true;
    });
  }

  /// Ligne icône, titre, sous-titre et badge (un badge en « trailing » de
  /// ListTile prenait toute la largeur de la ligne).
  Widget _row(WinScheme s, IconData icon, Color color, String title, String subtitle, Widget badge) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: WinType.titleS(s.onStrong)),
              if (subtitle.isNotEmpty) Text(subtitle, style: WinType.labelM(s.onMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          badge,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    if (!_loaded) return const WinLoading();
    if (_quizzes.isEmpty && _sheets.isEmpty && _purchases.isEmpty) {
      return WinEmptyState(
          icon: PhosphorIconsRegular.listChecks, title: l.followEmptyTitle, message: l.followEmptyText(widget.childName));
    }
    final consulted = _purchases.where((p) => p.consulted).length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        if (_quizzes.isNotEmpty || _sheets.isNotEmpty) ...[
          Text(l.followToWork, style: WinType.titleM(s.onStrong)),
          Text(l.followToWorkSub(_quizzes.length + _sheets.length), style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 8),
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final q in _quizzes)
                _row(s, PhosphorIconsRegular.trophy, s.primary, q.title,
                    [if (q.subject.isNotEmpty) q.subject, l.followQuestions(q.questionCount)].join(' · '),
                    WinBadge(l.followQuizNotDone)),
              for (final f in _sheets)
                _row(s, PhosphorIconsRegular.stack, s.primary, f.title, f.subject, WinBadge(l.followSheet)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
        if (_purchases.isNotEmpty) ...[
          Text(l.followPurchases, style: WinType.titleM(s.onStrong)),
          Text(l.followPurchasesSub(consulted, _purchases.length), style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 8),
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final p in _purchases)
                _row(
                    s,
                    p.consulted ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.hourglass,
                    p.consulted ? WinColors.teal600 : s.onMuted,
                    p.title ?? l.followContent,
                    p.consulted && p.firstConsultedAt != null
                        ? l.followOpenedOn(WinFormat.dayMonth(p.firstConsultedAt!))
                        : p.purchasedAt != null
                            ? l.followBoughtOn(WinFormat.dayMonth(p.purchasedAt!))
                            : '',
                    WinBadge(p.consulted ? l.followConsulted : l.followNotOpened,
                        color: p.consulted ? BadgeColor.teal : BadgeColor.neutral)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// « Mes enfants côte à côte » sur l'accueil du parent (2 enfants ou plus),
/// désactivable, comme ChildrenComparison du site : chiffres du mois par
/// enfant et remarques de WinAI.
class ChildrenComparisonCard extends StatefulWidget {
  final List<int> childIds;
  const ChildrenComparisonCard({super.key, required this.childIds});

  static const prefKey = 'parentComparisonEnabled';

  @override
  State<ChildrenComparisonCard> createState() => _ChildrenComparisonCardState();
}

class _ChildrenComparisonCardState extends State<ChildrenComparisonCard> {
  bool? _enabled;
  ChildrenInsights? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(ChildrenComparisonCard old) {
    super.didUpdateWidget(old);
    if (old.childIds.join(',') != widget.childIds.join(',') && _enabled == true) _load();
  }

  Future<void> _init() async {
    var enabled = true;
    try {
      enabled = (await SharedPreferences.getInstance()).getBool(ChildrenComparisonCard.prefKey) ?? true;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _enabled = enabled);
    if (enabled) await _load();
  }

  Future<void> _load() async {
    if (widget.childIds.length < 2) return;
    setState(() => _loading = true);
    try {
      final d = await ParentFollowService.instance.childrenInsights(widget.childIds);
      if (mounted) setState(() => _data = d);
    } catch (_) {
      if (mounted) setState(() => _data = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool enabled) async {
    setState(() => _enabled = enabled);
    try {
      (await SharedPreferences.getInstance()).setBool(ChildrenComparisonCard.prefKey, enabled);
    } catch (_) {}
    ParentFollowService.instance.setComparison(enabled).catchError((_) {});
    if (enabled) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.childIds.length < 2 || _enabled == null) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    final header = Row(children: [
      Expanded(child: Text(l.cmpChildrenTitle, style: WinType.titleM(s.onStrong))),
      if (_enabled!)
        IconButton(
            tooltip: l.cmpChildrenHide,
            onPressed: () => _toggle(false),
            icon: Icon(PhosphorIconsRegular.eyeSlash, color: s.onMuted)),
    ]);
    if (!_enabled!) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WinCard(
          child: Row(children: [
            Icon(PhosphorIconsRegular.usersThree, color: s.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(l.cmpChildrenEnableText, style: WinType.bodyS(s.onMuted))),
            TextButton(onPressed: () => _toggle(true), child: Text(l.cmpChildrenEnable)),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        header,
        Text(l.cmpChildrenSub, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        if (_loading && d == null)
          const WinLoading()
        else if (d == null || d.children.isEmpty)
          Text(l.cmpChildrenEmpty, style: WinType.bodyM(s.onMuted))
        else
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final c in d.children)
                ListTile(
                  leading: Icon(PhosphorIconsRegular.student, color: s.primary),
                  title: Text(c.name),
                  subtitle: Text(l.cmpChildrenMeta(c.quizCount, c.activeDays)),
                  trailing: Text('${(c.avgScore / 5).toStringAsFixed(1)} / 20', style: WinType.titleS(s.onStrong)),
                ),
              if (d.insights.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(PhosphorIconsRegular.sparkle, size: 16, color: s.primary),
                      const SizedBox(width: 6),
                      Text(l.cmpChildrenWinai, style: WinType.labelM(s.onStrong)),
                    ]),
                    const SizedBox(height: 4),
                    for (final t in d.insights) Text(t, style: WinType.bodyS(s.onMuted)),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }
}
