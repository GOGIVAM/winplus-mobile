import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/pending_actions_screen.dart';
import 'package:winplus/widgets/offline_strip.dart';
import 'package:winplus/services/connectivity_service.dart';
import 'package:winplus/services/favorites_service.dart';
import 'package:winplus/services/outbox_service.dart';
import 'package:winplus/services/session_manager.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// File d'attente du mode hors ligne (lot 3) : une action faite sans reseau
/// part au retour de la connexion, une seule fois (meme cle d'idempotence a
/// chaque essai), avec un nombre d'essais limite.
void main() {
  late FauxReseau faux;
  final file = OutboxService.instance;

  setUp(() async {
    faux = preparerEnvironnement();
    ConnectivityService.instance.debugSetOnline(true);
    await file.initForTest();
    await SessionManager.save(accessToken: 'a', refreshToken: 'r', userId: 1, email: 'a@b.cm', role: 'student', name: 'A');
  });
  tearDown(() => ConnectivityService.instance.debugSetOnline(true));

  String? cle(RequestOptions o) => o.headers['Idempotency-Key'] as String?;

  test('en ligne : envoye tout de suite, avec une cle d\'idempotence', () async {
    faux.repond('POST', '/favorites/4', {});
    final r = await file.sendOrQueue(method: 'POST', path: '/favorites/4', label: 'favorite_add');
    expect(r, SendOutcome.sent);
    expect(cle(faux.recues('POST', '/favorites/4').single), isNotNull);
    expect(file.pendingCount, 0);
  });

  test('mode avion : mis en file sans appel, puis envoye au retour du reseau', () async {
    ConnectivityService.instance.debugSetOnline(false);
    expect(await FavoritesService.instance.add(4), isTrue, reason: 'l\'ecran le compte comme fait');
    expect(faux.recues('POST', '/favorites/4'), isEmpty);
    expect(file.pending.value, 1);
    faux.repond('POST', '/favorites/4', {});
    ConnectivityService.instance.debugSetOnline(true);
    await file.flush();
    expect(faux.recues('POST', '/favorites/4'), hasLength(1));
    expect(file.pending.value, 0);
  });

  test('reponse perdue : le second envoi reprend la meme cle (le serveur l\'ignorera)', () async {
    faux.coupure('POST', '/goals/3/accept');
    final r = await file.sendOrQueue(method: 'POST', path: '/goals/3/accept', label: 'goal_accept');
    expect(r, SendOutcome.queued);
    faux.repond('POST', '/goals/3/accept', {});
    await file.flush();
    final envois = faux.recues('POST', '/goals/3/accept');
    expect(envois, hasLength(2));
    expect(cle(envois[0]), isNotNull);
    expect(cle(envois[1]), cle(envois[0]));
  });

  test('deux actions differentes : deux cles differentes', () async {
    faux.repond('POST', '/favorites/1', {});
    faux.repond('POST', '/favorites/2', {});
    await file.sendOrQueue(method: 'POST', path: '/favorites/1', label: 'favorite_add');
    await file.sendOrQueue(method: 'POST', path: '/favorites/2', label: 'favorite_add');
    expect(cle(faux.recues('POST', '/favorites/1').single), isNot(cle(faux.recues('POST', '/favorites/2').single)));
  });

  test('coupure pendant l\'envoi de la file : pas compte comme un essai', () async {
    ConnectivityService.instance.debugSetOnline(false);
    await file.sendOrQueue(method: 'PUT', path: '/notifications/9/read', label: 'notification_read');
    ConnectivityService.instance.debugSetOnline(true);
    faux.coupure('PUT', '/notifications/9/read');
    await file.flush();
    expect(file.entries.single.attempts, 0);
    expect(file.entries.single.failed, isFalse);
  });

  test('erreurs du serveur : cinq essais puis « non envoyee », relancable', () async {
    ConnectivityService.instance.debugSetOnline(false);
    await file.sendOrQueue(method: 'POST', path: '/goals/3/refuse', label: 'goal_refuse');
    ConnectivityService.instance.debugSetOnline(true);
    faux.repond('POST', '/goals/3/refuse', {'error': 'panne'}, statut: 500);
    for (var i = 0; i < OutboxService.maxAttempts + 2; i++) {
      await file.flush();
    }
    expect(faux.recues('POST', '/goals/3/refuse'), hasLength(OutboxService.maxAttempts));
    expect(file.entries.single.failed, isTrue);
    faux.repond('POST', '/goals/3/refuse', {});
    await file.retry(file.entries.single.id);
    expect(file.entries, isEmpty);
  });

  test('refus definitif du serveur : « non envoyee » tout de suite, avec son message', () async {
    ConnectivityService.instance.debugSetOnline(false);
    await file.sendOrQueue(method: 'POST', path: '/goals/3/accept', label: 'goal_accept');
    ConnectivityService.instance.debugSetOnline(true);
    faux.repond('POST', '/goals/3/accept', {'error': 'Objectif deja traite'}, statut: 409);
    await file.flush();
    final e = file.entries.single;
    expect(e.failed, isTrue);
    expect(e.error, 'Objectif deja traite');
    expect(e.label, 'goal_accept');
  });

  test('en ligne, un refus du serveur remonte comme avant (pas de mise en file)', () async {
    faux.repond('POST', '/goals/3/accept', {'error': 'interdit'}, statut: 403);
    await expectLater(
      file.sendOrQueue(method: 'POST', path: '/goals/3/accept', label: 'goal_accept'),
      throwsA(isA<DioException>()),
    );
    expect(file.pendingCount, 0);
  });

  testWidgets('le bandeau ouvre « En attente d\'envoi » : actions, statut, suppression', (tester) async {
    ConnectivityService.instance.debugSetOnline(false);
    await tester.runAsync(() async {
      await file.sendOrQueue(method: 'POST', path: '/favorites/4', label: 'favorite_add');
      await file.sendOrQueue(method: 'POST', path: '/goals/3/accept', label: 'goal_accept');
    });
    await monterEcran(tester, const Scaffold(body: Column(children: [OfflineStrip()])));
    final l = L10n.current;
    await tester.tap(find.textContaining(l.offlineStripPending(2)));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.byType(PendingActionsScreen), findsOneWidget);
    expect(find.text(l.pendingLabelFavoriteAdd), findsOneWidget);
    expect(find.text(l.pendingLabelGoalAccept), findsOneWidget);
    expect(find.textContaining(l.pendingWaiting), findsNWidgets(2));
    await tester.runAsync(() => file.remove(file.entries.first.id));
    await pomper(tester);
    expect(find.text(l.pendingLabelFavoriteAdd), findsNothing);
  });

  test('supprimer une action la retire de la file', () async {
    ConnectivityService.instance.debugSetOnline(false);
    await file.sendOrQueue(method: 'DELETE', path: '/favorites/7', label: 'favorite_remove');
    await file.remove(file.entries.single.id);
    expect(file.pending.value, 0);
  });
}
