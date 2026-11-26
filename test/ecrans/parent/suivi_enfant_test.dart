import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/child_follow_tab.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : suivi d'un enfant (à travailler, achats) et enfants côte à côte.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  testWidgets('suivi : quiz pas faits, fiches, achats ouverts ou non', (tester) async {
    faux.repond('GET', '/parent/quizzes/available', {'data': [
      {'id': 1, 'title': 'Quiz derivees', 'subject': 'Maths', 'difficulty': 'medium', 'questionCount': 10},
    ], 'success': true});
    faux.repond('GET', '/parent/revisions/available', {'data': [
      {'id': 2, 'title': 'Fiche limites', 'subject': 'Maths', 'type': 'Theory'},
    ], 'success': true});
    faux.repond('GET', '/parent/purchases/30/impact', {'data': [
      {'contentId': 7, 'contentTitle': 'Annales BAC', 'purchaseDate': '2026-11-10T00:00:00Z', 'consulted': true, 'firstConsultedAt': '2026-11-12T00:00:00Z'},
      {'contentId': 8, 'contentTitle': 'Physique', 'purchaseDate': '2026-11-20T00:00:00Z', 'consulted': false},
    ], 'success': true});
    await monterEcran(tester, const Scaffold(body: ChildFollowTab(childId: 30, childName: 'Paul')));
    final l = L10n.current;
    expect(faux.recues('GET', '/parent/quizzes/available').single.queryParameters['childId'], 30);
    expect(find.text('Quiz derivees'), findsOneWidget);
    expect(find.text(l.followToWorkSub(2)), findsOneWidget);
    expect(find.text('Fiche limites'), findsOneWidget);
    expect(find.text(l.followPurchasesSub(1, 2)), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.followNotOpened), findsOneWidget);
  });

  testWidgets('suivi : rien, ou pannes, explication', (tester) async {
    faux.repond('GET', '/parent/quizzes/available', {'error': 'x'}, statut: 500);
    faux.repond('GET', '/parent/revisions/available', {'data': [], 'success': true});
    faux.repond('GET', '/parent/purchases/30/impact', {'data': [], 'success': true});
    await monterEcran(tester, const Scaffold(body: ChildFollowTab(childId: 30, childName: 'Paul')));
    expect(find.text(L10n.current.followEmptyTitle), findsOneWidget);
  });

  testWidgets('enfants cote a cote : chiffres sur 20 et remarques WinAI ; masquer enregistre la preference', (tester) async {
    faux.repond('GET', '/parent/children-insights', {
      'children_summary': [
        {'child_id': 30, 'child_name': 'Paul', 'avg_score': 70.0, 'quiz_count': 8, 'active_days': 12},
        {'child_id': 31, 'child_name': 'Zoe', 'avg_score': 55.0, 'quiz_count': 3, 'active_days': 1},
        {'child_id': 32, 'child_name': 'Leo', 'avg_score': 0.0, 'quiz_count': 0, 'active_days': 1},
      ],
      'insights': ['Paul est tres regulier ce mois-ci.'],
    });
    faux.repond('PUT', '/parent/settings', {'message': 'ok'});
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: ChildrenComparisonCard(childIds: [30, 31]))));
    final l = L10n.current;
    expect(faux.recues('GET', '/parent/children-insights').single.queryParameters['childIds'], '30,31');
    expect(find.text('14/20'), findsOneWidget);
    expect(find.text(l.cmpChildrenMeta(3, 1)), findsOneWidget);
    expect(find.text('0/20'), findsNothing, reason: 'aucun quiz : pas de note nulle');
    expect(find.text('–'), findsOneWidget);
    expect(find.text('Paul est tres regulier ce mois-ci.'), findsOneWidget);
    await tester.tap(find.byTooltip(l.cmpChildrenHide));
    await reseau(tester);
    expect(faux.recues('PUT', '/parent/settings').single.data, {'childrenComparison': false});
    expect(find.text(l.cmpChildrenEnable), findsOneWidget);
  });

  testWidgets('un seul enfant : rien', (tester) async {
    await monterEcran(tester, const Scaffold(body: ChildrenComparisonCard(childIds: [30])));
    expect(faux.recues('GET', '/parent/children-insights'), isEmpty);
    expect(find.text(L10n.current.cmpChildrenTitle), findsNothing);
  });
}
