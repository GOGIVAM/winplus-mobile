import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/quiz_service.dart';
import '../services/subscription_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

// ===================== QUIZ ACTIF =====================

class QuizActiveScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizActiveScreen({super.key, required this.quiz});
  @override
  State<QuizActiveScreen> createState() => _QuizActiveScreenState();
}

class _QuizActiveScreenState extends State<QuizActiveScreen> {
  int _current = 0;
  final List<int?> _answers = [];
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _answers.addAll(List.filled(widget.quiz.questions.length, null));
    _seconds = widget.quiz.durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        _finish();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _select(int idx) => setState(() => _answers[_current] = idx);

  void _next() {
    if (_current < widget.quiz.questions.length - 1) {
      setState(() => _current++);
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    final elapsed = widget.quiz.durationMinutes * 60 - _seconds;
    final correct = _answers.asMap().entries.where((e) {
      final q = widget.quiz.questions[e.key];
      return e.value == q.answer;
    }).length;
    final result = QuizResult(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      correct: correct,
      total: widget.quiz.questions.length,
      durationSeconds: elapsed,
      answers: List<int?>.from(_answers),
      date: 'Maintenant',
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) =>
              QuizResultScreen(result: result, quiz: widget.quiz)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final q = widget.quiz.questions[_current];
    final total = widget.quiz.questions.length;
    final timerRed = _seconds < 60;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.quiz.title, style: WinType.titleM(s.onStrong)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _timerLabel,
                style: WinType.archivo(
                    size: 16,
                    weight: FontWeight.w700,
                    color: timerRed ? WinColors.error : s.onStrong),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        WinProgressBar((_current + 1) / total * 100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('Question ${_current + 1} sur $total',
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              WinCard(
                padding: const EdgeInsets.all(20),
                child: Text(q.question, style: WinType.headlineS(s.onStrong)),
              ),
              const SizedBox(height: 16),
              ...q.options.asMap().entries.map((e) {
                final selected = _answers[_current] == e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _select(e.key),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? s.primaryContainer
                            : s.cardBg,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: selected ? s.primary : s.cardBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? s.primary : s.surface2,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + e.key),
                              style: WinType.manrope(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: selected
                                      ? s.onPrimary
                                      : s.onMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(e.value,
                                style: WinType.bodyM(s.onSurface))),
                      ]),
                    ),
                  ),
                );
              }),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: WinButton(
            _current < total - 1 ? 'Suivant' : 'Terminer le quiz',
            block: true,
            onTap: _answers[_current] != null ? _next : null,
          ),
        ),
      ]),
    );
  }
}

// ===================== RÉSULTATS =====================

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  final Quiz quiz;
  const QuizResultScreen(
      {super.key, required this.result, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final pct = result.score;
    final Color scoreColor = pct >= 70
        ? WinColors.success
        : pct >= 50
            ? WinColors.warn
            : WinColors.error;
    final String scoreLabel =
        pct >= 70 ? 'Excellent !' : pct >= 50 ? 'Bon travail' : 'À améliorer';
    final durMin = result.durationSeconds ~/ 60;
    final durSec = result.durationSeconds % 60;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Résultats', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 10,
                  backgroundColor: s.outline,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${pct.round()}%',
                    style: WinType.displayM(scoreColor)),
                Text(scoreLabel, style: WinType.labelM(s.onMuted)),
              ]),
            ]),
          ),
          const SizedBox(height: 28),
          Row(children: [
            _ResultStat('${result.correct}', 'Correctes', WinColors.success),
            const SizedBox(width: 10),
            _ResultStat('${result.total - result.correct}', 'Incorrectes',
                WinColors.error),
            const SizedBox(width: 10),
            _ResultStat('${durMin}m ${durSec}s', 'Durée', s.primary),
          ]),
          const SizedBox(height: 28),
          WinButton('Revoir les réponses',
              block: true,
              icon: Icons.rate_review_outlined,
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            QuizReviewScreen(quiz: quiz, result: result)),
                  )),
          const SizedBox(height: 10),
          WinButton('Refaire le quiz',
              variant: WinButtonVariant.outline,
              block: true,
              icon: Icons.refresh,
              onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QuizActiveScreen(quiz: quiz)),
                  )),
          const SizedBox(height: 10),
          WinButton('Retour au catalogue',
              variant: WinButtonVariant.ghost,
              block: true,
              onTap: () =>
                  Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ResultStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Expanded(
      child: WinCard(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Text(value,
              style:
                  WinType.archivo(size: 22, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: WinType.labelM(s.onMuted)),
        ]),
      ),
    );
  }
}

// ===================== RÉVISION =====================

class QuizReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;
  const QuizReviewScreen(
      {super.key, required this.quiz, required this.result});

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
        title: Text('Révision', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: quiz.questions.length,
        itemBuilder: (_, i) {
          final q = quiz.questions[i];
          final userAnswer = result.answers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${i + 1}. ${q.question}',
                  style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 10),
              ...q.options.asMap().entries.map((e) {
                final isCorrect = e.key == q.answer;
                final isSelected = e.key == userAnswer;
                Color bg = s.cardBg;
                Color border = s.outline;
                if (isCorrect) {
                  bg = WinColors.successBg;
                  border = WinColors.success;
                } else if (isSelected && !isCorrect) {
                  bg = WinColors.errorBg;
                  border = WinColors.error;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: border)),
                    child: Row(children: [
                      Icon(
                        isCorrect
                            ? Icons.check_circle
                            : isSelected
                                ? Icons.cancel
                                : Icons.radio_button_unchecked,
                        size: 16,
                        color: isCorrect
                            ? WinColors.success
                            : isSelected
                                ? WinColors.error
                                : s.onFaint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(e.value,
                              style: WinType.bodyS(s.onSurface))),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
              WinAlert(q.explain, type: BadgeColor.teal,
                  icon: Icons.lightbulb_outline),
            ]),
          );
        },
      ),
    );
  }
}

// ===================== CATALOGUE QUIZ =====================

class QuizHubScreen extends StatefulWidget {
  const QuizHubScreen({super.key});
  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  List<ApiQuiz>? _quizzes;
  ApiActiveSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      QuizService.instance.getAll(),
      SubscriptionService.instance.getCurrent(),
    ]);
    if (mounted) {
      setState(() {
        _quizzes = results[0] as List<ApiQuiz>;
        _sub = results[1] as ApiActiveSubscription?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final quizzes = _quizzes;
    final sub = _sub;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Quiz', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() { _quizzes = null; _sub = null; }); _load(); },
          ),
        ],
      ),
      body: quizzes == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (sub != null)
                  WinAlert(
                    '${sub.quizUsedToday}/${sub.quizDailyLimit == 0 ? '∞' : sub.quizDailyLimit} quiz aujourd\'hui',
                    type: BadgeColor.neutral,
                    icon: Icons.info_outline,
                  ),
                const SizedBox(height: 16),
                const WinSectionHeader('Quiz disponibles'),
                const SizedBox(height: 12),
                if (quizzes.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Aucun quiz disponible.', style: WinType.bodyM(s.onMuted)),
                  ))
                else
                  ...quizzes.map((q) {
                    final subj = WinData.subjectById(q.subjectCategory ?? 'math');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WinCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => QuizActiveScreen(quiz: q.toQuiz())),
                        ),
                        child: Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            color: subj.color.withValues(alpha: 0.12),
                            child: Icon(subj.icon, size: 24, color: subj.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(q.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WinType.titleM(s.onStrong)),
                            Text('${q.questions.length} questions · ${q.durationMinutes} min',
                                style: WinType.labelM(s.onMuted)),
                          ])),
                          const SizedBox(width: 8),
                          Icon(Icons.play_circle_outline, color: s.primary),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
