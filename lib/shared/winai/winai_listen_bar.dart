import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/speech_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';

/// Barre d'écoute : fait lire un texte par la voix du téléphone, avec
/// lecture et pause, vitesse et progression. Utilisée sous une fiche de
/// révision et pour le résumé audio de WinAI.
///
/// [speechKey] identifie ce texte : la barre ne montre « en lecture » que si
/// c'est bien lui que le téléphone est en train de lire.
class WinAIListenBar extends StatefulWidget {
  final String text;
  final String speechKey;
  const WinAIListenBar({super.key, required this.text, required this.speechKey});

  @override
  State<WinAIListenBar> createState() => _WinAIListenBarState();
}

class _WinAIListenBarState extends State<WinAIListenBar> {
  static const _rates = [0.75, 1.0, 1.25, 1.5];

  @override
  void dispose() {
    // Sinon la lecture continue après avoir quitté l'écran.
    final svc = SpeechService.instance;
    if (svc.state.value.key == widget.speechKey) svc.stop();
    super.dispose();
  }

  void _nextRate(double current) {
    final i = _rates.indexWhere((r) => (r - current).abs() < 0.01);
    SpeechService.instance.setRate(_rates[(i + 1) % _rates.length]);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final svc = SpeechService.instance;
    return ValueListenableBuilder<SpeechState>(
      valueListenable: svc.state,
      builder: (context, st, _) {
        final mine = st.key == widget.speechKey;
        final playing = mine && st.isPlaying;
        final paused = mine && st.isPaused;
        final label = playing
            ? l.winaiListenPause
            : paused
                ? l.winaiListenResume
                : l.winaiListen;
        return Material(
          color: s.surface,
          child: SafeArea(
            top: false,
            child: Container(
              decoration:
                  BoxDecoration(border: Border(top: BorderSide(color: s.outline))),
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (mine && st.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: Row(children: [
                      const Icon(PhosphorIconsRegular.warningCircle,
                          size: 16, color: WinColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(l.winaiListenUnavailable,
                              style: WinType.labelM(s.onMuted))),
                    ]),
                  ),
                Row(children: [
                  // Bouton principal : écouter, mettre en pause, reprendre.
                  Semantics(
                    button: true,
                    label: label,
                    child: Material(
                      color: s.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () =>
                            svc.toggle(widget.text, key: widget.speechKey),
                        child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                                playing
                                    ? PhosphorIconsFill.pause
                                    : PhosphorIconsFill.play,
                                size: 22,
                                color: s.onPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: WinType.titleM(s.onStrong)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(WinRadii.full),
                            child: LinearProgressIndicator(
                                value: mine ? st.progress.clamp(0, 1) : 0,
                                minHeight: 4),
                          ),
                        ]),
                  ),
                  // Vitesse de lecture : un appui passe à la suivante.
                  TextButton(
                      onPressed: () => _nextRate(st.rate),
                      child: Text('${_fmt(st.rate)}×')),
                  if (playing || paused)
                    IconButton(
                        tooltip: l.winaiListenStop,
                        icon: const Icon(PhosphorIconsFill.stop, size: 18),
                        onPressed: svc.stop),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(double r) =>
      r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
}
