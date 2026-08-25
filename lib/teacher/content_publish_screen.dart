import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ContentPublishScreen extends StatefulWidget {
  const ContentPublishScreen({super.key});
  @override
  State<ContentPublishScreen> createState() => _ContentPublishScreenState();
}

class _ContentPublishScreenState extends State<ContentPublishScreen> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ContentType? _type;
  String? _subject, _exam, _level;
  PlatformFile? _pickedFile;
  bool _free = false, _loading = false, _done = false;

  static const _types = ['Épreuve', 'Correction', 'Quiz', 'Livre', 'Pack'];
  static const _subjects = ['Mathématiques', 'Physique', 'Chimie', 'Français', 'Anglais', 'SVT', 'Informatique'];
  static const _exams = ['BAC A', 'BAC C', 'BAC D', 'BEPC', 'Probatoire', 'ENSP', 'FMSB', 'Polytechnique'];
  static const _levels = ['BEPC', 'Probatoire', 'BAC', 'BTS', 'Licence', 'Concours'];

  static const _typeMap = {
    'Épreuve': ContentType.epreuve,
    'Correction': ContentType.correction,
    'Quiz': ContentType.quiz,
    'Livre': ContentType.livre,
    'Pack': ContentType.pack,
  };

  Future<void> _publish() async {
    if (_titleCtrl.text.trim().isEmpty || _type == null) return;
    setState(() => _loading = true);
    final ok = await TeacherService.instance.publishContent(
      title: _titleCtrl.text.trim(),
      type: _typeMap.entries.firstWhere((e) => e.value == _type).key,
      subjectCategory: _subject ?? '',
      level: _level ?? '',
      exam: _exam ?? '',
      price: _free ? 0.0 : double.tryParse(_priceCtrl.text) ?? 0.0,
      isFree: _free,
    );
    if (!mounted) return;
    if (ok) {
      setState(() { _loading = false; _done = true; });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la soumission.')));
    }
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  Widget _selectChips(List<String> items, String? sel, ValueChanged<String> onSel) {
    final s = WinTheme.of(context);
    return Wrap(spacing: 8, runSpacing: 8, children: items.map((item) {
      final active = sel == item;
      return GestureDetector(
        onTap: () => setState(() => onSel(item)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? WinColors.ink800 : s.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: active ? WinColors.ink800 : s.outline, width: 1.5),
          ),
          child: Text(item, style: WinType.manrope(
              size: 13, weight: FontWeight.w600,
              color: active ? WinColors.cream50 : s.onSurface)),
        ),
      );
    }).toList());
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
        title: Text('Publier un contenu', style: WinType.headlineS(s.onStrong)),
      ),
      body: _done
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, size: 64, color: WinColors.success),
                const SizedBox(height: 16),
                Text('Contenu soumis !', style: WinType.displayS(s.onStrong)),
                const SizedBox(height: 8),
                Text('Votre contenu est en cours de révision par l\'équipe WinPlus. Vous serez notifié sous 24h.',
                    style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                const SizedBox(height: 28),
                WinButton('Retour', block: true, variant: WinButtonVariant.outline,
                    onTap: () => Navigator.pop(context)),
              ]),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Upload zone
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'epub', 'zip', 'doc', 'docx'],
                    );
                    if (result != null) setState(() => _pickedFile = result.files.first);
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: _pickedFile != null ? WinColors.successBg : s.surface2,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: _pickedFile != null ? WinColors.success : s.outline,
                          width: 1.5),
                    ),
                    child: _pickedFile != null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_circle_outline, size: 32, color: WinColors.success),
                            const SizedBox(height: 8),
                            Text(_pickedFile!.name,
                                style: WinType.titleM(WinColors.success),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_fmtSize(_pickedFile!.size),
                                style: WinType.labelM(WinColors.success)),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.upload_file_outlined, size: 36, color: s.onFaint),
                            const SizedBox(height: 8),
                            Text('Appuyez pour choisir un fichier',
                                style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
                            Text('PDF, ePub, ZIP, Word',
                                style: WinType.labelM(s.onFaint), textAlign: TextAlign.center),
                          ]),
                  ),
                ),
                const SizedBox(height: 20),
                WinTextField(label: 'Titre du contenu *', hint: 'BAC C Mathématiques 2024',
                    icon: Icons.title, controller: _titleCtrl),
                const SizedBox(height: 16),
                Text('Type de contenu *', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                _selectChips(_types, _type == null ? null
                    : _typeMap.entries.firstWhere((e) => e.value == _type).key,
                    (v) { _type = _typeMap[v]; }),
                const SizedBox(height: 16),
                Text('Matière', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                _selectChips(_subjects, _subject, (v) { _subject = v; }),
                const SizedBox(height: 16),
                Text('Examen cible', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                _selectChips(_exams, _exam, (v) { _exam = v; }),
                const SizedBox(height: 16),
                Text('Niveau', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                _selectChips(_levels, _level, (v) { _level = v; }),
                const SizedBox(height: 16),
                // Prix
                Row(children: [
                  Expanded(child: WinTextField(
                    label: 'Prix (XAF)',
                    hint: '1000',
                    icon: Icons.attach_money,
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Gratuit', style: WinType.titleM(s.onStrong)),
                    Switch(
                      value: _free,
                      activeThumbColor: s.primary,
                      onChanged: (v) => setState(() => _free = v),
                    ),
                  ]),
                ]),
                const SizedBox(height: 32),
                WinButton('Soumettre pour révision',
                    block: true, loading: _loading,
                    icon: Icons.send_outlined, onTap: _publish),
              ]),
            ),
    );
  }
}
