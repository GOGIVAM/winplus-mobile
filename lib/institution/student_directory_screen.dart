import 'package:file_picker/file_picker.dart';
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
  String _levelFilter = 'Tous';
  String _statusFilter = 'Tous';
  int _displayCount = 25;

  static const _levels = ['Tous', 'Tle C', '1ère', '2nde', 'BEPC', 'BTS', 'Concours'];
  static const _statuses = ['Tous', 'Actifs', 'Inactifs'];

  List<MockStudent> get _filtered => WinData.mockStudents.where((s) {
    final matchQ = _query.isEmpty ||
        s.name.toLowerCase().contains(_query.toLowerCase());
    final matchL = _levelFilter == 'Tous' || s.level.startsWith(_levelFilter);
    final matchS = _statusFilter == 'Tous' ||
        (_statusFilter == 'Actifs' && s.active) ||
        (_statusFilter == 'Inactifs' && !s.active);
    return matchQ && matchL && matchS;
  }).toList();

  void _showCsvImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CsvImportDialog(
        onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('1 823 élèves importés avec succès !')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final all = _filtered;
    final shown = all.take(_displayCount).toList();
    final totalAll = WinData.mockStudents.length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Annuaire des élèves', style: WinType.headlineS(s.onStrong)),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.upload_file_outlined, color: s.primary, size: 18),
            label: Text('CSV', style: WinType.labelM(s.primary)),
            onPressed: _showCsvImportDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() { _query = v; _displayCount = 25; }),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
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
                  onTap: () => setState(() { _levelFilter = l; _displayCount = 25; })),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Filtres Statut
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _statuses.map((st) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: WinChip(st, active: _statusFilter == st,
                  onTap: () => setState(() { _statusFilter = st; _displayCount = 25; })),
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Text('Affichage ${shown.length} sur $totalAll élèves',
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        Expanded(
          child: all.isEmpty
              ? Center(child: Text('Aucun résultat.', style: WinType.bodyM(s.onMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: shown.length + (shown.length < all.length ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i == shown.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: WinButton(
                          'Charger 25 de plus',
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: Icons.expand_more,
                          onTap: () => setState(() => _displayCount += 25),
                        ),
                      );
                    }
                    return _StudentRow(student: shown[i]);
                  },
                ),
        ),
      ]),
    );
  }
}

class _CsvImportDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CsvImportDialog({required this.onSuccess});

  @override
  State<_CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<_CsvImportDialog> {
  String? _fileName;
  bool _loading = false;
  bool _done = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() { _fileName = result.files.first.name; _loading = true; });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() { _loading = false; _done = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return AlertDialog(
      backgroundColor: s.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Import CSV', style: WinType.archivo(size: 17, color: s.onStrong)),
      content: _done
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline, size: 40, color: WinColors.success),
              const SizedBox(height: 10),
              Text('1 823 élèves importés avec succès !',
                  style: WinType.bodyM(s.onStrong), textAlign: TextAlign.center),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Choisissez un fichier CSV avec les colonnes :\nnom, email, niveau, groupe',
                style: WinType.bodyS(s.onMuted),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.description_outlined, size: 16, color: s.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_fileName!, style: WinType.labelM(s.onStrong),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ],
              if (_loading) ...[
                const SizedBox(height: 16),
                const Row(children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Import en cours...'),
                ]),
              ],
            ]),
      actions: _done
          ? [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSuccess();
                },
                child: Text('Fermer', style: WinType.labelM(s.primary)),
              ),
            ]
          : [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: Text('Annuler', style: WinType.labelM(s.onMuted)),
              ),
              if (!_loading)
                TextButton(
                  onPressed: _pickFile,
                  child: Text('Choisir un fichier', style: WinType.labelM(s.primary)),
                ),
            ],
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
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: student.score / 100,
                minHeight: 4,
                backgroundColor: s.outline2,
                valueColor: AlwaysStoppedAnimation(scoreColor),
              ),
            ),
          ),
        ])),
        Text('${student.score}%', style: WinType.archivo(size: 15, color: scoreColor)),
        const SizedBox(width: 8),
        Icon(
          student.active ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: student.active ? WinColors.success : s.onFaint,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MessagingScreen())),
          child: Icon(Icons.chat_outlined, size: 20, color: s.primary),
        ),
      ]),
    );
  }
}
