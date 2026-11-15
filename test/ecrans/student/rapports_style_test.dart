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

  setUp(() => faux = preparerEnvironnement());

  group('StudentReportsScreen', () {
    testWidgets('score moyen calcule sur les cinq matieres (84, 71, 52, 79, 66 = 70 %)', (tester) async {
      await monterEcran(tester, const StudentReportsScreen());
      expect(find.text('70%'), findsOneWidget);
      expect(find.text(L10n.current.studentReportsAvgScore), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);
      expect(find.text('52%'), findsOneWidget);
    });

    testWidgets('matieres triees de la meilleure a la plus faible', (tester) async {
      await monterEcran(tester, const StudentReportsScreen());
      final maths = tester.getTopLeft(find.text(L10n.current.dataSubjectMathShort)).dy;
      final chimie = tester.getTopLeft(find.text(L10n.current.dataSubjectChemistry)).dy;
      expect(maths, lessThan(chimie));
    });

    testWidgets('periode 7 jours : pas d\'avertissement de plan ; autre periode : avertissement', (tester) async {
      await monterEcran(tester, const StudentReportsScreen());
      expect(find.text(L10n.current.studentReportsPlanRequired), findsNothing);
      await tester.tap(find.text(L10n.current.studentReportsPeriod30));
      await pomper(tester);
      expect(find.text(L10n.current.studentReportsPlanRequired), findsOneWidget);
      await tester.tap(find.text(L10n.current.studentReportsPeriod7));
      await pomper(tester);
      expect(find.text(L10n.current.studentReportsPlanRequired), findsNothing);
    });

    testWidgets('sept barres hebdomadaires et totaux de quiz', (tester) async {
      await monterEcran(tester, const StudentReportsScreen());
      await tester.scrollUntilVisible(find.text(L10n.current.studentReportsQuizDone), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('74%'), findsWidgets);
      expect(find.text(L10n.current.studentReportsWeekShort(7)), findsOneWidget);
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
