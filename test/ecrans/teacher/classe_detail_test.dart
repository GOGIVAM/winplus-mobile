import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/teacher_service.dart';
import 'package:winplus/teacher/teacher_class_detail_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

const _classe = ApiTeacherClass(id: 5, name: '3eA', studentCount: 2, isActive: true, pendingCount: 1);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({List<Map<String, dynamic>> eleves = const [], List<Map<String, dynamic>> devoirs = const []}) {
    faux.repond('GET', '/teacher/classes/5/students', eleves);
    faux.repond('GET', '/teacher/assignments', devoirs);
  }

  testWidgets('chargement, nom de la classe et effectif dans l\'onglet eleves', (tester) async {
    routes();
    telephone(tester);
    await monter(tester, ecran(const TeacherClassDetailScreen(initialClass: _classe)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    expect(find.text('3eA'), findsOneWidget);
    expect(find.text(L10n.current.tutoringStudentsN(2)), findsOneWidget);
  });

  testWidgets('classe sans eleve : message et indication', (tester) async {
    routes();
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    expect(find.text(L10n.current.teacherClassNoStudents), findsOneWidget);
    expect(find.text(L10n.current.teacherClassNoStudentsHint), findsOneWidget);
  });

  testWidgets('eleves : nom, niveau ou e-mail, moyenne ou « — »', (tester) async {
    routes(eleves: [
      {'studentId': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'level': 'BAC', 'avgScore': 82.4},
      {'studentId': 2, 'email': 'bob@x.cm'},
    ]);
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    expect(find.text('Ada Eto'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('bob@x.cm'), findsWidgets);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('erreur de chargement des eleves : message et « Reessayer »', (tester) async {
    faux.repond('GET', '/teacher/classes/5/students', {}, statut: 500);
    faux.repond('GET', '/teacher/assignments', []);
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    expect(find.text(L10n.current.teacherClassStudentsLoadError), findsOneWidget);
    faux.repond('GET', '/teacher/classes/5/students', []);
    await tester.tap(_bouton(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text(L10n.current.teacherClassNoStudents), findsOneWidget);
  });

  testWidgets('ajouter un eleve par e-mail : feuille, envoi, message de confirmation, liste relue', (tester) async {
    routes();
    faux.repond('POST', '/teacher/classes/5/students', {});
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    final l = L10n.current;
    await tester.tap(find.text(l.teacherClassAddStudent).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), ' ada@x.cm ');
    await tester.tap(_bouton(l.teacherClassAdd));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/classes/5/students').single.data, {'email': 'ada@x.cm'});
    expect(find.text(l.teacherClassStudentAdded), findsOneWidget);
    expect(faux.recues('GET', '/teacher/classes/5/students'), hasLength(2));
  });

  testWidgets('ajout refuse : message d\'erreur detaille', (tester) async {
    routes();
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    await tester.tap(find.text(L10n.current.teacherClassAddStudent).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'inconnu@x.cm');
    await tester.tap(_bouton(L10n.current.teacherClassAdd));
    await reseau(tester);
    expect(find.text(L10n.current.teacherClassAddStudentErrorDetail), findsOneWidget);
  });

  testWidgets('e-mail vide : aucune requete', (tester) async {
    routes();
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    await tester.tap(find.text(L10n.current.teacherClassAddStudent).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(L10n.current.teacherClassAdd));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/classes/5/students'), isEmpty);
  });

  testWidgets('retirer un eleve : confirmation puis appel serveur ; annuler ne fait rien', (tester) async {
    routes(eleves: [
      {'studentId': 1, 'firstName': 'Ada', 'lastName': 'Eto'},
    ]);
    faux.repond('DELETE', '/teacher/classes/5/students/1', {});
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    final l = L10n.current;
    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(l.teacherClassRemoveStudentBody('Ada Eto', '3eA')), findsOneWidget);
    await tester.tap(find.text(l.commonCancel));
    await reseau(tester);
    expect(faux.recues('DELETE', '/teacher/classes/5/students/1'), isEmpty);
    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(l.teacherClassRemove));
    await reseau(tester);
    expect(faux.recues('DELETE', '/teacher/classes/5/students/1'), hasLength(1));
  });

  testWidgets('onglet devoirs : seuls ceux de la classe, copies et a corriger', (tester) async {
    routes(devoirs: [
      {'id': 1, 'title': 'Devoir 1', 'teacherClassId': 5, 'submissionCount': 12, 'pendingCount': 4},
      {'id': 2, 'title': 'Devoir d\'une autre classe', 'teacherClassId': 9},
    ]);
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    final l = L10n.current;
    expect(find.text('${l.teacherClassAssignmentsTab} (1)'), findsOneWidget);
    await tester.tap(find.text('${l.teacherClassAssignmentsTab} (1)'));
    await pomper(tester);
    expect(find.text('Devoir 1'), findsOneWidget);
    expect(find.text('Devoir d\'une autre classe'), findsNothing);
    expect(find.text('${l.teacherClassCopies(12)}  ${l.teacherClassToMark(4)}'), findsOneWidget);
  });

  testWidgets('onglet devoirs vide : message dedie', (tester) async {
    routes();
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    await tester.tap(find.textContaining(L10n.current.teacherClassAssignmentsTab));
    await pomper(tester);
    expect(find.text(L10n.current.teacherClassNoAssignments), findsOneWidget);
  });

  testWidgets('creer un devoir : titre d\'au moins 3 caracteres, envoi avec enonce facultatif', (tester) async {
    routes();
    faux.repond('POST', '/teacher/assignments', {'id': 7, 'title': 'Devoir 7', 'teacherClassId': 5});
    await monterEcran(tester, const TeacherClassDetailScreen(initialClass: _classe));
    final l = L10n.current;
    await tester.tap(find.textContaining(l.teacherClassAssignmentsTab));
    await pomper(tester);
    await tester.tap(find.text(l.teacherClassNewAssignment).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(0), 'ab');
    await tester.tap(_bouton(l.teacherClassCreateAssignment));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/assignments'), isEmpty);
    await tester.tap(find.text(l.teacherClassNewAssignment).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(0), 'Devoir 7');
    await tester.enterText(find.byType(TextField).at(1), 'Resoudre les exercices');
    await tester.tap(_bouton(l.teacherClassCreateAssignment));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/assignments').single.data, {'teacherClassId': 5, 'title': 'Devoir 7', 'statementText': 'Resoudre les exercices'});
    expect(find.text(l.teacherClassAssignmentCreated), findsOneWidget);
  });
}
