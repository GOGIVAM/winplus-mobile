import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/teacher_library_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : bibliothèque du professeur (contenus, dossiers, rangement, classes).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> achete() => {
        'subjectId': 5, 'title': 'Annales Maths 2024', 'category': 'Maths', 'source': 'purchased',
        'tags': [], 'acquiredAt': '2026-11-01T00:00:00Z',
      };
  Map<String, dynamic> range() => {
        'subjectId': 7, 'title': 'Physique : ondes', 'category': 'Physique', 'source': 'organized',
        'favoriteId': 3, 'collectionId': 1, 'collectionName': 'Terminale', 'tags': ['Difficile', 'TP'],
        'notes': 'Pour la seance 4', 'acquiredAt': '2026-11-02T00:00:00Z',
      };

  void routes({List? items}) {
    faux.repond('GET', '/library/me', {'data': items ?? [range(), achete()], 'success': true});
    faux.repond('GET', '/favorite-collections', {'success': true, 'data': [{'id': 1, 'name': 'Terminale'}], 'count': 1});
  }

  Future<void> ouvrir(WidgetTester tester, String titre) async {
    await tester.tap(find.text(titre).last);
    // Première image : la feuille démarre son animation ; seconde : en place.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
  }

  testWidgets('liste : source, dossier, tags traduits, note ; dossiers en puces', (tester) async {
    routes();
    await monterEcran(tester, const TeacherLibraryScreen());
    final l = L10n.current;
    expect(find.text('Annales Maths 2024'), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.libPurchased), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.libOrganized), findsOneWidget);
    expect(find.text('Physique · Terminale'), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.libTagHard), findsOneWidget);
    expect(find.widgetWithText(WinBadge, 'TP'), findsOneWidget);
    expect(find.text('Pour la seance 4'), findsOneWidget);
    expect(find.widgetWithText(WinChip, 'Terminale'), findsOneWidget);
  });

  testWidgets('filtres : dossier et annotes envoyes au serveur ; recherche', (tester) async {
    routes();
    await monterEcran(tester, const TeacherLibraryScreen());
    await tester.tap(find.widgetWithText(WinChip, 'Terminale'));
    await reseau(tester);
    expect(faux.recues('GET', '/library/me').last.queryParameters['collectionId'], 1);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.libAnnotated));
    await reseau(tester);
    expect(faux.recues('GET', '/library/me').last.queryParameters['annotatedOnly'], true);
    await tester.enterText(find.byType(TextField), 'ondes');
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(faux.recues('GET', '/library/me').last.queryParameters['q'], 'ondes');
  });

  testWidgets('ranger : dossier, tag propose, tag libre et note envoyes', (tester) async {
    routes();
    faux.repond('POST', '/library/5/organize', {'success': true, 'favoriteId': 9});
    await monterEcran(tester, const TeacherLibraryScreen());
    final l = L10n.current;
    await ouvrir(tester, 'Annales Maths 2024');
    await ouvrir(tester, l.libOrganize);
    await tester.tap(find.widgetWithText(WinChip, 'Terminale').last);
    await tester.tap(find.widgetWithText(WinChip, l.libTagReview));
    await tester.enterText(find.widgetWithText(TextField, l.libAddTag), 'Bac blanc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pomper(tester);
    await tester.enterText(find.widgetWithText(TextField, l.libNotesHint), 'A revoir');
    await tester.ensureVisible(find.widgetWithText(WinButton, l.libSave));
    await tester.tap(find.widgetWithText(WinButton, l.libSave));
    await reseau(tester);
    expect(faux.recues('POST', '/library/5/organize').single.data,
        {'collectionId': 1, 'tags': ['À réviser', 'Bac blanc'], 'notes': 'A revoir'});
    expect(find.text(l.libSaved), findsOneWidget);
  });

  testWidgets('ranger sans dossier : clearCollection', (tester) async {
    routes();
    faux.repond('POST', '/library/7/organize', {'success': true, 'favoriteId': 3});
    await monterEcran(tester, const TeacherLibraryScreen());
    final l = L10n.current;
    await ouvrir(tester, 'Physique : ondes');
    await ouvrir(tester, l.libOrganize);
    await tester.tap(find.widgetWithText(WinChip, l.libNoFolder));
    await tester.ensureVisible(find.widgetWithText(WinButton, l.libSave));
    await tester.tap(find.widgetWithText(WinButton, l.libSave));
    await reseau(tester);
    final envoi = faux.recues('POST', '/library/7/organize').single.data as Map;
    expect(envoi['clearCollection'], true);
    expect(envoi.containsKey('collectionId'), isFalse);
    expect(envoi['tags'], ['Difficile', 'TP']);
  });

  testWidgets('assigner a une classe : montant debite ; solde insuffisant explique', (tester) async {
    routes();
    faux.repond('GET', '/teacher/classes', [{'id': 4, 'name': 'Tle C2'}]);
    faux.repond('POST', '/teacher/classes/4/content', {'data': {'id': 11, 'priceCharged': 2500}, 'success': true});
    await monterEcran(tester, const TeacherLibraryScreen());
    final l = L10n.current;
    await ouvrir(tester, 'Annales Maths 2024');
    await ouvrir(tester, l.libAssignClass);
    await reseau(tester);
    await ouvrir(tester, 'Tle C2');
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/classes/4/content').single.data, {'subjectId': 5});
    expect(find.textContaining('Tle C2'), findsOneWidget);
    expect(find.textContaining('2'), findsWidgets);

    faux.repond('POST', '/teacher/classes/4/content',
        {'success': false, 'error': 'Solde insuffisant', 'balanceXaf': 500, 'requiredXaf': 2500}, statut: 402);
    await tester.pump(const Duration(seconds: 5));
    await ouvrir(tester, 'Annales Maths 2024');
    await ouvrir(tester, l.libAssignClass);
    await reseau(tester);
    await ouvrir(tester, 'Tle C2');
    await reseau(tester);
    expect(find.textContaining(l.libAssignNoBalance('', '').split(':').first), findsOneWidget);
  });

  testWidgets('dossiers : creer, renommer et supprimer (appui long)', (tester) async {
    routes();
    faux.repond('POST', '/favorite-collections', {'success': true, 'data': {'id': 2, 'name': 'Premiere'}});
    faux.repond('PUT', '/favorite-collections/1', {'success': true, 'data': {'id': 1, 'name': 'Tle'}});
    faux.repond('DELETE', '/favorite-collections/1', {'success': true});
    await monterEcran(tester, const TeacherLibraryScreen());
    final l = L10n.current;
    await tester.ensureVisible(find.widgetWithText(WinChip, l.libNewFolder));
    await ouvrir(tester, l.libNewFolder);
    await tester.enterText(find.byType(TextField).last, 'Premiere');
    await tester.tap(find.text(l.commonConfirm));
    await reseau(tester);
    expect((faux.recues('POST', '/favorite-collections').single.data as Map)['name'], 'Premiere');

    await tester.ensureVisible(find.widgetWithText(WinChip, 'Terminale'));
    await tester.longPress(find.widgetWithText(WinChip, 'Terminale'));
    await pomper(tester, const Duration(milliseconds: 400));
    await ouvrir(tester, l.libRenameFolder);
    await tester.enterText(find.byType(TextField).last, 'Tle');
    await tester.tap(find.text(l.commonConfirm));
    await reseau(tester);
    expect((faux.recues('PUT', '/favorite-collections/1').single.data as Map)['name'], 'Tle');

    await tester.ensureVisible(find.widgetWithText(WinChip, 'Terminale'));
    await tester.longPress(find.widgetWithText(WinChip, 'Terminale'));
    await pomper(tester, const Duration(milliseconds: 400));
    await ouvrir(tester, l.libDeleteFolder);
    await tester.tap(find.widgetWithText(TextButton, l.libDeleteFolder));
    await reseau(tester);
    expect(faux.recues('DELETE', '/favorite-collections/1'), hasLength(1));
  });

  testWidgets('vide puis panne', (tester) async {
    routes(items: []);
    await monterEcran(tester, const TeacherLibraryScreen());
    expect(find.text(L10n.current.libEmptyTitle), findsOneWidget);
  });

  testWidgets('panne : erreur', (tester) async {
    faux.repond('GET', '/library/me', {'error': 'x'}, statut: 500);
    faux.repond('GET', '/favorite-collections', {'data': []});
    await monterEcran(tester, const TeacherLibraryScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });
}
