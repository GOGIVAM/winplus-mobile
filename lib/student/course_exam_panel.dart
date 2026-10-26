import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'quiz_screen.dart';
import 'student_tabs.dart' show StudentWinAITab;
import 'study_session_screen.dart';

/// Examen de formation dans le lecteur mobile : quiz de fin de module ou
/// examen final (parité web, décision du 2026-10-26).
///
/// Après un échec, WinAI propose de quoi combler les lacunes (plan de
/// révision, quiz d'entraînement, session de travail, leçons à revoir) ;
/// après 3 échecs de suite, l'examen se rouvre 24 h plus tard et seules ces
/// propositions restent affichées.
class CourseExamPanel extends StatefulWidget {
  final int courseId;
  final int quizId;
  final bool isFinal;

  /// Seuil de réussite affiché (examen final) ; null pour un quiz de module.
  final int? passScore;

  /// Appelé après chaque tentative envoyée : le lecteur relit la progression.
  final Future<void> Function() onAttempted;
  final void Function(int lessonId) onOpenLesson;

  const CourseExamPanel({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.isFinal,
    this.passScore,
    required this.onAttempted,
    required this.onOpenLesson,
  });

  @override
  State<CourseExamPanel> createState() => _CourseExamPanelState();
}

class _CourseExamPanelState extends State<CourseExamPanel> {
  ExamRetakeStatus? _status;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final s = await CourseService.instance.getExamRetake(widget.courseId, widget.quizId);
      if (mounted) setState(() { _status = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final quiz = (await QuizService.instance.getById(widget.quizId)).toQuiz();
      if (!mounted) return;
      await Navigator.push(
        context,
        WinPageRoute(builder: (_) => QuizActiveScreen(quiz: quiz, courseExam: true)),
      );
      await widget.onAttempted();
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.studentExamLoadFailed)));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  List<String> get _topics =>
      (_status?.weakPoints ?? []).map((w) => w.topic ?? w.question).take(5).toList();

  void _askWinAI({bool practice = false}) {
    final s = _status;
    if (s == null) return;
    final l = context.l10n;
    final points = _topics.isEmpty ? l.studentExamNoWeakPoints : _topics.map((p) => '- $p').join('\n');
    final message = practice
        ? l.studentExamPracticePrompt(s.examTitle, points)
        : l.studentExamPlanPrompt(s.consecutiveFailures, s.examTitle, s.courseTitle, points);
    Navigator.push(context, WinPageRoute(builder: (_) => StudentWinAITab(initialMessage: message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: WinColors.teal400)),
      );
    }
    final s = _status;
    final locked = s?.locked ?? false;
    final failed = (s?.consecutiveFailures ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(WinRadii.lg),
        border: Border.all(color: WinColors.teal600.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(widget.isFinal ? Icons.workspace_premium : Icons.quiz_outlined,
              color: WinColors.teal400),
          const SizedBox(width: 10),
          Expanded(
              child: Text(widget.isFinal ? l.studentExamFinalTitle : l.studentExamModuleTitle,
                  style: WinType.titleM(Colors.white))),
        ]),
        const SizedBox(height: 8),
        if (widget.isFinal && widget.passScore != null)
          Text(l.studentExamFinalIntro(widget.passScore!), style: WinType.bodyM(Colors.white70)),
        if (locked) ...[
          const SizedBox(height: 8),
          Text(l.studentExamPausedTitle, style: WinType.titleM(WinColors.gold)),
          const SizedBox(height: 4),
          Text(
            l.studentExamPausedBody(
              s!.consecutiveFailures,
              s.lockedUntil == null
                  ? ''
                  : DateFormat.MMMMEEEEd(L10n.code).add_Hm().format(s.lockedUntil!),
            ),
            style: WinType.bodyM(Colors.white70),
          ),
        ] else ...[
          if (failed) ...[
            const SizedBox(height: 8),
            Text(l.studentExamRemaining(s!.remaining), style: WinType.bodyM(Colors.white70)),
          ],
          const SizedBox(height: 12),
          WinButton(
            _starting ? l.studentExamLoading : (failed ? l.studentExamRetry : l.studentExamStart),
            onTap: _starting ? null : _start,
          ),
        ],
        if (locked || failed) ...[
          if (s!.weakPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.studentExamWeakTitle, style: WinType.labelM(Colors.white)),
            const SizedBox(height: 6),
            ...s.weakPoints.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ${w.question}', style: WinType.bodyM(Colors.white)),
                    if (w.explanation != null && w.explanation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(w.explanation!, style: WinType.labelS(Colors.white54)),
                      ),
                  ]),
                )),
          ],
          const SizedBox(height: 12),
          Text(l.studentExamHelpTitle, style: WinType.labelM(Colors.white)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Action(icon: Icons.smart_toy_outlined, label: l.studentExamAskWinAI, onTap: () => _askWinAI()),
            _Action(icon: Icons.checklist, label: l.studentExamPractice, onTap: () => _askWinAI(practice: true)),
            _Action(
              icon: Icons.timer_outlined,
              label: l.studentExamStudySession,
              onTap: () => Navigator.push(
                  context, WinPageRoute(builder: (_) => const StudySessionScreen())),
            ),
          ]),
          if (s.lessons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l.studentExamLessonsTitle, style: WinType.labelM(Colors.white)),
            const SizedBox(height: 6),
            ...s.lessons.map((lesson) => InkWell(
                  onTap: () => widget.onOpenLesson(lesson.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.menu_book_outlined, size: 16, color: WinColors.teal400),
                      const SizedBox(width: 8),
                      Expanded(child: Text(lesson.title, style: WinType.bodyM(Colors.white70))),
                    ]),
                  ),
                )),
          ],
        ],
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: WinColors.teal400),
      label: Text(label, style: WinType.labelM(Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: WinColors.teal600.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
