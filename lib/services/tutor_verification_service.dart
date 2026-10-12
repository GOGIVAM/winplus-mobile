import 'package:dio/dio.dart';

import 'api_client.dart';

/// Lot 9.5 (suivi 17.11, 17.12, 17.16) : vérification des tuteurs pour le
/// présentiel (pièce d'identité + selfie, entretien, caution d'institution),
/// et signalements. L'écran admin n'existe que sur le web.
/// Les fichiers d'identité ne sont jamais relus par l'application : ils
/// partent dans le stockage privé et seul un admin les consulte.

String _err(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    return (data['message'] ?? data['error'] ?? fallback).toString();
  }
  return fallback;
}

DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

const Map<String, String> kVerificationRouteLabels = {
  'identity': "Pièce d'identité et selfie",
  'interview': 'Entretien',
  'institution': "Caution d'une institution",
};

const Map<String, String> kIdentityDocumentTypes = {
  'cni': "Carte nationale d'identité",
  'passport': 'Passeport',
  'residence_permit': 'Titre de séjour',
  'driving_license': 'Permis de conduire',
  'other': 'Autre pièce officielle',
};

const Map<String, String> kInterviewStatusLabels = {
  'requested': 'Demandé',
  'scheduled': 'Planifié',
  'passed': 'Réussi',
  'failed': 'Non concluant',
  'no_show': 'Absent',
  'cancelled': 'Annulé',
};

const Map<String, String> kVerificationEventLabels = {
  'identity:submitted': "Pièce d'identité déposée",
  'identity:approved': "Pièce d'identité validée",
  'identity:rejected': "Pièce d'identité refusée",
  'identity:superseded': 'Dépôt remplacé',
  'identity:files_purged': 'Fichiers supprimés (conservation limitée)',
  'interview:requested': 'Entretien demandé',
  'interview:scheduled': 'Entretien planifié',
  'interview:passed': 'Entretien réussi',
  'interview:failed': 'Entretien non concluant',
  'interview:no_show': "Absent à l'entretien",
  'interview:cancelled': 'Entretien annulé',
  'institution:endorsed': "Caution d'une institution",
  'institution:revoked': 'Caution retirée',
  'status:verified': 'Vérifié pour le présentiel',
  'status:unverified': 'Vérification retirée',
  'suspension:suspended': 'Présentiel suspendu',
  'suspension:lifted': 'Suspension levée',
};

class TutorIdentityCheckSummary {
  final int id;
  final String status; // pending | approved | rejected | superseded
  final String documentType;
  final String? rejectionReason;
  final DateTime? submittedAt;
  const TutorIdentityCheckSummary(
      {required this.id, required this.status, required this.documentType, this.rejectionReason, this.submittedAt});
  factory TutorIdentityCheckSummary.fromJson(Map<String, dynamic> j) => TutorIdentityCheckSummary(
        id: (j['id'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'pending',
        documentType: j['documentType'] as String? ?? 'cni',
        rejectionReason: j['rejectionReason'] as String?,
        submittedAt: _date(j['submittedAt']),
      );
}

class TutorInterviewSummary {
  final int id;
  final String format; // video | in_person
  final String status;
  final String? availability;
  final String? city;
  final DateTime? scheduledAt;
  final String? meetingUrl;
  final String? location;
  final String? outcomeReason;
  final DateTime? requestedAt;
  final bool hasIdentityAttached;
  const TutorInterviewSummary({
    required this.id,
    required this.format,
    required this.status,
    this.availability,
    this.city,
    this.scheduledAt,
    this.meetingUrl,
    this.location,
    this.outcomeReason,
    this.requestedAt,
    this.hasIdentityAttached = false,
  });
  bool get isOpen => status == 'requested' || status == 'scheduled';
  factory TutorInterviewSummary.fromJson(Map<String, dynamic> j) => TutorInterviewSummary(
        id: (j['id'] as num?)?.toInt() ?? 0,
        format: j['format'] as String? ?? 'video',
        status: j['status'] as String? ?? 'requested',
        availability: j['availability'] as String?,
        city: j['city'] as String?,
        scheduledAt: _date(j['scheduledAt']),
        meetingUrl: j['meetingUrl'] as String?,
        location: j['location'] as String?,
        outcomeReason: j['outcomeReason'] as String?,
        requestedAt: _date(j['requestedAt']),
        hasIdentityAttached: j['hasIdentityAttached'] as bool? ?? false,
      );
}

class TutorEndorsement {
  final int id;
  final int tutorUserId;
  final String? tutorName;
  final String? institutionName;
  final String statement;
  final String verifierName;
  final DateTime? verifiedOn;
  final String status; // active | revoked
  final bool isValid;
  final DateTime? revokedAt;
  final String? revocationReason;
  const TutorEndorsement({
    required this.id,
    required this.tutorUserId,
    this.tutorName,
    this.institutionName,
    this.statement = '',
    this.verifierName = '',
    this.verifiedOn,
    this.status = 'active',
    this.isValid = false,
    this.revokedAt,
    this.revocationReason,
  });
  factory TutorEndorsement.fromJson(Map<String, dynamic> j) => TutorEndorsement(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tutorUserId: (j['tutorUserId'] as num?)?.toInt() ?? 0,
        tutorName: j['tutorName'] as String?,
        institutionName: j['institutionName'] as String?,
        statement: j['statement'] as String? ?? '',
        verifierName: j['verifierName'] as String? ?? '',
        verifiedOn: _date(j['verifiedOn']),
        status: j['status'] as String? ?? 'active',
        isValid: j['isValid'] as bool? ?? false,
        revokedAt: _date(j['revokedAt']),
        revocationReason: j['revocationReason'] as String?,
      );
}

class TutorVerificationEvent {
  final int id;
  final String category;
  final String action;
  final String? reason;
  final DateTime? createdAt;
  const TutorVerificationEvent({required this.id, required this.category, required this.action, this.reason, this.createdAt});
  String get label => kVerificationEventLabels['$category:$action'] ?? '$category · $action';
  factory TutorVerificationEvent.fromJson(Map<String, dynamic> j) => TutorVerificationEvent(
        id: (j['id'] as num?)?.toInt() ?? 0,
        category: j['category'] as String? ?? '',
        action: j['action'] as String? ?? '',
        reason: j['reason'] as String?,
        createdAt: _date(j['createdAt']),
      );
}

class TutorVerificationStatus {
  final bool isVerified;
  final List<String> routes;
  final bool isSuspended;
  final DateTime? suspendedAt;
  final bool inPersonAllowed;
  final bool isDiplomaVerified;
  final TutorIdentityCheckSummary? latestIdentity;
  final bool hasApprovedIdentity;
  final TutorInterviewSummary? latestInterview;
  final bool hasPassedInterview;
  final List<TutorEndorsement> endorsements;
  final List<TutorVerificationEvent> history;
  final int retentionDaysAfterApproval;
  final int retentionDaysAfterRejection;

  const TutorVerificationStatus({
    this.isVerified = false,
    this.routes = const [],
    this.isSuspended = false,
    this.suspendedAt,
    this.inPersonAllowed = false,
    this.isDiplomaVerified = false,
    this.latestIdentity,
    this.hasApprovedIdentity = false,
    this.latestInterview,
    this.hasPassedInterview = false,
    this.endorsements = const [],
    this.history = const [],
    this.retentionDaysAfterApproval = 30,
    this.retentionDaysAfterRejection = 7,
  });

  factory TutorVerificationStatus.fromJson(Map<String, dynamic> j) => TutorVerificationStatus(
        isVerified: j['isVerified'] as bool? ?? false,
        routes: (j['routes'] as List? ?? []).map((e) => e.toString()).toList(),
        isSuspended: j['isSuspended'] as bool? ?? false,
        suspendedAt: _date(j['suspendedAt']),
        inPersonAllowed: j['inPersonAllowed'] as bool? ?? false,
        isDiplomaVerified: j['isDiplomaVerified'] as bool? ?? false,
        latestIdentity: j['latestIdentity'] is Map<String, dynamic>
            ? TutorIdentityCheckSummary.fromJson(j['latestIdentity'] as Map<String, dynamic>)
            : null,
        hasApprovedIdentity: j['hasApprovedIdentity'] as bool? ?? false,
        latestInterview: j['latestInterview'] is Map<String, dynamic>
            ? TutorInterviewSummary.fromJson(j['latestInterview'] as Map<String, dynamic>)
            : null,
        hasPassedInterview: j['hasPassedInterview'] as bool? ?? false,
        endorsements: (j['endorsements'] as List? ?? [])
            .map((e) => TutorEndorsement.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: (j['history'] as List? ?? [])
            .map((e) => TutorVerificationEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        retentionDaysAfterApproval: (j['identityRetentionDaysAfterApproval'] as num?)?.toInt() ?? 30,
        retentionDaysAfterRejection: (j['identityRetentionDaysAfterRejection'] as num?)?.toInt() ?? 7,
      );
}

class InstitutionTutorForEndorsement {
  final int tutorUserId;
  final String? tutorName;
  final bool hasTutorProfile;
  final bool isInPersonVerified;
  final TutorEndorsement? activeEndorsement;
  const InstitutionTutorForEndorsement(
      {required this.tutorUserId, this.tutorName, this.hasTutorProfile = false, this.isInPersonVerified = false, this.activeEndorsement});
  factory InstitutionTutorForEndorsement.fromJson(Map<String, dynamic> j) => InstitutionTutorForEndorsement(
        tutorUserId: (j['tutorUserId'] as num?)?.toInt() ?? 0,
        tutorName: j['tutorName'] as String?,
        hasTutorProfile: j['hasTutorProfile'] as bool? ?? false,
        isInPersonVerified: j['isInPersonVerified'] as bool? ?? false,
        activeEndorsement: j['activeEndorsement'] is Map<String, dynamic>
            ? TutorEndorsement.fromJson(j['activeEndorsement'] as Map<String, dynamic>)
            : null,
      );
}

/// Fichier choisi sur l'appareil (pièce ou selfie), envoyé tel quel.
class IdentityUpload {
  final List<int> bytes;
  final String fileName;
  const IdentityUpload(this.bytes, this.fileName);
  MultipartFile toMultipart() => MultipartFile.fromBytes(bytes, filename: fileName);
}

class TutorReportReason {
  final String code;
  final String label;
  const TutorReportReason(this.code, this.label);
}

const List<TutorReportReason> kFallbackReportReasons = [
  TutorReportReason('inappropriate_behavior', 'Comportement inapproprié'),
  TutorReportReason('safety_concern', 'Problème de sécurité'),
  TutorReportReason('harassment', 'Harcèlement ou propos déplacés'),
  TutorReportReason('no_show', 'Absent à la séance'),
  TutorReportReason('off_platform_payment', 'Demande de paiement hors WinPlus'),
  TutorReportReason('identity_mismatch', "Ce n'est pas la personne du profil"),
  TutorReportReason('poor_quality', 'Séance de mauvaise qualité'),
  TutorReportReason('other', 'Autre'),
];

class TutorVerificationService {
  TutorVerificationService._();
  static final TutorVerificationService instance = TutorVerificationService._();
  final _api = ApiClient.instance;

  Future<TutorVerificationStatus> getMine() async {
    try {
      final res = await _api.dio.get('/tutor-verification/me');
      return TutorVerificationStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_err(e, 'Impossible de charger ta vérification.'));
    }
  }

  Future<TutorVerificationStatus> submitIdentity({
    required String documentType,
    required IdentityUpload front,
    IdentityUpload? back,
    required IdentityUpload selfie,
    int? interviewId,
  }) async {
    try {
      final form = FormData.fromMap({
        'documentType': documentType,
        'front': front.toMultipart(),
        if (back != null) 'back': back.toMultipart(),
        'selfie': selfie.toMultipart(),
        if (interviewId != null) 'interviewId': interviewId.toString(),
      });
      final res = await _api.dio.post('/tutor-verification/me/identity', data: form);
      return TutorVerificationStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_err(e, 'Envoi impossible.'));
    }
  }

  Future<TutorVerificationStatus> requestInterview(
      {required String format, required String availability, String? city, String? message}) async {
    try {
      final res = await _api.dio.post('/tutor-verification/me/interview', data: {
        'format': format,
        'availability': availability,
        if (city != null && city.isNotEmpty) 'city': city,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      return TutorVerificationStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_err(e, 'Demande impossible.'));
    }
  }

  Future<TutorVerificationStatus> cancelInterview(int id) async {
    try {
      final res = await _api.dio.post('/tutor-verification/me/interview/$id/cancel');
      return TutorVerificationStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_err(e, 'Annulation impossible.'));
    }
  }

  // ── Institution ──

  Future<List<InstitutionTutorForEndorsement>> institutionTutors() async {
    try {
      final res = await _api.dio.get('/tutor-verification/institution/tutors');
      return (res.data as List? ?? [])
          .map((e) => InstitutionTutorForEndorsement.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_err(e, 'Impossible de charger vos répétiteurs.'));
    }
  }

  Future<void> endorse(
      {required int tutorUserId, required String statement, required String verifierName, required DateTime verifiedOn}) async {
    try {
      await _api.dio.post('/tutor-verification/institution/endorsements', data: {
        'tutorUserId': tutorUserId,
        'statement': statement,
        'verifierName': verifierName,
        'verifiedOn':
            '${verifiedOn.year.toString().padLeft(4, '0')}-${verifiedOn.month.toString().padLeft(2, '0')}-${verifiedOn.day.toString().padLeft(2, '0')}',
      });
    } on DioException catch (e) {
      throw Exception(_err(e, 'Caution impossible.'));
    }
  }

  Future<void> revokeEndorsement(int id, {String? reason}) async {
    try {
      await _api.dio.post('/tutor-verification/institution/endorsements/$id/revoke', data: {'reason': reason});
    } on DioException catch (e) {
      throw Exception(_err(e, 'Retrait impossible.'));
    }
  }

  // ── Signalements ──

  Future<List<TutorReportReason>> reportReasons() async {
    try {
      final res = await _api.dio.get('/tutor-reports/reasons');
      final list = (res.data as List? ?? [])
          .map((e) => TutorReportReason((e as Map)['code'].toString(), e['label'].toString()))
          .toList();
      return list.isEmpty ? kFallbackReportReasons : list;
    } catch (_) {
      return kFallbackReportReasons;
    }
  }

  Future<String> report({required int bookingId, required String reason, String? description}) async {
    try {
      final res = await _api.dio.post('/tutor-reports', data: {
        'tutorBookingId': bookingId,
        'reason': reason,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      final data = res.data;
      return data is Map<String, dynamic> ? (data['message'] ?? 'Signalement transmis.').toString() : 'Signalement transmis.';
    } on DioException catch (e) {
      throw Exception(_err(e, 'Signalement impossible.'));
    }
  }
}
