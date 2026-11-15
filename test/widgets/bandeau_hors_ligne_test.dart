import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/connectivity_service.dart';
import 'package:winplus/services/http_cache.dart';
import 'package:winplus/services/outbox_service.dart';
import 'package:winplus/widgets/offline_strip.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// Bandeau des espaces (lot 3) : hors ligne, serveur injoignable, date des
/// donnees servies depuis le cache, actions en attente.
void main() {
  setUpAll(initialiserDates);
  setUp(() {
    preparerEnvironnement();
    ConnectivityService.instance.debugSetOnline(true);
    OutboxService.instance.pending.value = 0;
  });
  tearDown(() {
    ConnectivityService.instance.debugSetOnline(true);
    OutboxService.instance.pending.value = 0;
  });

  Future<void> monterBandeau(WidgetTester tester) =>
      monterEcran(tester, const Scaffold(body: Column(children: [OfflineStrip()])));

  testWidgets('tout est a jour : rien n\'est affiche', (tester) async {
    await monterBandeau(tester);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('mode avion : « Hors ligne », puis le bandeau disparait au retour du reseau', (tester) async {
    await monterBandeau(tester);
    ConnectivityService.instance.debugSetOnline(false);
    await pomper(tester, const Duration(milliseconds: 300));
    expect(find.text(L10n.current.offlineStripOffline), findsOneWidget);
    ConnectivityService.instance.debugSetOnline(true);
    await pomper(tester, const Duration(milliseconds: 300));
    expect(find.text(L10n.current.offlineStripOffline), findsNothing);
  });

  testWidgets('reseau present mais donnees du cache : serveur injoignable et date', (tester) async {
    await monterBandeau(tester);
    final quand = DateTime(2026, 11, 14, 18, 30);
    HttpCache.instance.servedFromCacheSince.value = quand;
    await pomper(tester, const Duration(milliseconds: 300));
    final l = L10n.current;
    expect(find.text('${l.offlineStripServerDown} · ${l.offlineStripDataOf(WinFormat.dayMonthTime(quand))}'), findsOneWidget);
  });

  testWidgets('actions en attente : leur nombre, meme en ligne', (tester) async {
    await monterBandeau(tester);
    OutboxService.instance.pending.value = 3;
    await pomper(tester, const Duration(milliseconds: 300));
    expect(find.text(L10n.current.offlineStripPending(3)), findsOneWidget);
  });
}
