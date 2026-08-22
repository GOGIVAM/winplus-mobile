import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';
import 'role_screen.dart';

/// Écran de bienvenue. L'image centrale est un emplacement à remplir
/// par ton propre visuel (équivalent des image-slots du prototype HTML).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(children: [
            Image.asset('assets/winplus-logo.png', width: 96),
            const SizedBox(height: 8),
            Text('WinPlus', style: WinType.archivo(size: 28, weight: FontWeight.w700, color: s.onStrong)),
            Text('Ta réussite, notre mission', style: WinType.bodyS(s.onMuted)),
            Expanded(child: Center(child: _ImageSlot(label: "Image d'accueil"))),
            WinButton('Créer un compte', variant: WinButtonVariant.accent, block: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleScreen()))),
            const SizedBox(height: 12),
            WinButton('Se connecter', variant: WinButtonVariant.outline, block: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
          ]),
        ),
      ),
    );
  }
}

/// Emplacement d'image à remplacer par un Image.asset(...) une fois ton visuel fourni.
class _ImageSlot extends StatelessWidget {
  final String label;
  const _ImageSlot({required this.label});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      width: 280, height: 230,
      decoration: BoxDecoration(
        color: s.surface2,
        borderRadius: BorderRadius.circular(WinRadii.xl),
        border: Border.all(color: s.outline, width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_outlined, size: 40, color: s.onFaint),
        const SizedBox(height: 8),
        Text(label, style: WinType.labelM(s.onFaint)),
      ]),
    );
  }
}
