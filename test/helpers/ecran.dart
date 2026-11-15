import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/subscription/subscription_notifier.dart';
import 'package:winplus/theme/win_theme.dart';

import 'faux_reseau.dart';

/// Monte un ECRAN complet (pas centre dans un Scaffold comme `appli`) : il est
/// la page d'accueil d'un MaterialApp, avec un Navigator pour tester les
/// ouvertures de pages, l'etat global, le schema de couleurs et l'etat
/// d'abonnement fournis au-dessus du Navigator (comme dans main.dart).
Widget ecran(
  Widget enfant, {
  WinAppState? etat,
  SubscriptionNotifier? abonnement,
  WinScheme schema = WinScheme.light,
  List<NavigatorObserver> observateurs = const [],
}) {
  return WinAppScope(
    notifier: etat ?? WinAppState(),
    child: SubscriptionScope(
      notifier: abonnement ?? SubscriptionNotifier(),
      child: WinTheme(
        scheme: schema,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          navigatorObservers: observateurs,
          home: enfant,
        ),
      ),
    ),
  );
}

/// Fixe la taille de l'ecran de test a celle d'un telephone (400 x 800 points)
/// et la restaure a la fin du test.
void telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Laisse se terminer les appels reseau simules : le faux reseau et les
/// preferences de test ne reposent que sur des micro-taches, que chaque
/// `pump` execute dans le temps simule de flutter_test.
Future<void> reseau(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await pomper(tester, const Duration(milliseconds: 50));
  }
}

/// Monte [enfant] comme ecran de telephone puis laisse finir le premier
/// chargement reseau.
Future<void> monterEcran(
  WidgetTester tester,
  Widget enfant, {
  WinAppState? etat,
  SubscriptionNotifier? abonnement,
  WinScheme schema = WinScheme.light,
  List<NavigatorObserver> observateurs = const [],
}) async {
  telephone(tester);
  await monter(tester, ecran(enfant, etat: etat, abonnement: abonnement, schema: schema, observateurs: observateurs));
  await reseau(tester);
}

/// Observateur qui memorise les pages poussees et retirees.
class ObservateurPages extends NavigatorObserver {
  int poussees = 0;
  int retirees = 0;
  int remplacees = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => poussees++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => retirees++;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => remplacees++;
}

/// Etat d'abonnement charge depuis un faux GET /subscriptions/me qui porte les
/// droits [droits] (ex. {'favorites.max': 20}). Doit etre appele avant
/// [monterEcran] pour que l'ecran lise les droits des son premier rendu.
Future<SubscriptionNotifier> abonnementAvecDroits(
  WidgetTester tester,
  FauxReseau faux,
  Map<String, dynamic> droits, {
  String plan = 'Premium',
  bool hasPlan = true,
}) async {
  faux.repond('GET', '/subscriptions/me', {
    'id': 1,
    'hasPlan': hasPlan,
    'pricingPlanId': 2,
    'planName': plan,
    'status': 'active',
    'entitlements': {'audience': 'student', 'aiMultiplier': 1, 'entitlements': droits},
  });
  final n = SubscriptionNotifier();
  await tester.runAsync(n.loadFromApi);
  return n;
}

/// Page d'accueil factice avec un bouton « ouvrir » qui pousse [cible] : permet
/// de tester les ecrans qui se ferment eux-memes (Navigator.pop) sans fermer
/// la route racine.
Widget lanceur(Widget cible, {Object? Function(Object?)? surResultat}) => Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(c).push(MaterialPageRoute<Object?>(builder: (_) => cible)).then((r) => surResultat?.call(r)),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );

/// Ouvre la page poussee par [lanceur] et laisse finir la transition et les
/// premiers appels reseau.
Future<void> ouvrir(WidgetTester tester) async {
  await tester.tap(find.text('ouvrir'));
  await pomper(tester, const Duration(milliseconds: 400));
  await reseau(tester);
}
