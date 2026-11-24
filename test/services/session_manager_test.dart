import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/services/session_manager.dart';

import '../helpers/faux_reseau.dart';

Future<void> _enregistrer() => SessionManager.save(
      accessToken: 'acces-1',
      refreshToken: 'refresh-1',
      userId: 42,
      email: 'eleve@winplus.cm',
      role: 'student',
      name: 'Ada Lovelace',
    );

void main() {
  setUp(() => preparerEnvironnement());

  group('SessionManager : enregistrement et lecture', () {
    test('sans session : tout est vide et personne n\'est connecte', () async {
      expect(await SessionManager.getAccessToken(), isNull);
      expect(await SessionManager.getRefreshToken(), isNull);
      expect(await SessionManager.getUserId(), isNull);
      expect(await SessionManager.getUserRole(), isNull);
      expect(await SessionManager.getUserName(), isNull);
      expect(await SessionManager.getUserEmail(), isNull);
      expect(await SessionManager.isLoggedIn(), isFalse);
    });

    test('save conserve toutes les informations de session', () async {
      await _enregistrer();
      expect(await SessionManager.getAccessToken(), 'acces-1');
      expect(await SessionManager.getRefreshToken(), 'refresh-1');
      expect(await SessionManager.getUserId(), 42);
      expect(await SessionManager.getUserEmail(), 'eleve@winplus.cm');
      expect(await SessionManager.getUserRole(), 'student');
      expect(await SessionManager.getUserName(), 'Ada Lovelace');
      expect(await SessionManager.isLoggedIn(), isTrue);
    });

    test('un jeton d\'acces vide ne compte pas comme connecte', () async {
      await SessionManager.save(accessToken: '', refreshToken: 'r', userId: 1, email: 'a@b.cm', role: 'student', name: 'X');
      expect(await SessionManager.isLoggedIn(), isFalse);
    });

    test('une nouvelle sauvegarde remplace la precedente', () async {
      await _enregistrer();
      await SessionManager.save(accessToken: 'acces-2', refreshToken: 'refresh-2', userId: 43, email: 'p@winplus.cm', role: 'parent', name: 'Parent');
      expect(await SessionManager.getAccessToken(), 'acces-2');
      expect(await SessionManager.getUserId(), 43);
      expect(await SessionManager.getUserRole(), 'parent');
    });
  });

  group('SessionManager.clear', () {
    test('efface la session', () async {
      await _enregistrer();
      await SessionManager.clear();
      expect(await SessionManager.isLoggedIn(), isFalse);
      expect(await SessionManager.getUserId(), isNull);
      expect(await SessionManager.getUserEmail(), isNull);
    });

    test('conserve la langue choisie sur l\'appareil', () async {
      SharedPreferences.setMockInitialValues({'winplus_locale': 'en'});
      await _enregistrer();
      await SessionManager.clear();
      final p = await SharedPreferences.getInstance();
      expect(p.getString('winplus_locale'), 'en');
      expect(await SessionManager.isLoggedIn(), isFalse);
    });

    test('sans langue memorisee, n\'en invente pas', () async {
      await _enregistrer();
      await SessionManager.clear();
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey('winplus_locale'), isFalse);
    });

    test('efface aussi les jetons du trousseau', () async {
      await _enregistrer();
      await SessionManager.clear();
      SessionManager.resetForTest();
      expect(await SessionManager.getAccessToken(), isNull);
      expect(await SessionManager.getRefreshToken(), isNull);
    });
  });

  group('Jetons dans le trousseau securise', () {
    test('les jetons ne sont plus ecrits dans les preferences en clair', () async {
      await _enregistrer();
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey('access_token'), isFalse);
      expect(p.containsKey('refresh_token'), isFalse);
      // Relus depuis le trousseau, pas seulement depuis la memoire.
      SessionManager.resetForTest();
      expect(await SessionManager.getAccessToken(), 'acces-1');
      expect(await SessionManager.getRefreshToken(), 'refresh-1');
    });

    test('une session en clair d\'une version precedente est reprise puis effacee des preferences', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'ancien', 'refresh_token': 'ancien-r', 'user_id': 7});
      SessionManager.resetForTest();
      expect(await SessionManager.isLoggedIn(), isTrue);
      expect(await SessionManager.getRefreshToken(), 'ancien-r');
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey('access_token'), isFalse);
      expect(p.containsKey('refresh_token'), isFalse);
      SessionManager.resetForTest();
      expect(await SessionManager.getAccessToken(), 'ancien');
    });

    test('updateTokens remplace les jetons sans toucher a l\'identite', () async {
      await _enregistrer();
      await SessionManager.updateTokens(accessToken: 'acces-2', refreshToken: 'refresh-2');
      expect(await SessionManager.getAccessToken(), 'acces-2');
      expect(await SessionManager.getRefreshToken(), 'refresh-2');
      expect(await SessionManager.getUserEmail(), 'eleve@winplus.cm');
      expect(await SessionManager.getUserRole(), 'student');
      expect(await SessionManager.getUserName(), 'Ada Lovelace');
    });

    test('updateTokens sans jeton de renouvellement garde l\'ancien', () async {
      await _enregistrer();
      await SessionManager.updateTokens(accessToken: 'acces-2');
      expect(await SessionManager.getRefreshToken(), 'refresh-1');
    });
  });
  test('la deconnexion garde les reglages du telephone : langue, notifications instantanees, theme', () async {
    SharedPreferences.setMockInitialValues({'winplus_locale': 'en', 'notif_instant_enabled': false, 'winplus_theme': 'dark', 'user_id': 1});
    await SessionManager.clear();
    final p = await SharedPreferences.getInstance();
    expect(p.getString('winplus_locale'), 'en');
    expect(p.getBool('notif_instant_enabled'), isFalse);
    expect(p.getString('winplus_theme'), 'dark');
    expect(p.getInt('user_id'), isNull);
  });}
