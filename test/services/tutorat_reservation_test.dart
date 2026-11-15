import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_booking_service.dart';

import '../helpers/faux_reseau.dart';

Map<String, dynamic> _seance([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'tutorUserId': 2,
      'studentUserId': 3,
      'sessionDate': '2026-04-06',
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('Fonctions utilitaires', () {
    test('addMinutesToHhmm : ajoute des minutes et boucle apres minuit', () {
      expect(addMinutesToHhmm('08:00', 90), '09:30');
      expect(addMinutesToHhmm('09:45', 30), '10:15');
      expect(addMinutesToHhmm('23:30', 60), '00:30');
      expect(addMinutesToHhmm('00:00', 0), '00:00');
    });

    test('formatDurationMinutes : minutes, heures, heures et minutes', () {
      expect(formatDurationMinutes(30), '30 min');
      expect(formatDurationMinutes(60), '1 h');
      expect(formatDurationMinutes(90), '1 h 30');
      expect(formatDurationMinutes(125), '2 h 05');
    });
  });

  group('Modeles de reservation', () {
    test('TutorAvailabilityOccurrence : duree max par defaut = derniere duree proposee', () {
      final o = TutorAvailabilityOccurrence.fromJson({
        'date': '2026-04-06',
        'startTime': '10:00',
        'availableDurationsMinutes': [30, 60, 90],
        'isBookable': true,
      });
      expect(o.maxDurationMinutes, 90);
      expect(o.isBookable, isTrue);
      expect(o.date, DateTime.parse('2026-04-06'));
      final v = TutorAvailabilityOccurrence.fromJson({'date': '2026-04-06'});
      expect(v.startTime, '08:00');
      expect(v.maxDurationMinutes, 0);
      expect(v.isBookable, isFalse);
      expect(TutorAvailabilityOccurrence.fromJson({'date': '2026-04-06', 'maxDurationMinutes': 45}).maxDurationMinutes, 45);
    });

    test('TutorPriceQuote : individuel par defaut, groupe des 2 participants', () {
      final q = TutorPriceQuote.fromJson(<String, dynamic>{});
      expect(q.modeCategory, 'online');
      expect(q.participantCount, 1);
      expect(q.isGroup, isFalse);
      expect(q.totalXaf, 0);
      expect(q.isAvailable, isNull);
      expect(q.groupFlatPercent, isNull);
      final g = TutorPriceQuote.fromJson({
        'participantCount': 3,
        'totalXaf': 9000,
        'perStudentXaf': 3000,
        'groupPricingMethod': 'per_student',
        'segments': [
          {'startTime': '10:00', 'endTime': '11:00', 'minutes': 60, 'modifierLabels': ['soir'], 'amountXaf': 4500.5},
        ],
      });
      expect(g.isGroup, isTrue);
      expect(g.perStudentXaf, 3000);
      expect(g.segments.single.modifierLabels, ['soir']);
      expect(g.segments.single.amountXaf, 4500.5);
      expect(g.segments.single.modifierPercent, 0);
    });

    test('TutorBookingParticipant.label : nom, a defaut « Élève #id »', () {
      expect(TutorBookingParticipant.fromJson({'userId': 4, 'name': 'Ada'}).label, 'Ada');
      expect(TutorBookingParticipant.fromJson({'userId': 4, 'name': ''}).label, 'Élève #4');
      expect(TutorBookingParticipant.fromJson({'userId': 4}).label, 'Élève #4');
    });

    test('kPayerTypeLabels : quatre types de payeur', () {
      expect(kPayerTypeLabels, {
        'student': 'Élève',
        'parent': 'Parent',
        'institution': 'Institution',
        'study_group': 'Groupe d\'étude',
      });
    });

    test('TutorAssignment : etats, libelles et auteur de l\'attribution', () {
      final a = TutorAssignment.fromJson(<String, dynamic>{});
      expect(a.status, 'pending');
      expect(a.isPending, isTrue);
      expect(a.isActive, isFalse);
      expect(a.statusLabel, 'En attente du tuteur');
      expect(a.assignerLabel, 'Parent');
      expect(TutorAssignment.fromJson({'status': 'active'}).statusLabel, 'Active');
      expect(TutorAssignment.fromJson({'status': 'active'}).isActive, isTrue);
      expect(TutorAssignment.fromJson({'status': 'declined'}).statusLabel, 'Refusée');
      expect(TutorAssignment.fromJson({'status': 'ended'}).statusLabel, 'Terminée');
      expect(TutorAssignment.fromJson({'status': 'autre'}).statusLabel, 'autre');
      expect(TutorAssignment.fromJson({'assignedByName': 'Mme X'}).assignerLabel, 'Mme X');
      expect(TutorAssignment.fromJson({'assignerType': 'institution'}).assignerLabel, 'Institution');
      expect(TutorAssignment.fromJson({'assignerType': 'institution', 'institutionName': 'Lycee'}).assignerLabel, 'Lycee');
    });

    test('TutorBookingContext : roles de payeur et groupes d\'etude', () {
      final c = TutorBookingContext.fromJson({
        'role': 'parent',
        'allowedPayerTypes': ['student', 'parent'],
        'children': [
          {'userId': 5, 'name': 'Zoe'},
        ],
        'studyGroups': [
          {
            'id': 2,
            'name': 'Groupe A',
            'members': [
              {'userId': 6},
            ],
          },
        ],
        'institutionPendingConfirmationCount': 3,
        'activeAssignments': [
          {'id': 1, 'status': 'active'},
        ],
      });
      expect(c.isParent, isTrue);
      expect(c.isInstitution, isFalse);
      expect(c.children.single.label, 'Zoe');
      expect(c.studyGroups.single.members.single.userId, 6);
      expect(c.institutionPendingConfirmationCount, 3);
      expect(c.activeAssignments.single.isActive, isTrue);
      expect(const TutorBookingContext().isParent, isFalse);
    });

    test('TutorBookingRecord : valeurs par defaut et statuts', () {
      final r = TutorBookingRecord.fromJson(_seance());
      expect(r.startTime, '08:00');
      expect(r.endTime, '09:00');
      expect(r.mode, 'online');
      expect(r.status, 'pending_payment');
      expect(r.isPending, isTrue);
      expect(r.paymentStatus, 'pending');
      expect(r.disputeWindowHours, 24);
      expect(r.payerType, 'student');
      expect(r.participantCount, 1);
      expect(r.canCancelAsPayer, isTrue);
      expect(r.partiesSummary, isNull);
      expect(r.refundSummary, isNull);
      expect(r.paidByWallet, isFalse);
    });

    test('TutorBookingRecord : un statut a la fois', () {
      TutorBookingRecord s(String st) => TutorBookingRecord.fromJson(_seance({'status': st}));
      expect(s('confirmed').isConfirmed, isTrue);
      expect(s('pending_tutor_approval').isPendingTutorApproval, isTrue);
      expect(s('completed').isCompleted, isTrue);
      expect(s('disputed').isDisputed, isTrue);
      expect(s('rejected').isRejected, isTrue);
      expect(s('expired').isExpired, isTrue);
      expect(s('cancelled').isCancelled, isTrue);
      expect(s('confirmed').isCompleted, isFalse);
      expect(TutorBookingRecord.fromJson(_seance({'paymentMethod': 'wallet'})).paidByWallet, isTrue);
    });

    test('canCancelAsPayer : faux seulement si le compte n\'est pas le payeur', () {
      expect(TutorBookingRecord.fromJson(_seance({'viewerIsPayer': false})).canCancelAsPayer, isFalse);
      expect(TutorBookingRecord.fromJson(_seance({'viewerIsPayer': true})).canCancelAsPayer, isTrue);
    });

    test('refundSummary : aucun remboursement = null ; montant nul selon le pourcentage', () {
      final l = L10n.current;
      final tard = TutorBookingRecord.fromJson(_seance({'refundedAt': '2026-04-06T08:00:00Z', 'refundAmountXaf': 0, 'refundPercent': 0}));
      expect(tard.refundSummary, l.svcRefundTooLate);
      final frais = TutorBookingRecord.fromJson(_seance({'refundedAt': '2026-04-06T08:00:00Z', 'refundAmountXaf': 0, 'refundPercent': 50, 'refundFeeXaf': 120}));
      expect(frais.refundSummary, l.svcRefundFeesExceed('120'));
    });

    test('partiesSummary : phrase differente pour un participant non payeur', () {
      final l = L10n.current;
      final pourAutrui = TutorBookingRecord.fromJson(_seance({
        'payerType': 'parent',
        'payerName': 'Mme X',
        'participants': [
          {'userId': 1, 'name': 'Ada'},
          {'userId': 2, 'name': 'Bob'},
        ],
      }));
      expect(pourAutrui.partiesSummary, l.svcBookedForOthers('Ada, Bob', 'Mme X'));
      final pourMoi = TutorBookingRecord.fromJson(_seance({
        'payerType': 'parent',
        'payerName': 'Mme X',
        'viewerIsParticipant': true,
        'viewerIsPayer': false,
        'participants': [
          {'userId': 1, 'name': 'Ada'},
        ],
      }));
      expect(pourMoi.partiesSummary, l.svcBookedForYou('Mme X', '', ''));
    });

    test('TutorBookingRecord exige une date de seance', () {
      expect(() => TutorBookingRecord.fromJson(<String, dynamic>{}), throwsA(anything));
    });

    test('TutorPendingBooking et resultat de creation', () {
      final p = TutorPendingBooking.fromJson({'booking': _seance(), 'minutesRemaining': 42});
      expect(p.minutesRemaining, 42);
      expect(p.booking.id, 1);
      final c = TutorBookingCreatedResult.fromJson({'booking': _seance(), 'notchpayAuthorizationUrl': 'https://pay'});
      expect(c.notchpayAuthorizationUrl, 'https://pay');
    });

    test('TutorPolicy : taux affiche avec virgule decimale', () {
      expect(TutorPolicy.fromJson({'notchPayFeePercent': 3}).feePercentLabel, '3');
      expect(TutorPolicy.fromJson({'notchPayFeePercent': 2.5}).feePercentLabel, '2,5');
      final p = TutorPolicy.fromJson({
        'version': 'v2',
        'bounds': {'min': 5, 'max': 9.0},
        'sections': [
          {'id': 's', 'title': 'T', 'paragraphs': ['a', 'b']},
        ],
      });
      expect(p.version, 'v2');
      expect(p.disputeWindowHours, 24);
      expect(p.bounds, {'min': 5, 'max': 9});
      expect(p.sections.single.paragraphs, ['a', 'b']);
    });
  });

  group('TutorBookingService', () {
    test('getCalendar envoie le debut de semaine au format AAAA-MM-JJ', () async {
      faux.repond('GET', '/tutor-bookings/tutor/4/calendar', [
        {'date': '2026-04-06', 'isBookable': true},
      ]);
      final l = await TutorBookingService.instance.getCalendar(4, DateTime(2026, 4, 8));
      expect(l.single.isBookable, isTrue);
      expect(faux.requetes.single.queryParameters, {'weekStart': '2026-04-08'});
    });

    test('getTwoWeekCalendar fusionne la semaine courante et la suivante', () async {
      faux.repond('GET', '/tutor-bookings/tutor/4/calendar', [
        {'date': '2026-04-06'},
      ]);
      final l = await TutorBookingService.instance.getTwoWeekCalendar(4);
      expect(l, hasLength(2));
      final debuts = faux.requetes.map((r) => r.queryParameters['weekStart']).toSet();
      expect(debuts, hasLength(2));
    });

    test('getWalletAvailableXaf : solde enveloppe ou a plat, null si illisible', () async {
      faux.repond('GET', '/wallet/me', {'data': {'availableXaf': 4000}});
      expect(await TutorBookingService.instance.getWalletAvailableXaf(), 4000);
      faux.repond('GET', '/wallet/me', {'availableXaf': 100});
      expect(await TutorBookingService.instance.getWalletAvailableXaf(), 100);
      faux.repond('GET', '/wallet/me', {}, statut: 500);
      expect(await TutorBookingService.instance.getWalletAvailableXaf(), isNull);
    });

    test('quote envoie la date, le nombre de participants et la matiere si non vide', () async {
      faux.repond('POST', '/tutor-bookings/quote', {'totalXaf': 2500});
      final q = await TutorBookingService.instance.quote(
        tutorUserId: 4,
        sessionDate: DateTime(2026, 4, 6),
        startTime: '10:00',
        durationMinutes: 60,
        mode: 'online',
        subject: '',
      );
      expect(q.totalXaf, 2500);
      expect(faux.requetes.single.data, {
        'tutorUserId': 4,
        'sessionDate': '2026-04-06',
        'startTime': '10:00',
        'durationMinutes': 60,
        'mode': 'online',
        'participantCount': 1,
      });
    });

    test('createBooking : champs facultatifs omis, Mobile Money par defaut', () async {
      faux.repond('POST', '/tutor-bookings', {'booking': _seance(), 'notchpayAuthorizationUrl': 'u'});
      final r = await TutorBookingService.instance.createBooking(
        tutorUserId: 4,
        sessionDate: DateTime(2026, 4, 6),
        startTime: '10:00',
        durationMinutes: 60,
        mode: 'online',
        phone: '',
        participantUserIds: const [],
      );
      expect(r.notchpayAuthorizationUrl, 'u');
      expect(faux.requetes.single.data, {
        'tutorUserId': 4,
        'sessionDate': '2026-04-06',
        'startTime': '10:00',
        'durationMinutes': 60,
        'mode': 'online',
        'paymentMethod': 'mobile_money',
        'topics': <String>[],
      });
    });

    test('createBooking pour autrui : payeur, participants, groupe et attribution', () async {
      faux.repond('POST', '/tutor-bookings', {'booking': _seance()});
      await TutorBookingService.instance.createBooking(
        tutorUserId: 4,
        sessionDate: DateTime(2026, 4, 6),
        startTime: '10:00',
        durationMinutes: 30,
        mode: 'student_home',
        phone: '670000000',
        paymentMethod: 'wallet',
        subject: 'Maths',
        topics: const ['Algebre'],
        payerType: 'parent',
        participantUserIds: const [7, 8],
        studyGroupId: 2,
        tutorAssignmentId: 9,
      );
      final d = faux.requetes.single.data as Map;
      expect(d['payerType'], 'parent');
      expect(d['participantUserIds'], [7, 8]);
      expect(d['studyGroupId'], 2);
      expect(d['tutorAssignmentId'], 9);
      expect(d['phone'], '670000000');
      expect(d['subject'], 'Maths');
      expect(d['topics'], ['Algebre']);
      expect(d['paymentMethod'], 'wallet');
    });

    test('lecture et transitions d\'une reservation', () async {
      faux.repond('GET', '/tutor-bookings/1', _seance());
      expect((await TutorBookingService.instance.getBooking(1)).id, 1);
      faux.repond('GET', '/tutor-bookings/mine', [_seance(), _seance({'id': 2})]);
      expect(await TutorBookingService.instance.getMine(), hasLength(2));
      faux.repond('GET', '/tutor-bookings/tutor/mine', [_seance()]);
      expect(await TutorBookingService.instance.getTutorMine(), hasLength(1));
      faux.repond('GET', '/tutor-bookings/tutor/pending', [
        {'booking': _seance(), 'minutesRemaining': 10},
      ]);
      expect((await TutorBookingService.instance.getPending()).single.minutesRemaining, 10);

      faux.repond('POST', '/tutor-bookings/1/cancel', _seance({'status': 'cancelled'}));
      expect((await TutorBookingService.instance.cancel(1, reason: 'Malade')).isCancelled, isTrue);
      expect(faux.recues('POST', '/tutor-bookings/1/cancel').single.data, {'reason': 'Malade'});

      faux.repond('PUT', '/tutor-bookings/1/confirm', _seance({'status': 'confirmed'}));
      expect((await TutorBookingService.instance.confirm(1)).isConfirmed, isTrue);
      faux.repond('PUT', '/tutor-bookings/1/decline', _seance({'status': 'rejected'}));
      expect((await TutorBookingService.instance.decline(1)).isRejected, isTrue);
      expect(faux.recues('PUT', '/tutor-bookings/1/decline').single.data, {'reason': null});
      faux.repond('PUT', '/tutor-bookings/1/complete', _seance({'status': 'completed'}));
      expect((await TutorBookingService.instance.complete(1)).isCompleted, isTrue);
      faux.repond('PUT', '/tutor-bookings/1/dispute', _seance({'status': 'disputed'}));
      expect((await TutorBookingService.instance.dispute(1, 'Absent')).isDisputed, isTrue);
      expect(faux.recues('PUT', '/tutor-bookings/1/dispute').single.data, {'reason': 'Absent'});
    });

    test('attributions de tuteur : contexte, listes, creation, reponse', () async {
      faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'parent'});
      expect((await TutorBookingService.instance.getBookingContext()).role, 'parent');
      faux.repond('GET', '/tutor-assignments/mine', [
        {'id': 1},
      ]);
      expect(await TutorBookingService.instance.getMyAssignments(), hasLength(1));
      faux.repond('GET', '/tutor-assignments/for-me', [
        {'id': 1},
        {'id': 2},
      ]);
      expect(await TutorBookingService.instance.getAssignmentsForMe(), hasLength(2));
      faux.repond('GET', '/tutor-assignments/tutor', []);
      expect(await TutorBookingService.instance.getTutorAssignments(), isEmpty);

      faux.repond('POST', '/tutor-assignments', {'id': 3});
      await TutorBookingService.instance.createAssignment(tutorUserId: 4, studentUserIds: const [5], groupName: '', subject: 'Maths', note: 'Merci');
      expect(faux.requetes.last.data, {'tutorUserId': 4, 'studentUserIds': [5], 'subject': 'Maths', 'note': 'Merci'});

      faux.repond('PUT', '/tutor-assignments/3/accept', {'id': 3, 'status': 'active'});
      final r = await TutorBookingService.instance.respondAssignment(3, action: 'accept');
      expect(r.isActive, isTrue);
      expect(faux.requetes.last.data, {'note': null});
    });

    test('getPolicy : lue une fois puis gardee en memoire (reponse enveloppee)', () async {
      faux.repond('GET', '/tutor-policy', {'data': {'version': 'v9', 'notchPayFeePercent': 3}});
      final a = await TutorBookingService.instance.getPolicy();
      final b = await TutorBookingService.instance.getPolicy();
      expect(a.version, 'v9');
      expect(b, same(a));
      expect(faux.recues('GET', '/tutor-policy'), hasLength(1));
    });
  });
}
