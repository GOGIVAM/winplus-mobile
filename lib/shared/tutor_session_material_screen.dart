import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/tutor_booking_service.dart';
import '../services/tutor_session_material_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Lot 9.6 (suivi 17.5) : support de séance généré par WinAI, parité web.
/// - Tuteur : générer (décompté de son usage WinAI), relancer avec une
///   consigne, relire, modifier, partager ; voir les réponses des élèves.
/// - Élève de la séance : lire le cours, faire le quiz et les exercices, voir
///   sa correction (les bonnes réponses n'arrivent qu'après l'envoi).
/// - Payeur (parent, institution) : consulter sans corrigés, voir les notes.
/// Le support s'affiche dans l'application uniquement (décision 18.21).

Map<String, String> get _difficultyLabels => {
      'facile': L10n.current.tutoringMatEasy,
      'moyen': L10n.current.tutoringMatMedium,
      'difficile': L10n.current.tutoringMatHard,
    };

String _date(DateTime d) {
  return '${WinFormat.weekday(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class TutorSessionMaterialScreen extends StatefulWidget {
  final int bookingId;
  const TutorSessionMaterialScreen({super.key, required this.bookingId});

  @override
  State<TutorSessionMaterialScreen> createState() => _TutorSessionMaterialScreenState();
}

class _TutorSessionMaterialScreenState extends State<TutorSessionMaterialScreen> {
  final _svc = TutorSessionMaterialService.instance;
  SessionMaterialView? _v;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _editing = false;
  final _instructions = TextEditingController();
  final Map<String, String> _quiz = {};
  final Map<String, TextEditingController> _exercises = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _instructions.dispose();
    for (final c in _exercises.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final v = await _svc.get(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _v = v;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = TutorSessionMaterialService.errorMessage(e) ?? L10n.current.tutoringMatNotFound;
      });
    }
  }

  Future<bool> _run(Future<SessionMaterialView> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      final v = await action();
      if (!mounted) return false;
      setState(() => _v = v);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(TutorSessionMaterialService.errorMessage(e) ?? L10n.current.tutoringActionFailed)));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonBack)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.commonContinue)),
          ],
        ),
      ) ==
      true;

  TextEditingController _exerciseCtrl(String id) => _exercises.putIfAbsent(id, () => TextEditingController());

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(context.l10n.tutoringMaterial, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _v == null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? context.l10n.tutoringMatNotFound, style: WinType.bodyS(s.onMuted))))
                : _editing && _v!.content != null
                    ? _MaterialEditor(
                        initial: _v!.content!,
                        busy: _busy,
                        onCancel: () => setState(() => _editing = false),
                        onSave: (c) async {
                          if (await _run(() => _svc.update(widget.bookingId, c), context.l10n.tutoringMatDraftSaved)) {
                            if (mounted) setState(() => _editing = false);
                          }
                        },
                      )
                    : RefreshIndicator(onRefresh: _load, child: _content(s, _v!)),
      ),
    );
  }

  Widget _content(WinScheme s, SessionMaterialView v) {
    final c = v.content;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _header(s, v),
      if (v.isTutor) ..._tutorActions(s, v),
      if (!v.isTutor && !v.exists && v.blockedReason == null)
        WinAlert(context.l10n.tutoringMatNotShared, type: BadgeColor.neutral),
      if (v.viewerRole == 'payer' && v.exists)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(context.l10n.tutoringMatReadOnly, style: WinType.labelS(s.onFaint)),
        ),
      if (c != null) ...[
        _course(s, c),
        if (c.quiz.isNotEmpty) _quizCard(s, v, c),
        if (c.exercises.isNotEmpty) _exercisesCard(s, v, c),
        if (v.canSubmit && v.isParticipant)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: WinButton(context.l10n.tutoringMatSubmit, block: true, loading: _busy, onTap: _busy ? null : () => _submit(c)),
          ),
      ],
      if (v.sharedVersion != null && (v.isTutor || v.results.isNotEmpty)) _resultsCard(s, v),
    ]);
  }

  Widget _header(WinScheme s, SessionMaterialView v) {
    final badge = v.isTutor && v.exists
        ? v.status == 'draft'
            ? WinBadge(context.l10n.commonDraft, color: BadgeColor.warn)
            : v.hasUnsharedChanges
                ? WinBadge(context.l10n.tutoringMatChanged, color: BadgeColor.warn)
                : WinBadge(context.l10n.tutoringMatShared, color: BadgeColor.success)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(v.content?.title.isNotEmpty == true ? v.content!.title : context.l10n.tutoringSession, style: WinType.titleM(s.onStrong))),
            if (badge != null) badge,
          ]),
          const SizedBox(height: 4),
          Text('${_date(v.sessionDate)} · ${v.startTime}-${v.endTime} · ${formatDurationMinutes(v.durationMinutes)}'
              '${v.subject != null ? ' · ${v.subject}' : ''}${!v.isTutor && v.tutorName != null ? ' · ${context.l10n.tutoringWithName('${v.tutorName}')}' : ''}',
              style: WinType.labelS(s.onMuted)),
          Text('${v.participantCount > 1 ? context.l10n.tutoringMatGroupPrefix(v.participantCount) : context.l10n.tutoringMatStudentPrefix}'
              '${v.participants.map((p) => p.name ?? '#${p.userId}').join(', ')}',
              style: WinType.labelS(s.onFaint)),
          if (v.topics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in v.topics) WinBadge(t, color: BadgeColor.blue)]),
          ],
          if (v.blockedReason != null) ...[
            const SizedBox(height: 8),
            Text(v.blockedReason!, style: WinType.labelS(s.onMuted)),
          ],
        ]),
      ),
    );
  }

  List<Widget> _tutorActions(WinScheme s, SessionMaterialView v) {
    if (!v.canGenerate) return const [];
    return [
      TextField(
        controller: _instructions,
        maxLength: 500,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: context.l10n.tutoringMatInstructionsHint,
          border: const OutlineInputBorder(),
        ),
      ),
      Text(
          context.l10n.tutoringMatGenerateHelp,
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 8),
      WinButton(v.exists ? context.l10n.tutoringMatRegenerate : context.l10n.tutoringMatGenerate,
          block: true,
          loading: _busy,
          variant: v.exists ? WinButtonVariant.outline : WinButtonVariant.accent,
          icon: Icons.auto_awesome,
          onTap: _busy
              ? null
              : () async {
                  if (v.exists && !await _confirm(context.l10n.tutoringMatRegenerateConfirm)) {
                    return;
                  }
                  if (await _run(() => _svc.generate(widget.bookingId, instructions: _instructions.text), L10n.current.tutoringMatGenerated)) {
                    _instructions.clear();
                  }
                }),
      if (v.canEdit) ...[
        const SizedBox(height: 8),
        WinButton(context.l10n.commonEdit, block: true, variant: WinButtonVariant.outline, icon: Icons.edit, onTap: _busy ? null : () => setState(() => _editing = true)),
      ],
      if (v.canShare) ...[
        const SizedBox(height: 8),
        WinButton(v.sharedVersion != null ? context.l10n.tutoringMatShareNew : context.l10n.tutoringMatShare,
            block: true,
            icon: Icons.send,
            onTap: _busy ? null : () => _run(() => _svc.share(widget.bookingId), context.l10n.tutoringMatSharedToast)),
      ],
      const SizedBox(height: 14),
    ];
  }

  Widget _card(WinScheme s, String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  Widget _bullets(WinScheme s, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final i in items) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $i', style: WinType.bodyS(s.onStrong)))],
      );

  Widget _course(WinScheme s, SessionMaterialContent c) => _card(s, context.l10n.tutoringMatCourse, [
        if (c.objectives.isNotEmpty) ...[
          Text(context.l10n.tutoringMatObjectives, style: WinType.labelM(s.onMuted)),
          _bullets(s, c.objectives),
          const SizedBox(height: 8),
        ],
        if (c.groupNote != null && c.groupNote!.isNotEmpty) ...[
          Text(c.groupNote!, style: WinType.labelS(s.onFaint)),
          const SizedBox(height: 8),
        ],
        if (c.introduction.isNotEmpty) Text(c.introduction, style: WinType.bodyS(s.onStrong)),
        for (final sec in c.sections) ...[
          const SizedBox(height: 12),
          Text(sec.title, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 4),
          Text(sec.content, style: WinType.bodyS(s.onStrong)),
          if (sec.example != null && sec.example!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: s.chipBg, borderRadius: BorderRadius.circular(10)),
              child: Text(context.l10n.tutoringMatExample('${sec.example}'), style: WinType.labelS(s.onStrong)),
            ),
          ],
        ],
        if (c.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(context.l10n.tutoringMatSummary, style: WinType.labelM(s.onStrong)),
          Text(c.summary, style: WinType.bodyS(s.onStrong)),
        ],
        if (c.keyPoints.isNotEmpty) ...[const SizedBox(height: 6), _bullets(s, c.keyPoints)],
      ]);

  String? _givenAnswer(SessionMaterialView v, String qid) {
    if (v.canSubmit && v.isParticipant) return _quiz[qid];
    final mine = v.myResult;
    if (mine == null || mine.isOutdated) return null;
    for (final q in mine.questions) {
      if (q.questionId == qid) return q.answer;
    }
    return null;
  }

  Widget _quizCard(WinScheme s, SessionMaterialView v, SessionMaterialContent c) {
    final answering = v.canSubmit && v.isParticipant;
    final mine = v.myResult != null && !v.myResult!.isOutdated ? v.myResult : null;
    return _card(s, mine != null ? 'Quiz · ${mine.quizScore}/${mine.quizTotal}' : context.l10n.tutoringMatQuizCount(c.quiz.length), [
      for (var i = 0; i < c.quiz.length; i++) ...[
        Text('${i + 1}. ${c.quiz[i].text}', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: _givenAnswer(v, c.quiz[i].id),
          onChanged: (val) {
            if (answering && val != null) setState(() => _quiz[c.quiz[i].id] = val);
          },
          child: Column(children: [
            for (final o in c.quiz[i].options)
              Builder(builder: (_) {
                final q = c.quiz[i];
                final given = _givenAnswer(v, q.id);
                final correct = v.solutionsIncluded && q.correctOptionId == o.id;
                final wrong = v.solutionsIncluded && given == o.id && q.correctOptionId != o.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: correct ? WinColors.successBg : wrong ? WinColors.errorBg : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RadioListTile<String>(
                    dense: true,
                    value: o.id,
                    enabled: answering,
                    title: Text(o.text, style: WinType.bodyS(s.onStrong)),
                    secondary: correct
                        ? const Icon(Icons.check_circle, color: WinColors.success, size: 18)
                        : wrong
                            ? const Icon(Icons.cancel, color: WinColors.error, size: 18)
                            : null,
                  ),
                );
              }),
          ]),
        ),
        if (v.solutionsIncluded && (c.quiz[i].explanation ?? '').isNotEmpty)
          Text(c.quiz[i].explanation!, style: WinType.labelS(s.onMuted)),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _exercisesCard(WinScheme s, SessionMaterialView v, SessionMaterialContent c) {
    final answering = v.canSubmit && v.isParticipant;
    final mine = v.myResult != null && !v.myResult!.isOutdated ? v.myResult : null;
    return _card(s, context.l10n.tutoringMatExercises, [
      for (final e in c.exercises) ...[
        Row(children: [
          Expanded(child: Text(e.title, style: WinType.labelM(s.onStrong))),
          WinBadge(_difficultyLabels[e.difficulty] ?? e.difficulty),
        ]),
        const SizedBox(height: 4),
        Text(e.statement, style: WinType.bodyS(s.onStrong)),
        if (e.hints.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.l10n.tutoringMatHints, style: WinType.labelS(s.onMuted)),
            children: [_bullets(s, e.hints)],
          ),
        if (answering) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _exerciseCtrl(e.id),
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(hintText: context.l10n.tutoringMatYourAnswerHint, border: const OutlineInputBorder()),
          ),
        ],
        if (mine?.exerciseAnswers[e.id] != null) ...[
          const SizedBox(height: 6),
          Text(context.l10n.tutoringMatYourAnswer('${mine!.exerciseAnswers[e.id]}'), style: WinType.labelS(s.onMuted)),
        ],
        if (v.solutionsIncluded && (e.solution ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: WinColors.successBg, borderRadius: BorderRadius.circular(10)),
            child: Text(context.l10n.tutoringMatSolution('${e.solution}'), style: WinType.labelS(s.onStrong)),
          ),
        ],
        const SizedBox(height: 14),
      ],
    ]);
  }

  Future<void> _submit(SessionMaterialContent c) async {
    final unanswered = c.quiz.where((q) => !_quiz.containsKey(q.id)).length;
    if (unanswered > 0 && !await _confirm(context.l10n.tutoringMatUnanswered(unanswered))) {
      return;
    }
    final exercises = <String, String>{
      for (final e in c.exercises)
        if ((_exercises[e.id]?.text.trim() ?? '').isNotEmpty) e.id: _exercises[e.id]!.text.trim(),
    };
    await _run(() => _svc.submit(widget.bookingId, Map.of(_quiz), exercises), L10n.current.tutoringMatAnswersSent);
  }

  Widget _resultsCard(WinScheme s, SessionMaterialView v) {
    final answered = v.results.map((r) => r.studentUserId).toSet();
    final waiting = v.participants.where((p) => !answered.contains(p.userId)).toList();
    return _card(s, v.isTutor ? context.l10n.tutoringMatStudentAnswers : context.l10n.tutoringMatResults, [
      if (v.results.isEmpty) Text(context.l10n.tutoringMatNoAnswer, style: WinType.labelS(s.onMuted)),
      for (final r in v.results) ...[
        Row(children: [
          Expanded(child: Text(r.studentName ?? context.l10n.tutoringStudentFallback(r.studentUserId), style: WinType.labelM(s.onStrong))),
          Text(r.quizTotal > 0 ? '${r.quizScore}/${r.quizTotal}' : context.l10n.tutoringMatExercisesSubmitted, style: WinType.labelM(s.onStrong)),
        ]),
        if (r.isOutdated) Text(context.l10n.tutoringMatOutdated, style: WinType.labelS(s.onFaint)),
        if (v.isTutor && r.questions.isNotEmpty)
          Text(r.questions.asMap().entries.map((q) => '${q.key + 1}${q.value.isCorrect ? ' ✓' : ' ✗'}').join('  '), style: WinType.labelS(s.onMuted)),
        if (v.isTutor)
          for (final a in r.exerciseAnswers.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.l10n.tutoringMatAnswerLine(v.content?.exercises.where((x) => x.id == a.key).map((x) => x.title).firstOrNull ?? a.key, a.value),
                  style: WinType.labelS(s.onStrong)),
            ),
        const SizedBox(height: 10),
      ],
      if (v.isTutor && waiting.isNotEmpty)
        Text(context.l10n.tutoringMatNotYet(waiting.map((p) => p.name ?? '#${p.userId}').join(', ')), style: WinType.labelS(s.onFaint)),
    ]);
  }
}

/// Édition du brouillon par le tuteur (titre, cours, quiz, exercices).
class _MaterialEditor extends StatefulWidget {
  final SessionMaterialContent initial;
  final bool busy;
  final VoidCallback onCancel;
  final Future<void> Function(SessionMaterialContent) onSave;
  const _MaterialEditor({required this.initial, required this.busy, required this.onCancel, required this.onSave});

  @override
  State<_MaterialEditor> createState() => _MaterialEditorState();
}

class _MaterialEditorState extends State<_MaterialEditor> {
  late SessionMaterialContent _c;

  @override
  void initState() {
    super.initState();
    _c = widget.initial.copy();
  }

  List<String> _lines(String v) => v.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  Widget _field(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          initialValue: value,
          maxLines: maxLines,
          minLines: 1,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(context.l10n.tutoringMatEditTitle, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 10),
      _field(context.l10n.tutoringMatFieldTitle, _c.title, (v) => _c.title = v),
      _field(context.l10n.tutoringMatFieldObjectives, _c.objectives.join('\n'), (v) => _c.objectives = _lines(v), maxLines: 4),
      _field('Introduction', _c.introduction, (v) => _c.introduction = v, maxLines: 5),
      for (var i = 0; i < _c.sections.length; i++) ...[
        Row(children: [
          Expanded(child: Text(context.l10n.tutoringMatPart(i + 1), style: WinType.labelM(s.onStrong))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.sections = [..._c.sections]..removeAt(i))),
        ]),
        _field(context.l10n.tutoringMatFieldPartTitle, _c.sections[i].title, (v) => _c.sections[i].title = v),
        _field(context.l10n.tutoringMatFieldContent, _c.sections[i].content, (v) => _c.sections[i].content = v, maxLines: 8),
        _field(context.l10n.tutoringMatFieldExample, _c.sections[i].example ?? '', (v) => _c.sections[i].example = v, maxLines: 4),
      ],
      TextButton.icon(
        onPressed: () => setState(() => _c.sections = [..._c.sections, MaterialSection(title: '', content: '')]),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.tutoringMatAddPart),
      ),
      _field(context.l10n.tutoringMatSummary, _c.summary, (v) => _c.summary = v, maxLines: 4),
      _field(context.l10n.tutoringMatFieldKeyPoints, _c.keyPoints.join('\n'), (v) => _c.keyPoints = _lines(v), maxLines: 4),
      const SizedBox(height: 8),
      Text('Quiz', style: WinType.titleM(s.onStrong)),
      for (var i = 0; i < _c.quiz.length; i++) ...[
        Row(children: [
          Expanded(child: Text('Question ${i + 1}', style: WinType.labelM(s.onStrong))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.quiz = [..._c.quiz]..removeAt(i))),
        ]),
        _field(context.l10n.tutoringMatFieldStatement, _c.quiz[i].text, (v) => _c.quiz[i].text = v, maxLines: 3),
        RadioGroup<String>(
          groupValue: _c.quiz[i].correctOptionId,
          onChanged: (val) => setState(() => _c.quiz[i].correctOptionId = val),
          child: Column(children: [
            for (final o in _c.quiz[i].options)
              Row(children: [
                Radio<String>(value: o.id),
                Expanded(child: _field(context.l10n.tutoringMatFieldAnswer(o.id.toUpperCase()), o.text, (v) => o.text = v)),
              ]),
          ]),
        ),
        _field(context.l10n.tutoringMatFieldExplanation, _c.quiz[i].explanation ?? '', (v) => _c.quiz[i].explanation = v, maxLines: 3),
      ],
      TextButton.icon(
        onPressed: () => setState(() => _c.quiz = [
              ..._c.quiz,
              MaterialQuizQuestion(
                id: 'q${_c.quiz.length + 1}',
                text: '',
                options: [for (final id in ['a', 'b', 'c', 'd']) MaterialQuizOption(id: id, text: '')],
                correctOptionId: 'a',
                explanation: '',
              ),
            ]),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.tutoringMatAddQuestion),
      ),
      const SizedBox(height: 8),
      Text(context.l10n.tutoringMatExercises, style: WinType.titleM(s.onStrong)),
      for (var i = 0; i < _c.exercises.length; i++) ...[
        Row(children: [
          Expanded(child: Text(context.l10n.tutoringMatExerciseN(i + 1), style: WinType.labelM(s.onStrong))),
          DropdownButton<String>(
            value: _difficultyLabels.containsKey(_c.exercises[i].difficulty) ? _c.exercises[i].difficulty : 'moyen',
            items: [for (final e in _difficultyLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _c.exercises[i].difficulty = v ?? 'moyen'),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.exercises = [..._c.exercises]..removeAt(i))),
        ]),
        _field(context.l10n.tutoringMatFieldTitle, _c.exercises[i].title, (v) => _c.exercises[i].title = v),
        _field(context.l10n.tutoringMatFieldStatement, _c.exercises[i].statement, (v) => _c.exercises[i].statement = v, maxLines: 5),
        _field(context.l10n.tutoringMatFieldHints, _c.exercises[i].hints.join('\n'), (v) => _c.exercises[i].hints = _lines(v), maxLines: 3),
        _field(context.l10n.tutoringMatFieldSolution, _c.exercises[i].solution ?? '', (v) => _c.exercises[i].solution = v, maxLines: 5),
      ],
      TextButton.icon(
        onPressed: () => setState(() => _c.exercises = [
              ..._c.exercises,
              MaterialExercise(id: 'e${_c.exercises.length + 1}', title: context.l10n.tutoringMatExerciseN(_c.exercises.length + 1), statement: ''),
            ]),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.tutoringMatAddExercise),
      ),
      const SizedBox(height: 12),
      WinButton(context.l10n.tutoringMatSaveDraft, block: true, loading: widget.busy, onTap: widget.busy ? null : () => widget.onSave(_c)),
      const SizedBox(height: 8),
      WinButton(context.l10n.commonCancel, block: true, variant: WinButtonVariant.outline, onTap: widget.busy ? null : widget.onCancel),
    ]);
  }
}
