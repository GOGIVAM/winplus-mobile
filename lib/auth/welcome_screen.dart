import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';
import 'role_screen.dart';

/// Onboarding en carrousel (direction visuelle "Funica") : un panneau plein
/// cadre par slide (icône/illustration + fond dégradé teal), titre + sous-
/// titre, pagination en pilules, CTA finaux sur la dernière slide.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _OnboardSlide {
  final IconData icon;
  final String title, subtitle;
  const _OnboardSlide(this.icon, this.title, this.subtitle);
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardSlide(
      Icons.menu_book_rounded,
      'Toutes tes épreuves, réunies',
      'Annales, corrigés et quiz du BEPC aux concours des grandes écoles.',
    ),
    _OnboardSlide(
      Icons.auto_awesome_rounded,
      'WinAI à tes côtés',
      'Un assistant pédagogique qui identifie tes lacunes et te propose un plan de révision.',
    ),
    _OnboardSlide(
      Icons.groups_rounded,
      'Toute la famille impliquée',
      'Parents, professeurs, élèves : chacun suit la progression en temps réel.',
    ),
  ];

  void _goNext() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Image.asset('assets/winplus-logo.png', width: 32),
              const SizedBox(width: 8),
              Text('WinPlus',
                  style: WinType.archivo(
                      size: 18, weight: FontWeight.w700, color: s.onStrong)),
              const Spacer(),
              const _LanguageToggle(),
              if (!isLast) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _pageCtrl.animateToPage(
                      _slides.length - 1,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut),
                  child: Text('Passer',
                      style: WinType.manrope(
                          size: 13, weight: FontWeight.w600, color: s.onMuted)),
                ),
              ],
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _SlidePanel(slide: _slides[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? s.primary : s.outline,
                    borderRadius: BorderRadius.circular(WinRadii.full),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: isLast
                ? Column(children: [
                    WinButton(
                      l10n.createAccount,
                      variant: WinButtonVariant.accent,
                      block: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RoleScreen())),
                    ),
                    const SizedBox(height: 12),
                    WinButton(
                      l10n.login,
                      variant: WinButtonVariant.outline,
                      block: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                    ),
                  ])
                : WinButton('Suivant',
                    block: true,
                    icon: Icons.arrow_forward_rounded,
                    onTap: _goNext),
          ),
        ]),
      ),
    );
  }
}

class _SlidePanel extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlidePanel({required this.slide});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WinRadii.xl),
              gradient: LinearGradient(
                colors: [s.heroFrom, s.heroTo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 56, color: WinColors.teal400),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(slide.title,
            textAlign: TextAlign.center,
            style: WinType.displayS(s.onStrong)),
        const SizedBox(height: 10),
        Text(slide.subtitle,
            textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 12),
      ]),
    );
  }
}

/// Bascule FR/EN manuelle (US onboarding). Persistée par WinAppState.setLocale
/// (SharedPreferences + synchro profil si connecté).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();
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
