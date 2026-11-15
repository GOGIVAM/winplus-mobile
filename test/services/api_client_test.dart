import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/app_config.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/api_client.dart';
import 'package:winplus/services/session_manager.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('AppConfig', () {
    test('le mode developpement est desactive et l\'API est celle de production', () {
      expect(AppConfig.devMode, isFalse);
      expect(AppConfig.apiBaseUrl, 'https://api.winplus.cm/api');
      expect(AppConfig.apiBaseUrl.startsWith('https://'), isTrue);
      expect(AppConfig.networkTimeout, 30);
    });
  });

  group('ApiClient : configuration', () {
    test('un seul client partage', () {
      expect(identical(ApiClient.instance, ApiClient.instance), isTrue);
      expect(identical(ApiClient.instance.dio, ApiClient.instance.dio), isTrue);
    });

    test('URL de base, delais et en-tete JSON', () {
      final o = ApiClient.instance.dio.options;
      expect(o.baseUrl, AppConfig.apiBaseUrl);
      expect(o.connectTimeout, const Duration(seconds: 30));
      expect(o.receiveTimeout, const Duration(seconds: 30));
      expect(o.headers['Content-Type'], 'application/json');
    });
  });

  group('ApiClient : intercepteur de requetes', () {
    test('sans session, aucune en-tete Authorization', () async {
      faux.repond('GET', '/ping', {'ok': true});
      await ApiClient.instance.dio.get('/ping');
      expect(faux.requetes.single.headers.containsKey('Authorization'), isFalse);
    });

    test('avec session, le jeton est envoye en Bearer', () async {
      await SessionManager.save(accessToken: 'abc123', refreshToken: 'r', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
      faux.repond('GET', '/ping', {'ok': true});
      await ApiClient.instance.dio.get('/ping');
      expect(faux.requetes.single.headers['Authorization'], 'Bearer abc123');
    });

    test('la langue de l\'application est envoyee dans Accept-Language', () async {
      faux.repond('GET', '/ping', {});
      await ApiClient.instance.dio.get('/ping');
      L10n.locale = const Locale('en');
      await ApiClient.instance.dio.get('/ping');
      expect(faux.requetes.map((r) => r.headers['Accept-Language']), ['fr', 'en']);
    });
  });

  group('ApiClient : get, post, put, delete', () {
    test('get renvoie le corps tel quel, et le convertit avec fromJson', () async {
      faux.repond('GET', '/items', {'n': 3});
      final brut = await ApiClient.instance.get<Map<String, dynamic>>('/items');
      expect(brut, {'n': 3});
      final n = await ApiClient.instance.get<int>('/items', fromJson: (d) => (d as Map)['n'] as int);
      expect(n, 3);
    });

    test('get transmet les parametres de requete', () async {
      faux.repond('GET', '/items', {});
      await ApiClient.instance.get<Map<String, dynamic>>('/items', params: {'page': 2});
      expect(faux.requetes.single.queryParameters, {'page': 2});
    });

    test('post et put envoient le corps et renvoient la reponse convertie', () async {
      faux.repond('POST', '/items', {'id': 9});
      faux.repond('PUT', '/items/9', {'id': 9, 'nom': 'x'});
      final cree = await ApiClient.instance.post<int>('/items', data: {'nom': 'x'}, fromJson: (d) => (d as Map)['id'] as int);
      expect(cree, 9);
      expect(faux.recues('POST', '/items').single.data, {'nom': 'x'});
      final maj = await ApiClient.instance.put<Map<String, dynamic>>('/items/9', data: {'nom': 'y'});
      expect(maj['nom'], 'x');
      expect(faux.recues('PUT', '/items/9').single.data, {'nom': 'y'});
    });

    test('delete appelle la route', () async {
      faux.repond('DELETE', '/items/9', null, statut: 204);
      await ApiClient.instance.delete('/items/9');
      expect(faux.recues('DELETE', '/items/9'), hasLength(1));
    });

    test('une erreur serveur (500) est levee en DioException avec sa reponse', () async {
      faux.repond('GET', '/boom', {'error': 'panne'}, statut: 500);
      await expectLater(
        ApiClient.instance.dio.get('/boom'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statut', 500).having((e) => (e.response?.data as Map)['error'], 'message', 'panne')),
      );
    });
  });

  group('ApiClient : session expiree (401)', () {
    test('sans jeton de rafraichissement, la session est effacee et l\'erreur 401 remonte', () async {
      // Le rafraichissement reel passerait par un autre Dio (reseau) : on ne
      // teste ici que la branche sans jeton de rafraichissement, pour laquelle
      // _tryRefresh renvoie false sans appel reseau.
      SharedPreferences.setMockInitialValues({'access_token': 'abc', 'user_id': 1});
      expect(await SessionManager.isLoggedIn(), isTrue);
      expect(await SessionManager.getRefreshToken(), isNull);
      faux.repond('GET', '/prive', {'error': 'non autorise'}, statut: 401);
      await expectLater(
        ApiClient.instance.dio.get('/prive'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statut', 401)),
      );
      expect(await SessionManager.isLoggedIn(), isFalse);
    });

    test('jeton renouvele : la requete est rejouee et l\'identite enregistree reste', () async {
      await SessionManager.save(accessToken: 'vieux', refreshToken: 'r1', userId: 1, email: 'a@b.cm', role: 'parent', name: 'A');
      faux.sur('GET', '/prive', (o) => o.headers['Authorization'] == 'Bearer neuf'
          ? const FauxReponse({'ok': true})
          : const FauxReponse({'error': 'expire'}, 401));
      faux.repond('POST', '/auth/refresh', {'accessToken': 'neuf', 'refreshToken': 'r2'});
      final res = await ApiClient.instance.dio.get('/prive');
      expect(res.data, {'ok': true});
      expect(faux.recues('POST', '/auth/refresh').single.data, {'refreshToken': 'r1'});
      expect(await SessionManager.getRefreshToken(), 'r2');
      expect(await SessionManager.getUserEmail(), 'a@b.cm');
      expect(await SessionManager.getUserRole(), 'parent');
    });

    test('plusieurs refus en meme temps : un seul renouvellement', () async {
      await SessionManager.save(accessToken: 'vieux', refreshToken: 'r1', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
      FauxReponse prive(RequestOptions o) => o.headers['Authorization'] == 'Bearer neuf'
          ? const FauxReponse({'ok': true})
          : const FauxReponse({'error': 'expire'}, 401);
      faux.sur('GET', '/a', prive);
      faux.sur('GET', '/b', prive);
      faux.repond('POST', '/auth/refresh', {'accessToken': 'neuf', 'refreshToken': 'r2'});
      await Future.wait([ApiClient.instance.dio.get('/a'), ApiClient.instance.dio.get('/b')]);
      expect(faux.recues('POST', '/auth/refresh'), hasLength(1));
    });

    test('renouvellement refuse : session effacee et signal de session expiree, une fois', () async {
      await SessionManager.save(accessToken: 'vieux', refreshToken: 'r1', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
      var signaux = 0;
      ApiClient.instance.onSessionExpired = () => signaux++;
      faux.repond('GET', '/prive', {'error': 'expire'}, statut: 401);
      faux.repond('POST', '/auth/refresh', {'error': 'refuse'}, statut: 401);
      await expectLater(ApiClient.instance.dio.get('/prive'), throwsA(isA<DioException>()));
      expect(await SessionManager.isLoggedIn(), isFalse);
      expect(signaux, 1);
    });

    test('un 401 sans session (mauvais mot de passe) n\'est pas une expiration', () async {
      var signaux = 0;
      ApiClient.instance.onSessionExpired = () => signaux++;
      faux.repond('POST', '/auth/signin', {'error': 'mauvais mot de passe'}, statut: 401);
      await expectLater(ApiClient.instance.dio.post('/auth/signin'), throwsA(isA<DioException>()));
      expect(signaux, 0);
      expect(faux.recues('POST', '/auth/refresh'), isEmpty);
    });

    test('une erreur 403 n\'efface pas la session', () async {
      await SessionManager.save(accessToken: 'abc', refreshToken: 'r', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
      faux.repond('GET', '/interdit', {'error': 'non'}, statut: 403);
      await expectLater(ApiClient.instance.dio.get('/interdit'), throwsA(isA<DioException>()));
      expect(await SessionManager.isLoggedIn(), isTrue);
    });
  });
}
