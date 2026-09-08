import 'api_client.dart';

/// Profil "Mode Répétiteur" (Module 1 — professeur_complete.md).
class TutorZone {
  final int? id;
  final String city;
  final String? quartier;
  const TutorZone({this.id, required this.city, this.quartier});

  factory TutorZone.fromJson(Map<String, dynamic> j) => TutorZone(
        id: j['id'] as int?,
        city: j['city'] as String? ?? '',
        quartier: j['quartier'] as String?,
      );

  Map<String, dynamic> toJson() => {'city': city, 'quartier': quartier};
}

class TutorPackage {
  final int? id;
  final String name;
  final int sessionsCount;
  final num totalPriceXaf;
  final bool isActive;
  const TutorPackage({
    this.id,
    required this.name,
    required this.sessionsCount,
    required this.totalPriceXaf,
    this.isActive = true,
  });

  factory TutorPackage.fromJson(Map<String, dynamic> j) => TutorPackage(
        id: j['id'] as int?,
        name: j['name'] as String? ?? '',
        sessionsCount: j['sessionsCount'] as int? ?? 0,
        totalPriceXaf: (j['totalPriceXaf'] ?? 0) as num,
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sessionsCount': sessionsCount,
        'totalPriceXaf': totalPriceXaf,
        'isActive': isActive,
      };
}

class TutorAvailabilitySlot {
  final int? id;
  final int dayOfWeek; // 0 = dimanche ... 6 = samedi
  final String startTime; // "HH:mm"
  final String endTime;
  final bool isActive;
  const TutorAvailabilitySlot({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory TutorAvailabilitySlot.fromJson(Map<String, dynamic> j) => TutorAvailabilitySlot(
        id: j['id'] as int?,
        dayOfWeek: j['dayOfWeek'] as int? ?? 0,
        startTime: j['startTime'] as String? ?? '08:00',
        endTime: j['endTime'] as String? ?? '09:00',
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': isActive,
      };
}

class TutorVerificationDocument {
  final int id;
  final String documentUrl;
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  const TutorVerificationDocument({
    required this.id,
    required this.documentUrl,
    required this.status,
    this.rejectionReason,
  });

  factory TutorVerificationDocument.fromJson(Map<String, dynamic> j) => TutorVerificationDocument(
        id: j['id'] as int? ?? 0,
        documentUrl: j['documentUrl'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        rejectionReason: j['rejectionReason'] as String?,
      );
}

class TutorProfile {
  final int id;
  final int userId;
  final String? fullName;
  final String? avatarUrl;
  final String? title;
  final String? tutorBio;
  final String? videoUrl;
  final String? teachingStyle;
  final num? hourlyRateXaf;
  final bool trialSessionEnabled;
  final num? trialSessionPriceXaf;
  final bool offersAtStudentHome;
  final bool offersAtTutorHome;
  final bool offersOnline;
  final bool offersNeutralPlace;
  final int noticeHours;
  final int? maxSessionsPerWeek;
  final bool isOnVacation;
  final bool isDiplomaVerified;
  final bool isActive;
  final int onboardingStep;
  final int completionScore;
  final List<String> subjects;
  final List<String> levels;
  final List<String> specialties;
  final List<TutorZone> interventionZones;
  final List<TutorPackage> packages;
  final List<TutorAvailabilitySlot> availabilitySlots;
  final TutorVerificationDocument? pendingOrLatestDocument;
  final double? averageRating;
  final int reviewCount;
  final bool isExperienced;
  final bool isHighlyResponsive;

  const TutorProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.title,
    this.tutorBio,
    this.videoUrl,
    this.teachingStyle,
    this.hourlyRateXaf,
    this.trialSessionEnabled = false,
    this.trialSessionPriceXaf,
    this.offersAtStudentHome = false,
    this.offersAtTutorHome = false,
    this.offersOnline = false,
    this.offersNeutralPlace = false,
    this.noticeHours = 24,
    this.maxSessionsPerWeek,
    this.isOnVacation = false,
    this.isDiplomaVerified = false,
    this.isActive = false,
    this.onboardingStep = 0,
    this.completionScore = 0,
    this.subjects = const [],
    this.levels = const [],
    this.specialties = const [],
    this.interventionZones = const [],
    this.packages = const [],
    this.availabilitySlots = const [],
    this.pendingOrLatestDocument,
    this.averageRating,
    this.reviewCount = 0,
    this.isExperienced = false,
    this.isHighlyResponsive = false,
  });

  factory TutorProfile.fromJson(Map<String, dynamic> j) => TutorProfile(
        id: j['id'] as int? ?? 0,
        userId: j['userId'] as int? ?? 0,
        fullName: j['fullName'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        title: j['title'] as String?,
        tutorBio: j['tutorBio'] as String?,
        videoUrl: j['videoUrl'] as String?,
        teachingStyle: j['teachingStyle'] as String?,
        hourlyRateXaf: j['hourlyRateXaf'] as num?,
        trialSessionEnabled: j['trialSessionEnabled'] as bool? ?? false,
        trialSessionPriceXaf: j['trialSessionPriceXaf'] as num?,
        offersAtStudentHome: j['offersAtStudentHome'] as bool? ?? false,
        offersAtTutorHome: j['offersAtTutorHome'] as bool? ?? false,
        offersOnline: j['offersOnline'] as bool? ?? false,
        offersNeutralPlace: j['offersNeutralPlace'] as bool? ?? false,
        noticeHours: j['noticeHours'] as int? ?? 24,
        maxSessionsPerWeek: j['maxSessionsPerWeek'] as int?,
        isOnVacation: j['isOnVacation'] as bool? ?? false,
        isDiplomaVerified: j['isDiplomaVerified'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? false,
        onboardingStep: j['onboardingStep'] as int? ?? 0,
        completionScore: j['completionScore'] as int? ?? 0,
        subjects: (j['subjects'] as List? ?? []).map((e) => e as String).toList(),
        levels: (j['levels'] as List? ?? []).map((e) => e as String).toList(),
        specialties: (j['specialties'] as List? ?? []).map((e) => e as String).toList(),
        interventionZones: (j['interventionZones'] as List? ?? [])
            .map((e) => TutorZone.fromJson(e as Map<String, dynamic>))
            .toList(),
        packages: (j['packages'] as List? ?? [])
            .map((e) => TutorPackage.fromJson(e as Map<String, dynamic>))
            .toList(),
        availabilitySlots: (j['availabilitySlots'] as List? ?? [])
            .map((e) => TutorAvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingOrLatestDocument: j['pendingOrLatestDocument'] != null
            ? TutorVerificationDocument.fromJson(j['pendingOrLatestDocument'] as Map<String, dynamic>)
            : null,
        averageRating: (j['averageRating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        isExperienced: j['isExperienced'] as bool? ?? false,
        isHighlyResponsive: j['isHighlyResponsive'] as bool? ?? false,
      );
}

class TutorProfileCompletion {
  final int score;
  final List<Map<String, String>> missingItems;
  const TutorProfileCompletion({required this.score, this.missingItems = const []});

  factory TutorProfileCompletion.fromJson(Map<String, dynamic> j) => TutorProfileCompletion(
        score: j['score'] as int? ?? 0,
        missingItems: (j['missingItems'] as List? ?? [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
      );
}

class TutorRateSuggestion {
  final int suggestedRateXaf;
  final int rangeLowXaf;
  final int rangeHighXaf;
  final String basedOn;
  final String explanation;
  const TutorRateSuggestion({
    required this.suggestedRateXaf,
    required this.rangeLowXaf,
    required this.rangeHighXaf,
    required this.basedOn,
    required this.explanation,
  });

  factory TutorRateSuggestion.fromJson(Map<String, dynamic> j) => TutorRateSuggestion(
        suggestedRateXaf: j['suggested_rate_xaf'] as int? ?? 0,
        rangeLowXaf: j['range_low_xaf'] as int? ?? 0,
        rangeHighXaf: j['range_high_xaf'] as int? ?? 0,
        basedOn: j['based_on'] as String? ?? 'estimation',
        explanation: j['explanation'] as String? ?? '',
      );
}

class TutorProfileService {
  TutorProfileService._();
  static final TutorProfileService instance = TutorProfileService._();
  final _api = ApiClient.instance;

  Future<TutorProfile> getMine() async {
    final res = await _api.dio.get('/tutor-profile/me');
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorProfile> update(Map<String, dynamic> payload) async {
    final res = await _api.dio.put('/tutor-profile/me', data: payload);
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorProfileCompletion> getCompletion() async {
    final res = await _api.dio.get('/tutor-profile/me/completion');
    return TutorProfileCompletion.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorProfile> activate() async {
    final res = await _api.dio.post('/tutor-profile/me/activate');
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorProfile> setVacation(bool isOnVacation) async {
    final res = await _api.dio.post('/tutor-profile/me/vacation', data: isOnVacation);
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorVerificationDocument> submitVerificationDocument(String documentUrl) async {
    final res = await _api.dio.post('/tutor-profile/me/verification-document', data: {'documentUrl': documentUrl});
    return TutorVerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorRateSuggestion> suggestRate(String subject, {String? level}) async {
    final res = await _api.dio.post('/tutor-profile/me/suggest-rate', data: {'subject': subject, 'level': level});
    return TutorRateSuggestion.fromJson(res.data as Map<String, dynamic>);
  }

  /// Recherche publique de répétiteurs (élève).
  Future<List<TutorSearchResult>> search({
    String? subject,
    String? level,
    num? maxHourlyRateXaf,
    bool? verifiedOnly,
    /// online | student_home | tutor_home | neutral_place
    String? mode,
    String? city,
    bool? availableSoon,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.dio.get('/tutor-profile/search', queryParameters: {
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (level != null && level.isNotEmpty) 'level': level,
      if (maxHourlyRateXaf != null) 'maxHourlyRateXaf': maxHourlyRateXaf,
      if (verifiedOnly != null) 'verifiedOnly': verifiedOnly,
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (city != null && city.isNotEmpty) 'city': city,
      if (availableSoon != null) 'availableSoon': availableSoon,
      'page': page,
      'pageSize': pageSize,
    });
    final list = res.data as List? ?? [];
    return list.map((e) => TutorSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fiche publique d'un répétiteur (404 si non actif).
  Future<TutorProfile> getPublicProfile(int userId) async {
    final res = await _api.dio.get('/tutor-profile/$userId');
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

/// Résultat de recherche répétiteur (US-STU — professeur_complete.md).
class TutorSearchResult {
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String? title;
  final num? hourlyRateXaf;
  final bool isDiplomaVerified;
  final double? averageRating;
  final int reviewCount;
  final List<String> subjects;
  final List<String> levels;

  const TutorSearchResult({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.title,
    this.hourlyRateXaf,
    this.isDiplomaVerified = false,
    this.averageRating,
    this.reviewCount = 0,
    this.subjects = const [],
    this.levels = const [],
  });

  factory TutorSearchResult.fromJson(Map<String, dynamic> j) => TutorSearchResult(
        userId: j['userId'] as int? ?? 0,
        fullName: j['fullName'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        title: j['title'] as String?,
        hourlyRateXaf: j['hourlyRateXaf'] as num?,
        isDiplomaVerified: j['isDiplomaVerified'] as bool? ?? false,
        averageRating: (j['averageRating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        subjects: (j['subjects'] as List? ?? []).map((e) => e as String).toList(),
        levels: (j['levels'] as List? ?? []).map((e) => e as String).toList(),
      );
}
