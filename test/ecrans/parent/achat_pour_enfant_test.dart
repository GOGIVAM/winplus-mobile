import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/class_levels.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/buy_for_child_screen.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

const _zoe = ApiChild(id: 4, firstName: 'Zoe', lastName: 'Eto', level: 'BAC');
const _leo = ApiChild(id: 5, firstName: 'Leo', lastName: 'Eto');

Map<String, dynamic> _sujet(int id, String titre, {num prix = 1000, bool gratuit = false}) =>
    {'id': id, 'title': titre, 'price': prix, 'isFree': gratuit, 'category': 'epreuve', 'subjectCategory': 'maths'};

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  testWidgets('solde du portefeuille parent et nom du plan', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': {'creditsLeft': 4500, 'planName': 'Famille', 'currency': 'XAF'}});
    faux.repond('GET', '/subjects', {'items': []});
    telephone(tester);
    await monter(tester, ecran(const BuyForChildScreen(children: [_zoe, _leo])));
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.parentBuyBalance), findsOneWidget);
    expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
    expect(find.text('Famille'), findsOneWidget);
  });

  testWidgets('sans abonnement payant : message dedie a la place du solde', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': null});
    faux.repond('GET', '/subjects', {'items': []});
    await monterEcran(tester, const BuyForChildScreen(children: [_zoe]));
    expect(find.text(L10n.current.parentBuyNoSubscription), findsOneWidget);
  });

  testWidgets('serveur en panne : « impossible de charger » et Reessayer, pas « sans abonnement »', (tester) async {
    faux.repond('GET', '/parent/credits', {'error': 'panne'}, statut: 500);
    faux.repond('GET', '/subjects', {'items': []});
    await monterEcran(tester, const BuyForChildScreen(children: [_zoe]));
    final l = L10n.current;
    expect(find.text(l.commonLoadError), findsOneWidget);
    expect(find.text(l.parentBuyNoSubscription), findsNothing);
    faux.repond('GET', '/parent/credits', {'data': null});
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.parentBuyNoSubscription), findsOneWidget);
  });

  testWidgets('catalogue filtre par le niveau de l\'enfant, titre, prix et bouton « acheter pour »', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': null});
    faux.repond('GET', '/subjects', {
      'items': [_sujet(1, 'Epreuve A'), _sujet(2, 'Epreuve B', gratuit: true), _sujet(3, 'Epreuve C', prix: 2500)],
    });
    await monterEcran(tester, const BuyForChildScreen(children: [_zoe, _leo]));
    final l = L10n.current;
    expect(faux.recues('GET', '/subjects').single.queryParameters['level'], 'BAC');
    expect(faux.recues('GET', '/subjects').single.queryParameters['pageSize'], 6);
    expect(find.text('Epreuve A'), findsOneWidget);
    expect(find.text(l.commonFree), findsOneWidget);
    expect(find.text('${fmtXaf(2500)} XAF'), findsOneWidget);
    expect(find.widgetWithText(WinButton, l.parentBuyFor('Zoe')), findsWidgets);
    expect(find.text('Zoe (${ClassLevels.label('BAC')})'), findsOneWidget);
    expect(find.text('Leo (${l.roleStudent})'), findsOneWidget);
  });

  testWidgets('moins de 3 resultats pour le niveau : repli sur le catalogue general', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': null});
    faux.repond('GET', '/subjects', {
      'items': [_sujet(1, 'Epreuve A')],
    });
    await monterEcran(tester, const BuyForChildScreen(children: [_zoe]));
    final appels = faux.recues('GET', '/subjects');
    expect(appels, hasLength(2));
    expect(appels.first.queryParameters['level'], 'BAC');
    expect(appels.last.queryParameters.containsKey('level'), isFalse);
  });

  testWidgets('catalogue vide ou en erreur : message « aucun contenu »', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': null});
    faux.repond('GET', '/subjects', {}, statut: 500);
    await monterEcran(tester, const BuyForChildScreen(children: [_leo]));
    expect(find.text(L10n.current.parentBuyNoContent), findsOneWidget);
  });

  testWidgets('choisir un autre enfant recharge le catalogue sans niveau', (tester) async {
    faux.repond('GET', '/parent/credits', {'data': null});
    faux.repond('GET', '/subjects', {
      'items': [_sujet(1, 'A'), _sujet(2, 'B'), _sujet(3, 'C')],
    });
    await monterEcran(tester, const BuyForChildScreen(children: [_zoe, _leo]));
    await tester.tap(find.text('Leo (${L10n.current.roleStudent})'));
    await reseau(tester);
    expect(faux.recues('GET', '/subjects').last.queryParameters.containsKey('level'), isFalse);
    expect(find.text(L10n.current.parentBuyRecommended('Leo', '')), findsOneWidget);
  });
}
