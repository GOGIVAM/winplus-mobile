import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/session_manager.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;
  late TestWidgetsFlutterBinding binding;

  setUp(() {
    faux = preparerEnvironnement();
    binding = TestWidgetsFlutterBinding.ensureInitialized();
    // Langue du telephone figee : espagnol, donc ni francais ni anglais.
    binding.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(binding.platformDispatcher.clearLocaleTestValue);
  });
  tearDown(() => L10n.locale = const Locale('fr'));

  group('WinAppState : theme et role', () {
    test('etat initial : clair, eleve, francais', () {
      final s = WinAppState();
      expect(s.dark, isFalse);
      expect(s.role, WinRole.student);
      expect(s.locale, const Locale('fr'));
    });

    test('toggleTheme bascule le theme et previent les ecouteurs', () {
      final s = WinAppState();
      var appels = 0;
      s.addListener(() => appels++);
      s.toggleTheme();
      expect(s.dark, isTrue);
      s.toggleTheme();
      expect(s.dark, isFalse);
      expect(appels, 2);
    });

    test('setDark fixe le theme et previent meme si la valeur ne change pas', () {
      final s = WinAppState();
      var appels = 0;
      s.addListener(() => appels++);
      s.setDark(true);
      s.setDark(true);
      expect(s.dark, isTrue);
      expect(appels, 2);
    });

    test('setRole change le role actif', () {
      final s = WinAppState();
      var appels = 0;
      s.addListener(() => appels++);
      s.setRole(WinRole.teacher);
      expect(s.role, WinRole.teacher);
      expect(appels, 1);
    });
  });

  group('WinAppState.loadLocale', () {
    test('sans choix enregistre, une langue de telephone inconnue donne le francais', () async {
      final s = WinAppState();
      await s.loadLocale();
      expect(s.locale.languageCode, 'fr');
      expect(L10n.code, 'fr');
    });

    test('sans choix enregistre, un telephone en anglais donne l\'anglais', () async {
      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      final s = WinAppState();
      await s.loadLocale();
      expect(s.locale.languageCode, 'en');
      expect(L10n.isEn, isTrue);
    });

    test('un choix enregistre l\'emporte sur la langue du telephone', () async {
      SharedPreferences.setMockInitialValues({kLocalePrefKey: 'en'});
      final s = WinAppState();
      await s.loadLocale();
      expect(s.locale.languageCode, 'en');

      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      SharedPreferences.setMockInitialValues({kLocalePrefKey: 'fr'});
      final s2 = WinAppState();
      await s2.loadLocale();
      expect(s2.locale.languageCode, 'fr');
    });

    test('un choix enregistre invalide est ignore au profit de la langue du telephone', () async {
      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      SharedPreferences.setMockInitialValues({kLocalePrefKey: 'de'});
      final s = WinAppState();
      await s.loadLocale();
      expect(s.locale.languageCode, 'en');
    });

    test('previent les ecouteurs du changement de langue', () async {
      SharedPreferences.setMockInitialValues({kLocalePrefKey: 'en'});
      final s = WinAppState();
      var appels = 0;
      s.addListener(() => appels++);
      await s.loadLocale();
      expect(appels, 1);
    });
  });

  group('WinAppState.setLocale', () {
    test('un code non gere est ignore : rien ne change, rien n\'est ecrit', () async {
      final s = WinAppState();
      var appels = 0;
      s.addListener(() => appels++);
      await s.setLocale('de');
      expect(s.locale.languageCode, 'fr');
      expect(appels, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocalePrefKey), isNull);
    });

    test('applique la langue, la memorise et met a jour L10n', () async {
      final s = WinAppState();
      await s.setLocale('en');
      expect(s.locale.languageCode, 'en');
      expect(L10n.code, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocalePrefKey), 'en');
    });

    test('hors connexion, aucune requete n\'est envoyee au serveur', () async {
      final s = WinAppState();
      await s.setLocale('en');
      await laisserFinir();
      expect(faux.requetes, isEmpty);
    });

    test('connecte, la langue est aussi envoyee au profil (PUT /users/profile)', () async {
      await SessionManager.save(accessToken: 'jeton', refreshToken: 'r', userId: 7, email: 'a@b.cm', role: 'student', name: 'Ada');
      faux.repond('PUT', '/users/profile', {});
      final s = WinAppState();
      await s.setLocale('en');
      await laisserFinir();
      final recues = faux.recues('PUT', '/users/profile');
      expect(recues, hasLength(1));
      expect(recues.single.data, {'locale': 'en'});
    });
  });

  group('WinAppState.applyAccountLocale', () {
    test('la langue du compte est appliquee et memorisee', () async {
      final s = WinAppState();
      await s.applyAccountLocale('en');
      expect(s.locale.languageCode, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocalePrefKey), 'en');
      expect(faux.requetes, isEmpty);
    });

    test('un compte sans langue recoit celle de l\'application', () async {
      faux.repond('PUT', '/users/profile', {});
      final s = WinAppState();
      await s.applyAccountLocale(null);
      await laisserFinir();
      expect(s.locale.languageCode, 'fr');
      final recues = faux.recues('PUT', '/users/profile');
      expect(recues, hasLength(1));
      expect(recues.single.data, {'locale': 'fr'});
    });

    test('une langue de compte invalide est traitee comme absente', () async {
      faux.repond('PUT', '/users/profile', {});
      final s = WinAppState();
      await s.applyAccountLocale('de');
      await laisserFinir();
      expect(s.locale.languageCode, 'fr');
      expect(faux.recues('PUT', '/users/profile'), hasLength(1));
    });
  });
}
