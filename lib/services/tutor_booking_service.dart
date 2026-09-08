import 'api_client.dart';

/// Réservation d'une séance de répétition (Module 1 — professeur_complete.md).
/// Mirroir du flow web (bookings + paiement Mobile Money via NotchPay).

class TutorAvailabilityOccurrence {
  final DateTime date;
  final String startTime; // "HH:mm"
  final String endTime;
  final bool isBookable;

  const TutorAvailabilityOccurrence({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBookable,
  });

  factory TutorAvailabilityOccurrence.fromJson(Map<String, dynamic> j) => TutorAvailabilityOccurrence(
        date: DateTime.parse(j['date'] as String),
        startTime: j['startTime'] as String? ?? '08:00',
        endTime: j['endTime'] as String? ?? '09:00',
        isBookable: j['isBookable'] as bool? ?? false,
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

  factory TutorBookingRecord.fromJson(Map<String, dynamic> j) => TutorBookingRecord(
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
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
        completedAt: j['completedAt'] != null ? DateTime.tryParse(j['completedAt'] as String) : null,
        escrowReleasedAt: j['escrowReleasedAt'] != null ? DateTime.tryParse(j['escrowReleasedAt'] as String) : null,
        disputedAt: j['disputedAt'] != null ? DateTime.tryParse(j['disputedAt'] as String) : null,
        disputeReason: j['disputeReason'] as String?,
        canMarkCompleted: j['canMarkCompleted'] as bool? ?? false,
        canDispute: j['canDispute'] as bool? ?? false,
      );
}

/// Réservation en attente de décision du répétiteur, avec le temps restant
/// avant expiration automatique (côté serveur).
class TutorPendingBooking {
  final TutorBookingRecord booking;
  final int minutesRemaining;
  const TutorPendingBooking({required this.booking, required this.minutesRemaining});

  factory TutorPendingBooking.fromJson(Map<String, dynamic> j) => TutorPendingBooking(
        booking: TutorBookingRecord.fromJson(j['booking'] as Map<String, dynamic>),
        minutesRemaining: j['minutesRemaining'] as int? ?? 0,
      );
}

class TutorBookingCreatedResult {
  final TutorBookingRecord booking;
  final String? notchpayAuthorizationUrl;
  const TutorBookingCreatedResult({required this.booking, this.notchpayAuthorizationUrl});

  factory TutorBookingCreatedResult.fromJson(Map<String, dynamic> j) => TutorBookingCreatedResult(
        booking: TutorBookingRecord.fromJson(j['booking'] as Map<String, dynamic>),
        notchpayAuthorizationUrl: j['notchpayAuthorizationUrl'] as String?,
      );
}

class TutorBookingService {
  TutorBookingService._();
  static final TutorBookingService instance = TutorBookingService._();
  final _api = ApiClient.instance;

  /// Calendrier des créneaux d'un répétiteur pour la semaine contenant [anyDateInWeek]
  /// (le backend recale sur le lundi).
  Future<List<TutorAvailabilityOccurrence>> getCalendar(int tutorUserId, DateTime anyDateInWeek) async {
    final weekStart =
        '${anyDateInWeek.year.toString().padLeft(4, '0')}-${anyDateInWeek.month.toString().padLeft(2, '0')}-${anyDateInWeek.day.toString().padLeft(2, '0')}';
    final res = await _api.dio.get('/tutor-bookings/tutor/$tutorUserId/calendar',
        queryParameters: {'weekStart': weekStart});
    final list = res.data as List? ?? [];
    return list.map((e) => TutorAvailabilityOccurrence.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Calendrier ~14 jours : semaine courante + semaine suivante.
  Future<List<TutorAvailabilityOccurrence>> getTwoWeekCalendar(int tutorUserId) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final results = await Future.wait([
      getCalendar(tutorUserId, now),
      getCalendar(tutorUserId, nextWeek),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<TutorBookingCreatedResult> createBooking({
    required int tutorUserId,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    required String mode,
    required String phone,
  }) async {
    final dateStr =
        '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';
    final res = await _api.dio.post('/tutor-bookings', data: {
      'tutorUserId': tutorUserId,
      'sessionDate': dateStr,
      'startTime': startTime,
      'endTime': endTime,
      'mode': mode,
      'phone': phone,
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
    return list.map((e) => TutorBookingRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TutorBookingRecord> cancel(int id, {String? reason}) async {
    final res = await _api.dio.post('/tutor-bookings/$id/cancel', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Demandes en attente de décision du répétiteur connecté, avec compte à
  /// rebours avant expiration.
  Future<List<TutorPendingBooking>> getPending() async {
    final res = await _api.dio.get('/tutor-bookings/tutor/pending');
    final list = res.data as List? ?? [];
    return list.map((e) => TutorPendingBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Le répétiteur accepte la demande.
  Future<TutorBookingRecord> confirm(int id) async {
    final res = await _api.dio.put('/tutor-bookings/$id/confirm');
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Le répétiteur refuse la demande (remboursement simulé côté serveur).
  Future<TutorBookingRecord> decline(int id, {String? reason}) async {
    final res = await _api.dio.put('/tutor-bookings/$id/decline', data: {'reason': reason});
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
    final res = await _api.dio.put('/tutor-bookings/$id/dispute', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }
}
