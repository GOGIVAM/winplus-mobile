import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/class_prediction_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/class_analysis_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : analyse de classe (professeur) et prévision de réussite (établissement).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  testWidgets('analyse : contenus publies seulement, envoi, repartition et actions', (tester) async {
    faux.repond('GET', '/teacher/contents/mine', [
      {'id': 4, 'title': 'Annales Maths', 'status': 'published'},
      {'id': 5, 'title': 'Brouillon', 'status': 'draft'},
    ]);
    faux.repond('POST', '/teacher/class-analysis', {
      'avg_score': 62.0, 'student_count': 18,
      'mastery_distribution': {'excellent': 3, 'good': 7, 'struggling': 5, 'at_risk': 3},
      'hardest_questions': [{'question_id': 2, 'wrong_answer_rate': 71.4, 'topic': 'Derivees'}],
      'common_mistakes': ['Signe oublie'],
      'recommended_actions': ['Revoir les derivees en classe'],
    });
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const ClassAnalysisScreen());
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    expect(find.widgetWithText(WinChip, 'Brouillon'), findsNothing);
    await tester.tap(find.widgetWithText(WinChip, 'Annales Maths'));
    await reseau(tester);
    expect((faux.recues('POST', '/teacher/class-analysis').single.data as Map)['content_id'], 4);
    expect(find.text('12,4/20'), findsOneWidget);
    expect(find.text('•  ${l.canWrongRate('Derivees', 71)}'), findsOneWidget);
    expect(find.text('•  Revoir les derivees en classe'), findsOneWidget);
  });

  testWidgets('analyse refusee (limite WinAI) : message', (tester) async {
    faux.repond('GET', '/teacher/contents/mine', [{'id': 4, 'title': 'Annales Maths', 'status': 'published'}]);
    faux.repond('POST', '/teacher/class-analysis', {'error': 'Limite WinAI atteinte.'}, statut: 402);
    await monterEcran(tester, const ClassAnalysisScreen());
    await tester.tap(find.widgetWithText(WinChip, 'Annales Maths'));
    await reseau(tester);
    expect(find.text('Limite WinAI atteinte.'), findsOneWidget);
  });

  testWidgets('prevision : taux, confiance, repartition, interventions objet ou texte', (tester) async {
    faux.repond('GET', '/institution/me', {'data': {'id': 4}, 'success': true});
    faux.repond('POST', '/institutions/class-prediction', {
      'predicted_pass_rate': 68, 'confidence': 'medium', 'at_risk_count': 6, 'likely_to_excel_count': 9, 'student_count': 40,
      'comparison_to_last_year': 4, 'key_risk_factors': ['Peu de quiz en physique'],
      'recommended_interventions': [{'intervention': 'Seances de soutien', 'impact': 'fort', 'effort': 'moyen'}, 'Plus de quiz'],
    });
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const ClassPredictionScreen());
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    await tester.tap(find.widgetWithText(WinButton, l.predRun));
    await reseau(tester);
    expect((faux.recues('POST', '/institutions/class-prediction').single.data as Map)['institution_id'], 4);
    expect(find.text(WinFormat.percent(68)), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.predConfMedium), findsOneWidget);
    expect(find.text(l.predVsLastYear('+4')), findsOneWidget);
    expect(find.text('25'), findsOneWidget, reason: '40 - 9 - 6 dans la moyenne');
    expect(find.text('${l.predImpact('fort')} · ${l.predEffort('moyen')}'), findsOneWidget);
    expect(find.text('Plus de quiz'), findsOneWidget);
  });
}
