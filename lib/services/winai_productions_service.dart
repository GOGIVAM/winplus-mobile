import 'package:dio/dio.dart';

import 'api_client.dart';
import 'connectivity_service.dart';
import 'winai_sources_service.dart';
import 'winai_studio_service.dart';

/// Une fiche recto verso gardée par le serveur.
typedef WinAICard = ({String front, String back, String? hint});

/// Paquet de fiches recto verso, ou résumé à écouter, produit par l'atelier
/// et gardé par le serveur. Une liste ne porte ni les fiches ni le texte.
class WinAIProduction {
  final int id;
  final String title;
  final String subject;
  final String topic;
  final int cardCount;
  final List<WinAICard> cards;
  final String script;
  final int estimatedSeconds;
  final List<WinAICitation> citations;

  const WinAIProduction({
    required this.id,
    required this.title,
    this.subject = '',
    this.topic = '',
    this.cardCount = 0,
    this.cards = const [],
    this.script = '',
    this.estimatedSeconds = 0,
    this.citations = const [],
  });

  factory WinAIProduction.fromJson(Map<String, dynamic> j) {
    String str(Object? v) => v is String ? v.trim() : '';
    int number(Object? v) => v is num ? v.toInt() : 0;
    final cards = <WinAICard>[
      for (final c in (j['cards'] as List? ?? const []).whereType<Map>())
        if (str(c['front']).isNotEmpty && str(c['back']).isNotEmpty)
          (
            front: str(c['front']),
            back: str(c['back']),
            hint: str(c['hint']).isEmpty ? null : str(c['hint'])
          ),
    ];
    return WinAIProduction(
      id: number(j['id']),
      title: str(j['title']),
      subject: str(j['subject']),
      topic: str(j['topic']),
      cardCount: cards.isNotEmpty ? cards.length : number(j['cardCount']),
      cards: cards,
      script: str(j['script']),
      estimatedSeconds: number(j['estimatedSeconds']),
      citations: [
        for (final s in (j['sources'] as List? ?? const []).whereType<Map>())
          WinAICitation.fromJson(Map<String, dynamic>.from(s)),
      ],
    );
  }
}

/// Synthèse rédigée par WinAI à partir de résultats réels : bilan de la
/// semaine d'un enfant, synthèse d'une classe.
class WinAISynthesis {
  final String title;
  final String text;
  const WinAISynthesis({required this.title, required this.text});
}

/// Demande d'une épreuve complète (réglages du professeur).
typedef WinAIExamRequest = ({
  String subject,
  String topic,
  String level,
  String examType,
  int durationMinutes,
  int totalPoints,
  int exercises,
});

class WinAIExamQuestion {
  final String number, statement, answer, scoringGuide;
  final double points;
  const WinAIExamQuestion({
    required this.number,
    required this.statement,
    required this.points,
    this.answer = '',
    this.scoringGuide = '',
  });
}

class WinAIExamExercise {
  final String title, context;
  final double points;
  final List<WinAIExamQuestion> questions;
  const WinAIExamExercise({
    required this.title,
    required this.points,
    this.context = '',
    this.questions = const [],
  });
}

/// Épreuve composée par WinAI pour un professeur : sujet, barème, corrigé.
/// Une liste ne porte pas les exercices.
class WinAIExam {
  final int id;
  final String title, subject, topic, level, examType, instructions;
  final int durationMinutes;
  final double totalPoints;
  final List<WinAIExamExercise> exercises;

  const WinAIExam({
    required this.id,
    required this.title,
    this.subject = '',
    this.topic = '',
    this.level = '',
    this.examType = '',
    this.instructions = '',
    this.durationMinutes = 0,
    this.totalPoints = 0,
    this.exercises = const [],
  });

  factory WinAIExam.fromJson(Map<String, dynamic> j) {
    String str(Object? v) => v is String ? v.trim() : (v is num ? '$v' : '');
    double dbl(Object? v) => v is num ? v.toDouble() : 0;
    return WinAIExam(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: str(j['title']),
      subject: str(j['subject']),
      topic: str(j['topic']),
      level: str(j['level']),
      examType: str(j['examType']),
      instructions: str(j['instructions']),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
      totalPoints: dbl(j['totalPoints']),
      exercises: [
        for (final e in (j['exercises'] as List? ?? const []).whereType<Map>())
          WinAIExamExercise(
            title: str(e['title']),
            context: str(e['context']),
            points: dbl(e['points']),
            questions: [
              for (final q
                  in (e['questions'] as List? ?? const []).whereType<Map>())
                WinAIExamQuestion(
                  number: str(q['number']),
                  statement: str(q['statement']),
                  points: dbl(q['points']),
                  answer: str(q['answer']),
                  scoringGuide: str(q['scoringGuide']),
                ),
            ],
          ),
      ],
    );
  }
}

/// Productions de l'atelier WinAI gardées par le serveur.
///
///  - fiches recto verso : POST/GET/DELETE /winai/flashcards ;
///  - résumé à écouter : POST/GET/DELETE /winai/resume-audio (un texte parlé,
///    lu par la voix du téléphone : aucun fichier audio) ;
///  - bilan de la semaine : POST /parent/children/{id}/bilan-semaine ;
///  - synthèse de classe : POST /institution/groups/{id}/synthese ;
///  - épreuve complète du professeur : POST/GET/DELETE /teacher/epreuves.
///
/// Les refus sont levés en [WinAiStudioException] avec la phrase du serveur.
class WinAiProductionsService {
  WinAiProductionsService._();
  static final WinAiProductionsService instance = WinAiProductionsService._();

  final _api = ApiClient.instance;

  /// Le serveur ne connaît pas (encore) la route : l'atelier se rabat sur la
  /// génération par la discussion, et les listes restent vides.
  static bool routeMissing(WinAiStudioException e) =>
      e.status == 404 || e.status == 405;

  Future<T> _guard<T>(Future<T> Function() call) async {
    if (!ConnectivityService.instance.isOnline) {
      throw WinAiStudioException(OfflineActionException().message);
    }
    try {
      return await call();
    } catch (e) {
      throw WinAiStudioService.refusal(e);
    }
  }

  static Map<String, dynamic> _data(Object? body) {
    final map = body is Map ? body : const {};
    final data = map['data'];
    return Map<String, dynamic>.from(data is Map ? data : map);
  }

  static List<WinAIProduction> _list(Object? body) {
    final raw = body is Map ? (body['data'] ?? body['items']) : body;
    return [
      for (final e in (raw is List ? raw : const []).whereType<Map>())
        WinAIProduction.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  Map<String, dynamic> _request(
          String subject, String topic, List<WinAISourceRef> sources) =>
      {
        if (subject.isNotEmpty) 'subject': subject,
        if (topic.isNotEmpty) 'topic': topic,
        if (sources.isNotEmpty)
          'sources': sources.map((r) => r.toJson()).toList(),
      };

  Future<WinAIProduction> generateFlashcards({
    String subject = '',
    String topic = '',
    List<WinAISourceRef> sources = const [],
  }) =>
      _guard(() async {
        final res = await _api.dio
            .post('/winai/flashcards', data: _request(subject, topic, sources));
        return WinAIProduction.fromJson(_data(res.data));
      });

  Future<WinAIProduction> generateAudioSummary({
    String subject = '',
    String topic = '',
    bool long = false,
    List<WinAISourceRef> sources = const [],
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/winai/resume-audio', data: {
          ..._request(subject, topic, sources),
          'duree': long ? 'longue' : 'courte',
        });
        return WinAIProduction.fromJson(_data(res.data));
      });

  /// Listes pour « Mes créations » : vides tant que le serveur ne connaît
  /// pas la route.
  Future<List<WinAIProduction>> _listOf(String path) async {
    try {
      return await _guard(() async => _list((await _api.dio.get(path)).data));
    } on WinAiStudioException catch (e) {
      if (routeMissing(e)) return const [];
      rethrow;
    }
  }

  Future<List<WinAIProduction>> flashcardDecks() => _listOf('/winai/flashcards');
  Future<List<WinAIProduction>> audioSummaries() =>
      _listOf('/winai/resume-audio');

  Future<WinAIProduction> flashcardDeck(int id) => _guard(() async =>
      WinAIProduction.fromJson(
          _data((await _api.dio.get('/winai/flashcards/$id')).data)));

  Future<WinAIProduction> audioSummary(int id) => _guard(() async =>
      WinAIProduction.fromJson(
          _data((await _api.dio.get('/winai/resume-audio/$id')).data)));

  Future<void> deleteFlashcardDeck(int id) =>
      _guard(() async => _api.dio.delete('/winai/flashcards/$id'));

  Future<void> deleteAudioSummary(int id) =>
      _guard(() async => _api.dio.delete('/winai/resume-audio/$id'));

  static WinAISynthesis _synthesis(Object? body) {
    final d = _data(body);
    String str(Object? v) => v is String ? v.trim() : '';
    return WinAISynthesis(title: str(d['title']), text: str(d['text']));
  }

  /// Épreuve complète : sujet, barème et corrigé. La génération dure 30 à
  /// 50 secondes, d'où le délai de réponse allongé pour cet appel.
  Future<WinAIExam> generateExam(WinAIExamRequest r,
          {List<WinAISourceRef> sources = const []}) =>
      _guard(() async {
        final res = await _api.dio.post('/teacher/epreuves',
            data: {
              ..._request(r.subject, r.topic, sources),
              if (r.level.isNotEmpty) 'level': r.level,
              'examType': r.examType,
              'durationMinutes': r.durationMinutes,
              'totalPoints': r.totalPoints,
              'exercises': r.exercises,
            },
            options: Options(receiveTimeout: const Duration(seconds: 120)));
        return WinAIExam.fromJson(_data(res.data));
      });

  Future<List<WinAIExam>> exams() => _guard(() async {
        final body = (await _api.dio.get('/teacher/epreuves')).data;
        final raw = body is Map ? (body['data'] ?? body['items']) : body;
        return [
          for (final e in (raw is List ? raw : const []).whereType<Map>())
            WinAIExam.fromJson(Map<String, dynamic>.from(e)),
        ];
      });

  Future<WinAIExam> exam(int id) => _guard(() async => WinAIExam.fromJson(
      _data((await _api.dio.get('/teacher/epreuves/$id')).data)));

  Future<void> deleteExam(int id) =>
      _guard(() async => _api.dio.delete('/teacher/epreuves/$id'));

  /// Bilan de la semaine d'un enfant, pour son parent.
  Future<WinAISynthesis> childWeekReport(int childId) => _guard(() async =>
      _synthesis((await _api.dio
              .post('/parent/children/$childId/bilan-semaine'))
          .data));

  /// Synthèse d'une classe, pour l'établissement.
  Future<WinAISynthesis> groupSummary(int groupId) => _guard(() async =>
      _synthesis(
          (await _api.dio.post('/institution/groups/$groupId/synthese')).data));
}
