import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/class_levels.dart';
import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Libellé affiché d'une matière du tutorat (la valeur échangée avec le
/// serveur reste celle de la liste commune).
String tutorSubjectLabel(String v) {
  final l = L10n.current;
  return switch (v) {
    'Mathématiques' => l.dataSubjectMath,
    'Physique' => l.dataSubjectPhysics,
    'Chimie' => l.dataSubjectChemistry,
    'Français' => l.dataSubjectFrench,
    'Philosophie' => l.dataSubjectPhilosophy,
    'Anglais' => l.dataSubjectEnglish,
    'Histoire-Géo' => l.dataSubjectHistGeo,
    'Informatique' => l.dataSubjectComputing,
    'Économie' => l.tutoringSubjectEconomics,
    _ => v,
  };
}

/// Libellé affiché d'un niveau du tutorat.
String tutorLevelLabel(String v) {
  final l = L10n.current;
  return switch (v) {
    'Prépa' => l.authLvlPrepa,
    'FMSB Médecine' => l.authLvlFmsb,
    'ESSEC Commerce' => l.authLvlEssec,
    'ENAM Administration' => l.teacherProfileLevelEnam,
    'ENS École Normale' => l.authLvlEns,
    _ => ClassLevels.label(v),
  };
}

/// Feuille de choix dans une liste commune (matières, niveaux), rangée par
/// sections et filtrable. Rend le choix, ou null si la feuille est fermée
/// sans choisir. Avec [noneLabel], une première ligne retire le choix
/// (ensemble vide). Avec [multiple], plusieurs lignes se cochent puis se
/// valident.
Future<Set<String>?> showTutorRefPicker(
  BuildContext context, {
  required String title,
  required List<(String, List<String>)> sections,
  required Set<String> selected,
  required String Function(String) labelOf,
  String? noneLabel,
  bool multiple = false,
}) =>
    showWinBottomSheet<Set<String>>(
      context: context,
      title: title,
      child: _RefPicker(
          sections: sections,
          selected: selected,
          labelOf: labelOf,
          noneLabel: noneLabel,
          multiple: multiple),
    );

// Lettres accentuées ramenées à leur lettre de base, pour que « mathem »
// trouve la matière écrite avec un accent.
const _plain = <int, String>{
  0xE0: 'a', 0xE2: 'a', 0xE4: 'a', 0xE7: 'c', 0xE8: 'e', 0xE9: 'e',
  0xEA: 'e', 0xEB: 'e', 0xEE: 'i', 0xEF: 'i', 0xF4: 'o', 0xF6: 'o',
  0xF9: 'u', 0xFB: 'u', 0xFC: 'u',
};

String _fold(String v) => String.fromCharCodes([
      for (final r in v.toLowerCase().runes) ...(_plain[r]?.runes ?? [r]),
    ]);

class _RefPicker extends StatefulWidget {
  final List<(String, List<String>)> sections;
  final Set<String> selected;
  final String Function(String) labelOf;
  final String? noneLabel;
  final bool multiple;
  const _RefPicker(
      {required this.sections,
      required this.selected,
      required this.labelOf,
      required this.noneLabel,
      required this.multiple});

  @override
  State<_RefPicker> createState() => _RefPickerState();
}

class _RefPickerState extends State<_RefPicker> {
  late final Set<String> _sel = {...widget.selected};
  String _query = '';

  void _tap(String v) {
    if (!widget.multiple) {
      Navigator.pop(context, {v});
      return;
    }
    setState(() => _sel.contains(v) ? _sel.remove(v) : _sel.add(v));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final shown = [
      for (final (name, items) in widget.sections)
        (
          name,
          [
            for (final v in items)
              if (_query.isEmpty ||
                  _fold(widget.labelOf(v)).contains(_query) ||
                  _fold(v).contains(_query))
                v,
          ]
        ),
    ].where((e) => e.$2.isNotEmpty).toList();
    final total =
        widget.sections.fold<int>(0, (n, e) => n + e.$2.length);
    final headers = widget.sections.where((e) => e.$2.isNotEmpty).length > 1;

    return SizedBox(
      // Hauteur fixe : la liste défile, la recherche et le bouton restent
      // en place.
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (total > 12) ...[
          WinTextField(
              hint: l.tutoringRefSearch,
              icon: PhosphorIconsRegular.magnifyingGlass,
              onChanged: (v) => setState(() => _query = _fold(v.trim()))),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            if (widget.noneLabel != null && _query.isEmpty)
              _RefLine(widget.noneLabel!,
                  selected: _sel.isEmpty,
                  onTap: () => Navigator.pop(context, <String>{})),
            for (final (name, items) in shown) ...[
              if (headers)
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Text(name, style: WinType.labelM(s.onMuted)),
                ),
              for (final v in items)
                _RefLine(widget.labelOf(v),
                    selected: _sel.contains(v), onTap: () => _tap(v)),
            ],
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l.tutoringRefEmpty,
                    textAlign: TextAlign.center,
                    style: WinType.bodyM(s.onMuted)),
              ),
          ]),
        ),
        if (widget.multiple) ...[
          const SizedBox(height: 12),
          WinButton(l.commonConfirm,
              block: true, onTap: () => Navigator.pop(context, _sel)),
        ],
      ]),
    );
  }
}

class _RefLine extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RefLine(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WinRadii.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(label,
                  style: WinType.bodyM(selected ? s.primary : s.onStrong)
                      .copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400)),
            ),
          ),
          if (selected)
            Icon(PhosphorIconsBold.check, size: 18, color: s.primary),
        ]),
      ),
    );
  }
}
