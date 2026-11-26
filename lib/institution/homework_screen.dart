import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_exams_service.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import 'mock_exams_screen.dart' show on20;

/// « Devoirs » de l'établissement (lot 7), comme InstitutionHomework du
/// site : devoirs donnés aux classes (rendus, moyenne), donner un devoir
/// (quiz ou épreuve, consignes, date limite), avancement par élève.
class InstitutionHomeworkScreen extends StatefulWidget {
  const InstitutionHomeworkScreen({super.key});

  @override
  State<InstitutionHomeworkScreen> createState() => _InstitutionHomeworkScreenState();
}

class _InstitutionHomeworkScreenState extends State<InstitutionHomeworkScreen> {
  final _svc = InstitutionExamsService.instance;
  List<InstitutionHomework>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final items = await _svc.homework();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const HomeworkFormScreen()));
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const WinLoading();
    } else if (items.isEmpty) {
      body = WinEmptyState(
        icon: PhosphorIconsRegular.notebook,
        title: l.ihwEmptyTitle,
        message: l.ihwEmptyText,
        actionLabel: l.ihwCreate,
        onAction: _create,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
          for (final h in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WinCard(
                onTap: () async {
                  await Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => HomeworkProgressScreen(homework: h)));
                  if (mounted) _load();
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.title, style: WinType.titleS(s.onStrong)),
                  Text(
                      [
                        if ((h.groupName ?? '').isNotEmpty) h.groupName!,
                        if ((h.subject ?? '').isNotEmpty) h.subject!,
                        if (h.dueDate != null) l.ihwDue(WinFormat.dayMonthTime(h.dueDate!)),
                      ].join(' · '),
                      style: WinType.labelM(s.onMuted)),
                  const SizedBox(height: 6),
                  WinProgressBar(h.students == 0 ? 0 : h.done / h.students * 100, color: WinColors.teal600, height: 6),
                  const SizedBox(height: 4),
                  Text(
                      [
                        l.ihwDone(h.done, h.students),
                        if (h.average != null) l.mockAverage(on20(h.average)),
                      ].join(' · '),
                      style: WinType.labelM(s.onStrong)),
                ]),
              ),
            ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.ihwTitle)),
      floatingActionButton: items == null || items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _create, icon: const Icon(PhosphorIconsRegular.plus), label: Text(l.ihwCreate)),
      body: SafeArea(child: body),
    );
  }
}

/// Donner un devoir : classe, sujet (épreuve ou quiz), titre, consignes,
/// date limite facultative.
class HomeworkFormScreen extends StatefulWidget {
  const HomeworkFormScreen({super.key});

  @override
  State<HomeworkFormScreen> createState() => _HomeworkFormScreenState();
}

class _HomeworkFormScreenState extends State<HomeworkFormScreen> {
  final _svc = InstitutionExamsService.instance;
  final _search = TextEditingController();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  Timer? _debounce;
  bool _exams = true;
  List<ExamPick> _results = const [];
  ExamPick? _pick;
  List<ApiGroup>? _groups;
  int? _group;
  DateTime? _due;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    InstitutionService.instance.getGroups().then((g) {
      if (mounted) setState(() => _groups = g);
    }).catchError((_) {
      if (mounted) setState(() => _groups = const []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await _svc.searchSubjects(q, exams: _exams);
        if (mounted) setState(() => _results = r);
      } catch (_) {}
    });
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: _due ?? now.add(const Duration(days: 7)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (t == null) return;
    setState(() => _due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    final l = context.l10n;
    String? error;
    if (_group == null) {
      error = l.ihwNeedClass;
    } else if (_pick == null) {
      error = l.mockNeedSubject;
    } else if (_due != null && !_due!.isAfter(DateTime.now())) {
      error = l.ihwDueFuture;
    }
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await _svc.createHomework(
          groupId: _group!, subject: _pick!, title: _title.text, instructions: _instructions.text, dueDate: _due);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.ihwCreated)));
      Navigator.of(context).pop(true);
    } on InstitutionExamsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final groups = _groups;
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(t, style: WinType.labelM(s.onStrong)),
        );
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.ihwCreate)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          label(l.ihwClass),
          if (groups == null)
            const WinLoading()
          else if (groups.isEmpty)
            Text(l.mockNoClass, style: WinType.bodyM(s.onMuted))
          else
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final g in groups) WinChip(g.name, active: _group == g.id, onTap: () => setState(() => _group = g.id)),
            ]),
          label(l.mockSubject),
          Wrap(spacing: 8, children: [
            WinChip(l.mockKindExam,
                active: _exams,
                onTap: () => setState(() {
                      _exams = true;
                      _results = const [];
                      _pick = null;
                    })),
            WinChip(l.mockKindQuiz,
                active: !_exams,
                onTap: () => setState(() {
                      _exams = false;
                      _results = const [];
                      _pick = null;
                    })),
          ]),
          const SizedBox(height: 8),
          if (_pick != null)
            WinCard(
              child: Row(children: [
                const Icon(PhosphorIconsRegular.checkCircle, color: WinColors.success),
                const SizedBox(width: 10),
                Expanded(child: Text(_pick!.title, style: WinType.titleS(s.onStrong))),
                IconButton(
                    tooltip: l.mockChangeSubject,
                    onPressed: () => setState(() => _pick = null),
                    icon: const Icon(PhosphorIconsRegular.x)),
              ]),
            )
          else ...[
            TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: _exams ? l.mockSearchExam : l.mockSearchQuiz,
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              ),
            ),
            for (final r in _results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.title),
                subtitle: r.meta == null ? null : Text(r.meta!),
                onTap: () => setState(() {
                  _pick = r;
                  _results = const [];
                }),
              ),
          ],
          label(l.mockTitleLabel),
          TextField(controller: _title, maxLength: 200),
          label(l.ihwInstructions),
          TextField(controller: _instructions, minLines: 2, maxLines: 5),
          label(l.ihwDueLabel),
          WinCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(PhosphorIconsRegular.calendarCheck),
              title: Text(_due == null ? l.ihwNoDue : WinFormat.dayMonthTime(_due!)),
              trailing: _due == null
                  ? null
                  : IconButton(
                      tooltip: l.ihwRemoveDue,
                      onPressed: () => setState(() => _due = null),
                      icon: const Icon(PhosphorIconsRegular.x)),
              onTap: _pickDue,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 12),
          WinButton(l.ihwGive, block: true, loading: _saving, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

/// Avancement d'un devoir, élève par élève ; supprimer le devoir.
class HomeworkProgressScreen extends StatefulWidget {
  final InstitutionHomework homework;
  const HomeworkProgressScreen({super.key, required this.homework});

  @override
  State<HomeworkProgressScreen> createState() => _HomeworkProgressScreenState();
}

class _HomeworkProgressScreenState extends State<HomeworkProgressScreen> {
  final _svc = InstitutionExamsService.instance;
  List<HomeworkProgress>? _rows;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final r = await _svc.homeworkProgress(widget.homework.id);
      if (mounted) setState(() => _rows = r);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.ihwDelete),
        content: Text(l.ihwDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.ihwDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteHomework(widget.homework.id);
      if (mounted) Navigator.of(context).pop();
    } on InstitutionExamsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final rows = _rows;
    (String, BadgeColor) status(String v) => switch (v) {
          'done' => (l.ihwStatusDone, BadgeColor.success),
          'late' => (l.ihwStatusLate, BadgeColor.warn),
          _ => (l.ihwStatusTodo, BadgeColor.neutral),
        };
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.homework.title), actions: [
        IconButton(tooltip: l.ihwDelete, onPressed: _delete, icon: const Icon(PhosphorIconsRegular.trash)),
      ]),
      body: SafeArea(
        child: _error
            ? WinErrorState(message: l.commonLoadError, onRetry: _load)
            : rows == null
                ? const WinLoading()
                : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                    if ((widget.homework.instructions ?? '').isNotEmpty) ...[
                      WinCard(child: Text(widget.homework.instructions!, style: WinType.bodyM(s.onStrong))),
                      const SizedBox(height: 12),
                    ],
                    if (rows.isEmpty)
                      Text(l.ihwNoStudent, style: WinType.bodyM(s.onMuted))
                    else
                      WinCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          for (final r in rows)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              child: Row(children: [
                                Expanded(child: Text(r.name, style: WinType.titleS(s.onStrong))),
                                if (r.score != null) ...[
                                  Text(on20(r.score), style: WinType.labelM(s.onStrong)),
                                  const SizedBox(width: 8),
                                ],
                                WinBadge(status(r.status).$1, color: status(r.status).$2),
                              ]),
                            ),
                        ]),
                      ),
                  ]),
      ),
    );
  }
}
