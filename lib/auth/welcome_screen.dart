import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/language_selector.dart';
import '../widgets/win_logo.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';
import 'role_screen.dart';

/// Présentation de WinPlus avant la connexion : trois écrans, chacun avec
/// une photo du site en grand, le logo dans son disque blanc, un titre et une
/// phrase. « Passer » mène au dernier écran, qui propose de créer un compte
/// ou de se connecter.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _images = [
    'assets/home/epreuves.webp',
    'assets/home/hero-eleve-confiance.webp',
    'assets/home/parent-enfant-etude.jpg',
  ];

  final _pages = PageController();
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Photos chargées d'avance : pas d'éclair blanc en changeant d'écran.
    for (final image in _images) {
      precacheImage(AssetImage(image), context);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) => _pages.animateToPage(page,
      duration: winReducedMotion(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 320),
      curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final slides = [
      (_images[0], l.authWelcomeSlide1Title, l.authWelcomeSlide1Subtitle),
      (_images[1], l.authWelcomeSlide2Title, l.authWelcomeSlide2Subtitle),
      (_images[2], l.authWelcomeSlide3Title, l.authWelcomeSlide3Subtitle),
    ];
    final last = _page == slides.length - 1;

    return Scaffold(
      backgroundColor: s.bg,
      body: Column(children: [
        // Photo plein cadre (la moitié haute), logo et langue par-dessus.
        Expanded(
          flex: 11,
          child: Stack(fit: StackFit.expand, children: [
            PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Image.asset(slides[i].$1,
                  fit: BoxFit.cover, excludeFromSemantics: true),
            ),
            // Voile en haut : le logo et « Passer » restent lisibles.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment(0, -0.2),
                    colors: [Color(0x8C0B3530), Color(0x000B3530)],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Row(children: [
                    const WinLogo(size: 48),
                    const SizedBox(width: 8),
                    // Langue et « Passer » : réduits ensemble si la place
                    // manque (petit écran, grand texte système).
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const LanguageToggle(),
                            if (!last)
                              TextButton(
                                onPressed: () => _go(slides.length - 1),
                                child: Text(l.authSkip,
                                    style: WinType.manrope(
                                        size: 14,
                                        weight: FontWeight.w700,
                                        color: Colors.white)),
                              )
                            else
                              const SizedBox(width: 8),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        // Texte et actions sur une feuille aux coins arrondis qui remonte
        // sur la photo.
        Expanded(
          flex: 9,
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _page ? WinColors.teal600 : s.outline,
                              borderRadius:
                                  BorderRadius.circular(WinRadii.full),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(slides[_page].$2,
                                textAlign: TextAlign.center,
                                style: WinType.archivo(
                                    size: 26,
                                    weight: FontWeight.w700,
                                    height: 1.15,
                                    letterSpacing: -0.6,
                                    color: s.onStrong)),
                            const SizedBox(height: 10),
                            Text(slides[_page].$3,
                                textAlign: TextAlign.center,
                                style: WinType.bodyL(s.onMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (last) ...[
                      WinButton(l.createAccount,
                          variant: WinButtonVariant.accent,
                          block: true,
                          onTap: () => Navigator.push(context,
                              WinPageRoute(builder: (_) => const RoleScreen()))),
                      const SizedBox(height: 10),
                      WinButton(l.login,
                          variant: WinButtonVariant.outline,
                          block: true,
                          onTap: () => Navigator.push(
                              context,
                              WinPageRoute(
                                  builder: (_) => const LoginScreen()))),
                    ] else
                      WinButton(l.authNext,
                          variant: WinButtonVariant.accent,
                          block: true,
                          onTap: () => _go(_page + 1)),
                    const SizedBox(height: 4),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
