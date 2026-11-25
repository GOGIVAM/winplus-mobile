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

/// Pourcentage (0 à 100) vers une note sur 20.
String on20(double? v) => v == null ? '–' : '${(v / 5).toStringAsFixed(1)} / 20';

(String, BadgeColor) _state(AppLocalizations l, String state) => switch (state) {
      'published' => (l.mockPublished, BadgeColor.success),
      'upcoming' => (l.mockUpcoming, BadgeColor.blue),
      'closed' => (l.mockToPublish, BadgeColor.warn),
      _ => (l.mockOpen, BadgeColor.teal),
    };

/// « Examens blancs » de l'établissement (lot 7), comme InstitutionMockExams
/// du site : examens programmés pour des classes, copies rendues, moyenne ;
/// programmer un examen, voir le classement, publier les résultats.
class MockExamsScreen extends StatefulWidget {
  const MockExamsScreen({super.key});

  @override
  State<MockExamsScreen> createState() => _MockExamsScreenState();
}

class _MockExamsScreenState extends State<MockExamsScreen> {
  final _svc = InstitutionExamsService.instance;
  List<MockExam>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final items = await _svc.mockExams();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const MockExamFormScreen()));
    if (created == true) await _load();
  }

  Future<void> _openRanking(MockExam e) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MockExamRankingScreen(examId: e.id, title: e.title)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    final now = DateTime.now();
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const WinLoading();
    } else if (items.isEmpty) {
      body = WinEmptyState(
        icon: PhosphorIconsRegular.exam,
        title: l.mockEmptyTitle,
        message: l.mockEmptyText,
        actionLabel: l.mockCreate,
        onAction: _create,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WinCard(
                onTap: () => _openRanking(e),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.title, style: WinType.titleS(s.onStrong))),
                    const SizedBox(width: 8),
                    WinBadge(_state(l, e.state(now)).$1, color: _state(l, e.state(now)).$2),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                      [
                        if ((e.subject ?? '').isNotEmpty) e.subject!,
                        if (e.groups.isNotEmpty) e.groups.join(', '),
                        l.mockDuration(e.durationMinutes),
                      ].join(' · '),
                      style: WinType.labelM(s.onMuted)),
                  if (e.opensAt != null && e.closesAt != null)
                    Text(l.mockWindow(WinFormat.dayMonthTime(e.opensAt!), WinFormat.dayMonthTime(e.closesAt!)),
                        style: WinType.labelM(s.onMuted)),
                  const SizedBox(height: 6),
                  Text(
                      [
                        l.mockSubmitted(e.submitted, e.expected),
                        if (e.average != null) l.mockAverage(on20(e.average)),
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
      appBar: AppBar(title: Text(l.mockTitle)),
      floatingActionButton: items == null || items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _create, icon: const Icon(PhosphorIconsRegular.plus), label: Text(l.mockCreate)),
      body: SafeArea(child: body),
    );
  }
}

/// Programmer un examen blanc : sujet (épreuve ou quiz), classes, ouverture,
/// fermeture et durée.
class MockExamFormScreen extends StatefulWidget {
  const MockExamFormScreen({super.key});

  @override
  State<MockExamFormScreen> createState() => _MockExamFormScreenState();
}

class _MockExamFormScreenState extends State<MockExamFormScreen> {
  final _svc = InstitutionExamsService.instance;
  final _title = TextEditingController();
  final _search = TextEditingController();
  final _duration = TextEditingController(text: '120');
  Timer? _debounce;
  bool _exams = true;
  List<ExamPick> _results = const [];
  ExamPick? _pick;
  List<ApiGroup>? _groups;
  final Set<int> _chosen = {};
  late DateTime _opens;
  late DateTime _closes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = DateTime.now().add(const Duration(days: 1));
    _opens = DateTime(t.year, t.month, t.day, 8);
    _closes = DateTime(t.year, t.month, t.day, 18);
    InstitutionService.instance.getGroups().then((g) {
      if (mounted) setState(() => _groups = g);
    }).catchError((_) {
      if (mounted) setState(() => _groups = const []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _search.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await _svc.searchSubjects(q, exams: _exams);
        if (mounted) setState(() => _results = r);
      } catch (_) {
        if (mounted) setState(() => _results = const []);
      }
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    final l = context.l10n;
    final duration = int.tryParse(_duration.text.trim()) ?? 0;
    String? error;
    if (_pick == null) {
      error = l.mockNeedSubject;
    } else if (_chosen.isEmpty) {
      error = l.mockNeedClass;
    } else if (!_closes.isAfter(_opens)) {
      error = l.mockCloseAfterOpen;
    } else if (duration < 5 || duration > 480) {
      error = l.mockDurationRange;
    }
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      final students = await _svc.createMockExam(
        groupIds: _chosen.toList(),
        subject: _pick!,
        title: _title.text,
        opensAt: _opens,
        closesAt: _closes,
        durationMinutes: duration,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.mockCreated(students))));
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
      appBar: AppBar(title: Text(l.mockCreate)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
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
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_pick!.title, style: WinType.titleS(s.onStrong)),
                    if (_pick!.meta != null) Text(_pick!.meta!, style: WinType.labelM(s.onMuted)),
                  ]),
                ),
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
          label(l.mockClasses),
          if (groups == null)
            const WinLoading()
          else if (groups.isEmpty)
            Text(l.mockNoClass, style: WinType.bodyM(s.onMuted))
          else
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final g in groups)
                WinChip(g.name,
                    active: _chosen.contains(g.id),
                    onTap: () => setState(() => _chosen.contains(g.id) ? _chosen.remove(g.id) : _chosen.add(g.id))),
            ]),
          label(l.mockWindowTitle),
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.lockOpen),
                title: Text(l.mockOpens),
                trailing: Text(WinFormat.dayMonthTime(_opens)),
                onTap: () async {
                  final d = await _pickDateTime(_opens);
                  if (d != null) setState(() => _opens = d);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.lock),
                title: Text(l.mockCloses),
                trailing: Text(WinFormat.dayMonthTime(_closes)),
                onTap: () async {
                  final d = await _pickDateTime(_closes);
                  if (d != null) setState(() => _closes = d);
                },
              ),
            ]),
          ),
          label(l.mockDurationLabel),
          TextField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: 'min')),
          label(l.mockTitleLabel),
          TextField(controller: _title, maxLength: 200, decoration: InputDecoration(hintText: l.mockTitleHint)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 12),
          WinButton(l.mockSchedule, block: true, loading: _saving, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

/// Classement d'un examen blanc : copies rendues, moyenne, répartition,
/// moyennes par classe, classement, absents ; publier ou supprimer.
class MockExamRankingScreen extends StatefulWidget {
  final int examId;
  final String title;
  const MockExamRankingScreen({super.key, required this.examId, required this.title});

  @override
  State<MockExamRankingScreen> createState() => _MockExamRankingScreenState();
}

class _MockExamRankingScreenState extends State<MockExamRankingScreen> {
  final _svc = InstitutionExamsService.instance;
  MockExamRanking? _r;
  bool _error = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final r = await _svc.ranking(widget.examId);
      if (mounted) setState(() => _r = r);
    } catch (_) {
      if (mounted && _r == null) setState(() => _error = true);
    }
  }

  Future<bool> _confirm(String title, String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.commonCancel)),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
          ],
        ),
      ) ==
      true;

  Future<void> _publish() async {
    final l = context.l10n;
    if (!await _confirm(l.mockPublish, l.mockPublishConfirm, l.mockPublish)) return;
    setState(() => _busy = true);
    try {
      await _svc.publish(widget.examId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.mockPublishedDone)));
      await _load();
    } on InstitutionExamsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    if (!await _confirm(l.mockDelete, l.mockDeleteConfirm, l.mockDelete)) return;
    setState(() => _busy = true);
    try {
      await _svc.deleteMockExam(widget.examId);
      if (mounted) Navigator.of(context).pop();
    } on InstitutionExamsException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final r = _r;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (r == null) {
      body = const WinLoading();
    } else {
      final e = r.exam;
      final maxBucket = r.buckets.fold<int>(0, (m, b) => b.$3 > m ? b.$3 : m);
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Row(children: [
            Expanded(child: WinStatCard('${e.submitted} / ${e.expected}', l.mockCopies, icon: PhosphorIconsRegular.files)),
            const SizedBox(width: 10),
            Expanded(child: WinStatCard(on20(e.average), l.mockAverageLabel, icon: PhosphorIconsRegular.chartBar)),
          ]),
          const SizedBox(height: 10),
          if (e.publishedAt != null)
            WinAlert(l.mockPublishedOn(WinFormat.dateShort(e.publishedAt!)), type: BadgeColor.success)
          else
            WinButton(l.mockPublish,
                block: true, icon: PhosphorIconsRegular.paperPlaneTilt, loading: _busy, onTap: _busy ? null : _publish),
          if (r.buckets.isNotEmpty && e.submitted > 0) ...[
            const SizedBox(height: 20),
            Text(l.mockDistribution, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            for (final b in r.buckets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(
                      width: 92,
                      child: Text('${b.$1 ~/ 5} – ${b.$2 ~/ 5} / 20', style: WinType.labelM(s.onMuted))),
                  Expanded(
                      child: WinProgressBar(maxBucket == 0 ? 0 : b.$3 / maxBucket * 100,
                          color: WinColors.teal600, height: 8)),
                  SizedBox(width: 32, child: Text('${b.$3}', textAlign: TextAlign.end, style: WinType.labelM(s.onStrong))),
                ]),
              ),
          ],
          if (r.byClass.length > 1) ...[
            const SizedBox(height: 20),
            Text(l.mockByClass, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            for (final c in r.byClass)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WinCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: WinType.titleS(s.onStrong)),
                        Text(l.mockSubmitted(c.submitted, c.students), style: WinType.labelM(s.onMuted)),
                      ]),
                    ),
                    Text(on20(c.average), style: WinType.titleS(s.onStrong)),
                  ]),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Text(l.mockRanking, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          if (r.ranking.isEmpty)
            Text(l.mockNoCopy, style: WinType.bodyM(s.onMuted))
          else
            WinCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final x in r.ranking)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: x.rank <= 3 ? WinColors.teal100 : s.surface2,
                      child: Text('${x.rank}', style: WinType.labelM(s.onStrong)),
                    ),
                    title: Text(x.name),
                    subtitle: Text([if (x.group.isNotEmpty) x.group, l.mockMinutes(x.minutes)].join(' · ')),
                    trailing: Text(on20(x.score), style: WinType.titleS(s.onStrong)),
                  ),
              ]),
            ),
          if (r.absent.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l.mockAbsent(r.absent.length), style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            Text(r.absent.map((a) => a.$2.isEmpty ? a.$1 : '${a.$1} (${a.$2})').join(', '),
                style: WinType.bodyM(s.onMuted)),
          ],
          const SizedBox(height: 24),
          WinButton(l.mockDelete,
              block: true,
              variant: WinButtonVariant.danger,
              icon: PhosphorIconsRegular.trash,
              onTap: _busy ? null : _delete),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(r?.exam.title ?? widget.title)),
      body: SafeArea(child: body),
    );
  }
}
