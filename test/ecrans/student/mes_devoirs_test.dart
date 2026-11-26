import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/homework_service.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/student/my_homework_screen.dart';
import 'package:winplus/student/quiz_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : « Mes devoirs » (devoirs des professeurs, examens blancs, devoirs
/// de l'établissement), comme /mes-devoirs du site.
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    await initialiserDates();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.studentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));
  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.studentDashboard.clear();
  });

  String dans(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

  Map<String, dynamic> devoir(int id, String titre,
          {bool rendu = false, int? quiz, num? note, String? echeance, String? enonce}) =>
      {
        'id': id, 'title': titre, 'statementText': enonce, 'maxScore': 20,
        'dueDate': echeance ?? dans(const Duration(days: 3)), 'teacherClassName': 'Tle C',
        'alreadySubmitted': rendu, 'createdAt': dans(const Duration(days: -1)),
        'quizId': quiz, 'myScore': note,
      };

  void routes({List devoirs = const [], List examens = const [], List etab = const []}) {
    faux.repond('GET', '/student/assignments', {'data': devoirs, 'success': true});
    faux.repond('GET', '/institution/mock-exams/mine', {'data': examens, 'success': true});
    faux.repond('GET', '/institution/homework/mine', {'data': etab, 'success': true});
  }

  final quizJson = {
    'id': 5, 'title': 'Derivees', 'durationMinutes': 10,
    'questions': [
      {'id': 'q1', 'questionText': '2 + 2 ?', 'options': ['3', '4'], 'correctAnswer': '4'},
    ],
  };

  testWidgets('trois sections et statuts : a rendre, en retard, rendu, note ; examen ouvert ; devoir manque', (tester) async {
    routes(
      devoirs: [
        devoir(1, 'Exercice 1'),
        devoir(2, 'Exercice 2', echeance: dans(const Duration(days: -2))),
        devoir(3, 'Exercice 3', rendu: true),
        devoir(4, 'Exercice 4', rendu: true, note: 15.5),
      ],
      examens: [
        {'id': 7, 'title': 'Bac blanc', 'opensAt': dans(const Duration(hours: -1)), 'closesAt': dans(const Duration(hours: 2)),
         'durationMinutes': 120, 'quizId': 5, 'status': 'open', 'published': false},
      ],
      etab: [
        {'id': 9, 'title': 'Revision chap 2', 'quizId': 5, 'groupName': 'Groupe A', 'status': 'missing'},
      ],
    );
    await monterEcran(tester, const MyHomeworkScreen());
    final l = L10n.current;
    expect(find.text(l.hwSectionTeacher), findsOneWidget);
    expect(find.text(l.hwStatusTodo), findsOneWidget);
    expect(find.text(l.hwStatusLate), findsOneWidget);
    expect(find.text(l.hwStatusDone), findsOneWidget);
    expect(find.text(l.hwScore('15,5', '20')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Revision chap 2'), 200);
    expect(find.text(l.hwChipOpen), findsOneWidget);
    expect(find.text(l.hwSchoolMissing), findsOneWidget);
  });

  testWidgets('aucun devoir : etat vide ; tout en panne : erreur et Reessayer', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/student/assignments', {'error': 'x'}, statut: 500);
    faux.repond('GET', '/institution/mock-exams/mine', {'error': 'x'}, statut: 500);
    faux.repond('GET', '/institution/homework/mine', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const MyHomeworkScreen());
    expect(find.text(l.commonLoadError), findsOneWidget);
    routes();
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.hwEmpty), findsOneWidget);
  });

  testWidgets('une source en panne : les autres s\'affichent avec un avertissement', (tester) async {
    final l = L10n.current;
    routes(devoirs: [devoir(1, 'Exercice 1')]);
    faux.repond('GET', '/institution/mock-exams/mine', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const MyHomeworkScreen());
    expect(find.text('Exercice 1'), findsOneWidget);
    expect(find.text(l.commonLoadError), findsOneWidget);
  });

  testWidgets('copie ecrite : texte exige, puis envoi et confirmation', (tester) async {
    final l = L10n.current;
    routes(devoirs: [devoir(1, 'Dissertation', enonce: 'Le bonheur est-il un droit ?')]);
    faux.repond('POST', '/student/assignments/1/submit', {'success': true});
    await monterEcran(tester, const MyHomeworkScreen());
    await tester.tap(find.text('Dissertation'));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.text('Le bonheur est-il un droit ?'), findsOneWidget);
    await tester.tap(find.text(l.hwSubmitCopy));
    await reseau(tester);
    expect(find.text(l.hwEmptyCopy), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ma reponse');
    await tester.tap(find.text(l.hwSubmitCopy));
    await reseau(tester);
    expect((faux.recues('POST', '/student/assignments/1/submit').single.data as Map)['content'], 'Ma reponse');
    expect(find.text(l.hwAlreadySubmitted), findsOneWidget);
  });

  testWidgets('devoir note : note et commentaire, pas de rendu', (tester) async {
    final l = L10n.current;
    routes(devoirs: [{...devoir(1, 'Exercice', rendu: true, note: 17), 'myComment': 'Bien'}]);
    await monterEcran(tester, const MyHomeworkScreen());
    await tester.tap(find.text('Exercice'));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.text(l.hwGrade('17', '20')), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);
    expect(find.text(l.hwSubmitCopy), findsNothing);
  });

  testWidgets('devoir quiz : le lecteur s\'ouvre rattache au devoir', (tester) async {
    final l = L10n.current;
    routes(devoirs: [devoir(1, 'Quiz derivees', quiz: 5)]);
    faux.repond('GET', '/quizzes/5', quizJson);
    await monterEcran(tester, const MyHomeworkScreen());
    await tester.tap(find.text('Quiz derivees'));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await tester.tap(find.text(l.hwTakeQuiz));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    final ecran = tester.widget<QuizActiveScreen>(find.byType(QuizActiveScreen));
    expect(ecran.assignmentId, 1);
    expect(ecran.homework, isTrue);
  });

  testWidgets('examen blanc ouvert : confirmation puis lecteur avec le temps restant', (tester) async {
    final l = L10n.current;
    routes(examens: [
      {'id': 7, 'title': 'Bac blanc', 'opensAt': dans(const Duration(hours: -1)), 'closesAt': dans(const Duration(minutes: 30)),
       'durationMinutes': 120, 'quizId': 5, 'status': 'open', 'published': false},
    ]);
    faux.repond('GET', '/quizzes/5', quizJson);
    await monterEcran(tester, const MyHomeworkScreen());
    await tester.tap(find.text('Bac blanc'));
    await reseau(tester);
    expect(find.text(l.hwMockStartTitle), findsOneWidget);
    await tester.tap(find.text(l.hwMockStart));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    final ecran = tester.widget<QuizActiveScreen>(find.byType(QuizActiveScreen));
    expect(ecran.timeLimitSeconds, lessThanOrEqualTo(30 * 60), reason: 'ferme dans 30 min, avant la fin des 120 min');
    expect(ecran.assignmentId, isNull);
  });

  group('QuizActiveScreen en mode devoir', () {
    const quiz = Quiz(id: '5', title: 'Derivees', subjectId: 'math', durationMinutes: 10, questions: [
      QuizQuestion('2 + 2 ?', ['3', '4'], 1, '', id: 'q1'),
    ]);

    Future<void> finir(WidgetTester tester) async {
      await tester.tap(find.text('4'));
      await pomper(tester);
      await tester.tap(find.widgetWithText(WinButton, L10n.current.studentQuizFinish));
      await pomper(tester);
      await reseau(tester);
    }

    testWidgets('la tentative part avec l\'identifiant du devoir', (tester) async {
      faux.repond('POST', '/quizzes/5/submit', {'score': 100});
      await monterEcran(tester, const QuizActiveScreen(quiz: quiz, homework: true, assignmentId: 1));
      await finir(tester);
      final d = faux.recues('POST', '/quizzes/5/submit').single.data as Map;
      expect(d['assignmentId'], 1);
      expect(find.byType(QuizResultScreen), findsOneWidget);
    });

    testWidgets('refus du serveur : son message, pas de faux resultat', (tester) async {
      faux.repond('POST', '/quizzes/5/submit', {'error': 'Examen ferme.'}, statut: 400);
      await monterEcran(tester, lanceur(const QuizActiveScreen(quiz: quiz, homework: true)));
      await ouvrir(tester);
      await finir(tester);
      expect(find.text('Examen ferme.'), findsOneWidget);
      expect(find.byType(QuizResultScreen), findsNothing);
    });

    testWidgets('temps impose : le chrono part de la limite donnee', (tester) async {
      await monterEcran(tester, const QuizActiveScreen(quiz: quiz, homework: true, timeLimitSeconds: 90));
      expect(find.text('01:30'), findsOneWidget);
    });
  });

  test('temps restant d\'un examen blanc : la duree, ou moins si la fermeture est plus proche', () {
    final now = DateTime(2026, 11, 25, 10);
    final e = ApiMockExam.fromJson({
      'id': 1, 'title': 'x', 'opensAt': now.toIso8601String(),
      'closesAt': now.add(const Duration(minutes: 30)).toIso8601String(), 'durationMinutes': 60, 'quizId': 1,
    });
    expect(e.remainingSeconds(now), 30 * 60);
    expect(e.remainingSeconds(now.subtract(const Duration(hours: 1))), 60 * 60);
    expect(e.remainingSeconds(now.add(const Duration(hours: 1))), 0);
  });
}
