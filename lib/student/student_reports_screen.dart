import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});
  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  String _period = '30j';
  static const _periods = ['7j', '30j', '90j', '1 an'];

  static const _quizHistory = [
    (title: 'Quiz Dérivées & Limites', score: 80, date: "Aujourd'hui"),
    (title: 'Quiz Chimie organique', score: 60, date: 'il y a 4j'),
    (title: 'Quiz Physique — Circuits', score: 45, date: 'il y a 1 sem.'),
    (title: 'Quiz Maths — Vecteurs', score: 72, date: 'il y a 2 sem.'),
  ];

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
        title: Text('Mes rapports', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _periods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WinChip(p,
                    active: _period == p,
                    onTap: () => setState(() => _period = p)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Score par matière',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ...WinData.subjectScores.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubjectBar(subject: e.key, score: e.value),
          )),
          const SizedBox(height: 24),
          Text('Statistiques générales',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.local_fire_department, size: 20, color: WinColors.warn),
                  const SizedBox(height: 8),
                  Text('${WinData.streak}j',
                      style: WinType.archivo(size: 22, color: s.onStrong)),
                  Text('Série', style: WinType.labelM(s.onMuted)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.quiz_outlined, size: 20, color: s.primary),
                  const SizedBox(height: 8),
                  Text('${WinData.quizWeek}',
                      style: WinType.archivo(size: 22, color: s.onStrong)),
                  Text('Quiz/sem.', style: WinType.labelM(s.onMuted)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.bar_chart_outlined, size: 20, color: WinColors.success),
                  const SizedBox(height: 8),
                  Text('${WinData.avgScore}%',
                      style: WinType.archivo(size: 22, color: s.onStrong)),
                  Text('Moy.', style: WinType.labelM(s.onMuted)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Historique des quiz',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          WinCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              for (int i = 0; i < _quizHistory.length; i++)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: i < _quizHistory.length - 1
                        ? Border(bottom: BorderSide(color: s.outline))
                        : null,
                  ),
                  child: _QuizHistoryRow(
                    title: _quizHistory[i].title,
                    score: _quizHistory[i].score,
                    date: _quizHistory[i].date,
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 24),
          WinButton(
            'Exporter PDF',
            variant: WinButtonVariant.outline,
            block: true,
            icon: Icons.download_outlined,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF en cours de génération...')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final String subject;
  final int score;
  const _SubjectBar({required this.subject, required this.score});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(subject);
    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(subj.short,
            style: WinType.bodyM(s.onStrong)
                .copyWith(fontWeight: FontWeight.w600)),
      ),
      Expanded(child: WinProgressBar(score.toDouble(), color: subj.color)),
      const SizedBox(width: 8),
      SizedBox(
        width: 40,
        child: Text('$score%',
            textAlign: TextAlign.right,
            style: WinType.labelM(s.onMuted)),
      ),
    ]);
  }
}

class _QuizHistoryRow extends StatelessWidget {
  final String title, date;
  final int score;
  const _QuizHistoryRow({required this.title, required this.score, required this.date});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final color = score >= 70 ? WinColors.success : (score >= 50 ? WinColors.warn : WinColors.error);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.bodyM(s.onStrong)
                  .copyWith(fontWeight: FontWeight.w600)),
          Text(date, style: WinType.labelM(s.onMuted)),
        ]),
      ),
      Text('$score%', style: WinType.archivo(size: 16, color: color)),
    ]);
  }
}
