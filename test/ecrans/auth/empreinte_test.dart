import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/auth/app_lock_screen.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/periodic_confirm_screen.dart';
import 'package:winplus/auth/splash_screen.dart';
import 'package:winplus/services/biometric_service.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/shell/role_shell.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Reconfirmation d'identite et deverrouillage par empreinte : plus de code
/// par e-mail juste apres une connexion ; l'empreinte, si elle est choisie,
/// ouvre l'application et compte comme preuve d'identite.
void main() {
  late FauxReseau faux;
  const reconfirmationDemandee = {
    'data': {'required': true, 'daysSinceLastConfirm': 40, 'windowDays': 35, 'maskedEmail': 'a***@x.cm'},
    'success': true,
  };

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Future<void> sessionOuverte({bool identiteRecente = false}) async {
    await SessionManager.save(accessToken: 'jeton', refreshToken: 'r', userId: 1, email: 'a@x.cm', role: 'student', name: 'Ada');
    if (!identiteRecente) {
      // Session reprise d'une version precedente : aucune preuve recente.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_identity_check');
    }
  }

  Future<void> lancer(WidgetTester tester) async {
    await monterEcran(tester, const SplashScreen());
    await pomper(tester, const Duration(milliseconds: 1300));
    await reseau(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 500));
  }

  Future<void> demonter(WidgetTester tester) async {
    await monter(tester, const SizedBox());
    await pomper(tester, const Duration(seconds: 3));
  }

  testWidgets('juste apres une connexion : pas de code demande, meme si le serveur le reclame', (tester) async {
    await tester.runAsync(() => sessionOuverte(identiteRecente: true));
    faux.repond('GET', '/auth/reconfirmation-status', reconfirmationDemandee);
    await lancer(tester);
    expect(find.byType(PeriodicConfirmScreen), findsNothing);
    expect(find.byType(RoleShell), findsOneWidget);
    expect(faux.recues('GET', '/auth/reconfirmation-status'), isEmpty);
    await demonter(tester);
  });

  testWidgets('aucune preuve recente sur ce telephone : le code par e-mail reste demande', (tester) async {
    await tester.runAsync(() => sessionOuverte());
    faux.repond('GET', '/auth/reconfirmation-status', reconfirmationDemandee);
    await lancer(tester);
    expect(find.byType(PeriodicConfirmScreen), findsOneWidget);
  });

  testWidgets('empreinte activee et reussie : l\'espace s\'ouvre, sans code par e-mail', (tester) async {
    await tester.runAsync(() async {
      await sessionOuverte();
      await BiometricService.instance.setEnabled(true);
    });
    BiometricService.instance.debugAuthenticate = () async => true;
    faux.repond('GET', '/auth/reconfirmation-status', reconfirmationDemandee);
    await lancer(tester);
    expect(find.byType(RoleShell), findsOneWidget);
    expect(find.byType(PeriodicConfirmScreen), findsNothing);
    await demonter(tester);
  });

  testWidgets('empreinte annulee : ecran verrouille ; « me deconnecter » ramene a la connexion', (tester) async {
    await tester.runAsync(() async {
      await sessionOuverte(identiteRecente: true);
      await BiometricService.instance.setEnabled(true);
    });
    BiometricService.instance.debugAuthenticate = () async => false;
    faux.repond('POST', '/auth/logout', {});
    await lancer(tester);
    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.byType(RoleShell), findsNothing);
    await tester.tap(find.byType(TextButton));
    // La deconnexion efface aussi le stockage local : laisse-la finir en
    // temps reel, puis les images de la navigation.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await reseau(tester);
    }
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('ecran verrouille : une empreinte reussie ouvre l\'espace', (tester) async {
    await tester.runAsync(() async {
      await sessionOuverte(identiteRecente: true);
      await BiometricService.instance.setEnabled(true);
    });
    var essais = 0;
    BiometricService.instance.debugAuthenticate = () async => ++essais > 1;
    await lancer(tester);
    expect(find.byType(AppLockScreen), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.fingerprint).last);
    await reseau(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 500));
    expect(find.byType(RoleShell), findsOneWidget);
    await demonter(tester);
  });

  test('la deconnexion oublie l\'empreinte et la proposition', () async {
    await BiometricService.instance.setEnabled(true);
    await SessionManager.clear();
    expect(await BiometricService.instance.isEnabled(), isFalse);
  });
}
