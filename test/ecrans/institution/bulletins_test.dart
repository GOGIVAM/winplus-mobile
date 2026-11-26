import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/bulletins_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/bulletin_view.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : bulletins (établissement : préparer, partager ; élève et parent : lire).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> donnees() => {
        'studentId': 30, 'studentName': 'Paul Eto', 'institutionName': 'Lycee Leclerc', 'classes': ['Tle C'],
        'from': '2026-09-01T00:00:00Z', 'to': '2026-11-30T23:59:59Z',
        'average': 70.0, 'classAverage': 60.0, 'rank': 3, 'classSize': 28,
        'subjects': [{'subject': 'Maths', 'average': 80.0, 'quizzes': 6, 'classAverage': 65.0}],
        'homeworkGiven': 4, 'homeworkDone': 3, 'homeworkAverage': 75.0, 'activeDays': 21, 'studyMinutes': 125, 'quizCount': 9,
      };

  testWidgets('apercu, appreciation et partage depuis un eleve choisi', (tester) async {
    faux.repond('GET', '/institution/bulletins/preview', {'data': donnees(), 'success': true});
    faux.repond('POST', '/institution/bulletins/appreciation', {'data': {'appreciation': 'Tres bon trimestre.', 'source': 'winai'}, 'success': true});
    faux.repond('POST', '/institution/bulletins', {'data': {'id': 5, 'parents': 2}, 'success': true});
    faux.repond('GET', '/institution/me', {'data': {'id': 4, 'name': 'Lycee Leclerc'}, 'success': true});
    faux.repond('GET', '/institution/4/students', {
      'items': [{'id': 900, 'studentId': 30, 'firstName': 'Paul', 'lastName': 'Eto', 'email': 'p@x.cm', 'group': 'Tle C'}],
    });
    tester.view.physicalSize = const Size(800, 5000);
    await monterEcran(tester, const BulletinPrepareScreen());
    tester.view.physicalSize = const Size(800, 5000);
    await pomper(tester);
    final l = L10n.current;
    await tester.enterText(find.byType(TextField).first, 'paul');
    await reseau(tester);
    expect(faux.recues('GET', '/institution/4/students').last.queryParameters['search'], 'paul');
    await tester.tap(find.text('Paul Eto'));
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.bullPreview));
    await reseau(tester);
    expect(faux.recues('GET', '/institution/bulletins/preview').single.queryParameters['studentId'], 30,
        reason: 'le compte de l\'eleve, pas la ligne de rattachement');
    expect(find.text('14/20'), findsOneWidget);
    expect(find.text('3 / 28'), findsOneWidget);
    expect(find.text('2 h 05'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.bullShare));
    await pomper(tester);
    expect(find.text(l.bullNeedLabel), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, l.bullLabelHint), '1er trimestre');
    await tester.tap(find.widgetWithText(WinButton, l.bullWriteWithWinai));
    await reseau(tester);
    expect(find.text('Tres bon trimestre.'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.bullShare));
    await reseau(tester);
    final envoi = faux.recues('POST', '/institution/bulletins').single.data as Map;
    expect(envoi['studentId'], 30);
    expect(envoi['periodLabel'], '1er trimestre');
    expect(envoi['appreciation'], 'Tres bon trimestre.');
    expect(envoi['from'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  testWidgets('etablissement : bulletins partages et retrait', (tester) async {
    faux.repond('GET', '/institution/bulletins', {'data': [
      {'id': 5, 'studentId': 30, 'studentName': 'Paul Eto', 'periodLabel': '1er trimestre', 'sharedAt': '2026-11-20T10:00:00Z'},
    ], 'success': true});
    faux.repond('DELETE', '/institution/bulletins/5', {'success': true});
    await monterEcran(tester, const InstitutionBulletinsScreen());
    final l = L10n.current;
    expect(find.text('1er trimestre'), findsOneWidget);
    await tester.tap(find.byTooltip(l.bullDelete));
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(TextButton, l.bullDelete));
    await reseau(tester);
    expect(faux.recues('DELETE', '/institution/bulletins/5'), hasLength(1));
  });

  testWidgets('eleve : mes bulletins puis lecture avec appreciation', (tester) async {
    faux.repond('GET', '/institution/bulletins/mine', {'data': [
      {'id': 5, 'studentId': 30, 'studentName': 'Paul Eto', 'periodLabel': '1er trimestre', 'sharedAt': '2026-11-20T10:00:00Z', 'institutionName': 'Lycee Leclerc'},
    ], 'success': true});
    faux.repond('GET', '/institution/bulletins/5', {'data': {
      'id': 5, 'periodLabel': '1er trimestre', 'appreciation': 'Continue ainsi.', 'institutionName': 'Lycee Leclerc', 'bulletin': donnees(),
    }, 'success': true});
    await monterEcran(tester, const MyBulletinsScreen());
    await tester.tap(find.text('1er trimestre'));
    await reseau(tester);
    expect(find.text('Paul Eto'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Continue ainsi.'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Continue ainsi.'), findsOneWidget);
  });

  testWidgets('eleve sans bulletin : explication', (tester) async {
    faux.repond('GET', '/institution/bulletins/mine', {'data': [], 'success': true});
    await monterEcran(tester, const MyBulletinsScreen());
    expect(find.text(L10n.current.bullMineEmptyTitle), findsOneWidget);
  });
}
