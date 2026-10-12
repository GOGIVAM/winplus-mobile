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

  // Lot 9.3 : prix de groupe (1 élève = séance individuelle).
  final int participantCount;
  final num soloTotalXaf;
  final String? groupPricingMethod; // per_student | flat
  final int groupDiscountPercent;
  final int? groupFlatPercent;
  final num perStudentXaf;

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
    this.participantCount = 1,
    this.soloTotalXaf = 0,
    this.groupPricingMethod,
    this.groupDiscountPercent = 0,
    this.groupFlatPercent,
    this.perStudentXaf = 0,
  });

  bool get isGroup => participantCount > 1;

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
        participantCount: (j['participantCount'] as num?)?.toInt() ?? 1,
        soloTotalXaf: (j['soloTotalXaf'] ?? 0) as num,
        groupPricingMethod: j['groupPricingMethod'] as String?,
        groupDiscountPercent: (j['groupDiscountPercent'] as num?)?.toInt() ?? 0,
        groupFlatPercent: (j['groupFlatPercent'] as num?)?.toInt(),
        perStudentXaf: (j['perStudentXaf'] ?? 0) as num,
      );
}

/// Élève participant d'une séance ou bénéficiaire d'une attribution (lot 9.3).
class TutorBookingParticipant {
  final int userId;
  final String? name;
  final String? avatarUrl;
  final String? groupName;
  const TutorBookingParticipant({required this.userId, this.name, this.avatarUrl, this.groupName});

  String get label => (name != null && name!.isNotEmpty) ? name! : 'Élève #$userId';

  factory TutorBookingParticipant.fromJson(Map<String, dynamic> j) => TutorBookingParticipant(
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        groupName: j['groupName'] as String?,
      );
}

/// Libellés des types de payeur (17.4).
const Map<String, String> kPayerTypeLabels = {
  'student': 'Élève',
  'parent': 'Parent',
  'institution': 'Institution',
  'study_group': "Groupe d'étude",
};

/// Attribution d'un tuteur par un parent ou une institution (lot 9.3).
class TutorAssignment {
  final int id;
  final int tutorUserId;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final String? assignedByName;
  final String assignerType; // parent | institution
  final String? institutionName;
  final String? groupName;
  final String? subject;
  final String? note;
  final String status; // pending | active | declined | ended
  final String? responseNote;
  final List<TutorBookingParticipant> beneficiaries;

  const TutorAssignment({
    required this.id,
    required this.tutorUserId,
    this.tutorName,
    this.tutorAvatarUrl,
    this.assignedByName,
    required this.assignerType,
    this.institutionName,
    this.groupName,
    this.subject,
    this.note,
    required this.status,
    this.responseNote,
    this.beneficiaries = const [],
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  String get statusLabel => switch (status) {
        'pending' => 'En attente du tuteur',
        'active' => 'Active',
        'declined' => 'Refusée',
        'ended' => 'Terminée',
        _ => status,
      };

  String get assignerLabel => assignerType == 'institution'
      ? (institutionName ?? 'Institution')
      : (assignedByName ?? 'Parent');

  factory TutorAssignment.fromJson(Map<String, dynamic> j) => TutorAssignment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tutorUserId: (j['tutorUserId'] as num?)?.toInt() ?? 0,
        tutorName: j['tutorName'] as String?,
        tutorAvatarUrl: j['tutorAvatarUrl'] as String?,
        assignedByName: j['assignedByName'] as String?,
        assignerType: j['assignerType'] as String? ?? 'parent',
        institutionName: j['institutionName'] as String?,
        groupName: j['groupName'] as String?,
        subject: j['subject'] as String?,
        note: j['note'] as String?,
        status: j['status'] as String? ?? 'pending',
        responseNote: j['responseNote'] as String?,
        beneficiaries: (j['beneficiaries'] as List? ?? [])
            .map((e) => TutorBookingParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TutorStudyGroupOption {
  final int id;
  final String name;
  final List<TutorBookingParticipant> members;
  const TutorStudyGroupOption({required this.id, required this.name, this.members = const []});
}

/// Ce que le compte peut réserver pour autrui (lot 9.3) ; revérifié par le serveur.
class TutorBookingContext {
  final String role;
  final List<String> allowedPayerTypes;
  final List<TutorBookingParticipant> children;
  final String? institutionName;
  final List<TutorBookingParticipant> institutionStudents;
  /// Suivi 17.14 : élèves rattachés qui n'ont pas encore confirmé (ou ont
  /// refusé) leur rattachement ; non réservables par l'institution.
  final int institutionPendingConfirmationCount;
  final List<TutorStudyGroupOption> studyGroups;
  final List<TutorAssignment> activeAssignments;

  const TutorBookingContext({
    this.role = '',
    this.allowedPayerTypes = const [],
    this.children = const [],
    this.institutionName,
    this.institutionStudents = const [],
    this.institutionPendingConfirmationCount = 0,
    this.studyGroups = const [],
    this.activeAssignments = const [],
  });

  bool get isParent => allowedPayerTypes.contains('parent');
  bool get isInstitution => allowedPayerTypes.contains('institution');

  factory TutorBookingContext.fromJson(Map<String, dynamic> j) {
    List<TutorBookingParticipant> people(dynamic l) => (l as List? ?? [])
        .map((e) => TutorBookingParticipant.fromJson(e as Map<String, dynamic>))
        .toList();
    return TutorBookingContext(
      role: j['role'] as String? ?? '',
      allowedPayerTypes: (j['allowedPayerTypes'] as List? ?? []).map((e) => e.toString()).toList(),
      children: people(j['children']),
      institutionName: j['institutionName'] as String?,
      institutionStudents: people(j['institutionStudents']),
      institutionPendingConfirmationCount:
          (j['institutionPendingConfirmationCount'] as num?)?.toInt() ?? 0,
      studyGroups: (j['studyGroups'] as List? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return TutorStudyGroupOption(
          id: (m['id'] as num?)?.toInt() ?? 0,
          name: m['name'] as String? ?? '',
          members: people(m['members']),
        );
      }).toList(),
      activeAssignments: (j['activeAssignments'] as List? ?? [])
          .map((e) => TutorAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

  // Lot 9.2 : contestation 24 h, moyen de paiement, remboursement automatique.
  final DateTime? disputeDeadline;
  final int disputeWindowHours;
  final String? paymentMethod; // mobile_money | wallet
  final DateTime? refundedAt;
  final String? refundCause;
  final int? refundPercent;
  final num? refundAmountXaf;
  final num? refundFeeXaf;
  final String? refundFeeBorneBy; // none | payer | tutor | platform
  final num? tutorFeeChargedXaf;

  // Lot 9.3 : payeur, participants et objet.
  final String payerType; // student | parent | institution | study_group
  final String? payerName;
  final String? studyGroupName;
  final int participantCount;
  final List<TutorBookingParticipant> participants;
  final int? tutorAssignmentId;
  final bool? viewerIsPayer;
  final bool? viewerIsParticipant;

  /// Lot 9.5 (17.12, 17.16) : noter (participants et payeur, une fois par
  /// séance et par personne) et signaler le tuteur, pour le compte connecté.
  /// [canReview] null = ancien serveur (règle d'avant : participant d'une séance effectuée).
  final bool? canReview;
  final int? myReviewRating;
  final bool canReport;
  final bool hasReported;
  /// Lot 9.4 : engagement mensuel d'origine (séance générée), sinon null.
  final int? tutorEngagementId;

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
    this.disputeDeadline,
    this.disputeWindowHours = 24,
    this.paymentMethod,
    this.refundedAt,
    this.refundCause,
    this.refundPercent,
    this.refundAmountXaf,
    this.refundFeeXaf,
    this.refundFeeBorneBy,
    this.tutorFeeChargedXaf,
    this.payerType = 'student',
    this.payerName,
    this.studyGroupName,
    this.participantCount = 1,
    this.participants = const [],
    this.tutorAssignmentId,
    this.viewerIsPayer,
    this.viewerIsParticipant,
    this.canReview,
    this.myReviewRating,
    this.canReport = false,
    this.hasReported = false,
    this.tutorEngagementId,
  });

  /// Lot 9.3 : seul le côté payeur annule (un élève dont la séance a été
  /// payée par son parent demande l'annulation au parent).
  bool get canCancelAsPayer => viewerIsPayer != false;

  /// Une phrase « pour qui / payée par qui », null pour un élève qui paie seul.
  String? get partiesSummary {
    if (payerType == 'student') return null;
    final names = participants.map((p) => p.label).toList();
    final payer = payerName ?? kPayerTypeLabels[payerType] ?? payerType;
    if (viewerIsParticipant == true && viewerIsPayer != true) {
      return 'Réservée pour toi par $payer'
          '${studyGroupName != null ? ' (groupe $studyGroupName)' : ''}'
          '${names.length > 1 ? ' · ${names.length} élèves' : ''}.';
    }
    final payerText = payerType == 'study_group' ? '$payer (groupe ${studyGroupName ?? ''})' : payer;
    return 'Pour : ${names.join(', ')} · payée par $payerText.';
  }

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
  bool get paidByWallet => paymentMethod == 'wallet';

  /// Remboursement décidé par le serveur et crédité au portefeuille (lot 9.2),
  /// en une phrase ; null si aucun.
  String? get refundSummary {
    if (refundedAt == null) return null;
    final amount = refundAmountXaf ?? 0;
    final fee = refundFeeXaf ?? 0;
    String xaf(num n) => _fmtXaf(n);
    if (amount <= 0) {
      return refundPercent == 0
          ? 'Aucun remboursement : annulation trop tardive selon la politique du tuteur.'
          : 'Aucun remboursement : les frais Mobile Money (${xaf(fee)} XAF) dépassent la part remboursable.';
    }
    final feeText = refundFeeBorneBy == 'payer' && fee > 0
        ? 'frais Mobile Money de ${xaf(fee)} XAF déduits'
        : null;
    final partial = refundCause == 'payer_cancelled' && (refundPercent ?? 100) < 100;
    final detail = partial
        ? ' ($refundPercent % selon la politique du tuteur${feeText != null ? ', $feeText' : ''})'
        : feeText != null
            ? ' ($feeText)'
            : ' (remboursement intégral)';
    if (viewerIsPayer == false) {
      return '${xaf(amount)} XAF remboursés à ${payerName ?? 'celui qui a payé'}$detail.';
    }
    final where = payerType == 'institution' ? "le portefeuille de l'institution" : 'ton portefeuille WinPlus';
    return '${xaf(amount)} XAF remboursés sur $where$detail.';
  }

  static String _fmtXaf(num n) {
    final s = n.round().abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

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
        disputeDeadline: j['disputeDeadline'] != null
            ? DateTime.tryParse(j['disputeDeadline'] as String)
            : null,
        disputeWindowHours: (j['disputeWindowHours'] as num?)?.toInt() ?? 24,
        paymentMethod: j['paymentMethod'] as String?,
        refundedAt: j['refundedAt'] != null
            ? DateTime.tryParse(j['refundedAt'] as String)
            : null,
        refundCause: j['refundCause'] as String?,
        refundPercent: (j['refundPercent'] as num?)?.toInt(),
        refundAmountXaf: j['refundAmountXaf'] as num?,
        refundFeeXaf: j['refundFeeXaf'] as num?,
        refundFeeBorneBy: j['refundFeeBorneBy'] as String?,
        tutorFeeChargedXaf: j['tutorFeeChargedXaf'] as num?,
        payerType: j['payerType'] as String? ?? 'student',
        payerName: j['payerName'] as String?,
        studyGroupName: j['studyGroupName'] as String?,
        participantCount: (j['participantCount'] as num?)?.toInt() ?? 1,
        participants: (j['participants'] as List? ?? [])
            .map((e) => TutorBookingParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
        tutorAssignmentId: (j['tutorAssignmentId'] as num?)?.toInt(),
        viewerIsPayer: j['viewerIsPayer'] as bool?,
        viewerIsParticipant: j['viewerIsParticipant'] as bool?,
        canReview: j['canReview'] as bool?,
        myReviewRating: (j['myReviewRating'] as num?)?.toInt(),
        canReport: j['canReport'] as bool? ?? false,
        hasReported: j['hasReported'] as bool? ?? false,
        tutorEngagementId: (j['tutorEngagementId'] as num?)?.toInt(),
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

/// Politique de tutorat publique (lot 9.2, 17.10) : texte, bornes des
/// réglages des tuteurs, délai de contestation et taux de frais servis par
/// GET /api/tutor-policy, la même source que le web.
class TutorPolicySection {
  final String id;
  final String title;
  final List<String> paragraphs;
  const TutorPolicySection(
      {required this.id, required this.title, this.paragraphs = const []});

  factory TutorPolicySection.fromJson(Map<String, dynamic> j) =>
      TutorPolicySection(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        paragraphs: (j['paragraphs'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class TutorPolicy {
  final String version;
  final int disputeWindowHours;
  final num notchPayFeePercent;
  final Map<String, int> bounds;
  final List<TutorPolicySection> sections;
  const TutorPolicy({
    required this.version,
    required this.disputeWindowHours,
    required this.notchPayFeePercent,
    this.bounds = const {},
    this.sections = const [],
  });

  factory TutorPolicy.fromJson(Map<String, dynamic> j) => TutorPolicy(
        version: j['version'] as String? ?? '',
        disputeWindowHours: (j['disputeWindowHours'] as num?)?.toInt() ?? 24,
        notchPayFeePercent: (j['notchPayFeePercent'] as num?) ?? 0,
        bounds: ((j['bounds'] as Map?) ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
        sections: (j['sections'] as List? ?? [])
            .map((e) => TutorPolicySection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Taux de frais affichable (« 3 », « 2,5 »).
  String get feePercentLabel {
    final v = notchPayFeePercent;
    return v == v.roundToDouble()
        ? v.round().toString()
        : v.toString().replaceAll('.', ',');
  }
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

  Future<TutorPolicy>? _policy;

  /// Politique publique (endpoint anonyme), gardée en mémoire pour la
  /// session ; un échec n'est pas mis en cache.
  Future<TutorPolicy> getPolicy() {
    final cached = _policy;
    if (cached != null) return cached;
    final future = _api.dio.get('/tutor-policy').then((res) {
      final data = res.data;
      final map = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return TutorPolicy.fromJson(map);
    });
    _policy = future;
    future.catchError((Object _) {
      _policy = null;
      return const TutorPolicy(version: '', disputeWindowHours: 24, notchPayFeePercent: 0);
    });
    return future;
  }

  /// Solde disponible du portefeuille (GET /wallet/me, lot 2), pour le choix
  /// du moyen de paiement (lot 9.2). Lecture seule, le serveur refait le
  /// contrôle au débit. Null si le solde ne peut pas être lu.
  Future<num?> getWalletAvailableXaf() async {
    try {
      final res = await _api.dio.get('/wallet/me');
      final data = res.data;
      final map = data is Map && data['data'] is Map ? data['data'] as Map : data;
      return map is Map ? map['availableXaf'] as num? : null;
    } catch (_) {
      return null;
    }
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
    int participantCount = 1,
  }) async {
    final res = await _api.dio.post('/tutor-bookings/quote', data: {
      'tutorUserId': tutorUserId,
      'sessionDate': _date(sessionDate),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'mode': mode,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      'participantCount': participantCount,
    });
    return TutorPriceQuote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorBookingCreatedResult> createBooking({
    required int tutorUserId,
    required DateTime sessionDate,
    required String startTime,
    required int durationMinutes,
    required String mode,
    String? phone,
    String paymentMethod = 'mobile_money',
    String? subject,
    List<String> topics = const [],
    String? payerType,
    List<int>? participantUserIds,
    int? studyGroupId,
    int? tutorAssignmentId,
  }) async {
    final res = await _api.dio.post('/tutor-bookings', data: {
      'tutorUserId': tutorUserId,
      'sessionDate': _date(sessionDate),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'mode': mode,
      'paymentMethod': paymentMethod,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      'topics': topics,
      // Lot 9.3 : réservation pour autrui (chaque lien revérifié par le serveur).
      if (payerType != null) 'payerType': payerType,
      if (participantUserIds != null && participantUserIds.isNotEmpty) 'participantUserIds': participantUserIds,
      if (studyGroupId != null) 'studyGroupId': studyGroupId,
      if (tutorAssignmentId != null) 'tutorAssignmentId': tutorAssignmentId,
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

  /// Séances reçues par le répétiteur connecté (GET /tutor-bookings/tutor/mine).
  Future<List<TutorBookingRecord>> getTutorMine() async {
    final res = await _api.dio.get('/tutor-bookings/tutor/mine');
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

  /// Le répétiteur refuse la demande : l'élève est remboursé intégralement sur
  /// son portefeuille, frais Mobile Money retenus sur le tuteur (lot 9.2).
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

  /// L'élève conteste une séance dans la fenêtre de contestation (24 h par
  /// défaut, réglée côté serveur) après qu'elle a été marquée effectuée.
  Future<TutorBookingRecord> dispute(int id, String reason) async {
    final res = await _api.dio
        .put('/tutor-bookings/$id/dispute', data: {'reason': reason});
    return TutorBookingRecord.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Lot 9.3 : réservation pour autrui et attribution de tuteur ──

  List<TutorAssignment> _assignments(dynamic data) => (data as List? ?? [])
      .map((e) => TutorAssignment.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<TutorBookingContext> getBookingContext() async {
    final res = await _api.dio.get('/tutor-assignments/booking-context');
    return TutorBookingContext.fromJson(res.data as Map<String, dynamic>);
  }

  /// Attributions créées par le parent ou par l'institution du compte.
  Future<List<TutorAssignment>> getMyAssignments() async =>
      _assignments((await _api.dio.get('/tutor-assignments/mine')).data);

  /// Attributions actives dont l'élève connecté est bénéficiaire.
  Future<List<TutorAssignment>> getAssignmentsForMe() async =>
      _assignments((await _api.dio.get('/tutor-assignments/for-me')).data);

  Future<List<TutorAssignment>> getTutorAssignments() async =>
      _assignments((await _api.dio.get('/tutor-assignments/tutor')).data);

  Future<TutorAssignment> createAssignment({
    required int tutorUserId,
    List<int> studentUserIds = const [],
    String? groupName,
    String? subject,
    String? note,
  }) async {
    final res = await _api.dio.post('/tutor-assignments', data: {
      'tutorUserId': tutorUserId,
      'studentUserIds': studentUserIds,
      if (groupName != null && groupName.isNotEmpty) 'groupName': groupName,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return TutorAssignment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorAssignment> respondAssignment(int id, {required String action, String? note}) async {
    // action : accept | decline | end
    final res = await _api.dio.put('/tutor-assignments/$id/$action', data: {'note': note});
    return TutorAssignment.fromJson(res.data as Map<String, dynamic>);
  }
}
