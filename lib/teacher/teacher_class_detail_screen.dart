import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Module 12 : écran d'une classe (élèves + devoirs), en miroir strict des
/// opérations exposées par TeacherClassesController côté serveur. Remplace
/// les listes codées en dur de l'ancien onglet « Élèves », qui n'appelait
/// jamais le réseau.
class TeacherClassDetailScreen extends StatefulWidget {
  final ApiTeacherClass initialClass;
  const TeacherClassDetailScreen({super.key, required this.initialClass});

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> {
  late ApiTeacherClass _klass;
  List<ApiClassStudent>? _students;
  List<ApiAssignment>? _assignments;
  String? _studentsError;
  String? _assignmentsError;
  bool _tabStudents = true;

  @override
  void initState() {
    super.initState();
    _klass = widget.initialClass;
    _loadStudents();
    _loadAssignments();
  }

  Future<void> _loadStudents() async {
    setState(() => _studentsError = null);
    try {
      final s = await TeacherService.instance.getClassStudents(_klass.id);
      if (mounted) setState(() => _students = s);
    } catch (_) {
      if (mounted) setState(() { _students = []; _studentsError = L10n.current.teacherClassStudentsLoadError; });
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => _assignmentsError = null);
    try {
      final all = await TeacherService.instance.getAssignments();
      if (mounted) setState(() => _assignments = all.where((a) => a.teacherClassId == _klass.id).toList());
    } catch (_) {
      if (mounted) setState(() { _assignments = []; _assignmentsError = L10n.current.teacherClassAssignmentsLoadError; });
    }
  }

  Future<void> _addStudent() async {
    final ctrl = TextEditingController();
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormSheet(
        title: context.l10n.teacherClassAddStudent,
        child: WinTextField(label: context.l10n.teacherClassStudentEmailLabel, hint: context.l10n.teacherClassStudentEmailHint, icon: Icons.email_outlined, controller: ctrl),
        submitLabel: context.l10n.teacherClassAdd,
        onSubmit: () => Navigator.pop(ctx, ctrl.text.trim()),
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await TeacherService.instance.addClassStudent(_klass.id, email);
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassStudentAdded)));
      }
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString() : L10n.current.teacherClassAddStudentError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.contains('DioException') ? L10n.current.teacherClassAddStudentErrorDetail : msg)));
      }
    }
  }

  Future<void> _removeStudent(ApiClassStudent s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.teacherClassRemoveStudentTitle),
        content: Text(ctx.l10n.teacherClassRemoveStudentBody(s.displayName, _klass.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.teacherClassRemove)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TeacherService.instance.removeClassStudent(_klass.id, s.studentId);
      await _loadStudents();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassRemoveStudentError)));
    }
  }

  Future<void> _createAssignment() async {
    final titleCtrl = TextEditingController();
    final statementCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormSheet(
        title: context.l10n.teacherClassNewAssignment,
        submitLabel: context.l10n.teacherClassCreateAssignment,
        onSubmit: () => Navigator.pop(ctx, true),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          WinTextField(label: context.l10n.teacherClassAssignmentTitle, hint: context.l10n.teacherClassAssignmentTitleHint, icon: Icons.assignment_outlined, controller: titleCtrl),
          const SizedBox(height: 12),
          _MultilineField(label: context.l10n.teacherClassStatementLabel, hint: context.l10n.teacherClassStatementHint, controller: statementCtrl),
          const SizedBox(height: 12),
          _MultilineField(label: context.l10n.teacherClassReferenceLabel, hint: context.l10n.teacherClassReferenceHint, controller: referenceCtrl),
        ]),
      ),
    );
    if (ok != true || titleCtrl.text.trim().length < 3) return;
    try {
      await TeacherService.instance.createAssignment(
        teacherClassId: _klass.id,
        title: titleCtrl.text.trim(),
        statementText: statementCtrl.text.trim().isEmpty ? null : statementCtrl.text.trim(),
        referenceAnswerText: referenceCtrl.text.trim().isEmpty ? null : referenceCtrl.text.trim(),
      );
      await _loadAssignments();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassAssignmentCreated)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassAssignmentCreateError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text(_klass.name, style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: WinChip(context.l10n.tutoringStudentsN(_klass.studentCount), active: _tabStudents, onTap: () => setState(() => _tabStudents = true))),
            const SizedBox(width: 8),
            Expanded(child: WinChip('${context.l10n.teacherClassAssignmentsTab}${_assignments != null ? ' (${_assignments!.length})' : ''}', active: !_tabStudents, onTap: () => setState(() => _tabStudents = false))),
          ]),
        ),
        Expanded(child: _tabStudents ? _buildStudents(s) : _buildAssignments(s)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabStudents ? _addStudent : _createAssignment,
        icon: Icon(_tabStudents ? Icons.person_add_outlined : Icons.add),
        label: Text(_tabStudents ? context.l10n.teacherClassAddStudent : context.l10n.teacherClassNewAssignment),
      ),
    );
  }

  Widget _buildStudents(WinScheme s) {
    if (_students == null) return const Center(child: CircularProgressIndicator());
    if (_studentsError != null) {
      return _ErrorState(message: _studentsError!, onRetry: _loadStudents);
    }
    if (_students!.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.group_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 10),
        Text(context.l10n.teacherClassNoStudents, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 4),
        Text(context.l10n.teacherClassNoStudentsHint, style: WinType.labelM(s.onFaint)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _students!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final st = _students![i];
        final hasScore = st.avgScore != null;
        final col = !hasScore ? WinColors.ink300 : (st.avgScore! < 50 ? WinColors.error : (st.avgScore! < 75 ? WinColors.warn : WinColors.success));
        return WinCard(
          child: Row(children: [
            WinAvatar(st.displayName, size: 40),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.displayName, style: WinType.titleM(s.onStrong)),
              Text(st.level ?? st.email ?? '', style: WinType.labelM(s.onMuted)),
            ])),
            Text(hasScore ? '${st.avgScore!.round()}%' : '—', style: WinType.archivo(size: 15, color: col)),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(Icons.person_remove_outlined, size: 19, color: s.onFaint),
              onPressed: () => _removeStudent(st),
              tooltip: context.l10n.teacherClassRemoveFromClass,
            ),
          ]),
        );
      },
    );
  }

  Widget _buildAssignments(WinScheme s) {
    if (_assignments == null) return const Center(child: CircularProgressIndicator());
    if (_assignmentsError != null) {
      return _ErrorState(message: _assignmentsError!, onRetry: _loadAssignments);
    }
    if (_assignments!.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.assignment_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 10),
        Text(context.l10n.teacherClassNoAssignments, style: WinType.bodyM(s.onMuted)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _assignments!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = _assignments![i];
        return WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.teacherClassCopies(a.submissionCount)}'
              '${a.pendingCount > 0 ? '  ${context.l10n.teacherClassToMark(a.pendingCount)}' : ''}',
              style: WinType.labelM(a.pendingCount > 0 ? WinColors.warn : s.onMuted),
            ),
          ]),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_outlined, size: 48, color: WinColors.error),
        const SizedBox(height: 10),
        Text(message, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        WinButton(context.l10n.commonRetry, icon: Icons.refresh, onTap: onRetry),
      ]),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  const _MultilineField({required this.label, required this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: WinType.manrope(size: 13, weight: FontWeight.w500, color: s.onStrong)),
      ),
      TextField(
        controller: controller,
        maxLines: 4,
        style: WinType.manrope(size: 14, color: s.onStrong),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: WinType.manrope(size: 14, color: s.onFaint),
          filled: true,
          fillColor: s.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(WinRadii.md), borderSide: BorderSide(color: s.outline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(WinRadii.md), borderSide: BorderSide(color: s.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(WinRadii.md), borderSide: BorderSide(color: s.primary, width: 2)),
        ),
      ),
    ]);
  }
}

class _FormSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final String submitLabel;
  final VoidCallback onSubmit;
  const _FormSheet({required this.title, required this.child, required this.submitLabel, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: s.outline, borderRadius: BorderRadius.circular(WinRadii.full)))),
            Text(title, style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 20),
            WinButton(submitLabel, block: true, icon: Icons.check, onTap: onSubmit),
          ]),
        ),
      ),
    );
  }
}
