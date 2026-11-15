import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/services/outbox_service.dart';
import 'package:winplus/services/quiz_service.dart';

import '../helpers/faux_reseau.dart';

Map<String, dynamic> _quizJson({int id = 3}) => {
      'id': id,
      'title': 'Calcul mental',
      'description': 'Quiz de base',
      'subjectCategory': 'math',
      'durationMinutes': 10,
      'questions': [
        {'id': 'q1', 'questionText': '2+2 ?', 'options': ['3', '4'], 'correctAnswer': '4', 'explanation': 'Parce que.'},
        {'id': 'q2', 'question': '1+1 ?', 'options': ['2', '3'], 'correctAnswerIndex': 0},
      ],
    };

void main() {
  late FauxReseau faux;
  late Directory dossier;
  late Box cache;

  setUpAll(() async {
    dossier = ouvrirDossierHive();
    cache = await Hive.openBox(LocalCacheService.studentDashboardBoxName);
    await OutboxService.instance.init();
    QuizService.registerOutboxHandler();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await cache.clear();
    await Hive.box('outbox').clear();
  });

  group('ApiQuizQuestion.fromJson', () {
    test('la bonne reponse en texte est retrouvee sans tenir compte de la casse ni des espaces', () {
      final q = ApiQuizQuestion.fromJson({'id': 'q1', 'questionText': 'Capitale ?', 'options': ['Douala', 'Yaoundé'], 'correctAnswer': '  yaoundé '});
      expect(q.correctAnswerIndex, 1);
      expect(q.options, ['Douala', 'Yaoundé']);
    });

    test('un index entier est conserve, un index en texte numerique est converti', () {
      expect(ApiQuizQuestion.fromJson({'options': ['a', 'b', 'c'], 'correctAnswerIndex': 2}).correctAnswerIndex, 2);
      expect(ApiQuizQuestion.fromJson({'options': ['a', 'b', 'c'], 'correctAnswer': '2'}).correctAnswerIndex, 2);
    });

    test('sans bonne reponse reconnue, l\'index est 0', () {
      expect(ApiQuizQuestion.fromJson({'options': ['a', 'b'], 'correctAnswer': 'zzz'}).correctAnswerIndex, 0);
      expect(ApiQuizQuestion.fromJson({'options': ['a', 'b']}).correctAnswerIndex, 0);
    });

    test('les options non textuelles sont converties en texte', () {
      expect(ApiQuizQuestion.fromJson({'options': [1, 2.5, true]}).options, ['1', '2.5', 'true']);
    });

    test('identifiant numerique converti en texte, absent donne une chaine vide', () {
      expect(ApiQuizQuestion.fromJson({'id': 5}).id, '5');
      expect(ApiQuizQuestion.fromJson(<String, dynamic>{}).id, '');
    });

    test('le texte de la question vient de questionText, a defaut de question', () {
      expect(ApiQuizQuestion.fromJson({'questionText': 'A', 'question': 'B'}).questionText, 'A');
      expect(ApiQuizQuestion.fromJson({'question': 'B'}).questionText, 'B');
      expect(ApiQuizQuestion.fromJson(<String, dynamic>{}).questionText, '');
    });
  });

  group('ApiQuiz', () {
    test('lit un quiz complet et le convertit en modele d\'ecran', () {
      final quiz = ApiQuiz.fromJson(_quizJson()).toQuiz();
      expect(quiz.id, '3');
      expect(quiz.title, 'Calcul mental');
      expect(quiz.subjectId, 'math');
      expect(quiz.durationMinutes, 10);
      expect(quiz.questions, hasLength(2));
      expect(quiz.questions[0].id, 'q1');
      expect(quiz.questions[0].answer, 1);
      expect(quiz.questions[0].explain, 'Parce que.');
      expect(quiz.questions[1].answer, 0);
      expect(quiz.questions[1].explain, '');
    });

    test('un quiz vide prend les valeurs par defaut : 30 minutes, matiere generale', () {
      final q = ApiQuiz.fromJson(<String, dynamic>{});
      expect(q.id, 0);
      expect(q.title, '');
      expect(q.durationMinutes, 30);
      expect(q.questions, isEmpty);
      expect(q.toQuiz().subjectId, 'general');
    });
  });

  group('QuizService.answerItems', () {
    const quiz = Quiz(id: '1', title: 'T', subjectId: 'math', questions: [
      QuizQuestion('a ?', ['x', 'y'], 0, '', id: 'q9'),
      QuizQuestion('b ?', ['u', 'v'], 1, ''),
      QuizQuestion('c ?', ['m', 'n'], 0, ''),
    ]);

    test('envoie le texte de l\'option choisie, avec l\'identifiant serveur ou le numero de la question', () {
      final items = QuizService.answerItems(quiz, [1, 0, 1]);
      expect(items, [
        {'questionId': 'q9', 'answer': 'y'},
        {'questionId': '2', 'answer': 'u'},
        {'questionId': '3', 'answer': 'n'},
      ]);
    });

    test('une question sans reponse, hors bornes ou sans entree donne une reponse vide', () {
      final items = QuizService.answerItems(quiz, [null, 5]);
      expect(items.map((i) => i['answer']), ['', '', '']);
      expect(QuizService.answerItems(quiz, [-1, 0, 0])[0]['answer'], '');
    });
  });

  group('QuizService : reseau', () {
    test('getById lit un quiz', () async {
      faux.repond('GET', '/quizzes/3', _quizJson());
      final q = await QuizService.instance.getById(3);
      expect(q.title, 'Calcul mental');
      expect(q.questions, hasLength(2));
    });

    test('submitAttempt envoie les reponses et la duree, et arrondit le score', () async {
      faux.repond('POST', '/quizzes/3/submit', {'score': 66.67, 'correctAnswers': 2, 'totalQuestions': 3, 'certificateUrl': 'https://x/c'});
      final items = [
        {'questionId': 'q1', 'answer': '4'},
      ];
      final r = await QuizService.instance.submitAttempt(quizId: 3, items: items, durationSeconds: 42);
      expect(faux.recues('POST', '/quizzes/3/submit').single.data, {'answers': items, 'timeSpentSeconds': 42});
      expect(r.score, 67);
      expect(r.correct, 2);
      expect(r.total, 3);
      expect(r.certificateUrl, 'https://x/c');
    });

    test('submitAttempt avec une reponse minimale : tout a zero', () async {
      faux.repond('POST', '/quizzes/3/submit', <String, dynamic>{});
      final r = await QuizService.instance.submitAttempt(quizId: 3, items: [], durationSeconds: 0);
      expect(r.score, 0);
      expect(r.correct, 0);
      expect(r.total, 0);
      expect(r.certificateUrl, isNull);
    });
  });

  group('QuizService.submitAttemptQueueable', () {
    final items = [
      {'questionId': 'q1', 'answer': '4'},
    ];

    test('en ligne et accepte : rien n\'est mis en file', () async {
      faux.repond('POST', '/quizzes/3/submit', {'score': 100});
      await QuizService.instance.submitAttemptQueueable(quizId: 3, items: items, durationSeconds: 5);
      expect(faux.recues('POST', '/quizzes/3/submit'), hasLength(1));
      expect(OutboxService.instance.pendingCount, 0);
    });

    test('refus du serveur (4xx) : pas mis en file, car le rejouer ne changerait rien', () async {
      faux.repond('POST', '/quizzes/3/submit', {'error': 'deja repondu'}, statut: 409);
      await QuizService.instance.submitAttemptQueueable(quizId: 3, items: items, durationSeconds: 5);
      expect(OutboxService.instance.pendingCount, 0);
    });

    test('erreur serveur (5xx) : mis en file pour un nouvel essai', () async {
      faux.repond('POST', '/quizzes/3/submit', {'error': 'panne'}, statut: 503);
      await QuizService.instance.submitAttemptQueueable(quizId: 3, items: items, durationSeconds: 5);
      expect(OutboxService.instance.pendingCount, 1);
      expect(OutboxService.instance.pendingCountFor('quiz_submit'), 1);
      expect(OutboxService.instance.pendingCountFor('autre'), 0);
    });

    test('coupure reseau : mis en file avec les reponses et la duree', () async {
      faux.coupure('POST', '/quizzes/3/submit');
      await QuizService.instance.submitAttemptQueueable(quizId: 3, items: items, durationSeconds: 5);
      expect(OutboxService.instance.pendingCount, 1);
      final entree = Hive.box('outbox').values.single as Map;
      expect(entree['type'], 'quiz_submit');
      expect((entree['payload'] as Map)['quizId'], 3);
      expect((entree['payload'] as Map)['durationSeconds'], 5);
    });
  });

  group('OutboxService.flush', () {
    test('rejoue une soumission en file puis la retire', () async {
      faux.repond('POST', '/quizzes/3/submit', {'score': 100});
      await OutboxService.instance.enqueue('quiz_submit', {
        'quizId': 3,
        'items': [
          {'questionId': 'q1', 'answer': '4'},
        ],
        'durationSeconds': 12,
      });
      await OutboxService.instance.flush();
      final envoi = faux.recues('POST', '/quizzes/3/submit').single.data as Map;
      expect(envoi['timeSpentSeconds'], 12);
      expect(envoi['answers'], [
        {'questionId': 'q1', 'answer': '4'},
      ]);
      expect(OutboxService.instance.pendingCount, 0);
    });

    test('une entree ancienne (numeros de reponse seuls) relit le quiz pour retrouver les textes', () async {
      faux.repond('GET', '/quizzes/3', _quizJson());
      faux.repond('POST', '/quizzes/3/submit', {'score': 50});
      await OutboxService.instance.enqueue('quiz_submit', {
        'quizId': 3,
        'answers': [1, null],
        'durationSeconds': 7,
      });
      await OutboxService.instance.flush();
      final envoi = faux.recues('POST', '/quizzes/3/submit').single.data as Map;
      expect(envoi['answers'], [
        {'questionId': 'q1', 'answer': '4'},
        {'questionId': 'q2', 'answer': ''},
      ]);
      expect(OutboxService.instance.pendingCount, 0);
    });

    test('un echec garde l\'action en file et arrete le passage', () async {
      faux.repond('POST', '/quizzes/3/submit', {'error': 'panne'}, statut: 500);
      await OutboxService.instance.enqueue('quiz_submit', {'quizId': 3, 'items': <Map<String, String>>[], 'durationSeconds': 1});
      await OutboxService.instance.flush();
      expect(OutboxService.instance.pendingCount, 1);
      // Le passage suivant retente et, cette fois, aboutit.
      faux.repond('POST', '/quizzes/3/submit', {'score': 10});
      await OutboxService.instance.flush();
      expect(OutboxService.instance.pendingCount, 0);
      expect(faux.recues('POST', '/quizzes/3/submit'), hasLength(2));
    });

    test('une action sans gestionnaire enregistre est abandonnee', () async {
      await OutboxService.instance.enqueue('type_inconnu', {'a': 1});
      await OutboxService.instance.flush();
      expect(OutboxService.instance.pendingCount, 0);
      expect(faux.requetes, isEmpty);
    });

    test('un gestionnaire qui repond false laisse l\'action en file', () async {
      OutboxService.instance.registerHandler('refuse', (_) async => false);
      await OutboxService.instance.enqueue('refuse', {});
      await OutboxService.instance.flush();
      expect(OutboxService.instance.pendingCountFor('refuse'), 1);
    });

    test('les actions sont rejouees dans l\'ordre d\'ajout', () async {
      final ordre = <int>[];
      OutboxService.instance.registerHandler('ordre', (p) async {
        ordre.add(p['n'] as int);
        return true;
      });
      for (final n in [1, 2, 3]) {
        await OutboxService.instance.enqueue('ordre', {'n': n});
      }
      await OutboxService.instance.flush();
      expect(ordre, [1, 2, 3]);
      expect(OutboxService.instance.pendingCount, 0);
    });
  });

  group('LocalCacheService.cachedFetch', () {
    Future<CachedResult<int>> chercher(Future<dynamic> Function() live) => LocalCacheService.cachedFetch<int>(
          box: cache,
          key: 'cle',
          fetchLiveRaw: live,
          parse: (raw) => (raw as Map)['n'] as int,
        );

    test('succes : valeur du reseau, mise en cache avec sa date', () async {
      final r = await chercher(() async => {'n': 5});
      expect(r.value, 5);
      expect(r.fromCache, isFalse);
      expect(r.updatedAt, isNotNull);
      expect(LocalCacheService.lastUpdatedAt(cache, 'cle'), isNotNull);
    });

    test('jamais mis en cache : pas de date', () {
      expect(LocalCacheService.lastUpdatedAt(cache, 'absente'), isNull);
    });

    test('coupure reseau apres un succes : la derniere valeur connue est servie, marquee « du cache »', () async {
      await chercher(() async => {'n': 5});
      final r = await chercher(() async => throw DioException.connectionError(requestOptions: RequestOptions(path: '/x'), reason: 'hors ligne'));
      expect(r.value, 5);
      expect(r.fromCache, isTrue);
      expect(r.updatedAt, isNotNull);
    });

    test('coupure reseau sans cache : l\'erreur d\'origine remonte', () async {
      await expectLater(
        chercher(() async => throw DioException.connectionError(requestOptions: RequestOptions(path: '/x'), reason: 'hors ligne')),
        throwsA(isA<DioException>()),
      );
    });

    test('reponse serveur en erreur (500) : jamais resservie depuis le cache', () async {
      await chercher(() async => {'n': 5});
      final reponse500 = DioException.badResponse(statusCode: 500, requestOptions: RequestOptions(path: '/x'), response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 500));
      await expectLater(chercher(() async => throw reponse500), throwsA(isA<DioException>()));
      expect(cache.containsKey('cle'), isTrue);
    });

    test('reponse 404 : l\'entree du cache est videe, une coupure ulterieure ne ressert pas une donnee perimee', () async {
      await chercher(() async => {'n': 5});
      final reponse404 = DioException.badResponse(statusCode: 404, requestOptions: RequestOptions(path: '/x'), response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 404));
      await expectLater(chercher(() async => throw reponse404), throwsA(isA<DioException>()));
      expect(cache.containsKey('cle'), isFalse);
      await expectLater(
        chercher(() async => throw DioException.connectionError(requestOptions: RequestOptions(path: '/x'), reason: 'hors ligne')),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('QuizService.getAll : cache', () {
    test('la liste est mise en cache puis servie hors ligne', () async {
      faux.repond('GET', '/quizzes', [_quizJson(id: 1), _quizJson(id: 2)]);
      final enLigne = await QuizService.instance.getAll();
      expect(enLigne.map((q) => q.id), [1, 2]);
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 20});

      faux.coupure('GET', '/quizzes');
      final horsLigne = await QuizService.instance.getAll();
      expect(horsLigne.map((q) => q.id), [1, 2]);
    });

    test('chaque page a sa propre entree de cache', () async {
      faux.repond('GET', '/quizzes', [_quizJson(id: 1)]);
      await QuizService.instance.getAll();
      expect(cache.containsKey('quizzes_p1_20'), isTrue);
      expect(cache.containsKey('quizzes_p2_20'), isFalse);
      faux.coupure('GET', '/quizzes');
      await expectLater(QuizService.instance.getAll(page: 2), throwsA(isA<DioException>()));
    });
  });
}
