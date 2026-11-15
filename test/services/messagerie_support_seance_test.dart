import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/messaging_service.dart';
import 'package:winplus/services/tutor_session_material_service.dart';

import '../helpers/faux_reseau.dart';

Map<String, dynamic> _support([Map<String, dynamic> en = const {}]) => {
      'bookingId': 5,
      'viewerRole': 'tutor',
      'bookingStatus': 'confirmed',
      'sessionDate': '2026-04-06',
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('Messagerie : modeles', () {
    test('ApiConversation : valeurs par defaut', () {
      final c = ApiConversation.fromJson(<String, dynamic>{});
      expect(c.participantName, '');
      expect(c.participantRole, 'teacher');
      expect(c.unreadCount, 0);
      expect(c.lastMessageAt, isNull);
      final p = ApiConversation.fromJson({'id': 3, 'participantName': 'Ada', 'unreadCount': 2, 'lastMessageAt': '2026-04-06T10:00:00Z'});
      expect(p.unreadCount, 2);
      expect(p.lastMessageAt!.toUtc(), DateTime.utc(2026, 4, 6, 10));
    });

    test('ApiMessage : message recu par defaut', () {
      final m = ApiMessage.fromJson({'content': 'Salut', 'sentAt': '2026-04-06T10:00:00Z'});
      expect(m.isFromMe, isFalse);
      expect(m.content, 'Salut');
      expect(m.sentAt.toUtc(), DateTime.utc(2026, 4, 6, 10));
      expect(ApiMessage.fromJson({'isFromMe': true}).isFromMe, isTrue);
    });
  });

  group('MessagingService', () {
    test('conversations et messages', () async {
      faux.repond('GET', '/messages/conversations', [
        {'id': 1, 'participantName': 'Ada'},
      ]);
      expect((await MessagingService.instance.getConversations()).single.participantName, 'Ada');
      faux.repond('GET', '/messages/conversations/1/messages', [
        {'id': 9, 'content': 'Bonjour'},
      ]);
      expect((await MessagingService.instance.getMessages(1)).single.content, 'Bonjour');
    });

    test('sendMessage : true si accepte, false sinon', () async {
      faux.repond('POST', '/messages/conversations/1/messages', {});
      expect(await MessagingService.instance.sendMessage(1, 'Coucou'), isTrue);
      expect(faux.requetes.single.data, {'content': 'Coucou'});
      expect(await MessagingService.instance.sendMessage(2, 'x'), isFalse);
    });

    test('startConversation : premier message par defaut « Bonjour », identifiant lu de deux facons', () async {
      faux.repond('POST', '/messages/conversations', {'conversationId': 7});
      expect(await MessagingService.instance.startConversation(3), 7);
      expect(faux.requetes.last.data, {'participantId': 3, 'firstMessage': 'Bonjour'});
      faux.repond('POST', '/messages/conversations', {'id': 8});
      expect(await MessagingService.instance.startConversation(3, firstMessage: 'Salut'), 8);
      expect((faux.requetes.last.data as Map)['firstMessage'], 'Salut');
      faux.repond('POST', '/messages/conversations', {}, statut: 500);
      expect(await MessagingService.instance.startConversation(3), isNull);
    });

    test('markRead appelle la route de lecture et ignore les erreurs', () async {
      faux.repond('PUT', '/messages/conversations/1/read', {});
      await MessagingService.instance.markRead(1);
      await MessagingService.instance.markRead(2);
      expect(faux.recues('PUT', '/messages/conversations/1/read'), hasLength(1));
      expect(faux.recues('PUT', '/messages/conversations/2/read'), hasLength(1));
    });
  });

  group('Support de seance : modeles', () {
    test('SessionMaterialContent : lecture du cours imbrique, quiz et exercices', () {
      final c = SessionMaterialContent.fromJson({
        'title': 'Les fractions',
        'objectives': ['Comprendre', 'Appliquer'],
        'course': {
          'introduction': 'Intro',
          'sections': [
            {'title': 'S1', 'content': 'Texte', 'example': 'Ex'},
          ],
          'summary': 'Resume',
          'keyPoints': ['a'],
        },
        'quiz': [
          {
            'id': 1,
            'text': 'Q?',
            'options': [
              {'id': 'a', 'text': 'A'},
              {'id': 'b', 'text': 'B'},
            ],
            'correctOptionId': 'b',
          },
        ],
        'exercises': [
          {'id': 'e1', 'title': 'T', 'statement': 'S', 'hints': ['h']},
        ],
        'groupNote': 'Note',
      });
      expect(c.introduction, 'Intro');
      expect(c.sections.single.example, 'Ex');
      expect(c.quiz.single.id, '1');
      expect(c.quiz.single.options.map((o) => o.id), ['a', 'b']);
      expect(c.quiz.single.correctOptionId, 'b');
      expect(c.exercises.single.difficulty, 'moyen');
      expect(c.exercises.single.hints, ['h']);
      expect(c.exercises.single.solution, isNull);
      expect(c.groupNote, 'Note');
    });

    test('SessionMaterialContent.copy est une copie profonde independante', () {
      final c = SessionMaterialContent(
        title: 'T',
        sections: [MaterialSection(title: 'S', content: 'C')],
        quiz: [
          MaterialQuizQuestion(id: 'q', text: 'Q', options: [MaterialQuizOption(id: 'a', text: 'A')]),
        ],
      );
      final d = c.copy();
      d.title = 'Autre';
      d.sections.first.content = 'Modifie';
      d.quiz.first.options.first.text = 'Modifie';
      expect(c.title, 'T');
      expect(c.sections.first.content, 'C');
      expect(c.quiz.first.options.first.text, 'A');
      expect(d.sections.first.title, 'S');
    });

    test('toJson puis fromJson redonne le meme contenu', () {
      final c = SessionMaterialContent(title: 'T', introduction: 'I', summary: 'R', keyPoints: ['k'], objectives: ['o']);
      final j = c.toJson();
      expect((j['course'] as Map)['introduction'], 'I');
      final r = SessionMaterialContent.fromJson(j);
      expect(r.title, 'T');
      expect(r.keyPoints, ['k']);
      expect(r.objectives, ['o']);
      expect(r.sections, isEmpty);
    });

    test('MaterialResult : reponses d\'exercices converties en texte', () {
      final r = MaterialResult.fromJson({
        'studentUserId': 4,
        'quizScore': 2,
        'quizTotal': 3,
        'isOutdated': true,
        'exerciseAnswers': {'e1': 5},
        'questions': [
          {'questionId': 1, 'isCorrect': true, 'answer': 'a'},
        ],
      });
      expect(r.materialVersion, 1);
      expect(r.isOutdated, isTrue);
      expect(r.exerciseAnswers, {'e1': '5'});
      expect(r.questions.single.questionId, '1');
      expect(r.questions.single.isCorrect, isTrue);
      expect(MaterialResult.fromJson(<String, dynamic>{}).submittedAt, isNull);
    });

    test('SessionMaterialView : valeurs par defaut = lecteur payeur sans droits', () {
      final v = SessionMaterialView.fromJson(<String, dynamic>{});
      expect(v.viewerRole, 'payer');
      expect(v.isTutor, isFalse);
      expect(v.isParticipant, isFalse);
      expect(v.exists, isFalse);
      expect(v.content, isNull);
      expect(v.canEdit, isFalse);
      expect(v.canSubmit, isFalse);
      expect(v.participantCount, 1);
      expect(v.results, isEmpty);
    });

    test('SessionMaterialView : role, droits, participants et resultat', () {
      final v = SessionMaterialView.fromJson(_support({
        'viewerRole': 'participant',
        'exists': true,
        'status': 'shared',
        'version': 3,
        'canSubmit': true,
        'participants': [
          {'userId': 1, 'name': 'Ada'},
          {'userId': 2},
        ],
        'content': {'title': 'T'},
        'myResult': {'quizScore': 1, 'quizTotal': 2},
        'blockedReason': 'Aucun',
      }));
      expect(v.isParticipant, isTrue);
      expect(v.exists, isTrue);
      expect(v.version, 3);
      expect(v.canSubmit, isTrue);
      expect(v.participants.map((p) => p.userId), [1, 2]);
      expect(v.participants.last.name, isNull);
      expect(v.content!.title, 'T');
      expect(v.myResult!.quizTotal, 2);
      expect(v.blockedReason, 'Aucun');
    });

    test('kSessionMaterialStatusLabels : trois statuts', () {
      final l = L10n.current;
      expect(kSessionMaterialStatusLabels, {
        'draft': l.svcMaterialDraft,
        'shared': l.svcMaterialShared,
        'shared_with_changes': l.svcMaterialSharedWithChanges,
      });
    });
  });

  group('TutorSessionMaterialService', () {
    test('get lit la vue, enveloppee dans data ou non', () async {
      faux.repond('GET', '/tutor-bookings/5/material', _support());
      expect((await TutorSessionMaterialService.instance.get(5)).bookingId, 5);
      faux.repond('GET', '/tutor-bookings/5/material', {'data': _support({'bookingId': 6})});
      expect((await TutorSessionMaterialService.instance.get(5)).bookingId, 6);
    });

    test('generate : consignes rognees, null si vides', () async {
      faux.repond('POST', '/tutor-bookings/5/material/generate', _support());
      await TutorSessionMaterialService.instance.generate(5, instructions: '  Insister sur les exemples  ');
      expect(faux.requetes.last.data, {'instructions': 'Insister sur les exemples'});
      await TutorSessionMaterialService.instance.generate(5, instructions: '   ');
      expect(faux.requetes.last.data, {'instructions': null});
      await TutorSessionMaterialService.instance.generate(5);
      expect(faux.requetes.last.data, {'instructions': null});
    });

    test('update envoie le contenu, share poste un corps vide, submit les reponses', () async {
      faux.repond('PUT', '/tutor-bookings/5/material', _support());
      await TutorSessionMaterialService.instance.update(5, SessionMaterialContent(title: 'Nouveau'));
      expect(((faux.requetes.last.data as Map)['content'] as Map)['title'], 'Nouveau');
      faux.repond('POST', '/tutor-bookings/5/material/share', _support({'status': 'shared'}));
      expect((await TutorSessionMaterialService.instance.share(5)).status, 'shared');
      expect(faux.requetes.last.data, <String, dynamic>{});
      faux.repond('POST', '/tutor-bookings/5/material/submit', _support());
      await TutorSessionMaterialService.instance.submit(5, {'1': 'a'}, {'e1': 'reponse'});
      expect(faux.requetes.last.data, {
        'quizAnswers': {'1': 'a'},
        'exerciseAnswers': {'e1': 'reponse'},
      });
    });

    test('reglage de generation automatique : lecture et ecriture', () async {
      faux.repond('GET', '/tutor-bookings/session-material/settings', {'autoGenerateOnAccept': true});
      expect(await TutorSessionMaterialService.instance.getAutoGenerate(), isTrue);
      faux.repond('GET', '/tutor-bookings/session-material/settings', {});
      expect(await TutorSessionMaterialService.instance.getAutoGenerate(), isFalse);
      faux.repond('PUT', '/tutor-bookings/session-material/settings', {'autoGenerateOnAccept': false});
      expect(await TutorSessionMaterialService.instance.setAutoGenerate(false), isFalse);
      expect(faux.requetes.last.data, {'autoGenerateOnAccept': false});
    });

    test('errorMessage : message ou erreur du serveur, sinon null', () async {
      faux.repond('GET', '/tutor-bookings/5/material', {'message': 'Plan insuffisant'}, statut: 403);
      try {
        await TutorSessionMaterialService.instance.get(5);
        fail('une erreur etait attendue');
      } catch (e) {
        expect(TutorSessionMaterialService.errorMessage(e), 'Plan insuffisant');
      }
      faux.repond('GET', '/tutor-bookings/5/material', {'error': 'Budget'}, statut: 402);
      try {
        await TutorSessionMaterialService.instance.get(5);
        fail('une erreur etait attendue');
      } catch (e) {
        expect(TutorSessionMaterialService.errorMessage(e), 'Budget');
      }
      expect(TutorSessionMaterialService.errorMessage(Exception('x')), isNull);
    });
  });
}
