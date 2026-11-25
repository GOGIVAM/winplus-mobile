import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/shop/checkout_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _demonter(WidgetTester tester) => monter(tester, const SizedBox());

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void panier() {
    faux.repond('GET', '/cart', {
      'items': [
        {'id': 1, 'subjectId': 4, 'title': 'Maths BAC', 'price': 1500},
        {'id': 2, 'subjectId': 5, 'title': 'Physique', 'price': 2000},
      ],
      'itemsCount': 2,
      'subtotal': 3500,
      'tax': 700,
      'total': 3500,
    });
  }

  Future<void> payer(WidgetTester tester, String tel) async {
    await tester.enterText(find.byType(TextField), tel);
    final b = _bouton(L10n.current.shopPayAmount(fmtXaf(3500)));
    await tester.ensureVisible(b);
    await tester.tap(b);
    await reseau(tester);
  }

  testWidgets('chargement puis recapitulatif : articles, total et choix de l\'operateur', (tester) async {
    panier();
    telephone(tester);
    await monter(tester, ecran(const CheckoutScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.shopCheckoutStepSummary), findsOneWidget);
    expect(find.text(l.shopItemsCount(2)), findsOneWidget);
    expect(find.text('Maths BAC'), findsOneWidget);
    expect(find.text('${fmtXaf(2000)} XAF'), findsOneWidget);
    expect(find.text(l.shopPaymentMethod), findsOneWidget);
    expect(_bouton(l.shopPayAmount(fmtXaf(3500))), findsOneWidget);
  });

  testWidgets('panier vide : message « panier vide » et pas de paiement', (tester) async {
    faux.repond('GET', '/cart', {'items': []});
    await monterEcran(tester, const CheckoutScreen());
    expect(find.text(L10n.current.shopCartEmpty), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('numero trop court : message et aucune commande creee', (tester) async {
    panier();
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '6700');
    expect(find.text(L10n.current.shopInvalidPhone), findsOneWidget);
    expect(faux.recues('POST', '/orders'), isEmpty);
  });

  testWidgets('commande refusee : message du serveur affiche, etape inchangee', (tester) async {
    panier();
    faux.repond('POST', '/orders', {'error': 'Panier vide'}, statut: 400);
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '670000000');
    expect(find.text('Panier vide'), findsOneWidget);
    expect(find.text(L10n.current.shopCheckoutStepConfirm), findsNothing);
  });

  testWidgets('paiement refuse a l\'initiation : message du serveur', (tester) async {
    panier();
    faux.repond('POST', '/orders', {'id': 8, 'orderNumber': 'WP-8', 'totalAmount': 3500});
    faux.repond('POST', '/payments/initiate', {'message': 'Operateur indisponible'}, statut: 400);
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '670000000');
    expect(find.text('Operateur indisponible'), findsOneWidget);
  });

  testWidgets('commande puis paiement : numero au format 237, montant de la commande, etape d\'attente', (tester) async {
    panier();
    faux.repond('POST', '/orders', {'id': 8, 'orderNumber': 'WP-8', 'totalAmount': 3500});
    faux.repond('POST', '/payments/initiate', {'paymentId': 21, 'notchpayReference': 'trx.99', 'amount': 3500});
    faux.repond('GET', '/payments/21/status', {'id': 21, 'status': 'pending'});
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '+237 670 00 00 00');
    expect(faux.recues('POST', '/orders').single.data, {'paymentMethod': 'mobile_money'});
    expect(faux.recues('POST', '/payments/initiate').single.data, {'orderId': 8, 'phone': '237670000000', 'amount': 3500.0});
    final l = L10n.current;
    expect(find.text(l.shopCheckoutStepConfirm), findsWidgets);
    expect(find.text(l.shopAwaitingConfirmation), findsOneWidget);
    expect(find.text(l.shopReference('trx.99')), findsOneWidget);
    await _demonter(tester);
  });

  testWidgets('sondage toutes les 4 s : paiement confirme = ecran de succes', (tester) async {
    panier();
    faux.repond('POST', '/orders', {'id': 8, 'orderNumber': 'WP-8', 'totalAmount': 3500});
    faux.repond('POST', '/payments/initiate', {'paymentId': 21});
    faux.repond('GET', '/payments/21/status', {'id': 21, 'status': 'completed'});
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '670000000');
    await pomper(tester, const Duration(seconds: 4));
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.shopPaymentConfirmed), findsOneWidget);
    expect(find.text(l.shopContentAvailable), findsOneWidget);
    expect(find.text(l.shopAwaitingConfirmation), findsNothing);
    await _demonter(tester);
  });

  testWidgets('paiement echoue : message du serveur et bouton « reessayer »', (tester) async {
    panier();
    faux.repond('POST', '/orders', {'id': 8, 'orderNumber': 'WP-8', 'totalAmount': 3500});
    faux.repond('POST', '/payments/initiate', {'paymentId': 21});
    faux.repond('GET', '/payments/21/status', {'id': 21, 'status': 'failed', 'errorMessage': 'Solde insuffisant'});
    await monterEcran(tester, const CheckoutScreen());
    await payer(tester, '670000000');
    await pomper(tester, const Duration(seconds: 4));
    await reseau(tester);
    expect(find.text(L10n.current.shopPaymentFailed), findsOneWidget);
    expect(find.text('Solde insuffisant'), findsOneWidget);
    expect(_bouton(L10n.current.commonRetry), findsOneWidget);
    await _demonter(tester);
  });
}
