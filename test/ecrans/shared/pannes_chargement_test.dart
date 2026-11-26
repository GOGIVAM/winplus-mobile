import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/institution/group_members_screen.dart';
import 'package:winplus/institution/institution_tabs.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/parent_tabs.dart';
import 'package:winplus/parent/winai_alerts_screen.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/student/quiz_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 8 (parcours sur le Pixel) : un 502 pendant un déploiement laissait
/// l'onglet Enfants du parent en chargement sans fin. Chaque écran affiche
/// maintenant « Impossible de charger » et Réessayer.
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    await initialiserDates();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.studentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));
  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
    await LocalCacheService.studentDashboard.clear();
  });

  Future<void> reessayer(WidgetTester tester) async {
    await tester.tap(find.text(L10n.current.commonRetry));
    await reseau(tester);
  }

  testWidgets('parent, Enfants : 502 puis la liste', (tester) async {
    faux.repond('GET', '/parent/children', {'error': 'Bad gateway'}, statut: 502);
    await monterEcran(tester, const Scaffold(body: ParentChildrenTab()));
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    faux.repond('GET', '/parent/children', [
      {'id': 30, 'firstName': 'Gael', 'lastName': 'Pilote', 'email': 'g@x.cm'},
    ]);
    await reessayer(tester);
    expect(find.text(L10n.current.commonLoadError), findsNothing);
    expect(find.textContaining('Gael'), findsWidgets);
  });

  testWidgets('parent, alertes WinAI : panne affichee', (tester) async {
    faux.repond('GET', '/parent/children', {'error': 'x'}, statut: 502);
    await monterEcran(tester, const WinAIAlertsScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });

  testWidgets('eleve, quiz : panne sans copie locale affichee', (tester) async {
    faux.repond('GET', '/quizzes', {'error': 'x'}, statut: 502);
    await monterEcran(tester, const QuizHubScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });

  testWidgets('etablissement, groupes et membres : panne affichee', (tester) async {
    faux.repond('GET', '/institution/groups', {'error': 'x'}, statut: 502);
    await monterEcran(tester, const Scaffold(body: InstitutionGroupsTab()));
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    faux.repond('GET', '/institution/groups/7/members', {'error': 'x'}, statut: 502);
    await monterEcran(tester, const GroupMembersScreen(groupId: 7, groupName: 'Tle C'));
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });
}
