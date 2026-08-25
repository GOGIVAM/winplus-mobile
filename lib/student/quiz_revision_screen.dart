import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'quiz_screen.dart' show QuizActiveScreen;

class QuizRevisionScreen extends StatefulWidget {
  const QuizRevisionScreen({super.key});
  @override
  State<QuizRevisionScreen> createState() => _QuizRevisionScreenState();
}

class _QuizRevisionScreenState extends State<QuizRevisionScreen> {
  String _filter = 'Tout';
  static const _filters = ['Tout', 'Maths', 'Physique', 'Chimie', 'Français'];

  static final _missedQuestions = WinData.quizDerivees.questions
      .where((q) => q.answer != 0)
      .toList();

  void _launchRevision() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => QuizActiveScreen(quiz: WinData.quizDerivees)));
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
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quiz de révision', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WinColors.blue50,
              border: Border.all(color: WinColors.blue100),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Questions ratées récemment',
                  style: WinType.titleL(WinColors.blue700)),
              const SizedBox(height: 6),
              Text('Entraîne-toi sur tes erreurs pour progresser',
                  style: WinType.bodyS(WinColors.blue700)),
              const SizedBox(height: 12),
              WinButton(
                'Lancer la révision →',
                small: true,
                onTap: _launchRevision,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Filtrer par matière',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WinChip(f,
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Questions à revoir',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ..._missedQuestions.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QuestionRow(
              question: q.question,
              subject: WinData.subjectById(WinData.quizDerivees.subjectId).short,
              onRevise: _launchRevision,
            ),
          )),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final String question, subject;
  final VoidCallback onRevise;
  const _QuestionRow({
    required this.question,
    required this.subject,
    required this.onRevise,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WinType.bodyM(s.onStrong)),
            const SizedBox(height: 8),
            WinChip(subject),
          ]),
        ),
        const SizedBox(width: 10),
        WinButton('Réviser',
            small: true,
            variant: WinButtonVariant.outline,
            onTap: onRevise),
      ]),
    );
  }
}
