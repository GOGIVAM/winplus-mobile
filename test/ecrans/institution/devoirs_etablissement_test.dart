import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/homework_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/institution_exams_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : devoirs donnés par l'établissement.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  testWidgets('liste : classe, rendus et moyenne sur 20', (tester) async {
    faux.repond('GET', '/institution/homework', {'data': [
      {'id': 3, 'title': 'Devoir derivees', 'groupName': 'Tle C', 'quizSubject': 'Maths', 'students': 20, 'done': 15, 'averageScore': 65.0},
    ], 'success': true});
    await monterEcran(tester, const InstitutionHomeworkScreen());
    final l = L10n.current;
    expect(find.text('Devoir derivees'), findsOneWidget);
    expect(find.text('${l.ihwDone(15, 20)} · ${l.mockAverage('13.0 / 20')}'), findsOneWidget);
  });

  testWidgets('donner un devoir : classe obligatoire, sujet, consignes', (tester) async {
    faux.repond('GET', '/institution/groups', [{'id': 1, 'name': 'Tle C', 'level': 'Tle'}]);
    faux.repond('GET', '/quizzes/search', {'items': [{'id': 9, 'title': 'Quiz limites', 'subject': 'Maths'}]});
    faux.repond('POST', '/institution/homework', {'data': {'id': 4}, 'success': true});
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const HomeworkFormScreen());
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    await tester.tap(find.widgetWithText(WinButton, l.ihwGive));
    await pomper(tester);
    expect(find.text(l.ihwNeedClass), findsOneWidget);
    await tester.tap(find.widgetWithText(WinChip, 'Tle C'));
    await tester.tap(find.widgetWithText(WinChip, l.mockKindQuiz));
    await pomper(tester);
    await tester.enterText(find.byType(TextField).first, 'limites');
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await tester.tap(find.text('Quiz limites'));
    await pomper(tester);
    await tester.enterText(find.byType(TextField).last, 'Avant vendredi');
    await tester.tap(find.widgetWithText(WinButton, l.ihwGive));
    await reseau(tester);
    expect(faux.recues('POST', '/institution/homework').single.data,
        {'studyGroupId': 1, 'quizId': 9, 'examId': null, 'instructions': 'Avant vendredi'});
  });

  testWidgets('avancement : statuts et notes ; supprimer', (tester) async {
    faux.repond('GET', '/institution/homework/3/progress', {'data': [
      {'id': 30, 'firstName': 'Paul', 'lastName': 'Eto', 'status': 'done', 'score': 80.0},
      {'id': 31, 'firstName': 'Zoe', 'lastName': 'Eto', 'status': 'late', 'score': 40.0},
      {'id': 32, 'firstName': 'Ali', 'lastName': 'Bello', 'status': 'pending'},
    ], 'success': true});
    faux.repond('DELETE', '/institution/homework/3', {'success': true});
    await monterEcran(tester, const HomeworkProgressScreen(homework: InstitutionHomework(id: 3, title: 'Devoir derivees')));
    final l = L10n.current;
    expect(find.text('16.0 / 20'), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.ihwStatusLate), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.ihwStatusTodo), findsOneWidget);
    await tester.tap(find.byTooltip(l.ihwDelete));
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(TextButton, l.ihwDelete));
    await reseau(tester);
    expect(faux.recues('DELETE', '/institution/homework/3'), hasLength(1));
  });
}
