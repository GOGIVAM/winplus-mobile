import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/two_factor_login_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/auth_service.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await reseau(tester);
  await pomper(tester, const Duration(milliseconds: 400));
}

const _session = {
  'accessToken': 'acc',
  'refreshToken': 'ref',
  'user': {'id': 9, 'email': 'ada@x.cm', 'role': 'student', 'firstName': 'Ada', 'lastName': 'Eto'},
};

/// Double authentification a la connexion (contrat de winplus-api 2a006d2) :
/// signin renvoie { requiresTwoFactor, twoFactorToken } sans session, puis
/// POST /auth/2fa/verify-login { twoFactorToken, code } ouvre la session.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('AuthService', () {
    test('signin avec la 2FA active : pas de session, jeton du second facteur', () async {
      faux.repond('POST', '/auth/signin', {'requiresTwoFactor': true, 'twoFactorToken': 'tf1', 'expiresIn': 300, 'message': 'Code requis'});
      final r = await AuthService.instance.signIn('ada@x.cm', 'secret');
      expect(r.success, isFalse);
      expect(r.needsTwoFactor, isTrue);
      expect(r.twoFactorToken, 'tf1');
      expect(await SessionManager.getUserRole(), isNot('student'));
    });

    test('verify-login : succes ouvre la session ; code faux, jeton expire et blocage lus', () async {
      faux.repond('POST', '/auth/2fa/verify-login', _session);
      final ok = await AuthService.instance.verifyTwoFactorLogin('tf1', ' 123456 ');
      expect(ok.success, isTrue);
      expect(faux.recues('POST', '/auth/2fa/verify-login').single.data, {'twoFactorToken': 'tf1', 'code': '123456'});
      expect(await SessionManager.getUserRole(), 'student');

      faux.repond('POST', '/auth/2fa/verify-login',
          {'success': false, 'code': 'code_invalide', 'errorCode': 'TWO_FACTOR_INVALID', 'attemptsLeft': 3, 'message': 'Code incorrect.'},
          statut: 401);
      final faux1 = await AuthService.instance.verifyTwoFactorLogin('tf1', '000000');
      expect(faux1.success, isFalse);
      expect(faux1.message, 'Code incorrect.');
      expect(faux1.attemptsLeft, 3);
      expect(faux1.twoFactorRestart, isFalse);

      faux.repond('POST', '/auth/2fa/verify-login',
          {'success': false, 'errorCode': 'TWO_FACTOR_EXPIRED', 'message': 'Jeton expire.'}, statut: 401);
      expect((await AuthService.instance.verifyTwoFactorLogin('tf1', '000000')).twoFactorRestart, isTrue);
      faux.repond('POST', '/auth/2fa/verify-login',
          {'success': false, 'errorCode': 'TWO_FACTOR_LOCKED', 'message': 'Trop d essais.'}, statut: 401);
      expect((await AuthService.instance.verifyTwoFactorLogin('tf1', '000000')).twoFactorRestart, isTrue);
    });

    test('Google avec la 2FA active : jeton du second facteur, pas de session', () async {
      faux.repond('POST', '/auth/google', {'requiresTwoFactor': true, 'twoFactorToken': 'tfg'});
      final r = await AuthService.instance.googleSignIn('id-token');
      expect(r.success, isFalse);
      expect(r.twoFactorToken, 'tfg');
    });
  });

  group('Ecrans', () {
    testWidgets('connexion avec la 2FA : ecran du code ; code faux affiche le message et les essais restants', (tester) async {
      faux.repond('POST', '/auth/signin', {'requiresTwoFactor': true, 'twoFactorToken': 'tf1'});
      faux.repond('POST', '/auth/2fa/verify-login',
          {'success': false, 'errorCode': 'TWO_FACTOR_INVALID', 'attemptsLeft': 2, 'message': 'Code incorrect.'},
          statut: 401);
      await monterEcran(tester, const LoginScreen());
      await tester.enterText(find.byType(TextField).at(0), 'ada@x.cm');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await _toucher(tester, _bouton(L10n.current.login));
      final l = L10n.current;
      expect(find.byType(TwoFactorLoginScreen), findsOneWidget);
      expect(find.text(l.authTwoFactorTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '111111');
      await _toucher(tester, _bouton(l.authTwoFactorVerify));
      expect(find.text('Code incorrect. ${l.authTwoFactorAttemptsLeft(2)}'), findsOneWidget);
      expect(find.byType(TwoFactorLoginScreen), findsOneWidget);
    });

    testWidgets('jeton expire : retour a la connexion avec le message du serveur', (tester) async {
      faux.repond('POST', '/auth/signin', {'requiresTwoFactor': true, 'twoFactorToken': 'tf1'});
      faux.repond('POST', '/auth/2fa/verify-login',
          {'success': false, 'errorCode': 'TWO_FACTOR_EXPIRED', 'message': 'Delai depasse, reconnectez-vous.'},
          statut: 401);
      await monterEcran(tester, const LoginScreen());
      await tester.enterText(find.byType(TextField).at(0), 'ada@x.cm');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await _toucher(tester, _bouton(L10n.current.login));
      await tester.enterText(find.byType(TextField).last, '111111');
      await _toucher(tester, _bouton(L10n.current.authTwoFactorVerify));
      expect(find.byType(TwoFactorLoginScreen), findsNothing);
      expect(find.text('Delai depasse, reconnectez-vous.'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.login)).loading, isFalse);
    });

    testWidgets('code vide : message sans appel au serveur', (tester) async {
      await monterEcran(tester, const TwoFactorLoginScreen(twoFactorToken: 'tf1'));
      await _toucher(tester, _bouton(L10n.current.authTwoFactorVerify));
      expect(find.text(L10n.current.authTwoFactorInvalid), findsOneWidget);
      expect(faux.recues('POST', '/auth/2fa/verify-login'), isEmpty);
    });
  });
}
