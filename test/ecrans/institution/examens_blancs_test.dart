import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/mock_exams_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : examens blancs de l'établissement (liste, programmation, classement).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> examen({String? publie, int jours = -2}) => {
        'id': 7, 'title': 'Examen blanc · Maths', 'subject': 'Maths', 'durationMinutes': 120,
        'opensAt': DateTime.now().add(Duration(days: jours)).toUtc().toIso8601String(),
        'closesAt': DateTime.now().add(Duration(days: jours + 1)).toUtc().toIso8601String(),
        'resultsPublishedAt': publie, 'quizId': 3,
        'groups': [{'id': 1, 'name': 'Tle C'}], 'expected': 30, 'submitted': 25, 'average': 62.0,
      };

  testWidgets('liste : statut a publier, copies, moyenne sur 20', (tester) async {
    faux.repond('GET', '/institution/mock-exams', {'data': [examen()], 'success': true});
    await monterEcran(tester, const MockExamsScreen());
    final l = L10n.current;
    expect(find.text('Examen blanc · Maths'), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.mockToPublish), findsOneWidget);
    expect(find.text('${l.mockSubmitted(25, 30)} · ${l.mockAverage('12,4/20')}'), findsOneWidget);
  });

  testWidgets('vide : explication et programmer', (tester) async {
    faux.repond('GET', '/institution/mock-exams', {'data': [], 'success': true});
    await monterEcran(tester, const MockExamsScreen());
    expect(find.text(L10n.current.mockEmptyTitle), findsOneWidget);
  });

  testWidgets('programmer : sujet, classe, controles, envoi', (tester) async {
    faux.repond('GET', '/institution/groups', [{'id': 1, 'name': 'Tle C', 'level': 'Tle'}, {'id': 2, 'name': 'Tle D', 'level': 'Tle'}]);
    faux.repond('GET', '/exams/search', {'items': [{'id': 44, 'title': 'BAC Maths 2024', 'category': 'Maths', 'year': 2024}]});
    faux.repond('POST', '/institution/mock-exams', {'data': {'id': 9, 'students': 28}, 'success': true});
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const MockExamFormScreen());
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    await tester.tap(find.widgetWithText(WinButton, l.mockSchedule));
    await pomper(tester);
    expect(find.text(l.mockNeedSubject), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'maths');
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(faux.recues('GET', '/exams/search').last.queryParameters['searchTerm'], 'maths');
    await tester.tap(find.text('BAC Maths 2024'));
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.mockSchedule));
    await pomper(tester);
    expect(find.text(l.mockNeedClass), findsOneWidget);
    await tester.tap(find.widgetWithText(WinChip, 'Tle D'));
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.mockSchedule));
    await reseau(tester);
    final envoi = faux.recues('POST', '/institution/mock-exams').single.data as Map;
    expect(envoi['groupIds'], [2]);
    expect(envoi['examId'], 44);
    expect(envoi['quizId'], isNull);
    expect(envoi['durationMinutes'], 120);
    expect(DateTime.parse(envoi['closesAt'] as String).isAfter(DateTime.parse(envoi['opensAt'] as String)), isTrue);
  });

  testWidgets('classement : repartition, classes, rangs, absents ; publier', (tester) async {
    faux.repond('GET', '/institution/mock-exams/7/ranking', {
      'data': {
        ...examen(),
        'ranking': [
          {'rank': 1, 'studentId': 30, 'name': 'Paul Eto', 'groupName': 'Tle C', 'score': 90.0, 'minutes': 80},
          {'rank': 2, 'studentId': 31, 'name': 'Zoe Eto', 'groupName': 'Tle D', 'score': 50.0, 'minutes': 110},
        ],
        'absent': [{'studentId': 32, 'name': 'Ali Bello', 'groupName': 'Tle C'}],
        'byClass': [
          {'groupId': 1, 'groupName': 'Tle C', 'students': 2, 'submitted': 1, 'average': 90.0, 'best': 90.0},
          {'groupId': 2, 'groupName': 'Tle D', 'students': 1, 'submitted': 1, 'average': 50.0, 'best': 50.0},
        ],
        'buckets': [{'from': 0, 'to': 25, 'count': 0}, {'from': 25, 'to': 50, 'count': 0}, {'from': 50, 'to': 75, 'count': 1}, {'from': 75, 'to': 100, 'count': 1}],
      },
      'success': true,
    });
    faux.repond('POST', '/institution/mock-exams/7/publish', {'success': true});
    tester.view.physicalSize = const Size(800, 4000);
    await monterEcran(tester, const MockExamRankingScreen(examId: 7, title: 'Examen'));
    tester.view.physicalSize = const Size(800, 4000);
    await pomper(tester);
    final l = L10n.current;
    expect(find.text('Paul Eto'), findsOneWidget);
    expect(find.text('18/20'), findsWidgets);
    expect(find.text(l.mockAbsent(1)), findsOneWidget);
    expect(find.text('Ali Bello (Tle C)'), findsOneWidget);
    expect(find.text('15 – 20/20'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.mockPublish));
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(TextButton, l.mockPublish));
    await reseau(tester);
    expect(faux.recues('POST', '/institution/mock-exams/7/publish'), hasLength(1));
    expect(find.text(l.mockPublishedDone), findsOneWidget);
  });

  testWidgets('panne : erreur', (tester) async {
    faux.repond('GET', '/institution/mock-exams', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const MockExamsScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });
}
