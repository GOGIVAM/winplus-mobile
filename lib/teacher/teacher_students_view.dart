import 'package:flutter/material.dart';
import '../services/content_refusal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/linking_service.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Un élève du professeur, toutes origines confondues : ses classes et sa
/// liaison directe éventuelle.
class TeacherStudent {
  final int id;
  final String name;
  final String? email;
  final String? level;

  /// Moyenne des quiz sur 100 (meilleure connue parmi ses classes).
  final double? average;
  final List<ApiTeacherClass> classes;
  final bool linked;

  const TeacherStudent({
    required this.id,
    required this.name,
    this.email,
    this.level,
    this.average,
    this.classes = const [],
    this.linked = false,
  });

  TeacherStudent merge({List<ApiTeacherClass> classes = const [], bool linked = false, double? average, String? email, String? level}) =>
      TeacherStudent(
        id: id,
        name: name,
        email: this.email ?? email,
        level: this.level ?? level,
        average: this.average ?? average,
        classes: [...this.classes, ...classes],
        linked: this.linked || linked,
      );
}

/// Rassemble les élèves du professeur : membres de ses classes actives et
/// liaisons directes acceptées, une ligne par élève (le serveur n'a pas de
/// liste unique, seulement une par classe).
Future<({List<TeacherStudent> students, List<ApiTeacherClass> classes})> loadTeacherStudents() async {
  final classes = await TeacherService.instance.getClasses();
  final active = classes.where((c) => c.isActive).toList();
  final members = await Future.wait(active.map((c) => TeacherService.instance.getClassStudents(c.id)));
  List<dynamic> links = const [];
  try {
    links = await LinkingService.instance.getMyLinks();
  } catch (_) {
    // Liaisons indisponibles : les élèves des classes restent affichés.
  }
  final byId = <int, TeacherStudent>{};
  for (var i = 0; i < active.length; i++) {
    for (final m in members[i]) {
      final s = TeacherStudent(
          id: m.studentId, name: m.displayName, email: m.email, level: m.level, average: m.avgScore, classes: [active[i]]);
      byId[m.studentId] = byId[m.studentId]?.merge(classes: [active[i]], average: m.avgScore) ?? s;
    }
  }
  for (final l in links.whereType<Map<String, dynamic>>()) {
    final o = l['other'] is Map<String, dynamic> ? l['other'] as Map<String, dynamic> : const <String, dynamic>{};
    final id = (o['id'] as num?)?.toInt();
    if (id == null) continue;
    final name = '${o['firstName'] ?? ''} ${o['lastName'] ?? ''}'.trim();
    final email = o['email'] as String?;
    byId[id] = byId[id]?.merge(linked: true, email: email) ??
        TeacherStudent(id: id, name: name.isNotEmpty ? name : (email ?? L10n.current.roleStudent), email: email, linked: true);
  }
  final list = byId.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return (students: list, classes: active);
}

/// « Mes élèves » de l'onglet Étudiants : tous les élèves du professeur,
/// recherche, classes de chacun, ajout à une classe.
class TeacherStudentsView extends StatefulWidget {
  /// Bas de liste : liaisons directes, réservations.
  final List<Widget> footer;
  const TeacherStudentsView({super.key, this.footer = const []});

  @override
  State<TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<TeacherStudentsView> {
  List<TeacherStudent>? _students;
  List<ApiTeacherClass> _classes = const [];
  bool _error = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_error) setState(() => _error = false);
    try {
      final r = await loadTeacherStudents();
      if (mounted) {
        setState(() {
          _students = r.students;
          _classes = r.classes;
        });
      }
    } catch (_) {
      if (mounted && _students == null) setState(() => _error = true);
    }
  }

  List<TeacherStudent> get _shown {
    final q = _query.trim().toLowerCase();
    final all = _students ?? const [];
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.email ?? '').toLowerCase().contains(q) ||
            s.classes.any((c) => c.name.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _addToClass(TeacherStudent st) async {
    final l = context.l10n;
    final choices = _classes.where((c) => !st.classes.any((k) => k.id == c.id)).toList();
    if (choices.isEmpty || st.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.teacherStudentsNoOtherClass)));
      return;
    }
    final klass = await showWinBottomSheet<ApiTeacherClass>(
      context: context,
      title: l.teacherStudentsAddToClass,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final c in choices)
          ListTile(
            leading: const Icon(PhosphorIconsRegular.chalkboardTeacher),
            title: Text(c.name),
            onTap: () => Navigator.pop(context, c),
          ),
      ]),
    );
    if (klass == null || !mounted) return;
    try {
      await TeacherService.instance.addClassStudent(klass.id, st.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.teacherStudentsAdded(st.name, klass.name))));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ServerRefusal.of(e)?.message ?? l.teacherClassesActionFailed)));
      }
    }
  }

  Widget _row(WinScheme s, AppLocalizations l, TeacherStudent st) {
    final avg = st.average;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          WinAvatar(st.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.name, style: WinType.titleS(s.onStrong), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final c in st.classes) WinBadge(c.name),
                if (st.linked) WinBadge(l.teacherStudentsDirect, color: BadgeColor.blue),
              ]),
            ]),
          ),
          if (avg != null) ...[
            const SizedBox(width: 8),
            // Lot 1 : moyenne de l'élève en note sur 20.
            Text(l.teacherClassesAverage(WinFormat.grade20(avg)), style: WinType.labelM(avg >= 70 ? WinColors.success : WinColors.warn)),
          ],
          IconButton(
            tooltip: l.teacherStudentsAddToClass,
            icon: Icon(PhosphorIconsRegular.userPlus, size: 20, color: s.onMuted),
            onPressed: () => _addToClass(st),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    if (_error) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    if (_students == null) return const WinLoading();
    final shown = _shown;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        WinTextField(
          icon: PhosphorIconsRegular.magnifyingGlass,
          hint: l.teacherStudentsSearch,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        if (_students!.isEmpty)
          SizedBox(
            height: 260,
            child: WinEmptyState(
              icon: PhosphorIconsRegular.student,
              title: l.teacherStudentsEmpty,
              message: l.teacherStudentsEmptyHint,
            ),
          )
        else ...[
          Text(l.teacherStudentsCount(shown.length), style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 8),
          for (final st in shown) _row(s, l, st),
        ],
        const SizedBox(height: 8),
        ...widget.footer,
      ]),
    );
  }
}
