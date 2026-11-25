import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';
import 'chatbot_service.dart';
import 'quiz_service.dart';

/// Fiche de révision (RevisionDto du serveur). Une fiche générée par WinAI
/// porte son texte en markdown dans [content] ; une fiche déposée par un
/// professeur peut avoir un PDF ([hasDocument], lu par [WinAiStudioService.document]).
class StudioSheet {
  final int id;
  final String title;
  final String? description;
  final String subject;
  final String topic;
  final String? difficulty;
  final String? content;
  final String? documentUrl;
  final int durationMinutes;
  final bool isAiGenerated;
  final bool hidden;
  final DateTime? createdAt;

  const StudioSheet({
    required this.id,
    required this.title,
    this.description,
    this.subject = '',
    this.topic = '',
    this.difficulty,
    this.content,
    this.documentUrl,
    this.durationMinutes = 0,
    this.isAiGenerated = false,
    this.hidden = false,
    this.createdAt,
  });

  bool get hasDocument => (documentUrl ?? '').trim().isNotEmpty;

  factory StudioSheet.fromJson(Map<String, dynamic> j) => StudioSheet(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        subject: j['subject']?.toString() ?? '',
        topic: j['topic']?.toString() ?? '',
        difficulty: j['difficulty'] as String?,
        content: j['content'] as String?,
        documentUrl: j['documentUrl'] as String?,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        isAiGenerated: j['isAIGenerated'] == true || j['isAiGenerated'] == true,
        hidden: j['hiddenFromList'] == true,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
      );
}

/// Quiz généré (QuizDto du serveur), pour la liste « Mes quiz WinAI ».
/// [id] se relit avec QuizService.getById(id).toQuiz() pour QuizActiveScreen ;
/// la réponse de [WinAiStudioService.generateQuiz] contient déjà les questions.
class StudioQuiz {
  final int id;
  final String title;
  final String subject;
  final String difficulty;
  final int questionsCount;
  final int? durationMinutes;
  final int totalAttempts;
  final num? averageScore;
  final bool hidden;
  final DateTime? createdAt;

  const StudioQuiz({
    required this.id,
    required this.title,
    this.subject = '',
    this.difficulty = '',
    this.questionsCount = 0,
    this.durationMinutes,
    this.totalAttempts = 0,
    this.averageScore,
    this.hidden = false,
    this.createdAt,
  });

  factory StudioQuiz.fromJson(Map<String, dynamic> j) => StudioQuiz(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        subject: j['subject']?.toString() ?? '',
        difficulty: j['difficulty']?.toString() ?? '',
        questionsCount: (j['questionsCount'] as num?)?.toInt() ??
            ((j['questions'] as List?)?.length ?? 0),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt(),
        totalAttempts: (j['totalAttempts'] as num?)?.toInt() ?? 0,
        averageScore: j['averageScore'] as num?,
        hidden: j['hiddenFromList'] == true,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
      );
}

/// Quiz tout juste généré : le résumé pour la liste et le quiz jouable.
class GeneratedQuiz {
  final StudioQuiz summary;
  final ApiQuiz quiz;
  const GeneratedQuiz(this.summary, this.quiz);
}

/// Refus ou échec d'une génération, avec un message prêt à afficher.
class WinAiStudioException implements Exception {
  final String message;

  /// ai_quota_exceeded, feature_not_in_plan, ai_quota_unavailable, ou null.
  final String? code;
  final int? status;
  const WinAiStudioException(this.message, {this.code, this.status});

  /// Limite atteinte ou fonction hors du plan : l'écran peut proposer
  /// l'abonnement plutôt que « Réessayer ».
  bool get isQuota => status == 402 || status == 403;

  @override
  String toString() => message;
}

/// Atelier WinAI, étape 3 : générer un quiz ou une fiche de révision,
/// lister ce qui a été généré, lire une fiche.
///
/// POST /quizzes/me/generate et POST /revisions/me/generate prennent
/// {subject, topic, difficulty: easy|medium|hard} ; une matière absente
/// laisse le serveur choisir la plus faible de l'élève.
class WinAiStudioService {
  WinAiStudioService._();
  static final WinAiStudioService instance = WinAiStudioService._();
  final _api = ApiClient.instance;

  static const difficulties = ['easy', 'medium', 'hard'];

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? (body['data'] ?? body['items']) : body;
    final list = raw is Map ? raw['items'] : raw;
    return (list is List ? list : const []).whereType<Map<String, dynamic>>().toList();
  }

  /// Corps de la demande. [sources] (identifiants de l'atelier) n'est
  /// envoyé que s'il est fourni : le serveur l'ignore tant qu'il ne le
  /// prend pas en charge.
  static Map<String, dynamic> _request(String? subject, String? topic, String difficulty, List<Object>? sources) {
    final s = subject?.trim() ?? '';
    final t = topic?.trim() ?? '';
    return {
      if (s.isNotEmpty) 'subject': s,
      if (t.isNotEmpty) 'topic': t,
      'difficulty': difficulties.contains(difficulty) ? difficulty : 'medium',
      if (sources != null && sources.isNotEmpty) 'sources': sources,
    };
  }

  /// Message prêt à afficher pour une erreur d'appel WinAI.
  static WinAiStudioException refusal(Object error) {
    if (error is WinAiStudioException) return error;
    final l = L10n.current;
    if (error is! DioException) return WinAiStudioException(l.commonLoadError);
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final map = body is Map ? body : null;
    final code = map?['code']?.toString();
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final serverText = text(map?['error']) ?? text(map?['message']);
    if (status == null) return WinAiStudioException(l.commonLoadError);
    if (status == 402 || status == 403) {
      return WinAiStudioException(
        serverText ?? ChatbotService.quotaRefusalMessage(402, body) ?? l.svcWinaiLimit,
        code: code,
        status: status,
      );
    }
    if (status == 503) {
      return WinAiStudioException(
        serverText ?? ChatbotService.quotaRefusalMessage(status, body) ?? l.svcWinaiUnavailable,
        code: code,
        status: status,
      );
    }
    // 400 : pas assez de données pour choisir une matière (nouvel élève).
    return WinAiStudioException(serverText ?? l.commonLoadError, code: code, status: status);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw refusal(e);
    }
  }

  /// Génère un quiz. La réponse contient les questions (sans la bonne
  /// réponse, révélée à la soumission) : jouable tout de suite avec
  /// `quiz.toQuiz()`.
  Future<GeneratedQuiz> generateQuiz({
    String? subject,
    String? topic,
    String difficulty = 'medium',
    List<Object>? sources,
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/quizzes/me/generate', data: _request(subject, topic, difficulty, sources));
        final j = _map(res.data);
        return GeneratedQuiz(StudioQuiz.fromJson(j), ApiQuiz.fromJson(j));
      });

  /// Génère une fiche de révision (texte markdown dans `content`).
  Future<StudioSheet> generateRevisionSheet({
    String? subject,
    String? topic,
    String difficulty = 'medium',
    List<Object>? sources,
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/revisions/me/generate', data: _request(subject, topic, difficulty, sources));
        return StudioSheet.fromJson(_map(res.data));
      });

  /// Quiz générés par l'élève, les plus récents d'abord (ordre du serveur).
  Future<List<StudioQuiz>> generatedQuizzes({bool includeHidden = false, int page = 1, int pageSize = 50}) =>
      _guard(() async {
        final res = await _api.dio.get('/quizzes/me/generated',
            queryParameters: {'includeHidden': includeHidden, 'page': page, 'pageSize': pageSize});
        return _list(res.data).map(StudioQuiz.fromJson).toList();
      });

  /// Fiches générées par l'élève.
  Future<List<StudioSheet>> generatedSheets({bool includeHidden = false, int page = 1, int pageSize = 50}) =>
      _guard(() async {
        final res = await _api.dio.get('/revisions/me/generated',
            queryParameters: {'includeHidden': includeHidden, 'page': page, 'pageSize': pageSize});
        return _list(res.data).map(StudioSheet.fromJson).toList();
      });

  /// Fiche complète (GET /revisions/{id}), pour relire son contenu.
  Future<StudioSheet> sheet(int id) => _guard(() async {
        final res = await _api.dio.get('/revisions/$id');
        return StudioSheet.fromJson(_map(res.data));
      });

  /// PDF d'une fiche qui en a un (GET /revisions/{id}/document).
  Future<Uint8List> document(int id) => _guard(() async {
        final res = await _api.dio.get<List<int>>('/revisions/$id/document',
            options: Options(responseType: ResponseType.bytes));
        return Uint8List.fromList(res.data ?? const []);
      });

  /// Masque ou réaffiche un élément de la liste (POST /{id}/hide|unhide).
  Future<void> setQuizHidden(int id, bool hidden) =>
      _guard(() => _api.dio.post('/quizzes/$id/${hidden ? 'hide' : 'unhide'}'));

  Future<void> setSheetHidden(int id, bool hidden) =>
      _guard(() => _api.dio.post('/revisions/$id/${hidden ? 'hide' : 'unhide'}'));
}
