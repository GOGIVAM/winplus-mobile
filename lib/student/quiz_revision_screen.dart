import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'quiz_screen.dart' show QuizActiveScreen;

// ─── Model ───────────────────────────────────────────────────────────────────

class QuizMistake {
  final String id, subject, question, givenAnswer, correctAnswer;
  final DateTime mistakeAt;
  const QuizMistake({
    required this.id,
    required this.subject,
    required this.question,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.mistakeAt,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class QuizRevisionScreen extends StatefulWidget {
  const QuizRevisionScreen({super.key});
  @override
  State<QuizRevisionScreen> createState() => _QuizRevisionScreenState();
}

class _QuizRevisionScreenState extends State<QuizRevisionScreen> {
  String _filter = 'Toutes';
  static const _filters = ['Toutes', 'Maths', 'Chimie', 'Physique', 'Français'];
  static const _filterToId = {
    'Maths': 'math',
    'Chimie': 'chimie',
    'Physique': 'pc',
    'Français': 'fr',
  };

  static final _mockMistakes = [
    QuizMistake(
      id: 'qm-001',
      subject: 'chimie',
      question: "Quelle est la formule de l'acide sulfurique ?",
      givenAnswer: 'HCl',
      correctAnswer: 'H₂SO₄',
      mistakeAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    QuizMistake(
      id: 'qm-002',
      subject: 'math',
      question: 'Calculer la limite de sin(x)/x quand x→0',
      givenAnswer: '0',
      correctAnswer: '1',
      mistakeAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    QuizMistake(
      id: 'qm-003',
      subject: 'pc',
      question: 'Unité du champ électrique ?',
      givenAnswer: 'Tesla',
      correctAnswer: 'V/m',
      mistakeAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<QuizMistake> get _filtered {
    if (_filter == 'Toutes') return _mockMistakes;
    final id = _filterToId[_filter];
    return _mockMistakes.where((m) => m.subject == id).toList();
  }

  String _relTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes}min';
    if (d.inHours < 24) return 'il y a ${d.inHours}h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quiz de révision', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('Questions que tu as ratées récemment',
                style: WinType.bodyM(s.onMuted)),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WinChip(f,
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Aucune question à réviser !\nTu maîtrises tout.',
                      style: WinType.bodyM(s.onMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MistakeCard(
                      mistake: items[i],
                      relTime: _relTime(items[i].mistakeAt),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: WinButton(
              'Lancer la révision',
              icon: Icons.play_arrow_rounded,
              block: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => QuizActiveScreen(quiz: WinData.quizDerivees))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mistake Card ─────────────────────────────────────────────────────────────

class _MistakeCard extends StatelessWidget {
  final QuizMistake mistake;
  final String relTime;
  const _MistakeCard({required this.mistake, required this.relTime});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(mistake.subject);

    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: subj.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(subj.short,
                style: WinType.manrope(
                    size: 11, weight: FontWeight.w700, color: subj.color)),
          ),
          const Spacer(),
          Text(relTime, style: WinType.labelS(s.onFaint)),
        ]),
        const SizedBox(height: 8),
        Text(
          mistake.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WinType.bodyM(s.onStrong),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.close, size: 14, color: WinColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(mistake.givenAnswer,
                style: WinType.labelM(WinColors.error)),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.check, size: 14, color: WinColors.success),
          const SizedBox(width: 4),
          Expanded(
            child: Text(mistake.correctAnswer,
                style: WinType.labelM(WinColors.success)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}
