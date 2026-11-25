import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/shop/cart_screen.dart';
import 'package:winplus/shared/shop/orders_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Map<String, dynamic> _panier({List<Map<String, dynamic>>? articles}) {
  final items = articles ??
      [
        {'id': 11, 'subjectId': 4, 'title': 'Maths BAC 2024', 'price': 1500},
        {'id': 12, 'subjectId': 5, 'title': 'Physique BEPC', 'price': 2000},
      ];
  final total = items.fold<num>(0, (a, e) => a + (e['price'] as num));
  return {'items': items, 'itemsCount': items.length, 'subtotal': total, 'tax': 570, 'total': total, 'currency': 'XAF'};
}

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  group('CartScreen', () {
    testWidgets('chargement puis articles, sous-total, TVA incluse et total', (tester) async {
      faux.repond('GET', '/cart', _panier());
      telephone(tester);
      await monter(tester, ecran(const CartScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Maths BAC 2024'), findsOneWidget);
      expect(find.text('Physique BEPC'), findsOneWidget);
      expect(find.text(l.shopSubtotal), findsOneWidget);
      expect(find.text(l.shopVatIncluded), findsOneWidget);
      expect(find.text(l.shopTotal), findsOneWidget);
      expect(find.widgetWithText(WinButton, l.shopPlaceOrder), findsOneWidget);
    });

    testWidgets('panier vide : message et bouton d\'exploration du catalogue', (tester) async {
      faux.repond('GET', '/cart', _panier(articles: []));
      await monterEcran(tester, const CartScreen());
      expect(find.text(L10n.current.shopCartEmpty), findsOneWidget);
      expect(find.widgetWithText(WinButton, L10n.current.shopExploreCatalog), findsOneWidget);
    });

    testWidgets('serveur en erreur : le service rend un panier vide (jamais de plantage)', (tester) async {
      faux.repond('GET', '/cart', {}, statut: 500);
      await monterEcran(tester, const CartScreen());
      expect(find.text(L10n.current.shopCartEmpty), findsOneWidget);
    });

    testWidgets('retirer un article : appel serveur puis rechargement', (tester) async {
      faux.repond('GET', '/cart', _panier());
      faux.repond('DELETE', '/cart/items/11', {});
      await monterEcran(tester, const CartScreen());
      faux.repond('GET', '/cart', _panier(articles: [
        {'id': 12, 'subjectId': 5, 'title': 'Physique BEPC', 'price': 2000},
      ]));
      await tester.tap(find.byIcon(PhosphorIconsRegular.x).first);
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(faux.recues('DELETE', '/cart/items/11'), hasLength(1));
      expect(find.text('Maths BAC 2024'), findsNothing);
      expect(find.text('Physique BEPC'), findsOneWidget);
    });

    testWidgets('retrait refuse : message dans la barre d\'information, l\'article reste', (tester) async {
      faux.repond('GET', '/cart', _panier());
      await monterEcran(tester, const CartScreen());
      await tester.tap(find.byIcon(PhosphorIconsRegular.x).first);
      await reseau(tester);
      expect(find.text(L10n.current.shopCartRemoveFailed), findsOneWidget);
      expect(find.text('Maths BAC 2024'), findsOneWidget);
    });

    testWidgets('code promo valide : remise annoncee', (tester) async {
      faux.repond('GET', '/cart', _panier());
      faux.repond('POST', '/cart/promo', {'success': true, 'discount': 300, 'finalAmount': 3200});
      await monterEcran(tester, const CartScreen());
      await tester.enterText(find.byType(TextField), 'BIENVENUE');
      await tester.tap(find.widgetWithText(WinButton, L10n.current.shopApply));
      await reseau(tester);
      expect(faux.recues('POST', '/cart/promo').single.data, {'code': 'BIENVENUE'});
      expect(find.text(L10n.current.shopPromoApplied(fmtXaf(300))), findsOneWidget);
    });

    testWidgets('code promo refuse : message du serveur', (tester) async {
      faux.repond('GET', '/cart', _panier());
      faux.repond('POST', '/cart/promo', {'error': 'Code expire'}, statut: 400);
      await monterEcran(tester, const CartScreen());
      await tester.enterText(find.byType(TextField), 'VIEUX');
      await tester.tap(find.widgetWithText(WinButton, L10n.current.shopApply));
      await reseau(tester);
      expect(find.text('Code expire'), findsOneWidget);
    });

    testWidgets('champ promo vide : aucun appel', (tester) async {
      faux.repond('GET', '/cart', _panier());
      await monterEcran(tester, const CartScreen());
      await tester.tap(find.widgetWithText(WinButton, L10n.current.shopApply));
      await reseau(tester);
      expect(faux.recues('POST', '/cart/promo'), isEmpty);
    });
  });

  group('OrdersScreen', () {
    testWidgets('aucune commande : message dedie', (tester) async {
      faux.repond('GET', '/orders', {'items': []});
      await monterEcran(tester, const OrdersScreen());
      expect(find.text(L10n.current.shopNoOrders), findsOneWidget);
    });

    testWidgets('serveur en panne : erreur et Reessayer, pas « aucune commande »', (tester) async {
      faux.repond('GET', '/orders', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const OrdersScreen());
      final l = L10n.current;
      expect(find.text(l.commonLoadError), findsOneWidget);
      expect(find.text(l.shopNoOrders), findsNothing);
      faux.repond('GET', '/orders', {'items': []});
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.shopNoOrders), findsOneWidget);
    });

    testWidgets('commandes : numero, date, montant et statut traduit', (tester) async {
      faux.repond('GET', '/orders', {
        'items': [
          {'id': 1, 'orderNumber': 'WP-0001', 'totalAmount': 3500, 'status': 'Completed', 'createdAt': '2026-01-05T10:00:00Z'},
          {'id': 2, 'orderNumber': 'WP-0002', 'totalAmount': 1000, 'status': 'Pending', 'createdAt': '2026-01-06T10:00:00Z'},
          {'id': 3, 'orderNumber': 'WP-0003', 'totalAmount': 800, 'status': 'Failed', 'createdAt': '2026-01-07T10:00:00Z'},
          {'id': 4, 'orderNumber': 'WP-0004', 'totalAmount': 800, 'status': 'inconnu', 'createdAt': '2026-01-08T10:00:00Z'},
        ],
      });
      await monterEcran(tester, const OrdersScreen());
      final l = L10n.current;
      expect(find.text('WP-0001'), findsOneWidget);
      expect(find.text('${fmtXaf(3500)} XAF'), findsOneWidget);
      expect(find.text(l.shopOrderPaid), findsOneWidget);
      expect(find.text(l.commonPending), findsOneWidget);
      expect(find.text(l.shopOrderFailed), findsOneWidget);
      expect(find.text('inconnu'), findsOneWidget);
    });

    testWidgets('detail d\'une commande payee : articles, facture et demande de remboursement', (tester) async {
      faux.repond('GET', '/orders', {
        'items': [
          {
            'id': 1,
            'orderNumber': 'WP-0001',
            'totalAmount': 3500,
            'status': 'Completed',
            'createdAt': '2026-01-05T10:00:00Z',
            'items': [
              {'subjectId': 4, 'subject': {'title': 'Maths BAC'}, 'priceAtPurchase': 1500},
              {'subjectId': 9, 'priceAtPurchase': 2000},
            ],
          },
        ],
      });
      await monterEcran(tester, const OrdersScreen());
      await tester.tap(find.text('WP-0001'));
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.shopItems), findsOneWidget);
      expect(find.text('Maths BAC'), findsOneWidget);
      expect(find.text(l.shopSubjectFallback(9)), findsOneWidget);
      expect(find.widgetWithText(WinButton, l.shopViewInvoice), findsOneWidget);
      expect(find.widgetWithText(WinButton, l.shopRequestRefund), findsOneWidget);
    });

    testWidgets('commande en attente : pas de demande de remboursement', (tester) async {
      faux.repond('GET', '/orders', {
        'items': [
          {'id': 2, 'orderNumber': 'WP-0002', 'totalAmount': 1000, 'status': 'Pending', 'createdAt': '2026-01-06T10:00:00Z'},
        ],
      });
      await monterEcran(tester, const OrdersScreen());
      await tester.tap(find.text('WP-0002'));
      await reseau(tester);
      expect(find.widgetWithText(WinButton, L10n.current.shopViewInvoice), findsOneWidget);
      expect(find.widgetWithText(WinButton, L10n.current.shopRequestRefund), findsNothing);
    });

    testWidgets('actualiser relit les commandes', (tester) async {
      faux.repond('GET', '/orders', {'items': []});
      await monterEcran(tester, const OrdersScreen());
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
      await reseau(tester);
      expect(faux.recues('GET', '/orders'), hasLength(2));
    });
  });
}
