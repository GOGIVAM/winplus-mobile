import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/course_editor_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Suivi et ludification » d'une formation publiée, en trois parties :
/// - Leçons : chiffres clés, endroit où les élèves décrochent, parcours
///   leçon par leçon (type, élèves arrivés au bout, visionnage, score) ;
/// - Élèves : inscrits inactifs depuis un seuil réglable, relance rédigée
///   par WinAI et taux de reprise après relance ;
/// - Points : réglages de la ludification et classement.
/// Lot 8 : Georges jugeait la première version trop sommaire (une simple
/// liste de barres).
class CourseStatsScreen extends StatefulWidget {
  final int courseId;
  final String title;
  const CourseStatsScreen({super.key, required this.courseId, required this.title});

  @override
  State<CourseStatsScreen> createState() => _CourseStatsScreenState();
}

enum _Part { lessons, students, points }

class _CourseStatsScreenState extends State<CourseStatsScreen> {
  final _svc = CourseEditorService.instance;
  _Part _part = _Part.lessons;

  Gamification? _g;
  List<(int, String, int)> _board = const [];
  List<LessonStats>? _lessons;
  List<InactiveStudent> _inactive = const [];
  RelaunchStats? _relaunchStats;
  int _threshold = 7;
  final Set<int> _selected = {};
  bool _error = false;
  bool _saving = false;
  bool _relaunching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final r = await Future.wait([
        _svc.lessonStats(widget.courseId),
        _svc.gamification(widget.courseId).then<Gamification?>((g) => g).catchError((_) => null),
        _svc.leaderboard(widget.courseId).catchError((_) => <(int, String, int)>[]),
        _svc.inactiveStudents(widget.courseId).catchError((_) => <InactiveStudent>[]),
        _svc.relaunchStats(widget.courseId).then<RelaunchStats?>((x) => x).catchError((_) => null),
        _svc.inactivityThreshold(widget.courseId).catchError((_) => 7),
      ]);
      if (!mounted) return;
      setState(() {
        _lessons = r[0] as List<LessonStats>;
        _g = r[1] as Gamification?;
        _board = r[2] as List<(int, String, int)>;
        _inactive = r[3] as List<InactiveStudent>;
        _relaunchStats = r[4] as RelaunchStats?;
        _threshold = r[5] as int;
        _selected.retainAll(_inactive.map((x) => x.userId));
      });
    } catch (_) {
      if (mounted && _lessons == null) setState(() => _error = true);
    }
  }

  // ---------------------------------------------------------------- Leçons

  static IconData _typeIcon(String type) => switch (type.toLowerCase()) {
        'video' => PhosphorIconsRegular.playCircle,
        'quiz' => PhosphorIconsRegular.exam,
        'pdf' || 'document' => PhosphorIconsRegular.filePdf,
        'live' => PhosphorIconsRegular.videoCamera,
        _ => PhosphorIconsRegular.article,
      };

  /// Le plus fort recul d'élèves entre deux leçons qui se suivent.
  (int, LessonStats, LessonStats)? _biggestDrop(List<LessonStats> ls) {
    (int, LessonStats, LessonStats)? best;
    for (var i = 1; i < ls.length; i++) {
      final drop = ls[i - 1].completed - ls[i].completed;
      if (drop > 0 && (best == null || drop > best.$1)) best = (drop, ls[i - 1], ls[i]);
    }
    return best;
  }

  List<Widget> _lessonsPart(WinScheme s, AppLocalizations l, List<LessonStats> ls) {
    if (ls.isEmpty) {
      return [
        SizedBox(
            height: 280,
            child: WinEmptyState(icon: PhosphorIconsRegular.chartBar, title: l.cstatNoLesson, message: l.cstatLessons)),
      ];
    }
    final enrolled = ls.first.enrolled;
    final avgCompletion = ls.fold(0.0, (a, x) => a + x.completionRate) / ls.length;
    final scores = ls.where((x) => x.quizScore != null).map((x) => x.quizScore!).toList();
    final avgQuiz = scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final toReview = ls.where((x) => x.lowCompletion).length;
    final drop = _biggestDrop(ls);
    return [
      Row(children: [
        Expanded(child: WinStatCard('$enrolled', l.cstatEnrolled, icon: PhosphorIconsRegular.users)),
        const SizedBox(width: 10),
        Expanded(
            child: WinStatCard('${avgCompletion.round()} %', l.cstatAvgCompletion,
                icon: PhosphorIconsRegular.checkCircle, color: avgCompletion >= 40 ? WinColors.success : WinColors.warn)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: WinStatCard(avgQuiz == null ? '–' : '${(avgQuiz / 5).toStringAsFixed(1)} / 20', l.cstatAvgQuiz,
                icon: PhosphorIconsRegular.exam)),
        const SizedBox(width: 10),
        Expanded(
            child: WinStatCard('$toReview', l.cstatToReview,
                icon: PhosphorIconsRegular.warning, color: toReview > 0 ? WinColors.error : WinColors.success)),
      ]),
      if (drop != null) ...[
        const SizedBox(height: 12),
        WinAlert('${l.cstatDropTitle} : ${l.cstatDropText(drop.$1, drop.$2.title, drop.$3.title)}',
            type: BadgeColor.warn, icon: PhosphorIconsRegular.trendDown),
      ],
      const SizedBox(height: 20),
      Text(l.cstatPath, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 8),
      for (var i = 0; i < ls.length; i++) _lessonStep(s, l, i + 1, ls[i], last: i == ls.length - 1),
    ];
  }

  /// Une étape du parcours : numéro, type, titre, élèves arrivés au bout.
  Widget _lessonStep(WinScheme s, AppLocalizations l, int n, LessonStats x, {required bool last}) {
    final color = x.lowCompletion ? WinColors.error : WinColors.teal600;
    final details = [
      if (x.watchSec > 0) l.cstatWatch((x.watchSec / 60).round().clamp(1, 999)),
      if (x.quizScore != null) l.cstatQuiz('${(x.quizScore! / 5).toStringAsFixed(1)} / 20'),
    ].join(' · ');
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Fil du parcours : pastille numérotée et trait vers l'étape suivante.
        SizedBox(
          width: 34,
          child: Column(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: winTone(s, x.lowCompletion ? BadgeColor.error : BadgeColor.teal).bg),
              child: Text('$n', style: WinType.labelM(color)),
            ),
            if (!last) Expanded(child: Container(width: 2, color: s.outline)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WinCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_typeIcon(x.type), size: 18, color: s.onMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(x.title, style: WinType.titleS(s.onStrong), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (x.lowCompletion) WinBadge(l.cstatReviewBadge, color: BadgeColor.error),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: WinProgressBar(x.completionRate.clamp(0, 100).toDouble(), color: color, height: 8)),
                  const SizedBox(width: 10),
                  Text('${x.completionRate.round()} %', style: WinType.labelM(color)),
                ]),
                const SizedBox(height: 6),
                Text(l.cstatLessonOf(x.completed, x.enrolled), style: WinType.labelM(s.onStrong)),
                if (details.isNotEmpty) Text(details, style: WinType.labelS(s.onMuted)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------- Élèves

  Future<void> _setThreshold(int days) async {
    if (days == _threshold) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _threshold = days);
    try {
      final saved = await _svc.setInactivityThreshold(widget.courseId, days);
      final inactive = await _svc.inactiveStudents(widget.courseId);
      if (!mounted) return;
      setState(() {
        _threshold = saved;
        _inactive = inactive;
        _selected.retainAll(inactive.map((x) => x.userId));
      });
    } on CourseEditorException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _relaunch() async {
    final l = context.l10n;
    final ids = _selected.toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cstatRelaunchConfirmTitle),
        content: Text(l.cstatRelaunchConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.commonConfirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _relaunching = true);
    try {
      final (sent, message) = await _svc.relaunch(widget.courseId, ids);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.cstatRelaunched(sent))));
      setState(() => _selected.clear());
      if (message.isNotEmpty) {
        await showWinBottomSheet<void>(
          context: context,
          title: l.cstatRelaunchMessage,
          child: Text(message, style: WinType.bodyM(WinTheme.of(context).onStrong)),
        );
      }
      await _load();
    } on CourseEditorException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _relaunching = false);
    }
  }

  List<Widget> _studentsPart(WinScheme s, AppLocalizations l) {
    final stats = _relaunchStats;
    final allSelected = _inactive.isNotEmpty && _selected.length == _inactive.length;
    return [
      Text(l.cstatInactiveTitle, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 2),
      Text(l.cstatInactiveHint, style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 12),
      Text(l.cstatThreshold, style: WinType.labelM(s.onMuted)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final d in const [3, 7, 14, 30])
          WinChip(l.cstatDays(d), active: _threshold == d, onTap: () => _setThreshold(d)),
      ]),
      if (stats != null && stats.sent > 0) ...[
        const SizedBox(height: 12),
        WinAlert(l.cstatRelaunchStats(stats.sent, (stats.rate ?? 0).toStringAsFixed(0)),
            type: BadgeColor.teal, icon: PhosphorIconsRegular.arrowsClockwise),
      ],
      const SizedBox(height: 12),
      if (_inactive.isEmpty)
        SizedBox(
          height: 200,
          child: WinEmptyState(
              icon: PhosphorIconsRegular.smiley, title: l.cstatNoInactive(_threshold), message: l.cstatInactiveHint),
        )
      else ...[
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l.cstatSelectAll),
          value: allSelected,
          onChanged: (v) => setState(() {
            _selected.clear();
            if (v == true) _selected.addAll(_inactive.map((x) => x.userId));
          }),
        ),
        for (final st in _inactive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WinCard(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              onTap: () => setState(() => _selected.contains(st.userId) ? _selected.remove(st.userId) : _selected.add(st.userId)),
              child: Row(children: [
                Checkbox(
                  value: _selected.contains(st.userId),
                  onChanged: (v) => setState(() => v == true ? _selected.add(st.userId) : _selected.remove(st.userId)),
                ),
                WinAvatar(st.name, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(st.name, style: WinType.titleS(s.onStrong)),
                    Text(
                        st.lastActivity == null
                            ? l.cstatInactiveDays(st.daysInactive)
                            : '${l.cstatInactiveDays(st.daysInactive)} · ${l.cstatLastActivity(WinFormat.dayMonth(st.lastActivity!))}',
                        style: WinType.labelS(st.daysInactive >= 2 * _threshold ? WinColors.error : s.onMuted)),
                  ]),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        WinButton(l.cstatRelaunch(_selected.length),
            block: true,
            icon: PhosphorIconsRegular.paperPlaneTilt,
            loading: _relaunching,
            onTap: _selected.isEmpty || _relaunching ? null : _relaunch),
      ],
    ];
  }

  // ---------------------------------------------------------------- Points

  Future<void> _save(Gamification g) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _g = g;
      _saving = true;
    });
    try {
      final saved = await _svc.saveGamification(widget.courseId, g);
      if (mounted) setState(() => _g = saved);
      messenger.showSnackBar(SnackBar(content: Text(l.cstatSaved)));
    } on CourseEditorException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _stepper(WinScheme s, String label, int value, ValueChanged<int> onChanged) => Row(children: [
        Expanded(child: Text(label, style: WinType.bodyM(s.onStrong))),
        IconButton(
            tooltip: '$label −',
            onPressed: _saving || value <= 0 ? null : () => onChanged(value - 5),
            icon: const Icon(PhosphorIconsRegular.minus)),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: WinType.titleS(s.onStrong))),
        IconButton(
            tooltip: '$label +',
            onPressed: _saving || value >= 500 ? null : () => onChanged(value + 5),
            icon: const Icon(PhosphorIconsRegular.plus)),
      ]);

  List<Widget> _pointsPart(WinScheme s, AppLocalizations l) {
    final g = _g;
    if (g == null) return [WinErrorState(message: l.commonLoadError, onRetry: _load)];
    return [
      Text(l.cstatGamification, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 2),
      Text(l.cstatGamificationHint, style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 8),
      WinCard(
        child: Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.cstatEnabled),
            value: g.enabled,
            onChanged: _saving ? null : (v) => _save(g.copyWith(enabled: v)),
          ),
          if (g.enabled) ...[
            _stepper(s, l.cstatPerLesson, g.pointsPerLesson, (v) => _save(g.copyWith(pointsPerLesson: v))),
            _stepper(s, l.cstatPerQuiz, g.pointsPerQuiz, (v) => _save(g.copyWith(pointsPerQuiz: v))),
            _stepper(s, l.cstatBonus, g.bonusPerfect, (v) => _save(g.copyWith(bonusPerfect: v))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.cstatBoardVisible),
              subtitle: Text(l.cstatBoardVisibleHint),
              value: g.leaderboardVisible,
              onChanged: _saving ? null : (v) => _save(g.copyWith(leaderboardVisible: v)),
            ),
          ],
        ]),
      ),
      if (g.enabled) ...[
        const SizedBox(height: 20),
        Text(l.cstatBoard, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        if (_board.isEmpty)
          Text(l.cstatNoPoints, style: WinType.bodyM(s.onMuted))
        else
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final b in _board.take(20))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: b.$1 <= 3
                          ? Icon(PhosphorIconsFill.medal,
                              size: 18, color: b.$1 == 1 ? WinColors.gold : (b.$1 == 2 ? s.onMuted : WinColors.warn))
                          : Text('${b.$1}', style: WinType.labelM(s.onMuted)),
                    ),
                    WinAvatar(b.$2, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b.$2, style: WinType.bodyM(s.onStrong))),
                    Text(l.cstatPoints(b.$3), style: WinType.labelM(s.onStrong)),
                  ]),
                ),
            ]),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final ls = _lessons;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (ls == null) {
      body = const WinLoading();
    } else {
      final part = switch (_part) {
        _Part.lessons => _lessonsPart(s, l, ls),
        _Part.students => _studentsPart(s, l),
        _Part.points => _pointsPart(s, l),
      };
      body = Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            for (final (p, label) in [
              (_Part.lessons, l.cstatTabLessons),
              (_Part.students, _inactive.isEmpty ? l.cstatTabStudents : '${l.cstatTabStudents} (${_inactive.length})'),
              (_Part.points, l.cstatTabPoints),
            ]) ...[
              Expanded(child: WinChip(label, active: _part == p, onTap: () => setState(() => _part = p))),
              if (p != _Part.points) const SizedBox(width: 8),
            ],
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: part),
          ),
        ),
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(child: body),
    );
  }
}
