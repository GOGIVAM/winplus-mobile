import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/dropout_alerts_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : alertes de décrochage du professeur (GET /teacher/alertes-decrochage,
/// POST /teacher/alertes/{id}/relancer), comme le panneau du site.
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> alerte(int id, String eleve) => {
        'id': id, 'courseId': 3, 'courseTitle': 'Maths Terminale', 'studentUserId': 40 + id,
        'studentName': eleve, 'niveau': 'eleve',
        'signaux': ['Inactif depuis 9 jours', 'Leçon 4 abandonnée'],
        'dateDetection': '2026-11-20T08:00:00Z',
      };

  testWidgets('alertes : eleve, formation, signaux, date ; relancer retire l\'alerte', (tester) async {
    faux.repond('GET', '/teacher/alertes-decrochage', [alerte(1, 'Zoe Eto'), alerte(2, 'Leo Mba')]);
    faux.repond('POST', '/teacher/alertes/1/relancer', {'sent': true});
    await monterEcran(tester, const DropoutAlertsScreen());
    final l = L10n.current;
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(find.text('Maths Terminale'), findsNWidgets(2));
    expect(find.text('Inactif depuis 9 jours'), findsNWidgets(2));
    expect(find.text(l.dpRelaunchAll(2)), findsOneWidget);
    await tester.tap(find.text(l.dpRelaunch).first);
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/alertes/1/relancer'), hasLength(1));
    expect(find.text('Zoe Eto'), findsNothing);
    expect(find.text(l.dpSent('Zoe Eto')), findsOneWidget);
  });

  testWidgets('tout relancer apres confirmation : chaque alerte, puis plus rien a relancer', (tester) async {
    faux.repond('GET', '/teacher/alertes-decrochage', [alerte(1, 'Zoe Eto'), alerte(2, 'Leo Mba')]);
    faux.repond('POST', '/teacher/alertes/1/relancer', {'sent': true});
    faux.repond('POST', '/teacher/alertes/2/relancer', {'sent': true});
    await monterEcran(tester, const DropoutAlertsScreen());
    final l = L10n.current;
    await tester.tap(find.text(l.dpRelaunchAll(2)));
    await reseau(tester);
    expect(find.text(l.dpConfirmAll(2)), findsOneWidget);
    await tester.tap(find.text(l.dpRelaunch).last);
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/alertes/1/relancer'), hasLength(1));
    expect(faux.recues('POST', '/teacher/alertes/2/relancer'), hasLength(1));
    expect(find.text(l.dpEmpty), findsOneWidget);
    expect(find.text(l.dpSentMany(2)), findsOneWidget);
  });

  testWidgets('relance refusee : l\'alerte reste, message d\'erreur', (tester) async {
    faux.repond('GET', '/teacher/alertes-decrochage', [alerte(1, 'Zoe Eto')]);
    faux.repond('POST', '/teacher/alertes/1/relancer', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const DropoutAlertsScreen());
    final l = L10n.current;
    await tester.tap(find.text(l.dpRelaunch));
    await reseau(tester);
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(find.text(l.dpSendError), findsOneWidget);
  });

  testWidgets('aucune alerte : message ; panne : erreur et Reessayer', (tester) async {
    final l = L10n.current;
    faux.repond('GET', '/teacher/alertes-decrochage', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const DropoutAlertsScreen());
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/teacher/alertes-decrochage', []);
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.dpEmpty), findsOneWidget);
  });
}
