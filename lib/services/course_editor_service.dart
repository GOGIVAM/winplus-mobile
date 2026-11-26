import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';
import 'chatbot_service.dart';

/// Refus lisible (formation en validation, droit WinAI absent…).
class CourseEditorException implements Exception {
  final String message;
  final int? status;
  const CourseEditorException(this.message, {this.status});

  /// Fonction hors du plan ou limite WinAI : proposer les offres.
  bool get isQuota => status == 402 || status == 403;

  @override
  String toString() => message;
}

/// Leçon d'une formation (éditeur du professeur).
class EditorLesson {
  final int id;
  final String title;
  final String? description;

  /// video, article, file, Fichier (contenu du catalogue) ou quiz.
  final String type;
  final String? videoUrl;
  final int videoDurationSec;
  final String? articleContent;
  final String? fileUrl;
  final String? fileName;
  final bool isPreview;
  final bool isPublished;
  final int position;
  final int? sourceSubjectId;

  const EditorLesson({
    required this.id,
    required this.title,
    this.description,
    this.type = 'video',
    this.videoUrl,
    this.videoDurationSec = 0,
    this.articleContent,
    this.fileUrl,
    this.fileName,
    this.isPreview = false,
    this.isPublished = true,
    this.position = 0,
    this.sourceSubjectId,
  });

  factory EditorLesson.fromJson(Map<String, dynamic> j) => EditorLesson(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        type: j['lessonType']?.toString() ?? 'video',
        videoUrl: j['videoUrl'] as String?,
        videoDurationSec: (j['videoDurationSec'] as num?)?.toInt() ?? 0,
        articleContent: j['articleContent'] as String?,
        fileUrl: j['fileUrl'] as String?,
        fileName: j['fileName'] as String?,
        isPreview: j['isPreview'] == true,
        isPublished: j['isPublished'] != false,
        position: (j['position'] as num?)?.toInt() ?? 0,
        sourceSubjectId: (j['sourceSubjectId'] as num?)?.toInt(),
      );
}

/// Section (chapitre) avec sa règle d'ouverture.
class EditorSection {
  final int id;
  final String title;
  final String? description;
  final int position;

  /// immediate, delay_days ou min_score.
  final String unlockRule;
  final int? delayDays;
  final int? minScore;
  final List<EditorLesson> lessons;

  const EditorSection({
    required this.id,
    required this.title,
    this.description,
    this.position = 0,
    this.unlockRule = 'immediate',
    this.delayDays,
    this.minScore,
    this.lessons = const [],
  });

  factory EditorSection.fromJson(Map<String, dynamic> j) => EditorSection(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        position: (j['position'] as num?)?.toInt() ?? 0,
        unlockRule: j['unlockRule']?.toString() ?? 'immediate',
        delayDays: (j['delayDays'] as num?)?.toInt(),
        minScore: (j['minScore'] as num?)?.toInt(),
        lessons: (j['lessons'] is List ? j['lessons'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(EditorLesson.fromJson)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position)),
      );
}

/// Formation telle que l'édite son professeur (GET /teacher/courses/{id}).
class EditorCourse {
  final int id;
  final String title;
  final String? shortDescription;
  final String? description;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String language;
  final String level;
  final String? category;
  final List<String> tags;
  final num price;
  final bool isFree;
  final List<String> requirements;
  final List<String> objectives;
  final bool certificateEnabled;

  /// draft, pending_review, published, rejected ou archived.
  final String status;
  final String? rejectionReason;
  final List<EditorSection> sections;

  const EditorCourse({
    required this.id,
    required this.title,
    this.shortDescription,
    this.description,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.language = 'fr',
    this.level = 'debutant',
    this.category,
    this.tags = const [],
    this.price = 0,
    this.isFree = false,
    this.requirements = const [],
    this.objectives = const [],
    this.certificateEnabled = true,
    this.status = 'draft',
    this.rejectionReason,
    this.sections = const [],
  });

  bool get editable => status != 'pending_review';
  int get lessonsCount => sections.fold(0, (n, s) => n + s.lessons.length);
  int get publishedLessons => sections.fold(0, (n, s) => n + s.lessons.where((x) => x.isPublished).length);

  static List<String> _strings(Object? v) => (v is List ? v : const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

  factory EditorCourse.fromJson(Map<String, dynamic> j) => EditorCourse(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        shortDescription: j['shortDescription'] as String?,
        description: j['description'] as String?,
        thumbnailUrl: j['thumbnailUrl'] as String?,
        previewVideoUrl: j['previewVideoUrl'] as String?,
        language: j['language']?.toString() ?? 'fr',
        level: j['level']?.toString() ?? 'debutant',
        category: j['category'] as String?,
        tags: _strings(j['tags']),
        price: (j['price'] as num?) ?? 0,
        isFree: j['isFree'] == true,
        requirements: _strings(j['requirements']),
        objectives: _strings(j['objectives']),
        certificateEnabled: j['certificateEnabled'] != false,
        status: j['status']?.toString() ?? 'draft',
        rejectionReason: j['rejectionReason'] as String?,
        sections: (j['sections'] is List ? j['sections'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(EditorSection.fromJson)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position)),
      );
}

/// Ludification d'une formation : points et classement.
class Gamification {
  final bool enabled;
  final int pointsPerLesson;
  final int pointsPerQuiz;
  final int bonusPerfect;
  final bool leaderboardVisible;
  const Gamification({
    this.enabled = false,
    this.pointsPerLesson = 10,
    this.pointsPerQuiz = 20,
    this.bonusPerfect = 10,
    this.leaderboardVisible = true,
  });

  factory Gamification.fromJson(Map<String, dynamic> j) => Gamification(
        enabled: j['gamificationEnabled'] == true,
        pointsPerLesson: (j['pointsPerLesson'] as num?)?.toInt() ?? 10,
        pointsPerQuiz: (j['pointsPerQuiz'] as num?)?.toInt() ?? 20,
        bonusPerfect: (j['pointsBonusPerfectScore'] as num?)?.toInt() ?? 10,
        leaderboardVisible: j['leaderboardVisible'] != false,
      );

  Map<String, dynamic> toJson() => {
        'gamificationEnabled': enabled,
        'pointsPerLesson': pointsPerLesson,
        'pointsPerQuiz': pointsPerQuiz,
        'pointsBonusPerfectScore': bonusPerfect,
        'leaderboardVisible': leaderboardVisible,
      };

  Gamification copyWith({bool? enabled, int? pointsPerLesson, int? pointsPerQuiz, int? bonusPerfect, bool? leaderboardVisible}) =>
      Gamification(
        enabled: enabled ?? this.enabled,
        pointsPerLesson: pointsPerLesson ?? this.pointsPerLesson,
        pointsPerQuiz: pointsPerQuiz ?? this.pointsPerQuiz,
        bonusPerfect: bonusPerfect ?? this.bonusPerfect,
        leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
      );
}

/// Suivi d'une leçon par les inscrits.
class LessonStats {
  final int lessonId;
  final String title;
  final String type;
  final double completionRate;
  final int completed;
  final int watchSec;
  final double? quizScore;
  final bool lowCompletion;

  /// Inscrits actifs de la formation (même nombre pour chaque leçon).
  final int enrolled;
  const LessonStats(this.lessonId, this.title, this.type, this.completionRate, this.completed, this.watchSec, this.quizScore,
      this.lowCompletion, [this.enrolled = 0]);

  factory LessonStats.fromJson(Map j) => LessonStats(
        (j['lessonId'] as num?)?.toInt() ?? 0,
        '${j['title'] ?? ''}',
        '${j['lessonType'] ?? ''}',
        (j['completionRate'] as num?)?.toDouble() ?? 0,
        (j['completedCount'] as num?)?.toInt() ?? 0,
        (j['averageWatchTimeSec'] as num?)?.toInt() ?? 0,
        (j['averageQuizScore'] as num?)?.toDouble(),
        j['lowCompletionAlert'] == true,
        (j['enrolledCount'] as num?)?.toInt() ?? 0,
      );
}

/// Inscrit sans activité dans la formation depuis le seuil choisi.
class InactiveStudent {
  final int userId;
  final String name;
  final String? avatarUrl;
  final DateTime? lastActivity;
  final int daysInactive;
  const InactiveStudent(this.userId, this.name, this.avatarUrl, this.lastActivity, this.daysInactive);

  factory InactiveStudent.fromJson(Map j) => InactiveStudent(
        (j['userId'] as num?)?.toInt() ?? 0,
        '${j['name'] ?? ''}',
        j['avatarUrl'] as String?,
        DateTime.tryParse('${j['lastActivity'] ?? ''}'),
        (j['daysInactive'] as num?)?.toInt() ?? 0,
      );
}

/// Relances envoyées et élèves qui ont repris la formation depuis.
class RelaunchStats {
  final int sent;
  final int reactivated;
  final double? rate;
  const RelaunchStats(this.sent, this.reactivated, this.rate);
}

/// Semaine d'un syllabus proposé par WinAI.
class SyllabusWeek {
  final int week;
  final String title;
  final List<String> concepts;
  final List<String> activities;
  final int durationMinutes;
  final List<String> resources;

  const SyllabusWeek({
    required this.week,
    required this.title,
    this.concepts = const [],
    this.activities = const [],
    this.durationMinutes = 60,
    this.resources = const [],
  });

  static List<String> _l(Object? v) => (v is List ? v : const []).map((e) => '$e').toList();

  /// Le serveur relaie le JSON du générateur tel quel (snake_case).
  factory SyllabusWeek.fromJson(Map<String, dynamic> j) => SyllabusWeek(
        week: (j['week'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        concepts: _l(j['concepts']),
        activities: _l(j['activities']),
        durationMinutes: ((j['duration_minutes'] ?? j['durationMinutes']) as num?)?.toInt() ?? 60,
        resources: _l(j['suggested_resources'] ?? j['suggestedResources']),
      );

  Map<String, dynamic> toJson() => {
        'week': week,
        'title': title,
        'concepts': concepts,
        'activities': activities,
        'durationMinutes': durationMinutes,
        'suggestedResources': resources,
      };
}

/// Création et édition d'une formation par le professeur (lot 7), comme
/// TeacherFormations du site : informations, sections, leçons (vidéo,
/// article, fichier, contenu du catalogue), ordre, syllabus WinAI.
class CourseEditorService {
  CourseEditorService._();
  static final CourseEditorService instance = CourseEditorService._();
  final _api = ApiClient.instance;

  static const levels = ['debutant', 'intermediaire', 'avance'];

  /// Catégories du site (valeurs enregistrées telles quelles, en français).
  static const categories = [
    'Mathématiques',
    'Physique-Chimie',
    'Informatique',
    'Français',
    'Anglais',
    'Économie',
    'Sciences',
    'Histoire-Géo',
    'Autre',
  ];

  static const lessonTypes = ['video', 'article', 'file'];
  static const unlockRules = ['immediate', 'delay_days', 'min_score'];

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  static CourseEditorException error(Object e) {
    if (e is CourseEditorException) return e;
    final l = L10n.current;
    if (e is! DioException || e.response == null) return CourseEditorException(l.commonLoadError);
    final status = e.response!.statusCode;
    final body = e.response!.data;
    final map = body is Map ? body : null;
    final text = [map?['error'], map?['message'], map?['detail']]
        .firstWhere((v) => v is String && v.trim().isNotEmpty, orElse: () => null) as String?;
    final quota = status == 402 || status == 403 ? ChatbotService.quotaRefusalMessage(402, body) : null;
    return CourseEditorException(text?.trim() ?? quota ?? l.commonLoadError, status: status);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw error(e);
    }
  }

  Future<EditorCourse> course(int id) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$id');
        return EditorCourse.fromJson(_map(res.data));
      });

  /// Corps commun à la création et à la mise à jour.
  static Map<String, dynamic> _upsert({
    required String title,
    String? shortDescription,
    String? description,
    String? thumbnailUrl,
    String? previewVideoUrl,
    String? language,
    String? level,
    String? category,
    List<String>? tags,
    num? price,
    bool? isFree,
    List<String>? requirements,
    List<String>? objectives,
    bool? certificateEnabled,
  }) =>
      {
        'title': title.trim(),
        if (shortDescription != null) 'shortDescription': shortDescription.trim(),
        if (description != null) 'description': description.trim(),
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl.trim(),
        if (previewVideoUrl != null) 'previewVideoUrl': previewVideoUrl.trim(),
        if (language != null) 'language': language,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
        if (price != null) 'price': price,
        if (isFree != null) 'isFree': isFree,
        if (requirements != null) 'requirements': requirements,
        if (objectives != null) 'objectives': objectives,
        if (certificateEnabled != null) 'certificateEnabled': certificateEnabled,
      };

  /// Crée une formation en brouillon ; renvoie son identifiant.
  Future<int> create({
    required String title,
    String? shortDescription,
    String? description,
    String? level,
    String? category,
    String? language,
    num? price,
    bool? isFree,
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/teacher/courses',
            data: _upsert(
                title: title,
                shortDescription: shortDescription,
                description: description,
                level: level,
                category: category,
                language: language,
                price: price,
                isFree: isFree));
        return (_map(res.data)['id'] as num?)?.toInt() ?? 0;
      });

  Future<void> update(int id,
          {required String title,
          String? shortDescription,
          String? description,
          String? thumbnailUrl,
          String? previewVideoUrl,
          String? language,
          String? level,
          String? category,
          List<String>? tags,
          num? price,
          bool? isFree,
          List<String>? requirements,
          List<String>? objectives,
          bool? certificateEnabled}) =>
      _guard(() => _api.dio.put('/teacher/courses/$id',
          data: _upsert(
              title: title,
              shortDescription: shortDescription,
              description: description,
              thumbnailUrl: thumbnailUrl,
              previewVideoUrl: previewVideoUrl,
              language: language,
              level: level,
              category: category,
              tags: tags,
              price: price,
              isFree: isFree,
              requirements: requirements,
              objectives: objectives,
              certificateEnabled: certificateEnabled)));

  static Map<String, dynamic> _section(String title, String? description, String rule, int? delayDays, int? minScore) => {
        'title': title.trim(),
        'description': (description ?? '').trim().isEmpty ? null : description!.trim(),
        'position': 0,
        'unlockRule': unlockRules.contains(rule) ? rule : 'immediate',
        'delayDays': rule == 'delay_days' ? delayDays : null,
        'minScore': rule == 'min_score' ? minScore : null,
      };

  Future<void> addSection(int courseId, String title,
          {String? description, String rule = 'immediate', int? delayDays, int? minScore}) =>
      _guard(() => _api.dio.post('/teacher/courses/$courseId/sections',
          data: _section(title, description, rule, delayDays, minScore)));

  Future<void> updateSection(int courseId, int sectionId, String title,
          {String? description, String rule = 'immediate', int? delayDays, int? minScore}) =>
      _guard(() => _api.dio.put('/teacher/courses/$courseId/sections/$sectionId',
          data: _section(title, description, rule, delayDays, minScore)));

  Future<void> deleteSection(int courseId, int sectionId) =>
      _guard(() => _api.dio.delete('/teacher/courses/$courseId/sections/$sectionId'));

  /// Nouvel ordre : la position de chaque identifiant est son rang dans [ids].
  Future<void> reorderSections(int courseId, List<int> ids) => _guard(() => _api.dio.put(
      '/teacher/courses/$courseId/sections/reorder',
      data: [for (var i = 0; i < ids.length; i++) {'id': ids[i], 'position': i}]));

  Future<void> reorderLessons(int courseId, int sectionId, List<int> ids) => _guard(() => _api.dio.put(
      '/teacher/courses/$courseId/sections/$sectionId/lessons/reorder',
      data: [for (var i = 0; i < ids.length; i++) {'id': ids[i], 'position': i}]));

  static Map<String, dynamic> _lesson({
    required String title,
    required String type,
    String? description,
    String? videoUrl,
    int? videoDurationSec,
    String? articleContent,
    String? fileUrl,
    String? fileName,
    bool? isPreview,
    bool? isPublished,
  }) =>
      {
        'title': title.trim(),
        'lessonType': type,
        'description': (description ?? '').trim(),
        if (type == 'video') 'videoUrl': (videoUrl ?? '').trim(),
        if (type == 'video' && videoDurationSec != null) 'videoDurationSec': videoDurationSec,
        if (type == 'article') 'articleContent': articleContent ?? '',
        if (type == 'file') 'fileUrl': (fileUrl ?? '').trim(),
        if (type == 'file') 'fileName': (fileName ?? '').trim(),
        if (isPreview != null) 'isPreview': isPreview,
        if (isPublished != null) 'isPublished': isPublished,
      };

  Future<void> addLesson(int courseId, int sectionId,
          {required String title,
          required String type,
          String? description,
          String? videoUrl,
          int? videoDurationSec,
          String? articleContent,
          String? fileUrl,
          String? fileName,
          bool isPreview = false,
          bool isPublished = true}) =>
      _guard(() => _api.dio.post('/teacher/courses/$courseId/sections/$sectionId/lessons',
          data: _lesson(
              title: title,
              type: type,
              description: description,
              videoUrl: videoUrl,
              videoDurationSec: videoDurationSec,
              articleContent: articleContent,
              fileUrl: fileUrl,
              fileName: fileName,
              isPreview: isPreview,
              isPublished: isPublished)));

  Future<void> updateLesson(int courseId, int sectionId, int lessonId,
          {required String title,
          required String type,
          String? description,
          String? videoUrl,
          int? videoDurationSec,
          String? articleContent,
          String? fileUrl,
          String? fileName,
          bool? isPreview,
          bool? isPublished}) =>
      _guard(() => _api.dio.put('/teacher/courses/$courseId/sections/$sectionId/lessons/$lessonId',
          data: _lesson(
              title: title,
              type: type,
              description: description,
              videoUrl: videoUrl,
              videoDurationSec: videoDurationSec,
              articleContent: articleContent,
              fileUrl: fileUrl,
              fileName: fileName,
              isPreview: isPreview,
              isPublished: isPublished)));

  Future<void> deleteLesson(int courseId, int sectionId, int lessonId) =>
      _guard(() => _api.dio.delete('/teacher/courses/$courseId/sections/$sectionId/lessons/$lessonId'));

  /// Ajoute un contenu du catalogue déjà possédé comme leçon.
  Future<void> addLessonFromSubject(int courseId, int sectionId, int subjectId) => _guard(() =>
      _api.dio.post('/teacher/courses/$courseId/sections/$sectionId/lessons/from-subject', data: {'subjectId': subjectId}));

  /// Réglages de ludification d'une formation.
  Future<Gamification> gamification(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId/gamification');
        return Gamification.fromJson(_map(res.data));
      });

  Future<Gamification> saveGamification(int courseId, Gamification g) => _guard(() async {
        final res = await _api.dio.put('/teacher/courses/$courseId/gamification', data: g.toJson());
        return Gamification.fromJson(_map(res.data));
      });

  /// Classement des élèves (vrais noms, réservé au professeur).
  Future<List<(int, String, int)>> leaderboard(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId/leaderboard');
        final raw = res.data is Map ? (res.data as Map)['data'] : res.data;
        return (raw is List ? raw : const [])
            .whereType<Map>()
            .map((r) => ((r['rank'] as num?)?.toInt() ?? 0, '${r['name'] ?? ''}', (r['points'] as num?)?.toInt() ?? 0))
            .toList();
      });

  /// Suivi de chaque leçon : taux de complétion, temps de visionnage, score.
  Future<List<LessonStats>> lessonStats(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId/analytics/lessons');
        final raw = res.data is Map ? (res.data as Map)['data'] : res.data;
        return (raw is List ? raw : const []).whereType<Map>().map(LessonStats.fromJson).toList();
      });

  /// Seuil d'inactivité de la formation (jours) ; 7, valeur du serveur,
  /// tant que la fiche ne le renvoie pas.
  Future<int> inactivityThreshold(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId');
        final m = _map(res.data);
        final d = m['data'] is Map ? m['data'] as Map : m;
        return (d['inactivityThresholdDays'] as num?)?.toInt() ?? 7;
      });

  Future<int> setInactivityThreshold(int courseId, int days) => _guard(() async {
        final res = await _api.dio.put('/teacher/courses/$courseId/inactivity-threshold', data: {'days': days});
        return (_map(res.data)['inactivityThresholdDays'] as num?)?.toInt() ?? days;
      });

  /// Inscrits inactifs depuis le seuil, du plus ancien au plus récent.
  Future<List<InactiveStudent>> inactiveStudents(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId/inactive-students');
        final raw = res.data is Map ? (res.data as Map)['data'] : res.data;
        return (raw is List ? raw : const []).whereType<Map>().map(InactiveStudent.fromJson).toList();
      });

  /// Relance par un message rédigé par WinAI (débité sur l'aide à la
  /// publication ; message par défaut si WinAI n'est pas disponible),
  /// envoyé dans la messagerie de chaque élève. [userIds] vide : tous les
  /// inactifs. Renvoie le nombre d'élèves relancés et le message.
  Future<(int, String)> relaunch(int courseId, List<int> userIds) => _guard(() async {
        final res = await _api.dio.post('/teacher/courses/$courseId/relaunch-students', data: {'userIds': userIds});
        final m = _map(res.data);
        return ((m['sent'] as num?)?.toInt() ?? 0, '${m['message'] ?? ''}');
      });

  Future<RelaunchStats> relaunchStats(int courseId) => _guard(() async {
        final res = await _api.dio.get('/teacher/courses/$courseId/relaunch-stats');
        final m = _map(res.data);
        return RelaunchStats((m['totalSent'] as num?)?.toInt() ?? 0, (m['reactivatedCount'] as num?)?.toInt() ?? 0,
            (m['reactivationRate'] as num?)?.toDouble());
      });

  /// Soumet la formation à la validation de l'équipe (au moins une leçon
  /// publiée ; limite de formations publiées du plan vérifiée au serveur).
  Future<void> submit(int courseId) =>
      _guard(() => _api.dio.post('/teacher/courses/$courseId/submit', data: const {}));

  /// Syllabus proposé par WinAI (débité sur la consommation WinAI).
  Future<List<SyllabusWeek>> generateSyllabus({
    required String subject,
    required String level,
    required int weeks,
    List<String> objectives = const [],
    List<String> targetExams = const [],
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/teacher/courses/generate-syllabus', data: {
          'subject': subject.trim(),
          'level': level,
          'duration_weeks': weeks,
          'objectives': objectives,
          'target_exams': targetExams,
        });
        final raw = _map(res.data)['weeks'];
        return (raw is List ? raw : const []).whereType<Map<String, dynamic>>().map(SyllabusWeek.fromJson).toList();
      });

  /// Importe le syllabus : une section par semaine, une leçon article
  /// (non publiée) à compléter.
  Future<void> importSyllabus(int courseId, List<SyllabusWeek> weeks) => _guard(() => _api.dio
      .post('/teacher/courses/$courseId/import-syllabus', data: {'weeks': weeks.map((w) => w.toJson()).toList()}));
}
