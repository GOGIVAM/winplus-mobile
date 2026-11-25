import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/peer_comparison_section.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : comparaison anonyme avec les élèves actifs (GET
/// /student/peer-comparison), dans « Mes rapports ».
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  Future<void> monterSection(WidgetTester tester) =>
      monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: PeerComparisonSection())));

  testWidgets('au-dessus de la moyenne : valeurs sur 20, perimetre, repere des 20 %, « mieux que X % »', (tester) async {
    faux.repond('GET', '/student/peer-comparison', {
      'hasData': true, 'userAvg': 14.2, 'peerAvg': 11.5, 'percentile': 72, 'topPerformersAvg': 16.8, 'sampleSize': 128,
    });
    await monterSection(tester);
    final l = L10n.current;
    expect(find.text(l.peersAbove), findsOneWidget);
    expect(find.text('14.2 / 20'), findsOneWidget);
    expect(find.text('11.5 / 20'), findsOneWidget);
    expect(find.text(l.peersScope(128)), findsOneWidget);
    expect(find.text(l.peersTop('16.8')), findsOneWidget);
    expect(find.text(l.peersBetterThan(72)), findsOneWidget);
  });

  testWidgets('en dessous : mot neutre, pas de pourcentage ni de rang', (tester) async {
    faux.repond('GET', '/student/peer-comparison', {
      'hasData': true, 'userAvg': 8.0, 'peerAvg': 11.5, 'percentile': 20, 'topPerformersAvg': 16.8, 'sampleSize': 128,
    });
    await monterSection(tester);
    final l = L10n.current;
    expect(find.text(l.peersBelow), findsOneWidget);
    expect(find.text(l.peersBetterThan(20)), findsNothing, reason: 'sous 50 %, pas de pourcentage');
  });

  testWidgets('moins d\'un point d\'ecart : « proche »', (tester) async {
    faux.repond('GET', '/student/peer-comparison', {
      'hasData': true, 'userAvg': 11.9, 'peerAvg': 11.5, 'percentile': 55, 'topPerformersAvg': 16.8, 'sampleSize': 40,
    });
    await monterSection(tester);
    expect(find.text(L10n.current.peersClose), findsOneWidget);
  });

  testWidgets('pas de donnees ou moins de 5 eleves : une phrase, pas de barres', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/student/peer-comparison', {'hasData': false});
    await monterSection(tester);
    expect(find.text(l.peersNotEnough), findsOneWidget);
    faux.repond('GET', '/student/peer-comparison', {
      'hasData': true, 'userAvg': 12, 'peerAvg': 11, 'percentile': 60, 'topPerformersAvg': 15, 'sampleSize': 3,
    });
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: PeerComparisonSection(key: ValueKey('b')))));
    expect(find.text(l.peersNotEnough), findsOneWidget);
    expect(find.text(l.peersYou), findsNothing);
  });

  testWidgets('panne : erreur et Reessayer', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/student/peer-comparison', {'error': 'x'}, statut: 500);
    await monterSection(tester);
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/student/peer-comparison', {'hasData': false});
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.peersNotEnough), findsOneWidget);
  });
}
