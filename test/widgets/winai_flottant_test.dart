import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show WinRole;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/parent_tabs.dart' show ParentWinAITab;
import 'package:winplus/student/student_tabs.dart' show StudentWinAITab;
import 'package:winplus/widgets/win_widgets.dart' show WinAIIcon;
import 'package:winplus/widgets/winai_floating_widget.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Page factice : un texte sous le bouton flottant, pour verifier que le
/// contenu de la coque reste affiche.
Widget _coque(WinRole role) => Scaffold(
      body: WinAIFloatingWidget(role: role, child: const Center(child: Text('contenu de la page'))),
    );

/// Le bouton rond (robot WinAI, comme sur le site) est le dernier de la pile : il passe au-dessus de la carte.
Finder _bouton() => find.byType(WinAIIcon).last;

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  testWidgets('au repos : le contenu est affiche et le bouton se place a droite, au-dessus des barres d action du bas', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    expect(find.text('contenu de la page'), findsOneWidget);
    expect(find.text('WinAI'), findsNothing);
    final coin = tester.getBottomRight(find.ancestor(of: _bouton(), matching: find.byType(Container)).first);
    final zone = tester.getBottomRight(find.byType(Scaffold));
    expect(zone.dx - coin.dx, 16);
    // 88 points du bas : au-dessus d'un bouton d'action ou d'un champ de message.
    expect(zone.dy - coin.dy, 88);
  });

  testWidgets('en bas d une liste, le bouton s efface pour laisser voir la derniere ligne, puis revient', (tester) async {
    await monterEcran(
        tester,
        Scaffold(
            body: WinAIFloatingWidget(
                role: WinRole.student,
                child: ListView(children: [
                  for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('ligne $i')),
                ]))));
    expect(find.byKey(const ValueKey('winai-fab')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text('ligne 39'), findsOneWidget);
    expect(find.byKey(const ValueKey('winai-fab')), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('winai-fab')), findsOneWidget);
  });

  testWidgets('toucher le bouton ouvre la mini-carte : titre, sous-titre du role et quatre suggestions', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    final l = L10n.current;
    expect(find.text('WinAI'), findsOneWidget);
    expect(find.text(l.studentTabsAiTagline), findsOneWidget);
    for (final s in [l.studentTabsAiSuggest1, l.studentTabsAiSuggest2, l.studentTabsAiSuggest3, l.studentTabsAiSuggest4]) {
      expect(find.text(s), findsOneWidget);
    }
    expect(find.text(l.commonWinaiMemory), findsOneWidget);
    expect(find.widgetWithText(TextField, l.aiAskHint), findsOneWidget);
  });

  testWidgets('chaque role a son sous-titre et sa premiere suggestion', (tester) async {
    final l = L10n.current;
    final cas = <WinRole, (String, String)>{
      WinRole.student: (l.studentTabsAiTagline, l.studentTabsAiSuggest1),
      WinRole.parent: (l.parentAiTagline, l.parentAiSuggestion1),
      WinRole.teacher: (l.teacherAiTagline, l.teacherAiSuggestQuiz),
      WinRole.institution: (l.instAiTagline, l.instAiSuggestion1),
    };
    for (final e in cas.entries) {
      await monterEcran(tester, _coque(e.key));
      await tester.tap(_bouton());
      await pomper(tester);
      expect(find.text(e.value.$1), findsOneWidget, reason: '${e.key} : sous-titre');
      expect(find.text(e.value.$2), findsOneWidget, reason: '${e.key} : suggestion');
      await monter(tester, const SizedBox());
    }
  });

  testWidgets('la croix, le voile et un second appui sur le bouton referment la carte', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    expect(find.text('WinAI'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await pomper(tester);
    expect(find.text('WinAI'), findsNothing);
    // Voile : un appui en haut de l'ecran, hors carte.
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tapAt(const Offset(200, 20));
    await pomper(tester);
    expect(find.text('WinAI'), findsNothing);
    // Second appui sur le bouton.
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tap(_bouton());
    await pomper(tester);
    expect(find.text('WinAI'), findsNothing);
  });

  testWidgets('une suggestion ouvre la conversation du role avec ce message, la carte se ferme', (tester) async {
    faux.repond('POST', '/chatbot/message', {'reply': 'Bien sur'});
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    final suggestion = L10n.current.studentTabsAiSuggest2;
    await tester.tap(find.text(suggestion));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    final conversation = tester.widget<StudentWinAITab>(find.byType(StudentWinAITab));
    expect(conversation.initialMessage, suggestion);
    expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], suggestion);
    expect(find.text('Bien sur'), findsOneWidget);
  });

  testWidgets('role parent : la conversation ouverte est celle du parent', (tester) async {
    faux.repond('POST', '/chatbot/message', {'reply': 'Voici un plan'});
    await monterEcran(tester, _coque(WinRole.parent));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tap(find.text(L10n.current.parentAiSuggestion2));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(ParentWinAITab), findsOneWidget);
    expect(find.text('Voici un plan'), findsOneWidget);
  });

  testWidgets('saisie puis bouton d\'envoi : message rogne transmis a la conversation', (tester) async {
    faux.repond('POST', '/chatbot/message', {'reply': 'D\'accord'});
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.enterText(find.byType(TextField), '  Explique les limites ');
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(tester.widget<StudentWinAITab>(find.byType(StudentWinAITab)).initialMessage, 'Explique les limites');
    expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Explique les limites');
  });

  testWidgets('validation au clavier : meme resultat que le bouton d\'envoi', (tester) async {
    faux.repond('POST', '/chatbot/message', {'reply': 'D\'accord'});
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(tester.widget<StudentWinAITab>(find.byType(StudentWinAITab)).initialMessage, 'Bonjour');
  });

  testWidgets('envoi sans texte : la conversation s\'ouvre mais aucun message n\'est envoye', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(StudentWinAITab), findsOneWidget);
    expect(faux.recues('POST', '/chatbot/message'), isEmpty);
  });

  testWidgets('icone « agrandir » : conversation complete sans message initial', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowsOut));
    // Premiere image de la page poussee : hors scene ; la suivante l'affiche.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(tester.widget<StudentWinAITab>(find.byType(StudentWinAITab)).initialMessage, isNull);
    expect(faux.recues('POST', '/chatbot/message'), isEmpty);
  });

  testWidgets('« Memoire de WinAI » : ferme la carte et ouvre la feuille des memoires', (tester) async {
    faux.repond('GET', '/chatbot/memories', []);
    await monterEcran(tester, _coque(WinRole.student));
    await tester.tap(_bouton());
    await pomper(tester);
    await tester.tap(find.text(L10n.current.commonWinaiMemory));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(faux.recues('GET', '/chatbot/memories'), hasLength(1));
    expect(find.text(L10n.current.widgetMemSubtitle), findsOneWidget);
    expect(find.text(L10n.current.studentTabsAiTagline), findsNothing);
  });

  testWidgets('glisser le bouton le deplace, sans sortir de l\'ecran (8 points de marge)', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    final avant = tester.getCenter(_bouton());
    await tester.drag(_bouton(), const Offset(-150, -200));
    await pomper(tester);
    final apres = tester.getCenter(_bouton());
    // Le geste ne perd qu'une petite distance de depart : au moins 100 et 150 points parcourus.
    expect(apres.dx, lessThan(avant.dx - 100));
    expect(apres.dy, lessThan(avant.dy - 150));
    // Trop loin vers le haut et la gauche : bloque a 8 points du bord.
    await tester.drag(_bouton(), const Offset(-900, -1500));
    await pomper(tester);
    final coin = tester.getTopLeft(find.ancestor(of: _bouton(), matching: find.byType(Container)).first);
    expect(coin.dx, 8);
    expect(coin.dy, 8);
  });

  testWidgets('un glisser ne doit pas ouvrir la carte', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.drag(_bouton(), const Offset(-100, 0));
    await pomper(tester);
    expect(find.text('WinAI'), findsNothing);
  });

  // Bug probable (lecture du code) : « _dragged » passe a vrai pendant un
  // glissement et n'est remis a faux qu'au debut du glissement suivant ; un
  // simple appui apres un deplacement est donc ignore et le bouton ne rouvre
  // plus jamais la carte tant qu'on ne le glisse pas a nouveau.
  testWidgets('BUG PROBABLE : apres un deplacement, un simple appui ouvre la carte', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.drag(_bouton(), const Offset(-100, 0));
    await pomper(tester);
    await tester.tap(_bouton());
    await pomper(tester);
    expect(find.text('WinAI'), findsOneWidget);
  });

  // Corrige (lot 4, constate sur telephone) : les ancrages de la carte sont inverses.
  // Bouton dans la moitie haute : la carte est ancree par son bord BAS a
  // « hauteur - y - 58 + 16 » du bas de l'ecran, donc presque tout en haut, et
  // elle depasse au-dessus de l'ecran ; bouton en bas, elle est ancree par le
  // haut a « hauteur - y + 16 ». La carte doit rester entierement visible et
  // ne pas recouvrir le bouton.
  testWidgets('bouton en haut de l ecran, la carte reste visible sous le bouton', (tester) async {
    await monterEcran(tester, _coque(WinRole.student));
    await tester.drag(_bouton(), const Offset(0, -600));
    await pomper(tester);
    await tester.tap(_bouton());
    await pomper(tester);
    final bouton = tester.getRect(_bouton());
    final titre = tester.getRect(find.text('WinAI'));
    expect(titre.top, greaterThanOrEqualTo(0));
    expect(titre.top, greaterThan(bouton.bottom));
  });
}
