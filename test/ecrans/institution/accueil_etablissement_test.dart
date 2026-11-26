import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/institution_tabs.dart';
import 'package:winplus/institution/license_screen.dart';
import 'package:winplus/institution/student_directory_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/mobile_home.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Accueil de l'etablissement (MobileHomeView) : recherche, « Pour toi »,
/// acces rapide, chiffres reels, alertes WinAI et groupes.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  // L'accueil ne rattrape pas les erreurs de ses trois premiers appels : ils
  // doivent toujours repondre dans ces tests.
  void routes({
    List<Map<String, dynamic>> groupes = const [],
    List<Map<String, dynamic>> risque = const [],
    Map<String, dynamic> analyses = const {},
    Map<String, dynamic>? licence,
  }) {
    faux.repond('GET', '/institution/groups', groupes);
    faux.repond('GET', '/institution/at-risk', risque);
    faux.repond('GET', '/institution/analytics', analyses);
    faux.repond('GET', '/institution/license', licence ?? {'license': null});
  }

  /// Ecran haut : les blocs du bas sont construits (et reveles) sans defilement.
  Future<void> monterHaut(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const InstitutionDashTab()));
    await reseau(tester);
  }

  /// Fait defiler la bande des chiffres jusqu'au dernier (sieges de licence).
  Future<void> dernierChiffre(WidgetTester tester, Finder cible) async {
    final bande = find.descendant(
      of: find.byType(MobileStatsStrip),
      matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right),
    );
    await tester.scrollUntilVisible(cible, 120, scrollable: bande.first);
  }

  testWidgets('chargement : « — » et indicateur des groupes avant les reponses', (tester) async {
    routes();
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const InstitutionDashTab()));
    expect(find.text('—'), findsWidgets);
    expect(chargement, findsOneWidget);
    await reseau(tester);
    expect(chargement, findsNothing);
  });

  testWidgets('chiffres reels : eleves actifs, quiz du mois et sieges de licence', (tester) async {
    routes(
      analyses: {'totalStudents': 200, 'activeStudents': 150, 'averageScore': 13.6, 'quizzesThisMonth': 42},
      licence: {'license': {'tier': 'pro', 'status': 'active', 'studentSeats': 250, 'studentSeatsUsed': 200}},
    );
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('150 / 200'), findsOneWidget);
    expect(find.text('(${WinFormat.percent(75)})'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    await dernierChiffre(tester, find.text('200 / 250'));
    expect(find.text('200 / 250'), findsOneWidget);
    expect(find.text('${l.instLicenseHeading('pro')} (${WinFormat.percent(80)})'), findsOneWidget);
  });

  testWidgets('sans licence : « Aucune » et mention de l\'absence de licence', (tester) async {
    routes();
    await monterHaut(tester);
    final l = L10n.current;
    await dernierChiffre(tester, find.text(l.teacherProfileNoneF));
    expect(find.text(l.teacherProfileNoneF), findsOneWidget);
    expect(find.text(l.instDashNoLicense), findsOneWidget);
  });

  testWidgets('eleves a risque : le nombre apparait dans « Pour toi »', (tester) async {
    routes(risque: [
      {'id': 1, 'firstName': 'Ada', 'riskScore': 80},
      {'id': 2, 'firstName': 'Bob', 'riskScore': 70},
    ]);
    await monterHaut(tester);
    expect(find.text(L10n.current.mobileHomeAtRiskMeta(2)), findsOneWidget);
  });

  testWidgets('aucun eleve a risque : texte general', (tester) async {
    routes();
    await monterHaut(tester);
    expect(find.text(L10n.current.mobileHomeInstMeta), findsOneWidget);
  });

  testWidgets('groupes : trois au plus, avec effectif', (tester) async {
    routes(groupes: [
      {'id': 1, 'name': '3eA', 'level': 'BEPC', 'memberCount': 30},
      {'id': 2, 'name': '3eB', 'level': 'BEPC', 'memberCount': 28},
      {'id': 3, 'name': '2ndeA', 'level': 'Seconde', 'memberCount': 25},
      {'id': 4, 'name': 'TleD', 'level': 'BAC', 'memberCount': 20},
    ]);
    await monterHaut(tester);
    expect(find.text('3eA'), findsOneWidget);
    expect(find.text('2ndeA'), findsOneWidget);
    expect(find.text('TleD'), findsNothing);
    expect(find.text(L10n.current.instDashStudentsCount(25)), findsOneWidget);
  });

  testWidgets('acces rapide : annuaire et licence ouvrent leur ecran', (tester) async {
    final l = L10n.current;
    for (final (libelle, type) in <(String, Type)>[
      (l.mobileHomeDirectory, StudentDirectoryScreen),
      (l.mobileHomeLicense, LicenseScreen),
    ]) {
      routes();
      await monterHaut(tester);
      await tester.tap(find.text(libelle).first);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(type), findsOneWidget, reason: libelle);
      await monter(tester, const SizedBox());
    }
  });

  testWidgets('information sur les alertes WinAI affichee', (tester) async {
    routes();
    await monterHaut(tester);
    expect(find.text(L10n.current.instDashAlertsInfo), findsOneWidget);
  });
}
