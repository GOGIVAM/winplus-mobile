import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Module 15 (lot 6) : portage mobile du questionnaire VARK, jusqu'ici
/// disponible uniquement sur le web (frontend/src/features/learningStyle/
/// LearningStyleQuiz.tsx). Même endpoint (POST /ai/learning-style) et même
/// champ de persistance (PUT /users/profile { learningStyle }), pour que la
/// donnée enregistrée soit strictement la même quelle que soit la
/// plateforme  version réduite à 6 questions (au lieu de 12) pour un
/// parcours mobile plus court, sans changer les catégories VARK ni le
/// contrat avec le backend.
class LearningStyleQuizScreen extends StatefulWidget {
  const LearningStyleQuizScreen({super.key});
  @override
  State<LearningStyleQuizScreen> createState() => _LearningStyleQuizScreenState();
}

class _VarkQuestion {
  final String id;
  final String text;
  final List<(String label, String tag)> options;
  const _VarkQuestion(this.id, this.text, this.options);
}

List<_VarkQuestion> get _questions => <_VarkQuestion>[
  _VarkQuestion('q1', L10n.current.studentVarkQ1, [
    (L10n.current.studentVarkQ1V, 'V'),
    (L10n.current.studentVarkQ1A, 'A'),
    (L10n.current.studentVarkQ1R, 'R'),
    (L10n.current.studentVarkQ1K, 'K'),
  ]),
  _VarkQuestion('q2', L10n.current.studentVarkQ2, [
    (L10n.current.studentVarkQ2V, 'V'),
    (L10n.current.studentVarkQ2A, 'A'),
    (L10n.current.studentVarkQ2R, 'R'),
    (L10n.current.studentVarkQ2K, 'K'),
  ]),
  _VarkQuestion('q3', L10n.current.studentVarkQ3, [
    (L10n.current.studentVarkQ3V, 'V'),
    (L10n.current.studentVarkQ3A, 'A'),
    (L10n.current.studentVarkQ3R, 'R'),
    (L10n.current.studentVarkQ3K, 'K'),
  ]),
  _VarkQuestion('q4', L10n.current.studentVarkQ4, [
    (L10n.current.studentVarkQ4V, 'V'),
    (L10n.current.studentVarkQ4A, 'A'),
    (L10n.current.studentVarkQ4R, 'R'),
    (L10n.current.studentVarkQ4K, 'K'),
  ]),
  _VarkQuestion('q5', L10n.current.studentVarkQ5, [
    (L10n.current.studentVarkQ5V, 'V'),
    (L10n.current.studentVarkQ5A, 'A'),
    (L10n.current.studentVarkQ5R, 'R'),
    (L10n.current.studentVarkQ5K, 'K'),
  ]),
  _VarkQuestion('q6', L10n.current.studentVarkQ6, [
    (L10n.current.studentVarkQ6V, 'V'),
    (L10n.current.studentVarkQ6A, 'A'),
    (L10n.current.studentVarkQ6R, 'R'),
    (L10n.current.studentVarkQ6K, 'K'),
  ]),
];

Map<String, String> get _styleLabels => {
  'visual': L10n.current.studentVarkVisual,
  'auditory': L10n.current.studentVarkAuditory,
  'reading_writing': L10n.current.studentVarkReadWrite,
  'kinesthetic': L10n.current.studentVarkKinesthetic,
  'mixed': L10n.current.studentVarkMixed,
};

const _letterToStyle = {
  'V': 'visual', 'A': 'auditory', 'R': 'reading_writing', 'K': 'kinesthetic',
};

class _LearningStyleQuizScreenState extends State<LearningStyleQuizScreen> {
  int _currentIdx = 0;
  final List<Map<String, String>> _answers = [];
  bool _submitting = false;
  String? _resultStyle;
  String? _resultLabel;
  bool _applying = false;
  bool _applied = false;

  Future<void> _select(String tag) async {
    _answers.add({'question_id': _questions[_currentIdx].id, 'style_tag': tag});
    if (_currentIdx < _questions.length - 1) {
      setState(() => _currentIdx++);
      return;
    }
    setState(() => _submitting = true);
    String style;
    try {
      final res = await ApiClient.instance.dio.post('/ai/learning-style', data: {'answers': _answers});
      final data = res.data is Map ? res.data as Map : {};
      style = (data['style'] as String?) ?? _localFallback();
    } catch (_) {
      style = _localFallback();
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _resultStyle = style;
      _resultLabel = _styleLabels[style] ?? style;
    });
  }

  String _localFallback() {
    final scores = <String, int>{'V': 0, 'A': 0, 'R': 0, 'K': 0};
    for (final a in _answers) {
      final tag = a['style_tag'];
      if (tag != null && scores.containsKey(tag)) scores[tag] = scores[tag]! + 1;
    }
    final dominant = scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _letterToStyle[dominant] ?? 'reading_writing';
  }

  Future<void> _apply() async {
    if (_resultStyle == null || _applying) return;
    setState(() => _applying = true);
    await UserService.instance.updateProfile(learningStyle: _resultStyle);
    if (!mounted) return;
    setState(() {
      _applying = false;
      _applied = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context, _resultStyle);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    if (_resultStyle != null) {
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(
          backgroundColor: s.bg,
          elevation: 0,
          title: Text(context.l10n.studentVarkTitle, style: WinType.headlineS(s.onStrong)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_resultLabel ?? '', style: WinType.displayS(s.onStrong)),
              const SizedBox(height: 12),
              Text(
                context.l10n.studentVarkSaved,
                style: WinType.bodyM(s.onMuted),
              ),
              const Spacer(),
              WinButton(
                _applied ? context.l10n.studentVarkApplied : (_applying ? context.l10n.studentVarkApplying : context.l10n.studentVarkApply),
                block: true,
                loading: _applying,
                onTap: _applied ? null : _apply,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    final q = _questions[_currentIdx];
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        title: Text(context.l10n.studentVarkTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WinProgressBar(((_currentIdx) / _questions.length) * 100, height: 3, color: s.primary),
            const SizedBox(height: 8),
            Text(context.l10n.studentVarkQuestionCount(_currentIdx + 1, _questions.length), style: WinType.labelS(s.onMuted)),
            const SizedBox(height: 20),
            Text(q.text, style: WinType.titleL(s.onStrong)),
            const SizedBox(height: 24),
            Expanded(
              child: _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: q.options.map((opt) {
                        final (label, tag) = opt;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _select(tag),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: s.surface,
                                borderRadius: BorderRadius.circular(WinRadii.md),
                                border: Border.all(color: s.outline, width: 1.5),
                              ),
                              child: Text(label, style: WinType.bodyM(s.onSurface)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
