import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/learning_style_quiz_screen.dart';
import 'package:winplus/student/profile_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);
Finder _onglet(String libelle) => find.widgetWithText(Tab, libelle);

Future<void> _versOnglet(WidgetTester tester, String libelle) async {
  // La barre d'onglets defile : l'onglet voulu peut etre hors de l'ecran.
  await tester.ensureVisible(_onglet(libelle));
  await pomper(tester);
  await tester.tap(_onglet(libelle));
  await pomper(tester);
  await pomper(tester, const Duration(milliseconds: 500));
}

Future<void> _defiler(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).last);

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    faux.repond('GET', '/users/me', {'id': 1, 'email': 'ada@x.cm', 'firstName': 'Ada', 'lastName': 'Eto Mba', 'phone': '670000000', 'level': 'Terminale'});
    faux.repond('GET', '/subscriptions/me', {'id': 1, 'hasPlan': false, 'planName': 'Gratuit'});
  });

  group('Onglet profil', () {
    testWidgets('formulaire prerempli depuis le serveur', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      final champs = tester.widgetList<TextField>(find.byType(TextField)).map((t) => t.controller!.text).toList();
      expect(champs, ['Ada Eto Mba', 'ada@x.cm', '670000000', 'Terminale']);
      for (final t in [L10n.current.studentProfileTabSecurity, L10n.current.studentProfileTabPrivacy, L10n.current.studentHubAccount]) {
        expect(_onglet(t), findsOneWidget);
      }
    });

    testWidgets('enregistrer : prenom et nom separes sur le premier espace, message de succes', (tester) async {
      faux.repond('PUT', '/users/profile', {});
      await monterEcran(tester, const ProfileScreen());
      await tester.ensureVisible(_bouton(L10n.current.studentProfileSaveChanges));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.studentProfileSaveChanges));
      await reseau(tester);
      expect(faux.recues('PUT', '/users/profile').single.data, {'firstName': 'Ada', 'lastName': 'Eto Mba', 'phone': '670000000', 'level': 'Terminale'});
      expect(find.text(L10n.current.studentProfileUpdated), findsOneWidget);
    });

    testWidgets('echec d\'enregistrement : message d\'erreur', (tester) async {
      faux.repond('PUT', '/users/profile', {}, statut: 500);
      await monterEcran(tester, const ProfileScreen());
      await tester.ensureVisible(_bouton(L10n.current.studentProfileSaveChanges));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.studentProfileSaveChanges));
      await reseau(tester);
      expect(find.text(L10n.current.studentProfileUpdateError), findsOneWidget);
    });

    testWidgets('« style d\'apprentissage » ouvre le questionnaire', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      final b = _bouton(L10n.current.studentProfileLearningStyle);
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(LearningStyleQuizScreen), findsOneWidget);
    });
  });

  group('Onglet securite', () {
    testWidgets('adresse actuelle, puis formulaire de changement et annulation', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      final l = L10n.current;
      expect(find.text(l.studentProfileEmailCurrent('ada@x.cm')), findsOneWidget);
      await tester.tap(find.text(l.studentProfileChange));
      await pomper(tester);
      expect(find.text(l.studentProfileNewEmailAddress), findsOneWidget);
      await tester.tap(_bouton(l.commonCancel));
      await pomper(tester);
      expect(find.text(l.studentProfileEmailCurrent('ada@x.cm')), findsOneWidget);
    });

    testWidgets('nouvelle adresse invalide ou identique : messages et aucun envoi', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      await tester.tap(find.text(L10n.current.studentProfileChange));
      await pomper(tester);
      await tester.enterText(find.byType(TextField).first, 'pas-une-adresse');
      await tester.tap(_bouton(L10n.current.studentProfileGetCode));
      await reseau(tester);
      expect(find.text(L10n.current.studentProfileEmailInvalid), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'ADA@x.cm');
      await tester.tap(_bouton(L10n.current.studentProfileGetCode));
      await reseau(tester);
      expect(find.text(L10n.current.studentProfileEmailSame), findsOneWidget);
      expect(faux.recues('POST', '/users/change-email'), isEmpty);
    });

    testWidgets('changement d\'adresse : demande, code trop court refuse, confirmation met a jour l\'adresse affichee', (tester) async {
      faux.repond('POST', '/users/change-email', {});
      faux.repond('POST', '/users/confirm-email-change', {'newEmail': 'neuf@x.cm'});
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      final l = L10n.current;
      await tester.tap(find.text(l.studentProfileChange));
      await pomper(tester);
      await tester.enterText(find.byType(TextField).first, 'neuf@x.cm');
      await tester.tap(_bouton(l.studentProfileGetCode));
      await reseau(tester);
      expect(faux.recues('POST', '/users/change-email').single.data, {'newEmail': 'neuf@x.cm'});
      expect(find.text(l.studentProfileCodeSent('neuf@x.cm')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.tap(_bouton(l.commonConfirm));
      await reseau(tester);
      expect(find.text(l.studentProfileEnterCode), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(_bouton(l.commonConfirm));
      await reseau(tester);
      expect(faux.recues('POST', '/users/confirm-email-change').single.data, {'verificationCode': '123456'});
      expect(find.text(l.studentProfileEmailCurrent('neuf@x.cm')), findsOneWidget);
    });

    testWidgets('demande refusee : message du serveur', (tester) async {
      faux.repond('POST', '/users/change-email', {'error': 'Email already in use'}, statut: 409);
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      await tester.tap(find.text(L10n.current.studentProfileChange));
      await pomper(tester);
      await tester.enterText(find.byType(TextField).first, 'pris@x.cm');
      await tester.tap(_bouton(L10n.current.studentProfileGetCode));
      await reseau(tester);
      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('mot de passe : champs vides, confirmation differente, ancien mot de passe faux, succes', (tester) async {
      faux.repond('POST', '/auth/change-password', {});
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      final l = L10n.current;
      final bouton = find.widgetWithText(WinButton, l.studentProfileChangePwd);
      await _defiler(tester, bouton);
      await tester.tap(bouton);
      await reseau(tester);
      expect(find.text(l.fillAllFields), findsOneWidget);
      final champs = find.byType(TextField);
      final n = tester.widgetList(champs).length;
      await tester.enterText(champs.at(n - 3), 'ancien');
      await tester.enterText(champs.at(n - 2), 'Nouveau1!');
      await tester.enterText(champs.at(n - 1), 'Autre1!');
      await tester.tap(bouton);
      await reseau(tester);
      expect(find.text(l.studentProfilePwdMismatch), findsOneWidget);
      await tester.enterText(champs.at(n - 1), 'Nouveau1!');
      await tester.tap(bouton);
      await reseau(tester);
      expect(faux.recues('POST', '/auth/change-password').single.data, {'currentPassword': 'ancien', 'newPassword': 'Nouveau1!'});
      expect(find.text(l.studentProfilePwdChanged), findsOneWidget);
    });

    testWidgets('ancien mot de passe refuse par le serveur : message dedie', (tester) async {
      faux.repond('POST', '/auth/change-password', {}, statut: 400);
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      final bouton = find.widgetWithText(WinButton, L10n.current.studentProfileChangePwd);
      await _defiler(tester, bouton);
      final champs = find.byType(TextField);
      final n = tester.widgetList(champs).length;
      await tester.enterText(champs.at(n - 3), 'faux');
      await tester.enterText(champs.at(n - 2), 'Nouveau1!');
      await tester.enterText(champs.at(n - 1), 'Nouveau1!');
      await tester.tap(bouton);
      await reseau(tester);
      expect(find.text(L10n.current.studentProfilePwdWrong), findsOneWidget);
    });

    testWidgets('double authentification : activation via le serveur ; refus = message et interrupteur inchange', (tester) async {
      faux.repond('POST', '/auth/2fa/enable', {});
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabSecurity);
      final commutateur = find.byType(Switch);
      await _defiler(tester, commutateur);
      expect(tester.widget<Switch>(commutateur).value, isFalse);
      await tester.tap(commutateur);
      await reseau(tester);
      expect(faux.recues('POST', '/auth/2fa/enable'), hasLength(1));
      expect(tester.widget<Switch>(commutateur).value, isTrue);
      faux.repond('POST', '/auth/2fa/disable', {'error': 'Impossible'}, statut: 400);
      await tester.tap(commutateur);
      await reseau(tester);
      expect(tester.widget<Switch>(commutateur).value, isTrue);
      expect(find.text('Impossible'), findsOneWidget);
    });
  });

  group('Autres onglets', () {
    testWidgets('notifications : cinq interrupteurs, trois actifs par defaut ; en basculer un', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentNotifTitle);
      final interrupteurs = find.byType(Switch);
      expect(interrupteurs, findsNWidgets(5));
      final actifs = tester.widgetList<Switch>(interrupteurs).where((s) => s.value).length;
      expect(actifs, 3);
      await tester.tap(interrupteurs.at(2));
      await pomper(tester);
      expect(tester.widgetList<Switch>(interrupteurs).where((s) => s.value).length, 4);
    });

    testWidgets('confidentialite : profil visible par defaut, statistiques anonymes desactivees', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentProfileTabPrivacy);
      final s = tester.widgetList<Switch>(find.byType(Switch)).map((x) => x.value).toList();
      expect(s, [true, false]);
    });

    testWidgets('compte : plan gratuit charge, zone de danger et suppression avec confirmation', (tester) async {
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentHubAccount);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.studentHubPlan('Gratuit')), findsOneWidget);
      expect(find.text(l.commonFree), findsOneWidget);
      await tester.tap(_bouton(l.studentProfileDeleteAccount));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.studentProfileDeleteTitle), findsOneWidget);
      await tester.tap(find.text(l.commonCancel));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.studentProfileDeleteTitle), findsNothing);
    });

    testWidgets('deconnexion : appel serveur puis retour a l\'accueil', (tester) async {
      faux.repond('POST', '/auth/logout', {});
      await monterEcran(tester, const ProfileScreen());
      await _versOnglet(tester, L10n.current.studentHubAccount);
      final b = find.text(L10n.current.commonLogout);
      await _defiler(tester, b);
      await tester.tap(b);
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(faux.recues('POST', '/auth/logout'), hasLength(1));
      expect(find.byType(ProfileScreen), findsNothing);
    });
  });
}
