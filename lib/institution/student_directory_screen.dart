import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../shared/messaging/messaging_screen.dart';
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
  String _query = '';
  String _levelFilter = 'Tout';
  String _groupFilter = 'Tout';
  String _statusFilter = 'Tout';

  static const _levels = ['Tout', 'Tle C', 'Tle D', '1ère', 'Concours', 'BTS', 'BEPC'];
  static const _groups = ['Tout', 'Classe A', 'Classe B', 'Classe C', 'BEPC'];
  static const _statuses = ['Tout', 'Actif', 'Inactif'];

  List<MockStudent> get _filtered => WinData.mockStudents.where((s) {
    final matchQ = _query.isEmpty ||
        s.name.toLowerCase().contains(_query.toLowerCase()) ||
        s.group.toLowerCase().contains(_query.toLowerCase());
    final matchL = _levelFilter == 'Tout' || s.level.startsWith(_levelFilter);
    final matchG = _groupFilter == 'Tout' || s.group == _groupFilter;
    final matchS = _statusFilter == 'Tout' ||
        (_statusFilter == 'Actif' && s.active) ||
        (_statusFilter == 'Inactif' && !s.active);
    return matchQ && matchL && matchG && matchS;
  }).toList();

  void _showCsvDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer des élèves'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.upload_file_outlined, size: 48, color: WinColors.teal500),
          const SizedBox(height: 12),
          const Text('Sélectionnez un fichier CSV avec les colonnes : nom, niveau, groupe.'),
          const SizedBox(height: 16),
          WinButton('Choisir un fichier CSV', block: true, icon: Icons.attach_file,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import en cours... 12 élèves détectés.')),
                );
              }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Annuaire élèves', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_outlined, color: s.primary),
            tooltip: 'Importer CSV',
            onPressed: _showCsvDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou groupe…',
              hintStyle: WinType.bodyS(s.onFaint),
              prefixIcon: Icon(Icons.search, size: 20, color: s.onFaint),
              filled: true,
              fillColor: s.surface2,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: s.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: s.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: s.primary, width: 2)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Filtres Niveau
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _levels.map((l) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: WinChip(l, active: _levelFilter == l,
                  onTap: () => setState(() => _levelFilter = l)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Filtres Groupe + Statut
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ..._groups.map((g) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: WinChip(g, active: _groupFilter == g,
                    onTap: () => setState(() => _groupFilter = g)),
              )),
              const SizedBox(width: 8),
              ..._statuses.map((st) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: WinChip(st, active: _statusFilter == st,
                    onTap: () => setState(() => _statusFilter = st)),
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Text('${items.length} élève${items.length > 1 ? 's' : ''}',
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('Aucun résultat.', style: WinType.bodyM(s.onMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _StudentRow(student: items[i]),
                ),
        ),
      ]),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final MockStudent student;
  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final scoreColor = student.score >= 70
        ? WinColors.success
        : student.score >= 50
            ? WinColors.warn
            : WinColors.error;

    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        WinAvatar(student.name, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(student.name, style: WinType.titleM(s.onStrong)),
          Text('${student.level} · ${student.group}', style: WinType.labelM(s.onMuted)),
        ])),
        Text('${student.score}%', style: WinType.archivo(size: 15, color: scoreColor)),
        const SizedBox(width: 10),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
              color: student.active ? WinColors.success : s.onFaint,
              shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MessagingScreen())),
          child: Icon(Icons.chat_outlined, size: 20, color: s.primary),
        ),
      ]),
    );
  }
}
