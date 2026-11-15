import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/api_client.dart';
import 'package:winplus/services/auth_service.dart';
import 'package:winplus/services/http_cache.dart';
import 'package:winplus/services/session_manager.dart';

import '../helpers/faux_reseau.dart';

/// Regle de lecture du mode hors ligne (lot 3) : la derniere version connue
/// remplace l'absence de reponse, jamais une vraie reponse du serveur.
void main() {
  late FauxReseau faux;
  final dio = ApiClient.instance.dio;

  Future<void> session(int id) => SessionManager.save(
      accessToken: 'jeton$id', refreshToken: 'r$id', userId: id, email: 'u$id@x.cm', role: 'student', name: 'U$id');

  setUp(() async {
    faux = preparerEnvironnement();
    await session(1);
  });

  test('coupure : la derniere version connue est servie, avec sa date', () async {
    faux.repond('GET', '/student/stats', {'data': {'averageScore': 74}});
    await dio.get('/student/stats');
    faux.coupure('GET', '/student/stats');
    final res = await dio.get('/student/stats');
    expect(res.data, {'data': {'averageScore': 74}});
    expect(res.extra['fromCache'], isTrue);
    expect(HttpCache.instance.servedFromCacheSince.value, isNotNull);
  });

  test('le retour du reseau efface l\'indication « donnees anciennes »', () async {
    faux.repond('GET', '/a', {'v': 1});
    await dio.get('/a');
    faux.coupure('GET', '/a');
    await dio.get('/a');
    expect(HttpCache.instance.servedFromCacheSince.value, isNotNull);
    faux.repond('GET', '/a', {'v': 2});
    final res = await dio.get('/a');
    expect(res.data, {'v': 2});
    expect(HttpCache.instance.servedFromCacheSince.value, isNull);
  });

  test('les parametres de la requete font partie de la cle', () async {
    faux.sur('GET', '/notifications', (o) => FauxReponse({'page': o.queryParameters['page']}));
    await dio.get('/notifications', queryParameters: {'page': 1});
    await dio.get('/notifications', queryParameters: {'page': 2});
    faux.coupure('GET', '/notifications');
    expect((await dio.get('/notifications', queryParameters: {'page': 2})).data, {'page': 2});
    expect((await dio.get('/notifications', queryParameters: {'page': 1})).data, {'page': 1});
  });

  test('une vraie erreur du serveur n\'est jamais remplacee par le cache', () async {
    faux.repond('GET', '/subscriptions/me', {'planName': 'Premium'});
    await dio.get('/subscriptions/me');
    faux.repond('GET', '/subscriptions/me', {'error': 'aucun plan'}, statut: 404);
    await expectLater(dio.get('/subscriptions/me'), throwsA(isA<DioException>()));
  });

  test('coupure sans version connue : l\'erreur reseau reste', () async {
    faux.coupure('GET', '/jamais-lu');
    await expectLater(dio.get('/jamais-lu'), throwsA(isA<DioException>()));
  });

  test('un compte ne voit jamais les donnees d\'un autre', () async {
    faux.repond('GET', '/users/me', {'firstName': 'Ada'});
    await dio.get('/users/me');
    await session(2);
    faux.coupure('GET', '/users/me');
    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
  });

  test('deconnexion : les lectures du compte sont effacees', () async {
    faux.repond('GET', '/users/me', {'firstName': 'Ada'});
    faux.repond('POST', '/auth/logout', {});
    await dio.get('/users/me');
    await AuthService.instance.signOut();
    await session(1);
    faux.coupure('GET', '/users/me');
    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
  });

  test('jamais gardes : lecons, supports de seance, paiements, connexion, ecritures', () {
    RequestOptions get(String p) => RequestOptions(path: p, method: 'GET');
    expect(HttpCache.isCacheable(get('/courses/7/play/1')), isFalse);
    expect(HttpCache.isCacheable(get('/courses/7/play')), isFalse);
    expect(HttpCache.isCacheable(get('/tutor-bookings/3/material')), isFalse);
    expect(HttpCache.isCacheable(get('/payments/history')), isFalse);
    expect(HttpCache.isCacheable(get('/auth/reconfirmation-status')), isFalse);
    expect(HttpCache.isCacheable(get('/notifications/sse')), isFalse);
    expect(HttpCache.isCacheable(RequestOptions(path: '/subjects/4/file', method: 'GET', responseType: ResponseType.bytes)), isFalse);
    expect(HttpCache.isCacheable(RequestOptions(path: '/favorites', method: 'POST')), isFalse);
    expect(HttpCache.isCacheable(get('/courses/7')), isTrue);
    expect(HttpCache.isCacheable(get('/student/stats')), isTrue);
  });

  test('isolat de fond (cache desactive) : rien n\'est garde ni servi, sans erreur', () async {
    final cache = HttpCache.instance;
    cache.enabled = false;
    addTearDown(() => cache.enabled = true);
    faux.repond('GET', '/notifications', {'data': []});
    await dio.get('/notifications');
    faux.coupure('GET', '/notifications');
    await expectLater(dio.get('/notifications'), throwsA(isA<DioException>()));
  });

  test('cles tres longues : gardees malgre la limite de Hive', () async {
    final long = 'x' * 400;
    faux.repond('GET', '/recherche', {'ok': true});
    await dio.get('/recherche', queryParameters: {'q': long});
    faux.coupure('GET', '/recherche');
    expect((await dio.get('/recherche', queryParameters: {'q': long})).data, {'ok': true});
  });
}
