import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});
  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  int? _institutionId;
  List<ApiInstitutionStudent> _students = [];
  ApiInstitutionKpis? _kpis;
  bool _loading = true;
  bool _addLoading = false;
  String _query = '';
  String _addEmail = '';
  String _addLevel = '';
  String _addGroup = '';
  String? _addError;
  String? _addSuccess;

  final _emailCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _levelCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _institutionId ?? await InstitutionService.instance.getMyInstitutionId();
    if (id == null) {
      if (mounted) { setState(() => _loading = false); }
      return;
    }
    final results = await Future.wait([
      InstitutionService.instance.getStudentDirectory(id, q: _query.isEmpty ? null : _query),
      InstitutionService.instance.getInstitutionKpis(id),
    ]);
    if (mounted) {
      setState(() {
        _institutionId = id;
        _students = results[0] as List<ApiInstitutionStudent>;
        _kpis = results[1] as ApiInstitutionKpis;
        _loading = false;
      });
    }
  }

  Future<void> _search(String q) async {
    setState(() => _query = q);
    if (_institutionId == null) return;
    final students = await InstitutionService.instance.getStudentDirectory(
      _institutionId!, q: q.isEmpty ? null : q);
    if (mounted) { setState(() => _students = students); }
  }

  Future<void> _addStudent() async {
    if (_addEmail.trim().isEmpty) {
      setState(() => _addError = 'Email requis');
      return;
    }
    setState(() { _addLoading = true; _addError = null; _addSuccess = null; });
    final ok = await InstitutionService.instance.addInstitutionStudent(
      _institutionId!,
      _addEmail.trim(),
      level: _addLevel.trim().isEmpty ? null : _addLevel.trim(),
      group: _addGroup.trim().isEmpty ? null : _addGroup.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _emailCtrl.clear();
      _levelCtrl.clear();
      _groupCtrl.clear();
      setState(() {
        _addEmail = '';
        _addLevel = '';
        _addGroup = '';
        _addLoading = false;
        _addSuccess = 'Élève ajouté avec succès';
      });
      await _load();
    } else {
      setState(() { _addLoading = false; _addError = 'Impossible d\'ajouter cet élève'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Annuaire des élèves', style: WinType.headlineS(s.onStrong)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _institutionId == null
              ? Center(child: Text('Aucune institution associée.', style: WinType.bodyM(s.onMuted)))
              : Column(children: [
                  // KPIs
                  if (_kpis != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(children: [
                        _KpiCard(label: 'Élèves', value: '${_kpis!.totalStudents}', s: s),
                        const SizedBox(width: 8),
                        _KpiCard(label: 'Actifs', value: '${_kpis!.activeStudents}', s: s),
                        const SizedBox(width: 8),
                        _KpiCard(label: 'Moy.', value: '${_kpis!.averageScore.toStringAsFixed(0)}%', s: s),
                        const SizedBox(width: 8),
                        _KpiCard(label: 'Groupes', value: '${_kpis!.groupCount}', s: s),
                      ]),
                    ),
                  // Add student form
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ajouter un élève', style: WinType.titleM(s.onStrong)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildTextField(s, _emailCtrl, 'Email', (v) => _addEmail = v)),
                        const SizedBox(width: 8),
                        SizedBox(width: 90, child: _buildTextField(s, _levelCtrl, 'Niveau', (v) => _addLevel = v)),
                        const SizedBox(width: 8),
                        SizedBox(width: 90, child: _buildTextField(s, _groupCtrl, 'Groupe', (v) => _addGroup = v)),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addLoading ? null : _addStudent,
                          style: FilledButton.styleFrom(backgroundColor: s.primary, foregroundColor: s.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                          child: _addLoading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add, size: 18),
                        ),
                      ]),
                      if (_addError != null)
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text(_addError!, style: WinType.labelM(WinColors.error))),
                      if (_addSuccess != null)
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text(_addSuccess!, style: WinType.labelM(WinColors.success))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom ou email…',
                        hintStyle: WinType.bodyS(s.onFaint),
                        prefixIcon: Icon(Icons.search, size: 20, color: s.onFaint),
                        filled: true,
                        fillColor: s.surface2,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: s.outline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: s.outline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: s.primary, width: 2)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${_students.length} élève${_students.length != 1 ? 's' : ''}', style: WinType.labelM(s.onMuted)),
                    ),
                  ),
                  Expanded(
                    child: _students.isEmpty
                        ? Center(child: Text('Aucun élève trouvé.', style: WinType.bodyM(s.onMuted)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _students.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _StudentRow(student: _students[i], s: s),
                          ),
                  ),
                ]),
    );
  }

  Widget _buildTextField(WinScheme s, TextEditingController ctrl, String hint, ValueChanged<String> onChanged) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: WinType.bodyS(s.onStrong),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: WinType.bodyS(s.onFaint),
        filled: true,
        fillColor: s.surface2,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: s.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: s.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: s.primary, width: 2)),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final WinScheme s;
  const _KpiCard({required this.label, required this.value, required this.s});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: s.surface,
          border: Border.all(color: s.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value, style: WinType.archivo(size: 18, color: s.primary)),
          Text(label, style: WinType.labelM(s.onMuted)),
        ]),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final ApiInstitutionStudent student;
  final WinScheme s;
  const _StudentRow({required this.student, required this.s});

  @override
  Widget build(BuildContext context) {
    final score = student.averageScore;
    final scoreColor = score == null
        ? s.onFaint
        : score >= 70
            ? WinColors.success
            : score >= 50
                ? WinColors.warn
                : WinColors.error;

    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        WinAvatar(student.fullName.isEmpty ? student.email : student.fullName, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            student.fullName.isEmpty ? student.email : student.fullName,
            style: WinType.titleM(s.onStrong),
          ),
          Text(
            [if (student.level != null) student.level!, if (student.group != null) student.group!].join(' · '),
            style: WinType.labelM(s.onMuted),
          ),
          if (student.matricule != null)
            Text(student.matricule!, style: WinType.labelM(s.onFaint)),
        ])),
        if (score != null) ...[
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${score.toStringAsFixed(0)}%', style: WinType.archivo(size: 14, color: scoreColor)),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 4,
                  backgroundColor: s.outline2,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 10),
        ],
        Icon(
          student.isActive ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: student.isActive ? WinColors.success : s.onFaint,
        ),
      ]),
    );
  }
}
