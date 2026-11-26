import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import 'win_widgets.dart';

/// Sélecteur de matière : on choisit dans la liste, on ne tape jamais le nom
/// (une matière mal orthographiée ne correspond à aucun contenu). La valeur
/// est le nom de la matière tel que l'API l'enregistre.
///
/// Avec [allowNone], un second appui sur la matière choisie la retire.
class WinSubjectPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool allowNone;
  const WinSubjectPicker(
      {super.key,
      required this.value,
      required this.onChanged,
      this.allowNone = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final sub in WinData.subjects)
        WinChip(sub.short,
            active: value == sub.name,
            onTap: () => onChanged(
                allowNone && value == sub.name ? '' : sub.name)),
    ]);
  }
}
