import 'api_client.dart';

/// Réservation d'une séance de répétition (Module 1  professeur_complete.md).
/// Mirroir du flow web (bookings + paiement Mobile Money via NotchPay).

/// "HH:mm" + minutes → "HH:mm".
String addMinutesToHhmm(String hhmm, int minutes) {
  final parts = hhmm.split(':');
  final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
  final h = (total ~/ 60) % 24;
  final m = total % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// "30 min", "1 h", "1 h 30".
String formatDurationMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// Point de départ réservable (lot 9.1) : depuis [startTime], l'élève choisit
/// une durée multiple de 30 min parmi [availableDurationsMinutes], jusqu'à la
/// fin de la plage libre en continu. Le serveur n'envoie pas d'heure de fin :
/// elle dépend de la durée choisie.
class TutorAvailabilityOccurrence {
  final DateTime date;
  final String startTime; // "HH:mm"
  final List<int> availableDurationsMinutes;
  final int maxDurationMinutes;
  final bool isBookable;

  const TutorAvailabilityOccurrence({
    required this.date,
    required this.startTime,
    this.availableDurationsMinutes = const [],
    this.maxDurationMinutes = 0,
    required this.isBookable,
  });

  factory TutorAvailabilityOccurrence.fromJson(Map<String, dynamic> j) {
    final durations = (j['availableDurationsMinutes'] as List? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    return TutorAvailabilityOccurrence(
      date: DateTime.parse(j['date'] as String),
      startTime: j['startTime'] as String? ?? '08:00',
      availableDurationsMinutes: durations,
      maxDurationMinutes: (j['maxDurationMinutes'] as num?)?.toInt() ??
          (durations.isEmpty ? 0 : durations.last),
      isBookable: j['isBookable'] as bool? ?? false,
    );
  }
}

class TutorPriceQuoteSegment {
  final String startTime;
  final String endTime;
  final int minutes;
  final int modifierPercent;
  final List<String> modifierLabels;
  final num effectiveHourlyRateXaf;
  final num amountXaf;

  const TutorPriceQuoteSegment({
    required this.startTime,
    required this.endTime,
    required this.minutes,
    required this.modifierPercent,
    required this.modifierLabels,
    required this.effectiveHourlyRateXaf,
    required this.amountXaf,
  });

  factory TutorPriceQuoteSegment.fromJson(Map<String, dynamic> j) =>
      TutorPriceQuoteSegment(
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
        modifierPercent: (j['modifierPercent'] as num?)?.toInt() ?? 0,
        modifierLabels: (j['modifierLabels'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        effectiveHourlyRateXaf: (j['effectiveHourlyRateXaf'] ?? 0) as num,
        amountXaf: (j['amountXaf'] ?? 0) as num,
      );
}

/// Devis calculé par le serveur (lot 9.1) : l'application n'affiche jamais un
/// prix calculé localement.
class TutorPriceQuote {
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String modeCategory; // online | in_person
  final String? subject;
  final num baseHourlyRateXaf;
  final List<TutorPriceQuoteSegment> segments;
  final num subtotalXaf;
  final int durationDiscountPercent;
  final num durationDiscountXaf;
  final num totalXaf;
  final bool? isAvailable;
  final String? unavailableReason;

  const TutorPriceQuote({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.modeCategory,
    this.subject,
    required this.baseHourlyRateXaf,
    required this.segments,
    required this.subtotalXaf,
    required this.durationDiscountPercent,
    required this.durationDiscountXaf,
    required this.totalXaf,
    this.isAvailable,
    this.unavailableReason,
  });

  factory TutorPriceQuote.fromJson(Map<String, dynamic> j) => TutorPriceQuote(
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        modeCategory: j['modeCategory'] as String? ?? 'online',
        subject: j['subject'] as String?,
        baseHourlyRateXaf: (j['baseHourlyRateXaf'] ?? 0) as num,
        segments: (j['segments'] as List? ?? [])
            .map((e) =>
                TutorPriceQuoteSegment.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotalXaf: (j['subtotalXaf'] ?? 0) as num,
        durationDiscountPercent:
            (j['durationDiscountPercent'] as num?)?.toInt() ?? 0,
        durationDiscountXaf: (j['durationDiscountXaf'] ?? 0) as num,
        totalXaf: (j['totalXaf'] ?? 0) as num,
        isAvailable: j['isAvailable'] as bool?,
        unavailableReason: j['unavailableReason'] as String?,
      );
}

class TutorBookingRecord {
  final int id;
  final int tutorUserId;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final int studentUserId;
  final String? studentName;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final String mode; // online | student_home | tutor_home | neutral_place
  final num priceXaf;
  final String status; // pending_payment | confirmed | cancelled | completed...
  final String paymentStatus; // pending | success | failed
  final String? notchpayReference;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? escrowReleasedAt;
  final DateTime? disputedAt;
  final String? disputeReason;
  final bool canMarkCompleted;
  final bool canDispute;
  final String? subject;
  final List<String> topics;
  final int durationMinutes;
  final TutorPriceQuote? priceBreakdown;

  const TutorBookingRecord({
    required this.id,
    required this.tutorUserId,
    this.tutorName,
    this.tutorAvatarUrl,
    required this.studentUserId,
    this.studentName,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.priceXaf,
    required this.status,
    required this.paymentStatus,
    this.notchpayReference,
    this.cancellationReason,
    this.createdAt,
    this.completedAt,
    this.escrowReleasedAt,
    this.disputedAt,
    this.disputeReason,
    this.canMarkCompleted = false,
    this.canDispute = false,
    this.subject,
    this.topics = const [],
    this.durationMinutes = 0,
    this.priceBreakdown,
  });

  /// Statut "actif" : le paiement a été validé (en attente du répétiteur,
  /// ou déjà confirmé). Utilisé pour distinguer du paiement en cours.
  bool get isConfirmed => status == 'confirmed';
  bool get isPendingTutorApproval => status == 'pending_tutor_approval';
  bool get isCompleted => status == 'completed';
  bool get isDisputed => status == 'disputed';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending_payment';

  factory TutorBookingRecord.fromJson(Map<String, dynamic> j) =>
      TutorBookingRecord(
        id: j['id'] as int? ?? 0,
        tutorUserId: j['tutorUserId'] as int? ?? 0,
        tutorName: j['tutorName'] as String?,
        tutorAvatarUrl: j['tutorAvatarUrl'] as String?,
        studentUserId: j['studentUserId'] as int? ?? 0,
        studentName: j['studentName'] as String?,
        sessionDate: DateTime.parse(j['sessionDate'] as String),
        startTime: j['startTime'] as String? ?? '08:00',
        endTime: j['endTime'] as String? ?? '09:00',
        mode: j['mode'] as String? ?? 'online',
        priceXaf: (j['priceXaf'] ?? 0) as num,
        status: j['status'] as String? ?? 'pending_payment',
        paymentStatus: j['paymentStatus'] as String? ?? 'pending',
        notchpayReference: j['notchpayReference'] as String?,
        cancellationReason: j['cancellationReason'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
        escrowReleasedAt: j['escrowReleasedAt'] != null
            ? DateTime.tryParse(j['escrowReleasedAt'] as String)
            : null,
        disputedAt: j['disputedAt'] != null
            ? DateTime.tryParse(j['disputedAt'] as String)
            : null,
        disputeReason: j['disputeReason'] as String?,
        canMarkCompleted: j['canMarkCompleted'] as bool? ?? false,
        canDispute: j['canDispute'] as bool? ?? false,
        subject: j['subject'] as String?,
        topics:
            (j['topics'] as List? ?? []).map((e) => e.toString()).toList(),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        priceBreakdown: j['priceBreakdown'] is Map<String, dynamic>
            ? TutorPriceQuote.fromJson(
                j['priceBreakdown'] as Map<String, dynamic>)
            : null,
      );
}

/// Réservation en attente de décision du répétiteur, avec le temps restant
/// avant expiration automatique (côté serveur).
class TutorPendingBooking {
  final TutorBookingRecord booking;
  final int minutesRemaining;
  const TutorPendingBooking(
      {required this.booking, required this.minutesRemaining});

  factory TutorPendingBooking.fromJson(Map<String, dynamic> j) =>
      TutorPendingBooking(
        booking:
            TutorBookingRecord.fromJson(j['booking'] as Map<String, dynamic>),
        minutesRemaining: j['minutesRemaining'] as int? ?? 0,
      );
}

class TutorBookingCreatedResult {
  final TutorBookingRecord booking;
  final String? notchpayAuthorizationUrl;
  const TutorBookingCreatedResult(
      {required this.booking, this.notchpayAuthorizationUrl});

  factory TutorBookingCreatedResult.fromJson(Map<String, dynamic> j) =>
      TutorBookingCreatedResult(
        booking:
            TutorBookingRecord.fromJson(j['booking'] as Map<String, dynamic>),
        notchpayAuthorizationUrl: j['notchpayAuthorizationUrl'] as String?,
      );
}

class TutorBookingService {
  TutorBookingService._();
  static final TutorBookingService instance = TutorBookingService._();
  final _api = ApiClient.instance;

  /// Calendrier des créneaux d'un répétiteur pour la semaine contenant [anyDateInWeek]
  /// (le backend recale sur le lundi).
  Future<List<TutorAvailabilityOccurrence>> getCalendar(
      int tutorUserId, DateTime anyDateInWeek) async {
    final weekStart =
        '${anyDateInWeek.year.toString().padLeft(4, '0')}-${anyDateInWeek.month.toString().padLeft(2, '0')}-${anyDateInWeek.day.toString().padLeft(2, '0')}';
    final res = await _api.dio.get(
        '/tutor-bookings/tutor/$tutorUserId/calendar',
        queryParameters: {'weekStart': weekStart});
    final list = res.data as List? ?? [];
    return list
        .map((e) =>
            TutorAvailabilityOccurrence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Calendrier ~14 jours : semaine courante + semaine suivante.
  Future<List<TutorAvailabilityOccurrence>> getTwoWeekCalendar(
      int tutorUserId) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final results = await Future.wait([
      getCalendar(tutorUserId, now),
      getCalendar(tutorUserId, nextWeek),
    ]);
    return [...results[0], ...results[1]];
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Devis serveur avant paiement (lot 9.1) ; le prix est recalculé de toute
  /// façon à la création de la réservation.
  Future<TutorPriceQuote> quote({
    required int tutorUserId,
    required DateTime sessionDate,
    required String startTime,
    required int durationMinutes,
    required String mode,
    String? subject,
  }) async {
    final res = await _api.dio.post('/tutor-bookings/quote', data: {
      'tutorUserId': tutorUserId,
      'sessionDate': _date(sessionDate),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'mode': mode,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
    });
    return TutorPriceQuote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorBookingCreatedResult> createBooking({
    required int tutorUserId,
    required DateTime sessionDate,
    required String startTime,
    required int durationMinutes,
    required String mode,
    required String phone,
    String? subject,
    List<String> topics = const [],
  }) async {
    final res = await _api.dio.post('/tutor-bookings', data: {
      'tutorUserId': tutorUserId,
      'sessionDate': _date(sessionDate),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'mode': mode,
      'phone': phone,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      'topics': topics,
    });
    return TutorBookingCreatedResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorBookingRecord> getBooking(int id) async {
    final res = await _api.dio.get('/tutor-bookings/$id');
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TutorBookingRecord>> getMine() async {
    final res = await _api.dio.get('/tutor-bookings/mine');
    final list = res.data as List? ?? [];
    return list
        .map((e) => TutorBookingRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TutorBookingRecord> cancel(int id, {String? reason}) async {
    final res = await _api.dio
        .post('/tutor-bookings/$id/cancel', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Demandes en attente de décision du répétiteur connecté, avec compte à
  /// rebours avant expiration.
  Future<List<TutorPendingBooking>> getPending() async {
    final res = await _api.dio.get('/tutor-bookings/tutor/pending');
    final list = res.data as List? ?? [];
    return list
        .map((e) => TutorPendingBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Le répétiteur accepte la demande.
  Future<TutorBookingRecord> confirm(int id) async {
    final res = await _api.dio.put('/tutor-bookings/$id/confirm');
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Le répétiteur refuse la demande (remboursement simulé côté serveur).
  Future<TutorBookingRecord> decline(int id, {String? reason}) async {
    final res = await _api.dio
        .put('/tutor-bookings/$id/decline', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Le répétiteur marque la séance comme effectuée (une fois l'heure de fin
  /// passée).
  Future<TutorBookingRecord> complete(int id) async {
    final res = await _api.dio.put('/tutor-bookings/$id/complete');
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// L'élève conteste une séance dans la fenêtre de 2h après la fin.
  Future<TutorBookingRecord> dispute(int id, String reason) async {
    final res = await _api.dio
        .put('/tutor-bookings/$id/dispute', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }
}
