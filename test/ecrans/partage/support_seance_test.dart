import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/tutor_session_material_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

/// Contenu genere par WinAI : un cours, deux questions de quiz, un exercice.
const _contenu = {
  'title': 'Les derivees',
  'objectives': ['Calculer une derivee'],
  'course': {
    'introduction': 'Introduction au calcul',
    'sections': [
      {'title': 'Definition', 'content': 'Le nombre derive...', 'example': 'f(x) = x2'},
    ],
    'summary': 'Retenir la formule',
    'keyPoints': ['Limite du taux'],
  },
  'quiz': [
    {
      'id': 'q1',
      'text': 'Derivee de x2 ?',
      'options': [
        {'id': 'a', 'text': '2x'},
        {'id': 'b', 'text': 'x'},
      ],
      'correctOptionId': 'a',
      'explanation': 'On abaisse l exposant',
    },
    {
      'id': 'q2',
      'text': 'Derivee d une constante ?',
      'options': [
        {'id': 'a', 'text': '0'},
        {'id': 'b', 'text': '1'},
      ],
      'correctOptionId': 'a',
    },
  ],
  'exercises': [
    {'id': 'e1', 'title': 'Exercice 1', 'statement': 'Deriver 3x', 'difficulty': 'facile', 'hints': ['Coefficient'], 'solution': '3'},
  ],
};

Map<String, dynamic> _vue([Map<String, dynamic> en = const {}]) => {
      'bookingId': 5,
      'viewerRole': 'tutor',
      'bookingStatus': 'confirmed',
      'subject': 'Maths',
      'topics': ['derivees'],
      'sessionDate': '2026-05-05',
      'startTime': '17:00',
      'endTime': '18:00',
      'durationMinutes': 60,
      'tutorName': 'Mme Ngo',
      'participantCount': 1,
      'participants': [
        {'userId': 3, 'name': 'Paul Eto'},
      ],
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  void servir(Map<String, dynamic> v) => faux.repond('GET', '/tutor-bookings/5/material', v);

  /// Ecran haut : tout le support est construit sans defilement.
  Future<void> monterSupport(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 5000);
    await monter(tester, ecran(const TutorSessionMaterialScreen(bookingId: 5)));
    await reseau(tester);
  }

  testWidgets('chargement puis en-tete : titre par defaut, horaire, eleve et sujets', (tester) async {
    servir(_vue({'canGenerate': true}));
    telephone(tester);
    await monter(tester, ecran(const TutorSessionMaterialScreen(bookingId: 5)));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.tutoringMaterial), findsOneWidget);
    expect(find.text(l.tutoringSession), findsOneWidget);
    expect(find.textContaining('17:00-18:00'), findsOneWidget);
    expect(find.text('${l.tutoringMatStudentPrefix}Paul Eto'), findsOneWidget);
    expect(find.text('derivees'), findsOneWidget);
  });

  testWidgets('introuvable : message du serveur, sinon message par defaut', (tester) async {
    faux.repond('GET', '/tutor-bookings/5/material', {'message': 'Plan insuffisant'}, statut: 403);
    await monterSupport(tester);
    expect(find.text('Plan insuffisant'), findsOneWidget);
    await monter(tester, const SizedBox());
    faux.repond('GET', '/tutor-bookings/5/material', {}, statut: 404);
    await monterSupport(tester);
    expect(find.text(L10n.current.tutoringMatNotFound), findsOneWidget);
  });

  group('Tuteur', () {
    testWidgets('sans support : consigne et « Generer avec WinAI » ; generation envoyee avec la consigne rognee', (tester) async {
      servir(_vue({'canGenerate': true}));
      faux.repond('POST', '/tutor-bookings/5/material/generate', _vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true, 'canEdit': true, 'canShare': true, 'solutionsIncluded': true}));
      await monterSupport(tester);
      final l = L10n.current;
      expect(find.widgetWithText(TextField, l.tutoringMatInstructionsHint), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, l.tutoringMatInstructionsHint), '  plus d exercices ');
      await tester.tap(_bouton(l.tutoringMatGenerate));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-bookings/5/material/generate').single.data, {'instructions': 'plus d exercices'});
      expect(find.text(l.tutoringMatGenerated), findsOneWidget);
      expect(find.text('Les derivees'), findsOneWidget);
      expect(find.text(l.commonDraft), findsOneWidget);
      expect(_bouton(l.tutoringMatRegenerate), findsOneWidget);
    });

    testWidgets('consigne vide : envoyee a null', (tester) async {
      servir(_vue({'canGenerate': true}));
      faux.repond('POST', '/tutor-bookings/5/material/generate', _vue({'exists': true, 'content': _contenu}));
      await monterSupport(tester);
      await tester.tap(_bouton(L10n.current.tutoringMatGenerate));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-bookings/5/material/generate').single.data, {'instructions': null});
    });

    testWidgets('regenerer : confirmation ; « Retour » n\'envoie rien', (tester) async {
      servir(_vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true}));
      faux.repond('POST', '/tutor-bookings/5/material/generate', _vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true}));
      await monterSupport(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringMatRegenerate));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.tutoringMatRegenerateConfirm), findsOneWidget);
      await tester.tap(find.text(l.commonBack));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(faux.recues('POST', '/tutor-bookings/5/material/generate'), isEmpty);
      await tester.tap(_bouton(l.tutoringMatRegenerate));
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text(l.commonContinue));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-bookings/5/material/generate'), hasLength(1));
    });

    testWidgets('generation refusee (budget WinAI) : message du serveur', (tester) async {
      servir(_vue({'canGenerate': true}));
      faux.repond('POST', '/tutor-bookings/5/material/generate', {'error': 'Budget WinAI epuise'}, statut: 402);
      await monterSupport(tester);
      await tester.tap(_bouton(L10n.current.tutoringMatGenerate));
      await reseau(tester);
      expect(find.text('Budget WinAI epuise'), findsOneWidget);
    });

    testWidgets('partager : premiere version puis nouvelle version ; badges selon l\'etat', (tester) async {
      servir(_vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true, 'canShare': true}));
      faux.repond('POST', '/tutor-bookings/5/material/share', _vue({'exists': true, 'status': 'shared', 'sharedVersion': 1, 'content': _contenu, 'canGenerate': true}));
      await monterSupport(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringMatShare));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-bookings/5/material/share'), hasLength(1));
      expect(find.text(l.tutoringMatSharedToast), findsOneWidget);
      expect(find.text(l.tutoringMatShared), findsOneWidget);

      await monter(tester, const SizedBox());
      servir(_vue({'exists': true, 'status': 'shared_with_changes', 'hasUnsharedChanges': true, 'sharedVersion': 1, 'content': _contenu, 'canGenerate': true, 'canShare': true}));
      await monterSupport(tester);
      expect(find.text(l.tutoringMatChanged), findsOneWidget);
      expect(_bouton(l.tutoringMatShareNew), findsOneWidget);
    });

    testWidgets('modifier : editeur, « Annuler » revient ; « Enregistrer » envoie le contenu', (tester) async {
      servir(_vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true, 'canEdit': true}));
      faux.repond('PUT', '/tutor-bookings/5/material', _vue({'exists': true, 'status': 'draft', 'content': _contenu, 'canGenerate': true, 'canEdit': true}));
      await monterSupport(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.commonEdit));
      await pomper(tester);
      expect(find.text(l.tutoringMatEditTitle), findsOneWidget);
      await tester.tap(_bouton(l.commonCancel));
      await pomper(tester);
      expect(find.text(l.tutoringMatEditTitle), findsNothing);
      await tester.tap(_bouton(l.commonEdit));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringMatSaveDraft));
      await reseau(tester);
      final envoi = faux.recues('PUT', '/tutor-bookings/5/material').single.data as Map;
      expect((envoi['content'] as Map)['title'], 'Les derivees');
      expect(find.text(l.tutoringMatDraftSaved), findsOneWidget);
      expect(find.text(l.tutoringMatEditTitle), findsNothing);
    });

    testWidgets('cours affiche : objectifs, partie, exemple, a retenir, quiz et exercice avec corrige', (tester) async {
      servir(_vue({'exists': true, 'status': 'draft', 'content': _contenu, 'solutionsIncluded': true}));
      await monterSupport(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringMatCourse), findsOneWidget);
      expect(find.text('• Calculer une derivee'), findsOneWidget);
      expect(find.text(l.tutoringMatExample('f(x) = x2')), findsOneWidget);
      expect(find.text(l.tutoringMatSummary), findsOneWidget);
      expect(find.text(l.tutoringMatQuizCount(2)), findsOneWidget);
      expect(find.text('1. Derivee de x2 ?'), findsOneWidget);
      expect(find.text('On abaisse l exposant'), findsOneWidget);
      expect(find.text(l.tutoringMatEasy), findsOneWidget);
      expect(find.text(l.tutoringMatSolution('3')), findsOneWidget);
      // Bonne reponse marquee.
      expect(find.byIcon(PhosphorIconsFill.checkCircle), findsNWidgets(2));
    });

    testWidgets('reponses des eleves : note, detail par question, reponse d\'exercice et eleves en attente', (tester) async {
      servir(_vue({
        'exists': true,
        'status': 'shared',
        'sharedVersion': 1,
        'content': _contenu,
        'participantCount': 2,
        'participants': [
          {'userId': 3, 'name': 'Paul Eto'},
          {'userId': 4, 'name': 'Zoe Eto'},
        ],
        'results': [
          {
            'studentUserId': 3,
            'studentName': 'Paul Eto',
            'quizScore': 1,
            'quizTotal': 2,
            'questions': [
              {'questionId': 'q1', 'answer': 'a', 'isCorrect': true},
              {'questionId': 'q2', 'answer': 'b', 'isCorrect': false},
            ],
            'exerciseAnswers': {'e1': '3'},
          },
        ],
      }));
      await monterSupport(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringMatStudentAnswers), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('1 ✓  2 ✗'), findsOneWidget);
      expect(find.text(l.tutoringMatAnswerLine('Exercice 1', '3')), findsOneWidget);
      expect(find.text(l.tutoringMatNotYet('Zoe Eto')), findsOneWidget);
    });

    testWidgets('partage sans reponse : « Aucune reponse pour l\'instant »', (tester) async {
      servir(_vue({'exists': true, 'status': 'shared', 'sharedVersion': 1, 'content': _contenu}));
      await monterSupport(tester);
      expect(find.text(L10n.current.tutoringMatNoAnswer), findsOneWidget);
    });
  });

  group('Eleve et payeur', () {
    testWidgets('eleve sans support partage : alerte « pas encore partage »', (tester) async {
      servir(_vue({'viewerRole': 'participant'}));
      await monterSupport(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringMatNotShared), findsOneWidget);
      expect(find.textContaining(l.tutoringWithName('Mme Ngo')), findsOneWidget);
      expect(_bouton(l.tutoringMatGenerate), findsNothing);
    });

    testWidgets('raison de blocage affichee a la place de l\'alerte', (tester) async {
      servir(_vue({'viewerRole': 'participant', 'blockedReason': 'Seance annulee'}));
      await monterSupport(tester);
      expect(find.text('Seance annulee'), findsOneWidget);
      expect(find.text(L10n.current.tutoringMatNotShared), findsNothing);
    });

    testWidgets('payeur : consultation seule', (tester) async {
      servir(_vue({'viewerRole': 'payer', 'exists': true, 'status': 'shared', 'content': _contenu}));
      await monterSupport(tester);
      expect(find.text(L10n.current.tutoringMatReadOnly), findsOneWidget);
      expect(_bouton(L10n.current.tutoringMatSubmit), findsNothing);
    });

    testWidgets('eleve : repond au quiz et a l\'exercice puis envoie', (tester) async {
      servir(_vue({'viewerRole': 'participant', 'exists': true, 'status': 'shared', 'content': _contenu, 'canSubmit': true}));
      faux.repond('POST', '/tutor-bookings/5/material/submit', _vue({'viewerRole': 'participant', 'exists': true, 'content': _contenu}));
      await monterSupport(tester);
      final l = L10n.current;
      await tester.tap(find.text('2x'));
      await pomper(tester);
      await tester.tap(find.text('0'));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, l.tutoringMatYourAnswerHint), '  3 ');
      await tester.tap(_bouton(l.tutoringMatSubmit));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-bookings/5/material/submit').single.data, {
        'quizAnswers': {'q1': 'a', 'q2': 'a'},
        'exerciseAnswers': {'e1': '3'},
      });
      expect(find.text(l.tutoringMatAnswersSent), findsOneWidget);
    });

    testWidgets('questions sans reponse : confirmation ; « Retour » n\'envoie rien', (tester) async {
      servir(_vue({'viewerRole': 'participant', 'exists': true, 'status': 'shared', 'content': _contenu, 'canSubmit': true}));
      await monterSupport(tester);
      final l = L10n.current;
      await tester.tap(find.text('2x'));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringMatSubmit));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.tutoringMatUnanswered(1)), findsOneWidget);
      await tester.tap(find.text(l.commonBack));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(faux.recues('POST', '/tutor-bookings/5/material/submit'), isEmpty);
    });

    testWidgets('apres envoi : note du quiz dans le titre et reponse d\'exercice rappelee', (tester) async {
      servir(_vue({
        'viewerRole': 'participant',
        'exists': true,
        'status': 'shared',
        'sharedVersion': 1,
        'content': _contenu,
        'solutionsIncluded': true,
        'myResult': {
          'studentUserId': 3,
          'quizScore': 1,
          'quizTotal': 2,
          'questions': [
            {'questionId': 'q1', 'answer': 'a', 'isCorrect': true},
            {'questionId': 'q2', 'answer': 'b', 'isCorrect': false},
          ],
          'exerciseAnswers': {'e1': '4'},
        },
        'results': [
          {'studentUserId': 3, 'quizScore': 1, 'quizTotal': 2},
        ],
      }));
      await monterSupport(tester);
      final l = L10n.current;
      expect(find.text('Quiz · 1/2'), findsOneWidget);
      expect(find.text(l.tutoringMatYourAnswer('4')), findsOneWidget);
      // Mauvaise reponse a la question 2 : croix rouge.
      expect(find.byIcon(PhosphorIconsFill.xCircle), findsOneWidget);
      expect(find.text(l.tutoringMatResults), findsOneWidget);
    });
  });
}
