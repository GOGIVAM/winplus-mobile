import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/teachers_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : enseignants de l'établissement.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes({bool vide = false}) {
    faux.repond('GET', '/institution/teachers', {
      'data': vide
          ? {'teachers': [], 'received': [], 'sent': []}
          : {
              'teachers': [
                {'linkId': 5, 'id': 50, 'firstName': 'Marie', 'lastName': 'Ngo', 'email': 'm@x.cm', 'contents': 4, 'published': 3, 'quizzes': 2,
                 'classes': [{'id': 1, 'name': 'Tle C'}]},
              ],
              'received': [{'linkId': 7, 'id': 51, 'firstName': 'Ali', 'lastName': 'Bello', 'email': 'a@x.cm'}],
              'sent': [{'linkId': 8, 'id': 52, 'firstName': 'Eva', 'lastName': 'Mba'}],
            },
      'success': true,
    });
    faux.repond('GET', '/institution/groups', [
      {'id': 1, 'name': 'Tle C', 'level': 'Tle'},
      {'id': 2, 'name': 'Tle D', 'level': 'Tle'},
    ]);
  }

  Future<void> ouvrir(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
  }

  testWidgets('liste : demande recue, affilie avec chiffres et classe, invitation envoyee', (tester) async {
    routes();
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const InstitutionTeachersScreen());
    final l = L10n.current;
    expect(find.text(l.teachReceived(1)), findsOneWidget);
    expect(find.text('Marie Ngo'), findsOneWidget);
    expect(find.text(l.teachStats(4, 3, 2)), findsOneWidget);
    expect(find.widgetWithText(WinChip, 'Tle C'), findsOneWidget);
    expect(find.text(l.teachSent(1)), findsOneWidget);
  });

  testWidgets('accepter une demande ; affecter a une classe libre', (tester) async {
    routes();
    faux.repond('PUT', '/institution-network/affiliation/7/accept', {'success': true});
    faux.repond('POST', '/institution/teachers/groups/2', {'success': true});
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const InstitutionTeachersScreen());
    final l = L10n.current;
    await tester.tap(find.widgetWithText(WinButton, l.teachAccept));
    await reseau(tester);
    expect(faux.recues('PUT', '/institution-network/affiliation/7/accept'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await ouvrir(tester, find.widgetWithText(WinChip, l.teachAssign));
    expect(find.text('Tle C'), findsOneWidget, reason: 'classe deja prise : seulement dans la carte');
    await ouvrir(tester, find.text('Tle D'));
    await reseau(tester);
    expect(faux.recues('POST', '/institution/teachers/groups/2').single.data, {'teacherId': 50});
  });

  testWidgets('retirer d\'une classe et mettre fin a l\'affiliation, apres confirmation', (tester) async {
    routes();
    faux.repond('DELETE', '/institution/teachers/groups/1/50', {'success': true});
    faux.repond('DELETE', '/institution-network/affiliation/5', {'success': true});
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const InstitutionTeachersScreen());
    final l = L10n.current;
    await ouvrir(tester, find.widgetWithText(WinChip, 'Tle C'));
    await tester.tap(find.widgetWithText(TextButton, l.teachUnassign));
    await reseau(tester);
    expect(faux.recues('DELETE', '/institution/teachers/groups/1/50'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await ouvrir(tester, find.byTooltip(l.teachRevoke));
    await tester.tap(find.widgetWithText(TextButton, l.teachRevoke));
    await reseau(tester);
    expect(faux.recues('DELETE', '/institution-network/affiliation/5'), hasLength(1));
  });

  testWidgets('vide : inviter un enseignant par recherche', (tester) async {
    routes(vide: true);
    faux.repond('GET', '/institution-network/search-teachers', [
      {'id': 60, 'firstName': 'Jean', 'lastName': 'Abena', 'email': 'j@x.cm'},
    ]);
    faux.repond('POST', '/institution-network/affiliation/request', {'success': true});
    await monterEcran(tester, const InstitutionTeachersScreen());
    final l = L10n.current;
    expect(find.text(l.teachEmptyTitle), findsOneWidget);
    await ouvrir(tester, find.text(l.teachInvite).last);
    await tester.enterText(find.byType(TextField), 'jean');
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await ouvrir(tester, find.text('Jean Abena'));
    await reseau(tester);
    expect(faux.recues('POST', '/institution-network/affiliation/request').single.data, {'teacherId': 60});
  });
}
