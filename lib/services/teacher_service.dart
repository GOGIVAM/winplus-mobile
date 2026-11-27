import 'api_client.dart';
import '../l10n/l10n.dart';

class ApiPublishedContent {
  final int id;
  final String title;
  final String status;
  final int downloads;
  final double rating;
  final int revenue;
  final String type;
  const ApiPublishedContent({
    required this.id,
    required this.title,
    required this.status,
    required this.downloads,
    required this.rating,
    required this.revenue,
    required this.type,
  });

  factory ApiPublishedContent.fromJson(Map<String, dynamic> j) =>
      ApiPublishedContent(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'draft',
        // Noms du serveur (GET /teacher/contents/mine) : downloads, rating ;
        // les anciens noms restent lus.
        downloads: ((j['downloads'] ?? j['downloadCount'] ?? 0) as num).toInt(),
        rating: ((j['rating'] ?? j['averageRating'] ?? 0) as num).toDouble(),
        revenue: j['revenue'] as int? ?? 0,
        type: j['category'] as String? ?? 'epreuve',
      );
}

class ApiSubmission {
  final int id;
  final String studentName;
  /// Titre du devoir (champ assignment du serveur).
  final String contentTitle;
  /// Classe du devoir (champ subject du serveur, qui porte le niveau).
  final String? className;
  final DateTime? submittedAt;
  final int daysWaiting;
  final String status;
  final bool corrected;
  /// Note sur [maxScore] (barème du devoir : 20, ou 100 pour un quiz).
  final double? score;
  final double maxScore;
  final String? comment;
  final String? textContent;
  final String? fileUrl;
  final bool urgent;
  const ApiSubmission({
    required this.id,
    required this.studentName,
    required this.contentTitle,
    this.className,
    this.submittedAt,
    this.daysWaiting = 0,
    this.status = 'pending',
    required this.corrected,
    this.score,
    this.maxScore = 20,
    this.comment,
    this.textContent,
    this.fileUrl,
    this.urgent = false,
  });

  bool get isDraft => status == 'draft';

  /// Note ramenée sur 20 (décision du 26/11 : toute note d'élève sur 20).
  double? get score20 => score == null || maxScore <= 0 ? null : score! * 20 / maxScore;

  /// Le serveur écrit la date sans fuseau (ToString("O") d'une date UTC) :
  /// sans Z, elle serait lue comme une heure locale.
  static DateTime? _utc(Object? v) {
    final t = v?.toString() ?? '';
    if (t.isEmpty) return null;
    final hasZone = RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(t);
    return DateTime.tryParse(hasZone || !t.contains('T') ? t : '${t}Z');
  }

  static String? _text(Object? v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }

  factory ApiSubmission.fromJson(Map<String, dynamic> j) {
    final status = '${j['status'] ?? 'pending'}';
    return ApiSubmission(
      id: (j['id'] as num?)?.toInt() ?? 0,
      studentName: j['studentName'] as String? ?? '',
      // GET /teacher/corrections/pending : assignment (titre du devoir),
      // submittedDate, status ; les anciens noms restent lus.
      contentTitle: j['assignment'] as String? ?? j['contentTitle'] as String? ?? '',
      className: _text(j['subject']),
      submittedAt: _utc(j['submittedDate'] ?? j['submittedAt']),
      daysWaiting: (j['daysWaiting'] as num?)?.toInt() ?? 0,
      status: status,
      corrected: j['corrected'] as bool? ??
          const {'corrected', 'graded', 'returned', 'done'}.contains(status),
      score: (j['score'] as num?)?.toDouble(),
      maxScore: (j['maxScore'] as num?)?.toDouble() ?? 20,
      comment: _text(j['comment']),
      textContent: _text(j['textContent']),
      fileUrl: _text(j['fileUrl']),
      urgent: j['priority'] == 'high',
    );
  }
}

class ApiTeacherStats {
  final int thisMonthRevenue;
  final List<int> weeklyRevenue;
  final int activeStudents;
  const ApiTeacherStats({
    required this.thisMonthRevenue,
    required this.weeklyRevenue,
    required this.activeStudents,
  });
}

/// Module 12 : miroir de GET/POST /api/teacher/classes (TeacherClassesController).
/// `id` est un entier côté serveur  le typer en String ici (comme avant)
/// provoquait une CastError à l'exécution dès que ce service était appelé,
/// ce qui explique pourquoi getClasses() n'était jamais branché sur l'écran.
class ApiTeacherClass {
  final int id;
  final String name;
  final String? level;
  final String? academicYear;
  final String? description;
  final int studentCount;
  final bool isActive;
  final int? classAverage;
  final int pendingCount;
  const ApiTeacherClass({
    required this.id,
    required this.name,
    this.level,
    this.academicYear,
    this.description,
    required this.studentCount,
    required this.isActive,
    this.classAverage,
    required this.pendingCount,
  });

  factory ApiTeacherClass.fromJson(Map<String, dynamic> j) => ApiTeacherClass(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        level: j['level'] as String?,
        academicYear: j['academicYear'] as String?,
        description: j['description'] as String?,
        studentCount: j['studentCount'] as int? ?? 0,
        isActive: j['isActive'] as bool? ?? true,
        classAverage: j['classAverage'] as int?,
        pendingCount: j['pendingCount'] as int? ?? 0,
      );
}

/// Miroir de GET /api/teacher/classes/{id}/students.
class ApiClassStudent {
  final int studentId;
  final String? firstName, lastName, email;
  final String? level;
  final double? avgScore;
  const ApiClassStudent({
    required this.studentId,
    this.firstName,
    this.lastName,
    this.email,
    this.level,
    this.avgScore,
  });

  String get displayName {
    final n = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return n.isNotEmpty ? n : (email ?? L10n.current.roleStudent);
  }

  factory ApiClassStudent.fromJson(Map<String, dynamic> j) => ApiClassStudent(
        studentId: j['studentId'] as int? ?? 0,
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        email: j['email'] as String?,
        level: j['level'] as String?,
        avgScore: (j['avgScore'] as num?)?.toDouble(),
      );
}

/// Miroir de GET /api/teacher/assignments (AssignmentDto).
class ApiAssignment {
  final int id;
  final String title;
  final String? statementText;
  final String? rubricJson;
  final int? quizId;
  final num maxScore;
  final String? dueDate;
  final int teacherClassId;
  final int submissionCount;
  final int pendingCount;
  const ApiAssignment({
    required this.id,
    required this.title,
    this.statementText,
    this.rubricJson,
    this.quizId,
    required this.maxScore,
    this.dueDate,
    required this.teacherClassId,
    required this.submissionCount,
    required this.pendingCount,
  });

  factory ApiAssignment.fromJson(Map<String, dynamic> j) => ApiAssignment(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        statementText: j['statementText'] as String?,
        rubricJson: j['rubricJson'] as String?,
        quizId: j['quizId'] as int?,
        maxScore: (j['maxScore'] as num?) ?? 20,
        dueDate: j['dueDate'] as String?,
        teacherClassId: j['teacherClassId'] as int? ?? 0,
        submissionCount: j['submissionCount'] as int? ?? 0,
        pendingCount: j['pendingCount'] as int? ?? 0,
      );
}

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  final _api = ApiClient.instance;

  /// Crée une session d'enseignement (POST /api/sessions). `date` vient d'un
  /// champ texte libre (pas encore un vrai sélecteur date/heure côté écran) :
  /// on tente un parse ISO, sinon on programme demain à défaut plutôt que
  /// d'échouer silencieusement.
  /// GET /sessions/mine — séances du professeur entre [from] et [to]
  /// (calendrier du site). Une erreur remonte : l'écran affiche « réessayer »
  /// au lieu d'une liste vide trompeuse.
  /// Alertes de décrochage non traitées, toutes formations confondues, les
  /// plus récentes d'abord. Lève une erreur si le serveur ne répond pas.
  Future<List<ApiDropoutAlert>> getDropoutAlerts() async {
    final res = await _api.dio.get('/teacher/alertes-decrochage');
    final raw = res.data is Map ? (res.data as Map)['data'] : res.data;
    return (raw is List ? raw : const [])
        .whereType<Map<String, dynamic>>()
        .map(ApiDropoutAlert.fromJson)
        .toList();
  }

  /// Relance l'élève : le serveur lui envoie un message (rédigé par WinAI
  /// quand le plan le permet) et marque l'alerte traitée.
  Future<void> relaunchDropoutAlert(int id) async {
    await _api.dio.post('/teacher/alertes/$id/relancer');
  }

  Future<List<ApiTeachingSession>> getMySessions(
      {DateTime? from, DateTime? to}) async {
    final res = await _api.dio.get('/sessions/mine', queryParameters: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    final body = res.data;
    final list = body is Map ? body['data'] as List? ?? const [] : body as List? ?? const [];
    return [
      for (final e in list)
        if (e is Map) ApiTeachingSession.fromJson(Map<String, dynamic>.from(e)),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<bool> createSession({
    required String title,
    required String date,
    String? link,
    int durationMinutes = 60,
    int? maxStudents,
  }) async {
    try {
      // Date envoyée en UTC (Npgsql refuse une date sans fuseau : la
      // création échouait, audit du 27/11).
      final startDate = (DateTime.tryParse(date) ??
              DateTime.now().add(const Duration(days: 1)))
          .toUtc();
      await _api.dio.post('/sessions', data: {
        'title': title,
        'type': 'live',
        'startDate': startDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'maxParticipants': maxStudents,
        'externalLink': link,
        'isFree': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// « Démarrer un cours maintenant » (Cours en direct, G6) : séance en direct
  /// qui commence tout de suite, pour 60 minutes ; renvoie son identifiant
  /// pour ouvrir la salle aussitôt. Lève en cas de refus du serveur.
  Future<int> startLiveNow(String title) async {
    final res = await _api.dio.post('/sessions', data: {
      'title': title,
      'type': 'live',
      'startDate': DateTime.now().toUtc().toIso8601String(),
      'durationMinutes': 60,
      'isFree': true,
    });
    final body = res.data is Map ? res.data as Map : const {};
    final d = body['data'] is Map ? body['data'] as Map : body;
    final id = (d['id'] as num?)?.toInt();
    if (id == null) throw StateError('session sans identifiant');
    return id;
  }

  /// Statistiques réelles d'une publication (GET /teacher/contents/{id}/stats) :
  /// téléchargements, note, inscrits, ventes et revenus. `null` si
  /// indisponible.
  Future<ApiContentStats?> getContentStats(int contentId) async {
    try {
      final res = await _api.dio.get('/teacher/contents/$contentId/stats');
      final d = (res.data as Map<String, dynamic>?)?['data'];
      return d is Map<String, dynamic> ? ApiContentStats.fromJson(d) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ApiPublishedContent>> getMyContent() async {
    // Le serveur répond { data, counts } (lot 8 : seule une liste brute était
    // lue, l'appel échouait toujours : « Aucun contenu », « 0 publié »,
    // analyse de classe impossible et copies à corriger jamais comptées).
    final res = await _api.dio.get('/teacher/contents/mine');
    final body = res.data;
    final list = body is List
        ? body
        : body is Map
            ? (body['data'] ?? body['items']) as List? ?? const []
            : const [];
    return list
        .map((e) => ApiPublishedContent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> publishContent({
    required String title,
    required String type,
    required String subjectCategory,
    required String level,
    required int price,
    String? description,
  }) async {
    try {
      // Module 25 : `POST /teacher/contents` n'existe pas (ce préfixe ne sert
      // que la lecture et la modification des publications) : la soumission
      // échouait toujours. La création passe par POST /subjects
      // (SubjectCreateRequest : title, description, category, level, price ;
      // publication toujours décidée par l'administration). Category porte la
      // matière, comme Subject.Category ; le type de contenu n'a pas de champ
      // correspondant à la création et n'est donc pas transmis.
      await _api.dio.post('/subjects', data: {
        'title': title,
        'category': subjectCategory,
        'level': level,
        'price': price,
        if (description != null) 'description': description,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toutes les copies (filter=all) : sans ce paramètre, le serveur ne
  /// renvoie que les copies en attente et le filtre « Corrigé » restait vide.
  Future<List<ApiSubmission>> getSubmissions() async {
    final res = await _api.dio.get('/teacher/corrections/pending',
        queryParameters: {'filter': 'all'});
    final raw = res.data;
    // Le serveur répond { data: [...] } ; seule la clé items était lue, et
    // l'accueil annonçait toujours 0 copie à corriger (lot 8, Pixel).
    final map = raw is Map<String, dynamic> ? raw : null;
    final list = raw is List
        ? raw
        : (map?['data'] ?? map?['items']) as List? ?? [];
    return list
        .map((e) => ApiSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Note une copie précise. Route réellement exposée par le backend :
  /// POST /api/corrections/{id} avec {note, comment, status} (contrat déjà
  /// utilisé par CorrectionQueue.tsx côté web)  PUT /teacher/corrections/pending
  /// n'a jamais existé côté .NET, cet appel échouait toujours en 404.
  Future<bool> correctSubmission(int submissionId, num score,
      [String? feedback]) async {
    try {
      await _api.dio.post('/corrections/$submissionId', data: {
        'note': score,
        'comment': feedback,
        'status': 'submitted',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getRevenueSummary() async {
    try {
      final res = await _api.dio.get('/teacher/revenues');
      return res.data as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  /// Revenus catalogue par contenu (titre, ventes, revenu), même route que le
  /// web (RevenueOverview). Lot 2, Module 5 : appelait auparavant
  /// /teacher/revenue-share, qui renvoie la part du plan (un objet, pas une
  /// liste) : le transtypage échouait toujours et la section restait vide.
  /// Lève en cas d'échec : l'écran affiche une erreur, jamais une liste vide
  /// trompeuse.
  Future<List<Map<String, dynamic>>> getContentRevenue() async {
    final res = await _api.dio.get('/teacher/revenue/by-content',
        queryParameters: {'sort': 'revenue', 'dir': 'desc'});
    final body = res.data;
    final list = body is List ? body : (body is Map ? body['data'] as List? : null) ?? [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Part enseignant du plan d'abonnement actif (null si aucun plan).
  Future<({String? planName, double? teacherShare})> getRevenueShare() async {
    final res = await _api.dio.get('/teacher/revenue-share');
    final body = res.data;
    final d = body is Map ? (body['data'] as Map? ?? body) : const {};
    return (
      planName: d['planName'] as String?,
      teacherShare: (d['teacherShare'] as num?)?.toDouble(),
    );
  }

  Future<bool> deleteContent(int contentId) async {
    try {
      await _api.dio.delete('/teacher/contents/$contentId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ApiTeacherStats> getStats() async {
    // { data: { monthRevenue, activeStudents, … } } (audit du 27/11 : lu à
    // plat sous d'autres noms, le revenu du mois restait à 0 XAF).
    final res = await _api.dio.get('/teacher/stats');
    final body = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : const <String, dynamic>{};
    final j = body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body;
    final weekly = (j['weeklyRevenue'] as List?)?.map((e) => (e as num).toInt()).toList();
    return ApiTeacherStats(
      thisMonthRevenue: ((j['monthRevenue'] ?? j['thisMonthRevenue'] ?? 0) as num).toInt(),
      weeklyRevenue: weekly ?? [0, 0, 0, 0],
      activeStudents: (j['activeStudents'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Module 12 : classes (miroir strict de TeacherClassesController) ──────

  Future<List<ApiTeacherClass>> getClasses({bool includeInactive = false}) async {
    final res = await _api.dio.get('/teacher/classes',
        queryParameters: includeInactive ? {'includeInactive': true} : null);
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiTeacherClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lève en cas d'échec (ex: nom déjà utilisé) : l'écran doit afficher
  /// l'erreur réelle du serveur, jamais une réussite simulée.
  Future<ApiTeacherClass> createClass({
    required String name,
    required String level,
    required String academicYear,
    String? description,
  }) async {
    final res = await _api.dio.post('/teacher/classes', data: {
      'name': name,
      'level': level,
      'academicYear': academicYear,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    final body = res.data;
    final j = (body is Map && body['data'] is Map) ? body['data'] as Map<String, dynamic> : body as Map<String, dynamic>;
    // La création ne renvoie pas isActive/classAverage/pendingCount : valeurs
    // par défaut cohérentes pour une classe toute neuve.
    return ApiTeacherClass(
      id: j['id'] as int? ?? 0,
      name: j['name'] as String? ?? name,
      level: j['level'] as String?,
      academicYear: j['academicYear'] as String?,
      description: j['description'] as String?,
      studentCount: j['studentCount'] as int? ?? 0,
      isActive: true,
      classAverage: null,
      pendingCount: 0,
    );
  }

  /// Désactivation (archivage), pas une suppression  miroir du comportement serveur réel.
  Future<void> deactivateClass(int classId) async {
    await _api.dio.patch('/teacher/classes/$classId/deactivate');
  }

  Future<void> reactivateClass(int classId) async {
    await _api.dio.patch('/teacher/classes/$classId/deactivate',
        queryParameters: {'reactivate': true});
  }

  /// Suppression définitive  le serveur la refuse (400) si la classe a des
  /// élèves ; l'appelant doit alors proposer la désactivation à la place.
  Future<void> deleteClass(int classId) async {
    await _api.dio.delete('/teacher/classes/$classId');
  }

  Future<List<ApiClassStudent>> getClassStudents(int classId) async {
    final res = await _api.dio.get('/teacher/classes/$classId/students');
    final body = res.data;
    final list = body is List ? body : (body is Map ? body['data'] as List? : null) ?? [];
    return list.map((e) => ApiClassStudent.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ajoute un élève par email WinPlus (le serveur résout l'email en studentId).
  Future<void> addClassStudent(int classId, String email) async {
    await _api.dio.post('/teacher/classes/$classId/students', data: {'email': email});
  }

  Future<void> removeClassStudent(int classId, int studentId) async {
    await _api.dio.delete('/teacher/classes/$classId/students/$studentId');
  }

  // ── Module 12 : devoirs (miroir de AssignmentsController/StudentController) ──

  Future<List<ApiAssignment>> getAssignments() async {
    final res = await _api.dio.get('/teacher/assignments');
    final body = res.data;
    final list = body is List ? body : (body is Map ? body['data'] as List? : null) ?? [];
    return list.map((e) => ApiAssignment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Devoir libre (énoncé texte) assigné à une classe. L'assignation de
  /// quiz/épreuve du catalogue (Module 11) n'est pas reprise ici : elle
  /// suppose un écran de jeu de quiz mobile équivalent à QuizActive, hors
  /// périmètre de ce module (parité web déjà conséquente à elle seule).
  Future<ApiAssignment> createAssignment({
    required int teacherClassId,
    required String title,
    String? statementText,
    String? referenceAnswerText,
    DateTime? dueDate,
  }) async {
    final res = await _api.dio.post('/teacher/assignments', data: {
      'teacherClassId': teacherClassId,
      'title': title,
      if (statementText != null && statementText.isNotEmpty) 'statementText': statementText,
      if (referenceAnswerText != null && referenceAnswerText.isNotEmpty) 'referenceAnswerText': referenceAnswerText,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });
    final body = res.data;
    final j = (body is Map && body['data'] is Map) ? body['data'] as Map<String, dynamic> : body as Map<String, dynamic>;
    return ApiAssignment.fromJson(j);
  }
}

/// Statistiques d'une publication du professeur.
class ApiContentStats {
  final int downloads;
  final double rating;
  final int ratingCount;
  final int enrollments;
  final int sales;
  final double grossRevenue;
  final double? netRevenue;
  const ApiContentStats({
    required this.downloads,
    required this.rating,
    required this.ratingCount,
    required this.enrollments,
    required this.sales,
    required this.grossRevenue,
    this.netRevenue,
  });

  factory ApiContentStats.fromJson(Map<String, dynamic> j) => ApiContentStats(
        downloads: (j['downloads'] as num?)?.toInt() ?? 0,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        enrollments: (j['enrollments'] as num?)?.toInt() ?? 0,
        sales: (j['sales'] as num?)?.toInt() ?? 0,
        grossRevenue: (j['grossRevenue'] as num?)?.toDouble() ?? 0,
        netRevenue: (j['netRevenue'] as num?)?.toDouble(),
      );
}

/// Séance d'un professeur (TeachingSessionDto du serveur).
class ApiTeachingSession {
  final int id;
  final String title;
  final String? subject;
  final String? level;
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final String? externalLink;
  final String status;
  final int enrolledCount;

  /// live, recording ou correction : seule une séance live a une salle de
  /// visio WinPlus.
  final String type;

  const ApiTeachingSession({
    required this.id,
    required this.title,
    this.subject,
    this.level,
    required this.start,
    required this.end,
    required this.durationMinutes,
    this.externalLink,
    required this.status,
    this.enrolledCount = 0,
    this.type = 'live',
  });

  factory ApiTeachingSession.fromJson(Map<String, dynamic> j) {
    final start = DateTime.tryParse(j['startDate']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final minutes = (j['durationMinutes'] as num?)?.toInt() ?? 60;
    return ApiTeachingSession(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title']?.toString() ?? '',
      subject: j['subject'] as String?,
      level: j['level'] as String?,
      start: start,
      end: DateTime.tryParse(j['endDate']?.toString() ?? '')?.toLocal() ??
          start.add(Duration(minutes: minutes)),
      durationMinutes: minutes,
      externalLink: (j['externalLink'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['externalLink'] as String).trim(),
      status: j['status']?.toString() ?? '',
      enrolledCount: (j['enrolledCount'] as num?)?.toInt() ?? 0,
      type: j['type']?.toString().toLowerCase() ?? 'live',
    );
  }

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Salle de visio WinPlus, comme sur le site : séance en direct sans lien
  /// externe (Meet, Zoom…), non annulée.
  bool get hasWinPlusVisio => type == 'live' && externalLink == null && !isCancelled;
}

/// Alerte de décrochage d'un élève d'une formation du professeur
/// (GET /teacher/alertes-decrochage), non traitée.
class ApiDropoutAlert {
  final int id;
  final int courseId;
  final String courseTitle;
  final int studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String level;
  final List<String> signals;
  final DateTime? detectedAt;

  const ApiDropoutAlert({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.studentName,
    this.studentAvatarUrl,
    required this.level,
    required this.signals,
    this.detectedAt,
  });

  factory ApiDropoutAlert.fromJson(Map<String, dynamic> j) => ApiDropoutAlert(
        id: (j['id'] as num?)?.toInt() ?? 0,
        courseId: (j['courseId'] as num?)?.toInt() ?? 0,
        courseTitle: j['courseTitle']?.toString() ?? '',
        studentId: (j['studentUserId'] as num?)?.toInt() ?? 0,
        studentName: j['studentName']?.toString() ?? '',
        studentAvatarUrl: j['studentAvatarUrl'] as String?,
        level: j['niveau']?.toString() ?? '',
        signals: (j['signaux'] as List? ?? const []).map((e) => '$e').toList(),
        detectedAt: DateTime.tryParse(j['dateDetection']?.toString() ?? '')?.toLocal(),
      );
}
