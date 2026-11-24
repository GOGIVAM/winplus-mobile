import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Réponse WinAI mise en forme, comme sur le site (MarkdownMath.tsx) :
/// titres, gras, italique, listes, tableaux, code, et formules LaTeX
/// ($…$, $$…$$, \(…\), \[…\]) compilées au lieu d'être affichées brutes.
/// Utilisée par les quatre espaces (élève, parent, professeur, établissement).
class WinAIMarkdown extends StatelessWidget {
  final String text;
  final Color? color;
  const WinAIMarkdown(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GptMarkdown(
      text,
      // Le modèle écrit ses formules entre $…$ (consigne du prompt), parfois
      // entre \(…\) : les deux sont compilés, comme sur le site.
      useDollarSignsForLatex: true,
      style: WinType.bodyM(color ?? s.onSurface),
    );
  }
}
