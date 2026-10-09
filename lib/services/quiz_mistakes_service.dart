import 'api_client.dart';

/// Questions ratées et quiz de révision (voir QuizMistakesController.cs
/// côté backend : GET/POST /api/quiz/mistakes, mêmes endpoints que le web
/// studentExtraService.getMistakes/getMistakeSubjects/resolveMistake).
/// Module 24 (lot 8, rattrapage 16.3) : remplace l'écran mobile 100%
/// simulé (3 questions fictives codées en dur).
class ApiQuizMistake {
  final int id;
  final int? quizId;
  final String? subject;
  final String question;
  final String? givenAnswer;
  final String? correctAnswer;
  final DateTime createdAt;
  final String? quizTitle;

  const ApiQuizMistake({
    required this.id,
    this.quizId,
    this.subject,
    required this.question,
    this.givenAnswer,
    this.correctAnswer,
    required this.createdAt,
    this.quizTitle,
  });

  factory ApiQuizMistake.fromJson(Map<String, dynamic> j) => ApiQuizMistake(
        id: j['id'] as int? ?? 0,
        quizId: j['quizId'] as int?,
        subject: j['subject'] as String?,
        question: j['question'] as String? ?? '',
        givenAnswer: j['givenAnswer'] as String?,
        correctAnswer: j['correctAnswer'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        quizTitle: j['quizTitle'] as String?,
      );
}

class ApiMistakeSubject {
  final String subject;
  final int count;
  const ApiMistakeSubject({required this.subject, required this.count});

  factory ApiMistakeSubject.fromJson(Map<String, dynamic> j) => ApiMistakeSubject(
        subject: j['subject'] as String? ?? '',
        count: j['count'] as int? ?? 0,
      );
}

class QuizMistakesService {
  QuizMistakesService._();
  static final QuizMistakesService instance = QuizMistakesService._();

  final _api = ApiClient.instance;

  Future<List<ApiQuizMistake>> getMistakes({String? subject}) async {
    final res = await _api.dio.get('/quiz/mistakes', queryParameters: {
      if (subject != null && subject != 'Toutes') 'subject': subject,
    });
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => ApiQuizMistake.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ApiMistakeSubject>> getSubjects() async {
    final res = await _api.dio.get('/quiz/mistakes/subjects');
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => ApiMistakeSubject.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> resolve(int id) async {
    await _api.dio.post('/quiz/mistakes/$id/resolve');
  }
}
