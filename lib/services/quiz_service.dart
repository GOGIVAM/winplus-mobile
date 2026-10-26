import 'package:dio/dio.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';
import 'outbox_service.dart';
import '../data/models.dart';

class ApiQuizQuestion {
  /// Identifiant serveur (texte : « q1 », « 3 »…).
  final String id;
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
    final opts = (j['options'] as List? ?? []).map((o) => '$o').toList();
    // Le serveur renvoie la bonne réponse en texte (l'option elle-même) ;
    // l'ancienne lecture « as int » levait une erreur sur chaque quiz réel.
    final raw = j['correctAnswerIndex'] ?? j['correctAnswer'];
    var correct = 0;
    if (raw is int) {
      correct = raw;
    } else if (raw is String) {
      final i = opts.indexWhere(
          (o) => o.trim().toLowerCase() == raw.trim().toLowerCase());
      correct = i >= 0 ? i : int.tryParse(raw) ?? 0;
    }
    return ApiQuizQuestion(
      id: '${j['id'] ?? ''}',
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
                  id: q.id,
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
      final quizId = payload['quizId'] as int;
      var items = (payload['items'] as List?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList();
      // Entrée mise en file avant la correction du 2026-10-26 (numéros de
      // réponse seuls) : on relit le quiz pour retrouver questions et options.
      if (items == null) {
        final quiz = (await QuizService.instance.getById(quizId)).toQuiz();
        final indexes =
            (payload['answers'] as List? ?? []).map((a) => a as int?).toList();
        items = answerItems(quiz, indexes);
      }
      await QuizService.instance.submitAttempt(
        quizId: quizId,
        items: items,
        durationSeconds: payload['durationSeconds'] as int? ?? 0,
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

  /// Réponses au format du serveur : { questionId, answer } où answer est le
  /// texte de l'option choisie (vide si la question est restée sans réponse).
  static List<Map<String, String>> answerItems(Quiz quiz, List<int?> answers) {
    final items = <Map<String, String>>[];
    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final idx = i < answers.length ? answers[i] : null;
      items.add({
        'questionId': q.id ?? '${i + 1}',
        'answer': idx != null && idx >= 0 && idx < q.options.length
            ? q.options[idx]
            : '',
      });
    }
    return items;
  }

  /// Envoi d'une tentative. Avant le 2026-10-26, le mobile envoyait une liste
  /// de numéros que le serveur refusait (400) : aucune tentative n'arrivait.
  Future<QuizAttemptResult> submitAttempt({
    required int quizId,
    required List<Map<String, String>> items,
    required int durationSeconds,
  }) async {
    final res = await _api.dio.post('/quizzes/$quizId/submit', data: {
      'answers': items,
      'timeSpentSeconds': durationSeconds,
    });
    final d = res.data as Map<String, dynamic>;
    return QuizAttemptResult(
      score: ((d['score'] ?? 0) as num).round(),
      correct: (d['correctAnswers'] as num?)?.toInt() ?? 0,
      total: (d['totalQuestions'] as num?)?.toInt() ?? 0,
      certificateUrl: d['certificateUrl'] as String?,
    );
  }

  /// Soumet immédiatement si en ligne ; sinon met en file (OutboxService) et
  /// synchronise automatiquement au retour du réseau. Le résultat affiché à
  /// l'élève hors ligne est calculé localement (voir quiz_screen.dart)
  /// cet appel ne fait que garantir que le score atteigne le serveur.
  Future<void> submitAttemptQueueable({
    required int quizId,
    required List<Map<String, String>> items,
    required int durationSeconds,
  }) async {
    if (ConnectivityService.instance.isOnline) {
      try {
        await submitAttempt(
            quizId: quizId, items: items, durationSeconds: durationSeconds);
        return;
      } on DioException catch (e) {
        // Refus du serveur (pause d'examen, quiz déjà répondu…) : le rejouer
        // plus tard ne changerait rien, on ne le met pas en file.
        final code = e.response?.statusCode;
        if (code != null && code >= 400 && code < 500) return;
      } catch (_) {
        // Tombe en file ci-dessous  réseau signalé disponible mais
        // requête effectivement en échec (portail captif, coupure ponctuelle...).
      }
    }
    await OutboxService.instance.enqueue('quiz_submit', {
      'quizId': quizId,
      'items': items,
      'durationSeconds': durationSeconds,
    });
  }
}
