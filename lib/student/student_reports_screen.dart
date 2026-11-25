import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/student_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// « Mes rapports » : progression réelle de l'élève, calculée par le serveur
/// (GET /student/reports) à partir de ses quiz, sessions d'étude et
/// téléchargements, comme la page du site. Avant, tout l'écran était fait de
/// chiffres fixes (scores par matière, progression, 47 quiz, 74 %) et d'une
/// restriction de plan inventée.
class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});
  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  /// Périodes du site, en jours ; 30 par défaut.
  static const _periods = [7, 30, 90, 365];
  int _period = 30;

  ApiStudentReport? _report;
  bool _error = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final r = await StudentService.instance.getReport(_period);
      if (mounted) {
        setState(() {
          _report = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  void _select(int days) {
    if (days == _period) return;
    setState(() => _period = days);
    _load();
  }

  String _periodLabel(int days) => switch (days) {
        7 => context.l10n.studentReportsPeriod7,
        30 => context.l10n.studentReportsPeriod30,
        90 => context.l10n.studentReportsPeriod90,
        _ => context.l10n.studentHistPeriod1y,
      };

  Color _barColor(int score) {
    if (score >= 70) return WinColors.success;
    if (score >= 50) return WinColors.warn;
    return WinColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final r = _report;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.studentReportsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. Période
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _periods)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: WinChip(
                        _periodLabel(p),
                        active: _period == p,
                        onTap: () => _select(p),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading && r == null)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error && r == null)
              Column(children: [
                const SizedBox(height: 32),
                Text(l.studentReportsLoadError,
                    textAlign: TextAlign.center,
                    style: WinType.bodyM(s.onMuted)),
                const SizedBox(height: 12),
                WinButton(l.commonRetry,
                    variant: WinButtonVariant.outline, onTap: _load),
              ])
            else if (r != null)
              ..._content(r, s, l),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(ApiStudentReport r, WinScheme s, AppLocalizations l) {
    final weeklyMax = r.weeklyScores
        .map((w) => w.score ?? 0)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return [
      // 2. Score moyen
      WinCard(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(
            r.avgScore == null ? '—' : '${r.avgScore}%',
            style: WinType.archivo(
                size: 48,
                color: r.avgScore == null ? s.onMuted : _barColor(r.avgScore!)),
          ),
          const SizedBox(height: 4),
          Text(l.studentReportsAvgScore, style: WinType.labelM(s.onMuted)),
        ]),
      ),
      if (r.isEmpty) ...[
        const SizedBox(height: 16),
        Text(l.studentReportsNoData,
            textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
      ],
      const SizedBox(height: 24),

      // 3. Score par matière (seulement les matières réellement travaillées)
      if (r.subjectScores.isNotEmpty) ...[
        WinSectionHeader(l.studentReportsBySubject),
        for (final e in r.subjectScores)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                width: 96,
                child: Text(e.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.bodyM(s.onStrong)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: WinProgressBar(e.score.toDouble(),
                    color: _barColor(e.score)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text('${e.score}%',
                    textAlign: TextAlign.right,
                    style: WinType.labelM(s.onMuted)),
              ),
            ]),
          ),
        const SizedBox(height: 24),
      ],

      // 4. Progression hebdomadaire (semaines sans quiz : barre vide, « — »)
      if (r.weeklyScores.isNotEmpty && !r.isEmpty) ...[
        WinSectionHeader(l.studentReportsWeekly),
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final w in r.weeklyScores)
                  SizedBox(
                    width: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(w.score == null ? '—' : '${w.score}',
                              style: WinType.labelS(s.onFaint)),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Container(
                              height: ((w.score ?? 0) / weeklyMax) * 72,
                              decoration: BoxDecoration(
                                color: w.score == null
                                    ? s.outline
                                    : _barColor(w.score!),
                                borderRadius:
                                    BorderRadius.circular(WinRadii.full),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(WinFormat.dayMonthShort(w.weekStart.toLocal()),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: WinType.labelS(s.onMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],

      // 5. Quiz, étude et téléchargements
      WinSectionHeader(l.studentReportsQuiz),
      Row(children: [
        Expanded(child: _figure(s, '${r.quizTotal}', l.studentReportsQuizDone)),
        const SizedBox(width: 10),
        Expanded(
          child: _figure(
            s,
            r.quizSuccessRate == null ? '—' : '${r.quizSuccessRate}%',
            l.studentReportsSuccessRate,
            color: r.quizSuccessRate == null ? null : WinColors.success,
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _figure(s, WinFormat.number(r.studyHours.round()),
                l.studentReportsStudyHours)),
        const SizedBox(width: 10),
        Expanded(child: _figure(s, '${r.downloads}', l.studentReportsDownloads)),
      ]),
      if (r.bestSubject != null || r.weakestSubject != null) ...[
        const SizedBox(height: 12),
        WinCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.bestSubject != null)
              Row(children: [
                const Icon(PhosphorIconsFill.trophy, size: 16, color: WinColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.studentReportsBest(r.bestSubject!),
                      style: WinType.bodyM(s.onStrong)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ]),
            // Une seule matière travaillée : elle n'est pas aussi « à
            // travailler ».
            if (r.weakestSubject != null &&
                r.weakestSubject != r.bestSubject) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(PhosphorIconsRegular.warning,
                    size: 16, color: WinColors.warn),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(l.studentReportsWeakest(r.weakestSubject!),
                        style: WinType.bodyM(s.onMuted))),
              ]),
            ],
          ]),
        ),
      ],
      const SizedBox(height: 8),
    ];
  }

  Widget _figure(WinScheme s, String value, String label, {Color? color}) =>
      WinCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: WinType.archivo(size: 28, color: color ?? s.onStrong)),
          const SizedBox(height: 4),
          Text(label, style: WinType.labelM(s.onMuted)),
        ]),
      );
}
