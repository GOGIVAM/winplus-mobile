import 'dart:async';
import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/study_session_service.dart';
import '../services/subject_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Module 32 (lot 8, décision 14.3) : portage mobile de la session d'étude
/// guidée, déjà entièrement reconstruite côté web au lot 6
/// (frontend/src/pages/StudySession.tsx). Reproduit le même parcours en 3
/// phases (briefing → quiz progressif → synthèse WinAI) et le même écran
/// d'historique, en consommant tels quels les relais .NET existants
/// (phase2/quiz, phase3/summary, history) — aucune route n'est modifiée.
class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});
  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

enum _Phase {
  launcher,
  briefing,
  quizLoading,
  quiz,
  synthesisLoading,
  synthesis,
  done,
  history,
}

const _durations = [15, 25, 45, 60];

class _StudySessionScreenState extends State<StudySessionScreen> {
  _Phase _phase = _Phase.launcher;

  // Launcher
  List<ApiSubject> _subjects = [];
  bool _loadingSubjects = true;
  ApiSubject? _selectedSubject;
  int _selectedDuration = 25;
  bool _starting = false;
  String? _launcherError;

  // Session
  StudySessionData? _session;
  int? _userId;
  Timer? _timer;
  int _elapsedSec = 0;

  // Quiz
  List<Phase2Question> _questions = [];
  int _qIndex = 0;
  String? _selectedOption;
  int _correctCount = 0;

  // Synthèse
  Phase3Summary? _summary;
  bool _synthesisError = false;
  double _score = 0;

  // Historique
  List<StudySessionHistoryEntry>? _history;
  bool _historyLoading = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final page = await SubjectService.instance.getAll(pageSize: 20, page: 1);
      if (!mounted) return;
      setState(() {
        _subjects = page.items;
        _loadingSubjects = false;
        if (_subjects.isNotEmpty) _selectedSubject = _subjects.first;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  void _startTimer(int totalSeconds) {
    _timer?.cancel();
    _elapsedSec = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_elapsedSec < totalSeconds) _elapsedSec++;
      });
    });
  }

  Future<void> _startSession() async {
    final subject = _selectedSubject;
    if (subject == null) {
      setState(() => _launcherError = 'Choisis une matière pour commencer.');
      return;
    }
    setState(() {
      _starting = true;
      _launcherError = null;
    });
    try {
      final userId = await SessionManager.getUserId();
      _userId = userId;
      final session = await StudySessionService.instance.generate(
        userId: userId ?? 0,
        subjectId: subject.id,
        durationMinutes: _selectedDuration,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _starting = false;
        _phase = _Phase.briefing;
      });
      _startTimer(_selectedDuration * 60);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _launcherError = 'Impossible de démarrer la session. Réessaie.';
      });
    }
  }

  Future<void> _startQuiz() async {
    final session = _session;
    if (session == null) return;
    setState(() => _phase = _Phase.quizLoading);
    try {
      final questions = await StudySessionService.instance.phase2Quiz(
        userId: _userId ?? 0,
        subjectId: session.subject.id,
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _phase = _Phase.briefing;
          _launcherError = 'Impossible de générer le quiz. Réessaie dans un instant.';
        });
        return;
      }
      setState(() {
        _questions = questions;
        _qIndex = 0;
        _correctCount = 0;
        _selectedOption = null;
        _phase = _Phase.quiz;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.briefing;
        _launcherError = 'Impossible de générer le quiz. Réessaie dans un instant.';
      });
    }
  }

  void _answer(String option) {
    if (_selectedOption != null) return;
    final q = _questions[_qIndex];
    setState(() {
      _selectedOption = option;
      if (option == q.correct) _correctCount++;
    });
  }

  Future<void> _nextQuestion() async {
    if (_qIndex < _questions.length - 1) {
      setState(() {
        _qIndex++;
        _selectedOption = null;
      });
      return;
    }

    // Dernière question : calcule le score et demande la synthèse.
    final score = _questions.isEmpty
        ? 0.0
        : (_correctCount / _questions.length) * 100;
    setState(() {
      _score = score;
      _phase = _Phase.synthesisLoading;
    });
    final session = _session;
    try {
      final summary = await StudySessionService.instance.phase3Summary(
        userId: _userId ?? 0,
        subjectId: session?.subject.id ?? 0,
        score: score,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _synthesisError = false;
        _phase = _Phase.synthesis;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _synthesisError = true;
        _phase = _Phase.synthesis;
      });
    }
  }

  Future<void> _finishSession() async {
    final session = _session;
    _timer?.cancel();
    await StudySessionService.instance.complete(
      userId: _userId ?? 0,
      subjectId: session?.subject.id ?? 0,
      durationMinutes: session?.durationMinutes ?? _selectedDuration,
      score: _score,
      keyPoints: _summary?.keypoints ?? const [],
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
  }

  Future<void> _openHistory() async {
    setState(() {
      _phase = _Phase.history;
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final items = await StudySessionService.instance.history();
      if (!mounted) return;
      setState(() {
        _history = items;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Impossible de charger l\'historique.';
        _historyLoading = false;
      });
    }
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.launcher;
      _session = null;
      _questions = [];
      _summary = null;
      _synthesisError = false;
      _score = 0;
      _launcherError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
              _phase == _Phase.launcher || _phase == _Phase.done
                  ? Icons.arrow_back
                  : Icons.close,
              color: s.onStrong),
          onPressed: () {
            if (_phase == _Phase.history) {
              _restart();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("Session d'étude guidée", style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(child: _buildBody(s)),
    );
  }

  Widget _buildBody(WinScheme s) {
    switch (_phase) {
      case _Phase.launcher:
        return _buildLauncher(s);
      case _Phase.history:
        return _buildHistory(s);
      case _Phase.done:
        return _buildDone(s);
      default:
        return Column(children: [
          _buildHeader(s),
          Expanded(child: _buildPhaseContent(s)),
        ]);
    }
  }

  // ─── Lanceur ────────────────────────────────────────────────────────────

  Widget _buildLauncher(WinScheme s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choisis une matière et une durée. WinAI prépare un briefing, '
            'un quiz progressif puis une synthèse personnalisée.',
            style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 24),
        Text('Matière', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 10),
        if (_loadingSubjects)
          const Center(child: CircularProgressIndicator())
        else if (_subjects.isEmpty)
          WinAlert('Aucune matière disponible pour le moment.',
              type: BadgeColor.warn)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjects
                .map((subj) => WinChip(subj.title,
                    active: _selectedSubject?.id == subj.id,
                    onTap: () => setState(() => _selectedSubject = subj)))
                .toList(),
          ),
        const SizedBox(height: 24),
        Text('Durée', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _durations
              .map((d) => WinChip('$d min',
                  active: _selectedDuration == d,
                  onTap: () => setState(() => _selectedDuration = d)))
              .toList(),
        ),
        if (_launcherError != null) ...[
          const SizedBox(height: 16),
          WinAlert(_launcherError!, type: BadgeColor.error),
        ],
        const SizedBox(height: 28),
        WinButton('Démarrer la session',
            block: true, loading: _starting, onTap: _startSession),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: _openHistory,
            icon: Icon(Icons.history, size: 18, color: s.primary),
            label: Text('Voir mes sessions passées',
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ─── En-tête commun (briefing/quiz/synthèse) ───────────────────────────

  Widget _buildHeader(WinScheme s) {
    final session = _session;
    if (session == null) return const SizedBox.shrink();
    final total = session.durationMinutes * 60;
    final remaining = (total - _elapsedSec).clamp(0, total);
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');

    const stepOrder = ['briefing', 'quiz', 'synthesis'];
    final currentStepIdx = switch (_phase) {
      _Phase.briefing => 0,
      _Phase.quizLoading || _Phase.quiz => 1,
      _Phase.synthesisLoading || _Phase.synthesis => 2,
      _ => 0,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(session.subject.name,
                  style: WinType.titleL(s.onStrong))),
          Icon(Icons.timer_outlined, size: 16, color: s.onMuted),
          const SizedBox(width: 4),
          Text('$mm:$ss', style: WinType.labelM(s.onMuted)),
        ]),
        const SizedBox(height: 10),
        WinProgressBar(total == 0 ? 0 : (_elapsedSec / total) * 100,
            color: s.primary),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: List.generate(stepOrder.length, (i) {
            final labels = ['Briefing', 'Quiz progressif', 'Synthèse WinAI'];
            final done = i < currentStepIdx;
            final active = i == currentStepIdx;
            return WinBadge(
              done ? '✓ ${labels[i]}' : labels[i],
              color: done
                  ? BadgeColor.success
                  : (active ? BadgeColor.teal : BadgeColor.neutral),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildPhaseContent(WinScheme s) {
    switch (_phase) {
      case _Phase.briefing:
        return _buildBriefing(s);
      case _Phase.quizLoading:
      case _Phase.synthesisLoading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.quiz:
        return _buildQuiz(s);
      case _Phase.synthesis:
        return _buildSynthesis(s);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBriefing(WinScheme s) {
    final session = _session;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinCard(
            child: Text(session?.briefing ?? '',
                style: WinType.bodyM(s.onSurface).copyWith(height: 1.6))),
        if (_launcherError != null) ...[
          const SizedBox(height: 14),
          WinAlert(_launcherError!, type: BadgeColor.error),
        ],
        const SizedBox(height: 20),
        WinButton('Commencer le quiz', block: true, onTap: _startQuiz),
      ]),
    );
  }

  Widget _buildQuiz(WinScheme s) {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final q = _questions[_qIndex];
    final answered = _selectedOption != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Question ${_qIndex + 1} / ${_questions.length}',
            style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 10),
        Text(q.question, style: WinType.titleL(s.onStrong)),
        const SizedBox(height: 18),
        ...q.options.map((opt) {
          final isCorrect = opt == q.correct;
          final isChosen = opt == _selectedOption;
          Color? bg;
          Color? border;
          if (answered) {
            if (isCorrect) {
              bg = WinColors.successBg;
              border = WinColors.success;
            } else if (isChosen) {
              bg = WinColors.errorBg;
              border = WinColors.error;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: answered ? null : () => _answer(opt),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg ?? s.surface,
                  borderRadius: BorderRadius.circular(WinRadii.md),
                  border: Border.all(color: border ?? s.outline, width: 1.5),
                ),
                child: Text(opt,
                    style: WinType.bodyM(s.onSurface)
                        .copyWith(color: answered && (isCorrect || isChosen) ? null : null)),
              ),
            ),
          );
        }),
        if (answered) ...[
          const SizedBox(height: 10),
          WinAlert(q.explanation, type: BadgeColor.teal),
          const SizedBox(height: 20),
          WinButton(
            _qIndex < _questions.length - 1
                ? 'Question suivante'
                : 'Voir la synthèse',
            block: true,
            onTap: _nextQuestion,
          ),
        ],
      ]),
    );
  }

  Widget _buildSynthesis(WinScheme s) {
    final summary = _summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinBadge(
            '$_correctCount/${_questions.length} correctes · ${_score.round()}%',
            color: _score >= 50 ? BadgeColor.success : BadgeColor.warn),
        const SizedBox(height: 16),
        if (_synthesisError)
          WinAlert(
              "La synthèse n'a pas pu être générée, mais tes réponses sont bien conservées.",
              type: BadgeColor.warn)
        else if (summary != null) ...[
          Text(summary.summary, style: WinType.bodyM(s.onSurface).copyWith(height: 1.6)),
          const SizedBox(height: 14),
          Text(summary.performanceComment, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 14),
          ...summary.keypoints.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_outline, size: 18, color: s.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(k, style: WinType.bodyM(s.onSurface))),
                ]),
              )),
        ],
        const SizedBox(height: 24),
        WinButton('Terminer la session', block: true, onTap: _finishSession),
      ]),
    );
  }

  Widget _buildDone(WinScheme s) {
    final session = _session;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 72, color: WinColors.teal500),
          const SizedBox(height: 16),
          Text('Session terminée !', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 8),
          Text(
              'Score : ${_score.round()}% sur ${session?.subject.name ?? ''}',
              style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 28),
          WinButton('Retour', block: true, onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  // ─── Historique ─────────────────────────────────────────────────────────

  Widget _buildHistory(WinScheme s) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyError != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: WinAlert(_historyError!, type: BadgeColor.error),
      ));
    }
    final items = _history ?? [];
    if (items.isEmpty) {
      return Center(
          child: Text('Aucune session terminée pour le moment.',
              style: WinType.bodyM(s.onMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        final date = it.completedAt;
        final dateStr = date == null
            ? ''
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WinCard(
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(it.subject, style: WinType.titleM(s.onStrong)),
                    const SizedBox(height: 2),
                    Text(
                        '${it.duration} min · ${it.score != null ? '${it.score!.round()}%' : 'sans score'} · $dateStr',
                        style: WinType.bodyS(s.onMuted)),
                  ])),
            ]),
          ),
        );
      },
    );
  }
}
