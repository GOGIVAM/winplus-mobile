import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/biometric_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Interrupteur « Déverrouillage par empreinte » (feuille de l'avatar).
/// Invisible si le téléphone n'a ni empreinte ni visage enregistré.
/// L'activation demande l'empreinte une fois, pour vérifier qu'elle marche.
class BiometricToggle extends StatefulWidget {
  const BiometricToggle({super.key});

  @override
  State<BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<BiometricToggle> {
  bool? _available;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    if (v && !await BiometricService.instance.authenticate()) return;
    await BiometricService.instance.setEnabled(v);
    if (mounted) setState(() => _enabled = v);
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(children: [
        Icon(Icons.fingerprint, color: s.onMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.biometricToggleTitle, style: WinType.titleM(s.onStrong)),
            Text(l.biometricToggleHint, style: WinType.bodyS(s.onMuted)),
          ]),
        ),
        Switch(value: _enabled, activeTrackColor: s.primary, onChanged: _toggle),
      ]),
    );
  }
}

/// Après une connexion : propose une fois l'empreinte, si le téléphone en a.
Future<void> offerBiometricIfUseful(BuildContext context) async {
  final service = BiometricService.instance;
  if (!await service.shouldOffer()) return;
  if (!context.mounted) return;
  await service.markOffered();
  if (!context.mounted) return;
  final l = context.l10n;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 36),
      title: Text(l.biometricOfferTitle),
      content: Text(l.biometricOfferBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.biometricOfferNo)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.biometricOfferYes)),
      ],
    ),
  );
  if (yes == true && await service.authenticate()) {
    await service.setEnabled(true);
  }
}
