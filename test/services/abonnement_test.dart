import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/subscription_service.dart';
import 'package:winplus/shared/subscription/subscription_notifier.dart';

import '../helpers/faux_reseau.dart';

Map<String, dynamic> _abonnementJson() => {
      'id': 4,
      'hasPlan': true,
      'pricingPlanId': 2,
      'planName': 'Premium',
      'status': 'trialing',
      'billingPeriod': 'monthly',
      'expiresAt': '2026-02-01T00:00:00Z',
      'autoRenew': true,
      'price': 2500,
      'pendingPlanName': 'Standard',
      'entitlements': {
        'audience': 'student',
        'aiMultiplier': 5,
        'entitlements': {'catalog.access': true, 'favorites.max': -1, 'groups.max_owned': 2, 'ai.feature.exam_coach': false},
      },
      'aiUsageMultiplier': 5,
      'aiUsageLabel': 'x5',
      'aiQuotaExhausted': true,
      'aiLimitReached': 'session',
      'aiLimitResetsAt': '2026-01-05T15:00:00Z',
      'aiLimitMessage': 'Reessayez plus tard',
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('ApiEntitlements', () {
    const droits = ApiEntitlements(values: {'a': true, 'b': false, 'max': 3, 'illimite': -1, 'texte': 'oui'});

    test('has : vrai seulement pour la valeur booleenne true', () {
      expect(droits.has('a'), isTrue);
      expect(droits.has('b'), isFalse);
      expect(droits.has('absent'), isFalse);
      expect(droits.has('texte'), isFalse);
    });

    test('limit : valeur entiere, 0 si absente ou non numerique', () {
      expect(droits.limit('max'), 3);
      expect(droits.limit('absent'), 0);
      expect(droits.limit('texte'), 0);
    });

    test('-1 signifie illimite', () {
      expect(ApiEntitlements.unlimited, -1);
      expect(droits.isUnlimited('illimite'), isTrue);
      expect(droits.isUnlimited('max'), isFalse);
    });

    test('allowsOneMore : strictement sous la limite, ou toujours si illimite', () {
      expect(droits.allowsOneMore('max', 2), isTrue);
      expect(droits.allowsOneMore('max', 3), isFalse);
      expect(droits.allowsOneMore('illimite', 1000000), isTrue);
      expect(droits.allowsOneMore('absent', 0), isFalse);
    });

    test('fromJson : null ou vide donne aucun droit et un multiplicateur de 1', () {
      final vide = ApiEntitlements.fromJson(null);
      expect(vide.audience, isNull);
      expect(vide.aiMultiplier, 1);
      expect(vide.values, isEmpty);
      expect(ApiEntitlements.fromJson(<String, dynamic>{}).values, isEmpty);
    });

    test('fromJson lit le public, le multiplicateur et les droits', () {
      final d = ApiEntitlements.fromJson({'audience': 'parent', 'aiMultiplier': 3, 'entitlements': {'children.max': 4}});
      expect(d.audience, 'parent');
      expect(d.aiMultiplier, 3);
      expect(d.limit('children.max'), 4);
    });
  });

  group('ApiActiveSubscription', () {
    test('lit un abonnement complet', () {
      final s = ApiActiveSubscription.fromJson(_abonnementJson());
      expect(s.id, 4);
      expect(s.hasPlan, isTrue);
      expect(s.pricingPlanId, 2);
      expect(s.planName, 'Premium');
      expect(s.billingPeriod, 'monthly');
      expect(s.expiresAt!.toUtc(), DateTime.utc(2026, 2, 1));
      expect(s.graceUntil, isNull);
      expect(s.autoRenew, isTrue);
      expect(s.cancelAtPeriodEnd, isFalse);
      expect(s.price, 2500.0);
      expect(s.pendingPlanName, 'Standard');
      expect(s.entitlements.aiMultiplier, 5);
      expect(s.entitlements.has('catalog.access'), isTrue);
      expect(s.aiUsageMultiplier, 5);
      expect(s.aiQuotaExhausted, isTrue);
      expect(s.aiLimitReached, 'session');
      expect(s.aiLimitResetsAt!.toUtc(), DateTime.utc(2026, 1, 5, 15));
      expect(s.aiLimitMessage, 'Reessayez plus tard');
    });

    test('un abonnement vide est le plan Gratuit, sans plan', () {
      final s = ApiActiveSubscription.fromJson(<String, dynamic>{});
      expect(s.hasPlan, isFalse);
      expect(s.planName, 'Gratuit');
      expect(s.status, 'free');
      expect(s.aiUsageMultiplier, 1);
      expect(s.aiQuotaExhausted, isFalse);
      expect(s.expiresAt, isNull);
      expect(s.isInGrace, isFalse);
      expect(s.isTrial, isFalse);
    });

    test('essai et periode de grace se deduisent du statut', () {
      expect(ApiActiveSubscription.fromJson({'status': 'trialing'}).isTrial, isTrue);
      expect(ApiActiveSubscription.fromJson({'status': 'past_due'}).isInGrace, isTrue);
      expect(ApiActiveSubscription.fromJson({'status': 'active'}).isTrial, isFalse);
      expect(ApiActiveSubscription.fromJson({'status': 'active'}).isInGrace, isFalse);
    });
  });

  group('ApiPlanCard et ApiSubscriptionQuote', () {
    test('une carte de plan indexe les prix par periode', () {
      final c = ApiPlanCard.fromJson({
        'planId': 7,
        'name': 'Standard',
        'audience': 'parent',
        'isPopular': true,
        'aiMultiplier': 3,
        'prices': [
          {'period': 'monthly', 'priceTtc': 2000},
          {'period': 'yearly', 'priceTtc': 20000.5},
        ],
        'features': [
          {'key': 'k', 'label': 'Quiz', 'display': 'Illimites', 'included': true},
          <String, dynamic>{},
        ],
      });
      expect(c.planId, 7);
      expect(c.audience, 'parent');
      expect(c.isPopular, isTrue);
      expect(c.isFree, isFalse);
      expect(c.priceFor('monthly'), 2000.0);
      expect(c.priceFor('yearly'), 20000.5);
      expect(c.priceFor('quarterly'), isNull);
      expect(c.aiMultiplier, 3);
      expect(c.features, hasLength(2));
      expect(c.features.first.included, isTrue);
      expect(c.features.last.included, isFalse);
      expect(c.features.last.label, '');
    });

    test('une carte vide : public eleve, aucun prix, multiplicateur 1', () {
      final c = ApiPlanCard.fromJson(<String, dynamic>{});
      expect(c.audience, 'student');
      expect(c.prices, isEmpty);
      expect(c.aiMultiplier, 1);
    });

    test('un prix sans periode est mensuel', () {
      final c = ApiPlanCard.fromJson({
        'prices': [
          {'priceTtc': 1500},
        ],
      });
      expect(c.priceFor('monthly'), 1500.0);
    });

    test('un devis lit les montants et les valeurs par defaut', () {
      final q = ApiSubscriptionQuote.fromJson({'planName': 'P', 'listPriceTtc': 5000, 'discountTtc': 500, 'prorataCreditTtc': 100, 'amountDueTtc': 4400, 'trialDays': 7, 'promoCode': 'X', 'promoError': 'expire'});
      expect(q.listPrice, 5000.0);
      expect(q.discount, 500.0);
      expect(q.prorataCredit, 100.0);
      expect(q.amountDue, 4400.0);
      expect(q.trialDays, 7);
      expect(q.promoError, 'expire');
      final vide = ApiSubscriptionQuote.fromJson(<String, dynamic>{});
      expect(vide.billingPeriod, 'monthly');
      expect(vide.change, 'new');
      expect(vide.amountDue, 0);
      expect(vide.trialDays, isNull);
    });
  });

  group('SubscriptionService', () {
    test('getCatalog demande le public et lit la liste de ce public', () async {
      faux.repond('GET', '/pricing/catalog', {
        'data': {
          'student': [
            {'planId': 1, 'name': 'Gratuit', 'isFree': true},
          ],
          'parent': [],
        },
      });
      final l = await SubscriptionService.instance.getCatalog('student');
      expect(faux.requetes.single.queryParameters, {'audience': 'student'});
      expect(l.single.name, 'Gratuit');
      expect(l.single.isFree, isTrue);
      expect(await SubscriptionService.instance.getCatalog('parent'), isEmpty);
      expect(await SubscriptionService.instance.getCatalog('teacher'), isEmpty);
    });

    test('quote envoie le plan, la periode et le code promo seulement s\'il n\'est pas vide', () async {
      faux.repond('POST', '/subscriptions/quote', {'planName': 'P', 'amountDueTtc': 1000});
      await SubscriptionService.instance.quote(planId: 2, period: 'yearly');
      await SubscriptionService.instance.quote(planId: 2, period: 'yearly', promoCode: '');
      await SubscriptionService.instance.quote(planId: 2, period: 'yearly', promoCode: 'PROMO');
      final envois = faux.recues('POST', '/subscriptions/quote').map((r) => r.data as Map).toList();
      expect(envois[0], {'planId': 2, 'billingPeriod': 'yearly'});
      expect(envois[1], {'planId': 2, 'billingPeriod': 'yearly'});
      expect(envois[2], {'planId': 2, 'billingPeriod': 'yearly', 'promoCode': 'PROMO'});
    });

    test('purchasePlan envoie le telephone Mobile Money et lit le resultat', () async {
      faux.repond('POST', '/subscriptions/purchase', {'status': 'payment_pending', 'message': 'Confirmez', 'paymentId': 12, 'amount': 2500});
      final r = await SubscriptionService.instance.purchasePlan(planId: 2, period: 'monthly', method: 'mobile_money', phone: '677000000', autoRenew: true);
      expect(faux.recues('POST', '/subscriptions/purchase').single.data, {
        'planId': 2,
        'billingPeriod': 'monthly',
        'method': 'mobile_money',
        'phone': '677000000',
        'autoRenew': true,
      });
      expect(r.status, 'payment_pending');
      expect(r.paymentId, 12);
      expect(r.amount, 2500.0);
    });

    test('purchasePlan par solde, sans reponse detaillee : active par defaut', () async {
      faux.repond('POST', '/subscriptions/purchase', <String, dynamic>{});
      final r = await SubscriptionService.instance.purchasePlan(planId: 2, period: 'monthly', method: 'balance');
      final envoi = faux.recues('POST', '/subscriptions/purchase').single.data as Map;
      expect(envoi.containsKey('phone'), isFalse);
      expect(envoi['autoRenew'], isFalse);
      expect(r.status, 'activated');
      expect(r.paymentId, isNull);
    });

    test('purchasePlan leve l\'erreur du serveur (message a afficher)', () async {
      faux.repond('POST', '/subscriptions/purchase', {'error': 'Solde insuffisant'}, statut: 402);
      await expectLater(
        SubscriptionService.instance.purchasePlan(planId: 2, period: 'monthly', method: 'balance'),
        throwsA(isA<DioException>().having((e) => (e.response?.data as Map)['error'], 'message', 'Solde insuffisant')),
      );
    });

    test('resume, cancel, cancelPending et setAutoRenew : true si accepte, false sinon', () async {
      faux.repond('POST', '/subscriptions/me/resume', {});
      faux.repond('POST', '/subscriptions/me/cancel', {});
      faux.repond('DELETE', '/subscriptions/me/pending', null, statut: 204);
      faux.repond('PUT', '/subscriptions/me/auto-renew', {});
      expect(await SubscriptionService.instance.resume(), isTrue);
      expect(await SubscriptionService.instance.cancel(), isTrue);
      expect(await SubscriptionService.instance.cancelPending(), isTrue);
      expect(await SubscriptionService.instance.setAutoRenew(false), isTrue);
      expect(faux.recues('PUT', '/subscriptions/me/auto-renew').single.data, {'enabled': false});
      faux.repond('POST', '/subscriptions/me/resume', {}, statut: 409);
      faux.coupure('POST', '/subscriptions/me/cancel');
      expect(await SubscriptionService.instance.resume(), isFalse);
      expect(await SubscriptionService.instance.cancel(), isFalse);
    });

    test('topUpWinAi envoie le nombre de paquets et un identifiant de requete', () async {
      faux.repond('POST', '/winai/topup', {'message': 'Recharge effectuee'});
      final m = await SubscriptionService.instance.topUpWinAi(packs: 2);
      expect(m, 'Recharge effectuee');
      final envoi = faux.recues('POST', '/winai/topup').single.data as Map;
      expect(envoi['packs'], 2);
      expect(envoi['requestId'], isA<String>());
      expect((envoi['requestId'] as String), isNotEmpty);
    });

    test('topUpWinAi sans message serveur utilise le message par defaut', () async {
      faux.repond('POST', '/winai/topup', <String, dynamic>{});
      expect(await SubscriptionService.instance.topUpWinAi(), L10n.current.svcTopUpDone);
    });

    test('en cas d\'echec : getCurrent leve une erreur (pas un faux plan gratuit), getCurrentOrNull et getEntitlements rendent null', () async {
      expect(await SubscriptionService.instance.getEntitlements(), isNull);
      await expectLater(SubscriptionService.instance.getCurrent(), throwsA(isA<DioException>()));
      expect(await SubscriptionService.instance.getCurrentOrNull(), isNull);
      faux.repond('GET', '/me/entitlements', {'aiMultiplier': 2, 'entitlements': {'catalog.access': true}});
      faux.repond('GET', '/subscriptions/me', _abonnementJson());
      expect((await SubscriptionService.instance.getEntitlements())!.has('catalog.access'), isTrue);
      expect((await SubscriptionService.instance.getCurrent()).planName, 'Premium');
    });
  });

  group('SubscriptionNotifier', () {
    test('avant tout chargement : plan gratuit, aucun droit, WinAI utilisable', () {
      final n = SubscriptionNotifier();
      expect(n.current, isNull);
      expect(n.hasPlan, isFalse);
      expect(n.planName, 'Gratuit');
      expect(n.aiMultiplier, 1);
      expect(n.has(EntitlementKeys.catalogAccess), isFalse);
      expect(n.limit(EntitlementKeys.favoritesMax), 0);
      expect(n.canUseAI, isTrue);
    });

    test('un abonnement charge fournit les droits et previent les ecouteurs', () async {
      faux.repond('GET', '/subscriptions/me', _abonnementJson());
      final n = SubscriptionNotifier();
      var appels = 0;
      n.addListener(() => appels++);
      await n.loadFromApi();
      expect(appels, 1);
      expect(n.hasPlan, isTrue);
      expect(n.planName, 'Premium');
      expect(n.aiMultiplier, 5);
      expect(n.has(EntitlementKeys.catalogAccess), isTrue);
      expect(n.has(EntitlementKeys.examCoach), isFalse);
      expect(n.limit(EntitlementKeys.groupsMax), 2);
      expect(n.allowsOneMore(EntitlementKeys.groupsMax, 1), isTrue);
      expect(n.allowsOneMore(EntitlementKeys.groupsMax, 2), isFalse);
      expect(n.allowsOneMore(EntitlementKeys.favoritesMax, 999), isTrue);
      expect(n.canUseAI, isFalse);
    });

    test('un echec de chargement ne change rien et ne previent personne', () async {
      final n = SubscriptionNotifier();
      var appels = 0;
      n.addListener(() => appels++);
      await n.loadFromApi();
      expect(appels, 0);
      expect(n.current, isNull);
    });

    test('les cles de droits sont celles du catalogue serveur', () {
      expect(EntitlementKeys.catalogAccess, 'catalog.access');
      expect(EntitlementKeys.favoritesMax, 'favorites.max');
      expect(EntitlementKeys.childrenMax, 'children.max');
      expect(EntitlementKeys.examCoach, 'ai.feature.exam_coach');
    });
  });
}
