import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/connectivity_service.dart';
import '../services/deep_links.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import 'app_lock_screen.dart';
import 'periodic_confirm_screen.dart';
import 'login_screen.dart';

/// Délai après lequel l'identité doit être reprouvée (35 jours, comme le
/// serveur).
const reconfirmWindow = Duration(days: 35);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..forward();

  @override
  void initState() {
    super.initState();
    // Juste le temps de montrer la marque : l'application ouvre ensuite
    // directement l'espace du compte, ou la connexion sans session.
    Future.delayed(const Duration(milliseconds: 1200), _route);
  }

  /// Le serveur demande-t-il la reconfirmation d'identité ? Jamais bloquant :
  /// hors ligne, serveur muet ou trop lent, on ouvre l'espace du compte.
  Future<ReconfirmationStatus?> _reconfirmation() async {
    if (!ConnectivityService.instance.isOnline) return null;
    // Identité prouvée récemment sur ce téléphone (connexion, code reçu par
    // e-mail, empreinte) : pas de code à redemander. Le serveur, lui, ne
    // connaît que la dernière reconfirmation par code.
    final last = await SessionManager.lastIdentityCheck();
    if (last != null &&
        DateTime.now().toUtc().difference(last) < reconfirmWindow) {
      return null;
    }
    return AuthService.instance
        .reconfirmationStatus()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  Future<void> _route() async {
    try {
      await _ouvrirPremierePage();
    } finally {
      // Un lien reçu au lancement (réinitialisation du mot de passe) s'ouvre
      // par-dessus la première page, une fois celle-ci en place.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => DeepLinks.instance.ready());
    }
  }

  Future<void> _ouvrirPremierePage() async {
    if (!mounted) return;

    final loggedIn = await SessionManager.isLoggedIn();
    if (!mounted) return;

    // Pas de présentation à la manière du site : sans session, on se connecte.
    if (!loggedIn) {
      Navigator.of(context).pushReplacement(
        WinPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Déverrouillage par empreinte choisi : demandé avant tout. Une réussite
    // vaut preuve d'identité ; un refus ou une annulation mène à l'écran
    // verrouillé (réessayer ou se déconnecter).
    if (await BiometricService.instance.isEnabled()) {
      final ok = await BiometricService.instance.authenticate();
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).pushReplacement(
          WinPageRoute(builder: (_) => const AppLockScreen()),
        );
        return;
      }
    }

    final status = await _reconfirmation();
    if (!mounted) return;
    // La session a pu expirer pendant l'appel : main.dart a alors déjà
    // ouvert la connexion.
    if (!await SessionManager.isLoggedIn() || !mounted) return;

    if (status != null && status.required) {
      Navigator.of(context).pushReplacement(
        WinPageRoute(builder: (_) => PeriodicConfirmScreen(status: status)),
      );
      return;
    }

    // Déjà connecté, reconfirmation non requise : l'espace du compte.
    final roleStr = await SessionManager.getUserRole();
    if (!mounted) return;
    WinAppScope.of(context).setRole(winRoleFromString(roleStr));
    Navigator.of(context).pushReplacement(
      WinPageRoute(builder: (_) => const RoleShell()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Vert profond de la marque (surfaces sombres du site), plus de presque noir.
      backgroundColor: WinColors.teal900,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Image.asset('assets/winplus-logo.png', width: 120),
          ),
          const SizedBox(height: 18),
          Text('WinPlus',
              style: WinType.archivo(
                  size: 30, weight: FontWeight.w700, color: WinColors.cream50)),
          const SizedBox(height: 4),
          Text(context.l10n.welcomeTagline,
              style: WinType.bodyS(WinColors.teal200)),
        ]),
      ),
    );
  }
}
