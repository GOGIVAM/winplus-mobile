import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/student/quiz_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

const _quiz = Quiz(
  id: '3',
  title: 'Calcul mental',
  subjectId: 'math',
  durationMinutes: 1,
  questions: [
    QuizQuestion('2 + 2 ?', ['3', '4', '5'], 1, 'Parce que 2 + 2 = 4', id: 'q1'),
    QuizQuestion('3 x 3 ?', ['6', '9'], 1, 'Neuf', id: 'q2'),
  ],
);

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.studentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.studentDashboard.clear();
  });

  Future<void> repondre(WidgetTester tester, String option) async {
    await tester.tap(find.text(option));
    await pomper(tester);
  }

  group('QuizActiveScreen', () {
    testWidgets('premiere question : titre, compteur, minuteur, options lettrees et bouton « Suivant » inactif', (tester) async {
      await monterEcran(tester, const QuizActiveScreen(quiz: _quiz));
      final l = L10n.current;
      expect(find.text('Calcul mental'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text(l.studentQuizCounter(1, 2)), findsOneWidget);
      expect(find.text('2 + 2 ?'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.authNext)).onTap, isNull);
      await monter(tester, const SizedBox());
    });

    testWidgets('choisir une option active « Suivant » ; la derniere question propose « Terminer »', (tester) async {
      await monterEcran(tester, const QuizActiveScreen(quiz: _quiz));
      await repondre(tester, '4');
      expect(tester.widget<WinButton>(_bouton(L10n.current.authNext)).onTap, isNotNull);
      await tester.tap(_bouton(L10n.current.authNext));
      await pomper(tester);
      expect(find.text(L10n.current.studentQuizCounter(2, 2)), findsOneWidget);
      expect(_bouton(L10n.current.studentQuizFinish), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.studentQuizFinish)).onTap, isNull);
      await monter(tester, const SizedBox());
    });

    testWidgets('le minuteur decompte', (tester) async {
      await monterEcran(tester, const QuizActiveScreen(quiz: _quiz));
      await pomper(tester, const Duration(seconds: 5));
      expect(find.text('00:55'), findsOneWidget);
      await monter(tester, const SizedBox());
    });

    testWidgets('quiz termine avec deux bonnes reponses : resultat 100 %, envoi de la tentative au serveur', (tester) async {
      faux.repond('POST', '/quizzes/3/submit', {'score': 100});
      await monterEcran(tester, const QuizActiveScreen(quiz: _quiz));
      await repondre(tester, '4');
      await tester.tap(_bouton(L10n.current.authNext));
      await pomper(tester);
      await repondre(tester, '9');
      await tester.tap(_bouton(L10n.current.studentQuizFinish));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      await reseau(tester);
      final l = L10n.current;
      expect(find.byType(QuizResultScreen), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text(l.studentQuizExcellent), findsOneWidget);
      final d = faux.recues('POST', '/quizzes/3/submit').single.data as Map;
      expect(d['answers'], [
        {'questionId': 'q1', 'answer': '4'},
        {'questionId': 'q2', 'answer': '9'},
      ]);
      expect(d['timeSpentSeconds'], isA<int>());
    });

    testWidgets('temps ecoule : la tentative est terminee d\'office, reponses vides envoyees comme chaines vides', (tester) async {
      faux.repond('POST', '/quizzes/3/submit', {});
      await monterEcran(tester, const QuizActiveScreen(quiz: _quiz));
      await pomper(tester, const Duration(seconds: 62));
      await pomper(tester, const Duration(milliseconds: 500));
      await reseau(tester);
      expect(find.byType(QuizResultScreen), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text(L10n.current.studentQuizToImprove), findsOneWidget);
      final d = faux.recues('POST', '/quizzes/3/submit').single.data as Map;
      expect(d['answers'], [
        {'questionId': 'q1', 'answer': ''},
        {'questionId': 'q2', 'answer': ''},
      ]);
      expect(d['timeSpentSeconds'], 60);
    });

    testWidgets('examen de formation : un refus 423 ferme l\'ecran avec le resultat « paused »', (tester) async {
      faux.repond('POST', '/quizzes/3/submit', {}, statut: 423);
      Object? resultat;
      await monterEcran(tester, lanceur(const QuizActiveScreen(quiz: _quiz, courseExam: true), surResultat: (r) => resultat = r));
      await ouvrir(tester);
      await repondre(tester, '4');
      await tester.tap(_bouton(L10n.current.authNext));
      await pomper(tester);
      await repondre(tester, '9');
      await tester.tap(_bouton(L10n.current.studentQuizFinish));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(resultat, 'paused');
      expect(find.byType(QuizResultScreen), findsNothing);
    });

    testWidgets('la croix ferme le quiz sans envoyer de tentative', (tester) async {
      await monterEcran(tester, lanceur(const QuizActiveScreen(quiz: _quiz)));
      await ouvrir(tester);
      await tester.tap(find.byIcon(Icons.close));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(QuizActiveScreen), findsNothing);
      expect(faux.recues('POST', '/quizzes/3/submit'), isEmpty);
    });
  });

  group('QuizResultScreen et QuizReviewScreen', () {
    const bon = QuizResult(quizId: '3', quizTitle: 'Calcul mental', correct: 2, total: 2, durationSeconds: 75, answers: [1, 1], date: 'maintenant');
    const moyen = QuizResult(quizId: '3', quizTitle: 'Calcul mental', correct: 1, total: 2, durationSeconds: 5, answers: [1, 0], date: 'maintenant');

    testWidgets('score, corrects, incorrects et duree', (tester) async {
      await monterEcran(tester, const QuizResultScreen(result: moyen, quiz: _quiz));
      final l = L10n.current;
      expect(find.text('50%'), findsOneWidget);
      expect(find.text(l.studentQuizGoodWork), findsOneWidget);
      expect(find.text(l.studentQuizCorrect), findsOneWidget);
      expect(find.text('0m 5s'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
    });

    testWidgets('duree minutes et secondes', (tester) async {
      await monterEcran(tester, const QuizResultScreen(result: bon, quiz: _quiz));
      expect(find.text('1m 15s'), findsOneWidget);
      expect(find.text(L10n.current.studentQuizExcellent), findsOneWidget);
    });

    testWidgets('« Revoir mes reponses » : bonne reponse en vert, mauvaise choisie en erreur, explication', (tester) async {
      await monterEcran(tester, const QuizResultScreen(result: moyen, quiz: _quiz));
      await tester.tap(_bouton(L10n.current.studentQuizReviewAnswers));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(QuizReviewScreen), findsOneWidget);
      expect(find.text('1. 2 + 2 ?'), findsOneWidget);
      expect(find.text('Parce que 2 + 2 = 4'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.cancel), findsOneWidget, reason: 'seule la reponse « 6 » a la question 2 est fausse');
    });

    testWidgets('« Refaire » relance le quiz', (tester) async {
      await monterEcran(tester, const QuizResultScreen(result: moyen, quiz: _quiz));
      await tester.tap(_bouton(L10n.current.studentQuizRetake));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(QuizActiveScreen), findsOneWidget);
      await monter(tester, const SizedBox());
    });
  });

  group('QuizHubScreen', () {
    testWidgets('liste des quiz : titre et meta (questions, duree)', (tester) async {
      faux.repond('GET', '/quizzes', [
        {'id': 1, 'title': 'Quiz algebre', 'durationMinutes': 20, 'questions': [{'id': 'a', 'questionText': 'Q', 'options': ['x', 'y']}]},
      ]);
      telephone(tester);
      await monter(tester, ecran(const QuizHubScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      expect(find.text(L10n.current.studentQuizAvailable), findsOneWidget);
      expect(find.text('Quiz algebre'), findsOneWidget);
      expect(find.text(L10n.current.studentQuizMeta(1, 20)), findsOneWidget);
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 20});
    });

    testWidgets('aucun quiz : message dedie', (tester) async {
      faux.repond('GET', '/quizzes', []);
      await monterEcran(tester, const QuizHubScreen());
      expect(find.text(L10n.current.studentQuizNone), findsOneWidget);
    });

    testWidgets('toucher un quiz l\'ouvre ; actualiser relit la liste', (tester) async {
      faux.repond('GET', '/quizzes', [
        {'id': 1, 'title': 'Quiz algebre', 'questions': [{'id': 'a', 'questionText': 'Quelle est la reponse ?', 'options': ['x', 'y']}]},
      ]);
      await monterEcran(tester, const QuizHubScreen());
      await tester.tap(find.byIcon(Icons.refresh_outlined));
      await reseau(tester);
      expect(faux.recues('GET', '/quizzes'), hasLength(2));
      await tester.tap(find.text('Quiz algebre'));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(QuizActiveScreen), findsOneWidget);
      expect(find.text('Quelle est la reponse ?'), findsOneWidget);
      await monter(tester, const SizedBox());
    });
  });
}
