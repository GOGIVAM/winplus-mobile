import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/splash_screen.dart';
import 'package:winplus/services/connectivity_service.dart';
import 'package:winplus/shell/role_shell.dart';
import 'package:winplus/student/student_home.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// Critere de fin du lot 3 : en mode avion, avec une session ouverte,
/// l'application demarre sur l'espace du compte et les ecrans affichent
/// leurs dernieres donnees, sans erreur technique.
void main() {
  late FauxReseau faux;
  const session = {'access_token': 'jeton', 'refresh_token': 'r', 'user_id': 1, 'user_role': 'student'};

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement(prefs: session);
    ConnectivityService.instance.debugSetOnline(true);
  });
  tearDown(() => ConnectivityService.instance.debugSetOnline(true));

  void routesAccueil() {
    faux.repond('GET', '/users/me', {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto'});
    faux.repond('GET', '/student/stats', {'data': {'averageScore': 74.4, 'weeklyQuizCompleted': 5}});
    faux.repond('GET', '/student/learning/continue', {'data': []});
    faux.repond('GET', '/student/events/upcoming', {'data': []});
    faux.repond('GET', '/users/profile/statistics', {'currentStreak': 4});
    faux.repond('GET', '/badges', {'data': []});
  }

  void toutCouper() {
    for (final r in ['/users/me', '/student/stats', '/student/learning/continue', '/student/events/upcoming', '/users/profile/statistics', '/badges']) {
      faux.coupure('GET', r);
    }
  }

  testWidgets('mode avion au demarrage : l\'espace du compte s\'ouvre, pas la connexion', (tester) async {
    ConnectivityService.instance.debugSetOnline(false);
    await monterEcran(tester, const SplashScreen());
    await pomper(tester, const Duration(milliseconds: 1300));
    await reseau(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 500));
    expect(find.byType(RoleShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(faux.recues('GET', '/auth/reconfirmation-status'), isEmpty, reason: 'aucune attente du serveur hors ligne');
    await monter(tester, const SizedBox());
    await pomper(tester, const Duration(seconds: 3));
  });

  testWidgets('accueil deja vu, puis mode avion : memes chiffres, aucune erreur', (tester) async {
    routesAccueil();
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const StudentHomeTab()));
    await reseau(tester);
    expect(find.text('14,9/20'), findsOneWidget);

    await monter(tester, const SizedBox());
    ConnectivityService.instance.debugSetOnline(false);
    toutCouper();
    await monter(tester, ecran(const StudentHomeTab()));
    await reseau(tester);
    expect(find.text('14,9/20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('serveur injoignable avec le reseau : la derniere version s\'affiche aussi', (tester) async {
    routesAccueil();
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const StudentHomeTab()));
    await reseau(tester);
    await monter(tester, const SizedBox());
    toutCouper();
    await monter(tester, ecran(const StudentHomeTab()));
    await reseau(tester);
    expect(find.text('14,9/20'), findsOneWidget);
  });
}
