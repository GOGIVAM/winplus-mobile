import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/regional_comparison_screen.dart';
import 'package:winplus/l10n/l10n.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : comparaison régionale anonyme de l'établissement.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> dispo() => {
        'data': {
          'available': true, 'scope': 'région Centre', 'institutions': 6, 'rank': 2, 'percentile': 80,
          'mine': 70.0, 'regionAverage': 60.0, 'best': 75.0, 'students': 42,
          'subjects': [
            {'subject': 'Mathématiques', 'mine': 72.0, 'region': 60.0, 'best': 80.0, 'quizzes': 30},
            {'subject': 'Physique', 'mine': 50.0, 'region': 60.0, 'best': 70.0, 'quizzes': 12},
            {'subject': 'SVT', 'mine': 61.0, 'region': 60.0, 'best': 65.0, 'quizzes': 8},
          ],
        },
        'success': true,
      };

  testWidgets('rang, notes sur 20, ecart par matiere', (tester) async {
    faux.repond('GET', '/institution/comparison', dispo());
    await monterEcran(tester, const RegionalComparisonScreen());
    final l = L10n.current;
    expect(find.text(l.regCmpRank(2, 6)), findsOneWidget);
    expect(find.text(l.regCmpBetter(80)), findsOneWidget);
    expect(find.text('14.0 / 20'), findsOneWidget, reason: '70 sur 100');
    expect(find.text('12.0 / 20'), findsWidgets);
    expect(find.text(l.regCmpAverage('région Centre')), findsOneWidget);
    expect(find.text(l.regCmpStudents(42)), findsOneWidget);
    await tester.scrollUntilVisible(find.text('SVT'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('+2.4'), findsOneWidget, reason: '(72 - 60) / 5');
    expect(find.text('-2.0'), findsOneWidget);
    expect(find.text('+0.2'), findsOneWidget, reason: 'ecart faible : affiche, mais neutre');
  });

  testWidgets('pas assez d\'etablissements : raison du serveur et Reessayer', (tester) async {
    faux.repond('GET', '/institution/comparison',
        {'data': {'available': false, 'reason': 'Pas encore assez d\'établissements comparables.'}, 'success': true});
    await monterEcran(tester, const RegionalComparisonScreen());
    final l = L10n.current;
    expect(find.text(l.regCmpNoneTitle), findsOneWidget);
    expect(find.text('Pas encore assez d\'établissements comparables.'), findsOneWidget);
    faux.repond('GET', '/institution/comparison', dispo());
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.regCmpRank(2, 6)), findsOneWidget);
  });

  testWidgets('panne : erreur et Reessayer', (tester) async {
    faux.repond('GET', '/institution/comparison', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const RegionalComparisonScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });

  testWidgets('comparaison nationale : moyenne sur 20, taux, matieres ; affichee meme sans comparaison regionale', (tester) async {
    faux.repond('GET', '/institution/comparison',
        {'data': {'available': false, 'reason': 'Pas encore assez.'}, 'success': true});
    faux.repond('GET', '/institution/me', {'data': {'id': 4}, 'success': true});
    faux.repond('GET', '/institutions/4/benchmark', {
      'institution_avg_score': 64.0, 'national_avg_score': 58.0, 'top_quartile_avg': 75.0, 'institution_percentile': 70,
      'institution_pass_rate': 72.0, 'national_pass_rate': 61.0, 'strongest_subject': 'Maths', 'weakest_subject_vs_peers': 'Anglais',
      'engagement_rate': 55.0, 'peer_engagement_avg': 48.0, 'student_count': 420, 'national_student_count': 9000,
    });
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const RegionalComparisonScreen());
    tester.view.physicalSize = const Size(800, 3000);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.regCmpNoneTitle), findsOneWidget);
    expect(find.text(l.benchSub(70)), findsOneWidget);
    expect(find.text('12.8 / 20'), findsOneWidget);
    expect(find.text(l.benchNational('11.6 / 20')), findsOneWidget);
    expect(find.text(l.benchStrongest('Maths')), findsOneWidget);
  });
}
