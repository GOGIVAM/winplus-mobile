import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/institution/at_risk_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/goal_proposal_tab.dart';
import 'package:winplus/parent/parent_tabs.dart';
import 'package:winplus/services/messaging_service.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/shared/messaging/messaging_screen.dart';
import 'package:winplus/student/notifications_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Une panne du serveur n'est plus affichée comme une liste vide : message
/// commun « Impossible de charger » et Réessayer, puis la vraie liste (ou le
/// vrai état vide) au nouvel essai.
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    await initialiserDates();
    dossier = ouvrirDossierHive();
    // Boîtes du cache parent en mémoire (objectifs, enfants).
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));
  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
  });

  Future<void> reessayer(WidgetTester tester) async {
    await tester.tap(find.text(L10n.current.commonRetry));
    await reseau(tester);
  }

  testWidgets('messagerie : panne puis aucune conversation', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/messages/conversations', {'error': 'panne'}, statut: 500);
    await monterEcran(tester, const MessagingScreen());
    expect(find.text(l.commonLoadError), findsOneWidget);
    expect(find.text(l.msgEmpty), findsNothing);
    faux.repond('GET', '/messages/conversations', []);
    await reessayer(tester);
    expect(find.text(l.msgEmpty), findsOneWidget);
  });

  testWidgets('conversation : panne puis aucun message', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/messages/conversations/4/messages', {'error': 'panne'}, statut: 500);
    faux.repond('PUT', '/messages/conversations/4/read', {});
    faux.repond('POST', '/messages/conversations/4/read', {});
    await monterEcran(
        tester,
        ConversationScreen(
            conversation: ApiConversation.fromJson(
                {'id': 4, 'participantId': 2, 'participantName': 'Zoe Eto', 'participantRole': 'student', 'unreadCount': 0})));
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/messages/conversations/4/messages', []);
    await reessayer(tester);
    expect(find.text(l.msgStartConversation), findsOneWidget);
  });

  testWidgets('eleves a risque : panne, pas « aucun eleve a risque »', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/institution/at-risk', {'error': 'panne'}, statut: 500);
    await monterEcran(tester, const AtRiskScreen());
    expect(find.text(l.commonLoadError), findsOneWidget);
    expect(find.text(l.instRiskEmpty), findsNothing);
    faux.repond('GET', '/institution/at-risk', []);
    await reessayer(tester);
    expect(find.text(l.instRiskEmpty), findsOneWidget);
  });

  testWidgets('notifications : panne, pas « tout est a jour »', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/notifications', {'error': 'panne'}, statut: 500);
    await monterEcran(tester, const NotificationsScreen());
    expect(find.text(l.commonLoadError), findsOneWidget);
    expect(find.text(l.studentNotifAllCaughtUp), findsNothing);
    faux.repond('GET', '/notifications', {'items': [], 'total': 0});
    await reessayer(tester);
    expect(find.text(l.studentNotifAllCaughtUp), findsOneWidget);
  });

  testWidgets('objectifs proposes : panne puis la liste', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/parent/children/4/goals', {'error': 'panne'}, statut: 500);
    await monterEcran(
        tester,
        const Scaffold(
            body: GoalProposalTab(child: ApiChild(id: 4, firstName: 'Zoe', lastName: 'Eto'))));
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/parent/children/4/goals', {'data': []});
    await reessayer(tester);
    expect(find.text(l.commonLoadError), findsNothing);
  });

  testWidgets('accueil parent : panne, pas « aucun enfant »', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/parent/children', {'error': 'panne'}, statut: 500);
    await monterEcran(tester, const Scaffold(body: ParentDashTab()));
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/parent/children', []);
    await reessayer(tester);
    expect(find.text(l.commonLoadError), findsNothing);
  });
}
