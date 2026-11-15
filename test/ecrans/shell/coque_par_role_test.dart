import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/services/user_service.dart';
import 'package:winplus/shell/role_shell.dart';
import 'package:winplus/student/notifications_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Libelle dans la barre d'onglets du bas seulement : les accueils reprennent
/// certains libelles (Messages, Revenus) dans leurs raccourcis.
Finder _onglet(String libelle) => find.descendant(
      of: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_BottomNav'),
      matching: find.text(libelle),
    );

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.studentDashboardBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.examCoachBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.reportsBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() {
    faux = preparerEnvironnement();
    UserService.instance.resetNotifications();
    faux.repond('GET', '/users/me', {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto Mba', 'locale': 'fr'});
    faux.repond('GET', '/notifications/unread-count', {'unread': 3});
    // L'accueil etablissement ne rattrape pas les erreurs reseau de son
    // chargement initial : ces trois routes doivent repondre.
    faux.repond('GET', '/institution/groups', []);
    faux.repond('GET', '/institution/at-risk', []);
    faux.repond('GET', '/institution/analytics', {});
  });

  Future<void> monterCoque(WidgetTester tester, WinRole role) async {
    final etat = WinAppState()..setRole(role);
    await monterEcran(tester, const RoleShell(), etat: etat);
  }

  testWidgets('eleve : quatre onglets, accueil par defaut', (tester) async {
    await monterCoque(tester, WinRole.student);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabCatalog, l.shellTabMySpace, l.shellTabMe]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
    expect(find.text(l.shellTabChildren), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('parent : cinq onglets dont les messages', (tester) async {
    await monterCoque(tester, WinRole.parent);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabChildren, l.shellTabResources, l.shellTabMessages, l.shellTabProfile]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('professeur : cinq onglets dont les gains', (tester) async {
    await monterCoque(tester, WinRole.teacher);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabContent, l.shellTabStudents, l.shellTabSessions, l.shellTabEarnings]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('etablissement : cinq onglets, avatar en icone d\'immeuble', (tester) async {
    await monterCoque(tester, WinRole.institution);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabGroups, l.shellTabCatalog, l.shellTabAnalytics, l.shellTabAccount]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
    expect(find.byIcon(Icons.apartment_outlined), findsWidgets);
  });

  testWidgets('l\'avatar de l\'eleve affiche les initiales du profil (deux premiers mots)', (tester) async {
    await monterCoque(tester, WinRole.student);
    expect(find.text('AE'), findsOneWidget);
  });

  testWidgets('le profil est lu une fois au demarrage', (tester) async {
    await monterCoque(tester, WinRole.student);
    expect(faux.recues('GET', '/users/me'), isNotEmpty);
  });

  testWidgets('pastille de notifications : compteur du serveur, plafonne a 99+', (tester) async {
    await monterCoque(tester, WinRole.student);
    expect(find.text('3'), findsWidgets);
    UserService.instance.unreadNotifications.value = 150;
    await pomper(tester);
    expect(find.text('99+'), findsOneWidget);
    UserService.instance.unreadNotifications.value = 0;
    await pomper(tester);
    expect(find.text('99+'), findsNothing);
  });

  testWidgets('toucher la cloche ouvre les notifications, puis le compteur est relu au retour', (tester) async {
    faux.repond('GET', '/notifications', {'data': [], 'total': 0});
    await monterCoque(tester, WinRole.student);
    final avant = faux.recues('GET', '/notifications/unread-count').length;
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    // Retour systeme : l'ecran des notifications a sa propre fleche.
    await tester.binding.handlePopRoute();
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(faux.recues('GET', '/notifications/unread-count').length, greaterThan(avant));
  });

  testWidgets('choisir un onglet remplace le logo par le titre de l\'onglet', (tester) async {
    await monterCoque(tester, WinRole.student);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.text(L10n.current.shellTabMe));
    await pomper(tester, const Duration(milliseconds: 300));
    await reseau(tester);
    expect(find.text(L10n.current.shellTabMe), findsWidgets);
    expect(find.byIcon(Icons.person_outline), findsWidgets);
  });

  testWidgets('l\'avatar ouvre le choix de la langue', (tester) async {
    await monterCoque(tester, WinRole.student);
    await tester.tap(find.text('AE'));
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.language), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('la langue du compte est appliquee au demarrage', (tester) async {
    faux.repond('GET', '/users/me', {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'locale': 'en'});
    final etat = WinAppState()..setRole(WinRole.student);
    await monterEcran(tester, const RoleShell(), etat: etat);
    expect(etat.locale.languageCode, 'en');
    L10n.locale = const Locale('fr');
  });
}
