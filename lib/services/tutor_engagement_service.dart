import 'api_client.dart';
import 'tutor_booking_service.dart';
import '../l10n/l10n.dart';

/// Lot 9.4 (suivi 17.7) : engagement mensuel à créneaux fixes, parité web.
/// Les mêmes créneaux chaque semaine pendant 4 semaines, payés d'avance ; le
/// prix vient toujours du devis serveur. Les actions sur une séance précise
/// (effectuée, contestation, annulation d'une séance seule) passent par
/// [TutorBookingService] : chaque séance garde son propre cycle.

/// Jours (index 0 = dimanche), dans la langue de l'application (lot 10.11).
List<String> get kDayNames => [for (final d in const [7, 1, 2, 3, 4, 5, 6]) WinFormat.weekdayCap(d)];

Map<String, String> get kEngagementStatusLabels {
  final l = L10n.current;
  return {
    'pending_payment': l.tutoringStatusPendingPayment,
    'pending_tutor_approval': l.tutoringStatusPendingTutor,
    'active': l.svcEngStatusActive,
    'completed': l.svcEngStatusCompleted,
    'cancelled': l.svcEngStatusCancelled,
    'rejected': l.svcEngStatusRejected,
    'expired': l.svcEngStatusExpired,
  };
}

Map<String, String> get kMoneyStateLabels {
  final l = L10n.current;
  return {
    'held': l.tutoringEngHeld,
    'released': l.tutoringEngReleased,
    'refunded': l.tutoringEngRefundedTile,
    'partial': l.svcMoneyPartial,
    'unpaid': l.svcMoneyUnpaid,
  };
}

Map<String, String> get kSessionStatusLabels {
  final l = L10n.current;
  return {
    'pending_payment': l.tutoringStatusPendingPayment,
    'pending_tutor_approval': l.commonPending,
    'confirmed': l.svcSessionStatusConfirmed,
    'completed': l.tutoringStatusCompleted,
    'disputed': l.tutoringStatusDisputed,
    'cancelled': l.shopOrderCancelled,
    'rejected': l.tutoringStatusRejected,
    'expired': l.tutoringStatusExpired,
  };
}

DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;
num _num(dynamic v) => v is num ? v : 0;

class EngagementSlot {
  final int dayOfWeek; // 0 = dimanche … 6 = samedi
  final String startTime;
  final int durationMinutes;
  final String? endTime;
  const EngagementSlot({required this.dayOfWeek, required this.startTime, required this.durationMinutes, this.endTime});

  EngagementSlot copyWith({int? dayOfWeek, String? startTime, int? durationMinutes}) => EngagementSlot(
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );

  String get label => '${WinFormat.weekday(dayOfWeek == 0 ? 7 : dayOfWeek)} $startTime (${formatDurationMinutes(durationMinutes)})';

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'startTime': startTime, 'durationMinutes': durationMinutes};

  factory EngagementSlot.fromJson(Map<String, dynamic> j) => EngagementSlot(
        dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 1,
        startTime: j['startTime'] as String? ?? '17:00',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 60,
        endTime: j['endTime'] as String?,
      );
}

class EngagementQuoteSession {
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final num baseTotalXaf;
  final num discountXaf;
  final num priceXaf;
  final bool isAvailable;
  final String? unavailableReason;
  const EngagementQuoteSession({
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.baseTotalXaf,
    required this.discountXaf,
    required this.priceXaf,
    required this.isAvailable,
    this.unavailableReason,
  });

  factory EngagementQuoteSession.fromJson(Map<String, dynamic> j) => EngagementQuoteSession(
        sessionDate: DateTime.parse(j['sessionDate'] as String),
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        baseTotalXaf: _num(j['baseTotalXaf']),
        discountXaf: _num(j['discountXaf']),
        priceXaf: _num(j['priceXaf']),
        isAvailable: j['isAvailable'] as bool? ?? false,
        unavailableReason: j['unavailableReason'] as String?,
      );
}

class EngagementQuote {
  final DateTime startDate;
  final DateTime endDate;
  final bool monthlyEnabled;
  final int discountPercent;
  final int participantCount;
  final List<EngagementQuoteSession> sessions;
  final num subtotalXaf;
  final num discountXaf;
  final num totalXaf;
  final bool isAvailable;
  final List<String> conflicts;
  const EngagementQuote({
    required this.startDate,
    required this.endDate,
    required this.monthlyEnabled,
    required this.discountPercent,
    required this.participantCount,
    required this.sessions,
    required this.subtotalXaf,
    required this.discountXaf,
    required this.totalXaf,
    required this.isAvailable,
    required this.conflicts,
  });

  factory EngagementQuote.fromJson(Map<String, dynamic> j) => EngagementQuote(
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        monthlyEnabled: j['monthlyEnabled'] as bool? ?? false,
        discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
        participantCount: (j['participantCount'] as num?)?.toInt() ?? 1,
        sessions: (j['sessions'] as List? ?? []).map((e) => EngagementQuoteSession.fromJson(e as Map<String, dynamic>)).toList(),
        subtotalXaf: _num(j['subtotalXaf']),
        discountXaf: _num(j['discountXaf']),
        totalXaf: _num(j['totalXaf']),
        isAvailable: j['isAvailable'] as bool? ?? false,
        conflicts: (j['conflicts'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class EngagementSession {
  final int id;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final num priceXaf;
  final String status;
  final String moneyState;
  final num? refundAmountXaf;
  final int? refundPercent;
  final DateTime? disputeDeadline;
  final bool canMarkCompleted;
  final bool canDispute;
  final bool canCancel;
  const EngagementSession({
    required this.id,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.priceXaf,
    required this.status,
    required this.moneyState,
    this.refundAmountXaf,
    this.refundPercent,
    this.disputeDeadline,
    this.canMarkCompleted = false,
    this.canDispute = false,
    this.canCancel = false,
  });

  factory EngagementSession.fromJson(Map<String, dynamic> j) => EngagementSession(
        id: (j['id'] as num?)?.toInt() ?? 0,
        sessionDate: DateTime.parse(j['sessionDate'] as String),
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        priceXaf: _num(j['priceXaf']),
        status: j['status'] as String? ?? '',
        moneyState: j['moneyState'] as String? ?? 'held',
        refundAmountXaf: j['refundAmountXaf'] as num?,
        refundPercent: (j['refundPercent'] as num?)?.toInt(),
        disputeDeadline: _date(j['disputeDeadline']),
        canMarkCompleted: j['canMarkCompleted'] as bool? ?? false,
        canDispute: j['canDispute'] as bool? ?? false,
        canCancel: j['canCancel'] as bool? ?? false,
      );
}

class TutorEngagementRecord {
  final int id;
  final int tutorUserId;
  final String? tutorName;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextStartDate;
  final List<EngagementSlot> slots;
  final String mode;
  final String? subject;
  final String payerType;
  final String? payerName;
  final List<TutorBookingParticipant> participants;
  final int discountPercent;
  final num discountXaf;
  final num totalXaf;
  final String paymentMethod;
  final num releasedXaf;
  final num heldXaf;
  final num refundedXaf;
  final num feesRetainedXaf;
  final int sessionsCount;
  final int sessionsDone;
  final List<EngagementSession> sessions;
  final DateTime? responseDeadlineAt;
  final bool autoRenew;
  final bool canSetAutoRenew;
  final bool canRenew;
  final bool canCancel;
  final DateTime? autoRenewAt;
  final String? autoRenewFailureReason;
  final int? renewedToEngagementId;
  final String? cancellationReason;
  final bool viewerIsPayer;
  final bool viewerIsTutor;

  const TutorEngagementRecord({
    required this.id,
    required this.tutorUserId,
    this.tutorName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.nextStartDate,
    this.slots = const [],
    this.mode = 'online',
    this.subject,
    this.payerType = 'student',
    this.payerName,
    this.participants = const [],
    this.discountPercent = 0,
    this.discountXaf = 0,
    this.totalXaf = 0,
    this.paymentMethod = 'wallet',
    this.releasedXaf = 0,
    this.heldXaf = 0,
    this.refundedXaf = 0,
    this.feesRetainedXaf = 0,
    this.sessionsCount = 0,
    this.sessionsDone = 0,
    this.sessions = const [],
    this.responseDeadlineAt,
    this.autoRenew = false,
    this.canSetAutoRenew = false,
    this.canRenew = false,
    this.canCancel = false,
    this.autoRenewAt,
    this.autoRenewFailureReason,
    this.renewedToEngagementId,
    this.cancellationReason,
    this.viewerIsPayer = false,
    this.viewerIsTutor = false,
  });

  String get statusLabel => kEngagementStatusLabels[status] ?? status;
  String get slotsSummary => slots.map((s) => s.label).join(', ');
  String get participantNames => participants.map((p) => p.label).join(', ');

  factory TutorEngagementRecord.fromJson(Map<String, dynamic> j) => TutorEngagementRecord(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tutorUserId: (j['tutorUserId'] as num?)?.toInt() ?? 0,
        tutorName: j['tutorName'] as String?,
        status: j['status'] as String? ?? '',
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        nextStartDate: DateTime.parse((j['nextStartDate'] ?? j['endDate']) as String),
        slots: (j['slots'] as List? ?? []).map((e) => EngagementSlot.fromJson(e as Map<String, dynamic>)).toList(),
        mode: j['mode'] as String? ?? 'online',
        subject: j['subject'] as String?,
        payerType: j['payerType'] as String? ?? 'student',
        payerName: j['payerName'] as String?,
        participants: (j['participants'] as List? ?? []).map((e) => TutorBookingParticipant.fromJson(e as Map<String, dynamic>)).toList(),
        discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
        discountXaf: _num(j['discountXaf']),
        totalXaf: _num(j['totalXaf']),
        paymentMethod: j['paymentMethod'] as String? ?? 'wallet',
        releasedXaf: _num(j['releasedXaf']),
        heldXaf: _num(j['heldXaf']),
        refundedXaf: _num(j['refundedXaf']),
        feesRetainedXaf: _num(j['feesRetainedXaf']),
        sessionsCount: (j['sessionsCount'] as num?)?.toInt() ?? 0,
        sessionsDone: (j['sessionsDone'] as num?)?.toInt() ?? 0,
        sessions: (j['sessions'] as List? ?? []).map((e) => EngagementSession.fromJson(e as Map<String, dynamic>)).toList(),
        responseDeadlineAt: _date(j['responseDeadlineAt']),
        autoRenew: j['autoRenew'] as bool? ?? false,
        canSetAutoRenew: j['canSetAutoRenew'] as bool? ?? false,
        canRenew: j['canRenew'] as bool? ?? false,
        canCancel: j['canCancel'] as bool? ?? false,
        autoRenewAt: _date(j['autoRenewAt']),
        autoRenewFailureReason: j['autoRenewFailureReason'] as String?,
        renewedToEngagementId: (j['renewedToEngagementId'] as num?)?.toInt(),
        cancellationReason: j['cancellationReason'] as String?,
        viewerIsPayer: j['viewerIsPayer'] as bool? ?? false,
        viewerIsTutor: j['viewerIsTutor'] as bool? ?? false,
      );
}

class PendingEngagement {
  final TutorEngagementRecord engagement;
  final int minutesRemaining;
  const PendingEngagement(this.engagement, this.minutesRemaining);
}

class TutorEngagementService {
  TutorEngagementService._();
  static final TutorEngagementService instance = TutorEngagementService._();
  final _api = ApiClient.instance;

  static String dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _plan({
    required int tutorUserId,
    required DateTime startDate,
    required List<EngagementSlot> slots,
    required String mode,
    String? subject,
    int participantCount = 1,
  }) =>
      {
        'tutorUserId': tutorUserId,
        'startDate': dateParam(startDate),
        'slots': slots.map((s) => s.toJson()).toList(),
        'mode': mode,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'participantCount': participantCount,
      };

  Future<EngagementQuote> quote({
    required int tutorUserId,
    required DateTime startDate,
    required List<EngagementSlot> slots,
    required String mode,
    String? subject,
    int participantCount = 1,
  }) async {
    final res = await _api.dio.post('/tutor-engagements/quote',
        data: _plan(tutorUserId: tutorUserId, startDate: startDate, slots: slots, mode: mode, subject: subject, participantCount: participantCount));
    return EngagementQuote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorEngagementRecord> create({
    required int tutorUserId,
    required DateTime startDate,
    required List<EngagementSlot> slots,
    required String mode,
    String? subject,
    int participantCount = 1,
    List<String> topics = const [],
    required String paymentMethod,
    String? phone,
    String? payerType,
    List<int>? participantUserIds,
    int? studyGroupId,
    int? tutorAssignmentId,
    bool autoRenew = false,
  }) async {
    final res = await _api.dio.post('/tutor-engagements', data: {
      ..._plan(tutorUserId: tutorUserId, startDate: startDate, slots: slots, mode: mode, subject: subject, participantCount: participantCount),
      'topics': topics,
      'paymentMethod': paymentMethod,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (payerType != null) 'payerType': payerType,
      if (participantUserIds != null && participantUserIds.isNotEmpty) 'participantUserIds': participantUserIds,
      if (studyGroupId != null) 'studyGroupId': studyGroupId,
      if (tutorAssignmentId != null) 'tutorAssignmentId': tutorAssignmentId,
      'autoRenew': autoRenew,
    });
    final data = res.data as Map<String, dynamic>;
    return TutorEngagementRecord.fromJson(data['engagement'] as Map<String, dynamic>);
  }

  List<TutorEngagementRecord> _list(dynamic data) =>
      (data as List? ?? []).map((e) => TutorEngagementRecord.fromJson(e as Map<String, dynamic>)).toList();

  Future<TutorEngagementRecord> get(int id) async =>
      TutorEngagementRecord.fromJson((await _api.dio.get('/tutor-engagements/$id')).data as Map<String, dynamic>);

  Future<List<TutorEngagementRecord>> mine() async => _list((await _api.dio.get('/tutor-engagements/mine')).data);

  Future<List<TutorEngagementRecord>> tutorMine() async => _list((await _api.dio.get('/tutor-engagements/tutor/mine')).data);

  Future<List<PendingEngagement>> pending() async {
    final list = (await _api.dio.get('/tutor-engagements/tutor/pending')).data as List? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return PendingEngagement(TutorEngagementRecord.fromJson(m['engagement'] as Map<String, dynamic>),
          (m['minutesRemaining'] as num?)?.toInt() ?? 0);
    }).toList();
  }

  Future<TutorEngagementRecord> _one(Future<dynamic> call) async =>
      TutorEngagementRecord.fromJson(((await call) as dynamic).data as Map<String, dynamic>);

  Future<TutorEngagementRecord> accept(int id) => _one(_api.dio.put('/tutor-engagements/$id/accept'));
  Future<TutorEngagementRecord> decline(int id, {String? reason}) =>
      _one(_api.dio.put('/tutor-engagements/$id/decline', data: {'reason': reason}));
  Future<TutorEngagementRecord> cancel(int id, {String? reason}) =>
      _one(_api.dio.post('/tutor-engagements/$id/cancel', data: {'reason': reason}));
  Future<TutorEngagementRecord> setAutoRenew(int id, bool enabled) =>
      _one(_api.dio.put('/tutor-engagements/$id/auto-renew', data: {'enabled': enabled}));

  Future<TutorEngagementRecord> renew(int id, {required String paymentMethod, String? phone}) async {
    final res = await _api.dio.post('/tutor-engagements/$id/renew', data: {
      'paymentMethod': paymentMethod,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return TutorEngagementRecord.fromJson((res.data as Map<String, dynamic>)['engagement'] as Map<String, dynamic>);
  }

  /// Message lisible d'une erreur serveur (un 409 de conflit liste déjà les séances indisponibles).
  static String? errorMessage(Object e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    } catch (_) {}
    return null;
  }
}
