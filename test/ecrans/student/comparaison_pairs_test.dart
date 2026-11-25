import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/peer_comparison_section.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : comparaison anonyme avec les autres élèves (GET
/// /student/peer-comparison), dans « Mes rapports ». Les moyennes du
/// serveur sont des pourcentages, affichés sur 20.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  Future<void> monterSection(WidgetTester tester, {Key? key}) =>
      monterEcran(tester, Scaffold(body: SingleChildScrollView(child: PeerComparisonSection(key: key))));

  group('ancien serveur (production : toute la plateforme, sans portees)', () {
    testWidgets('au-dessus : valeurs sur 20, perimetre, repere des 20 %, « mieux que X % », pas de selecteur', (tester) async {
      faux.repond('GET', '/student/peer-comparison', {
        'hasData': true, 'userAvg': 71.0, 'peerAvg': 57.5, 'percentile': 72, 'topPerformersAvg': 84.0, 'sampleSize': 128,
      });
      await monterSection(tester);
      final l = L10n.current;
      expect(find.text(l.peersAbove), findsOneWidget);
      expect(find.text('14.2 / 20'), findsOneWidget);
      expect(find.text('11.5 / 20'), findsOneWidget);
      expect(find.text(l.peersScope(128)), findsOneWidget);
      expect(find.text(l.peersTop('16.8')), findsOneWidget);
      expect(find.text(l.peersBetterThan(72)), findsOneWidget);
      expect(find.byType(WinChip), findsNothing);
      expect(faux.recues('GET', '/student/peer-comparison').single.queryParameters, isEmpty);
    });

    testWidgets('en dessous : mot neutre, pas de pourcentage', (tester) async {
      faux.repond('GET', '/student/peer-comparison', {
        'hasData': true, 'userAvg': 40.0, 'peerAvg': 57.5, 'percentile': 20, 'topPerformersAvg': 84.0, 'sampleSize': 128,
      });
      await monterSection(tester);
      final l = L10n.current;
      expect(find.text(l.peersBelow), findsOneWidget);
      expect(find.text(l.peersBetterThan(20)), findsNothing, reason: 'sous 50 %, pas de pourcentage');
    });

    testWidgets('moins d\'un point sur 20 d\'ecart : « proche »', (tester) async {
      faux.repond('GET', '/student/peer-comparison', {
        'hasData': true, 'userAvg': 59.5, 'peerAvg': 57.5, 'percentile': 55, 'topPerformersAvg': 84.0, 'sampleSize': 40,
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
        'hasData': true, 'userAvg': 60, 'peerAvg': 55, 'percentile': 60, 'topPerformersAvg': 75, 'sampleSize': 3,
      });
      await monterSection(tester, key: const ValueKey('b'));
      expect(find.text(l.peersNotEnough), findsOneWidget);
      expect(find.text(l.peersYou), findsNothing);
    });
  });

  group('nouveau serveur (portees et matieres)', () {
    Map<String, dynamic> classe({Map<String, dynamic> extra = const {}}) => {
          'hasData': true, 'scope': 'class', 'periodDays': 30, 'minSample': 5,
          'group': {'label': 'Terminale C · Maths', 'size': 24},
          'userAvg': 70.0, 'peerAvg': 60.0, 'groupAvg': 60.0, 'percentile': 75, 'sampleSize': 24,
          'availableScopes': [
            {'scope': 'class', 'label': 'Terminale C · Maths', 'available': true},
            {'scope': 'level', 'label': 'Mon niveau', 'available': false},
            {'scope': 'platform', 'label': 'Tous les élèves', 'available': true},
          ],
          'subjects': [
            {'subjectId': 1, 'name': 'Mathématiques', 'userAvg': 80.0, 'userQuizCount': 6, 'groupAvg': 65.0, 'percentile': 80, 'size': 20},
            {'subjectId': 2, 'name': 'Physique', 'userAvg': 50.0, 'userQuizCount': 2, 'size': 3, 'reason': 'group_too_small',
             'reasonMessage': 'Trop peu d’élèves de ta classe en Physique.'},
          ],
          ...extra,
        };

    testWidgets('classe : nom du groupe, matieres, portee indisponible grisee', (tester) async {
      faux.repond('GET', '/student/peer-comparison', classe());
      await monterSection(tester);
      final l = L10n.current;
      expect(find.text(l.peersGroupAverage('Terminale C · Maths')), findsOneWidget);
      expect(find.text(l.peersScopeGroup(24)), findsOneWidget);
      expect(find.text('Mathématiques'), findsOneWidget);
      expect(find.text(l.peersSubjectLine('16.0', '13.0')), findsOneWidget);
      expect(find.text('${l.peersSubjectYou('10.0')} · Trop peu d’élèves de ta classe en Physique.'), findsOneWidget);
      final niveau = tester.widget<WinChip>(find.widgetWithText(WinChip, l.peersScopeLevel));
      expect(niveau.onTap, isNull, reason: 'portee indisponible');
      expect(tester.widget<WinChip>(find.widgetWithText(WinChip, 'Terminale C · Maths')).active, isTrue);
    });

    testWidgets('changer de portee : scope envoye au serveur', (tester) async {
      faux.repond('GET', '/student/peer-comparison', classe());
      await monterSection(tester);
      final l = L10n.current;
      faux.repond('GET', '/student/peer-comparison', classe(extra: {'scope': 'platform', 'sampleSize': 300}));
      await tester.tap(find.widgetWithText(WinChip, l.peersScopePlatform));
      await reseau(tester);
      expect(faux.recues('GET', '/student/peer-comparison').last.queryParameters, {'scope': 'platform'});
      expect(find.text(l.peersScope(300)), findsOneWidget);
      expect(find.text(l.peersAverage), findsOneWidget);
    });

    testWidgets('raison du serveur affichee telle quelle (groupe trop petit), moyenne de l\'eleve gardee', (tester) async {
      faux.repond('GET', '/student/peer-comparison', {
        'hasData': true, 'scope': 'class', 'group': {'label': 'Tle C', 'size': 2}, 'userAvg': 65.0, 'sampleSize': 2,
        'reason': 'group_too_small', 'reasonMessage': 'Trop peu d’élèves de ta classe ont fait des quiz.',
        'availableScopes': [
          {'scope': 'class', 'label': 'Tle C', 'available': true},
          {'scope': 'platform', 'label': 'Tous les élèves', 'available': true},
        ],
        'subjects': [],
      });
      await monterSection(tester);
      final l = L10n.current;
      expect(find.text(l.peersYourAverage('13.0')), findsOneWidget);
      expect(find.text('Trop peu d’élèves de ta classe ont fait des quiz.'), findsOneWidget);
      expect(find.text(l.peersYou), findsNothing);
    });
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
