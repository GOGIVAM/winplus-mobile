import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../services/two_factor_service.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'settings_screen.dart' show kTwoFactorSetupAvailable;
import 'two_factor_settings_screen.dart';

/// Rappel discret de la double authentification sur l'accueil (décision de
/// Georges, 28/11 : jamais obligatoire, mais on peut la rappeler).
/// Rien pour un compte déjà protégé ; « Plus tard » la fait revenir après
/// [snooze] ; en cas de panne du serveur, rien non plus.
class TwoFactorReminderCard extends StatefulWidget {
  static const prefKey = 'twofa_reminder_until';
  static const snooze = Duration(days: 30);
  const TwoFactorReminderCard({super.key});

  @override
  State<TwoFactorReminderCard> createState() => _TwoFactorReminderCardState();
}

class _TwoFactorReminderCardState extends State<TwoFactorReminderCard> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    if (kTwoFactorSetupAvailable) _check();
  }

  Future<void> _check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(TwoFactorReminderCard.prefKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < until) return;
      final st = await TwoFactorService.instance.status();
      if (mounted) setState(() => _show = !st.isEnabled);
    } catch (_) {
      // Pas de rappel si l'état est inconnu.
    }
  }

  Future<void> _later() async {
    setState(() => _show = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(TwoFactorReminderCard.prefKey,
          DateTime.now().add(TwoFactorReminderCard.snooze).millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _open() async {
    await Navigator.push(context, WinPageRoute(builder: (_) => const TwoFactorSettingsScreen()));
    if (mounted) _check();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(PhosphorIconsRegular.shieldCheck, size: 24, color: s.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(l.twoFaReminderTitle, style: WinType.titleM(s.onStrong))),
          ]),
          const SizedBox(height: 6),
          Text(l.twoFaReminderText, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 12),
          Row(children: [
            WinButton(l.twoFaEnable, small: true, onTap: _open),
            const SizedBox(width: 10),
            WinButton(l.twoFaReminderLater, small: true, variant: WinButtonVariant.outline, onTap: _later),
          ]),
        ]),
      ),
    );
  }
}
