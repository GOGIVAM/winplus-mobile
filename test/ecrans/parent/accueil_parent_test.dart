import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/buy_for_child_screen.dart';
import 'package:winplus/parent/parent_tabs.dart';
import 'package:winplus/parent/subscription_status_screen.dart';
import 'package:winplus/parent/winai_alerts_screen.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/widgets/mobile_home.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

String _dans(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

/// Accueil du parent (MobileHomeView) : « Pour toi », acces rapide, bande de
/// chiffres (enfants, credits, conseils, offre, moyenne), dernier conseil
/// WinAI, enfants suivis et evenements a venir.
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boite en memoire : une ecriture sur disque lancee pendant un test ne
    // se termine jamais dans son temps simule et bloquerait le test suivant.
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
  });

  void routes({
    List<Map<String, dynamic>> enfants = const [],
    Map<String, dynamic>? abo,
    Object credits = const {'data': null},
    List<Map<String, dynamic>> evenements = const [],
  }) {
    faux.repond('GET', '/parent/children', enfants);
    faux.repond('GET', '/subscriptions/me', abo ?? {'id': 1, 'hasPlan': false, 'planName': 'Gratuit'});
    faux.repond('GET', '/parent/credits', credits);
    faux.repond('GET', '/parent/events/upcoming', {'data': evenements});
    for (final e in enfants) {
      faux.repond('GET', '/parent-alerts/${e['id']}', []);
      faux.repond('GET', '/parent/children/${e['id']}/stats', {'averageScore': 14});
    }
  }

  /// Ecran haut : les blocs du bas sont construits (et reveles) sans defilement.
  Future<void> monterHaut(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const ParentDashTab()));
    await reseau(tester);
  }

  /// Fait defiler la bande des chiffres jusqu'a [cible].
  Future<void> chiffre(WidgetTester tester, Finder cible) async {
    final bande = find.descendant(
      of: find.byType(MobileStatsStrip),
      matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right),
    );
    await tester.scrollUntilVisible(cible, 120, scrollable: bande.first);
  }

  Future<void> ouvrir(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
  }

  testWidgets('chargement : « — » et indicateur dans la rubrique des enfants', (tester) async {
    routes();
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const ParentDashTab()));
    expect(find.text('—'), findsWidgets);
    expect(chargement, findsOneWidget);
    await reseau(tester);
    expect(chargement, findsNothing);
  });

  testWidgets('sans abonnement ni enfant : pas de credits, « sans abonnement », invitation a rattacher', (tester) async {
    routes();
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.parentDashNoCredits), findsOneWidget);
    expect(find.text(l.parentDashNoChild), findsOneWidget);
    expect(find.text(l.mobileHomeLinkTitle), findsOneWidget);
    await chiffre(tester, find.text(l.parentNoSubscription));
    expect(find.text(l.parentNoSubscription), findsOneWidget);
  });

  testWidgets('enfants suivis, solde du portefeuille, offre et moyenne', (tester) async {
    routes(
      enfants: [
        {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto', 'level': 'BAC'},
        {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto'},
      ],
      abo: {'id': 1, 'hasPlan': true, 'planName': 'Famille', 'pricingPlanId': 2, 'status': 'active'},
      credits: {'data': {'creditsLeft': 4500, 'allocationRemaining': 3000, 'permanent': 1500, 'planName': 'Famille'}},
    );
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('2'), findsWidgets);
    expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
    expect(find.text(l.parentDashCreditsDetail(fmtXaf(3000), fmtXaf(1500))), findsOneWidget);
    expect(find.text('Zoe'), findsWidgets);
    expect(find.text('Leo'), findsOneWidget);
    expect(find.text(l.mobileHomeFollowTitle('Zoe')), findsOneWidget);
    expect(faux.recues('GET', '/parent/children/4/stats'), hasLength(1));
    await chiffre(tester, find.text(l.parentPlanName('Famille')));
    expect(find.text(l.parentPlanName('Famille')), findsOneWidget);
    await chiffre(tester, find.text(l.mobileHomeChildrenAvg));
    // Moyenne des enfants (14 % chacun) : dans la bande et sur chaque carte.
    expect(find.text('14%'), findsWidgets);
  });

  testWidgets('conseil WinAI : le plus recent est affiche et ouvre les conseils', (tester) async {
    routes(enfants: [
      {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
    ]);
    faux.repond('GET', '/parent-alerts/4', [
      {'id': 1, 'severity': 'High', 'content': 'Inactif depuis 9 jours', 'detectedAt': _dans(const Duration(hours: -2))},
    ]);
    await monterHaut(tester);
    expect(find.text('Inactif depuis 9 jours'), findsOneWidget);
    await ouvrir(tester, find.text('Inactif depuis 9 jours'));
    expect(find.byType(WinAIAlertsScreen), findsOneWidget);
  });

  testWidgets('evenements : renouvellement de l\'abonnement et evenement publie', (tester) async {
    routes(
      abo: {'id': 1, 'hasPlan': true, 'planName': 'Famille', 'pricingPlanId': 2, 'expiresAt': _dans(const Duration(days: 10, hours: 12))},
      evenements: [
        {'title': 'Portes ouvertes', 'eventType': 'event', 'startDate': _dans(const Duration(days: 3, hours: 12))},
      ],
    );
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.parentDashUpcomingEvents), findsOneWidget);
    expect(find.text('Portes ouvertes'), findsOneWidget);
    expect(find.text(l.parentDashRenewalEvent('Famille')), findsOneWidget);
    await chiffre(tester, find.text(l.parentDashPeriodEndIn('Famille', 10)));
    expect(find.text(l.parentDashPeriodEndIn('Famille', 10)), findsOneWidget);
  });

  testWidgets('abonnement expire : aucun evenement de renouvellement', (tester) async {
    routes(abo: {'id': 1, 'hasPlan': true, 'planName': 'Famille', 'pricingPlanId': 2, 'expiresAt': _dans(const Duration(days: -2))});
    await monterHaut(tester);
    expect(find.text(L10n.current.parentDashUpcomingEvents), findsNothing);
  });

  testWidgets('acces rapide « Abonnement » ouvre l\'etat de l\'abonnement', (tester) async {
    routes();
    faux.repond('GET', '/payments/history', {'payments': []});
    await monterHaut(tester);
    await ouvrir(tester, find.text(L10n.current.mobileHomeSubscription).first);
    expect(find.byType(SubscriptionStatusScreen), findsOneWidget);
  });

  testWidgets('serveur en erreur : plus d\'indicateur, message et Reessayer (pas « aucun enfant »)', (tester) async {
    faux.repond('GET', '/parent/children', {}, statut: 500);
    await monterHaut(tester);
    expect(chargement, findsNothing);
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    expect(find.text(L10n.current.parentDashNoChild), findsNothing);
  });

  testWidgets('acces rapide « Acheter » ouvre l\'achat pour un enfant', (tester) async {
    routes(enfants: [
      {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
    ]);
    await monterHaut(tester);
    final achat = find.text(L10n.current.mobileHomeBuy).first;
    final rangee = find.ancestor(of: achat, matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right));
    if (rangee.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(achat, 80, scrollable: rangee.first);
      await pomper(tester);
    }
    await ouvrir(tester, achat);
    expect(find.byType(BuyForChildScreen), findsOneWidget);
  });
  testWidgets('activite reelle des enfants : active, hier, inactif, jamais actif ; pas de tendance inventee', (tester) async {
    routes(enfants: [
      {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
      {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto'},
      {'id': 7, 'firstName': 'Ivy', 'lastName': 'Eto'},
    ]);
    faux.repond('GET', '/parent/children/4/stats', {'averageScore': 70, 'inactivityDays': 0, 'currentStreak': 3});
    faux.repond('GET', '/parent/children/5/stats', {'averageScore': 60, 'inactivityDays': 1, 'currentStreak': 1});
    faux.repond('GET', '/parent/children/7/stats', {'averageScore': 0, 'inactivityDays': 0, 'currentStreak': 0});
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.commonActive), findsOneWidget, reason: 'seule Zoe a ete active aujourd\'hui');
    expect(find.text(l.commonYesterday), findsOneWidget);
    expect(find.text(l.parentChildInactive), findsOneWidget, reason: 'Ivy n''a jamais ete active');
    expect(find.byIcon(PhosphorIconsRegular.arrowRight), findsNothing, reason: 'le serveur ne calcule aucune tendance');
  });
}
