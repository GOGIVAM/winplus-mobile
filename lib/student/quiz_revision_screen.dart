import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../services/quiz_mistakes_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_catalog_screen.dart';

/// Module 24 (lot 8, rattrapage 16.3) : révision des erreurs de quiz
/// branchée sur les vraies questions ratées (QuizMistakesController.cs,
/// mêmes endpoints que le web studentExtraService.getMistakes), remplace
/// les 3 questions fictives codées en dur de l'ancien écran.
///
/// « Lancer la révision » renvoie au catalogue (pas de quiz "dérivé des
/// erreurs" généré côté serveur à ce jour — créer cette route sort du
/// périmètre du portage, décision §16.3 du suivi : réutiliser l'existant).
class QuizRevisionScreen extends StatefulWidget {
  const QuizRevisionScreen({super.key});
  @override
  State<QuizRevisionScreen> createState() => _QuizRevisionScreenState();
}

class _QuizRevisionScreenState extends State<QuizRevisionScreen> {
  String _filter = 'Toutes';
  List<ApiMistakeSubject> _subjects = [];
  List<ApiQuizMistake>? _mistakes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadMistakes();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await QuizMistakesService.instance.getSubjects();
      if (mounted) setState(() => _subjects = subjects);
    } catch (_) {}
  }

  Future<void> _loadMistakes() async {
    setState(() => _error = false);
    try {
      final mistakes = await QuizMistakesService.instance.getMistakes(subject: _filter);
      if (mounted) setState(() => _mistakes = mistakes);
    } catch (_) {
      if (mounted) setState(() {
        _mistakes = [];
        _error = true;
      });
    }
  }

  String _relTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes}min';
    if (d.inHours < 24) return 'il y a ${d.inHours}h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays}j';
  }

  Future<void> _resolve(ApiQuizMistake m) async {
    try {
      await QuizMistakesService.instance.resolve(m.id);
      await _loadMistakes();
      await _loadSubjects();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _mistakes;
    final filters = ['Toutes', ..._subjects.map((e) => e.subject)];

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
          if (filters.length > 1)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: filters
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: WinChip(f,
                              active: _filter == f,
                              onTap: () {
                                setState(() => _filter = f);
                                _loadMistakes();
                              }),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: items == null
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? Center(
                        child: Text('Impossible de charger tes erreurs.',
                            style: WinType.bodyM(s.onMuted)))
                    : items.isEmpty
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
                              relTime: _relTime(items[i].createdAt),
                              onResolve: () => _resolve(items[i]),
                            ),
                          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: WinButton(
              'Revoir le catalogue',
              icon: Icons.play_arrow_rounded,
              block: true,
              onTap: () => Navigator.push(
                  context, WinPageRoute(builder: (_) => const CourseCatalogScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final ApiQuizMistake mistake;
  final String relTime;
  final VoidCallback onResolve;
  const _MistakeCard({required this.mistake, required this.relTime, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (mistake.subject != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: s.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(WinRadii.full),
              ),
              child: Text(mistake.subject!,
                  style: WinType.manrope(size: 11, weight: FontWeight.w700, color: s.primary)),
            ),
          const Spacer(),
          Text(relTime, style: WinType.labelS(s.onFaint)),
        ]),
        const SizedBox(height: 8),
        Text(
          mistake.question,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: WinType.bodyM(s.onStrong),
        ),
        if (mistake.givenAnswer != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.close, size: 14, color: WinColors.error),
            const SizedBox(width: 4),
            Expanded(
              child: Text(mistake.givenAnswer!, style: WinType.labelM(WinColors.error)),
            ),
          ]),
        ],
        if (mistake.correctAnswer != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.check, size: 14, color: WinColors.success),
            const SizedBox(width: 4),
            Expanded(
              child: Text(mistake.correctAnswer!,
                  style: WinType.labelM(WinColors.success).copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: WinButton('Maîtrisé', small: true, variant: WinButtonVariant.outline, onTap: onResolve),
        ),
      ]),
    );
  }
}
