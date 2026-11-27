import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_analytics_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import 'action_plan_screen.dart';
import 'at_risk_screen.dart';
import 'class_prediction_screen.dart';
import 'regional_comparison_screen.dart';
import 'reports_screen.dart';

/// Onglet « Analyses » de l'établissement (G8 : Georges le jugeait « trop
/// moche et pas assez complet »). Structure proposée par la session du
/// design : période et classe, chiffres clés avec tendance, élèves à
/// risque, évolution par semaine, résultats par classe et par matière,
/// activité des contenus, plan WinAI et analyses voisines.
class InstitutionAnalyticsView extends StatefulWidget {
  const InstitutionAnalyticsView({super.key});

  @override
  State<InstitutionAnalyticsView> createState() => _InstitutionAnalyticsViewState();
}

class _InstitutionAnalyticsViewState extends State<InstitutionAnalyticsView> {
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  int? _groupId;
  String? _groupName;
  InstitutionOverview? _data;
  bool _error = false;

  /// Classes connues (tirées de la première réponse) pour le filtre.
  List<AnalyticsGroup> _allGroups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final d = await InstitutionAnalyticsService.instance.overview(_period, groupId: _groupId);
      if (!mounted) return;
      setState(() {
        _data = d;
        if (_groupId == null && d.groups.isNotEmpty) _allGroups = d.groups;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _setPeriod(AnalyticsPeriod p) {
    if (p == _period) return;
    setState(() => _period = p);
    _load();
  }

  Future<void> _pickGroup() async {
    final l = context.l10n;
    final picked = await showWinBottomSheet<AnalyticsGroup?>(
      context: context,
      title: l.anaFilterClass,
      child: Builder(
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(PhosphorIconsRegular.usersThree),
            title: Text(l.anaAllClasses),
            onTap: () => Navigator.pop(ctx, const AnalyticsGroup(0, '', 0, 0, null)),
          ),
          for (final g in _allGroups)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.chalkboardTeacher),
              title: Text(g.name),
              onTap: () => Navigator.pop(ctx, g),
            ),
        ]),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _groupId = picked.id == 0 ? null : picked.id;
      _groupName = picked.id == 0 ? null : picked.name;
    });
    _load();
  }

  void _push(Widget page) => Navigator.push(context, WinPageRoute(builder: (_) => page));

  /// Tendance par rapport à la période précédente : « +2 » ou « −1,5 ».
  String? _trend(num? now, num? prev, {double factor = 1, bool decimal = false}) {
    if (now == null || prev == null) return null;
    final diff = (now - prev) / factor;
    if (diff.abs() < (decimal ? 0.05 : 0.5)) return null;
    final txt = decimal ? WinFormat.decimal(diff.abs().toDouble()) : diff.abs().round().toString();
    return '${diff > 0 ? '+' : '−'}$txt';
  }

  Widget _stat(WinScheme s, String value, String label, IconData icon, {String? trend, bool good = true}) => WinCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: s.primary),
            const Spacer(),
            if (trend != null)
              Text(trend,
                  style: WinType.labelM(
                      trend.startsWith('+') == good ? WinColors.success : WinColors.error)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 2),
          Text(label, style: WinType.labelS(s.onMuted), maxLines: 2),
        ]),
      );

  Widget _section(WinScheme s, String title, {String? action, VoidCallback? onAction}) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          Expanded(child: Text(title, style: WinType.titleM(s.onStrong))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action)),
        ]),
      );

  /// Ligne d'une classe ou d'une matière : barre de la note sur 20.
  Widget _scoreRow(WinScheme s, String name, String meta, double? avg) {
    final color = avg == null
        ? s.outline2
        : avg >= 60
            ? WinColors.success
            : avg >= 50
                ? WinColors.warn
                : WinColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: WinType.titleS(s.onStrong), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(WinFormat.grade20(avg), style: WinType.labelM(avg == null ? s.onMuted : color)),
        ]),
        const SizedBox(height: 4),
        WinProgressBar((avg ?? 0).clamp(0, 100).toDouble(), color: color, height: 8),
        const SizedBox(height: 2),
        Text(meta, style: WinType.labelS(s.onMuted)),
      ]),
    );
  }

  /// Évolution par semaine : barres des élèves actifs.
  Widget _weekly(WinScheme s, AppLocalizations l, List<AnalyticsWeek> weeks) {
    final max = weeks.fold<int>(0, (m, w) => w.active > m ? w.active : m);
    if (max == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l.anaNoActivityPeriod, style: WinType.bodyS(s.onMuted)),
      );
    }
    final shown = weeks.length > 12 ? weeks.sublist(weeks.length - 12) : weeks;
    return SizedBox(
      height: 120,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final w in shown)
          Expanded(
            child: Tooltip(
              message: '${WinFormat.dayMonthShort(w.weekStart)} : ${l.anaActiveCount(w.active)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (w.active > 0) Text('${w.active}', style: WinType.labelS(s.onMuted)),
                  const SizedBox(height: 2),
                  Container(
                    height: 80 * w.active / max + 2,
                    decoration: BoxDecoration(
                        color: w.active > 0 ? WinColors.teal600 : s.outline,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    if (_error && d == null) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    if (d == null) return const WinLoading();
    final k = d.kpis;
    final periods = [
      (AnalyticsPeriod.week, l.anaPeriodWeek),
      (AnalyticsPeriod.month, l.anaPeriodMonth),
      (AnalyticsPeriod.term, l.anaPeriodTerm),
      (AnalyticsPeriod.year, l.anaPeriodYear),
    ];
    final groupsByScore = [...d.groups]..sort((a, b) => (a.avgScore ?? 101).compareTo(b.avgScore ?? 101));
    final subjectsByScore = [...d.subjects]..sort((a, b) => (a.avgScore ?? 101).compareTo(b.avgScore ?? 101));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        // 1. Période et classe.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (p, label) in periods) ...[
              WinChip(label, active: _period == p, onTap: d.partial ? null : () => _setPeriod(p)),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        if (!d.partial && _allGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: WinChip(_groupName ?? l.anaAllClasses,
                icon: PhosphorIconsRegular.funnel, active: _groupId != null, onTap: _pickGroup),
          ),
        ],
        if (d.partial) ...[
          const SizedBox(height: 10),
          WinAlert(l.anaPartial, type: BadgeColor.blue, icon: PhosphorIconsRegular.info),
        ],
        const SizedBox(height: 12),
        // 2. Chiffres clés.
        Row(children: [
          Expanded(
              child: _stat(s, '${k.enrolled}', k.neverLoggedIn > 0 ? l.anaEnrolledNever(k.neverLoggedIn) : l.anaEnrolled,
                  PhosphorIconsRegular.users)),
          const SizedBox(width: 10),
          Expanded(
              child: _stat(s, l.anaActiveOf(k.active, k.enrolled), l.anaActive, PhosphorIconsRegular.pulse,
                  trend: _trend(k.active, k.activePrev))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _stat(s, WinFormat.grade20(k.avgScore), l.anaAvgScore, PhosphorIconsRegular.exam,
                  trend: _trend(k.avgScore, k.avgScorePrev, factor: 5, decimal: true))),
          const SizedBox(width: 10),
          Expanded(
              child: _stat(s, '${k.quizzes}', l.anaQuizzes, PhosphorIconsRegular.checkCircle,
                  trend: _trend(k.quizzes, k.quizzesPrev))),
        ]),
        if (!d.partial && !d.hasActivity) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: WinEmptyState(
              icon: PhosphorIconsRegular.chartLine,
              title: l.anaNoActivityTitle,
              message: l.anaNoActivityHint,
            ),
          ),
        ],
        // 3. Élèves à risque.
        if (!d.partial) ...[
          _section(s, l.anaRiskTitle, action: l.commonSeeAll, onAction: () => _push(const AtRiskScreen())),
          WinCard(
            child: d.riskCritical + d.riskModerate == 0
                ? Text(l.anaRiskNone, style: WinType.bodyS(s.onMuted))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      if (d.riskCritical > 0) WinBadge(l.anaRiskCritical(d.riskCritical), color: BadgeColor.error),
                      if (d.riskModerate > 0) WinBadge(l.anaRiskModerate(d.riskModerate), color: BadgeColor.warn),
                    ]),
                    const SizedBox(height: 10),
                    for (final r in d.riskTop.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          WinAvatar(r.name, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text([r.name, if ((r.groupName ?? '').isNotEmpty) r.groupName!].join(' · '),
                                  style: WinType.titleS(s.onStrong)),
                              Text(r.riskReason, style: WinType.labelS(s.onMuted)),
                            ]),
                          ),
                        ]),
                      ),
                  ]),
          ),
          // 4. Évolution.
          _section(s, l.anaWeeklyTitle),
          WinCard(child: _weekly(s, l, d.weekly)),
          // 5. Résultats par classe.
          if (groupsByScore.isNotEmpty) ...[
            _section(s, l.anaByClass),
            WinCard(
              child: Column(children: [
                for (final g in groupsByScore)
                  _scoreRow(s, g.name, l.anaClassMeta(g.active, g.students), g.avgScore),
              ]),
            ),
          ],
          // 6. Résultats par matière.
          if (subjectsByScore.isNotEmpty) ...[
            _section(s, l.anaBySubject),
            WinCard(
              child: Column(children: [
                for (final x in subjectsByScore)
                  _scoreRow(s, x.subject, l.anaSubjectMeta(x.attempts), x.avgScore),
              ]),
            ),
          ],
          // 7. Activité des contenus.
          _section(s, l.anaContentTitle),
          WinCard(
            child: Column(children: [
              _contentRow(s, PhosphorIconsRegular.downloadSimple, l.anaDownloads, '${d.downloads}'),
              _contentRow(s, PhosphorIconsRegular.notebook, l.anaHomework,
                  l.anaHomeworkValue(d.homeworkSubmitted, d.homeworkGiven)),
              _contentRow(s, PhosphorIconsRegular.exam, l.anaMockExams, '${d.mockExamsTaken}'),
            ]),
          ),
        ],
        // 8. Plan d'action WinAI.
        _section(s, l.instPlanTitle),
        WinCard(
          onTap: () => _push(const ActionPlanScreen()),
          child: Row(children: [
            Icon(PhosphorIconsRegular.sparkle, color: s.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l.anaPlanHint, style: WinType.bodyS(s.onStrong))),
            Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onMuted),
          ]),
        ),
        // 9. Pour aller plus loin.
        _section(s, l.anaMore),
        WinCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _link(s, PhosphorIconsRegular.trendUp, l.predTitle, () => _push(const ClassPredictionScreen())),
            _link(s, PhosphorIconsRegular.mapPin, l.regCmpTitle, () => _push(const RegionalComparisonScreen())),
            _link(s, PhosphorIconsRegular.fileText, l.anaReports, () => _push(const ReportsScreen())),
          ]),
        ),
      ]),
    );
  }

  Widget _contentRow(WinScheme s, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: s.onMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: WinType.bodyM(s.onStrong))),
          Text(value, style: WinType.titleS(s.onStrong)),
        ]),
      );

  Widget _link(WinScheme s, IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: s.primary),
        title: Text(label),
        trailing: Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onMuted),
        onTap: onTap,
      );
}
