import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/onboarding_success_screen.dart';
import 'package:winplus/auth/periodic_confirm_screen.dart';
import 'package:winplus/auth/splash_screen.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/legal_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('SplashScreen', () {
    testWidgets('affiche la marque puis, sans session, ouvre directement la connexion', (tester) async {
      await monterEcran(tester, const SplashScreen());
      expect(find.text('WinPlus'), findsOneWidget);
      expect(find.text(L10n.current.welcomeTagline), findsOneWidget);
      await pomper(tester, const Duration(milliseconds: 1300));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('SplashScreen avec session', () {
    const session = {'access_token': 'jeton', 'refresh_token': 'r', 'user_id': 1, 'user_role': 'student'};

    testWidgets('le serveur demande la reconfirmation : ecran de reconfirmation', (tester) async {
      faux = preparerEnvironnement(prefs: session);
      faux.repond('GET', '/auth/reconfirmation-status', {
        'data': {'required': true, 'daysSinceLastConfirm': 40, 'windowDays': 35, 'maskedEmail': 'a***@x.cm'},
        'success': true,
      });
      await monterEcran(tester, const SplashScreen());
      await pomper(tester, const Duration(milliseconds: 1300));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(PeriodicConfirmScreen), findsOneWidget);
      expect(find.text('a***@x.cm'), findsOneWidget);
    });

    testWidgets('serveur muet : pas de reconfirmation, pas de retour a la connexion', (tester) async {
      faux = preparerEnvironnement(prefs: session);
      faux.coupure('GET', '/auth/reconfirmation-status');
      await monterEcran(tester, const SplashScreen());
      await pomper(tester, const Duration(milliseconds: 1300));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(PeriodicConfirmScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(SplashScreen), findsNothing);
      // L'espace du compte a lance l'ecoute des notifications : on le retire
      // et on laisse s'ecouler l'attente de reconnexion en cours.
      await monter(tester, const SizedBox());
      await pomper(tester, const Duration(seconds: 3));
    });
  });

  group('OnboardingSuccessScreen', () {
    testWidgets('prenom fourni : message de bienvenue et trois avantages pour un eleve', (tester) async {
      await monterEcran(tester, const OnboardingSuccessScreen(firstName: 'Ada'));
      final l = L10n.current;
      expect(find.text(l.authWelcomeName('Ada')), findsOneWidget);
      expect(find.text(l.authSuccessStudent), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(3));
      expect(find.text(l.authFeatStudent1), findsOneWidget);
      expect(_bouton(l.authStart), findsOneWidget);
    });

    testWidgets('sans prenom : formule par defaut ; le sous-titre suit le role', (tester) async {
      await monterEcran(tester, const OnboardingSuccessScreen(role: WinRole.parent));
      final l = L10n.current;
      expect(find.text(l.authWelcomeName(l.authYouDefault)), findsOneWidget);
      expect(find.text(l.authSuccessParent), findsOneWidget);
      expect(find.text(l.authFeatParent1), findsOneWidget);
    });
  });

  group('LegalScreen', () {
    testWidgets('CGU : titre, huit sections et contact', (tester) async {
      await monterEcran(tester, const LegalScreen(doc: LegalDoc.cgu));
      final l = L10n.current;
      expect(find.text(l.legalCguTitle), findsOneWidget);
      expect(find.text(l.legalCgu1Title), findsOneWidget);
      expect(find.text(l.legalLastUpdated), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.legalContactTitle), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.legalContactTitle), findsOneWidget);
    });

    testWidgets('confidentialite : titre propre et premiere section', (tester) async {
      await monterEcran(tester, const LegalScreen(doc: LegalDoc.confidentialite));
      final l = L10n.current;
      expect(find.text(l.legalPrivacyTitle), findsOneWidget);
      expect(find.text(l.legalPriv1Title), findsOneWidget);
      expect(find.text(l.legalCgu1Title), findsNothing);
    });

    testWidgets('la fleche retour ferme l\'ecran', (tester) async {
      await monterEcran(tester, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => LegalScreen.showCgu(c), child: const Text('ouvrir')))));
      await tester.tap(find.text('ouvrir'));
      // Premiere image de la page poussee : hors scene ; la suivante l'affiche.
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(LegalScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(LegalScreen), findsNothing);
    });
  });
}
