import 'package:dio/dio.dart';

import 'api_client.dart';

// ─── Modèles ──────────────────────────────────────────────────────────────────

class CourseListItem {
  final int id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? thumbnailUrl;
  final String? level;
  final String? category;
  final double price;
  final bool isFree;
  final int totalDurationMin;
  final int lessonsCount;
  final int enrolledCount;
  final double avgRating;
  final int reviewsCount;
  final String instructorName;

  const CourseListItem({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.thumbnailUrl,
    this.level,
    this.category,
    required this.price,
    required this.isFree,
    required this.totalDurationMin,
    required this.lessonsCount,
    required this.enrolledCount,
    required this.avgRating,
    required this.reviewsCount,
    required this.instructorName,
  });

  factory CourseListItem.fromJson(Map<String, dynamic> j) => CourseListItem(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        shortDescription: j['shortDescription'] as String?,
        thumbnailUrl: j['thumbnailUrl'] as String?,
        level: j['level'] as String?,
        category: j['category'] as String?,
        price: ((j['price'] ?? 0) as num).toDouble(),
        isFree: j['isFree'] as bool? ?? false,
        totalDurationMin: j['totalDurationMin'] as int? ?? 0,
        lessonsCount: j['lessonsCount'] as int? ?? 0,
        enrolledCount: j['enrolledCount'] as int? ?? 0,
        avgRating: ((j['avgRating'] ?? 0) as num).toDouble(),
        reviewsCount: j['reviewsCount'] as int? ?? 0,
        instructorName: j['instructorName'] as String? ?? '',
      );

  String get durationStr {
    final h = totalDurationMin ~/ 60;
    final m = totalDurationMin % 60;
    if (h > 0 && m > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    if (h > 0) return '${h}h';
    return '${m}min';
  }
}

class CourseLesson {
  final int id;
  final String title;
  final String lessonType;
  final int videoDurationSec;
  final bool isPreview;
  final int position;
  final String? videoUrl;
  final String? articleContent;
  final String? fileUrl;
  final String? fileName;

  const CourseLesson({
    required this.id,
    required this.title,
    required this.lessonType,
    required this.videoDurationSec,
    required this.isPreview,
    required this.position,
    this.videoUrl,
    this.articleContent,
    this.fileUrl,
    this.fileName,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> j) => CourseLesson(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        lessonType: j['lessonType'] as String? ?? 'video',
        videoDurationSec: j['videoDurationSec'] as int? ?? 0,
        isPreview: j['isPreview'] as bool? ?? false,
        position: j['position'] as int? ?? 0,
        videoUrl: j['videoUrl'] as String?,
        articleContent: j['articleContent'] as String?,
        fileUrl: j['fileUrl'] as String?,
        fileName: j['fileName'] as String?,
      );

  String get durationStr {
    final m = videoDurationSec ~/ 60;
    final s = videoDurationSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class CourseSection {
  final int id;
  final String title;
  final int position;
  final List<CourseLesson> lessons;

  const CourseSection({
    required this.id,
    required this.title,
    required this.position,
    required this.lessons,
  });

  factory CourseSection.fromJson(Map<String, dynamic> j) => CourseSection(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        position: j['position'] as int? ?? 0,
        lessons: (j['lessons'] as List? ?? [])
            .map((e) => CourseLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CourseDetail {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String? level;
  final String? category;
  final double price;
  final bool isFree;
  final int totalDurationMin;
  final int lessonsCount;
  final int enrolledCount;
  final double avgRating;
  final int reviewsCount;
  final List<String> requirements;
  final List<String> objectives;
  final bool certificateEnabled;
  final bool isEnrolled;
  final List<CourseSection> sections;
  final String instructorName;

  /// Lot 9.7b (F1, F2) : formation achetée par l'utilisateur, formation dont
  /// il est l'auteur, et raison d'un achat impossible (free_course,
  /// own_course, already_enrolled, already_purchased) ou null si achetable.
  /// Le prix est TTC (18.21) ; une formation n'est jamais incluse dans un
  /// abonnement (18.16).
  final bool isPurchased;
  final bool isOwner;
  final String? purchaseBlockCode;

  bool get isPaid => !isFree && price > 0;

  const CourseDetail({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.shortDescription,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.level,
    this.category,
    required this.price,
    required this.isFree,
    required this.totalDurationMin,
    required this.lessonsCount,
    required this.enrolledCount,
    required this.avgRating,
    required this.reviewsCount,
    required this.requirements,
    required this.objectives,
    required this.certificateEnabled,
    required this.isEnrolled,
    required this.sections,
    required this.instructorName,
    this.isPurchased = false,
    this.isOwner = false,
    this.purchaseBlockCode,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> j) => CourseDetail(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        description: j['description'] as String?,
        shortDescription: j['shortDescription'] as String?,
        thumbnailUrl: j['thumbnailUrl'] as String?,
        previewVideoUrl: j['previewVideoUrl'] as String?,
        level: j['level'] as String?,
        category: j['category'] as String?,
        price: ((j['price'] ?? 0) as num).toDouble(),
        isFree: j['isFree'] as bool? ?? false,
        totalDurationMin: j['totalDurationMin'] as int? ?? 0,
        lessonsCount: j['lessonsCount'] as int? ?? 0,
        enrolledCount: j['enrolledCount'] as int? ?? 0,
        avgRating: ((j['avgRating'] ?? 0) as num).toDouble(),
        reviewsCount: j['reviewsCount'] as int? ?? 0,
        requirements: (j['requirements'] as List? ?? []).cast<String>(),
        objectives: (j['objectives'] as List? ?? []).cast<String>(),
        certificateEnabled: j['certificateEnabled'] as bool? ?? true,
        isEnrolled: j['isEnrolled'] as bool? ?? false,
        sections: (j['sections'] as List? ?? [])
            .map((e) => CourseSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        instructorName:
            (j['instructor'] as Map<String, dynamic>?)?['name'] as String? ??
                '',
        isPurchased: j['isPurchased'] as bool? ?? false,
        isOwner: j['isOwner'] as bool? ?? false,
        purchaseBlockCode: j['purchaseBlockCode'] as String?,
      );

  String get durationStr {
    final h = totalDurationMin ~/ 60;
    final m = totalDurationMin % 60;
    if (h > 0 && m > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  int get totalLessons => sections.fold(0, (a, s) => a + s.lessons.length);
}

class CurriculumLesson {
  final int id;
  final String title;
  final String lessonType;
  final int videoDurationSec;
  final int position;
  final bool isPreview;
  final bool isCompleted;
  final int lastPositionSec;

  const CurriculumLesson({
    required this.id,
    required this.title,
    required this.lessonType,
    required this.videoDurationSec,
    required this.position,
    required this.isPreview,
    required this.isCompleted,
    required this.lastPositionSec,
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> j) => CurriculumLesson(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        lessonType: j['lessonType'] as String? ?? 'video',
        videoDurationSec: j['videoDurationSec'] as int? ?? 0,
        position: j['position'] as int? ?? 0,
        isPreview: j['isPreview'] as bool? ?? false,
        isCompleted: j['isCompleted'] as bool? ?? false,
        lastPositionSec: j['lastPositionSec'] as int? ?? 0,
      );

  String get durationStr {
    final m = videoDurationSec ~/ 60;
    final s = videoDurationSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class CurriculumSection {
  final int id;
  final String title;
  final int position;
  final List<CurriculumLesson> lessons;

  const CurriculumSection({
    required this.id,
    required this.title,
    required this.position,
    required this.lessons,
  });

  factory CurriculumSection.fromJson(Map<String, dynamic> j) =>
      CurriculumSection(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        position: j['position'] as int? ?? 0,
        lessons: (j['lessons'] as List? ?? [])
            .map((e) => CurriculumLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CourseCurriculum {
  final int courseId;
  final String title;
  final double progressPercent;
  final String? completedAt;
  final String? certificateUrl;
  final List<CurriculumSection> sections;

  const CourseCurriculum({
    required this.courseId,
    required this.title,
    required this.progressPercent,
    this.completedAt,
    this.certificateUrl,
    required this.sections,
  });

  factory CourseCurriculum.fromJson(Map<String, dynamic> j) => CourseCurriculum(
        courseId: j['courseId'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        progressPercent: ((j['progressPercent'] ?? 0) as num).toDouble(),
        completedAt: j['completedAt'] as String?,
        certificateUrl: j['certificateUrl'] as String?,
        sections: (j['sections'] as List? ?? [])
            .map((e) => CurriculumSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<CurriculumLesson> get allLessons =>
      sections.expand((s) => s.lessons).toList();
}

class LessonContent {
  final int id;
  final String title;
  final String lessonType;
  final String? description;
  final String? videoUrl;
  final int videoDurationSec;
  final String? articleContent;
  final String? fileUrl;
  final String? fileName;
  final bool isPreview;
  final bool isCompleted;
  final int lastPositionSec;

  /// Lot 9.7b (F13) : épreuve ou livre du catalogue contenu dans la
  /// formation. Jamais téléchargeable (fileUrl nul) : consulté dans la
  /// visionneuse sécurisée (/subjects/{id}/view?courseId=…).
  final int? sourceSubjectId;
  final int? quizId;

  const LessonContent({
    required this.id,
    required this.title,
    required this.lessonType,
    this.description,
    this.videoUrl,
    required this.videoDurationSec,
    this.articleContent,
    this.fileUrl,
    this.fileName,
    required this.isPreview,
    required this.isCompleted,
    required this.lastPositionSec,
    this.sourceSubjectId,
    this.quizId,
  });

  factory LessonContent.fromJson(Map<String, dynamic> j) {
    final prog = j['progress'] as Map<String, dynamic>?;
    return LessonContent(
      id: j['id'] as int? ?? 0,
      title: j['title'] as String? ?? '',
      lessonType: j['lessonType'] as String? ?? 'video',
      description: j['description'] as String?,
      videoUrl: j['videoUrl'] as String?,
      videoDurationSec: j['videoDurationSec'] as int? ?? 0,
      articleContent: j['articleContent'] as String?,
      fileUrl: j['fileUrl'] as String?,
      fileName: j['fileName'] as String?,
      isPreview: j['isPreview'] as bool? ?? false,
      isCompleted: prog?['isCompleted'] as bool? ?? false,
      lastPositionSec: prog?['lastPositionSec'] as int? ?? 0,
      sourceSubjectId: j['sourceSubjectId'] as int?,
      quizId: j['quizId'] as int?,
    );
  }
}

/// Lot 9.7b (F15) : certificat de formation de l'utilisateur
/// (GET /api/my-course-certificates), distinct des certificats de sujets.
class MyCourseCertificate {
  final int id;
  final int courseId;
  final String courseTitle;
  final String? instructorName;
  final String verificationCode;
  final double? grade;

  /// Lien PDF présigné à durée limitée (les certificats de formation restent
  /// téléchargeables, 18.21).
  final String? fileUrl;
  final DateTime? issuedAt;

  const MyCourseCertificate({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.instructorName,
    required this.verificationCode,
    this.grade,
    this.fileUrl,
    this.issuedAt,
  });

  factory MyCourseCertificate.fromJson(Map<String, dynamic> j) =>
      MyCourseCertificate(
        id: j['id'] as int? ?? 0,
        courseId: j['courseId'] as int? ?? 0,
        courseTitle: j['courseTitle'] as String? ?? 'Formation',
        instructorName: j['instructorName'] as String?,
        verificationCode: j['verificationCode'] as String? ?? '',
        grade: (j['grade'] as num?)?.toDouble(),
        fileUrl: j['fileUrl'] as String?,
        issuedAt: DateTime.tryParse(j['issuedAt'] as String? ?? ''),
      );
}

/// Lot 9.7b (F12, F3) : refus explicite du serveur (409) : complétion non
/// validée, ou formation déjà achetée / déjà suivie / gratuite / à soi.
class CourseActionRefused implements Exception {
  final String? code;
  final String message;
  const CourseActionRefused(this.code, this.message);
  @override
  String toString() => message;
}

class MyEnrollment {
  final int enrollmentId;
  final String accessType;
  final double progressPercent;
  final String? completedAt;
  final String? certificateUrl;
  final int courseId;
  final String courseTitle;
  final String? thumbnailUrl;
  final String? category;
  final int lessonsCount;
  final int totalDurationMin;
  final String instructorName;

  /// Lot 9.7b (F15) : code de vérification du certificat de formation.
  final String? certificateCode;

  const MyEnrollment({
    required this.enrollmentId,
    required this.accessType,
    required this.progressPercent,
    this.completedAt,
    this.certificateUrl,
    this.certificateCode,
    required this.courseId,
    required this.courseTitle,
    this.thumbnailUrl,
    this.category,
    required this.lessonsCount,
    required this.totalDurationMin,
    required this.instructorName,
  });

  factory MyEnrollment.fromJson(Map<String, dynamic> j) {
    final c = j['course'] as Map<String, dynamic>? ?? {};
    return MyEnrollment(
      enrollmentId: j['enrollmentId'] as int? ?? 0,
      accessType: j['accessType'] as String? ?? 'free',
      progressPercent: ((j['progressPercent'] ?? 0) as num).toDouble(),
      completedAt: j['completedAt'] as String?,
      certificateUrl: j['certificateUrl'] as String?,
      certificateCode: j['certificateCode'] as String?,
      courseId: c['id'] as int? ?? 0,
      courseTitle: c['title'] as String? ?? '',
      thumbnailUrl: c['thumbnailUrl'] as String?,
      category: c['category'] as String?,
      lessonsCount: c['lessonsCount'] as int? ?? 0,
      totalDurationMin: c['totalDurationMin'] as int? ?? 0,
      instructorName: c['instructorName'] as String? ?? '',
    );
  }

  bool get isCompleted => completedAt != null || progressPercent >= 100;

  String get durationStr {
    final h = totalDurationMin ~/ 60;
    final m = totalDurationMin % 60;
    if (h > 0) return '${h}h${m > 0 ? m.toString().padLeft(2, '0') : ''}';
    return '${m}min';
  }
}

// ─── Reviews ─────────────────────────────────────────────────────────────────

class CourseReview {
  final int id;
  final int rating;
  final String? comment;
  final bool isVerified;
  final String createdAt;
  final String authorName;
  final String? authorAvatarUrl;

  const CourseReview({
    required this.id,
    required this.rating,
    this.comment,
    required this.isVerified,
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
  });

  factory CourseReview.fromJson(Map<String, dynamic> j) => CourseReview(
        id: j['id'] as int? ?? 0,
        rating: j['rating'] as int? ?? 0,
        comment: j['comment'] as String?,
        isVerified: j['isVerified'] as bool? ?? false,
        createdAt: j['createdAt'] as String? ?? '',
        authorName:
            (j['author'] as Map<String, dynamic>?)?['name'] as String? ??
                'Utilisateur',
        authorAvatarUrl:
            (j['author'] as Map<String, dynamic>?)?['avatarUrl'] as String?,
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class CourseService {
  CourseService._();
  static final CourseService instance = CourseService._();

  final _api = ApiClient.instance;

  // Catalogue
  Future<({List<CourseListItem> items, int total, int totalPages})> list({
    String? category,
    String? level,
    bool? free,
    int page = 1,
    int pageSize = 12,
  }) async {
    final res = await _api.dio.get('/courses', queryParameters: {
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      if (free != null) 'free': free,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? [])
        .map((e) => CourseListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      total: data['total'] as int? ?? items.length,
      totalPages: data['totalPages'] as int? ?? 1,
    );
  }

  Future<List<CourseListItem>> search(String q, {int page = 1}) async {
    final res = await _api.dio
        .get('/courses/search', queryParameters: {'q': q, 'page': page});
    return (res.data as List? ?? [])
        .map((e) => CourseListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseDetail> get(int id) async {
    final res = await _api.dio.get('/courses/$id');
    return CourseDetail.fromJson(res.data as Map<String, dynamic>);
  }

  // Inscription : lot 9.7b, formations gratuites seulement (ou rattrapage
  // d'une formation déjà payée). Une formation payante s'achète (panier ou
  // achat direct) et s'ouvre à la confirmation du paiement.
  Future<void> enroll(int courseId) async {
    try {
      await _api.dio.post('/courses/$courseId/enroll');
    } on DioException catch (e) {
      throw _refusal(e) ?? e;
    }
  }

  /// Lot 9.7b (F2) : paiement immédiat du panier par le solde WinPlus
  /// (comptes professeur). Renvoie null en cas de succès (l'inscription est
  /// créée par le serveur), sinon le message à afficher (solde insuffisant,
  /// formation déjà achetée…).
  Future<String?> payCartWithBalance() async {
    try {
      await _api.dio.post('/orders/pay-with-balance');
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['error'] as String? : null;
      return msg ?? 'Le paiement par solde a échoué. Réessaie.';
    }
  }

  /// Lot 9.7b (F14) : un parent achète la formation pour un enfant lié,
  /// depuis son portefeuille. Renvoie null en cas de succès (l'enfant est
  /// inscrit par le serveur), sinon le message à afficher (solde
  /// insuffisant, déjà achetée ou déjà suivie par l'enfant…).
  Future<String?> purchaseForChild(int courseId, int childId) async {
    try {
      await _api.dio.post('/parent/purchase-for-child',
          data: {'childId': childId, 'courseId': courseId});
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['error'] as String? : null;
      return msg ?? 'L\'achat n\'a pas pu être finalisé.';
    }
  }

  /// Lot 9.7b (F15) : mes certificats de formation.
  Future<List<MyCourseCertificate>> myCourseCertificates() async {
    final res = await _api.dio.get('/my-course-certificates');
    final data = res.data;
    final list =
        data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return list
        .map((e) => MyCourseCertificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Refus métier (400/409) renvoyé par le serveur, avec son message.
  static CourseActionRefused? _refusal(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if ((status == 409 || status == 400) && data is Map) {
      final msg = data['error'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return CourseActionRefused(data['code'] as String?, msg);
      }
    }
    return null;
  }

  Future<List<MyEnrollment>> myCourses() async {
    final res = await _api.dio.get('/my-courses');
    return (res.data as List? ?? [])
        .map((e) => MyEnrollment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Lecteur
  Future<CourseCurriculum> getCurriculum(int courseId) async {
    final res = await _api.dio.get('/courses/$courseId/play');
    return CourseCurriculum.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LessonContent> getLesson(int courseId, int lessonId) async {
    final res = await _api.dio.get('/courses/$courseId/play/$lessonId');
    return LessonContent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<({double progressPercent, bool courseCompleted})> saveProgress(
    int courseId,
    int lessonId, {
    required int watchTimeSec,
    required int lastPositionSec,
    required bool isCompleted,
  }) async {
    // Lot 9.7b (F12) : la complétion est validée par le serveur ; un refus
    // (vidéo pas assez regardée, quiz non réussi) répond 409 et remonte en
    // CourseActionRefused avec le message à afficher.
    final Response res;
    try {
      res = await _api.dio.post(
        '/courses/$courseId/play/$lessonId/progress',
        data: {
          'watchTimeSec': watchTimeSec,
          'lastPositionSec': lastPositionSec,
          'isCompleted': isCompleted,
        },
      );
    } on DioException catch (e) {
      throw _refusal(e) ?? e;
    }
    final d = res.data as Map<String, dynamic>;
    return (
      progressPercent: ((d['progressPercent'] ?? 0) as num).toDouble(),
      courseCompleted: d['courseCompleted'] as bool? ?? false,
    );
  }

  // Avis
  Future<List<CourseReview>> getReviews(int courseId) async {
    final res = await _api.dio.get('/courses/$courseId/reviews',
        queryParameters: {'page': 1, 'pageSize': 10});
    final data = res.data;
    final list =
        data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return list
        .map((e) => CourseReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitReview(int courseId, int rating, {String? comment}) async {
    await _api.dio.post('/courses/$courseId/reviews', data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment
    });
  }
}
