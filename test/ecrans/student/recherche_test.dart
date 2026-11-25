import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/search_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  Future<void> saisir(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(TextField), q);
    await pomper(tester, const Duration(milliseconds: 500));
    await reseau(tester);
  }

  testWidgets('etat initial : invitation a chercher, aucune requete', (tester) async {
    await monterEcran(tester, const SearchScreen());
    expect(find.text(L10n.current.studentSearchIdle), findsOneWidget);
    expect(faux.requetes, isEmpty);
  });

  testWidgets('la recherche est declenchee apres 400 ms avec le terme rogne et 30 resultats par page', (tester) async {
    faux.repond('GET', '/subjects', {'items': []});
    await monterEcran(tester, const SearchScreen());
    await tester.enterText(find.byType(TextField), '  maths ');
    await pomper(tester, const Duration(milliseconds: 100));
    expect(faux.requetes, isEmpty);
    await pomper(tester, const Duration(milliseconds: 500));
    await reseau(tester);
    final q = faux.recues('GET', '/subjects').single.queryParameters;
    expect(q['q'], 'maths');
    expect(q['pageSize'], 30);
    expect(q.containsKey('category'), isFalse);
  });

  testWidgets('resultats affiches dans une grille', (tester) async {
    faux.repond('GET', '/subjects', {
      'items': [
        {'id': 1, 'title': 'Epreuve de maths BAC', 'category': 'epreuve', 'level': 'BAC', 'price': 500},
        {'id': 2, 'title': 'Livre de physique', 'category': 'livre', 'isFree': true},
      ],
    });
    await monterEcran(tester, const SearchScreen());
    await saisir(tester, 'maths');
    expect(find.text('Epreuve de maths BAC'), findsOneWidget);
    expect(find.text('Livre de physique'), findsOneWidget);
    expect(find.text(L10n.current.studentSearchNoResults('maths')), findsNothing);
  });

  testWidgets('aucun resultat : message avec le terme cherche', (tester) async {
    faux.repond('GET', '/subjects', {'items': []});
    await monterEcran(tester, const SearchScreen());
    await saisir(tester, 'xyz');
    expect(find.text(L10n.current.studentSearchNoResults('xyz')), findsOneWidget);
  });

  testWidgets('erreur serveur : meme etat « aucun resultat »', (tester) async {
    faux.repond('GET', '/subjects', {}, statut: 500);
    await monterEcran(tester, const SearchScreen());
    await saisir(tester, 'xyz');
    expect(find.text(L10n.current.studentSearchNoResults('xyz')), findsOneWidget);
  });

  testWidgets('filtres de type, niveau et langue sont envoyes avec le terme', (tester) async {
    faux.repond('GET', '/subjects', {'items': []});
    await monterEcran(tester, const SearchScreen());
    await saisir(tester, 'maths');
    await tester.tap(find.widgetWithText(WinChip, L10n.current.dataTypePaper));
    await reseau(tester);
    await tester.tap(find.widgetWithText(WinChip, 'BAC'));
    await reseau(tester);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.studentSearchLangEn));
    await reseau(tester);
    final q = faux.recues('GET', '/subjects').last.queryParameters;
    expect(q['category'], 'epreuve');
    expect(q['level'], 'BAC');
    expect(q['contentLanguage'], 'en');
  });

  testWidgets('changer de filtre sans terme ne lance aucune recherche', (tester) async {
    await monterEcran(tester, const SearchScreen());
    await tester.tap(find.widgetWithText(WinChip, 'BEPC'));
    await reseau(tester);
    expect(faux.requetes, isEmpty);
  });

  testWidgets('la croix efface le terme et les resultats', (tester) async {
    faux.repond('GET', '/subjects', {
      'items': [
        {'id': 1, 'title': 'Epreuve A'},
      ],
    });
    await monterEcran(tester, const SearchScreen());
    await saisir(tester, 'a');
    expect(find.text('Epreuve A'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await pomper(tester);
    expect(find.text('Epreuve A'), findsNothing);
    expect(find.text(L10n.current.studentSearchIdle), findsOneWidget);
  });
}
