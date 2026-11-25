import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/portfolio_tab.dart';
import 'package:winplus/parent/winai_alerts_screen.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/services/parent_service.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

String _ilYa(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

const _enfant = ApiChild(id: 4, firstName: 'Zoe', lastName: 'Eto');

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boites en memoire : une ecriture sur disque lancee pendant un test ne
    // se termine jamais dans son temps simule et bloquerait le test suivant.
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.reportsBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
    await LocalCacheService.reports.clear();
  });

  group('WinAIAlertsScreen', () {
    testWidgets('aucune alerte : message rassurant et conseils', (tester) async {
      faux.repond('GET', '/parent/children', [
        {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
      ]);
      faux.repond('GET', '/parent-alerts/4', []);
      telephone(tester);
      await monter(tester, ecran(const WinAIAlertsScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.parentAlertsNone), findsOneWidget);
      expect(find.text(l.parentAlertsAllGood), findsOneWidget);
      expect(find.text(l.parentAlertsIntro), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.parentAlertsTip3Title), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.parentAlertsTip1Title), findsOneWidget);
    });

    testWidgets('alertes de plusieurs enfants triees de la plus recente a la plus ancienne, avec gravite', (tester) async {
      faux.repond('GET', '/parent/children', [
        {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
        {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto'},
      ]);
      faux.repond('GET', '/parent-alerts/4', [
        {'id': 1, 'severity': 'High', 'content': 'Inactif depuis 9 jours', 'detectedAt': _ilYa(const Duration(hours: 5))},
      ]);
      faux.repond('GET', '/parent-alerts/5', [
        {'id': 2, 'severity': 'Low', 'content': 'Bon rythme', 'detectedAt': _ilYa(const Duration(minutes: 10))},
      ]);
      await monterEcran(tester, const WinAIAlertsScreen());
      final l = L10n.current;
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Bon rythme'), lessThan(y('Inactif depuis 9 jours')));
      expect(find.text('Zoe Eto'), findsOneWidget);
      expect(find.text('Leo Eto'), findsOneWidget);
      expect(find.text(l.studentNotifMinutesAgo(10)), findsOneWidget);
      expect(find.text(l.studentNotifHoursAgo(5)), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.warningCircle), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsOneWidget);
      expect(find.text(l.parentAlertsSeeActivity), findsNWidgets(2));
    });

    testWidgets('un enfant en echec n\'empeche pas d\'afficher les autres', (tester) async {
      faux.repond('GET', '/parent/children', [
        {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
        {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto'},
      ]);
      faux.repond('GET', '/parent-alerts/4', {}, statut: 500);
      faux.repond('GET', '/parent-alerts/5', [
        {'id': 2, 'severity': 'Medium', 'content': 'Notes en baisse', 'detectedAt': _ilYa(const Duration(minutes: 3))},
      ]);
      await monterEcran(tester, const WinAIAlertsScreen());
      expect(find.text('Notes en baisse'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.warning), findsOneWidget);
    });

    testWidgets('actualiser relit les enfants et les alertes', (tester) async {
      faux.repond('GET', '/parent/children', []);
      await monterEcran(tester, const WinAIAlertsScreen());
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
      await reseau(tester);
      expect(faux.recues('GET', '/parent/children'), hasLength(2));
    });
  });

  group('PortfolioTab', () {
    testWidgets('portefeuille absent (404) : message « pas encore »', (tester) async {
      faux.repond('GET', '/parent-reports/4/portefeuille', {}, statut: 404);
      await monterEcran(tester, const Scaffold(body: PortfolioTab(child: _enfant)));
      expect(find.text(L10n.current.parentPortfolioNotYet('Zoe')), findsOneWidget);
    });

    testWidgets('serveur en panne : erreur et Reessayer, pas « pas encore »', (tester) async {
      faux.repond('GET', '/parent-reports/4/portefeuille', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const Scaffold(body: PortfolioTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text(l.commonLoadError), findsOneWidget);
      expect(find.text(l.parentPortfolioNotYet('Zoe')), findsNothing);
      faux.repond('GET', '/parent-reports/4/portefeuille', {'regularite': 'Travaille chaque soir'});
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(find.text('Travaille chaque soir'), findsOneWidget);
    });

    testWidgets('trois textes descriptifs, date de mise a jour et textes par defaut', (tester) async {
      faux.repond('GET', '/parent-reports/4/portefeuille', {'regularite': 'Travaille chaque soir', 'updatedAt': '2026-03-01T10:00:00'});
      await monterEcran(tester, const Scaffold(body: PortfolioTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text(l.parentPortfolioTitle('Zoe')), findsOneWidget);
      expect(find.text(l.parentPortfolioUpdatedOn('01/03/2026')), findsOneWidget);
      expect(find.text('Travaille chaque soir'), findsOneWidget);
      expect(find.text(l.parentPortfolioNoAutonomy('Zoe')), findsOneWidget);
      expect(find.text(l.parentPortfolioNoCuriosity('Zoe')), findsOneWidget);
      expect(find.text(l.parentPortfolioRegularity.toUpperCase()), findsOneWidget);
    });

    testWidgets('hors ligne : le dernier portefeuille connu reste affiche', (tester) async {
      faux.repond('GET', '/parent-reports/4/portefeuille', {'autonomie': 'Cherche seul', 'updatedAt': '2026-03-01T10:00:00'});
      await monterEcran(tester, const Scaffold(body: PortfolioTab(child: _enfant)));
      expect(find.text('Cherche seul'), findsOneWidget);
      // Meme ecran, sans reseau : relu depuis le cache.
      faux.coupure('GET', '/parent-reports/4/portefeuille');
      await monter(tester, const SizedBox());
      await monterEcran(tester, const Scaffold(body: PortfolioTab(child: _enfant)));
      expect(find.text('Cherche seul'), findsOneWidget);
    });
  });
}
