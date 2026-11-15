import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/subscription/pricing_screen.dart';
import 'package:winplus/shared/subscription/subscribe_sheet.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _catalogue() => {
      'data': {
        'student': [
          {
            'planId': 1,
            'name': 'Gratuit',
            'isFree': true,
            'description': 'Pour commencer',
            'prices': [],
            'features': [
              {'key': 'a', 'label': 'Catalogue limite', 'display': 'Oui', 'included': true},
            ],
          },
          {
            'planId': 2,
            'name': 'Premium',
            'isPopular': true,
            'prices': [
              {'billingPeriod': 'monthly', 'priceTtc': 3000},
              {'period': 'yearly', 'priceTtc': 30000},
            ],
            'features': [
              {'key': 'b', 'label': 'Favoris', 'display': '50', 'included': true},
              {'key': 'c', 'label': 'Exam Coach', 'display': 'Non', 'included': false},
            ],
          },
        ],
      },
    };

Map<String, dynamic> _devis({num du = 3000, String change = 'new', String? promoErreur}) => {
      'planName': 'Premium',
      'billingPeriod': 'monthly',
      'change': change,
      'message': 'Abonnement mensuel',
      'listPriceTtc': 3000,
      'discountTtc': 0,
      'prorataCreditTtc': 0,
      'amountDueTtc': du,
      if (promoErreur != null) 'promoError': promoErreur,
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('PricingScreen', () {
    testWidgets('chargement puis plans : prix, badges, fonctionnalites incluses ou non', (tester) async {
      faux.repond('GET', '/pricing/catalog', _catalogue());
      telephone(tester);
      await monter(tester, ecran(const PricingScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.subOurPlans), findsOneWidget);
      // Le plan s'appelle « Gratuit » et son prix s'affiche « Gratuit ».
      expect(find.text('Gratuit'), findsNWidgets(2));
      expect(find.text(fmtXaf(3000)), findsOneWidget);
      expect(find.text(l.subBadgePopular), findsOneWidget);
      expect(find.text(l.subBadgeCurrent), findsOneWidget, reason: 'le plan gratuit est le plan courant sans abonnement');
      expect(find.text('Favoris : 50'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(faux.requetes.single.queryParameters, {'audience': 'student'});
    });

    testWidgets('changer de periode affiche le prix annuel ; periode absente = « non propose »', (tester) async {
      faux.repond('GET', '/pricing/catalog', _catalogue());
      await monterEcran(tester, const PricingScreen());
      await tester.tap(find.widgetWithText(WinChip, L10n.current.subPeriodYearly));
      await pomper(tester);
      expect(find.text(fmtXaf(30000)), findsOneWidget);
      expect(find.widgetWithText(WinChip, L10n.current.subPeriodQuarterly), findsNothing);
    });

    testWidgets('erreur : message puis « Reessayer »', (tester) async {
      faux.repond('GET', '/pricing/catalog', {}, statut: 500);
      await monterEcran(tester, const PricingScreen());
      expect(find.text(L10n.current.subLoadError), findsOneWidget);
      faux.repond('GET', '/pricing/catalog', _catalogue());
      await tester.tap(_bouton(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('compte etablissement : note sur la licence, aucune requete', (tester) async {
      final etat = WinAppState()..setRole(WinRole.institution);
      await monterEcran(tester, const PricingScreen(), etat: etat);
      expect(find.text(L10n.current.subInstitutionLicenseNote), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('« Choisir ce plan » ouvre la feuille de souscription avec le devis', (tester) async {
      faux.repond('GET', '/pricing/catalog', _catalogue());
      faux.repond('POST', '/subscriptions/quote', _devis());
      await monterEcran(tester, const PricingScreen());
      final b = _bouton(L10n.current.subChoosePlan);
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(SubscribeSheet), findsOneWidget);
      expect(faux.recues('POST', '/subscriptions/quote').single.data, {'planId': 2, 'billingPeriod': 'monthly'});
    });
  });

  group('SubscribeSheet', () {
    Widget ouvreur() => Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => SubscribeSheet.show(c, planId: 2, planName: 'Premium'),
              child: const Text('souscrire'),
            ),
          ),
        );

    Future<void> ouvrirFeuille(WidgetTester tester) async {
      await monterEcran(tester, ouvreur());
      await tester.tap(find.text('souscrire'));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
    }

    testWidgets('devis : prix de liste, montant du maintenant et message du serveur', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis());
      await ouvrirFeuille(tester);
      final l = L10n.current;
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('${fmtXaf(3000)} XAF'), findsWidgets);
      expect(find.text(l.subDueNow), findsOneWidget);
      expect(find.text('Abonnement mensuel'), findsOneWidget);
      expect(_bouton(l.shopPayAmount(fmtXaf(3000))), findsOneWidget);
    });

    testWidgets('devis indisponible : message du serveur et bouton inactif', (tester) async {
      faux.repond('POST', '/subscriptions/quote', {'error': 'Plan indisponible'}, statut: 400);
      await ouvrirFeuille(tester);
      expect(find.text('Plan indisponible'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.subActivate)).onTap, isNull);
    });

    testWidgets('Mobile Money sans numero valide : message et aucun achat', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis());
      await ouvrirFeuille(tester);
      await tester.enterText(find.byType(TextField).last, '670');
      final b = _bouton(L10n.current.shopPayAmount(fmtXaf(3000)));
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      expect(find.text(L10n.current.subEnterMomoNumber), findsOneWidget);
      expect(faux.recues('POST', '/subscriptions/purchase'), isEmpty);
    });

    testWidgets('achat Mobile Money : numero au format 237, puis confirmation de paiement lance', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis());
      faux.repond('POST', '/subscriptions/purchase', {'status': 'payment_pending', 'paymentId': 5, 'amount': 3000});
      faux.repond('GET', '/subscriptions/me', {'id': 1, 'hasPlan': false});
      await ouvrirFeuille(tester);
      await tester.enterText(find.byType(TextField).last, '670 00 00 00');
      final b = _bouton(L10n.current.shopPayAmount(fmtXaf(3000)));
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      expect(faux.recues('POST', '/subscriptions/purchase').single.data, {
        'planId': 2,
        'billingPeriod': 'monthly',
        'method': 'mobile_money',
        'phone': '237670000000',
        'autoRenew': false,
      });
      expect(find.text(L10n.current.subPaymentInitiated), findsOneWidget);
    });

    testWidgets('montant nul (essai ou gratuit) : activation par le solde, sans numero', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis(du: 0, change: 'trial'));
      faux.repond('POST', '/subscriptions/purchase', {'status': 'activated', 'message': 'Essai active'});
      faux.repond('GET', '/subscriptions/me', {'id': 1, 'hasPlan': true});
      await ouvrirFeuille(tester);
      expect(find.byType(TextField), findsOneWidget, reason: 'seul le champ promo reste');
      final b = _bouton(L10n.current.subStartTrial);
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      expect(faux.recues('POST', '/subscriptions/purchase').single.data['method'], 'balance');
      expect(faux.recues('POST', '/subscriptions/purchase').single.data.containsKey('phone'), isFalse);
      expect(find.text('Essai active'), findsOneWidget);
    });

    testWidgets('code promo : devis recalcule avec le code en majuscules', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis());
      await ouvrirFeuille(tester);
      await tester.enterText(find.byType(TextField).first, 'bienvenue');
      await tester.tap(_bouton(L10n.current.shopApply));
      await reseau(tester);
      expect(faux.recues('POST', '/subscriptions/quote').last.data, {'planId': 2, 'billingPeriod': 'monthly', 'promoCode': 'BIENVENUE'});
    });

    testWidgets('achat refuse : message du serveur affiche', (tester) async {
      faux.repond('POST', '/subscriptions/quote', _devis());
      faux.repond('POST', '/subscriptions/purchase', {'error': 'Solde insuffisant'}, statut: 402);
      await ouvrirFeuille(tester);
      await tester.enterText(find.byType(TextField).last, '670000000');
      final b = _bouton(L10n.current.shopPayAmount(fmtXaf(3000)));
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      expect(find.text('Solde insuffisant'), findsOneWidget);
    });
  });
}
