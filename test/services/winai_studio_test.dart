import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/quiz_service.dart';
import 'package:winplus/services/winai_studio_service.dart';

import '../helpers/faux_reseau.dart';

/// Atelier WinAI, étape 3 : génération de quiz et de fiches, listes, lecture.
void main() {
  late FauxReseau faux;
  setUp(() => faux = preparerEnvironnement());
  final svc = WinAiStudioService.instance;

  Map<String, dynamic> quizDto() => {
        'id': 91, 'title': 'Quiz : fonctions', 'subject': 'Maths', 'difficulty': 'hard',
        'questionsCount': 2, 'durationMinutes': 10, 'isAIGenerated': true, 'createdAt': '2026-11-25T08:00:00Z',
        'questions': [
          {'id': 'q1', 'question': '2 + 2 ?', 'options': ['3', '4']},
          {'id': 'q2', 'question': 'f(x) = x² en 3 ?', 'options': ['6', '9']},
        ],
      };

  Map<String, dynamic> ficheDto({String? doc}) => {
        'id': 12, 'title': 'Fiche : derivees', 'subject': 'Maths', 'topic': 'Derivees', 'difficulty': 'medium',
        'content': '# Derivees\n\n- regle 1', 'documentUrl': doc, 'durationMinutes': 15, 'isAIGenerated': true,
        'createdAt': '2026-11-25T08:00:00Z',
      };

  test('quiz : corps envoye (matiere, sujet, difficulte) et quiz jouable avec son id', () async {
    faux.repond('POST', '/quizzes/me/generate', quizDto());
    final g = await svc.generateQuiz(subject: ' Maths ', topic: 'Fonctions', difficulty: 'hard');
    expect(faux.recues('POST', '/quizzes/me/generate').single.data,
        {'subject': 'Maths', 'topic': 'Fonctions', 'difficulty': 'hard'});
    expect(g.summary.id, 91);
    expect(g.summary.questionsCount, 2);
    final q = g.quiz.toQuiz();
    expect(q.id, '91');
    expect(q.questions.map((e) => e.id), ['q1', 'q2']);
  });

  test('sans matiere ni sujet : seule la difficulte part (le serveur choisit) ; difficulte inconnue = medium ; sources si fournies', () async {
    faux.repond('POST', '/revisions/me/generate', ficheDto());
    await svc.generateRevisionSheet(subject: '  ', difficulty: 'extreme');
    expect(faux.recues('POST', '/revisions/me/generate').single.data, {'difficulty': 'medium'});
    await svc.generateRevisionSheet(subject: 'Maths', sources: [3, 4]);
    expect(faux.recues('POST', '/revisions/me/generate').last.data,
        {'subject': 'Maths', 'difficulty': 'medium', 'sources': [3, 4]});
  });

  test('fiche : contenu markdown, pas de document ; listes generees avec includeHidden', () async {
    faux.repond('POST', '/revisions/me/generate', ficheDto());
    final f = await svc.generateRevisionSheet(subject: 'Maths', topic: 'Derivees');
    expect(f.content, startsWith('# Derivees'));
    expect(f.hasDocument, isFalse);
    faux.repond('GET', '/revisions/me/generated', [ficheDto(), {...ficheDto(), 'id': 13, 'hiddenFromList': true}]);
    final fiches = await svc.generatedSheets(includeHidden: true);
    expect(fiches.map((e) => e.id), [12, 13]);
    expect(fiches.last.hidden, isTrue);
    expect(faux.recues('GET', '/revisions/me/generated').single.queryParameters['includeHidden'], true);
    faux.repond('GET', '/quizzes/me/generated', {'data': [quizDto()]});
    expect((await svc.generatedQuizzes()).single.title, 'Quiz : fonctions');
  });

  test('document PDF lu en octets ; masquer et reafficher', () async {
    faux.repond('GET', '/revisions/12/document', const FauxTexte('%PDF-1.4'));
    final octets = await svc.document(12);
    expect(String.fromCharCodes(octets), '%PDF-1.4');
    faux.repond('POST', '/quizzes/91/hide', null, statut: 204);
    faux.repond('POST', '/revisions/12/unhide', null, statut: 204);
    await svc.setQuizHidden(91, true);
    await svc.setSheetHidden(12, false);
    expect(faux.recues('POST', '/quizzes/91/hide'), hasLength(1));
    expect(faux.recues('POST', '/revisions/12/unhide'), hasLength(1));
  });

  group('refus', () {
    Future<WinAiStudioException> refus(Object corps, int statut) async {
      faux.repond('POST', '/quizzes/me/generate', corps, statut: statut);
      try {
        await svc.generateQuiz(subject: 'Maths');
      } on WinAiStudioException catch (e) {
        return e;
      }
      fail('aucun refus');
    }

    test('402 limite atteinte : message du serveur, isQuota', () async {
      final e = await refus({'error': 'Limite de la semaine atteinte.', 'code': 'ai_quota_exceeded'}, 402);
      expect(e.message, 'Limite de la semaine atteinte.');
      expect(e.code, 'ai_quota_exceeded');
      expect(e.isQuota, isTrue);
    });

    test('402 sans texte : message WinAI par defaut', () async {
      expect((await refus({}, 402)).message, L10n.current.svcWinaiLimit);
    });

    test('403 hors du plan : message du serveur, isQuota', () async {
      final e = await refus({'error': '« Quiz adaptatif » n\'est pas inclus dans votre plan.', 'code': 'feature_not_in_plan'}, 403);
      expect(e.message, contains('pas inclus'));
      expect(e.isQuota, isTrue);
    });

    test('503 indisponible et 400 donnees insuffisantes : message, pas isQuota', () async {
      final e = await refus({'error': 'WinAI est momentanement indisponible.', 'code': 'ai_quota_unavailable'}, 503);
      expect(e.message, 'WinAI est momentanement indisponible.');
      expect(e.isQuota, isFalse);
      expect((await refus({}, 503)).message, L10n.current.svcWinaiUnavailable);
      expect((await refus({'message': 'Pas assez de donnees.'}, 400)).message, 'Pas assez de donnees.');
    });

    test('hors ligne : message de chargement', () async {
      faux.coupure('POST', '/quizzes/me/generate');
      await expectLater(svc.generateQuiz(), throwsA(isA<WinAiStudioException>()
          .having((e) => e.message, 'message', L10n.current.commonLoadError)));
    });
  });
}
