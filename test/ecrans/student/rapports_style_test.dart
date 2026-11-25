import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/learning_style_quiz_screen.dart';
import 'package:winplus/student/student_reports_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    // Section « Parmi les élèves » de Mes rapports (lot 7).
    faux.repond('GET', '/student/peer-comparison', {'hasData': false});
  });

  group('StudentReportsScreen', () {
    Map<String, dynamic> rapport({int period = 30, bool vide = false}) => {
          'data': vide
              ? {'periodDays': period, 'avgScore': null, 'quizTotal': 0, 'quizSuccessRate': null, 'studyHours': 0, 'downloads': 0, 'subjectScores': [], 'weeklyScores': [], 'bestSubject': null, 'weakestSubject': null}
              : {
                  'periodDays': period,
                  'avgScore': 68,
                  'quizTotal': 12,
                  'quizSuccessRate': 75,
                  'studyHours': 6.4,
                  'downloads': 3,
                  'subjectScores': [
                    {'subject': 'Mathematiques', 'score': 82, 'quizzes': 7},
                    {'subject': 'Chimie', 'score': 49, 'quizzes': 5},
                  ],
                  'weeklyScores': [
                    {'weekStart': '2026-11-03T00:00:00Z', 'score': null, 'quizzes': 0},
                    {'weekStart': '2026-11-10T00:00:00Z', 'score': 61, 'quizzes': 4},
                    {'weekStart': '2026-11-17T00:00:00Z', 'score': 72, 'quizzes': 8},
                  ],
                  'bestSubject': 'Mathematiques',
                  'weakestSubject': 'Chimie',
                },
          'success': true,
        };

    testWidgets('chiffres du serveur : moyenne, matieres, quiz, etude, telechargements', (tester) async {
      faux.sur('GET', '/student/reports', (o) => FauxReponse(rapport(period: o.queryParameters['period'] as int)));
      telephone(tester);
      tester.view.physicalSize = const Size(800, 3200);
      await monter(tester, ecran(const StudentReportsScreen()));
      await reseau(tester);
      final l = L10n.current;
      expect(faux.recues('GET', '/student/reports').single.queryParameters, {'period': 30});
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('Mathematiques'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('6'), findsOneWidget, reason: 'heures d\'etude arrondies');
      expect(find.text(l.studentReportsBest('Mathematiques')), findsOneWidget);
      expect(find.text(l.studentReportsWeakest('Chimie')), findsOneWidget);
      expect(find.text('—'), findsOneWidget, reason: 'semaine sans quiz');
      expect(find.text(l.studentReportsPlanRequired), findsNothing, reason: 'aucune restriction inventee');
    });

    testWidgets('changer de periode relit le rapport du serveur', (tester) async {
      faux.sur('GET', '/student/reports', (o) => FauxReponse(rapport(period: o.queryParameters['period'] as int)));
      await monterEcran(tester, const StudentReportsScreen());
      await tester.tap(find.text(L10n.current.studentReportsPeriod7));
      await reseau(tester);
      final periodes = faux.recues('GET', '/student/reports').map((o) => o.queryParameters['period']).toList();
      expect(periodes, [30, 7]);
    });

    testWidgets('aucun quiz sur la periode : « — » et message, pas de chiffre invente', (tester) async {
      faux.repond('GET', '/student/reports', rapport(vide: true));
      await monterEcran(tester, const StudentReportsScreen());
      expect(find.text('—'), findsWidgets);
      expect(find.text(L10n.current.studentReportsNoData), findsOneWidget);
      expect(find.text(L10n.current.studentReportsBySubject), findsNothing);
    });

    testWidgets('serveur en erreur : message et « Reessayer »', (tester) async {
      faux.repond('GET', '/student/reports', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const StudentReportsScreen());
      expect(find.text(L10n.current.studentReportsLoadError), findsOneWidget);
      faux.sur('GET', '/student/reports', (o) => FauxReponse(rapport()));
      await tester.tap(find.text(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text('68%'), findsOneWidget);
    });
  });

  group('LearningStyleQuizScreen', () {
    Future<void> repondreToutes(WidgetTester tester) async {
      final l = L10n.current;
      final auditives = [l.studentVarkQ1A, l.studentVarkQ2A, l.studentVarkQ3A, l.studentVarkQ4A, l.studentVarkQ5A, l.studentVarkQ6A];
      for (final t in auditives) {
        await tester.tap(find.text(t));
        await pomper(tester);
      }
      await reseau(tester);
    }

    testWidgets('premiere question, progression et quatre reponses', (tester) async {
      await monterEcran(tester, const LearningStyleQuizScreen());
      final l = L10n.current;
      expect(find.text(l.studentVarkQuestionCount(1, 6)), findsOneWidget);
      expect(find.text(l.studentVarkQ1), findsOneWidget);
      expect(find.text(l.studentVarkQ1V), findsOneWidget);
      expect(find.text(l.studentVarkQ1K), findsOneWidget);
    });

    testWidgets('chaque reponse passe a la question suivante', (tester) async {
      await monterEcran(tester, const LearningStyleQuizScreen());
      await tester.tap(find.text(L10n.current.studentVarkQ1V));
      await pomper(tester);
      expect(find.text(L10n.current.studentVarkQuestionCount(2, 6)), findsOneWidget);
      expect(find.text(L10n.current.studentVarkQ2), findsOneWidget);
    });

    testWidgets('apres six reponses : le style renvoye par le serveur est affiche', (tester) async {
      faux.repond('POST', '/ai/learning-style', {'style': 'kinesthetic'});
      await monterEcran(tester, const LearningStyleQuizScreen());
      await repondreToutes(tester);
      final d = (faux.requetes.single.data as Map)['answers'] as List;
      expect(d, hasLength(6));
      expect(d.first, {'question_id': 'q1', 'style_tag': 'A'});
      expect(find.text(L10n.current.studentVarkKinesthetic), findsOneWidget);
      expect(find.text(L10n.current.studentVarkSaved), findsOneWidget);
    });

    testWidgets('serveur indisponible : calcul local, six « A » = style auditif', (tester) async {
      await monterEcran(tester, const LearningStyleQuizScreen());
      await repondreToutes(tester);
      expect(find.text(L10n.current.studentVarkAuditory), findsOneWidget);
    });

    testWidgets('« Appliquer » enregistre le style sur le profil', (tester) async {
      faux.repond('POST', '/ai/learning-style', {'style': 'visual'});
      faux.repond('PUT', '/users/profile', {});
      await monterEcran(tester, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const LearningStyleQuizScreen())), child: const Text('go')))));
      await tester.tap(find.text('go'));
      // Premiere image de la page poussee : hors scene ; la suivante l'affiche.
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      await repondreToutes(tester);
      await tester.tap(find.widgetWithText(WinButton, L10n.current.studentVarkApply));
      await reseau(tester);
      expect(faux.recues('PUT', '/users/profile').single.data, {'learningStyle': 'visual'});
      await pomper(tester, const Duration(milliseconds: 800));
      expect(find.byType(LearningStyleQuizScreen), findsNothing, reason: 'l\'ecran se ferme apres l\'application');
    });
  });
}
