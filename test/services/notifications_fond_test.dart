import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/services/api_client.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/services/system_notifications.dart';
import 'package:winplus/services/user_service.dart';

import '../helpers/faux_reseau.dart';

ApiNotification _n(int id, {bool lue = false}) => ApiNotification(
      id: id,
      title: 'Notification $id',
      type: 'info',
      isRead: lue,
      createdAt: DateTime(2026, 11, 15),
    );

/// Notifications application fermée (lot 2) : regle d'affichage commune au
/// service d'ecoute et a la verification periodique, et protection des
/// jetons quand un isolat de fond tourne a cote de l'application.
void main() {
  late FauxReseau faux;

  setUp(() async {
    faux = preparerEnvironnement();
    ApiClient.instance.backgroundMode = false;
    ApiClient.instance.mayRefresh = null;
    await SessionManager.save(accessToken: 'a1', refreshToken: 'r1', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
  });

  tearDown(() {
    ApiClient.instance.backgroundMode = false;
    ApiClient.instance.mayRefresh = null;
  });

  group('NotificationSync', () {
    Future<List<int>> passage(List<ApiNotification> serveur) async {
      final affichees = <int>[];
      await NotificationSync.checkAndNotify(
        fetch: () async => serveur,
        display: (n) async => affichees.add(n.id),
      );
      return affichees;
    }

    test('premier passage : rien n\'est affiche, le point de depart est memorise', () async {
      expect(await passage([_n(3), _n(2)]), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(NotificationSync.lastShownKey), 3);
    });

    test('ensuite : seules les nouvelles non lues, de la plus ancienne a la plus recente', () async {
      await passage([_n(3)]);
      expect(await passage([_n(6), _n(5, lue: true), _n(4), _n(3)]), [4, 6]);
    });

    test('une notification n\'est jamais affichee deux fois', () async {
      await passage([_n(3)]);
      expect(await passage([_n(4), _n(3)]), [4]);
      expect(await passage([_n(4), _n(3)]), isEmpty);
    });

    test('au plus cinq par passage : les plus recentes', () async {
      await passage([_n(1)]);
      final serveur = [for (var i = 12; i >= 2; i--) _n(i)];
      expect(await passage(serveur), [8, 9, 10, 11, 12]);
    });

    test('sans session : aucun appel, rien d\'affiche', () async {
      await SessionManager.clear();
      var appels = 0;
      final n = await NotificationSync.checkAndNotify(
        fetch: () async {
          appels++;
          return [_n(9)];
        },
        display: (_) async {},
      );
      expect(n, 0);
      expect(appels, 0);
    });

    test('panne reseau : aucune erreur levee, le passage suivant reprend', () async {
      await passage([_n(3)]);
      final n = await NotificationSync.checkAndNotify(
        fetch: () async => throw DioException.connectionError(requestOptions: RequestOptions(), reason: 'coupure'),
        display: (_) async {},
      );
      expect(n, 0);
      expect(await passage([_n(4), _n(3)]), [4]);
    });

    test('lit la premiere page de GET /notifications par defaut', () async {
      await passage([_n(1)]);
      faux.repond('GET', '/notifications', {
        'data': [
          {'id': 2, 'title': 'Nouveau message', 'isRead': false, 'type': 'info', 'createdAt': '2026-11-15T08:00:00Z'},
        ],
        'unread': 1,
        'total': 1,
      });
      final affichees = <String>[];
      await NotificationSync.checkAndNotify(display: (n) async => affichees.add(n.title));
      expect(affichees, ['Nouveau message']);
      expect(faux.recues('GET', '/notifications').single.queryParameters, {'page': 1, 'limit': 20});
    });
  });

  group('Jetons partages avec un isolat de fond', () {
    test('jeton deja renouvele par un autre isolat : rejoue sans consommer le jeton de renouvellement', () async {
      faux.sur('GET', '/prive', (o) => o.headers['Authorization'] == 'Bearer a2'
          ? const FauxReponse({'ok': true})
          : const FauxReponse({'error': 'expire'}, 401));
      // L'autre isolat a ecrit de nouveaux jetons dans le trousseau, la copie
      // en memoire de celui-ci a encore « a1 ».
      await SessionManager.getAccessToken();
      await const FlutterSecureStorage().write(key: 'access_token', value: 'a2');
      await const FlutterSecureStorage().write(key: 'refresh_token', value: 'r2');
      final res = await ApiClient.instance.dio.get('/prive');
      expect(res.data, {'ok': true});
      expect(faux.recues('POST', '/auth/refresh'), isEmpty);
    });

    test('en arriere-plan, un renouvellement refuse ne deconnecte pas', () async {
      ApiClient.instance.backgroundMode = true;
      var signaux = 0;
      ApiClient.instance.onSessionExpired = () => signaux++;
      faux.repond('GET', '/prive', {'error': 'expire'}, statut: 401);
      faux.repond('POST', '/auth/refresh', {'error': 'refuse'}, statut: 401);
      await expectLater(ApiClient.instance.dio.get('/prive'), throwsA(isA<DioException>()));
      expect(await SessionManager.isLoggedIn(), isTrue);
      expect(signaux, 0);
    });

    test('application ouverte : l\'isolat de fond ne renouvelle pas', () async {
      ApiClient.instance.backgroundMode = true;
      ApiClient.instance.mayRefresh = () async => false;
      faux.repond('GET', '/prive', {'error': 'expire'}, statut: 401);
      faux.repond('POST', '/auth/refresh', {'accessToken': 'a3', 'refreshToken': 'r3'});
      await expectLater(ApiClient.instance.dio.get('/prive'), throwsA(isA<DioException>()));
      expect(faux.recues('POST', '/auth/refresh'), isEmpty);
      expect(await SessionManager.getRefreshToken(), 'r1');
    });
  });
}
