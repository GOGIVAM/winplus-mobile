import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/forum/thread_detail_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _sujet = {'id': 7, 'title': 'Comment factoriser ?', 'content': 'Je bloque sur x2 - 4', 'category': 'Questions'};

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('en-tete : categorie, titre et contenu du sujet', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', []);
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    expect(find.text(L10n.current.forumCatQuestions), findsOneWidget);
    expect(find.text('Comment factoriser ?'), findsOneWidget);
    expect(find.text('Je bloque sur x2 - 4'), findsOneWidget);
  });

  testWidgets('sans categorie : titre generique « Sujet »', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', []);
    await monterEcran(tester, const ThreadDetailScreen(thread: {'id': 7, 'title': 'T'}));
    expect(find.text(L10n.current.forumThread), findsOneWidget);
  });

  testWidgets('reponses lues sous forme { posts } : auteur, role, votes, reponse acceptee', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', {
      'posts': [
        {'id': 1, 'authorName': 'Prof Ngo', 'authorRole': 'teacher', 'content': 'Utilise (a-b)(a+b)', 'upvotes': 4, 'isAccepted': true},
        {'id': 2, 'content': 'Moi aussi', 'authorRole': 'parent'},
      ],
    });
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    final l = L10n.current;
    expect(find.text('Prof Ngo'), findsOneWidget);
    expect(find.text(l.forumRoleTeacher), findsOneWidget);
    expect(find.text('Utilise (a-b)(a+b)'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.checkCircle), findsOneWidget);
    expect(find.text(l.forumAnonymous), findsOneWidget);
    expect(find.text(l.roleParent), findsOneWidget);
  });

  testWidgets('erreur de chargement : le sujet reste affiche sans reponse', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', {}, statut: 500);
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Comment factoriser ?'), findsOneWidget);
  });

  testWidgets('reponse vide : rien n\'est envoye', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', []);
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await reseau(tester);
    expect(faux.recues('POST', '/forums/threads/7/posts'), isEmpty);
  });

  testWidgets('envoyer une reponse : appel serveur, champ vide, liste rechargee', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', []);
    faux.repond('POST', '/forums/threads/7/posts', {});
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    await tester.enterText(find.byType(TextField), '  Ma reponse ');
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await reseau(tester);
    expect(faux.recues('POST', '/forums/threads/7/posts').single.data, {'content': 'Ma reponse'});
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(faux.recues('GET', '/forums/threads/7/posts'), hasLength(2));
  });

  testWidgets('voter pour ou contre une reponse envoie le type de vote', (tester) async {
    faux.repond('GET', '/forums/threads/7/posts', [
      {'id': 1, 'content': 'R', 'upvotes': 0},
    ]);
    faux.repond('POST', '/forums/posts/1/vote', {});
    await monterEcran(tester, const ThreadDetailScreen(thread: _sujet));
    await tester.tap(find.byIcon(PhosphorIconsRegular.thumbsUp));
    await reseau(tester);
    await tester.tap(find.byIcon(PhosphorIconsRegular.thumbsDown));
    await reseau(tester);
    final votes = faux.recues('POST', '/forums/posts/1/vote').map((r) => r.data).toList();
    expect(votes, [
      {'type': 'up'},
      {'type': 'down'},
    ]);
  });
}
