import 'package:flutter/material.dart';

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

const _difficultyLabels = {'facile': 'Facile', 'moyen': 'Moyen', 'difficile': 'Difficile'};

String _date(DateTime d) {
  const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
        _error = TutorSessionMaterialService.errorMessage(e) ?? 'Support introuvable.';
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
          .showSnackBar(SnackBar(content: Text(TutorSessionMaterialService.errorMessage(e) ?? 'Action impossible.')));
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer')),
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
        title: Text('Support de séance', style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _v == null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? 'Support introuvable.', style: WinType.bodyS(s.onMuted))))
                : _editing && _v!.content != null
                    ? _MaterialEditor(
                        initial: _v!.content!,
                        busy: _busy,
                        onCancel: () => setState(() => _editing = false),
                        onSave: (c) async {
                          if (await _run(() => _svc.update(widget.bookingId, c), 'Brouillon enregistré.')) {
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
        const WinAlert('Le tuteur n\'a pas encore partagé de support pour cette séance.', type: BadgeColor.neutral),
      if (v.viewerRole == 'payer' && v.exists)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Consultation seule : les élèves répondent au quiz et aux exercices dans leur compte.', style: WinType.labelS(s.onFaint)),
        ),
      if (c != null) ...[
        _course(s, c),
        if (c.quiz.isNotEmpty) _quizCard(s, v, c),
        if (c.exercises.isNotEmpty) _exercisesCard(s, v, c),
        if (v.canSubmit && v.isParticipant)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: WinButton('Envoyer mes réponses', block: true, loading: _busy, onTap: _busy ? null : () => _submit(c)),
          ),
      ],
      if (v.sharedVersion != null && (v.isTutor || v.results.isNotEmpty)) _resultsCard(s, v),
    ]);
  }

  Widget _header(WinScheme s, SessionMaterialView v) {
    final badge = v.isTutor && v.exists
        ? v.status == 'draft'
            ? const WinBadge('Brouillon', color: BadgeColor.warn)
            : v.hasUnsharedChanges
                ? const WinBadge('Modifié depuis le partage', color: BadgeColor.warn)
                : const WinBadge('Partagé', color: BadgeColor.success)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(v.content?.title.isNotEmpty == true ? v.content!.title : 'Séance', style: WinType.titleM(s.onStrong))),
            if (badge != null) badge,
          ]),
          const SizedBox(height: 4),
          Text('${_date(v.sessionDate)} · ${v.startTime}-${v.endTime} · ${formatDurationMinutes(v.durationMinutes)}'
              '${v.subject != null ? ' · ${v.subject}' : ''}${!v.isTutor && v.tutorName != null ? ' · avec ${v.tutorName}' : ''}',
              style: WinType.labelS(s.onMuted)),
          Text('${v.participantCount > 1 ? 'Groupe (${v.participantCount} élèves) : ' : 'Élève : '}'
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
        decoration: const InputDecoration(
          hintText: 'Consigne pour WinAI (facultatif) : « plus d\'exercices », « niveau plus simple »…',
          border: OutlineInputBorder(),
        ),
      ),
      Text(
          'WinAI prépare un cours, un quiz et des exercices à partir des sujets de la séance. '
          'La génération est décomptée de ton usage WinAI ; rien n\'est envoyé aux élèves avant que tu partages.',
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 8),
      WinButton(v.exists ? 'Régénérer' : 'Générer avec WinAI',
          block: true,
          loading: _busy,
          variant: v.exists ? WinButtonVariant.outline : WinButtonVariant.accent,
          icon: Icons.auto_awesome,
          onTap: _busy
              ? null
              : () async {
                  if (v.exists && !await _confirm('Régénérer remplace ton brouillon actuel (la version partagée reste visible jusqu\'au prochain partage). Continuer ?')) {
                    return;
                  }
                  if (await _run(() => _svc.generate(widget.bookingId, instructions: _instructions.text), 'Support généré : relis-le avant de le partager.')) {
                    _instructions.clear();
                  }
                }),
      if (v.canEdit) ...[
        const SizedBox(height: 8),
        WinButton('Modifier', block: true, variant: WinButtonVariant.outline, icon: Icons.edit, onTap: _busy ? null : () => setState(() => _editing = true)),
      ],
      if (v.canShare) ...[
        const SizedBox(height: 8),
        WinButton(v.sharedVersion != null ? 'Partager la nouvelle version' : 'Partager avec les élèves',
            block: true,
            icon: Icons.send,
            onTap: _busy ? null : () => _run(() => _svc.share(widget.bookingId), 'Support partagé avec les élèves et le payeur.')),
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

  Widget _course(WinScheme s, SessionMaterialContent c) => _card(s, 'Cours', [
        if (c.objectives.isNotEmpty) ...[
          Text('Objectifs', style: WinType.labelM(s.onMuted)),
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
              child: Text('Exemple : ${sec.example}', style: WinType.labelS(s.onStrong)),
            ),
          ],
        ],
        if (c.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('À retenir', style: WinType.labelM(s.onStrong)),
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
    return _card(s, mine != null ? 'Quiz · ${mine.quizScore}/${mine.quizTotal}' : 'Quiz (${c.quiz.length} questions)', [
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
    return _card(s, 'Exercices', [
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
            title: Text('Indices', style: WinType.labelS(s.onMuted)),
            children: [_bullets(s, e.hints)],
          ),
        if (answering) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _exerciseCtrl(e.id),
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Ta réponse…', border: OutlineInputBorder()),
          ),
        ],
        if (mine?.exerciseAnswers[e.id] != null) ...[
          const SizedBox(height: 6),
          Text('Ta réponse : ${mine!.exerciseAnswers[e.id]}', style: WinType.labelS(s.onMuted)),
        ],
        if (v.solutionsIncluded && (e.solution ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: WinColors.successBg, borderRadius: BorderRadius.circular(10)),
            child: Text('Corrigé : ${e.solution}', style: WinType.labelS(s.onStrong)),
          ),
        ],
        const SizedBox(height: 14),
      ],
    ]);
  }

  Future<void> _submit(SessionMaterialContent c) async {
    final unanswered = c.quiz.where((q) => !_quiz.containsKey(q.id)).length;
    if (unanswered > 0 && !await _confirm('$unanswered question(s) sans réponse. Envoyer quand même ? Tu ne pourras plus modifier tes réponses.')) {
      return;
    }
    final exercises = <String, String>{
      for (final e in c.exercises)
        if ((_exercises[e.id]?.text.trim() ?? '').isNotEmpty) e.id: _exercises[e.id]!.text.trim(),
    };
    await _run(() => _svc.submit(widget.bookingId, Map.of(_quiz), exercises), 'Réponses envoyées à ton tuteur.');
  }

  Widget _resultsCard(WinScheme s, SessionMaterialView v) {
    final answered = v.results.map((r) => r.studentUserId).toSet();
    final waiting = v.participants.where((p) => !answered.contains(p.userId)).toList();
    return _card(s, v.isTutor ? 'Réponses des élèves' : 'Résultats', [
      if (v.results.isEmpty) Text('Aucune réponse pour l\'instant.', style: WinType.labelS(s.onMuted)),
      for (final r in v.results) ...[
        Row(children: [
          Expanded(child: Text(r.studentName ?? 'Élève #${r.studentUserId}', style: WinType.labelM(s.onStrong))),
          Text(r.quizTotal > 0 ? '${r.quizScore}/${r.quizTotal}' : 'Exercices rendus', style: WinType.labelM(s.onStrong)),
        ]),
        if (r.isOutdated) Text('Réponses à une version précédente', style: WinType.labelS(s.onFaint)),
        if (v.isTutor && r.questions.isNotEmpty)
          Text(r.questions.asMap().entries.map((q) => '${q.key + 1}${q.value.isCorrect ? ' ✓' : ' ✗'}').join('  '), style: WinType.labelS(s.onMuted)),
        if (v.isTutor)
          for (final a in r.exerciseAnswers.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${v.content?.exercises.where((x) => x.id == a.key).map((x) => x.title).firstOrNull ?? a.key} : ${a.value}',
                  style: WinType.labelS(s.onStrong)),
            ),
        const SizedBox(height: 10),
      ],
      if (v.isTutor && waiting.isNotEmpty)
        Text('Pas encore répondu : ${waiting.map((p) => p.name ?? '#${p.userId}').join(', ')}', style: WinType.labelS(s.onFaint)),
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
      Text('Modifier le support', style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 10),
      _field('Titre', _c.title, (v) => _c.title = v),
      _field('Objectifs (un par ligne)', _c.objectives.join('\n'), (v) => _c.objectives = _lines(v), maxLines: 4),
      _field('Introduction', _c.introduction, (v) => _c.introduction = v, maxLines: 5),
      for (var i = 0; i < _c.sections.length; i++) ...[
        Row(children: [
          Expanded(child: Text('Partie ${i + 1}', style: WinType.labelM(s.onStrong))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.sections = [..._c.sections]..removeAt(i))),
        ]),
        _field('Titre de la partie', _c.sections[i].title, (v) => _c.sections[i].title = v),
        _field('Contenu', _c.sections[i].content, (v) => _c.sections[i].content = v, maxLines: 8),
        _field('Exemple (facultatif)', _c.sections[i].example ?? '', (v) => _c.sections[i].example = v, maxLines: 4),
      ],
      TextButton.icon(
        onPressed: () => setState(() => _c.sections = [..._c.sections, MaterialSection(title: '', content: '')]),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une partie'),
      ),
      _field('À retenir', _c.summary, (v) => _c.summary = v, maxLines: 4),
      _field('Points clés (un par ligne)', _c.keyPoints.join('\n'), (v) => _c.keyPoints = _lines(v), maxLines: 4),
      const SizedBox(height: 8),
      Text('Quiz', style: WinType.titleM(s.onStrong)),
      for (var i = 0; i < _c.quiz.length; i++) ...[
        Row(children: [
          Expanded(child: Text('Question ${i + 1}', style: WinType.labelM(s.onStrong))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.quiz = [..._c.quiz]..removeAt(i))),
        ]),
        _field('Énoncé', _c.quiz[i].text, (v) => _c.quiz[i].text = v, maxLines: 3),
        RadioGroup<String>(
          groupValue: _c.quiz[i].correctOptionId,
          onChanged: (val) => setState(() => _c.quiz[i].correctOptionId = val),
          child: Column(children: [
            for (final o in _c.quiz[i].options)
              Row(children: [
                Radio<String>(value: o.id),
                Expanded(child: _field('Réponse ${o.id.toUpperCase()}', o.text, (v) => o.text = v)),
              ]),
          ]),
        ),
        _field('Explication', _c.quiz[i].explanation ?? '', (v) => _c.quiz[i].explanation = v, maxLines: 3),
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
        label: const Text('Ajouter une question'),
      ),
      const SizedBox(height: 8),
      Text('Exercices', style: WinType.titleM(s.onStrong)),
      for (var i = 0; i < _c.exercises.length; i++) ...[
        Row(children: [
          Expanded(child: Text('Exercice ${i + 1}', style: WinType.labelM(s.onStrong))),
          DropdownButton<String>(
            value: _difficultyLabels.containsKey(_c.exercises[i].difficulty) ? _c.exercises[i].difficulty : 'moyen',
            items: [for (final e in _difficultyLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _c.exercises[i].difficulty = v ?? 'moyen'),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _c.exercises = [..._c.exercises]..removeAt(i))),
        ]),
        _field('Titre', _c.exercises[i].title, (v) => _c.exercises[i].title = v),
        _field('Énoncé', _c.exercises[i].statement, (v) => _c.exercises[i].statement = v, maxLines: 5),
        _field('Indices (un par ligne)', _c.exercises[i].hints.join('\n'), (v) => _c.exercises[i].hints = _lines(v), maxLines: 3),
        _field('Corrigé (visible après la réponse de l\'élève)', _c.exercises[i].solution ?? '', (v) => _c.exercises[i].solution = v, maxLines: 5),
      ],
      TextButton.icon(
        onPressed: () => setState(() => _c.exercises = [
              ..._c.exercises,
              MaterialExercise(id: 'e${_c.exercises.length + 1}', title: 'Exercice ${_c.exercises.length + 1}', statement: ''),
            ]),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un exercice'),
      ),
      const SizedBox(height: 12),
      WinButton('Enregistrer le brouillon', block: true, loading: widget.busy, onTap: widget.busy ? null : () => widget.onSave(_c)),
      const SizedBox(height: 8),
      WinButton('Annuler', block: true, variant: WinButtonVariant.outline, onTap: widget.busy ? null : widget.onCancel),
    ]);
  }
}
