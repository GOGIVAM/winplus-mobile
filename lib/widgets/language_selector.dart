import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Bascule FR/EN (accueil, réglages de chaque espace). Persistée par
/// WinAppState.setLocale : SharedPreferences, et User.Locale si connecté.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = WinAppScope.of(context);
    final current = state.locale.languageCode;
    Widget seg(String code) {
      final active = current == code;
      return GestureDetector(
        onTap: () => state.setLocale(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? s.onStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(WinRadii.full),
          ),
          child: Text(code.toUpperCase(),
              style: WinType.manrope(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? s.bg : s.onMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: s.outline, width: 1),
        borderRadius: BorderRadius.circular(WinRadii.full),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('fr'),
        seg('en'),
      ]),
    );
  }
}

/// Feuille de réglage de la langue (lot 10.11), ouverte depuis l'avatar de
/// la barre du haut : utile aux espaces sans écran de réglages (professeur).
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: WinTheme.of(context).surface,
    builder: (ctx) {
      final s = WinTheme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.language, color: s.onMuted),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(ctx.l10n.language,
                        style: WinType.titleM(s.onStrong))),
                const LanguageToggle(),
              ]),
              const SizedBox(height: 10),
              Text(ctx.l10n.languageHint, style: WinType.bodyS(s.onMuted)),
            ],
          ),
        ),
      );
    },
  );
}
