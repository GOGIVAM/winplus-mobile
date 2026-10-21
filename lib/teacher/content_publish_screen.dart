import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

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

  static const _types = [
    'Épreuve',
    'Correction',
    'Quiz',
    'Livre',
    'Pack',
    'Fiche'
  ];
  static const _subjects = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Français',
    'SVT',
    'Anglais',
    'Histoire-Géo'
  ];
  static const _levels = [
    'BEPC',
    'Probatoire',
    'BAC A',
    'BAC C',
    'BAC D',
    'Concours'
  ];
  static const _exams = [
    'BAC',
    'BEPC',
    'ENSP',
    'Polytechnique',
    'ESSEC',
    'FMSB',
    'ENAM',
    'ENS'
  ];

  // Libellés affichés ; les valeurs envoyées à l'API (_type, _subject, _level) ne changent pas.
  String _typeLabel(String t) => switch (t) {
        'Épreuve' => context.l10n.dataTypePaper,
        'Correction' => context.l10n.dataTypeCorrection,
        'Quiz' => context.l10n.studentReportsQuiz,
        'Livre' => context.l10n.dataTypeBook,
        'Pack' => context.l10n.teacherPublishTypePack,
        'Fiche' => context.l10n.teacherPublishTypeSheet,
        _ => t,
      };

  String _subjectLabel(String sub) => switch (sub) {
        'Mathématiques' => context.l10n.dataSubjectMath,
        'Physique' => context.l10n.dataSubjectPhysics,
        'Chimie' => context.l10n.dataSubjectChemistry,
        'Français' => context.l10n.dataSubjectFrench,
        'Anglais' => context.l10n.dataSubjectEnglish,
        'Histoire-Géo' => context.l10n.dataSubjectHistGeo,
        _ => sub,
      };

  String _levelLabel(String lvl) =>
      lvl == 'Concours' ? context.l10n.authOptConcours : lvl;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return context.l10n.teacherPublishSizeBytes(bytes);
    if (bytes < 1024 * 1024) return context.l10n.teacherPublishSizeKb((bytes / 1024).toStringAsFixed(1));
    return context.l10n.teacherPublishSizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
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
      if (mounted) setState(() => _errorMsg = L10n.current.teacherPublishTitleRequired);
      return;
    }
    if (_pickedFile == null) {
      if (mounted) setState(() => _errorMsg = L10n.current.teacherPublishFileRequired);
      return;
    }
    if (mounted)
      setState(() {
        _loading = true;
        _errorMsg = null;
      });
    try {
      final price =
          _prixLibre ? (int.tryParse(_priceCtrl.text.trim()) ?? 0) : 0;
      final ok = await TeacherService.instance.publishContent(
        title: _titleCtrl.text.trim(),
        type: _type,
        subjectCategory: _subject,
        level: _level,
        price: price,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.teacherPublishSubmitted)),
        );
        Navigator.pop(context);
      } else {
        setState(() => _errorMsg = L10n.current.teacherPublishSubmitFailed);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = L10n.current.teacherPublishNetworkError);
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
        borderRadius: BorderRadius.circular(WinRadii.md),
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
        title: Text(context.l10n.teacherPublishTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 1. Titre
          _label(context.l10n.forumTitleField),
          TextField(
            controller: _titleCtrl,
            maxLength: 100,
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: context.l10n.teacherPublishTitleHint,
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              counterStyle: WinType.labelS(s.onFaint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Type + Matière
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label(context.l10n.teacherPublishType),
                  _styledDropdown<String>(
                    value: _type,
                    items: _types,
                    display: _typeLabel,
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label(context.l10n.commonSubject),
                  _styledDropdown<String>(
                    value: _subject,
                    items: _subjects,
                    display: _subjectLabel,
                    onChanged: (v) {
                      if (v != null) setState(() => _subject = v);
                    },
                  ),
                ])),
          ]),
          const SizedBox(height: 16),

          // 3. Chips niveau
          _label(context.l10n.commonLevel),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? s.primary : Colors.transparent,
                        border: Border.all(
                          color: active ? s.primary : s.outline,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(WinRadii.full),
                      ),
                      child: Text(
                        _levelLabel(lvl),
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
          _label(context.l10n.widgetMemExam),
          _styledDropdown<String>(
            value: _exam,
            items: _exams,
            onChanged: (v) {
              if (v != null) setState(() => _exam = v);
            },
          ),
          const SizedBox(height: 16),

          // 5. Année
          _label(context.l10n.teacherPublishYear),
          TextField(
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: context.l10n.teacherPublishYearHint,
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Description
          _label(context.l10n.commonDescription),
          TextField(
            controller: _descCtrl,
            maxLength: 500,
            maxLines: 4,
            style: WinType.bodyM(s.onStrong),
            decoration: InputDecoration(
              hintText: context.l10n.teacherPublishDescriptionHint,
              hintStyle: WinType.bodyM(s.onFaint),
              filled: true,
              fillColor: s.surface,
              counterStyle: WinType.labelS(s.onFaint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7. Prix
          _label(context.l10n.tutoringPrice),
          _PrixRow(
            prixLibre: _prixLibre,
            priceCtrl: _priceCtrl,
            onChanged: (v) => setState(() => _prixLibre = v),
          ),
          const SizedBox(height: 20),

          // 8. Upload fichier
          _label(context.l10n.teacherVerifFile),
          if (_pickedFile == null)
            WinButton(
              context.l10n.teacherPublishChooseFile,
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
                border:
                    Border.all(color: WinColors.success.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(WinRadii.md),
              ),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf_outlined,
                    size: 20, color: WinColors.success),
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
                  child: const Icon(Icons.close,
                      size: 18, color: WinColors.success),
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
            context.l10n.teacherPublishSubmit,
            block: true,
            loading: _loading,
            icon: Icons.send_outlined,
            onTap: _submit,
          ),
          const SizedBox(height: 12),

          // 10. Note légale
          Center(
            child: Text(
              context.l10n.teacherPublishReviewNote,
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
            width: 20,
            height: 20,
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
                      width: 10,
                      height: 10,
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
            Text(context.l10n.teacherPublishSubscriptionOnly, style: WinType.titleM(s.onStrong)),
            Text(context.l10n.teacherPublishSubscriptionOnlyHint,
                style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Option 2: Prix libre
      GestureDetector(
        onTap: () => onChanged(true),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
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
                      width: 10,
                      height: 10,
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
            Text(context.l10n.teacherPublishFreePrice, style: WinType.titleM(s.onStrong)),
            Text(context.l10n.teacherPublishFreePriceHint,
                style: WinType.labelS(s.onMuted)),
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
            hintText: context.l10n.teacherPublishAmountHint,
            hintStyle: WinType.bodyM(s.onFaint),
            filled: true,
            fillColor: s.surface,
            suffixText: 'XAF',
            suffixStyle: WinType.labelM(s.onMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WinRadii.md),
              borderSide: BorderSide(color: s.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WinRadii.md),
              borderSide: BorderSide(color: s.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WinRadii.md),
              borderSide: BorderSide(color: s.primary, width: 1.5),
            ),
          ),
        ),
      ],
    ]);
  }
}
