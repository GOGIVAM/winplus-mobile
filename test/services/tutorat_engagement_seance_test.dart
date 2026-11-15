import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/study_session_service.dart';
import 'package:winplus/services/tutor_engagement_service.dart';

import '../helpers/faux_reseau.dart';

Map<String, dynamic> _engagement([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'tutorUserId': 2,
      'startDate': '2026-04-06',
      'endDate': '2026-05-03',
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('Engagement mensuel : libelles', () {
    test('kDayNames commence le dimanche', () {
      expect(kDayNames, ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']);
      L10n.locale = const Locale('en');
      expect(kDayNames.first, 'Sunday');
      expect(kDayNames[1], 'Monday');
    });

    test('tables de libelles couvrent tous les statuts', () {
      expect(kEngagementStatusLabels.keys, containsAll(['pending_payment', 'pending_tutor_approval', 'active', 'completed', 'cancelled', 'rejected', 'expired']));
      expect(kEngagementStatusLabels['active'], 'En cours');
      expect(kMoneyStateLabels.keys, ['held', 'released', 'refunded', 'partial', 'unpaid']);
      expect(kMoneyStateLabels['held'], 'Bloqué');
      expect(kSessionStatusLabels.keys, hasLength(8));
      expect(kSessionStatusLabels['pending_payment'], 'Paiement en cours');
    });
  });

  group('Engagement mensuel : modeles', () {
    test('EngagementSlot : valeurs par defaut, libelle et copie', () {
      final s = EngagementSlot.fromJson(<String, dynamic>{});
      expect(s.dayOfWeek, 1);
      expect(s.startTime, '17:00');
      expect(s.durationMinutes, 60);
      expect(s.label, 'lundi 17:00 (1 h)');
      expect(const EngagementSlot(dayOfWeek: 0, startTime: '09:00', durationMinutes: 90).label, 'dimanche 09:00 (1 h 30)');
      final c = s.copyWith(dayOfWeek: 3, durationMinutes: 30);
      expect(c.dayOfWeek, 3);
      expect(c.startTime, '17:00');
      expect(c.durationMinutes, 30);
      expect(c.endTime, isNull);
    });

    test('EngagementSlot.toJson n\'envoie pas l\'heure de fin', () {
      expect(const EngagementSlot(dayOfWeek: 2, startTime: '10:00', durationMinutes: 45, endTime: '10:45').toJson(), {
        'dayOfWeek': 2,
        'startTime': '10:00',
        'durationMinutes': 45,
      });
    });

    test('EngagementQuote : seances et conflits', () {
      final q = EngagementQuote.fromJson({
        'startDate': '2026-04-06',
        'endDate': '2026-05-03',
        'monthlyEnabled': true,
        'discountPercent': 10,
        'totalXaf': 18000,
        'isAvailable': false,
        'conflicts': ['Lundi 6 avril'],
        'sessions': [
          {'sessionDate': '2026-04-06', 'startTime': '17:00', 'endTime': '18:00', 'priceXaf': 4500, 'isAvailable': true},
        ],
      });
      expect(q.monthlyEnabled, isTrue);
      expect(q.discountPercent, 10);
      expect(q.participantCount, 1);
      expect(q.totalXaf, 18000);
      expect(q.isAvailable, isFalse);
      expect(q.conflicts, ['Lundi 6 avril']);
      expect(q.sessions.single.priceXaf, 4500);
      expect(q.sessions.single.discountXaf, 0);
      expect(q.sessions.single.unavailableReason, isNull);
    });

    test('EngagementSession : argent bloque par defaut et droits d\'action', () {
      final s = EngagementSession.fromJson({'sessionDate': '2026-04-06', 'canCancel': true, 'disputeDeadline': '2026-04-07T10:00:00Z', 'refundPercent': 50});
      expect(s.moneyState, 'held');
      expect(s.canCancel, isTrue);
      expect(s.canDispute, isFalse);
      expect(s.canMarkCompleted, isFalse);
      expect(s.refundPercent, 50);
      expect(s.disputeDeadline!.toUtc(), DateTime.utc(2026, 4, 7, 10));
      expect(EngagementSession.fromJson({'sessionDate': '2026-04-06', 'disputeDeadline': 5}).disputeDeadline, isNull);
    });

    test('TutorEngagementRecord : valeurs par defaut', () {
      final r = TutorEngagementRecord.fromJson(_engagement());
      expect(r.nextStartDate, DateTime.parse('2026-05-03'), reason: 'a defaut, la date de fin');
      expect(r.mode, 'online');
      expect(r.payerType, 'student');
      expect(r.paymentMethod, 'wallet');
      expect(r.totalXaf, 0);
      expect(r.autoRenew, isFalse);
      expect(r.viewerIsPayer, isFalse);
      expect(r.viewerIsTutor, isFalse);
      expect(r.statusLabel, '');
      expect(r.slotsSummary, '');
      expect(r.participantNames, '');
    });

    test('TutorEngagementRecord : statut, creneaux et participants', () {
      final r = TutorEngagementRecord.fromJson(_engagement({
        'status': 'active',
        'nextStartDate': '2026-05-04',
        'slots': [
          {'dayOfWeek': 1, 'startTime': '17:00', 'durationMinutes': 60},
          {'dayOfWeek': 3, 'startTime': '18:30', 'durationMinutes': 30},
        ],
        'participants': [
          {'userId': 1, 'name': 'Ada'},
          {'userId': 2, 'name': 'Bob'},
        ],
        'sessions': [
          {'id': 1, 'sessionDate': '2026-04-06'},
        ],
        'heldXaf': 9000,
        'responseDeadlineAt': '2026-04-01T00:00:00Z',
        'renewedToEngagementId': 9,
      }));
      expect(r.statusLabel, 'En cours');
      expect(r.nextStartDate, DateTime.parse('2026-05-04'));
      expect(r.slotsSummary, 'lundi 17:00 (1 h), mercredi 18:30 (30 min)');
      expect(r.participantNames, 'Ada, Bob');
      expect(r.sessions, hasLength(1));
      expect(r.heldXaf, 9000);
      expect(r.responseDeadlineAt, isNotNull);
      expect(r.renewedToEngagementId, 9);
    });

    test('un statut inconnu est affiche tel quel', () {
      expect(TutorEngagementRecord.fromJson(_engagement({'status': 'bizarre'})).statusLabel, 'bizarre');
    });
  });

  group('TutorEngagementService', () {
    final lundi = [const EngagementSlot(dayOfWeek: 1, startTime: '17:00', durationMinutes: 60)];

    test('dateParam : AAAA-MM-JJ avec zeros', () {
      expect(TutorEngagementService.dateParam(DateTime(2026, 4, 6)), '2026-04-06');
    });

    test('quote envoie le plan (creneaux sans heure de fin, matiere si non vide)', () async {
      faux.repond('POST', '/tutor-engagements/quote', {'startDate': '2026-04-06', 'endDate': '2026-05-03', 'totalXaf': 100});
      final q = await TutorEngagementService.instance
          .quote(tutorUserId: 4, startDate: DateTime(2026, 4, 6), slots: lundi, mode: 'online', subject: '', participantCount: 2);
      expect(q.totalXaf, 100);
      expect(faux.requetes.single.data, {
        'tutorUserId': 4,
        'startDate': '2026-04-06',
        'slots': [
          {'dayOfWeek': 1, 'startTime': '17:00', 'durationMinutes': 60},
        ],
        'mode': 'online',
        'participantCount': 2,
      });
    });

    test('create : paiement, renouvellement automatique et champs facultatifs', () async {
      faux.repond('POST', '/tutor-engagements', {'engagement': _engagement({'id': 7})});
      final r = await TutorEngagementService.instance.create(
        tutorUserId: 4,
        startDate: DateTime(2026, 4, 6),
        slots: lundi,
        mode: 'online',
        paymentMethod: 'wallet',
        phone: '',
        autoRenew: true,
        participantUserIds: const [3],
        payerType: 'parent',
      );
      expect(r.id, 7);
      final d = faux.requetes.single.data as Map;
      expect(d['paymentMethod'], 'wallet');
      expect(d['autoRenew'], isTrue);
      expect(d['topics'], isEmpty);
      expect(d['participantUserIds'], [3]);
      expect(d['payerType'], 'parent');
      expect(d.containsKey('phone'), isFalse);
      expect(d.containsKey('studyGroupId'), isFalse);
    });

    test('lectures : un engagement, mes engagements, ceux du tuteur, demandes en attente', () async {
      faux.repond('GET', '/tutor-engagements/1', _engagement());
      expect((await TutorEngagementService.instance.get(1)).id, 1);
      faux.repond('GET', '/tutor-engagements/mine', [_engagement(), _engagement({'id': 2})]);
      expect(await TutorEngagementService.instance.mine(), hasLength(2));
      faux.repond('GET', '/tutor-engagements/tutor/mine', [_engagement()]);
      expect(await TutorEngagementService.instance.tutorMine(), hasLength(1));
      faux.repond('GET', '/tutor-engagements/tutor/pending', [
        {'engagement': _engagement(), 'minutesRemaining': 15},
        {'engagement': _engagement({'id': 3})},
      ]);
      final p = await TutorEngagementService.instance.pending();
      expect(p.map((e) => e.minutesRemaining), [15, 0]);
      expect(p.last.engagement.id, 3);
    });

    test('actions : accepter, refuser, annuler, renouvellement automatique', () async {
      faux.repond('PUT', '/tutor-engagements/1/accept', _engagement({'status': 'active'}));
      expect((await TutorEngagementService.instance.accept(1)).status, 'active');
      faux.repond('PUT', '/tutor-engagements/1/decline', _engagement({'status': 'rejected'}));
      expect((await TutorEngagementService.instance.decline(1, reason: 'Complet')).status, 'rejected');
      expect(faux.recues('PUT', '/tutor-engagements/1/decline').single.data, {'reason': 'Complet'});
      faux.repond('POST', '/tutor-engagements/1/cancel', _engagement({'status': 'cancelled'}));
      expect((await TutorEngagementService.instance.cancel(1)).status, 'cancelled');
      expect(faux.recues('POST', '/tutor-engagements/1/cancel').single.data, {'reason': null});
      faux.repond('PUT', '/tutor-engagements/1/auto-renew', _engagement({'autoRenew': true}));
      expect((await TutorEngagementService.instance.setAutoRenew(1, true)).autoRenew, isTrue);
      expect(faux.recues('PUT', '/tutor-engagements/1/auto-renew').single.data, {'enabled': true});
    });

    test('renew envoie le moyen de paiement et lit l\'engagement cree', () async {
      faux.repond('POST', '/tutor-engagements/1/renew', {'engagement': _engagement({'id': 8})});
      final r = await TutorEngagementService.instance.renew(1, paymentMethod: 'mobile_money', phone: '670000000');
      expect(r.id, 8);
      expect(faux.requetes.single.data, {'paymentMethod': 'mobile_money', 'phone': '670000000'});
      await TutorEngagementService.instance.renew(1, paymentMethod: 'wallet');
      expect(faux.requetes.last.data, {'paymentMethod': 'wallet'});
    });

    test('errorMessage : message du serveur d\'une DioException, null sinon', () async {
      faux.repond('POST', '/tutor-engagements/1/cancel', {'message': 'Seances en conflit'}, statut: 409);
      try {
        await TutorEngagementService.instance.cancel(1);
        fail('une DioException etait attendue');
      } on DioException catch (e) {
        expect(TutorEngagementService.errorMessage(e), 'Seances en conflit');
      }
      expect(TutorEngagementService.errorMessage(Exception('x')), isNull);
      expect(TutorEngagementService.errorMessage('texte'), isNull);
    });
  });

  group('Session d\'etude guidee : modeles', () {
    test('StudySessionData : 25 minutes et niveau intermediaire par defaut', () {
      final d = StudySessionData.fromJson(<String, dynamic>{});
      expect(d.durationMinutes, 25);
      expect(d.level, 'intermédiaire');
      expect(d.briefing, '');
      expect(d.phases, isEmpty);
      expect(d.subject.id, 0);
    });

    test('StudySessionData lit sujet et phases', () {
      final d = StudySessionData.fromJson({
        'subject': {'id': 3, 'name': 'Maths', 'category': 'Sciences'},
        'duration_minutes': 40,
        'phases': [
          {'id': 'p1', 'label': 'Cours', 'duration_pct': 50},
        ],
      });
      expect(d.subject.name, 'Maths');
      expect(d.durationMinutes, 40);
      expect(d.phases.single.durationPct, 50);
    });

    test('Phase2Question, Phase3Summary et historique', () {
      final q = Phase2Question.fromJson({'question': 'Q', 'options': ['A', 'B', 1], 'correct': 'A'});
      expect(q.options, ['A', 'B', '1']);
      expect(q.explanation, '');
      final s = Phase3Summary.fromJson({'summary': 'S', 'keypoints': ['a'], 'performance_comment': 'Bien'});
      expect(s.performanceComment, 'Bien');
      expect(s.subject, '');
      final h = StudySessionHistoryEntry.fromJson({'id': 1, 'score': 80, 'completedAt': '2026-04-06T10:00:00Z'});
      expect(h.score, 80.0);
      expect(h.completedAt!.toUtc(), DateTime.utc(2026, 4, 6, 10));
      expect(StudySessionHistoryEntry.fromJson(<String, dynamic>{}).completedAt, isNull);
    });
  });

  group('StudySessionService', () {
    test('generate envoie utilisateur, matiere et duree', () async {
      faux.repond('POST', '/ai/study-session/generate', {'briefing': 'Bonjour'});
      final d = await StudySessionService.instance.generate(userId: 1, subjectId: 2, durationMinutes: 30);
      expect(d.briefing, 'Bonjour');
      expect(faux.requetes.single.data, {'user_id': 1, 'subject_id': 2, 'duration_minutes': 30});
    });

    test('phase2Quiz lit les questions de phase2 ; liste vide sans phase2', () async {
      faux.repond('POST', '/ai/study-session/phase2/quiz', {
        'phase2': {
          'questions': [
            {'question': 'Q1', 'options': ['A', 'B'], 'correct': 'B'},
          ],
        },
      });
      final q = await StudySessionService.instance.phase2Quiz(userId: 1, subjectId: 2);
      expect(q.single.correct, 'B');
      faux.repond('POST', '/ai/study-session/phase2/quiz', {});
      expect(await StudySessionService.instance.phase2Quiz(userId: 1, subjectId: 2), isEmpty);
    });

    test('phase3Summary : la note n\'est envoyee que si elle existe', () async {
      faux.repond('POST', '/ai/study-session/phase3/summary', {
        'phase3': {'summary': 'Resume', 'keypoints': ['a', 'b']},
      });
      final s = await StudySessionService.instance.phase3Summary(userId: 1, subjectId: 2, score: 66.5);
      expect(s.keypoints, ['a', 'b']);
      expect(faux.requetes.last.data, {'user_id': 1, 'subject_id': 2, 'score': 66.5});
      await StudySessionService.instance.phase3Summary(userId: 1, subjectId: 2);
      expect(faux.requetes.last.data, {'user_id': 1, 'subject_id': 2});
    });

    test('complete envoie les points cles (liste vide par defaut) et ne leve jamais d\'erreur', () async {
      faux.repond('POST', '/ai/study-session/complete', {});
      await StudySessionService.instance.complete(userId: 1, subjectId: 2, durationMinutes: 25);
      expect(faux.requetes.last.data, {'user_id': 1, 'subject_id': 2, 'duration_minutes': 25, 'key_points': <String>[]});
      faux.repond('POST', '/ai/study-session/complete', {}, statut: 500);
      await StudySessionService.instance.complete(userId: 1, subjectId: 2, durationMinutes: 25, score: 10, keyPoints: ['x']);
      expect(faux.requetes.last.data, containsPair('score', 10));
    });

    test('history lit les seances passees', () async {
      faux.repond('GET', '/ai/study-session/history', [
        {'id': 1, 'subject': 'Maths', 'duration': 25},
      ]);
      final h = await StudySessionService.instance.history();
      expect(h.single.subject, 'Maths');
      expect(h.single.duration, 25);
    });
  });
}
