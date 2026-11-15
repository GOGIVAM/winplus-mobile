import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/exam_coach_service.dart';
import 'package:winplus/services/study_group_service.dart';
import 'package:winplus/services/tutor_review_service.dart';
import 'package:winplus/services/wallet_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('Portefeuille : modeles', () {
    test('WalletWithdrawal : valeurs par defaut, montant et etats', () {
      final w = WalletWithdrawal.fromJson(<String, dynamic>{});
      expect(w.status, 'pending');
      expect(w.operator, 'mtn');
      expect(w.operatorLabel, 'MTN MoMo');
      expect(w.amountXaf, 0);
      expect(w.isTerminal, isFalse);
      expect(w.requestedAt, isNull);
      final o = WalletWithdrawal.fromJson({'id': 3, 'operator': 'orange', 'amount': 1500.4, 'status': 'completed', 'processedAt': '2026-01-02T00:00:00Z'});
      expect(o.operatorLabel, 'Orange Money');
      expect(o.amountXaf, 1500);
      expect(o.isCompleted, isTrue);
      expect(o.isTerminal, isTrue);
      expect(o.processedAt!.toUtc(), DateTime.utc(2026, 1, 2));
    });

    test('WalletWithdrawal : amountXaf prime sur amount ; echec et annulation sont terminaux', () {
      expect(WalletWithdrawal.fromJson({'amountXaf': 700, 'amount': 900}).amountXaf, 700);
      expect(WalletWithdrawal.fromJson({'status': 'failed'}).isFailed, isTrue);
      expect(WalletWithdrawal.fromJson({'status': 'cancelled'}).isTerminal, isTrue);
      expect(WalletWithdrawal.fromJson({'status': 'processing'}).isTerminal, isFalse);
    });

    test('WalletSummary : minimums par defaut, vide et retrait actif', () {
      final s = WalletSummary.fromJson(<String, dynamic>{});
      expect(s.isEmpty, isTrue);
      expect(s.minWithdrawalXaf, 500);
      expect(s.minRechargeXaf, 100);
      expect(s.activeWithdrawal, isNull);
      final p = WalletSummary.fromJson({
        'availableXaf': 1000,
        'engagedXaf': 5,
        'isAnomaly': true,
        'activeWithdrawal': {'id': 1},
      });
      expect(p.isEmpty, isFalse);
      expect(p.isAnomaly, isTrue);
      expect(p.activeWithdrawal!.id, 1);
    });

    test('WalletEntry : valeurs par defaut', () {
      final e = WalletEntry.fromJson(<String, dynamic>{});
      expect(e.source, 'autre');
      expect(e.status, 'completed');
      expect(e.date, isNull);
    });

    test('walletSources commence par Tout et couvre 8 filtres', () {
      expect(walletSources.first, ('all', 'Tout'));
      expect(walletSources, hasLength(8));
    });

    test('newClientRequestId : identifiants differents a chaque appel', () {
      final a = newClientRequestId();
      final b = newClientRequestId();
      expect(a, isNot(b));
      expect(a, contains('-'));
    });

    test('WalletApiException : indicateurs derives du code HTTP', () {
      expect(const WalletApiException('x', statusCode: 401).sessionExpired, isTrue);
      expect(const WalletApiException('x', statusCode: 402).insufficientBalance, isTrue);
      expect(const WalletApiException('x').offline, isTrue);
      expect(const WalletApiException('x', statusCode: 500).offline, isFalse);
      expect(const WalletApiException('Message').toString(), 'Message');
    });
  });

  group('WalletService', () {
    test('getSummary lit la reponse enveloppee dans data ou a plat', () async {
      faux.repond('GET', '/wallet/me', {
        'data': {'availableXaf': 2000},
      });
      expect((await WalletService.instance.getSummary()).availableXaf, 2000);
      faux.repond('GET', '/wallet/me', {'availableXaf': 3000});
      expect((await WalletService.instance.getSummary()).availableXaf, 3000);
    });

    test('getSummary : 401 = session expiree', () async {
      faux.repond('GET', '/wallet/me', {}, statut: 401);
      await expectLater(
        WalletService.instance.getSummary(),
        throwsA(isA<WalletApiException>().having((e) => e.sessionExpired, 'sessionExpired', isTrue)),
      );
    });

    test('getSummary : coupure reseau = message de connexion, hors ligne', () async {
      faux.coupure('GET', '/wallet/me');
      await expectLater(
        WalletService.instance.getSummary(),
        throwsA(isA<WalletApiException>()
            .having((e) => e.offline, 'offline', isTrue)
            .having((e) => e.message, 'message', 'Connexion impossible. Vérifie ton réseau et réessaie.')),
      );
    });

    test('getSummary : 500 sans message serveur = message par defaut', () async {
      faux.repond('GET', '/wallet/me', {}, statut: 500);
      await expectLater(
        WalletService.instance.getSummary(),
        throwsA(isA<WalletApiException>()
            .having((e) => e.message, 'message', 'Impossible de charger ton solde.')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('un 403 sans message demande de verifier l\'e-mail ; avec message, il est repris', () async {
      faux.repond('GET', '/wallet/me', {}, statut: 403);
      await expectLater(
        WalletService.instance.getSummary(),
        throwsA(isA<WalletApiException>().having((e) => e.message, 'message', contains('vérifie ton adresse e-mail'))),
      );
      faux.repond('GET', '/wallet/me', {'error': 'Interdit'}, statut: 403);
      await expectLater(
        WalletService.instance.getSummary(),
        throwsA(isA<WalletApiException>().having((e) => e.message, 'message', 'Interdit')),
      );
    });

    test('402 : le solde disponible et le code du serveur sont remontes', () async {
      faux.repond('POST', '/withdrawals', {'error': 'Solde insuffisant', 'code': 'low', 'balanceXaf': 300}, statut: 402);
      await expectLater(
        WalletService.instance.requestWithdrawal(operator: 'mtn', phone: '6', amountXaf: 1000, clientRequestId: 'id'),
        throwsA(isA<WalletApiException>()
            .having((e) => e.insufficientBalance, 'insufficientBalance', isTrue)
            .having((e) => e.code, 'code', 'low')
            .having((e) => e.availableXaf, 'availableXaf', 300)),
      );
    });

    test('getEntries envoie source, page et taille et ignore les lignes invalides', () async {
      faux.repond('GET', '/wallet/me/entries', {
        'data': {
          'items': [
            {'id': 1, 'label': 'Vente', 'amountXaf': 500},
            'pas une map',
            {'id': 2},
          ],
          'total': 9,
        },
      });
      final p = await WalletService.instance.getEntries(source: 'retrait', page: 2, pageSize: 5);
      expect(p.items.map((e) => e.id), [1, 2]);
      expect(p.total, 9);
      expect(faux.requetes.single.queryParameters, {'source': 'retrait', 'page': 2, 'pageSize': 5});
    });

    test('getActiveWithdrawal : null quand data est absent', () async {
      faux.repond('GET', '/withdrawals/active', {'data': {'id': 4, 'status': 'processing'}});
      expect((await WalletService.instance.getActiveWithdrawal())!.id, 4);
      faux.repond('GET', '/withdrawals/active', {'data': null});
      expect(await WalletService.instance.getActiveWithdrawal(), isNull);
    });

    test('getWithdrawal lit le statut', () async {
      faux.repond('GET', '/withdrawals/status/4', {'data': {'id': 4, 'status': 'completed'}});
      expect((await WalletService.instance.getWithdrawal(4)).isCompleted, isTrue);
    });

    test('requestWithdrawal envoie operateur, telephone, montant et identifiant de rejeu', () async {
      faux.repond('POST', '/withdrawals', {'data': {'id': 5}});
      final w = await WalletService.instance
          .requestWithdrawal(operator: 'orange', phone: '690000000', amountXaf: 2000, clientRequestId: 'abc');
      expect(w.id, 5);
      expect(faux.requetes.single.data, {'operator': 'orange', 'phone': '690000000', 'amount': 2000, 'clientRequestId': 'abc'});
    });

    test('requestWithdrawal sans message serveur : message par defaut', () async {
      faux.repond('POST', '/withdrawals', {}, statut: 500);
      await expectLater(
        WalletService.instance.requestWithdrawal(operator: 'mtn', phone: '6', amountXaf: 1, clientRequestId: 'x'),
        throwsA(isA<WalletApiException>().having((e) => e.message, 'message', 'Le retrait n\'a pas pu être enregistré.')),
      );
    });

    test('startRecharge lit le paiement cree', () async {
      faux.repond('POST', '/wallet/recharge', {'data': {'paymentId': 8, 'amountXaf': 1000}});
      final r = await WalletService.instance
          .startRecharge(operator: 'mtn', phone: '670', amountXaf: 1000, clientRequestId: 'r1');
      expect(r.paymentId, 8);
      expect(r.amountXaf, 1000);
      expect(faux.requetes.single.data, {'amount': 1000, 'operator': 'mtn', 'phone': '670', 'clientRequestId': 'r1'});
    });

    test('getPaymentStatus : statut en minuscules et message d\'erreur', () async {
      faux.repond('GET', '/payments/8/status', {'status': 'FAILED', 'errorMessage': 'Annule'});
      final (statut, message) = await WalletService.instance.getPaymentStatus(8);
      expect(statut, 'failed');
      expect(message, 'Annule');
      faux.repond('GET', '/payments/9/status', {});
      expect((await WalletService.instance.getPaymentStatus(9)).$1, 'pending');
    });
  });

  group('TutorReview et TutorReviewService', () {
    test('TutorReview : valeurs par defaut et dates', () {
      final r = TutorReview.fromJson(<String, dynamic>{});
      expect(r.id, 0);
      expect(r.rating, 0);
      expect(r.tutorReply, isNull);
      expect(r.createdAt, isNull);
      final p = TutorReview.fromJson({'rating': 5, 'createdAt': '2026-02-01T08:00:00Z', 'tutorRepliedAt': '2026-02-02T08:00:00Z'});
      expect(p.createdAt!.toUtc(), DateTime.utc(2026, 2, 1, 8));
      expect(p.tutorRepliedAt!.toUtc(), DateTime.utc(2026, 2, 2, 8));
    });

    test('submit envoie la note, et le commentaire seulement s\'il existe', () async {
      faux.repond('POST', '/tutor-reviews', {'id': 1, 'rating': 4});
      final r = await TutorReviewService.instance.submit(7, 4, comment: 'Bien');
      expect(r.rating, 4);
      await TutorReviewService.instance.submit(7, 4, comment: '');
      final d = faux.recues('POST', '/tutor-reviews');
      expect(d[0].data, {'tutorBookingId': 7, 'rating': 4, 'comment': 'Bien'});
      expect(d[1].data, {'tutorBookingId': 7, 'rating': 4});
    });

    test('submit : erreur du serveur, puis message par defaut', () async {
      faux.repond('POST', '/tutor-reviews', {'error': 'Deja note'}, statut: 400);
      await expectLater(
        TutorReviewService.instance.submit(7, 4),
        throwsA(isA<Exception>().having((e) => e.toString(), 'texte', contains('Deja note'))),
      );
      faux.repond('POST', '/tutor-reviews', {}, statut: 500);
      await expectLater(
        TutorReviewService.instance.submit(7, 4),
        throwsA(isA<Exception>().having((e) => e.toString(), 'texte', contains('avis'))),
      );
    });

    test('reply poste la reponse', () async {
      faux.repond('POST', '/tutor-reviews/3/reply', {'id': 3, 'tutorReply': 'Merci'});
      final r = await TutorReviewService.instance.reply(3, 'Merci');
      expect(r.tutorReply, 'Merci');
      expect(faux.requetes.single.data, {'reply': 'Merci'});
    });

    test('getForTutor accepte { items } ou une liste brute', () async {
      faux.repond('GET', '/tutor-reviews/tutor/9', {
        'items': [
          {'id': 1},
        ],
      });
      expect(await TutorReviewService.instance.getForTutor(9), hasLength(1));
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 20});
      faux.repond('GET', '/tutor-reviews/tutor/9', [
        {'id': 1},
        {'id': 2},
      ]);
      expect(await TutorReviewService.instance.getForTutor(9), hasLength(2));
    });
  });

  group('Groupes d\'etude', () {
    test('ApiStudyGroup : valeurs par defaut', () {
      final g = ApiStudyGroup.fromJson(<String, dynamic>{});
      expect(g.name, '');
      expect(g.joinCode, '');
      expect(g.isOwner, isFalse);
      expect(g.memberCount, 0);
      expect(g.lastActivityAt, isNull);
    });

    test('ApiStudyGroupMember.fullName ignore les parties vides', () {
      expect(ApiStudyGroupMember.fromJson({'firstName': 'Ada', 'lastName': 'Eto'}).fullName, 'Ada Eto');
      expect(ApiStudyGroupMember.fromJson({'firstName': 'Ada', 'lastName': ''}).fullName, 'Ada');
      expect(ApiStudyGroupMember.fromJson(<String, dynamic>{}).fullName, '');
      expect(ApiStudyGroupMember.fromJson(<String, dynamic>{}).role, 'member');
    });

    test('ApiStudyGroupDetail : le nombre de membres vient de la liste', () {
      final d = ApiStudyGroupDetail.fromJson({
        'id': 2,
        'name': 'G',
        'memberCount': 99,
        'members': [
          {'userId': 1},
          {'userId': 2},
        ],
      });
      expect(d.memberCount, 2);
      expect(d.members.map((m) => m.userId), [1, 2]);
    });

    test('classement : periode de 7 jours par defaut et nom complet', () {
      final l = ApiStudyGroupLeaderboard.fromJson({
        'ranking': [
          {'userId': 1, 'firstName': 'Ada', 'points': 30, 'quizzesPassed': 2, 'studyMinutes': 45},
        ],
      });
      expect(l.periodDays, 7);
      expect(l.ranking.single.fullName, 'Ada');
      expect(l.ranking.single.points, 30);
      expect(ApiStudyGroupLeaderboard.fromJson(<String, dynamic>{}).ranking, isEmpty);
    });

    test('StudyGroupService : liste, detail, creation, adhesion, depart, classement', () async {
      faux.repond('GET', '/study-groups/me', {
        'data': [
          {'id': 1, 'name': 'A'},
        ],
      });
      expect((await StudyGroupService.instance.getMine()).single.name, 'A');

      faux.repond('GET', '/study-groups/1', {
        'data': {'id': 1, 'name': 'A', 'members': []},
      });
      expect((await StudyGroupService.instance.getOne(1)).members, isEmpty);

      faux.repond('POST', '/study-groups', {
        'data': {'id': 2, 'name': 'Nouveau'},
      });
      expect((await StudyGroupService.instance.create(name: 'Nouveau', subject: 'Maths', description: '')).id, 2);
      expect(faux.requetes.last.data, {'name': 'Nouveau', 'subject': 'Maths'});

      faux.repond('POST', '/study-groups/join', {
        'data': {'id': 3, 'name': 'Rejoint', 'alreadyMember': true},
      });
      final j = await StudyGroupService.instance.join('ABC123');
      expect(j.alreadyMember, isTrue);
      expect(faux.requetes.last.data, {'code': 'ABC123'});

      faux.repond('DELETE', '/study-groups/1/leave', {});
      await StudyGroupService.instance.leave(1);
      expect(faux.recues('DELETE', '/study-groups/1/leave'), hasLength(1));

      faux.repond('GET', '/study-groups/1/leaderboard', {
        'data': {'periodDays': 14, 'ranking': []},
      });
      expect((await StudyGroupService.instance.getLeaderboard(1)).periodDays, 14);
    });
  });

  group('Exam Coach : modeles et mode veille', () {
    test('ApiExamCoachPlan : valeurs par defaut et jours termines', () {
      final p = ApiExamCoachPlan.fromJson(<String, dynamic>{});
      expect(p.hoursPerDay, 2.0);
      expect(p.confidenceScore, 0.0);
      expect(p.isActive, isTrue);
      expect(p.planJson, '{}');
      expect(p.completedDays, isEmpty);
      final q = ApiExamCoachPlan.fromJson({
        'examDate': '2026-06-15T00:00:00Z',
        'completedDays': [
          {'dayNumber': 1, 'completedAt': '2026-05-01T00:00:00Z', 'quizScore': 80},
        ],
      });
      expect(q.examDate.toUtc(), DateTime.utc(2026, 6, 15));
      expect(q.completedDays.single.quizScore, 80.0);
    });

    test('mode veille : lecture, activation (date non fournie omise) et desactivation', () async {
      faux.repond('GET', '/exam-coach/5/watch-mode', {'active': true, 'examType': 'BAC', 'examDate': '2026-06-15T00:00:00Z'});
      final s = await ExamCoachService.instance.getWatchMode(5);
      expect(s.active, isTrue);
      expect(s.examType, 'BAC');
      expect(s.examDate, isNotNull);

      faux.repond('POST', '/exam-coach/5/watch-mode', {'active': true});
      await ExamCoachService.instance.activateWatchMode(5);
      expect(faux.recues('POST', '/exam-coach/5/watch-mode').single.data, {'hoursPerDay': 2.0});
      await ExamCoachService.instance.activateWatchMode(5, examType: 'BEPC', hoursPerDay: 3);
      expect(faux.recues('POST', '/exam-coach/5/watch-mode').last.data, {'examType': 'BEPC', 'hoursPerDay': 3.0});

      faux.repond('DELETE', '/exam-coach/5/watch-mode', {});
      await ExamCoachService.instance.deactivateWatchMode(5);
      expect(faux.recues('DELETE', '/exam-coach/5/watch-mode'), hasLength(1));
      expect(ApiWatchModeState.fromJson(<String, dynamic>{}).active, isFalse);
    });
  });
}
