import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _yearCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _type = 'Épreuve';
  String _subject = 'Mathématiques';
  String _level = 'BAC C';
  String _exam = 'BAC';
  bool _prixLibre = false;
  PlatformFile? _pickedFile;
  bool _loading = false;
  String? _errorMsg;

  static const _types = ['Épreuve', 'Correction', 'Quiz', 'Livre', 'Pack', 'Fiche'];
  static const _subjects = ['Mathématiques', 'Physique', 'Chimie', 'Français', 'SVT', 'Anglais', 'Histoire-Géo'];
  static const _levels = ['BEPC', 'Probatoire', 'BAC A', 'BAC C', 'BAC D', 'Concours'];
  static const _exams = ['BAC', 'BEPC', 'ENSP', 'Polytechnique', 'ESSEC', 'FMSB', 'ENAM', 'ENS'];

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'zip'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      if (mounted) setState(() => _errorMsg = 'Veuillez saisir un titre.');
      return;
    }
    if (_pickedFile == null) {
      if (mounted) setState(() => _errorMsg = 'Veuillez choisir un fichier.');
      return;
    }
    if (mounted) setState(() { _loading = true; _errorMsg = null; });
    try {
      final price = _prixLibre
          ? (int.tryParse(_priceCtrl.text.trim()) ?? 0)
          : 0;
      final ok = await TeacherService.instance.publishContent(
        title: _titleCtrl.text.trim(),
        type: _type,
        subjectCategory: _subject,
        level: _level,
        price: price,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenu soumis pour révision !')),
        );
        Navigator.pop(context);
      } else {
        setState(() => _errorMsg = 'Échec de la soumission. Réessayez.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Erreur réseau. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: WinType.titleM(s.onStrong)),
    );
  }

  Widget _styledDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? display,
  }) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border.all(color: s.outline),
        borderRadius: BorderRadius.zero,
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: s.onMuted, size: 20),
        style: WinType.bodyM(s.onStrong),
        dropdownColor: s.surface,
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    display != null ? display(e) : e.toString(),
                    style: WinType.bodyM(s.onStrong),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Publier un contenu', style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 1. Titre
          _label('Titre *'),
          TextField(
            controller: _titleCtrl,
            maxLength: 100,
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: 'Ex: BAC C Mathématiques 2024',
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              counterStyle: WinType.labelS(s.onFaint),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Type + Matière
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Type'),
              _styledDropdown<String>(
                value: _type,
                items: _types,
                onChanged: (v) { if (v != null) setState(() => _type = v); },
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Matière'),
              _styledDropdown<String>(
                value: _subject,
                items: _subjects,
                onChanged: (v) { if (v != null) setState(() => _subject = v); },
              ),
            ])),
          ]),
          const SizedBox(height: 16),

          // 3. Chips niveau
          _label('Niveau'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _levels.map((lvl) {
                final active = _level == lvl;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _level = lvl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? s.primary : Colors.transparent,
                        border: Border.all(
                          color: active ? s.primary : s.outline,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        lvl,
                        style: WinType.manrope(
                          size: 13,
                          weight: FontWeight.w600,
                          color: active ? s.onPrimary : s.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Examen
          _label('Examen'),
          _styledDropdown<String>(
            value: _exam,
            items: _exams,
            onChanged: (v) { if (v != null) setState(() => _exam = v); },
          ),
          const SizedBox(height: 16),

          // 5. Année
          _label('Année'),
          TextField(
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: 'Ex: 2024',
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Description
          _label('Description'),
          TextField(
            controller: _descCtrl,
            maxLength: 500,
            maxLines: 4,
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: 'Décrivez le contenu (objectifs, niveau, contenu…)',
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              counterStyle: WinType.labelS(s.onFaint),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7. Prix
          _label('Prix'),
          _PrixRow(
            prixLibre: _prixLibre,
            priceCtrl: _priceCtrl,
            onChanged: (v) => setState(() => _prixLibre = v),
          ),
          const SizedBox(height: 20),

          // 8. Upload fichier
          _label('Fichier'),
          if (_pickedFile == null)
            WinButton(
              'Choisir un fichier',
              variant: WinButtonVariant.outline,
              block: true,
              icon: Icons.attach_file,
              onTap: _pickFile,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: WinColors.successBg,
                border: Border.all(color: WinColors.success.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 20, color: WinColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_pickedFile!.name}${_pickedFile!.size > 0 ? ' · ${_formatFileSize(_pickedFile!.size)}' : ''}',
                    style: WinType.bodyM(WinColors.success),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _pickedFile = null),
                  child: const Icon(Icons.close, size: 18, color: WinColors.success),
                ),
              ]),
            ),
          const SizedBox(height: 28),

          // 9. Erreur inline
          if (_errorMsg != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorMsg!, style: WinType.bodyS(WinColors.error)),
            ),
          ],

          // 9. Bouton publier
          WinButton(
            'Publier pour révision',
            block: true,
            loading: _loading,
            icon: Icons.send_outlined,
            onTap: _submit,
          ),
          const SizedBox(height: 12),

          // 10. Note légale
          Center(
            child: Text(
              'Votre contenu sera examiné avant d\'être publié (24-48h)',
              style: WinType.labelS(s.onMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ),
    );
  }
}

class _PrixRow extends StatelessWidget {
  final bool prixLibre;
  final TextEditingController priceCtrl;
  final ValueChanged<bool> onChanged;

  const _PrixRow({
    required this.prixLibre,
    required this.priceCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Option 1: Abonnement uniquement
      GestureDetector(
        onTap: () => onChanged(false),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: !prixLibre ? s.primary : s.outline,
                width: 2,
              ),
            ),
            child: !prixLibre
                ? Center(
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Abonnement uniquement', style: WinType.titleM(s.onStrong)),
            Text('Accessible à tous les abonnés', style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Option 2: Prix libre
      GestureDetector(
        onTap: () => onChanged(true),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: prixLibre ? s.primary : s.outline,
                width: 2,
              ),
            ),
            child: prixLibre
                ? Center(
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prix libre', style: WinType.titleM(s.onStrong)),
            Text('Fixez votre propre prix en XAF', style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
      if (prixLibre) ...[
        const SizedBox(height: 12),
        TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: WinType.bodyM(s.onStrong),
          decoration: InputDecoration(
            hintText: 'Montant en XAF (ex: 500)',
            hintStyle: WinType.bodyM(s.onFaint),
            filled: true,
            fillColor: s.surface,
            suffixText: 'XAF',
            suffixStyle: WinType.labelM(s.onMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: s.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: s.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: s.primary, width: 1.5),
            ),
          ),
        ),
      ],
    ]);
  }
}
