import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Dictée vocale (lot 6) : la reconnaissance vocale du téléphone transcrit la
/// question, comme la dictée du site (Web Speech API). Le texte reconnu est
/// renvoyé à l'appelant, qui le place dans le champ de saisie : rien n'est
/// envoyé sans que la personne relise et valide.
///
/// Renvoie `null` si la dictée est annulée ou indisponible.
Future<String?> showVoiceDictation(BuildContext context) {
  return showModalBottomSheet<String>(
      showDragHandle: false,
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VoiceDictationSheet(),
  );
}

class _VoiceDictationSheet extends StatefulWidget {
  const _VoiceDictationSheet();
  @override
  State<_VoiceDictationSheet> createState() => _VoiceDictationSheetState();
}

class _VoiceDictationSheetState extends State<_VoiceDictationSheet> {
  final _speech = SpeechToText();
  String _texte = '';
  bool _ecoute = false;
  bool _indisponible = false;

  @override
  void initState() {
    super.initState();
    _demarrer();
  }

  Future<void> _demarrer() async {
    bool ok;
    try {
      ok = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _ecoute = false);
        },
        onStatus: (statut) {
          if (!mounted) return;
          if (statut == SpeechToText.doneStatus ||
              statut == SpeechToText.notListeningStatus) {
            setState(() => _ecoute = false);
          }
        },
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      // Micro refusé ou pas de service de reconnaissance sur le téléphone.
      setState(() => _indisponible = true);
      return;
    }
    setState(() => _ecoute = true);
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          if (mounted) setState(() => _texte = r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: L10n.code == 'en' ? 'en_GB' : 'fr_FR',
          partialResults: true,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _ecoute = false;
          _indisponible = true;
        });
      }
    }
  }

  Future<void> _arreter() async {
    await _speech.stop();
    if (mounted) setState(() => _ecoute = false);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final texte = _texte.trim();
    return Container(
      decoration: BoxDecoration(
          color: s.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: s.outline2,
                borderRadius: BorderRadius.circular(WinRadii.full))),
        Icon(_ecoute ? PhosphorIconsFill.microphone : PhosphorIconsRegular.microphone,
            size: 44, color: _ecoute ? WinColors.teal600 : s.onFaint),
        const SizedBox(height: 12),
        Text(
          _indisponible
              ? l.voiceUnavailable
              : _ecoute
                  ? l.voiceListening
                  : (texte.isEmpty ? l.voiceNothingHeard : l.voiceCheckText),
          textAlign: TextAlign.center,
          style: WinType.titleM(s.onStrong),
        ),
        if (texte.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(texte,
              textAlign: TextAlign.center, style: WinType.bodyM(s.onSurface)),
        ],
        const SizedBox(height: 22),
        if (_ecoute)
          WinButton(l.voiceStop,
              block: true, icon: PhosphorIconsFill.stop, onTap: _arreter)
        else if (!_indisponible && texte.isNotEmpty)
          WinButton(l.voiceUseText,
              block: true, onTap: () => Navigator.pop(context, texte))
        else if (!_indisponible)
          WinButton(l.voiceRetry,
              block: true, icon: PhosphorIconsRegular.microphone, onTap: _demarrer),
        const SizedBox(height: 8),
        WinButton(l.commonCancel,
            block: true,
            variant: WinButtonVariant.ghost,
            onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}
