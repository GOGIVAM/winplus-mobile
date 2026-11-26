import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/teacher_tabs.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Onglet Étudiants du professeur (demande de Georges, 26/11) : deux
/// sous-sections, « Mes élèves » (tous les élèves, une ligne chacun, avec
/// ses classes et sa liaison directe) et « Mes classes ».
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes() {
    faux.repond('GET', '/teacher/classes', [
      {'id': 1, 'name': 'Tle C', 'studentCount': 2, 'isActive': true, 'pendingCount': 0},
      {'id': 2, 'name': '1re D', 'studentCount': 1, 'isActive': true, 'pendingCount': 0},
    ]);
    faux.repond('GET', '/teacher/classes/1/students', [
      {'studentId': 30, 'firstName': 'Gael', 'lastName': 'Pilote', 'email': 'g@x.cm', 'avgScore': 72.0},
      {'studentId': 61, 'firstName': 'Flore', 'lastName': 'Essai', 'email': 'f@x.cm'},
    ]);
    faux.repond('GET', '/teacher/classes/2/students', [
      {'studentId': 30, 'firstName': 'Gael', 'lastName': 'Pilote', 'email': 'g@x.cm'},
    ]);
    faux.repond('GET', '/teacher-links/mine', [
      {'id': 9, 'other': {'id': 77, 'firstName': 'Zoe', 'lastName': 'Eto', 'email': 'z@x.cm'}},
    ]);
  }

  testWidgets('Mes eleves : une ligne par eleve, ses classes et la liaison directe', (tester) async {
    routes();
    tester.view.physicalSize = const Size(800, 2400);
    await monterEcran(tester, const Scaffold(body: TeacherStudentsTab()));
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.teacherStudentsCount(3)), findsOneWidget);
    expect(find.text('Gael Pilote'), findsOneWidget, reason: 'dans deux classes, mais une seule ligne');
    expect(find.text('Tle C'), findsNWidgets(2));
    expect(find.text('1re D'), findsOneWidget);
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(find.text(l.teacherStudentsDirect), findsOneWidget);
    expect(find.text('72 %'), findsOneWidget);
  });

  testWidgets('recherche par nom ou par classe', (tester) async {
    routes();
    tester.view.physicalSize = const Size(800, 2400);
    await monterEcran(tester, const Scaffold(body: TeacherStudentsTab()));
    await reseau(tester);
    await tester.enterText(find.byType(TextField), '1re');
    await pomper(tester);
    expect(find.text(L10n.current.teacherStudentsCount(1)), findsOneWidget);
    expect(find.text('Gael Pilote'), findsOneWidget);
    expect(find.text('Zoe Eto'), findsNothing);
  });

  testWidgets('Mes classes : la liste des classes et la creation', (tester) async {
    routes();
    tester.view.physicalSize = const Size(800, 2400);
    await monterEcran(tester, const Scaffold(body: TeacherStudentsTab()));
    await reseau(tester);
    await tester.tap(find.text(L10n.current.teacherStudentsTabClasses));
    await reseau(tester);
    expect(find.text(L10n.current.teacherClassesCreate), findsOneWidget);
    expect(find.text('Tle C'), findsOneWidget);
    expect(find.text('Gael Pilote'), findsNothing);
  });
}
