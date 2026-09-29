import 'api_client.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';
import 'outbox_service.dart';
import '../data/models.dart';

class ApiQuizQuestion {
  final int id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  const ApiQuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory ApiQuizQuestion.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] as List? ?? []).cast<String>();
    final correct =
        j['correctAnswerIndex'] as int? ?? j['correctAnswer'] as int? ?? 0;
    return ApiQuizQuestion(
      id: j['id'] as int? ?? 0,
      questionText:
          j['questionText'] as String? ?? j['question'] as String? ?? '',
      options: opts,
      correctAnswerIndex: correct,
      explanation: j['explanation'] as String?,
    );
  }
}

class ApiQuiz {
  final int id;
  final String title;
  final String? description;
  final String? subjectCategory;
  final int durationMinutes;
  final List<ApiQuizQuestion> questions;
  const ApiQuiz({
    required this.id,
    required this.title,
    this.description,
    this.subjectCategory,
    this.durationMinutes = 30,
    this.questions = const [],
  });

  factory ApiQuiz.fromJson(Map<String, dynamic> j) => ApiQuiz(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        subjectCategory: j['subjectCategory'] as String?,
        durationMinutes: j['durationMinutes'] as int? ?? 30,
        questions: (j['questions'] as List? ?? [])
            .map((q) => ApiQuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

extension ApiQuizToModel on ApiQuiz {
  Quiz toQuiz() => Quiz(
        id: id.toString(),
        title: title,
        subjectId: subjectCategory ?? 'general',
        durationMinutes: durationMinutes,
        questions: questions
            .map((q) => QuizQuestion(
                  q.questionText,
                  q.options,
                  q.correctAnswerIndex,
                  q.explanation ?? '',
                ))
            .toList(),
      );
}

class QuizAttemptResult {
  final int score;
  final int correct;
  final int total;
  final String? certificateUrl;
  const QuizAttemptResult({
    required this.score,
    required this.correct,
    required this.total,
    this.certificateUrl,
  });
}

class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  final _api = ApiClient.instance;

  /// Enregistre le rejeu des soumissions de quiz mises en file hors ligne
  /// à appeler une fois au démarrage (voir main.dart).
  static void registerOutboxHandler() {
    OutboxService.instance.registerHandler('quiz_submit', (payload) async {
      await QuizService.instance.submitAttempt(
        quizId: payload['quizId'] as int,
        answers: (payload['answers'] as List).map((a) => a as int?).toList(),
        durationSeconds: payload['durationSeconds'] as int,
      );
      return true;
    });
  }

  /// Liste des quiz  mise en cache (StudentDashboardBox).
  Future<List<ApiQuiz>> getAll({int page = 1, int pageSize = 20}) async {
    final result = await LocalCacheService.cachedFetch<List<ApiQuiz>>(
      box: LocalCacheService.studentDashboard,
      key: 'quizzes_p${page}_$pageSize',
      fetchLiveRaw: () async => (await _api.dio.get('/quizzes',
              queryParameters: {'page': page, 'pageSize': pageSize}))
          .data,
      parse: (raw) => ((raw as List?) ?? [])
          .map((e) => ApiQuiz.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.value;
  }

  Future<ApiQuiz> getById(int id) async {
    final res = await _api.dio.get('/quizzes/$id');
    return ApiQuiz.fromJson(res.data as Map<String, dynamic>);
  }

  Future<QuizAttemptResult> submitAttempt({
    required int quizId,
    required List<int?> answers,
    required int durationSeconds,
  }) async {
    final res = await _api.dio.post('/quizzes/$quizId/submit', data: {
      'answers': answers,
      'durationSeconds': durationSeconds,
    });
    final d = res.data as Map<String, dynamic>;
    return QuizAttemptResult(
      score: d['score'] as int? ?? 0,
      correct: d['correctAnswers'] as int? ?? 0,
      total: d['totalQuestions'] as int? ?? 0,
      certificateUrl: d['certificateUrl'] as String?,
    );
  }

  /// Soumet immédiatement si en ligne ; sinon met en file (OutboxService) et
  /// synchronise automatiquement au retour du réseau. Le résultat affiché à
  /// l'élève hors ligne est calculé localement (voir quiz_screen.dart)
  /// cet appel ne fait que garantir que le score atteigne le serveur.
  Future<void> submitAttemptQueueable({
    required int quizId,
    required List<int?> answers,
    required int durationSeconds,
  }) async {
    if (ConnectivityService.instance.isOnline) {
      try {
        await submitAttempt(
            quizId: quizId, answers: answers, durationSeconds: durationSeconds);
        return;
      } catch (_) {
        // Tombe en file ci-dessous  réseau signalé disponible mais
        // requête effectivement en échec (portail captif, coupure ponctuelle...).
      }
    }
    await OutboxService.instance.enqueue('quiz_submit', {
      'quizId': quizId,
      'answers': answers,
      'durationSeconds': durationSeconds,
    });
  }
}
