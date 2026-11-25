import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/messaging_service.dart';
import 'package:winplus/shared/messaging/messaging_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

String _ilYa(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('MessagingScreen', () {
    testWidgets('chargement puis conversations : nom, role, dernier message, non lus, heure relative', (tester) async {
      faux.repond('GET', '/messages/conversations', [
        {'id': 1, 'participantName': 'Mme Ngo', 'participantRole': 'teacher', 'lastMessage': 'A demain', 'unreadCount': 2, 'lastMessageAt': _ilYa(const Duration(minutes: 7))},
        {'id': 2, 'participantName': 'M. Eto', 'participantRole': 'parent', 'lastMessageAt': _ilYa(const Duration(days: 3))},
      ]);
      telephone(tester);
      await monter(tester, ecran(const MessagingScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text('A demain'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text(l.roleTeacher), findsOneWidget);
      expect(find.text(l.roleParent), findsOneWidget);
      expect(find.text(l.msgMinutesAgo(7)), findsOneWidget);
      expect(find.text(l.msgDaysAgo(3)), findsOneWidget);
    });

    testWidgets('aucune conversation : message et indication', (tester) async {
      faux.repond('GET', '/messages/conversations', []);
      await monterEcran(tester, const MessagingScreen());
      expect(find.text(L10n.current.msgEmpty), findsOneWidget);
      expect(find.text(L10n.current.msgEmptyHint), findsOneWidget);
    });

    testWidgets('erreur serveur : message et Reessayer, pas « aucune conversation »', (tester) async {
      faux.repond('GET', '/messages/conversations', {}, statut: 500);
      await monterEcran(tester, const MessagingScreen());
      expect(find.text(L10n.current.commonLoadError), findsOneWidget);
      expect(find.text(L10n.current.msgEmpty), findsNothing);
    });

    testWidgets('toucher une conversation l\'ouvre et la marque lue', (tester) async {
      faux.repond('GET', '/messages/conversations', [
        {'id': 1, 'participantName': 'Mme Ngo', 'participantRole': 'teacher'},
      ]);
      faux.repond('GET', '/messages/conversations/1/messages', []);
      faux.repond('PUT', '/messages/conversations/1/read', {});
      await monterEcran(tester, const MessagingScreen());
      await tester.tap(find.text('Mme Ngo'));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(faux.recues('PUT', '/messages/conversations/1/read'), hasLength(1));
    });

    testWidgets('actualiser relit les conversations', (tester) async {
      faux.repond('GET', '/messages/conversations', []);
      await monterEcran(tester, const MessagingScreen());
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
      await reseau(tester);
      expect(faux.recues('GET', '/messages/conversations'), hasLength(2));
    });
  });

  group('ConversationScreen', () {
    const conv = ApiConversation(id: 1, participantName: 'Mme Ngo', participantRole: 'teacher');

    testWidgets('fil vide : invitation a ecrire', (tester) async {
      faux.repond('GET', '/messages/conversations/1/messages', []);
      await monterEcran(tester, const ConversationScreen(conversation: conv));
      expect(find.text(L10n.current.msgStartConversation), findsOneWidget);
      expect(find.text('Mme Ngo'), findsWidgets);
    });

    testWidgets('messages : contenu des deux cotes, mes messages alignes a droite', (tester) async {
      faux.repond('GET', '/messages/conversations/1/messages', [
        {'id': 1, 'content': 'Bonjour', 'isFromMe': false, 'sentAt': _ilYa(const Duration(minutes: 5))},
        {'id': 2, 'content': 'Merci madame', 'isFromMe': true, 'sentAt': _ilYa(const Duration(minutes: 2))},
      ]);
      await monterEcran(tester, const ConversationScreen(conversation: conv));
      final recu = tester.getCenter(find.text('Bonjour')).dx;
      final envoye = tester.getCenter(find.text('Merci madame')).dx;
      expect(envoye, greaterThan(recu));
    });

    testWidgets('message vide : rien n\'est envoye', (tester) async {
      faux.repond('GET', '/messages/conversations/1/messages', []);
      await monterEcran(tester, const ConversationScreen(conversation: conv));
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(faux.recues('POST', '/messages/conversations/1/messages'), isEmpty);
    });

    testWidgets('envoi : message rogne poste, champ vide, fil recharge', (tester) async {
      faux.repond('GET', '/messages/conversations/1/messages', []);
      faux.repond('POST', '/messages/conversations/1/messages', {});
      await monterEcran(tester, const ConversationScreen(conversation: conv));
      await tester.enterText(find.byType(TextField), '  Bonsoir ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(faux.recues('POST', '/messages/conversations/1/messages').single.data, {'content': 'Bonsoir'});
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(faux.recues('GET', '/messages/conversations/1/messages'), hasLength(2));
    });
  });
}
