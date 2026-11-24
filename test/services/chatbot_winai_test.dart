import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/chatbot_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() {
    faux = preparerEnvironnement();
    ChatbotService.instance.knowledgeBase.value = false;
  });
  tearDown(() {
    L10n.locale = const Locale('fr');
    ChatbotService.instance.knowledgeBase.value = false;
  });

  group('Modeles du chat', () {
    test('ApiWinAIMemory : type general par defaut', () {
      final m = ApiWinAIMemory.fromJson({'id': 3, 'content': 'Difficulte en algebre', 'createdAt': '2026-01-05T10:00:00Z'});
      expect(m.type, 'general');
      expect(m.id, 3);
      expect(m.createdAt.toUtc(), DateTime.utc(2026, 1, 5, 10));
      expect(ApiWinAIMemory.fromJson(<String, dynamic>{}).content, '');
    });

    test('ApiChatMessage : role assistant par defaut', () {
      expect(ApiChatMessage.fromJson({'content': 'Bonjour'}).role, 'assistant');
      expect(ApiChatMessage.fromJson({'role': 'user'}).role, 'user');
    });

    test('ApiChatSession : titre « Conversation » par defaut', () {
      final s = ApiChatSession.fromJson({'id': 2, 'lastMessage': 'A bientot'});
      expect(s.title, 'Conversation');
      expect(s.lastMessage, 'A bientot');
    });
  });

  group('ChatbotService', () {
    test('sessions : liste brute ou { conversations }', () async {
      faux.repond('GET', '/chatbot/conversations', [
        {'id': 1, 'title': 'A'},
      ]);
      expect(await ChatbotService.instance.getSessions(), hasLength(1));
      faux.repond('GET', '/chatbot/conversations', {
        'conversations': [
          {'id': 1},
          {'id': 2},
        ],
      });
      expect(await ChatbotService.instance.getSessions(), hasLength(2));
    });

    test('historique d\'une conversation', () async {
      faux.repond('GET', '/chatbot/conversations/4', {
        'messages': [
          {'role': 'user', 'content': 'Q'},
          {'role': 'assistant', 'content': 'R'},
        ],
      });
      final h = await ChatbotService.instance.getHistory(4);
      expect(h.map((m) => m.content), ['Q', 'R']);
      faux.repond('GET', '/chatbot/conversations/5', {});
      expect(await ChatbotService.instance.getHistory(5), isEmpty);
    });

    test('sendMessage : corps conforme au DTO (content, identifiant de message, base de connaissance)', () async {
      faux.repond('POST', '/chatbot/message', {
        'assistantMessage': {'content': 'Voici la reponse'},
      });
      final r = await ChatbotService.instance.sendMessage(message: 'Aide-moi', sessionId: 9, context: 'maths');
      expect(r, 'Voici la reponse');
      final d = faux.requetes.single.data as Map;
      expect(d['content'], 'Aide-moi');
      expect(d['conversationId'], 9);
      expect(d['context'], 'maths');
      expect(d['knowledgeBase'], false);
      expect(d['clientMessageId'], matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(d.containsKey('message'), isFalse);
    });

    test('sendMessage : un nouvel identifiant a chaque envoi, mode base de connaissance transmis', () async {
      faux.repond('POST', '/chatbot/message', {'reply': 'ok'});
      ChatbotService.instance.knowledgeBase.value = true;
      expect(await ChatbotService.instance.sendMessage(message: 'a'), 'ok');
      await ChatbotService.instance.sendMessage(message: 'b');
      final l = faux.recues('POST', '/chatbot/message').map((r) => r.data as Map).toList();
      expect(l[0]['clientMessageId'], isNot(l[1]['clientMessageId']));
      expect(l[0]['knowledgeBase'], true);
      expect(l[0].containsKey('conversationId'), isFalse);
    });

    test('sendMessage : repli sur le champ « message » de la reponse', () async {
      faux.repond('POST', '/chatbot/message', {'message': 'repli'});
      expect(await ChatbotService.instance.sendMessage(message: 'a'), 'repli');
    });

    test('sendMessage : 402 rend le message du serveur, ou le message de limite par defaut', () async {
      faux.repond('POST', '/chatbot/message', {'message': 'Reessayez a 15 h'}, statut: 402);
      expect(await ChatbotService.instance.sendMessage(message: 'a'), 'Reessayez a 15 h');
      faux.repond('POST', '/chatbot/message', {}, statut: 402);
      expect(await ChatbotService.instance.sendMessage(message: 'a'), L10n.current.svcWinaiLimit);
    });

    test('sendMessage : 503 quota_unavailable = message de maintenance ; autre erreur = null', () async {
      faux.repond('POST', '/chatbot/message', {'error': 'quota_unavailable'}, statut: 503);
      expect(await ChatbotService.instance.sendMessage(message: 'a'), L10n.current.svcWinaiUnavailable);
      faux.repond('POST', '/chatbot/message', {'error': 'autre'}, statut: 503);
      expect(await ChatbotService.instance.sendMessage(message: 'a'), isNull);
      faux.repond('POST', '/chatbot/message', {}, statut: 500);
      expect(await ChatbotService.instance.sendMessage(message: 'a'), isNull);
    });

    test('quotaRefusalMessage : statuts sans rapport avec le quota = null', () {
      expect(ChatbotService.quotaRefusalMessage(404, {'message': 'x'}), isNull);
      expect(ChatbotService.quotaRefusalMessage(null, null), isNull);
      expect(ChatbotService.quotaRefusalMessage(402, {'message': ''}), L10n.current.svcWinaiLimit);
    });

    test('suppression de conversation et memoires', () async {
      faux.repond('DELETE', '/chatbot/conversations/4', {});
      expect(await ChatbotService.instance.deleteSession(4), isTrue);
      expect(await ChatbotService.instance.deleteSession(5), isFalse);
      faux.repond('GET', '/chatbot/memories', [
        {'id': 1, 'type': 'exam_context', 'content': 'BAC en juin'},
      ]);
      expect((await ChatbotService.instance.getMemories()).single.content, 'BAC en juin');
      faux.repond('GET', '/chatbot/memories', {}, statut: 500);
      await expectLater(ChatbotService.instance.getMemories(), throwsA(isA<DioException>()),
          reason: 'une panne remonte : la feuille affiche son erreur, pas « aucune memoire »');
      faux.repond('DELETE', '/chatbot/memories/1', {});
      expect(await ChatbotService.instance.deleteMemory(1), isTrue);
      expect(await ChatbotService.instance.deleteMemory(2), isFalse);
    });
  });
}
