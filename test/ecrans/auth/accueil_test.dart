import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/onboarding_success_screen.dart';
import 'package:winplus/auth/periodic_confirm_screen.dart';
import 'package:winplus/auth/splash_screen.dart';
import 'package:winplus/auth/welcome_screen.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/legal_screen.dart';
import 'package:winplus/widgets/win_logo.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('SplashScreen', () {
    testWidgets('affiche la marque (logo dans son disque blanc) puis, sans session, la presentation', (tester) async {
      await monterEcran(tester, const SplashScreen());
      expect(find.text('WinPlus'), findsOneWidget);
      expect(find.text(L10n.current.welcomeTagline), findsOneWidget);
      expect(find.byType(WinLogo), findsOneWidget);
      await pomper(tester, const Duration(milliseconds: 1300));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('WelcomeScreen', () {
    testWidgets('logo et choix de langue en haut de la photo, pas au milieu', (tester) async {
      telephone(tester);
      await monter(tester, ecran(const WelcomeScreen()));
      await pomper(tester);
      final logo = tester.getRect(find.byType(WinLogo));
      final langue = tester.getRect(find.text('EN'));
      final photo = tester.getRect(find.byType(PageView));
      expect(logo.top - photo.top, lessThan(80), reason: 'logo colle au haut de la photo');
      expect(langue.center.dy, lessThan(photo.top + 100), reason: 'langue en haut, alignee sur le logo');
      expect((langue.center.dy - logo.center.dy).abs(), lessThan(24));
    });

    testWidgets('trois ecrans avec photo : titre, « Suivant » avance, le dernier propose compte et connexion', (tester) async {
      await monterEcran(tester, const WelcomeScreen());
      final l = L10n.current;
      expect(find.byType(WinLogo), findsOneWidget);
      // Une photo par ecran (PageView), pas d'icone a la place.
      expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/home/epreuves.webp'), findsOneWidget);
      expect(find.text(l.authWelcomeSlide1Title), findsOneWidget);
      await tester.tap(_bouton(l.authNext));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.text(l.authWelcomeSlide2Title), findsOneWidget);
      await tester.tap(_bouton(l.authNext));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.text(l.authWelcomeSlide3Title), findsOneWidget);
      expect(_bouton(l.authNext), findsNothing);
      expect(_bouton(l.createAccount), findsOneWidget);
      expect(find.text(l.authSkip), findsNothing);
      await tester.tap(_bouton(l.login));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('« Passer » mene au dernier ecran', (tester) async {
      await monterEcran(tester, const WelcomeScreen());
      final l = L10n.current;
      await tester.tap(find.text(l.authSkip));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 600));
      expect(find.text(l.authWelcomeSlide3Title), findsOneWidget);
      expect(_bouton(l.createAccount), findsOneWidget);
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
      expect(find.byIcon(PhosphorIconsBold.check), findsNWidgets(3));
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
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowLeft));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(LegalScreen), findsNothing);
    });
  });
}
