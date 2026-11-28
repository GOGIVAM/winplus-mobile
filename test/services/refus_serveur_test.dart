import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/content_refusal.dart';
import 'package:winplus/services/messaging_service.dart';
import 'package:winplus/services/quiz_service.dart';

import '../helpers/faux_reseau.dart';

DioException _err(int status, Object data) {
  final req = RequestOptions(path: '/x');
  return DioException(requestOptions: req, response: Response(requestOptions: req, statusCode: status, data: data));
}

/// Refus motives du serveur (correctifs de securite cdc17f9, c9fd931) :
/// { code, message } affiche tel quel a la place d'une erreur generique.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  test('ServerRefusal.of : 403, 409 et 400 avec code et message ; sinon null', () {
    expect(ServerRefusal.of(_err(403, {'code': 'lien_requis', 'message': 'Lien requis.'}))?.message, 'Lien requis.');
    expect(ServerRefusal.of(_err(403, {'code': 'exam_access_required', 'message': 'Acces requis.'}))?.code, 'exam_access_required');
    expect(ServerRefusal.of(_err(409, {'code': 'deja', 'message': 'Deja fait.'}))?.message, 'Deja fait.');
    expect(ServerRefusal.of(_err(403, {'message': 'sans code'})), isNull);
    expect(ServerRefusal.of(_err(500, {'code': 'x', 'message': 'panne'})), isNull);
    expect(ServerRefusal.of(_err(403, 'texte')), isNull);
    expect(ServerRefusal.of(StateError('x')), isNull);
    expect(ServerRefusal.of(const ContentRefused('langage_inapproprie', 'Mot refuse.'))?.message, 'Mot refuse.');
  });

  test('startConversation : un refus motive remonte avec son message (repetiteur qui ecrit le premier)', () async {
    faux.repond('POST', '/messages/conversations',
        {'success': false, 'code': 'premier_message_interdit', 'message': 'Le repetiteur repond seulement.'}, statut: 403);
    await expectLater(MessagingService.instance.startConversation(3, firstMessage: 'Bonjour'),
        throwsA(isA<ServerRefusal>().having((r) => r.message, 'message', 'Le repetiteur repond seulement.')));
    faux.repond('POST', '/messages/conversations', {}, statut: 500);
    expect(await MessagingService.instance.startConversation(3, firstMessage: 'Bonjour'), isNull);
  });

  test('quiz d epreuve payante sans acces : le message du serveur est lisible', () async {
    faux.repond('GET', '/quizzes/7', {'success': false, 'code': 'exam_access_required', 'message': 'Achetez l epreuve.'}, statut: 403);
    try {
      await QuizService.instance.getById(7);
      fail('refus attendu');
    } catch (e) {
      expect(ServerRefusal.of(e)?.message, 'Achetez l epreuve.');
    }
  });
}
