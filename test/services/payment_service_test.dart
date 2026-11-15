import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/payment_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('Modeles de paiement', () {
    test('ApiOrderPaymentIntent : valeurs par defaut XAF et en attente', () {
      final p = ApiOrderPaymentIntent.fromJson(<String, dynamic>{});
      expect(p.paymentId, 0);
      expect(p.status, 'pending');
      expect(p.currency, 'XAF');
      expect(p.amount, 0.0);
      expect(p.authorizationUrl, isNull);
      final q = ApiOrderPaymentIntent.fromJson({
        'paymentId': 12.0,
        'notchpayReference': 'trx.1',
        'amount': 2500,
        'authorizationUrl': 'https://pay.exemple/x',
      });
      expect(q.paymentId, 12);
      expect(q.notchpayReference, 'trx.1');
      expect(q.amount, 2500.0);
    });

    test('ApiPaymentIntent lit le code USSD et le lien', () {
      final p = ApiPaymentIntent.fromJson({'id': 'p1', 'amount': 1000.5, 'ussdCode': '*126#', 'paymentUrl': 'u'});
      expect(p.id, 'p1');
      expect(p.amount, 1000.5);
      expect(p.ussdCode, '*126#');
      expect(p.paymentUrl, 'u');
      expect(ApiPaymentIntent.fromJson(<String, dynamic>{}).id, '');
    });

    test('ApiPaymentStatus : id numerique converti, message d\'erreur prioritaire', () {
      final s = ApiPaymentStatus.fromJson({'id': 42, 'status': 'Completed', 'errorMessage': 'E', 'message': 'M'});
      expect(s.id, '42');
      expect(s.message, 'E');
      expect(s.isCompleted, isTrue);
      expect(s.isFailed, isFalse);
      expect(ApiPaymentStatus.fromJson({'message': 'M'}).message, 'M');
      expect(ApiPaymentStatus.fromJson(<String, dynamic>{}).id, '');
    });

    test('ApiPaymentStatus : succes et echec sans tenir compte de la casse', () {
      expect(const ApiPaymentStatus(id: '1', status: 'SUCCESS').isCompleted, isTrue);
      expect(const ApiPaymentStatus(id: '1', status: 'Error').isFailed, isTrue);
      expect(const ApiPaymentStatus(id: '1', status: 'failed').isFailed, isTrue);
      const attente = ApiPaymentStatus(id: '1', status: 'pending');
      expect(attente.isCompleted || attente.isFailed, isFalse);
      expect(ApiPaymentStatus.fromJson(<String, dynamic>{}).status, 'pending');
    });
  });

  group('PaymentService', () {
    test('initiate envoie la methode Mobile Money et la periodicite', () async {
      faux.repond('POST', '/payments/initiate', {'id': 'p9', 'amount': 3000});
      final r = await PaymentService.instance
          .initiate(planId: 2, method: PaymentMethod.mtnMomo, phoneNumber: '670000000', yearly: false);
      expect(r!.id, 'p9');
      expect(faux.requetes.single.data, {
        'planId': 2,
        'method': 'mtn_momo',
        'phoneNumber': '670000000',
        'billing': 'monthly',
      });
      await PaymentService.instance
          .initiate(planId: 2, method: PaymentMethod.orangeMoney, phoneNumber: '690000000', yearly: true);
      final d = faux.requetes.last.data as Map;
      expect(d['method'], 'orange_money');
      expect(d['billing'], 'yearly');
    });

    test('initiate rend null si le serveur refuse', () async {
      faux.repond('POST', '/payments/initiate', {'error': 'x'}, statut: 500);
      expect(
        await PaymentService.instance
            .initiate(planId: 1, method: PaymentMethod.mtnMomo, phoneNumber: '6', yearly: false),
        isNull,
      );
    });

    test('checkStatus lit le statut, null en cas d\'erreur', () async {
      faux.repond('GET', '/payments/7/status', {'id': 7, 'status': 'completed'});
      expect((await PaymentService.instance.checkStatus('7'))!.isCompleted, isTrue);
      expect(await PaymentService.instance.checkStatus('8'), isNull);
    });

    test('initiateForOrder envoie la commande et l\'e-mail seulement s\'il existe', () async {
      faux.repond('POST', '/payments/initiate', {'paymentId': 3, 'amount': 4000});
      final r = await PaymentService.instance.initiateForOrder(orderId: 5, phone: '670', amount: 4000);
      expect(r.paymentId, 3);
      expect(faux.requetes.single.data, {'orderId': 5, 'phone': '670', 'amount': 4000.0});
      await PaymentService.instance.initiateForOrder(orderId: 5, phone: '670', amount: 4000, email: 'a@b.cm');
      expect((faux.requetes.last.data as Map)['email'], 'a@b.cm');
    });

    test('initiateForOrder : message du serveur (message avant error) ou message par defaut', () async {
      faux.repond('POST', '/payments/initiate', {'message': 'Numero invalide', 'error': 'autre'}, statut: 400);
      await expectLater(
        PaymentService.instance.initiateForOrder(orderId: 1, phone: 'x', amount: 1),
        throwsA(isA<OrderPaymentException>().having((e) => e.message, 'message', 'Numero invalide')),
      );
      faux.repond('POST', '/payments/initiate', {'error': 'Refuse'}, statut: 400);
      await expectLater(
        PaymentService.instance.initiateForOrder(orderId: 1, phone: 'x', amount: 1),
        throwsA(isA<OrderPaymentException>().having((e) => e.message, 'message', 'Refuse')),
      );
      faux.repond('POST', '/payments/initiate', {}, statut: 500);
      await expectLater(
        PaymentService.instance.initiateForOrder(orderId: 1, phone: 'x', amount: 1),
        throwsA(isA<OrderPaymentException>().having((e) => e.message, 'message', 'Impossible d\'initier le paiement.')),
      );
    });

    test('getHistory lit { payments } ou une liste brute, vide en cas d\'erreur', () async {
      faux.repond('GET', '/payments/history', {
        'payments': [
          {'id': 1},
          {'id': 2},
        ],
        'total': 2,
      });
      expect(await PaymentService.instance.getHistory(), hasLength(2));
      faux.repond('GET', '/payments/history', [
        {'id': 1},
      ]);
      expect(await PaymentService.instance.getHistory(), hasLength(1));
      faux.repond('GET', '/payments/history', {'total': 0});
      expect(await PaymentService.instance.getHistory(), isEmpty);
      faux.repond('GET', '/payments/history', {}, statut: 500);
      expect(await PaymentService.instance.getHistory(), isEmpty);
    });
  });
}
