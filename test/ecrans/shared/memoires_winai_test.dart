import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/winai_memories_sheet.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Widget _ouvreur() => Builder(
      builder: (c) => Scaffold(
        body: TextButton(onPressed: () => showWinAIMemoriesSheet(c), child: const Text('memoire')),
      ),
    );

Future<void> _ouvrir(WidgetTester tester) async {
  await tester.tap(find.text('memoire'));
  await pomper(tester);
  await pomper(tester, const Duration(milliseconds: 400));
  await reseau(tester);
}

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('titre, sous-titre et etat vide quand WinAI n\'a rien retenu', (tester) async {
    faux.repond('GET', '/chatbot/memories', []);
    await monterEcran(tester, _ouvreur());
    await _ouvrir(tester);
    final l = L10n.current;
    expect(find.text(l.commonWinaiMemory), findsOneWidget);
    expect(find.text(l.widgetMemSubtitle), findsOneWidget);
    expect(find.text(l.widgetMemEmpty), findsOneWidget);
  });

  testWidgets('memoires : type traduit et contenu', (tester) async {
    faux.repond('GET', '/chatbot/memories', [
      {'id': 1, 'type': 'struggling_topics', 'content': 'Difficulte en algebre'},
      {'id': 2, 'type': 'understood_topics', 'content': 'Les fractions sont acquises'},
      {'id': 3, 'type': 'inconnu', 'content': 'Autre note'},
    ]);
    await monterEcran(tester, _ouvreur());
    await _ouvrir(tester);
    final l = L10n.current;
    expect(find.text('Difficulte en algebre'), findsOneWidget);
    // Les memoires sont regroupees par type, sous un titre en majuscules.
    expect(find.text(l.widgetMemDifficulty.toUpperCase()), findsOneWidget);
    expect(find.text(l.widgetMemMastered.toUpperCase()), findsOneWidget);
    expect(find.text(l.widgetMemMemory.toUpperCase()), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(3));
  });

  testWidgets('supprimer une memoire : appel serveur puis disparition de la ligne', (tester) async {
    faux.repond('GET', '/chatbot/memories', [
      {'id': 1, 'type': 'exam_context', 'content': 'BAC en juin'},
      {'id': 2, 'type': 'exam_context', 'content': 'Objectif 14'},
    ]);
    faux.repond('DELETE', '/chatbot/memories/1', {});
    await monterEcran(tester, _ouvreur());
    await _ouvrir(tester);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await reseau(tester);
    expect(faux.recues('DELETE', '/chatbot/memories/1'), hasLength(1));
    expect(find.text('BAC en juin'), findsNothing);
    expect(find.text('Objectif 14'), findsOneWidget);
  });

  testWidgets('suppression refusee : message d\'echec et la ligne reste', (tester) async {
    faux.repond('GET', '/chatbot/memories', [
      {'id': 1, 'type': 'exam_context', 'content': 'BAC en juin'},
    ]);
    await monterEcran(tester, _ouvreur());
    await _ouvrir(tester);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await reseau(tester);
    expect(find.text(L10n.current.widgetMemDeleteFailed), findsOneWidget);
    expect(find.text('BAC en juin'), findsOneWidget);
  });

  testWidgets('actualiser relit les memoires', (tester) async {
    faux.repond('GET', '/chatbot/memories', []);
    await monterEcran(tester, _ouvreur());
    await _ouvrir(tester);
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await reseau(tester);
    expect(faux.recues('GET', '/chatbot/memories'), hasLength(2));
  });
}
