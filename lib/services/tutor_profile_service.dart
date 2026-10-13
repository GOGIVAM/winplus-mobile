import 'api_client.dart';

/// Profil "Mode Répétiteur" (Module 1  professeur_complete.md).
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

  factory TutorAvailabilitySlot.fromJson(Map<String, dynamic> j) =>
      TutorAvailabilitySlot(
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

// ── Grille tarifaire (lot 9.1, suivi 17.3) ──────────────────────────────

/// Tarif de base : [subject]/[mode] null = toutes les matières / tous modes.
class TutorRate {
  final String? subject;
  final String? mode; // online | in_person | null
  final num hourlyRateXaf;
  const TutorRate({this.subject, this.mode, required this.hourlyRateXaf});

  factory TutorRate.fromJson(Map<String, dynamic> j) => TutorRate(
        subject: j['subject'] as String?,
        mode: j['mode'] as String?,
        hourlyRateXaf: (j['hourlyRateXaf'] ?? 0) as num,
      );

  Map<String, dynamic> toJson() =>
      {'subject': subject, 'mode': mode, 'hourlyRateXaf': hourlyRateXaf};

  TutorRate copyWith(
          {String? subject,
          bool clearSubject = false,
          String? mode,
          bool clearMode = false,
          num? hourlyRateXaf}) =>
      TutorRate(
        subject: clearSubject ? null : (subject ?? this.subject),
        mode: clearMode ? null : (mode ?? this.mode),
        hourlyRateXaf: hourlyRateXaf ?? this.hourlyRateXaf,
      );
}

/// Modulation par créneau : +/- % sur les tranches de 30 min concernées.
class TutorRateModifier {
  final String label;
  final List<int> daysOfWeek; // 0 = dimanche … 6 = samedi ; vide = tous
  final String? startTime;
  final String? endTime;
  final int percentAdjustment;
  const TutorRateModifier({
    required this.label,
    this.daysOfWeek = const [],
    this.startTime,
    this.endTime,
    required this.percentAdjustment,
  });

  factory TutorRateModifier.fromJson(Map<String, dynamic> j) =>
      TutorRateModifier(
        label: j['label'] as String? ?? '',
        daysOfWeek: (j['daysOfWeek'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        startTime: j['startTime'] as String?,
        endTime: j['endTime'] as String?,
        percentAdjustment: (j['percentAdjustment'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'daysOfWeek': daysOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'percentAdjustment': percentAdjustment,
      };
}

/// Palier de dégressivité : remise sur toute la séance dès une durée.
class TutorDurationDiscount {
  final int minDurationMinutes;
  final int percentDiscount;
  const TutorDurationDiscount(
      {required this.minDurationMinutes, required this.percentDiscount});

  factory TutorDurationDiscount.fromJson(Map<String, dynamic> j) =>
      TutorDurationDiscount(
        minDurationMinutes: (j['minDurationMinutes'] as num?)?.toInt() ?? 120,
        percentDiscount: (j['percentDiscount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'minDurationMinutes': minDurationMinutes,
        'percentDiscount': percentDiscount,
      };
}

/// Palier de prix de groupe (lot 9.3) : remise par élève dès une taille de groupe.
class TutorGroupDiscount {
  final int minGroupSize;
  final int percentDiscount;
  const TutorGroupDiscount({required this.minGroupSize, required this.percentDiscount});

  factory TutorGroupDiscount.fromJson(Map<String, dynamic> j) => TutorGroupDiscount(
        minGroupSize: (j['minGroupSize'] as num?)?.toInt() ?? 2,
        percentDiscount: (j['percentDiscount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'minGroupSize': minGroupSize, 'percentDiscount': percentDiscount};
}

/// Réglages de prix de groupe proposés par WinAI (suivi 17.14, réponse
/// snake_case relayée telle quelle).
class TutorGroupPricingSuggestion {
  final int maxGroupSize;
  final List<TutorGroupDiscount> discounts;
  final int flatPercent;
  final bool marketData;
  final int sampleSize;
  final String explanation;
  const TutorGroupPricingSuggestion({
    required this.maxGroupSize,
    required this.discounts,
    required this.flatPercent,
    required this.marketData,
    required this.sampleSize,
    required this.explanation,
  });

  factory TutorGroupPricingSuggestion.fromJson(Map<String, dynamic> j) => TutorGroupPricingSuggestion(
        maxGroupSize: (j['max_group_size'] as num?)?.toInt() ?? 4,
        discounts: (j['discounts'] as List? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return TutorGroupDiscount(
              minGroupSize: (m['min_group_size'] as num?)?.toInt() ?? 2,
              percentDiscount: (m['percent_discount'] as num?)?.toInt() ?? 0);
        }).toList(),
        flatPercent: (j['flat_price_percent'] as num?)?.toInt() ?? 150,
        marketData: j['based_on'] == 'market_data',
        sampleSize: (j['sample_size'] as num?)?.toInt() ?? 0,
        explanation: j['explanation'] as String? ?? '',
      );
}

/// Grille proposée par WinAI (réponse snake_case relayée telle quelle).
class TutorRateGridSuggestion {
  final List<TutorRate> rates;
  final List<TutorRateModifier> modifiers;
  final List<TutorDurationDiscount> discounts;
  final String explanation;
  const TutorRateGridSuggestion({
    required this.rates,
    required this.modifiers,
    required this.discounts,
    required this.explanation,
  });

  factory TutorRateGridSuggestion.fromJson(Map<String, dynamic> j) =>
      TutorRateGridSuggestion(
        rates: (j['base_rates'] as List? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return TutorRate(
              subject: m['subject'] as String?,
              mode: m['mode'] as String?,
              hourlyRateXaf: (m['hourly_rate_xaf'] ?? 0) as num);
        }).toList(),
        modifiers: (j['modifiers'] as List? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return TutorRateModifier(
            label: m['label'] as String? ?? '',
            daysOfWeek: (m['days_of_week'] as List? ?? [])
                .map((d) => (d as num).toInt())
                .toList(),
            startTime: m['start_time'] as String?,
            endTime: m['end_time'] as String?,
            percentAdjustment: (m['percent_adjustment'] as num?)?.toInt() ?? 0,
          );
        }).toList(),
        discounts: (j['duration_discounts'] as List? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return TutorDurationDiscount(
              minDurationMinutes:
                  (m['min_duration_minutes'] as num?)?.toInt() ?? 120,
              percentDiscount: (m['percent_discount'] as num?)?.toInt() ?? 0);
        }).toList(),
        explanation: j['explanation'] as String? ?? '',
      );
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

  factory TutorVerificationDocument.fromJson(Map<String, dynamic> j) =>
      TutorVerificationDocument(
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

  /// Lot 9.5 (17.11) : vérifié pour le présentiel, suspension, présentiel possible.
  final bool isInPersonVerified;
  final bool inPersonSuspended;
  final bool inPersonAllowed;
  final String? inPersonBlockedReason;
  final List<String> endorsedByInstitutions;

  /// Lot 9.5 (17.17), propriétaire seulement : choix présentiels ENREGISTRÉS,
  /// conservés même sans vérification (inactifs tant que [inPersonAllowed] est
  /// faux). null = vue publique ou ancien serveur.
  final bool? savedOffersAtStudentHome;
  final bool? savedOffersAtTutorHome;
  final bool? savedOffersNeutralPlace;
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
  final List<TutorRate> rates;
  final List<TutorRateModifier> rateModifiers;
  final List<TutorDurationDiscount> durationDiscounts;
  final num? fromHourlyRateXaf;

  /// Politique d'annulation effective (bornée par la plateforme, lot 9.2).
  final int fullRefundHours;
  final int partialRefundPercent;
  final int noRefundHours;

  /// Séances de groupe (lot 9.3) : null = individuel seulement.
  final String? groupPricingMethod; // per_student | flat
  final int maxGroupSize;
  final int? groupFlatPricePercent;
  final List<TutorGroupDiscount> groupDiscounts;

  /// Lot 9.4 : offre d'engagement mensuel et sa remise (0 à 30 %).
  final bool monthlyEnabled;
  final int monthlyDiscountPercent;
  final int monthlyMaxDiscountPercent;

  /// Taille de groupe effective (1 si le tuteur ne propose pas de groupe).
  int get effectiveMaxGroupSize => groupPricingMethod == null ? 1 : maxGroupSize;

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
    this.isInPersonVerified = false,
    this.inPersonSuspended = false,
    this.inPersonAllowed = true,
    this.inPersonBlockedReason,
    this.endorsedByInstitutions = const [],
    this.savedOffersAtStudentHome,
    this.savedOffersAtTutorHome,
    this.savedOffersNeutralPlace,
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
    this.rates = const [],
    this.rateModifiers = const [],
    this.durationDiscounts = const [],
    this.fromHourlyRateXaf,
    this.fullRefundHours = 24,
    this.partialRefundPercent = 50,
    this.noRefundHours = 2,
    this.groupPricingMethod,
    this.maxGroupSize = 1,
    this.groupFlatPricePercent,
    this.groupDiscounts = const [],
    this.monthlyEnabled = false,
    this.monthlyDiscountPercent = 0,
    this.monthlyMaxDiscountPercent = 30,
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
        isInPersonVerified: j['isInPersonVerified'] as bool? ?? false,
        inPersonSuspended: j['inPersonSuspended'] as bool? ?? false,
        // Absent (ancien serveur) = autorisé, comme avant le lot 9.5.
        inPersonAllowed: j['inPersonAllowed'] as bool? ?? true,
        inPersonBlockedReason: j['inPersonBlockedReason'] as String?,
        endorsedByInstitutions: (j['endorsedByInstitutions'] as List? ?? []).map((e) => e.toString()).toList(),
        savedOffersAtStudentHome: j['savedOffersAtStudentHome'] as bool?,
        savedOffersAtTutorHome: j['savedOffersAtTutorHome'] as bool?,
        savedOffersNeutralPlace: j['savedOffersNeutralPlace'] as bool?,
        isActive: j['isActive'] as bool? ?? false,
        onboardingStep: j['onboardingStep'] as int? ?? 0,
        completionScore: j['completionScore'] as int? ?? 0,
        subjects:
            (j['subjects'] as List? ?? []).map((e) => e as String).toList(),
        levels: (j['levels'] as List? ?? []).map((e) => e as String).toList(),
        specialties:
            (j['specialties'] as List? ?? []).map((e) => e as String).toList(),
        interventionZones: (j['interventionZones'] as List? ?? [])
            .map((e) => TutorZone.fromJson(e as Map<String, dynamic>))
            .toList(),
        packages: (j['packages'] as List? ?? [])
            .map((e) => TutorPackage.fromJson(e as Map<String, dynamic>))
            .toList(),
        availabilitySlots: (j['availabilitySlots'] as List? ?? [])
            .map((e) =>
                TutorAvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingOrLatestDocument: j['pendingOrLatestDocument'] != null
            ? TutorVerificationDocument.fromJson(
                j['pendingOrLatestDocument'] as Map<String, dynamic>)
            : null,
        averageRating: (j['averageRating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        isExperienced: j['isExperienced'] as bool? ?? false,
        isHighlyResponsive: j['isHighlyResponsive'] as bool? ?? false,
        rates: (j['rates'] as List? ?? [])
            .map((e) => TutorRate.fromJson(e as Map<String, dynamic>))
            .toList(),
        rateModifiers: (j['rateModifiers'] as List? ?? [])
            .map((e) => TutorRateModifier.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationDiscounts: (j['durationDiscounts'] as List? ?? [])
            .map((e) =>
                TutorDurationDiscount.fromJson(e as Map<String, dynamic>))
            .toList(),
        fromHourlyRateXaf: j['fromHourlyRateXaf'] as num?,
        fullRefundHours: (j['fullRefundHours'] as num?)?.toInt() ?? 24,
        partialRefundPercent: (j['partialRefundPercent'] as num?)?.toInt() ?? 50,
        noRefundHours: (j['noRefundHours'] as num?)?.toInt() ?? 2,
        groupPricingMethod: j['groupPricingMethod'] as String?,
        maxGroupSize: (j['maxGroupSize'] as num?)?.toInt() ?? 1,
        groupFlatPricePercent: (j['groupFlatPricePercent'] as num?)?.toInt(),
        groupDiscounts: (j['groupDiscounts'] as List? ?? [])
            .map((e) => TutorGroupDiscount.fromJson(e as Map<String, dynamic>))
            .toList(),
        monthlyEnabled: j['monthlyEnabled'] as bool? ?? false,
        monthlyDiscountPercent: (j['monthlyDiscountPercent'] as num?)?.toInt() ?? 0,
        monthlyMaxDiscountPercent: (j['monthlyMaxDiscountPercent'] as num?)?.toInt() ?? 30,
      );
}

class TutorProfileCompletion {
  final int score;
  final List<Map<String, String>> missingItems;
  const TutorProfileCompletion(
      {required this.score, this.missingItems = const []});

  factory TutorProfileCompletion.fromJson(Map<String, dynamic> j) =>
      TutorProfileCompletion(
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

  factory TutorRateSuggestion.fromJson(Map<String, dynamic> j) =>
      TutorRateSuggestion(
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
    final res =
        await _api.dio.post('/tutor-profile/me/vacation', data: isOnVacation);
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorVerificationDocument> submitVerificationDocument(
      String documentUrl) async {
    final res = await _api.dio.post('/tutor-profile/me/verification-document',
        data: {'documentUrl': documentUrl});
    return TutorVerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorRateSuggestion> suggestRate(String subject,
      {String? level}) async {
    final res = await _api.dio.post('/tutor-profile/me/suggest-rate',
        data: {'subject': subject, 'level': level});
    return TutorRateSuggestion.fromJson(res.data as Map<String, dynamic>);
  }

  /// Suggestion WinAI d'une grille complète (lot 9.1) : base par matière et
  /// par mode, modulations, dégressivité. Le tuteur reste libre de l'éditer.
  Future<TutorRateGridSuggestion?> suggestRateGrid(
      List<String> subjects, List<String> modes,
      {String? level}) async {
    final res = await _api.dio.post('/tutor-profile/me/suggest-rate', data: {
      'subject': subjects.first,
      'level': level,
      'include_grid': true,
      'subjects': subjects,
      'modes': modes,
    });
    final grid = (res.data as Map<String, dynamic>)['grid'];
    return grid is Map<String, dynamic>
        ? TutorRateGridSuggestion.fromJson(grid)
        : null;
  }

  /// Suivi 17.14 : suggestion WinAI des réglages de prix de groupe (17.3).
  Future<TutorGroupPricingSuggestion?> suggestGroupPricing(String subject, {String? level}) async {
    final res = await _api.dio.post('/tutor-profile/me/suggest-rate',
        data: {'subject': subject, 'level': level, 'include_group': true});
    final group = (res.data as Map<String, dynamic>)['group'];
    return group is Map<String, dynamic> ? TutorGroupPricingSuggestion.fromJson(group) : null;
  }

  /// Recherche publique de répétiteurs (élève).
  Future<List<TutorSearchResult>> search({
    String? subject,
    String? level,
    num? maxHourlyRateXaf,
    bool? verifiedOnly,

    /// Lot 9.5 : seulement les tuteurs vérifiés pour le présentiel.
    bool? inPersonVerifiedOnly,

    /// online | in_person | student_home | tutor_home | neutral_place
    /// (tout mode présentiel ne renvoie que des tuteurs vérifiés, lot 9.5)
    String? mode,
    String? city,
    bool? availableSoon,

    /// Sujets de séance (lot 9.1) : classent les tuteurs par correspondance.
    List<String> topics = const [],
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.dio.get('/tutor-profile/search', queryParameters: {
      if (topics.isNotEmpty) 'topics': topics.join(','),
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (level != null && level.isNotEmpty) 'level': level,
      if (maxHourlyRateXaf != null) 'maxHourlyRateXaf': maxHourlyRateXaf,
      if (verifiedOnly != null) 'verifiedOnly': verifiedOnly,
      if (inPersonVerifiedOnly == true) 'inPersonVerifiedOnly': true,
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (city != null && city.isNotEmpty) 'city': city,
      if (availableSoon != null) 'availableSoon': availableSoon,
      'page': page,
      'pageSize': pageSize,
    });
    final list = res.data as List? ?? [];
    return list
        .map((e) => TutorSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fiche publique d'un répétiteur (404 si non actif).
  Future<TutorProfile> getPublicProfile(int userId) async {
    final res = await _api.dio.get('/tutor-profile/$userId');
    return TutorProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

/// Résultat de recherche répétiteur (US-STU  professeur_complete.md).
class TutorSearchResult {
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String? title;
  final num? hourlyRateXaf;
  final bool isDiplomaVerified;

  /// Lot 9.5 : vérifié pour le présentiel (non suspendu), modes réels, cautions.
  final bool isInPersonVerified;
  final bool? offersInPerson;
  final List<String> endorsedByInstitutions;
  final double? averageRating;
  final int reviewCount;
  final List<String> subjects;
  final List<String> levels;
  final num? fromHourlyRateXaf;
  final List<String> matchedTopics;

  const TutorSearchResult({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.title,
    this.hourlyRateXaf,
    this.isDiplomaVerified = false,
    this.isInPersonVerified = false,
    this.offersInPerson,
    this.endorsedByInstitutions = const [],
    this.averageRating,
    this.reviewCount = 0,
    this.subjects = const [],
    this.levels = const [],
    this.fromHourlyRateXaf,
    this.matchedTopics = const [],
  });

  factory TutorSearchResult.fromJson(Map<String, dynamic> j) =>
      TutorSearchResult(
        fromHourlyRateXaf: j['fromHourlyRateXaf'] as num?,
        matchedTopics: (j['matchedTopics'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        userId: j['userId'] as int? ?? 0,
        fullName: j['fullName'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        title: j['title'] as String?,
        hourlyRateXaf: j['hourlyRateXaf'] as num?,
        isDiplomaVerified: j['isDiplomaVerified'] as bool? ?? false,
        isInPersonVerified: j['isInPersonVerified'] as bool? ?? false,
        offersInPerson: j['offersInPerson'] as bool?,
        endorsedByInstitutions: (j['endorsedByInstitutions'] as List? ?? []).map((e) => e.toString()).toList(),
        averageRating: (j['averageRating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        subjects:
            (j['subjects'] as List? ?? []).map((e) => e as String).toList(),
        levels: (j['levels'] as List? ?? []).map((e) => e as String).toList(),
      );
}
