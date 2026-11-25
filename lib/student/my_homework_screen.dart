import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/homework_service.dart';
import '../services/quiz_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import 'quiz_screen.dart';

String _num(num n) => n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

String _when(DateTime d) => '${WinFormat.dateShort(d)} ${WinFormat.time(d)}';

/// Ouvre le quiz [quizId] dans le lecteur, en mode devoir (envoi au serveur
/// avant le résultat). [assignmentId] : devoir d'un professeur ; [limit] :
/// temps imposé (examen blanc).
Future<void> openHomeworkQuiz(BuildContext context, int quizId,
    {int? assignmentId, int? limit}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    final quiz = (await QuizService.instance.getById(quizId)).toQuiz();
    if (!context.mounted) return;
    await Navigator.of(context).push(WinPageRoute(
        builder: (_) => QuizActiveScreen(
              quiz: quiz,
              homework: true,
              assignmentId: assignmentId,
              timeLimitSeconds: limit,
            )));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.commonLoadError)));
  }
}

/// « Mes devoirs » (lot 7), comme la page /mes-devoirs du site : devoirs des
/// professeurs (copie écrite ou quiz), examens blancs chronométrés et devoirs
/// de l'établissement, au même endroit.
class MyHomeworkScreen extends StatefulWidget {
  const MyHomeworkScreen({super.key});

  @override
  State<MyHomeworkScreen> createState() => _MyHomeworkScreenState();
}

class _MyHomeworkScreenState extends State<MyHomeworkScreen> {
  List<ApiStudentAssignment>? _assignments;
  List<ApiMockExam>? _mocks;
  List<ApiInstitutionHomework>? _school;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<T>?> _try<T>(Future<List<T>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _try(HomeworkService.instance.assignments),
      _try(HomeworkService.instance.mockExams),
      _try(HomeworkService.instance.institutionHomework),
    ]);
    if (!mounted) return;
    setState(() {
      _assignments = results[0] as List<ApiStudentAssignment>?;
      _mocks = results[1] as List<ApiMockExam>?;
      _school = results[2] as List<ApiInstitutionHomework>?;
      _loading = false;
    });
  }

  bool get _anyFailed => _assignments == null || _mocks == null || _school == null;
  bool get _allFailed => _assignments == null && _mocks == null && _school == null;

  Future<void> _openAssignment(ApiStudentAssignment a) async {
    await Navigator.of(context)
        .push(WinPageRoute(builder: (_) => AssignmentDetailScreen(assignment: a)));
    if (mounted) _load();
  }

  Future<void> _startMock(ApiMockExam e) async {
    final l = context.l10n;
    final seconds = e.remainingSeconds();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.hwMockStartTitle),
        content: Text(l.hwMockStartBody((seconds / 60).ceil())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.hwMockStart)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await openHomeworkQuiz(context, e.quizId, limit: seconds);
    if (mounted) _load();
  }

  Future<void> _openSchool(ApiInstitutionHomework h) async {
    await openHomeworkQuiz(context, h.quizId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.hwTitle)),
      body: SafeArea(child: _body(s, l)),
    );
  }

  Widget _body(WinScheme s, AppLocalizations l) {
    if (_loading && _assignments == null && _mocks == null && _school == null) {
      return const WinLoading();
    }
    if (_allFailed) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    final assignments = _assignments ?? const [];
    final mocks = _mocks ?? const [];
    final school = _school ?? const [];
    if (!_anyFailed && assignments.isEmpty && mocks.isEmpty && school.isEmpty) {
      return WinEmptyState(
          icon: PhosphorIconsRegular.clipboardText, title: l.hwEmpty, message: l.hwEmptyHint);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        // Une des trois sources n'a pas répondu : le reste s'affiche.
        if (_anyFailed) ...[
          WinAlert(l.commonLoadError, icon: PhosphorIconsRegular.warningCircle),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _load, child: Text(l.commonRetry)),
          ),
        ],
        if (assignments.isNotEmpty) ...[
          _Section(l.hwSectionTeacher),
          for (final a in assignments) _assignmentCard(l, a),
        ],
        if (mocks.isNotEmpty) ...[
          _Section(l.hwSectionMock),
          for (final e in mocks) _mockCard(l, e),
        ],
        if (school.isNotEmpty) ...[
          _Section(l.hwSectionSchool),
          for (final h in school) _schoolCard(l, h),
        ],
      ]),
    );
  }

  Widget _assignmentCard(AppLocalizations l, ApiStudentAssignment a) {
    final (chip, color) = a.graded
        ? (l.hwScore(_num(a.myScore!), _num(a.maxScore)), BadgeColor.success)
        : a.submitted
            ? (l.hwStatusDone, BadgeColor.teal)
            : a.late
                ? (l.hwStatusLate, BadgeColor.error)
                : (l.hwStatusTodo, BadgeColor.warn);
    return _HomeworkCard(
      icon: a.quizId != null ? PhosphorIconsRegular.listChecks : PhosphorIconsRegular.pencilSimpleLine,
      title: a.title,
      meta: [
        if (a.className != null) a.className!,
        if (a.dueDate != null) l.hwDue(_when(a.dueDate!)),
        if (a.quizId != null) l.hwQuiz,
      ].join(' · '),
      chip: chip,
      chipColor: color,
      onTap: () => _openAssignment(a),
    );
  }

  Widget _mockCard(AppLocalizations l, ApiMockExam e) {
    final (chip, color, meta) = switch (e.status) {
      'open' => (l.hwChipOpen, BadgeColor.warn, l.hwMockOpen(_when(e.closesAt), e.durationMinutes)),
      'submitted' => (
          l.hwStatusDone,
          BadgeColor.teal,
          e.published && e.score != null && e.rank != null && e.total != null
              ? l.hwMockResult(_num(e.score!), e.rank!, e.total!, e.average == null ? '—' : _num(e.average!))
              : l.hwMockSubmitted
        ),
      'missed' => (l.hwMockMissed, BadgeColor.error, l.hwMockOpen(_when(e.closesAt), e.durationMinutes)),
      _ => (l.hwChipUpcoming, BadgeColor.neutral, l.hwMockUpcoming(_when(e.opensAt), e.durationMinutes)),
    };
    return _HomeworkCard(
      icon: PhosphorIconsRegular.timer,
      title: e.title,
      meta: meta,
      chip: chip,
      chipColor: color,
      onTap: e.status == 'open' ? () => _startMock(e) : null,
    );
  }

  Widget _schoolCard(AppLocalizations l, ApiInstitutionHomework h) {
    final (chip, color) = switch (h.status) {
      'done' => (h.myScore != null ? '${_num(h.myScore!)} / 100' : l.hwStatusDone, BadgeColor.success),
      'missing' => (l.hwSchoolMissing, BadgeColor.error),
      _ => (l.hwStatusTodo, BadgeColor.warn),
    };
    return _HomeworkCard(
      icon: PhosphorIconsRegular.buildings,
      title: h.title,
      meta: [
        if (h.groupName != null) h.groupName!,
        if (h.dueDate != null) l.hwDue(_when(h.dueDate!)),
      ].join(' · '),
      chip: chip,
      chipColor: color,
      onTap: h.status == 'done' ? null : () => _openSchool(h),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(title, style: WinType.titleM(WinTheme.of(context).onStrong)),
      );
}

class _HomeworkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;
  final String chip;
  final BadgeColor chipColor;
  final VoidCallback? onTap;
  const _HomeworkCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.chip,
    required this.chipColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: WinColors.teal600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: WinType.titleM(s.onStrong)),
              if (meta.isNotEmpty) Text(meta, style: WinType.labelM(s.onMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          WinBadge(chip, color: chipColor),
        ]),
      ),
    );
  }
}

/// Fiche d'un devoir de professeur : énoncé, puis note, copie déjà rendue,
/// quiz à faire ou copie à écrire.
class AssignmentDetailScreen extends StatefulWidget {
  final ApiStudentAssignment assignment;
  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _content = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final text = _content.text.trim();
    if (text.isEmpty) {
      setState(() => _error = l.hwEmptyCopy);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await HomeworkService.instance.submitAssignment(widget.assignment.id, text);
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.hwCopySent)));
    } on HomeworkSubmitException catch (e) {
      if (mounted) setState(() => _error = e.message ?? l.hwSubmitFailed);
    } catch (_) {
      if (mounted) setState(() => _error = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final a = widget.assignment;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.hwTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(a.title, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 4),
          Text(
              [
                if (a.className != null) a.className!,
                if (a.subject != null) a.subject!,
                if (a.dueDate != null) l.hwDue(_when(a.dueDate!)),
              ].join(' · '),
              style: WinType.labelM(s.onMuted)),
          if ((a.statement ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            WinCard(child: Text(a.statement!.trim(), style: WinType.bodyM(s.onStrong))),
          ],
          const SizedBox(height: 20),
          ..._action(s, l, a),
        ]),
      ),
    );
  }

  List<Widget> _action(WinScheme s, AppLocalizations l, ApiStudentAssignment a) {
    if (a.graded) {
      return [
        WinAlert(l.hwGrade(_num(a.myScore!), _num(a.maxScore)),
            type: BadgeColor.success, icon: PhosphorIconsRegular.sealCheck),
        if ((a.myComment ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l.hwTeacherComment, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 4),
          Text(a.myComment!.trim(), style: WinType.bodyM(s.onStrong)),
        ],
      ];
    }
    if (a.submitted || _sent) {
      return [WinAlert(l.hwAlreadySubmitted, type: BadgeColor.teal, icon: PhosphorIconsRegular.checkCircle)];
    }
    if (a.quizId != null) {
      return [
        WinButton(l.hwTakeQuiz,
            block: true,
            icon: PhosphorIconsRegular.listChecks,
            onTap: () => openHomeworkQuiz(context, a.quizId!, assignmentId: a.id)),
      ];
    }
    return [
      TextField(
        controller: _content,
        minLines: 6,
        maxLines: 14,
        decoration: InputDecoration(hintText: l.hwWriteHint),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        WinAlert(_error!, type: BadgeColor.error),
      ],
      const SizedBox(height: 12),
      WinButton(l.hwSubmitCopy, block: true, loading: _sending, onTap: _sending ? null : _submit),
    ];
  }
}
