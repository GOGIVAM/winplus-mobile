import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winplus/services/content_refusal.dart';
import 'package:winplus/services/messaging_service.dart';
import 'package:winplus/services/outbox_service.dart';
import 'package:winplus/shared/messaging/messaging_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Filtre des messageries (serveur) : un message avec un numéro de
/// téléphone ou un gros mot est refusé (400, code, message). Le message du
/// serveur s'affiche tel quel, le texte reste dans le champ pour être
/// corrigé, et rien ne part en file d'envoi. Avant, tout échec d'envoi était
/// mis en file et affiché comme envoyé.
void main() {
  late FauxReseau faux;
  setUp(() => faux = preparerEnvironnement());

  const conv = ApiConversation(id: 1, participantName: 'Mme Ngo', participantRole: 'teacher');
  const Map<String, Object> refus = {
    'success': false,
    'error': 'Les coordonnees personnelles ne sont pas autorisees.',
    'code': 'coordonnees_interdites',
    'message': 'Pour ta securite, les numeros de telephone ne sont pas autorises.',
  };

  test('reconnait les deux codes du filtre, pas les autres refus', () {
    expect(ContentRefused.of(_dio(400, refus))?.code, 'coordonnees_interdites');
    expect(ContentRefused.of(_dio(400, {'code': 'langage_inapproprie', 'message': 'Langage'}))?.message, 'Langage');
    expect(ContentRefused.of(_dio(400, {'code': 'autre', 'message': 'x'})), isNull);
    expect(ContentRefused.of(_dio(500, refus)), isNull);
  });

  testWidgets('conversation : refus affiche, texte garde, rien en file', (tester) async {
    faux.repond('GET', '/messages/conversations/1/messages', []);
    faux.repond('POST', '/messages/conversations/1/messages', refus, statut: 400);
    await tester.runAsync(OutboxService.instance.initForTest);
    await monterEcran(tester, const ConversationScreen(conversation: conv));
    await tester.enterText(find.byType(TextField), 'Appelle-moi au 6 70 00 00 00');
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await reseau(tester);
    expect(find.text(refus['message']! as String), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Appelle-moi au 6 70 00 00 00');
    expect(OutboxService.instance.pendingCount, 0);
    expect(faux.recues('POST', '/messages/conversations/1/messages'), hasLength(1));
  });
}

Object _dio(int statut, Map<String, Object> corps) {
  final o = RequestOptions(path: '/x');
  return DioException(requestOptions: o, response: Response(requestOptions: o, statusCode: statut, data: corps));
}
