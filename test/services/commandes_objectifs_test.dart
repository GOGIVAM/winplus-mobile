import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/connectivity_service.dart';
import 'package:winplus/services/forum_service.dart';
import 'package:winplus/services/goals_service.dart';
import 'package:winplus/services/linking_service.dart';
import 'package:winplus/services/order_service.dart';
import 'package:winplus/services/quiz_mistakes_service.dart';
import 'package:winplus/services/student_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('ApiOrder', () {
    test('lit une commande complete avec ses lignes', () {
      final o = ApiOrder.fromJson({
        'id': 8,
        'orderNumber': 'WP-0008',
        'totalAmount': 3500,
        'status': 'Completed',
        'paymentMethod': 'mobile_money',
        'createdAt': '2026-01-05T10:00:00Z',
        'items': [
          {'subjectId': 4, 'subject': {'title': 'Maths BAC'}, 'priceAtPurchase': 1500},
          {'subjectId': 5, 'priceAtPurchase': 2000.5},
        ],
      });
      expect(o.id, 8);
      expect(o.orderNumber, 'WP-0008');
      expect(o.totalAmount, 3500.0);
      expect(o.paymentMethod, 'mobile_money');
      expect(o.createdAt.toUtc(), DateTime.utc(2026, 1, 5, 10));
      expect(o.items, hasLength(2));
      expect(o.items[0].title, 'Maths BAC');
      expect(o.items[0].price, 1500.0);
      expect(o.items[1].title, isNull);
      expect(o.items[1].price, 2000.5);
    });

    test('une commande vide prend les valeurs par defaut (en attente, aucune ligne)', () {
      final o = ApiOrder.fromJson(<String, dynamic>{});
      expect(o.id, 0);
      expect(o.orderNumber, '');
      expect(o.status, 'Pending');
      expect(o.items, isEmpty);
      expect(o.isPending, isTrue);
    });

    test('les statuts sont compares sans tenir compte de la casse', () {
      expect(ApiOrder.fromJson({'status': 'COMPLETED'}).isCompleted, isTrue);
      expect(ApiOrder.fromJson({'status': 'Cancelled'}).isCancelled, isTrue);
      expect(ApiOrder.fromJson({'status': 'refund_requested'}).isRefundRequested, isTrue);
      final failed = ApiOrder.fromJson({'status': 'Failed'});
      expect(failed.isCompleted || failed.isPending || failed.isCancelled || failed.isRefundRequested, isFalse);
    });
  });

  group('OrderService', () {
    test('createOrder envoie le moyen de paiement (mobile money par defaut) et lit la commande', () async {
      faux.repond('POST', '/orders', {'id': 8, 'orderNumber': 'WP-0008', 'totalAmount': 1000, 'status': 'Pending'});
      final o = await OrderService.instance.createOrder();
      expect(o.id, 8);
      expect(faux.recues('POST', '/orders').single.data, {'paymentMethod': 'mobile_money'});
      await OrderService.instance.createOrder(paymentMethod: 'carte');
      expect(faux.recues('POST', '/orders').last.data, {'paymentMethod': 'carte'});
    });

    test('createOrder leve OrderCreateException avec le message du serveur', () async {
      faux.repond('POST', '/orders', {'error': 'Panier vide'}, statut: 400);
      await expectLater(
        OrderService.instance.createOrder(),
        throwsA(isA<OrderCreateException>().having((e) => e.message, 'message', 'Panier vide')),
      );
    });

    test('createOrder sans message serveur utilise le message par defaut de la langue', () async {
      faux.repond('POST', '/orders', {}, statut: 500);
      await expectLater(
        OrderService.instance.createOrder(),
        throwsA(isA<OrderCreateException>().having((e) => e.message, 'message', 'Impossible de créer la commande.')),
      );
    });

    test('getOrders lit la page et envoie page et taille', () async {
      faux.repond('GET', '/orders', {
        'items': [
          {'id': 1, 'status': 'Completed'},
          {'id': 2},
        ],
      });
      final l = await OrderService.instance.getOrders(page: 2, pageSize: 5);
      expect(l.map((o) => o.id), [1, 2]);
      expect(faux.requetes.single.queryParameters, {'page': 2, 'pageSize': 5});
    });

    test('getOrders : une panne remonte (ecran affiche « erreur, reessayer »)', () async {
      faux.repond('GET', '/orders', {'error': 'x'}, statut: 500);
      await expectLater(OrderService.instance.getOrders(), throwsA(isA<DioException>()));
    });

    test('getOrderById : la commande, ou null si introuvable', () async {
      faux.repond('GET', '/orders/8', {'id': 8});
      expect((await OrderService.instance.getOrderById(8))?.id, 8);
      expect(await OrderService.instance.getOrderById(99), isNull);
    });

    test('getOrderStatus lit le statut imbrique, null sinon', () async {
      faux.repond('GET', '/orders/8/status', {'data': {'status': 'Completed'}});
      faux.repond('GET', '/orders/9/status', {});
      expect(await OrderService.instance.getOrderStatus(8), 'Completed');
      expect(await OrderService.instance.getOrderStatus(9), isNull);
      expect(await OrderService.instance.getOrderStatus(10), isNull);
    });

    test('cancelOrder et requestRefund : true si accepte, false sinon', () async {
      faux.repond('POST', '/orders/8/cancel', {});
      faux.repond('POST', '/orders/8/refund', {});
      expect(await OrderService.instance.cancelOrder(8), isTrue);
      expect(await OrderService.instance.requestRefund(8), isTrue);
      expect(await OrderService.instance.cancelOrder(9), isFalse);
      expect(await OrderService.instance.requestRefund(9), isFalse);
    });
  });

  group('ApiGoalDetail et GoalsService', () {
    test('un objectif vide prend le statut Active et la date du jour', () {
      final g = ApiGoalDetail.fromJson(<String, dynamic>{});
      expect(g.id, 0);
      expect(g.userId, 0);
      expect(g.status, 'Active');
      expect(g.title, isNull);
      expect(g.proposedByUserId, isNull);
      expect(g.targetDate.difference(DateTime.now()).inMinutes.abs(), lessThan(5));
    });

    test('getMyGoals accepte une liste enveloppee dans data ou une liste brute', () async {
      faux.repond('GET', '/student/goals', {
        'data': [
          {'id': 1, 'userId': 2, 'title': 'Reviser', 'status': 'Pending', 'proposedByUserId': 9, 'progress': 40, 'targetDate': '2026-03-01T00:00:00Z'},
        ],
      });
      var l = await GoalsService.instance.getMyGoals();
      expect(l.single.title, 'Reviser');
      expect(l.single.status, 'Pending');
      expect(l.single.proposedByUserId, 9);
      expect(l.single.progress, 40);
      expect(l.single.targetDate.toUtc(), DateTime.utc(2026, 3, 1));

      faux.repond('GET', '/student/goals', [
        {'id': 5},
      ]);
      l = await GoalsService.instance.getMyGoals();
      expect(l.single.id, 5);

      faux.repond('GET', '/student/goals', <String, dynamic>{});
      expect(await GoalsService.instance.getMyGoals(), isEmpty);
    });

    test('propose envoie l\'enfant, l\'echeance en ISO et omet les champs facultatifs absents', () async {
      faux.repond('POST', '/goals/propose', {'data': {'id': 3, 'status': 'Pending'}});
      final echeance = DateTime(2026, 6, 30, 12);
      final g = await GoalsService.instance.propose(childId: 7, title: 'Lire', deadline: echeance);
      expect(g.id, 3);
      expect(g.status, 'Pending');
      expect(faux.recues('POST', '/goals/propose').single.data, {
        'childId': 7,
        'title': 'Lire',
        'deadline': echeance.toIso8601String(),
      });
      await GoalsService.instance.propose(childId: 7, title: 'Lire', description: 'd', type: 'quiz', deadline: echeance);
      final corps = faux.recues('POST', '/goals/propose').last.data as Map;
      expect(corps['description'], 'd');
      expect(corps['type'], 'quiz');
    });

    test('create envoie l\'objectif sans identifiant d\'enfant', () async {
      faux.repond('POST', '/goals', {'data': {'id': 4, 'status': 'Active'}});
      final echeance = DateTime(2026, 6, 30);
      final g = await GoalsService.instance.create(title: 'Maths', deadline: echeance);
      expect(g.id, 4);
      final corps = faux.recues('POST', '/goals').single.data as Map;
      expect(corps.containsKey('childId'), isFalse);
      expect(corps['title'], 'Maths');
    });

    test('accept, refuse et modify appellent les bonnes routes', () async {
      faux.repond('POST', '/goals/3/accept', {});
      faux.repond('POST', '/goals/3/refuse', {});
      faux.repond('PUT', '/goals/3/modify', {});
      await GoalsService.instance.accept(3);
      await GoalsService.instance.refuse(3);
      final echeance = DateTime(2026, 7, 1);
      await GoalsService.instance.modify(3, title: 'Nouveau', deadline: echeance);
      expect(faux.recues('POST', '/goals/3/accept'), hasLength(1));
      expect(faux.recues('POST', '/goals/3/refuse'), hasLength(1));
      expect(faux.recues('PUT', '/goals/3/modify').single.data, {'title': 'Nouveau', 'deadline': echeance.toIso8601String()});
    });

    test('accept leve l\'erreur du serveur au lieu de l\'avaler', () async {
      faux.repond('POST', '/goals/3/accept', {'error': 'deja traite'}, statut: 409);
      await expectLater(GoalsService.instance.accept(3), throwsA(isA<DioException>()));
    });
  });

  group('QuizMistakesService', () {
    test('getMistakes lit les questions ratees et omet le filtre « Toutes »', () async {
      faux.repond('GET', '/quiz/mistakes', {
        'data': [
          {'id': 1, 'quizId': 2, 'subject': 'Maths', 'question': '2+2 ?', 'givenAnswer': '3', 'correctAnswer': '4', 'createdAt': '2026-01-05T10:00:00Z', 'quizTitle': 'Calcul'},
          {'id': 2},
        ],
      });
      final l = await QuizMistakesService.instance.getMistakes(subject: 'Toutes');
      expect(l, hasLength(2));
      expect(l[0].question, '2+2 ?');
      expect(l[0].correctAnswer, '4');
      expect(l[0].quizTitle, 'Calcul');
      expect(l[1].question, '');
      expect(l[1].quizId, isNull);
      expect(faux.requetes.single.queryParameters, isEmpty);
    });

    test('un filtre de matiere est transmis au serveur', () async {
      faux.repond('GET', '/quiz/mistakes', {'data': []});
      await QuizMistakesService.instance.getMistakes(subject: 'Maths');
      expect(faux.requetes.single.queryParameters, {'subject': 'Maths'});
    });

    test('getSubjects compte les erreurs par matiere', () async {
      faux.repond('GET', '/quiz/mistakes/subjects', {
        'data': [
          {'subject': 'Maths', 'count': 3},
          <String, dynamic>{},
        ],
      });
      final l = await QuizMistakesService.instance.getSubjects();
      expect(l[0].subject, 'Maths');
      expect(l[0].count, 3);
      expect(l[1].subject, '');
      expect(l[1].count, 0);
    });

    test('resolve appelle la route de la question', () async {
      faux.repond('POST', '/quiz/mistakes/4/resolve', {});
      await QuizMistakesService.instance.resolve(4);
      expect(faux.recues('POST', '/quiz/mistakes/4/resolve'), hasLength(1));
    });
  });

  group('ForumService', () {
    test('getThreads envoie la pagination et ignore la categorie « all »', () async {
      faux.repond('GET', '/forums/threads', {'threads': []});
      await ForumService.instance.getThreads(category: 'all', page: 3, pageSize: 10);
      expect(faux.requetes.single.queryParameters, {'page': 3, 'pageSize': 10});
      await ForumService.instance.getThreads(category: 'maths');
      expect(faux.requetes.last.queryParameters, {'page': 1, 'pageSize': 20, 'category': 'maths'});
    });

    test('getPosts accepte une liste brute ou un objet avec posts', () async {
      faux.repond('GET', '/forums/threads/1/posts', [
        {'id': 1},
      ]);
      expect(await ForumService.instance.getPosts(1), hasLength(1));
      faux.repond('GET', '/forums/threads/1/posts', {
        'posts': [
          {'id': 1},
          {'id': 2},
        ],
      });
      expect(await ForumService.instance.getPosts(1), hasLength(2));
      faux.repond('GET', '/forums/threads/1/posts', <String, dynamic>{});
      expect(await ForumService.instance.getPosts(1), isEmpty);
    });

    test('createThread envoie le tag seulement s\'il est donne', () async {
      faux.repond('POST', '/forums/threads', {'id': 1});
      await ForumService.instance.createThread(title: 'T', content: 'C', category: 'maths');
      expect(faux.recues('POST', '/forums/threads').single.data, {'title': 'T', 'content': 'C', 'category': 'maths'});
      await ForumService.instance.createThread(title: 'T', content: 'C', category: 'maths', tag: 'urgent');
      expect((faux.recues('POST', '/forums/threads').last.data as Map)['tag'], 'urgent');
    });

    test('reply et vote envoient leur corps', () async {
      faux.repond('POST', '/forums/threads/1/posts', {});
      faux.repond('POST', '/forums/posts/5/vote', {});
      await ForumService.instance.reply(1, 'Merci');
      await ForumService.instance.vote(5, 'up');
      expect(faux.recues('POST', '/forums/threads/1/posts').single.data, {'content': 'Merci'});
      expect(faux.recues('POST', '/forums/posts/5/vote').single.data, {'type': 'up'});
    });
  });

  group('StudentService', () {
    test('getStats lit les statistiques reelles', () async {
      faux.repond('GET', '/student/stats', {
        'data': {'averageScore': 14, 'hoursSpent': 12.5, 'quizCompleted': 9, 'weeklyQuizCompleted': 2, 'weeklyStudyHours': [1, 0.5, 2], 'totalDownloads': 4},
      });
      final s = await StudentService.instance.getStats();
      expect(s.averageScore, 14.0);
      expect(s.hoursSpent, 12.5);
      expect(s.quizCompleted, 9);
      expect(s.weeklyQuizCompleted, 2);
      expect(s.weeklyStudyHours, [1.0, 0.5, 2.0]);
      expect(s.weeklyStudyHoursTotal, 3.5);
      expect(s.totalDownloads, 4);
    });

    test('getStats sans donnees : tout est a zero', () async {
      faux.repond('GET', '/student/stats', <String, dynamic>{});
      final s = await StudentService.instance.getStats();
      expect(s.averageScore, 0);
      expect(s.weeklyStudyHours, isEmpty);
      expect(s.weeklyStudyHoursTotal, 0);
    });

    test('getContinueLearning arrondit la progression et applique les valeurs par defaut', () async {
      faux.repond('GET', '/student/learning/continue', {
        'data': [
          {'subjectId': 12, 'title': 'Algebre', 'category': 'physique', 'progress': 41.6},
          <String, dynamic>{},
        ],
      });
      final l = await StudentService.instance.getContinueLearning();
      expect(l[0].contentId, '12');
      expect(l[0].title, 'Algebre');
      expect(l[0].subjectId, 'physique');
      expect(l[0].progressPct, 42);
      expect(l[1].contentId, '0');
      expect(l[1].subjectId, 'math');
      expect(l[1].progressPct, 0);
    });

    test('getUpcomingEvents envoie la limite et calcule les jours restants', () async {
      final dans10jours = DateTime.now().add(const Duration(days: 10, hours: 2));
      faux.repond('GET', '/student/events/upcoming', {
        'data': [
          {'title': 'BAC', 'startDate': dans10jours.toIso8601String()},
          {'title': 'Sans date'},
        ],
      });
      final l = await StudentService.instance.getUpcomingEvents(limit: 3);
      expect(faux.requetes.single.queryParameters, {'limit': 3});
      expect(l[0].name, 'BAC');
      expect(l[0].daysLeft, 10);
      expect(l[0].date, WinFormat.dateNumeric(dans10jours));
      expect(l[1].daysLeft, 0);
      expect(l[1].date, '');
    });
  });

  group('LinkingService', () {
    test('getStudentLinks rend le corps tel quel', () async {
      faux.repond('GET', '/student/links', {'teachers': []});
      expect(await LinkingService.instance.getStudentLinks(), {'teachers': []});
    });

    test('searchUsers envoie q et rend la liste', () async {
      faux.repond('GET', '/teacher-links/search', [
        {'id': 1},
      ]);
      final l = await LinkingService.instance.searchUsers('ada');
      expect(l, hasLength(1));
      expect(faux.requetes.single.queryParameters, {'q': 'ada'});
    });

    test('invite, accepte et refuse un lien enseignant', () async {
      faux.repond('POST', '/teacher-links/invite', {});
      faux.repond('PUT', '/teacher-links/4/accept', {});
      faux.repond('PUT', '/teacher-links/4/reject', {});
      faux.repond('DELETE', '/teacher-links/4', null, statut: 204);
      await LinkingService.instance.invite(9);
      await LinkingService.instance.acceptInvitation(4);
      await LinkingService.instance.rejectInvitation(4);
      await LinkingService.instance.deleteLink(4);
      expect(faux.recues('POST', '/teacher-links/invite').single.data, {'targetUserId': 9});
      expect(faux.recues('PUT', '/teacher-links/4/accept'), hasLength(1));
      expect(faux.recues('PUT', '/teacher-links/4/reject'), hasLength(1));
      expect(faux.recues('DELETE', '/teacher-links/4'), hasLength(1));
    });

    test('invitations en attente et liens existants rendent des listes', () async {
      faux.repond('GET', '/teacher-links/pending', [1, 2]);
      faux.repond('GET', '/teacher-links/mine', [3]);
      expect(await LinkingService.instance.getPendingInvitations(), [1, 2]);
      expect(await LinkingService.instance.getMyLinks(), [3]);
    });

    test('rattachements d\'etablissement : liste enveloppee ou brute, vide si format inattendu', () async {
      faux.repond('GET', '/student/institution-attachments', {
        'data': [
          {'id': 1, 'status': 'pending'},
        ],
      });
      var l = await LinkingService.instance.getInstitutionAttachments();
      expect(l.single['status'], 'pending');
      faux.repond('GET', '/student/institution-attachments', [
        {'id': 2},
      ]);
      l = await LinkingService.instance.getInstitutionAttachments();
      expect(l.single['id'], 2);
      faux.repond('GET', '/student/institution-attachments', {'data': 'rien'});
      expect(await LinkingService.instance.getInstitutionAttachments(), isEmpty);
    });

    test('repondre a un rattachement choisit accept ou refuse dans l\'URL', () async {
      faux.repond('PUT', '/student/institution-attachments/6/accept', {});
      faux.repond('PUT', '/student/institution-attachments/6/refuse', {});
      await LinkingService.instance.respondInstitutionAttachment(6, accept: true);
      await LinkingService.instance.respondInstitutionAttachment(6, accept: false);
      expect(faux.recues('PUT', '/student/institution-attachments/6/accept'), hasLength(1));
      expect(faux.recues('PUT', '/student/institution-attachments/6/refuse'), hasLength(1));
    });
  });

  group('Connectivite', () {
    test('par defaut l\'application se croit en ligne : requireOnline ne leve rien', () {
      expect(ConnectivityService.instance.isOnline, isTrue);
      expect(requireOnline, returnsNormally);
    });

    test('OfflineActionException porte le message donne, ou le message par defaut de la langue', () {
      expect(OfflineActionException('coupe').message, 'coupe');
      expect(OfflineActionException('coupe').toString(), 'coupe');
      final defaut = OfflineActionException();
      expect(defaut.message, L10n.current.svcOfflineAction);
      expect(defaut.message, isNotEmpty);
    });
  });
}
