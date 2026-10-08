import 'api_client.dart';

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
        downloads: j['downloadCount'] as int? ?? 0,
        rating: ((j['averageRating'] ?? 0) as num).toDouble(),
        revenue: j['revenue'] as int? ?? 0,
        type: j['category'] as String? ?? 'epreuve',
      );
}

class ApiSubmission {
  final int id;
  final String studentName;
  final String contentTitle;
  final String submittedAt;
  final bool corrected;
  final int? score;
  const ApiSubmission({
    required this.id,
    required this.studentName,
    required this.contentTitle,
    required this.submittedAt,
    required this.corrected,
    this.score,
  });

  factory ApiSubmission.fromJson(Map<String, dynamic> j) => ApiSubmission(
        id: j['id'] as int? ?? 0,
        studentName: j['studentName'] as String? ?? '',
        contentTitle: j['contentTitle'] as String? ?? '',
        submittedAt: j['submittedAt'] as String? ?? '',
        corrected: j['corrected'] as bool? ?? false,
        score: j['score'] as int?,
      );
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
    return n.isNotEmpty ? n : (email ?? 'Élève');
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
  Future<bool> createSession({
    required String title,
    required String date,
    String? link,
    int durationMinutes = 60,
    int? maxStudents,
  }) async {
    try {
      final startDate = DateTime.tryParse(date) ??
          DateTime.now().add(const Duration(days: 1));
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

  Future<List<ApiPublishedContent>> getMyContent() async {
    final res = await _api.dio.get('/teacher/contents/mine');
    final list = res.data as List? ?? [];
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

  Future<List<ApiSubmission>> getSubmissions() async {
    final res = await _api.dio.get('/teacher/corrections/pending');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw as Map<String, dynamic>?)?['items'] as List? ?? [];
    return list
        .map((e) => ApiSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Note une copie précise. Route réellement exposée par le backend :
  /// POST /api/corrections/{id} avec {note, comment, status} (contrat déjà
  /// utilisé par CorrectionQueue.tsx côté web)  PUT /teacher/corrections/pending
  /// n'a jamais existé côté .NET, cet appel échouait toujours en 404.
  Future<bool> correctSubmission(int submissionId, int score,
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
    final res = await _api.dio.get('/teacher/stats');
    final j = res.data as Map<String, dynamic>;
    return ApiTeacherStats(
      thisMonthRevenue: (j['thisMonthRevenue'] as num?)?.toInt() ?? 0,
      weeklyRevenue: (j['weeklyRevenue'] as List?)?.cast<int>() ?? [0, 0, 0, 0],
      activeStudents: j['activeStudents'] as int? ?? 0,
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
