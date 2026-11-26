import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/winai_productions_service.dart';
import '../../services/winai_studio_service.dart';
import '../../shell/more_screen.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';
import '../../widgets/winai_markdown.dart';

const _examTypes = ['interrogation', 'devoir', 'composition', 'examen-blanc'];

String examTypeLabel(BuildContext context, String type) {
  final l = context.l10n;
  return switch (type) {
    'interrogation' => l.winaiExamTypeTest,
    'devoir' => l.winaiExamTypeAssignment,
    'composition' => l.winaiExamTypeTerm,
    'examen-blanc' => l.winaiExamTypeMock,
    _ => type,
  };
}

String _points(double p) => p == p.roundToDouble()
    ? p.toStringAsFixed(0)
    : p.toString().replaceAll('.', L10n.isEn ? '.' : ',');

/// Réglages d'une épreuve complète : matière, chapitre, classe, type, durée,
/// barème et nombre d'exercices. Rend la demande par Navigator.pop.
class WinAIExamSettings extends StatefulWidget {
  const WinAIExamSettings({super.key});
  @override
  State<WinAIExamSettings> createState() => _WinAIExamSettingsState();
}

class _WinAIExamSettingsState extends State<WinAIExamSettings> {
  final _subject = TextEditingController();
  final _topic = TextEditingController();
  final _level = TextEditingController();
  String _type = 'devoir';
  int _duration = 120;
  int _total = 20;
  int _exercises = 3;
  bool _missing = false;

  @override
  void dispose() {
    _subject.dispose();
    _topic.dispose();
    _level.dispose();
    super.dispose();
  }

  void _submit() {
    if (_subject.text.trim().isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.pop<WinAIExamRequest>(context, (
      subject: _subject.text.trim(),
      topic: _topic.text.trim(),
      level: _level.text.trim(),
      examType: _type,
      durationMinutes: _duration,
      totalPoints: _total,
      exercises: _exercises,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: WinType.titleM(s.onStrong)));
    Widget chips<T>(List<T> values, T current, String Function(T) text,
            ValueChanged<T> pick) =>
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            WinChip(text(v),
                active: v == current, onTap: () => setState(() => pick(v))),
        ]);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          WinTextField(
              label: l.commonSubject,
              hint: l.winaiExamSubjectHint,
              controller: _subject,
              onChanged: (_) {
                if (_missing) setState(() => _missing = false);
              }),
          if (_missing)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.winaiExamSubjectRequired,
                    style: WinType.labelM(WinColors.error))),
          const SizedBox(height: 14),
          WinTextField(
              label: l.winaiSettingsTopic,
              hint: l.winaiSettingsTopicHint,
              controller: _topic),
          const SizedBox(height: 14),
          WinTextField(
              label: l.winaiExamClass,
              hint: l.winaiExamClassHint,
              controller: _level),
          const SizedBox(height: 18),
          label(l.winaiExamType),
          chips<String>(_examTypes, _type, (t) => examTypeLabel(context, t),
              (v) => _type = v),
          const SizedBox(height: 18),
          label(l.winaiExamDuration),
          chips<int>(const [30, 60, 120, 180, 240], _duration,
              (m) => l.winaiExamMinutes(m), (v) => _duration = v),
          const SizedBox(height: 18),
          label(l.winaiExamTotal),
          chips<int>(const [10, 20, 40, 100], _total, (p) => '$p',
              (v) => _total = v),
          const SizedBox(height: 18),
          label(l.winaiExamExercises),
          chips<int>(const [1, 2, 3, 4, 5, 6], _exercises, (n) => '$n',
              (v) => _exercises = v),
          const SizedBox(height: 14),
          Text(l.winaiExamWait, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 18),
          WinButton(l.winaiSettingsGenerate,
              block: true, icon: PhosphorIconsRegular.sparkle, onTap: _submit),
          const SizedBox(height: 8),
        ]);
  }
}

/// Épreuve générée : le sujet exercice par exercice, puis le corrigé et le
/// barème quand le professeur les demande.
class WinAIExamScreen extends StatefulWidget {
  final WinAIExam exam;
  const WinAIExamScreen({super.key, required this.exam});
  @override
  State<WinAIExamScreen> createState() => _WinAIExamScreenState();
}

class _WinAIExamScreenState extends State<WinAIExamScreen> {
  bool _answers = false;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final e = widget.exam;
    final meta = [
      if (e.examType.isNotEmpty) examTypeLabel(context, e.examType),
      if (e.level.isNotEmpty) e.level,
      if (e.durationMinutes > 0) l.winaiExamMinutes(e.durationMinutes),
      if (e.totalPoints > 0) l.winaiExamOutOf(_points(e.totalPoints)),
    ].join(' · ');
    Widget pts(double p) => Text(l.winaiExamPointsShort(_points(p)),
        style: WinType.labelM(s.primary));
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.winaiToolExam), actions: [
        IconButton(
            tooltip: _answers ? l.winaiExamHideAnswers : l.winaiExamShowAnswers,
            icon: Icon(_answers
                ? PhosphorIconsRegular.eyeSlash
                : PhosphorIconsRegular.eye),
            onPressed: () => setState(() => _answers = !_answers)),
      ]),
      body: e.exercises.isEmpty
          ? WinEmptyState(
              title: l.winaiExamEmpty, icon: PhosphorIconsRegular.exam)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(e.title, style: WinType.displayS(s.onStrong)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: WinType.bodyS(s.onMuted)),
                ],
                const SizedBox(height: 12),
                Align(child: WinButton(
                    _answers ? l.winaiExamHideAnswers : l.winaiExamShowAnswers,
                    variant: WinButtonVariant.outline,
                    icon: _answers
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
                    onTap: () => setState(() => _answers = !_answers))),
                if (e.instructions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  WinAIMarkdown(e.instructions, color: s.onSurface),
                ],
                for (var i = 0; i < e.exercises.length; i++) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: s.cardBg,
                        borderRadius: BorderRadius.circular(WinRadii.lg),
                        border: Border.all(color: s.cardBorder)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Text(
                                        e.exercises[i].title.isEmpty
                                            ? l.winaiExamExercise(i + 1)
                                            : e.exercises[i].title,
                                        style: WinType.titleL(s.onStrong))),
                                const SizedBox(width: 8),
                                pts(e.exercises[i].points),
                              ]),
                          if (e.exercises[i].context.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            WinAIMarkdown(e.exercises[i].context,
                                color: s.onSurface),
                          ],
                          for (final q in e.exercises[i].questions) ...[
                            const SizedBox(height: 12),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${q.number}. ',
                                      style: WinType.titleM(s.onStrong)),
                                  Expanded(
                                      child: WinAIMarkdown(q.statement,
                                          color: s.onSurface)),
                                  const SizedBox(width: 8),
                                  pts(q.points),
                                ]),
                            if (_answers)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: s.primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(WinRadii.md)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l.winaiExamAnswer,
                                          style: WinType.labelM(s.primary)),
                                      const SizedBox(height: 4),
                                      WinAIMarkdown(q.answer,
                                          color: s.onStrong),
                                      if (q.scoringGuide.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(l.winaiExamScoring,
                                            style: WinType.labelM(s.primary)),
                                        const SizedBox(height: 4),
                                        WinAIMarkdown(q.scoringGuide,
                                            color: s.onStrong),
                                      ],
                                    ]),
                              ),
                          ],
                        ]),
                  ),
                ],
              ],
            ),
    );
  }
}

/// « Mes épreuves » : les épreuves que WinAI a composées pour le professeur.
class WinAIExamsScreen extends StatefulWidget {
  const WinAIExamsScreen({super.key});
  @override
  State<WinAIExamsScreen> createState() => _WinAIExamsScreenState();
}

class _WinAIExamsScreenState extends State<WinAIExamsScreen> {
  List<WinAIExam>? _exams;
  String? _error;
  int? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _exams = null;
      _error = null;
    });
    try {
      final list = await WinAiProductionsService.instance.exams();
      if (mounted) setState(() => _exams = list);
    } on WinAiStudioException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(WinAIExam e) async {
    if (_opening != null) return;
    setState(() => _opening = e.id);
    try {
      final full = await WinAiProductionsService.instance.exam(e.id);
      if (!mounted) return;
      await Navigator.push(
          context, WinPageRoute(builder: (_) => WinAIExamScreen(exam: full)));
    } on WinAiStudioException catch (err) {
      _toast(err.message);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Future<void> _delete(WinAIExam e) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(l.winaiCreationsDeleteTitle),
              content: Text(l.winaiCreationsDeleteBody(e.title)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l.commonCancel)),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l.commonDelete)),
              ],
            ));
    if (ok != true) return;
    try {
      await WinAiProductionsService.instance.deleteExam(e.id);
      if (mounted) {
        setState(() => _exams = _exams?.where((x) => x.id != e.id).toList());
      }
    } on WinAiStudioException catch (err) {
      _toast(err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final exams = _exams;
    final Widget body;
    if (_error != null) {
      body = WinErrorState(message: _error!, onRetry: _load);
    } else if (exams == null) {
      body = const WinLoading();
    } else if (exams.isEmpty) {
      body = WinEmptyState(
          title: l.winaiExamsEmpty,
          message: l.winaiExamsEmptyHint,
          icon: PhosphorIconsRegular.exam);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              MoreGroup(children: [
                for (final e in exams)
                  MoreLine(
                      icon: PhosphorIconsRegular.exam,
                      label: e.title,
                      trailing: IconButton(
                          tooltip: l.commonDelete,
                          icon:
                              const Icon(PhosphorIconsRegular.trash, size: 18),
                          onPressed: () => _delete(e)),
                      onTap: () => _open(e)),
              ]),
            ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(l.winaiExamsTitle),
        bottom: _opening == null
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3)),
      ),
      body: body,
    );
  }
}
