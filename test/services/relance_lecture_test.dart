import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/api_client.dart';

import '../helpers/faux_reseau.dart';

/// Lot 8 (réseau lent) : une lecture qui n'a pas joint le serveur est
/// relancée une fois ; jamais une écriture, ni une vraie réponse du serveur.
void main() {
  late FauxReseau faux;
  setUp(() {
    faux = preparerEnvironnement();
    ApiClient.instance.networkRetries = 1;
    ApiClient.instance.retryDelay = Duration.zero;
  });
  tearDown(() {
    ApiClient.instance.networkRetries = 0;
    ApiClient.instance.retryDelay = const Duration(milliseconds: 800);
  });

  test('micro-coupure : la lecture est relancee et reussit', () async {
    var essais = 0;
    faux.sur('GET', '/courses', (o) {
      essais++;
      if (essais == 1) throw DioException.connectionError(requestOptions: o, reason: 'coupure');
      return const FauxReponse({'data': [1, 2]});
    });
    final r = await ApiClient.instance.dio.get('/courses');
    expect(essais, 2);
    expect(r.data, {'data': [1, 2]});
  });

  test('serveur toujours injoignable : une seule relance, puis l\'erreur', () async {
    faux.coupure('GET', '/courses');
    await expectLater(ApiClient.instance.dio.get('/courses'), throwsA(isA<DioException>()));
    expect(faux.recues('GET', '/courses'), hasLength(2));
  });

  test('ecriture : jamais relancee (la file d\'attente s\'en charge)', () async {
    faux.coupure('POST', '/cart');
    await expectLater(ApiClient.instance.dio.post('/cart', data: {}), throwsA(isA<DioException>()));
    expect(faux.recues('POST', '/cart'), hasLength(1));
  });

  test('reponse du serveur en erreur : pas de relance', () async {
    faux.repond('GET', '/courses', {'error': 'panne'}, statut: 500);
    await expectLater(ApiClient.instance.dio.get('/courses'), throwsA(isA<DioException>()));
    expect(faux.recues('GET', '/courses'), hasLength(1));
  });
}
