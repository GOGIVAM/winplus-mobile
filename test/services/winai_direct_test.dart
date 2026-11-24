import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:winplus/services/chatbot_service.dart';
import 'package:winplus/student/student_tabs.dart';
import 'package:winplus/widgets/winai_markdown.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// WinAI en direct (POST /chatbot/stream, comme le site) : la reponse
/// s'ecrit au fil des fragments, reste dans la meme conversation, et passe
/// par la route classique si le flux n'apporte rien.
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  String flux(List<String> lignes) => '${lignes.map((l) => 'data: $l').join('\n\n')}\n\n';

  test('fragments assembles au fil de l\'eau ; conversation retenue', () async {
    faux.sur('POST', '/chatbot/stream', (_) => FauxReponse(FauxTexte(flux([
          '{"conversationId": 42}',
          '{"delta": "La derivee de "}',
          '{"delta": "\$x^2\$ est \$2x\$."}',
          '[DONE]',
        ]))));
    final etapes = <String>[];
    int? conv;
    final r = await ChatbotService.instance.streamMessage(
      message: 'Derivee de x^2 ?',
      onText: etapes.add,
      onConversation: (id) => conv = id,
    );
    expect(etapes, ['La derivee de ', 'La derivee de \$x^2\$ est \$2x\$.']);
    expect(r, 'La derivee de \$x^2\$ est \$2x\$.');
    expect(conv, 42);
    final envoi = faux.recues('POST', '/chatbot/stream').single.data as Map;
    expect(envoi['message'], 'Derivee de x^2 ?');
    expect(envoi['clientMessageId'], isNotNull);
  });

  test('flux vide ou route absente : reponse par la route classique', () async {
    faux.repond('POST', '/chatbot/stream', {}, statut: 404);
    faux.repond('POST', '/chatbot/message', {'assistantMessage': {'content': 'Reponse classique'}});
    final r = await ChatbotService.instance.streamMessage(message: 'Bonjour', onText: (_) {});
    expect(r, 'Reponse classique');
  });

  test('limite atteinte (402) : le message du serveur, sans repli', () async {
    faux.repond('POST', '/chatbot/stream', {'message': 'Limite de la semaine atteinte'}, statut: 402);
    final r = await ChatbotService.instance.streamMessage(message: 'Bonjour', onText: (_) {});
    expect(r, 'Limite de la semaine atteinte');
    expect(faux.recues('POST', '/chatbot/message'), isEmpty);
  });

  testWidgets('onglet WinAI : reponse mise en forme et meme conversation au message suivant', (tester) async {
    faux.sur('POST', '/chatbot/stream', (o) => FauxReponse(FauxTexte(flux([
          if ((o.data as Map)['conversationId'] == null) '{"conversationId": 7}',
          '{"delta": "**Bravo**, la formule est \$a^2+b^2=c^2\$"}',
          '[DONE]',
        ]))));
    await monterEcran(tester, const StudentWinAITab(initialMessage: 'Pythagore ?'));
    await reseau(tester);
    expect(find.byType(WinAIMarkdown), findsOneWidget);
    expect(find.byType(GptMarkdown), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Et la reciproque ?');
    await tester.tap(find.byIcon(Icons.send));
    await reseau(tester);
    final envois = faux.recues('POST', '/chatbot/stream');
    expect(envois, hasLength(2));
    expect((envois[0].data as Map)['conversationId'], isNull);
    expect((envois[1].data as Map)['conversationId'], 7, reason: 'WinAI garde le contexte');
  });
}
