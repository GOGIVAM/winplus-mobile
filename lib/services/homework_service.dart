import 'package:dio/dio.dart';

import 'api_client.dart';

/// Devoir d'un professeur pour une classe de l'élève (GET /student/assignments).
class ApiStudentAssignment {
  final int id;
  final String title;
  final String? statement;
  final num maxScore;
  final DateTime? dueDate;
  final String? className;
  final bool submitted;
  final String? subject;

  /// Devoir sous forme de quiz : il se fait dans le lecteur de quiz.
  final int? quizId;

  /// Note, une fois la correction validée par le professeur.
  final num? myScore;
  final String? myComment;

  const ApiStudentAssignment({
    required this.id,
    required this.title,
    this.statement,
    required this.maxScore,
    this.dueDate,
    this.className,
    required this.submitted,
    this.subject,
    this.quizId,
    this.myScore,
    this.myComment,
  });

  factory ApiStudentAssignment.fromJson(Map<String, dynamic> j) => ApiStudentAssignment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        statement: j['statementText'] as String?,
        maxScore: (j['maxScore'] as num?) ?? 20,
        dueDate: DateTime.tryParse(j['dueDate']?.toString() ?? '')?.toLocal(),
        className: j['teacherClassName'] as String?,
        submitted: j['alreadySubmitted'] == true,
        subject: (j['subjectName'] ?? j['subject']) as String?,
        quizId: (j['quizId'] as num?)?.toInt(),
        myScore: j['myScore'] as num?,
        myComment: j['myComment'] as String?,
      );

  bool get graded => myScore != null;
  bool get late => !submitted && dueDate != null && dueDate!.isBefore(DateTime.now());
}

/// Devoir donné par l'établissement à un groupe de l'élève : toujours un quiz
/// (GET /institution/homework/mine).
class ApiInstitutionHomework {
  final int id;
  final String title;
  final String? instructions;
  final DateTime? dueDate;
  final int quizId;
  final String? groupName;
  final String? subject;

  /// done, pending ou missing.
  final String status;
  final num? myScore;

  const ApiInstitutionHomework({
    required this.id,
    required this.title,
    this.instructions,
    this.dueDate,
    required this.quizId,
    this.groupName,
    this.subject,
    required this.status,
    this.myScore,
  });

  factory ApiInstitutionHomework.fromJson(Map<String, dynamic> j) => ApiInstitutionHomework(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        instructions: j['instructions'] as String?,
        dueDate: DateTime.tryParse(j['dueDate']?.toString() ?? '')?.toLocal(),
        quizId: (j['quizId'] as num?)?.toInt() ?? 0,
        groupName: j['groupName'] as String?,
        subject: j['quizSubject'] as String?,
        status: j['status']?.toString() ?? 'pending',
        myScore: j['myScore'] as num?,
      );
}

/// Examen blanc chronométré de l'établissement (GET /institution/mock-exams/mine).
class ApiMockExam {
  final int id;
  final String title;
  final DateTime opensAt;
  final DateTime closesAt;
  final int durationMinutes;
  final int quizId;
  final String? subject;

  /// upcoming, open, submitted ou missed.
  final String status;
  final bool published;
  final num? score;
  final int? rank;
  final int? total;
  final num? average;

  const ApiMockExam({
    required this.id,
    required this.title,
    required this.opensAt,
    required this.closesAt,
    required this.durationMinutes,
    required this.quizId,
    this.subject,
    required this.status,
    required this.published,
    this.score,
    this.rank,
    this.total,
    this.average,
  });

  factory ApiMockExam.fromJson(Map<String, dynamic> j) {
    final opens = DateTime.tryParse(j['opensAt']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    return ApiMockExam(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title']?.toString() ?? '',
      opensAt: opens,
      closesAt: DateTime.tryParse(j['closesAt']?.toString() ?? '')?.toLocal() ?? opens,
      durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 60,
      quizId: (j['quizId'] as num?)?.toInt() ?? 0,
      subject: j['subject'] as String?,
      status: j['status']?.toString() ?? 'upcoming',
      published: j['published'] == true,
      score: j['score'] as num?,
      rank: (j['rank'] as num?)?.toInt(),
      total: (j['total'] as num?)?.toInt(),
      average: j['average'] as num?,
    );
  }

  /// Temps de composition : la durée, ou moins si l'examen ferme avant.
  int remainingSeconds([DateTime? now]) {
    final left = closesAt.difference(now ?? DateTime.now()).inSeconds;
    final full = durationMinutes * 60;
    return left < full ? (left < 0 ? 0 : left) : full;
  }
}

/// Copie refusée par le serveur (devoir fermé, déjà rendu…), avec son message.
class HomeworkSubmitException implements Exception {
  final String? message;
  const HomeworkSubmitException(this.message);
}

/// « Mes devoirs » de l'élève, comme la page /mes-devoirs du site.
class HomeworkService {
  HomeworkService._();
  static final HomeworkService instance = HomeworkService._();
  final _api = ApiClient.instance;

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    return raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];
  }

  Future<List<ApiStudentAssignment>> assignments() async {
    final res = await _api.dio.get('/student/assignments');
    return _list(res.data).map(ApiStudentAssignment.fromJson).toList();
  }

  /// Rendu d'une copie écrite.
  Future<void> submitAssignment(int id, String content) async {
    try {
      await _api.dio.post('/student/assignments/$id/submit', data: {'content': content});
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        throw HomeworkSubmitException(data is Map ? data['error']?.toString() : null);
      }
      rethrow;
    }
  }

  Future<List<ApiInstitutionHomework>> institutionHomework() async {
    final res = await _api.dio.get('/institution/homework/mine');
    return _list(res.data).map(ApiInstitutionHomework.fromJson).toList();
  }

  Future<List<ApiMockExam>> mockExams() async {
    final res = await _api.dio.get('/institution/mock-exams/mine');
    return _list(res.data).map(ApiMockExam.fromJson).toList();
  }
}
