import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/winai_markdown.dart';
import 'winai_listen_bar.dart';

/// Une fiche recto verso : la question d'un côté, la réponse de l'autre.
typedef WinAIFlashcard = ({String question, String answer});

final _qLine =
    RegExp(r'^(?:Q|Question)\s*\d*\s*:\s*(.*)$', caseSensitive: false);
// « R.ponse » : avec ou sans accent.
final _aLine = RegExp(r'^(?:R|A|R.ponse|Answer)\s*\d*\s*:\s*(.*)$',
    caseSensitive: false);
final _bullet = RegExp(r'^(?:[-*]\s+|\d+[.)]\s+)');

/// Lit les fiches dans la réponse de WinAI : une ligne « Q: » puis une ligne
/// « R: » (ou « A: » en anglais). Les lignes suivantes prolongent la réponse.
/// Renvoie une liste vide si le texte ne suit pas cette forme.
List<WinAIFlashcard> parseFlashcards(String raw) {
  final cards = <WinAIFlashcard>[];
  String? q;
  StringBuffer? a;
  void close() {
    final question = q?.trim() ?? '';
    final answer = a?.toString().trim() ?? '';
    if (question.isNotEmpty && answer.isNotEmpty) {
      cards.add((question: question, answer: answer));
    }
    q = null;
    a = null;
  }

  for (final line in raw.split('\n')) {
    final plain = line.trim().replaceAll('**', '');
    final head = plain.replaceFirst(_bullet, '');
    final mq = _qLine.firstMatch(head);
    if (mq != null) {
      close();
      q = mq.group(1);
      continue;
    }
    final ma = _aLine.firstMatch(head);
    if (ma != null && q != null && a == null) {
      a = StringBuffer(ma.group(1) ?? '');
      continue;
    }
    if (plain.isEmpty) continue;
    if (a != null) {
      a!.write('\n$plain');
    } else if (q != null) {
      q = '$q $plain';
    }
  }
  close();
  return cards;
}

/// Résultat d'un outil de l'atelier : le texte mis en forme, avec la barre
/// d'écoute en bas (exercices corrigés, plan de révision, résumé audio…).
class WinAITextScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String text;

  /// Identifie ce texte pour la lecture à voix haute.
  final String speechKey;
  const WinAITextScreen(
      {super.key,
      required this.title,
      required this.text,
      required this.speechKey,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = subtitle?.trim() ?? '';
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: WinAIListenBar(text: text, speechKey: speechKey),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (sub.isNotEmpty) ...[
            Text(sub, style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 12),
          ],
          WinAIMarkdown(text, color: s.onSurface),
        ],
      ),
    );
  }
}

/// Fiches recto verso : une fiche à la fois, un appui la retourne.
class WinAIFlashcardsScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<WinAIFlashcard> cards;
  const WinAIFlashcardsScreen(
      {super.key, required this.title, required this.cards, this.subtitle});

  @override
  State<WinAIFlashcardsScreen> createState() => _WinAIFlashcardsScreenState();
}

class _WinAIFlashcardsScreenState extends State<WinAIFlashcardsScreen> {
  int _index = 0;
  bool _back = false;

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.cards.length) return;
    setState(() {
      _index = next;
      _back = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    if (widget.cards.isEmpty) {
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(title: Text(widget.title)),
        body: WinEmptyState(
            title: l.winaiCardsEmpty, icon: PhosphorIconsRegular.cards),
      );
    }
    final card = widget.cards[_index];
    final total = widget.cards.length;
    final sub = widget.subtitle?.trim() ?? '';
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WinType.bodyS(s.onMuted))),
              Text(l.winaiCardsCount(_index + 1, total),
                  style: WinType.labelM(s.onMuted)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(WinRadii.full),
              child: LinearProgressIndicator(
                  value: (_index + 1) / total, minHeight: 4),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Semantics(
                button: true,
                label: l.winaiCardsFlip,
                child: Material(
                  color: _back ? s.primaryContainer : s.cardBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WinRadii.xl),
                      side: BorderSide(color: s.cardBorder)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _back = !_back),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                                _back
                                    ? l.winaiCardsAnswer
                                    : l.winaiCardsQuestion,
                                style: WinType.labelM(s.primary)),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    child: Text(
                                        _back ? card.answer : card.question,
                                        key: ValueKey('$_index:$_back'),
                                        textAlign: TextAlign.center,
                                        style: _back
                                            ? WinType.bodyL(s.onStrong)
                                            : WinType.headlineS(s.onStrong)),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.arrowsClockwise,
                                      size: 16, color: s.onMuted),
                                  const SizedBox(width: 6),
                                  Text(l.winaiCardsFlip,
                                      style: WinType.labelM(s.onMuted)),
                                ]),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: _index == 0 ? null : () => _go(-1),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, size: 18),
                    label: Text(l.winaiCardsPrevious)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                    onPressed: _index == total - 1 ? null : () => _go(1),
                    icon: const Icon(PhosphorIconsRegular.arrowRight, size: 18),
                    label: Text(l.winaiCardsNext)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
