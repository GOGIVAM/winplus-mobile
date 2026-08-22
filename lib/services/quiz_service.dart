import 'api_client.dart';
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
    final correct = j['correctAnswerIndex'] as int? ??
        j['correctAnswer'] as int? ?? 0;
    return ApiQuizQuestion(
      id: j['id'] as int? ?? 0,
      questionText: j['questionText'] as String? ?? j['question'] as String? ?? '',
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

  Future<List<ApiQuiz>> getAll({int page = 1, int pageSize = 20}) async {
    final res = await _api.dio.get('/quizzes',
        queryParameters: {'page': page, 'pageSize': pageSize});
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiQuiz.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final res = await _api.dio.post('/quizzes/$quizId/attempt', data: {
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
}
