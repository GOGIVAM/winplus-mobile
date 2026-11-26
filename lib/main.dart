import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_config.dart';
import 'app_state.dart';
import 'l10n/gen/app_localizations.dart';
import 'theme/win_theme.dart';
import 'auth/login_screen.dart';
import 'auth/splash_screen.dart';
import 'l10n/l10n.dart';
import 'services/api_client.dart';
import 'services/background_notifications.dart';
import 'theme/win_motion.dart';
import 'shared/subscription/subscription_notifier.dart';
import 'services/connectivity_service.dart';
import 'services/local_cache_service.dart';
import 'services/deep_links.dart';
import 'services/local_downloads_service.dart';
import 'services/messaging_service.dart';
import 'services/outbox_service.dart';
import 'services/quiz_service.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Polices embarquées (assets/google_fonts) : jamais de téléchargement, ce
  // qui échouait hors ligne et laissait une police de secours.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Lot 10.11 : données de dates fr/en pour WinFormat (intl.DateFormat).
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');

  // Fondation hors ligne (brique 1/2/3) : stockage structuré, détection
  // réseau, file d'attente  dans cet ordre, chacun dépendant du précédent.
  await LocalCacheService.init();
  await ConnectivityService.instance.start();
  await OutboxService.instance.init();
  QuizService.registerOutboxHandler();
  MessagingService.registerOutboxHandler();
  // Au cas où l'app démarre déjà en ligne avec des actions en attente d'un
  // précédent passage hors ligne.
  unawaited(OutboxService.instance.flush());
  // Module 44 : épreuves, corrigés et livres ne sont plus téléchargeables ;
  // on efface les copies en clair laissées par les versions précédentes.
  unawaited(LocalDownloadsService.instance.purgeLegacyCatalogFiles());
  // Notifications application fermée (Android) : canal avec le service
  // d'écoute et tâche périodique de secours.
  await BackgroundNotifications.initMainIsolate();

  runApp(const WinPlusApp());
}

class WinPlusApp extends StatefulWidget {
  const WinPlusApp({super.key});
  @override
  State<WinPlusApp> createState() => _WinPlusAppState();
}

class _WinPlusAppState extends State<WinPlusApp>
    with WidgetsBindingObserver {
  final WinAppState _state = WinAppState();
  final SubscriptionNotifier _sub = SubscriptionNotifier();

  /// Navigateur racine : permet de quitter n'importe quel écran quand la
  /// session expire.
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub.loadFromApi();
    _state.loadLocale();
    // Mode clair ou sombre : le choix enregistré, sinon celui du téléphone.
    _state.loadTheme();
    // Liens du site ouverts dans l'application (réinitialisation du mot de
    // passe reçue par e-mail).
    DeepLinks.instance.start(_navigator);
    // Session perdue (renouvellement refusé par le serveur) : retour à la
    // connexion avec un message, plutôt qu'un écran resté en erreur.
    ApiClient.instance.onSessionExpired = () {
      _navigator.currentState?.pushAndRemoveUntil(
        WinPageRoute(
            builder: (_) =>
                LoginScreen(notice: L10n.current.authSessionExpired)),
        (r) => false,
      );
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Le téléphone passe en clair ou en sombre : l'application suit, sauf si
  /// un choix a été fait dans ses réglages.
  @override
  void didChangePlatformBrightness() => _state.systemThemeChanged();

  @override
  Widget build(BuildContext context) {
    return WinAppScope(
      notifier: _state,
      child: SubscriptionScope(
        notifier: _sub,
        child: AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            final scheme = _state.dark ? WinScheme.dark_ : WinScheme.light;
            return WinTheme(
              scheme: scheme,
              child: MaterialApp(
                navigatorKey: _navigator,
                title: 'WinPlus',
                debugShowCheckedModeBanner: false,
                theme: winMaterialTheme(scheme),
                locale: _state.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SplashScreen(),
                // Version d'intégration : ruban en coin sur tous les écrans,
                // pour ne jamais la confondre avec la production (comme le
                // bandeau du site d'intégration).
                builder: AppConfig.isIntegration
                    ? (context, child) => Banner(
                          message: context.l10n.integrationRibbon,
                          location: BannerLocation.topStart,
                          color: const Color(0xFFE67E22),
                          child: child ?? const SizedBox.shrink(),
                        )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
