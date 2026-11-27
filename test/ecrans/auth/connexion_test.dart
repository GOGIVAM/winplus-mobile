import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/forgot_password_screen.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/reset_password_screen.dart';
import 'package:winplus/auth/role_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await reseau(tester);
}

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('LoginScreen', () {
    testWidgets('affiche titre, champs, bouton de connexion et lien mot de passe oublie', (tester) async {
      await monterEcran(tester, const LoginScreen());
      final l = L10n.current;
      expect(find.text(l.loginTitle), findsWidgets);
      expect(find.text(l.loginSubtitle), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(_bouton(l.login), findsOneWidget);
      expect(find.text(l.forgotPassword), findsOneWidget);
    });

    testWidgets('champs vides : message « remplir tous les champs » sans appel reseau', (tester) async {
      await monterEcran(tester, const LoginScreen());
      await _toucher(tester, _bouton(L10n.current.login));
      expect(find.text(L10n.current.fillAllFields), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('identifiants refuses : message traduit (pas le texte du serveur) et le bouton redevient actif', (tester) async {
      faux.repond('POST', '/auth/signin', {'error': 'Invalid email or password'}, statut: 401);
      await monterEcran(tester, const LoginScreen());
      await tester.enterText(find.byType(TextField).at(0), '  ada@x.cm ');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await _toucher(tester, _bouton(L10n.current.login));
      expect(find.text(L10n.current.wrongCredentials), findsOneWidget);
      expect(faux.recues('POST', '/auth/signin').single.data, {'email': 'ada@x.cm', 'password': 'secret'});
      expect(tester.widget<WinButton>(_bouton(L10n.current.login)).loading, isFalse);
    });

    testWidgets('l\'oeil du mot de passe bascule l\'affichage', (tester) async {
      await monterEcran(tester, const LoginScreen());
      final champ = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(champ).obscureText, isTrue);
      await tester.tap(find.byIcon(PhosphorIconsRegular.eye));
      await pomper(tester);
      expect(tester.widget<TextField>(champ).obscureText, isFalse);
      expect(find.byIcon(PhosphorIconsRegular.eyeSlash), findsOneWidget);
    });

    testWidgets('« mot de passe oublie » ouvre l\'ecran de recuperation', (tester) async {
      await monterEcran(tester, const LoginScreen());
      await _toucher(tester, find.text(L10n.current.forgotPassword));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('bouton Google sans identifiant client sur le serveur : message « indisponible »', (tester) async {
      faux.repond('GET', '/auth/google/client', {'clientId': null});
      await monterEcran(tester, const LoginScreen());
      await _toucher(tester, find.text(L10n.current.continueWithGoogle));
      expect(faux.recues('GET', '/auth/google/client'), hasLength(1));
      expect(find.text(L10n.current.authGoogleUnavailable), findsOneWidget);
    });

    testWidgets('premier ecran sans session : pas de retour, ni connexion par telephone', (tester) async {
      await monterEcran(tester, const LoginScreen());
      expect(find.byIcon(PhosphorIconsRegular.caretLeft), findsNothing);
      expect(find.text(L10n.current.continueWithPhone), findsNothing);
    });

    testWidgets('« Creer un compte » ouvre le choix du profil par-dessus la connexion', (tester) async {
      await monterEcran(tester, const LoginScreen());
      await _toucher(tester, find.textContaining(L10n.current.createAccount, findRichText: true));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(RoleScreen), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen', () {
    testWidgets('e-mail vide : rien n\'est envoye', (tester) async {
      await monterEcran(tester, const ForgotPasswordScreen());
      await _toucher(tester, _bouton(L10n.current.authSendLink));
      expect(faux.requetes, isEmpty);
      expect(find.text(L10n.current.authForgotTitle), findsOneWidget);
    });

    testWidgets('envoi reussi : confirmation avec l\'adresse, puis retour au formulaire', (tester) async {
      faux.repond('POST', '/auth/forgot-password', {});
      await monterEcran(tester, const ForgotPasswordScreen());
      await tester.enterText(find.byType(TextField), ' ada@x.cm ');
      await _toucher(tester, _bouton(L10n.current.authSendLink));
      expect(faux.recues('POST', '/auth/forgot-password').single.data, {'email': 'ada@x.cm'});
      expect(find.text(L10n.current.authForgotSent('ada@x.cm')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await _toucher(tester, _bouton(L10n.current.authResendEmail));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('echec : message du serveur', (tester) async {
      faux.repond('POST', '/auth/forgot-password', {'error': 'Adresse inconnue'}, statut: 404);
      await monterEcran(tester, const ForgotPasswordScreen());
      await tester.enterText(find.byType(TextField), 'x@x.cm');
      await _toucher(tester, _bouton(L10n.current.authSendLink));
      expect(find.text('Adresse inconnue'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    Future<void> saisir(WidgetTester tester, String a, String b) async {
      await tester.enterText(find.byType(TextField).at(0), a);
      await tester.enterText(find.byType(TextField).at(1), b);
      await pomper(tester);
    }

    testWidgets('les six regles passent au vert avec un mot de passe conforme', (tester) async {
      await monterEcran(tester, const ResetPasswordScreen(token: 't'));
      expect(find.byIcon(PhosphorIconsFill.checkCircle), findsNothing);
      await saisir(tester, 'Abcdef1!', 'Abcdef1!');
      expect(find.byIcon(PhosphorIconsFill.checkCircle), findsNWidgets(6));
    });

    testWidgets('mot de passe « abc » : seules minuscule et confirmation sont validees', (tester) async {
      await monterEcran(tester, const ResetPasswordScreen(token: 't'));
      await saisir(tester, 'abc', 'abc');
      expect(find.byIcon(PhosphorIconsFill.checkCircle), findsNWidgets(2));
    });

    testWidgets('mot de passe invalide : aucun envoi', (tester) async {
      await monterEcran(tester, const ResetPasswordScreen(token: 't'));
      await saisir(tester, 'faible', 'faible');
      await _toucher(tester, _bouton(L10n.current.authReset));
      expect(faux.requetes, isEmpty);
    });

    testWidgets('mot de passe valide : envoi avec le jeton puis confirmation', (tester) async {
      faux.repond('POST', '/auth/reset-password', {});
      await monterEcran(tester, const ResetPasswordScreen(token: 'jeton-42'));
      await saisir(tester, 'Abcdef1!', 'Abcdef1!');
      await _toucher(tester, _bouton(L10n.current.authReset));
      expect(faux.requetes.single.data, {'resetToken': 'jeton-42', 'token': 'jeton-42', 'newPassword': 'Abcdef1!'});
      expect(find.text(L10n.current.authPwdUpdated), findsOneWidget);
      expect(_bouton(L10n.current.authGoToLogin), findsOneWidget);
    });

    testWidgets('erreur du serveur affichee', (tester) async {
      faux.repond('POST', '/auth/reset-password', {'error': 'Lien expire'}, statut: 400);
      await monterEcran(tester, const ResetPasswordScreen(token: 't'));
      await saisir(tester, 'Abcdef1!', 'Abcdef1!');
      await _toucher(tester, _bouton(L10n.current.authReset));
      expect(find.text('Lien expire'), findsOneWidget);
    });
  });

  group('RoleScreen', () {
    testWidgets('quatre profils, « Continuer » inactif tant qu\'aucun n\'est choisi', (tester) async {
      await monterEcran(tester, const RoleScreen());
      final l = L10n.current;
      for (final t in [l.authRoleStudentLabel, l.authRoleParentLabel, l.authRoleTeacherLabel, l.authRoleInstitutionLabel]) {
        expect(find.text(t), findsOneWidget);
      }
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNull);
    });

    testWidgets('choisir un profil active « Continuer » qui ouvre l\'inscription', (tester) async {
      await monterEcran(tester, const RoleScreen());
      await tester.tap(find.text(L10n.current.authRoleParentLabel));
      await pomper(tester);
      expect(tester.widget<WinButton>(_bouton(L10n.current.commonContinue)).onTap, isNotNull);
      await _toucher(tester, _bouton(L10n.current.commonContinue));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(L10n.current.authCreateMyAccount), findsOneWidget);
    });

    testWidgets('apres Google (compte inconnu) : le profil choisi est envoye avec le jeton, refus = message', (tester) async {
      faux.repond('POST', '/auth/google', {'error': 'Compte desactive'}, statut: 400);
      await monterEcran(tester, const RoleScreen(googleIdToken: 'jeton-google'));
      final l = L10n.current;
      expect(find.text(l.authGoogleChooseProfile), findsOneWidget);
      await tester.tap(find.text(l.authRoleParentLabel));
      await pomper(tester);
      await _toucher(tester, _bouton(l.commonContinue));
      final envoi = faux.recues('POST', '/auth/google').single.data as Map;
      expect(envoi['idToken'], 'jeton-google');
      expect(envoi['role'], 'parent');
      expect(find.text('Compte desactive'), findsOneWidget);
      // Pas de formulaire d'inscription : le compte se cree avec Google.
      expect(find.text(l.authCreateMyAccount), findsNothing);
    });
  });
}
