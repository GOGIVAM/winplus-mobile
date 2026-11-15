import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/periodic_confirm_screen.dart';
import 'package:winplus/auth/signup_screen.dart';
import 'package:winplus/auth/verify_code_screen.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/auth_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  // Comme une personne qui ferme le clavier : les poignees de selection du
  // dernier champ saisi ne recouvrent plus le bouton.
  FocusManager.instance.primaryFocus?.unfocus();
  await pomper(tester);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await reseau(tester);
}

Future<void> _remplir(WidgetTester tester,
    {String prenom = 'Ada', String nom = 'Eto', String email = 'ada@x.cm', String tel = '', String mdp = 'Abcdef1!', String confirme = 'Abcdef1!'}) async {
  final champs = find.byType(TextField);
  await tester.enterText(champs.at(0), prenom);
  await tester.enterText(champs.at(1), nom);
  await tester.enterText(champs.at(2), email);
  await tester.enterText(champs.at(3), tel);
  await tester.enterText(champs.at(4), mdp);
  await tester.enterText(champs.at(5), confirme);
  await pomper(tester);
}

/// Retire l'ecran de l'arbre : arrete les minuteurs qu'il avait lances.
Future<void> _demonter(WidgetTester tester) async {
  await monter(tester, const SizedBox());
}

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('SignupScreen', () {
    testWidgets('champs obligatoires vides : message et aucun envoi', (tester) async {
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect(find.text(L10n.current.authFillRequired), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('mot de passe trop faible : criteres rappeles', (tester) async {
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester, mdp: 'faible', confirme: 'faible');
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect(find.text(L10n.current.authPwdCriteria), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('confirmation differente : criteres rappeles', (tester) async {
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester, confirme: 'Autre123!');
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect(find.text(L10n.current.authPwdCriteria), findsOneWidget);
    });

    testWidgets('telephone camerounais incomplet refuse', (tester) async {
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester, tel: '6712345');
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect(find.text(L10n.current.authPhoneInvalid), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('inscription reussie : role, noms et telephone nettoye envoyes, puis verification du code', (tester) async {
      faux.repond('POST', '/auth/signup', {});
      await monterEcran(tester, const SignupScreen(role: WinRole.teacher));
      await _remplir(tester, tel: '671 23 45 67');
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      final d = faux.recues('POST', '/auth/signup').single.data as Map;
      expect(d['email'], 'ada@x.cm');
      expect(d['firstName'], 'Ada');
      expect(d['lastName'], 'Eto');
      expect(d['role'], 'teacher');
      expect(d['phone'], '671234567', reason: 'les espaces sont retires');
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(VerifyCodeScreen), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('numero international : garde le « + » et accepte 10 chiffres ou plus', (tester) async {
      faux.repond('POST', '/auth/signup', {});
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester, tel: '+33 6 12 34 56 78');
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect((faux.requetes.single.data as Map)['phone'], '+33612345678');
      await pomper(tester, const Duration(milliseconds: 400));
      await _demonter(tester);
    });

    testWidgets('sans telephone : le champ n\'est pas envoye', (tester) async {
      faux.repond('POST', '/auth/signup', {});
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester);
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect((faux.requetes.single.data as Map).containsKey('phone'), isFalse);
      await pomper(tester, const Duration(milliseconds: 400));
      await _demonter(tester);
    });

    testWidgets('refus du serveur : son message est affiche', (tester) async {
      faux.repond('POST', '/auth/signup', {'error': 'E-mail deja utilise'}, statut: 409);
      await monterEcran(tester, const SignupScreen(role: WinRole.student));
      await _remplir(tester);
      await _toucher(tester, _bouton(L10n.current.authCreateMyAccount));
      expect(find.text('E-mail deja utilise'), findsOneWidget);
      expect(find.byType(VerifyCodeScreen), findsNothing);
    });
  });

  group('VerifyCodeScreen', () {
    Future<void> saisirCode(WidgetTester tester, String code) async {
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(find.byType(TextField).at(i), code[i]);
      }
      await pomper(tester);
    }

    testWidgets('affiche l\'adresse, six cases et un bouton inactif', (tester) async {
      await monterEcran(tester, const VerifyCodeScreen(email: 'ada@x.cm'));
      expect(find.text('ada@x.cm'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(tester.widget<WinButton>(_bouton(L10n.current.authVerify)).onTap, isNull);
      await _demonter(tester);
    });

    testWidgets('compte a rebours de renvoi : 60 s puis lien actif', (tester) async {
      await monterEcran(tester, const VerifyCodeScreen(email: 'ada@x.cm'));
      expect(find.text(L10n.current.authResendCodeParen(60)), findsOneWidget);
      await pomper(tester, const Duration(seconds: 1));
      expect(find.text(L10n.current.authResendCodeParen(59)), findsOneWidget);
      for (var i = 0; i < 60; i++) {
        await pomper(tester, const Duration(seconds: 1));
      }
      expect(find.text(L10n.current.authResendCode), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('code complet refuse : message du serveur', (tester) async {
      faux.repond('POST', '/auth/verify-email', {'error': 'Code expire'}, statut: 400);
      await monterEcran(tester, const VerifyCodeScreen(email: 'ada@x.cm'));
      await saisirCode(tester, '123456');
      expect(tester.widget<WinButton>(_bouton(L10n.current.authVerify)).onTap, isNotNull);
      await _toucher(tester, _bouton(L10n.current.authVerify));
      expect(faux.requetes.single.data, {'email': 'ada@x.cm', 'code': '123456'});
      expect(find.text('Code expire'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('code accepte : l\'ecran de succes remplace la verification', (tester) async {
      faux.repond('POST', '/auth/verify-email', {});
      await monterEcran(tester, const VerifyCodeScreen(email: 'ada@x.cm'));
      await saisirCode(tester, '654321');
      await _toucher(tester, _bouton(L10n.current.authVerify));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(VerifyCodeScreen), findsNothing);
      await _demonter(tester);
    });

    testWidgets('renvoyer le code relance le compte a rebours et appelle le serveur', (tester) async {
      faux.repond('POST', '/auth/resend-verification', {});
      await monterEcran(tester, const VerifyCodeScreen(email: 'ada@x.cm'));
      for (var i = 0; i < 61; i++) {
        await pomper(tester, const Duration(seconds: 1));
      }
      await tester.tap(find.text(L10n.current.authResendCode));
      await reseau(tester);
      expect(faux.recues('POST', '/auth/resend-verification').single.data, {'email': 'ada@x.cm'});
      expect(find.text(L10n.current.authResendCodeParen(60)), findsOneWidget);
      await _demonter(tester);
    });
  });

  group('PeriodicConfirmScreen', () {
    const statut = ReconfirmationStatus(required: true, windowDays: 35, maskedEmail: 'a***@x.cm');

    testWidgets('adresse masquee du serveur, fenetre de 35 jours, aucune case avant l\'envoi', (tester) async {
      await monterEcran(tester, const PeriodicConfirmScreen(status: statut));
      expect(find.text('a***@x.cm'), findsOneWidget);
      expect(find.text(L10n.current.authVerifyItsYou), findsOneWidget);
      expect(find.text(L10n.current.authPeriodicIntro(35)), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await _demonter(tester);
    });

    testWidgets('envoi refuse par le serveur : son message, pas de cases', (tester) async {
      faux.repond('POST', '/auth/send-confirmation-code', {'error': 'Trop de demandes'}, statut: 429);
      await monterEcran(tester, const PeriodicConfirmScreen(status: statut));
      await _toucher(tester, _bouton(L10n.current.authSendCode));
      expect(find.text('Trop de demandes'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await _demonter(tester);
    });

    testWidgets('code envoye par le serveur ; un mauvais code affiche le message du serveur', (tester) async {
      faux.repond('POST', '/auth/send-confirmation-code', {'message': 'ok'});
      faux.repond('POST', '/auth/verify-confirmation', {'error': 'Code invalide'}, statut: 400);
      await monterEcran(tester, const PeriodicConfirmScreen(status: statut));
      await _toucher(tester, _bouton(L10n.current.authSendCode));
      expect(faux.recues('POST', '/auth/send-confirmation-code'), hasLength(1));
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text(L10n.current.authCodeSentEmail), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
      }
      await reseau(tester);
      expect(faux.recues('POST', '/auth/verify-confirmation').single.data, {'code': '123456'});
      expect(find.text('Code invalide'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('« me deconnecter » quitte l\'ecran', (tester) async {
      await monterEcran(tester, const PeriodicConfirmScreen(status: statut));
      await _toucher(tester, find.text(L10n.current.authLogMeOut));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(PeriodicConfirmScreen), findsNothing);
      await _demonter(tester);
    });
  });
}
