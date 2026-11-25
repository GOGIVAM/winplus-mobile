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
import 'package:winplus/shell/more_screen.dart';
import 'package:winplus/shell/settings_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  // Meme barre pour tous : Accueil, deux onglets de l'espace, Messages, Plus.
  testWidgets('eleve : accueil, catalogue, mon espace, messages, plus', (tester) async {
    await monterCoque(tester, WinRole.student);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabCatalog, l.shellTabMySpace, l.shellTabMessages, l.shellTabMore]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
    expect(find.text(l.shellTabChildren), findsNothing);
  });

  testWidgets('parent : accueil, enfants, catalogue, messages, plus', (tester) async {
    await monterCoque(tester, WinRole.parent);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabChildren, l.shellTabCatalog, l.shellTabMessages, l.shellTabMore]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('professeur : accueil, contenus, etudiants, messages, plus', (tester) async {
    await monterCoque(tester, WinRole.teacher);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabContent, l.shellTabStudents, l.shellTabMessages, l.shellTabMore]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('etablissement : accueil, groupes, analyses, messages, plus ; avatar en icone d\'immeuble', (tester) async {
    await monterCoque(tester, WinRole.institution);
    final l = L10n.current;
    for (final t in [l.shellTabHome, l.shellTabGroups, l.shellTabAnalytics, l.shellTabMessages, l.shellTabMore]) {
      expect(_onglet(t), findsOneWidget, reason: t);
    }
    expect(find.byIcon(PhosphorIconsRegular.buildings), findsWidgets);
  });

  testWidgets('professeur, « Plus » : seances, revenus, corrections, reglages et deconnexion', (tester) async {
    faux.repond('POST', '/auth/logout', {});
    await monterCoque(tester, WinRole.teacher);
    final l = L10n.current;
    await tester.tap(_onglet(l.shellTabMore));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(MoreScreen), findsOneWidget);
    // Dans l'ordre de l'ecran : quatre groupes d'usage, puis les reglages.
    final liste = find.byType(Scrollable).last;
    for (final t in [
      l.moreGroupTeach, l.mobileHomeSessions, l.shellTabCatalog,
      l.moreGroupFollow, l.dpTitle, l.mobileHomeCorrections,
      l.moreGroupTutoring,
      l.moreGroupEarnings, l.shellTabEarnings,
      l.settingsTitle,
    ]) {
      await tester.scrollUntilVisible(find.text(t), 200, scrollable: liste);
      expect(find.text(t), findsWidgets, reason: t);
    }
    final sortie = find.text(l.commonLogout);
    await tester.scrollUntilVisible(sortie, 300, scrollable: find.byType(Scrollable).last);
    expect(sortie, findsOneWidget);
  });

  testWidgets('professeur, « Plus » : une entree ouvre sa page avec retour', (tester) async {
    await monterCoque(tester, WinRole.teacher);
    final l = L10n.current;
    await tester.tap(_onglet(l.shellTabMore));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await tester.scrollUntilVisible(find.text(l.shellTabEarnings), 200, scrollable: find.byType(Scrollable).last);
    await pomper(tester);
    await tester.tap(find.text(l.shellTabEarnings));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(MorePage), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.arrowLeft), findsOneWidget);
  });

  testWidgets('« Plus » puis « Parametres », pour chaque espace : langue et mode sombre', (tester) async {
    final l = L10n.current;
    for (final role in WinRole.values) {
      await monterCoque(tester, role);
      await tester.tap(_onglet(l.shellTabMore));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(MoreScreen), findsOneWidget, reason: '$role');
      // Lot 9.4 : cours en direct dans « Plus » pour chaque espace.
      final cours = find.text(l.liveTitle);
      await tester.scrollUntilVisible(cours, 200, scrollable: find.byType(Scrollable).last);
      expect(cours, findsOneWidget, reason: '$role');
      // Lot 7 : aide et contact, sous « Paramètres », pour chaque espace.
      final aide = find.text(l.helpTitle);
      await tester.scrollUntilVisible(aide, 200, scrollable: find.byType(Scrollable).last);
      expect(aide, findsOneWidget, reason: '$role');
      final ligne = find.text(l.settingsTitle);
      await tester.scrollUntilVisible(ligne, 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(ligne);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(SettingsScreen), findsOneWidget, reason: '$role');
      expect(find.text(l.language), findsOneWidget);
      expect(find.text(l.commonDarkMode), findsOneWidget);
      // Lot 3 : place occupée sur le téléphone, pour chaque espace.
      final telechargements = find.text(l.dlTitle);
      await tester.scrollUntilVisible(telechargements, 200, scrollable: find.byType(Scrollable).last);
      expect(telechargements, findsOneWidget, reason: '$role');
      await monter(tester, const SizedBox());
    }
  });

  testWidgets('l\'avatar ouvre « Plus »', (tester) async {
    await monterCoque(tester, WinRole.teacher);
    await tester.tap(find.text('AE'));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(MoreScreen), findsOneWidget);
  });

  testWidgets('panier dans la barre du haut pour l\'eleve et le parent, pas pour le professeur', (tester) async {
    await monterCoque(tester, WinRole.student);
    expect(find.byTooltip(L10n.current.mobileCatalogCart), findsOneWidget);
    await monter(tester, const SizedBox());
    await monterCoque(tester, WinRole.teacher);
    expect(find.byTooltip(L10n.current.mobileCatalogCart), findsNothing);
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
    await tester.tap(find.byTooltip(L10n.current.studentNotifTitle));
    await pomper(tester);
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
    await tester.tap(_onglet(L10n.current.shellTabMySpace));
    await pomper(tester, const Duration(milliseconds: 300));
    await reseau(tester);
    // Le titre de la barre du haut et le libelle de l'onglet.
    expect(find.text(L10n.current.shellTabMySpace), findsNWidgets(2));
  });

  testWidgets('la langue du compte est appliquee au demarrage', (tester) async {
    faux.repond('GET', '/users/me', {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'locale': 'en'});
    final etat = WinAppState()..setRole(WinRole.student);
    await monterEcran(tester, const RoleShell(), etat: etat);
    expect(etat.locale.languageCode, 'en');
    L10n.locale = const Locale('fr');
  });
}
