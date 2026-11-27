import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/study_session_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _demonter(WidgetTester tester) => monter(tester, const SizedBox());

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement(prefs: {'user_id': 7});
    // Épreuves de la matière choisie (doublon de titre retiré à l'affichage).
    faux.repond('GET', '/subjects', {
      'items': [
        {'id': 1, 'title': 'Bac C 2022'},
        {'id': 2, 'title': 'Probatoire 2021'},
        {'id': 3, 'title': 'Bac C 2022'},
      ],
    });
  });

  /// Matière choisie dans le sélecteur commun (puce « Maths »).
  Future<void> choisirMaths(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(WinChip, 'Maths'));
    await reseau(tester);
  }

  void sessionOk() {
    faux.repond('POST', '/ai/study-session/generate', {
      'subject': {'id': 1, 'name': 'Maths', 'category': 'Sciences'},
      'duration_minutes': 25,
      'briefing': 'Aujourd\'hui, on revoit les fractions.',
    });
    faux.repond('POST', '/ai/study-session/phase2/quiz', {
      'phase2': {
        'questions': [
          {'question': '1/2 + 1/2 ?', 'options': ['1', '2'], 'correct': '1', 'explanation': 'Une moitie plus une moitie'},
          {'question': '1/4 x 4 ?', 'options': ['1', '4'], 'correct': '1', 'explanation': 'Quatre quarts'},
        ],
      },
    });
  }

  Future<void> lancer(WidgetTester tester) async {
    await tester.tap(_bouton(L10n.current.studentSessionStart));
    await reseau(tester);
  }

  group('Lanceur', () {
    testWidgets('matiere au selecteur commun, puis sujets de cette matiere sans doublon, premier choisi', (tester) async {
      await monterEcran(tester, const StudySessionScreen());
      final l = L10n.current;
      expect(find.text(l.studentSessionIntro), findsOneWidget);
      expect(faux.recues('GET', '/subjects'), isEmpty, reason: 'rien a charger avant le choix de la matiere');
      for (final d in [15, 25, 45, 60]) {
        expect(find.text(WinFormat.duration(d)), findsOneWidget);
      }
      await choisirMaths(tester);
      expect(faux.recues('GET', '/subjects').single.queryParameters['category'], 'Mathématiques');
      expect(find.text('Bac C 2022'), findsOneWidget, reason: 'doublon retire');
      expect(find.text('Probatoire 2021'), findsOneWidget);
      expect(tester.widget<WinChip>(find.widgetWithText(WinChip, WinFormat.duration(25))).active, isTrue);
    });

    testWidgets('sans matiere choisie : demarrer demande de choisir ; matiere sans sujet : avertissement', (tester) async {
      await monterEcran(tester, const StudySessionScreen());
      await lancer(tester);
      expect(find.text(L10n.current.studentSessionPickSubject), findsOneWidget);
      expect(faux.recues('POST', '/ai/study-session/generate'), isEmpty);
      faux.repond('GET', '/subjects', {'items': []});
      await choisirMaths(tester);
      expect(find.text(L10n.current.studentSessionNoSubjects), findsOneWidget);
    });

    testWidgets('echec du demarrage : message d erreur, on reste sur le lanceur', (tester) async {
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      expect(find.text(L10n.current.studentSessionStartError), findsOneWidget);
      expect(_bouton(L10n.current.studentSessionStart), findsOneWidget);
    });
  });

  group('Parcours en trois phases', () {
    testWidgets('briefing : matiere, minuteur, etapes et texte du serveur ; la matiere et la duree choisies sont envoyees', (tester) async {
      sessionOk();
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await tester.tap(find.text('Probatoire 2021'));
      await tester.tap(find.text(WinFormat.duration(45)));
      await pomper(tester);
      await lancer(tester);
      final l = L10n.current;
      expect(faux.recues('POST', '/ai/study-session/generate').single.data, {'user_id': 7, 'subject_id': 2, 'duration_minutes': 45});
      expect(find.text('Aujourd\'hui, on revoit les fractions.'), findsOneWidget);
      expect(find.text('Maths'), findsOneWidget, reason: 'la matiere renvoyee par le serveur s\'affiche');
      expect(find.text(l.studentSessionStepBriefing), findsOneWidget);
      expect(find.text(l.studentSessionStepQuiz), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('le minuteur decompte pendant la session', (tester) async {
      sessionOk();
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      await pomper(tester, const Duration(seconds: 3));
      expect(find.text('24:57'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('parcours complet : quiz, bonne et mauvaise reponse, synthese, cloture et ecran final', (tester) async {
      sessionOk();
      faux.repond('POST', '/ai/study-session/phase3/summary', {
        'phase3': {'summary': 'Bon travail sur les fractions', 'keypoints': ['Additionner', 'Simplifier'], 'performance_comment': 'Continue'},
      });
      faux.repond('POST', '/ai/study-session/complete', {});
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.studentDetailStartQuiz));
      await reseau(tester);
      expect(find.text(l.studentVarkQuestionCount(1, 2)), findsOneWidget);
      await tester.tap(find.text('1'));
      await pomper(tester);
      expect(find.text('Une moitie plus une moitie'), findsOneWidget);
      await tester.tap(find.text('2'));
      await pomper(tester);
      await tester.tap(_bouton(l.studentSessionNextQuestion));
      await pomper(tester);
      expect(find.text(l.studentVarkQuestionCount(2, 2)), findsOneWidget);
      await tester.tap(find.text('4'));
      await pomper(tester);
      expect(find.text('Quatre quarts'), findsOneWidget);
      await tester.tap(_bouton(l.studentSessionSeeSummary));
      await reseau(tester);
      // Une reponse revelee est verrouillee : le second toucher sur « 2 »
      // ne change plus la bonne reponse « 1 ». Une sur deux : 50 %.
      expect(faux.recues('POST', '/ai/study-session/phase3/summary').single.data, {'user_id': 7, 'subject_id': 1, 'score': 50.0});
      expect(find.text(l.studentSessionScoreLine(1, 2, '10/20')), findsOneWidget);
      expect(find.text('Bon travail sur les fractions'), findsOneWidget);
      expect(find.text('Simplifier'), findsOneWidget);
      await tester.tap(_bouton(l.studentSessionFinish));
      await reseau(tester);
      final d = faux.recues('POST', '/ai/study-session/complete').single.data as Map;
      expect(d['key_points'], ['Additionner', 'Simplifier']);
      expect(d['duration_minutes'], 25);
      expect(find.text(l.studentSessionDone), findsOneWidget);
      expect(find.text(l.studentSessionDoneScore('10/20', 'Maths')), findsOneWidget);
    });

    testWidgets('un clic apres la reponse n\'en change pas le resultat ; deux bonnes reponses = score de 100', (tester) async {
      sessionOk();
      faux.repond('POST', '/ai/study-session/phase3/summary', {'phase3': {'summary': 'S'}});
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.studentDetailStartQuiz));
      await reseau(tester);
      await tester.tap(find.text('1'));
      await pomper(tester);
      await tester.tap(find.text('2'));
      await pomper(tester);
      await tester.tap(_bouton(l.studentSessionNextQuestion));
      await pomper(tester);
      await tester.tap(find.text('1'));
      await pomper(tester);
      await tester.tap(_bouton(l.studentSessionSeeSummary));
      await reseau(tester);
      expect(find.text(l.studentSessionScoreLine(2, 2, '20/20')), findsOneWidget);
    });

    testWidgets('quiz indisponible (liste vide) : retour au briefing avec message', (tester) async {
      faux.repond('POST', '/ai/study-session/generate', {'subject': {'id': 1, 'name': 'Maths'}, 'briefing': 'B'});
      faux.repond('POST', '/ai/study-session/phase2/quiz', {});
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      await tester.tap(_bouton(L10n.current.studentDetailStartQuiz));
      await reseau(tester);
      expect(find.text(L10n.current.studentSessionQuizError), findsOneWidget);
      expect(_bouton(L10n.current.studentDetailStartQuiz), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('synthese indisponible : avertissement mais la session peut etre terminee', (tester) async {
      sessionOk();
      faux.repond('POST', '/ai/study-session/complete', {});
      await monterEcran(tester, const StudySessionScreen());
      await choisirMaths(tester);
      await lancer(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.studentDetailStartQuiz));
      await reseau(tester);
      await tester.tap(find.text('1'));
      await pomper(tester);
      await tester.tap(_bouton(l.studentSessionNextQuestion));
      await pomper(tester);
      await tester.tap(find.text('1'));
      await pomper(tester);
      await tester.tap(_bouton(l.studentSessionSeeSummary));
      await reseau(tester);
      expect(find.text(l.studentSessionSummaryError), findsOneWidget);
      await tester.tap(_bouton(l.studentSessionFinish));
      await reseau(tester);
      expect(find.text(l.studentSessionDone), findsOneWidget);
    });
  });

  group('Historique', () {
    testWidgets('lignes : matiere, duree, note ou « sans note », et retour au lanceur', (tester) async {
      faux.repond('GET', '/ai/study-session/history', [
        {'id': 1, 'subject': 'Maths', 'duration': 25, 'score': 80, 'completedAt': '2026-01-05T10:00:00'},
        {'id': 2, 'subject': 'Physique', 'duration': 15},
      ]);
      await monterEcran(tester, const StudySessionScreen());
      await tester.tap(find.text(L10n.current.studentSessionHistory));
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.studentSessionHistoryLine('25 min', '16/20', '05/01/2026')), findsOneWidget);
      expect(find.text(l.studentSessionHistoryLine('15 min', l.studentSessionNoScore, '')), findsOneWidget);
      await tester.tap(find.byIcon(PhosphorIconsRegular.x));
      await pomper(tester);
      expect(_bouton(l.studentSessionStart), findsOneWidget);
    });

    testWidgets('historique vide ou en erreur', (tester) async {
      faux.repond('GET', '/ai/study-session/history', []);
      await monterEcran(tester, const StudySessionScreen());
      await tester.tap(find.text(L10n.current.studentSessionHistory));
      await reseau(tester);
      expect(find.text(L10n.current.studentSessionNoHistory), findsOneWidget);
    });

    testWidgets('erreur serveur sur l\'historique : message de chargement', (tester) async {
      faux.repond('GET', '/ai/study-session/history', {}, statut: 500);
      await monterEcran(tester, const StudySessionScreen());
      await tester.tap(find.text(L10n.current.studentSessionHistory));
      await reseau(tester);
      expect(find.text(L10n.current.studentHistLoadError), findsOneWidget);
    });
  });
}
