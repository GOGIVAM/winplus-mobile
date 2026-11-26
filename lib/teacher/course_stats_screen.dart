import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/course_editor_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Suivi et ludification » d'une formation (lot 7), comme les panneaux
/// CourseGamificationPanel et statistiques des leçons du site : réglages
/// des points et du classement, classement des élèves, suivi de chaque
/// leçon (complétion, visionnage, score) avec alerte sous 40 %.
class CourseStatsScreen extends StatefulWidget {
  final int courseId;
  final String title;
  const CourseStatsScreen({super.key, required this.courseId, required this.title});

  @override
  State<CourseStatsScreen> createState() => _CourseStatsScreenState();
}

class _CourseStatsScreenState extends State<CourseStatsScreen> {
  final _svc = CourseEditorService.instance;
  Gamification? _g;
  List<(int, String, int)> _board = const [];
  List<LessonStats> _lessons = const [];
  bool _error = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final g = await _svc.gamification(widget.courseId);
      final r = await Future.wait([
        _svc.leaderboard(widget.courseId).catchError((_) => <(int, String, int)>[]),
        _svc.lessonStats(widget.courseId).catchError((_) => <LessonStats>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _g = g;
        _board = r[0] as List<(int, String, int)>;
        _lessons = r[1] as List<LessonStats>;
      });
    } catch (_) {
      if (mounted && _g == null) setState(() => _error = true);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final g = _g;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (g == null) {
      body = const WinLoading();
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.cstatLessons, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          if (_lessons.isEmpty)
            Text(l.cstatNoLesson, style: WinType.bodyM(s.onMuted))
          else
            WinCard(
              child: Column(children: [
                for (final x in _lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(x.title, style: WinType.labelM(s.onStrong))),
                        Text('${x.completionRate.round()} %',
                            style: WinType.labelM(x.lowCompletion ? WinColors.error : s.onStrong)),
                      ]),
                      const SizedBox(height: 4),
                      WinProgressBar(x.completionRate.clamp(0, 100).toDouble(),
                          color: x.lowCompletion ? WinColors.error : WinColors.teal600, height: 6),
                      Text(
                          [
                            l.cstatCompleted(x.completed),
                            if (x.watchSec > 0) l.cstatWatch((x.watchSec / 60).round()),
                            if (x.quizScore != null) l.cstatQuiz('${(x.quizScore! / 5).toStringAsFixed(1)} / 20'),
                          ].join(' · '),
                          style: WinType.labelS(s.onMuted)),
                    ]),
                  ),
              ]),
            ),
          const SizedBox(height: 20),
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
                        SizedBox(width: 28, child: Text('${b.$1}', style: WinType.labelM(s.onMuted))),
                        Expanded(child: Text(b.$2, style: WinType.bodyM(s.onStrong))),
                        Text(l.cstatPoints(b.$3), style: WinType.labelM(s.onStrong)),
                      ]),
                    ),
                ]),
              ),
          ],
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(child: body),
    );
  }
}
