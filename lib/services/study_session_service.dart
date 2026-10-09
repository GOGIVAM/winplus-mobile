import 'api_client.dart';

/// Module 32 (lot 8, décision 14.3) : portage mobile de la session d'étude
/// guidée (phases 2 et 3), déjà reconstruite côté web au lot 6
/// (frontend/src/pages/StudySession.tsx). Les 5 routes ci-dessous sont des
/// relais .NET existants (AIController.cs) vers le service Python WinAI :
/// aucune route n'est créée ou modifiée ici, uniquement consommée telle
/// quelle, exactement comme le fait le web.
class SessionSubjectRef {
  final int id;
  final String name;
  final String category;
  const SessionSubjectRef(
      {required this.id, required this.name, required this.category});

  factory SessionSubjectRef.fromJson(Map<String, dynamic> j) =>
      SessionSubjectRef(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
      );
}

class StudySessionData {
  final SessionSubjectRef subject;
  final int durationMinutes;
  final String level;
  final String briefing;
  final List<StudySessionPhase> phases;
  const StudySessionData({
    required this.subject,
    required this.durationMinutes,
    required this.level,
    required this.briefing,
    required this.phases,
  });

  factory StudySessionData.fromJson(Map<String, dynamic> j) =>
      StudySessionData(
        subject: SessionSubjectRef.fromJson(
            j['subject'] as Map<String, dynamic>? ?? const {}),
        durationMinutes: j['duration_minutes'] as int? ?? 25,
        level: j['level'] as String? ?? 'intermédiaire',
        briefing: j['briefing'] as String? ?? '',
        phases: (j['phases'] as List? ?? [])
            .map((e) => StudySessionPhase.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StudySessionPhase {
  final String id;
  final String label;
  final int durationPct;
  const StudySessionPhase(
      {required this.id, required this.label, required this.durationPct});

  factory StudySessionPhase.fromJson(Map<String, dynamic> j) =>
      StudySessionPhase(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        durationPct: j['duration_pct'] as int? ?? 0,
      );
}

class Phase2Question {
  final String question;
  final List<String> options;
  final String correct;
  final String explanation;
  const Phase2Question({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  factory Phase2Question.fromJson(Map<String, dynamic> j) => Phase2Question(
        question: j['question'] as String? ?? '',
        options:
            (j['options'] as List? ?? []).map((e) => e.toString()).toList(),
        correct: j['correct'] as String? ?? '',
        explanation: j['explanation'] as String? ?? '',
      );
}

class Phase3Summary {
  final String summary;
  final List<String> keypoints;
  final String performanceComment;
  final String subject;
  const Phase3Summary({
    required this.summary,
    required this.keypoints,
    required this.performanceComment,
    required this.subject,
  });

  factory Phase3Summary.fromJson(Map<String, dynamic> j) => Phase3Summary(
        summary: j['summary'] as String? ?? '',
        keypoints:
            (j['keypoints'] as List? ?? []).map((e) => e.toString()).toList(),
        performanceComment: j['performance_comment'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
      );
}

class StudySessionHistoryEntry {
  final int id;
  final String subject;
  final int duration;
  final double? score;
  final DateTime? completedAt;
  const StudySessionHistoryEntry({
    required this.id,
    required this.subject,
    required this.duration,
    this.score,
    this.completedAt,
  });

  factory StudySessionHistoryEntry.fromJson(Map<String, dynamic> j) =>
      StudySessionHistoryEntry(
        id: j['id'] as int? ?? 0,
        subject: j['subject'] as String? ?? '',
        duration: j['duration'] as int? ?? 0,
        score: (j['score'] as num?)?.toDouble(),
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}

class StudySessionService {
  StudySessionService._();
  static final StudySessionService instance = StudySessionService._();

  final _api = ApiClient.instance;

  /// Phase 1 (déjà existante avant le module 32) : briefing + plan de phases.
  Future<StudySessionData> generate({
    required int userId,
    required int subjectId,
    required int durationMinutes,
  }) async {
    final res = await _api.dio.post('/ai/study-session/generate', data: {
      'user_id': userId,
      'subject_id': subjectId,
      'duration_minutes': durationMinutes,
    });
    return StudySessionData.fromJson(res.data as Map<String, dynamic>);
  }

  /// Phase 2 : quiz progressif (3 questions). `correct` est le texte complet
  /// de l'option correcte, à comparer par égalité stricte  pas un index.
  Future<List<Phase2Question>> phase2Quiz({
    required int userId,
    required int subjectId,
  }) async {
    final res = await _api.dio.post('/ai/study-session/phase2/quiz', data: {
      'user_id': userId,
      'subject_id': subjectId,
    });
    final data = res.data as Map<String, dynamic>;
    final phase2 = data['phase2'] as Map<String, dynamic>? ?? const {};
    return (phase2['questions'] as List? ?? [])
        .map((e) => Phase2Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Phase 3 : synthèse WinAI à partir du score du quiz.
  Future<Phase3Summary> phase3Summary({
    required int userId,
    required int subjectId,
    double? score,
  }) async {
    final res = await _api.dio.post('/ai/study-session/phase3/summary', data: {
      'user_id': userId,
      'subject_id': subjectId,
      if (score != null) 'score': score,
    });
    final data = res.data as Map<String, dynamic>;
    return Phase3Summary.fromJson(
        data['phase3'] as Map<String, dynamic>? ?? const {});
  }

  /// Clôture non bloquante : un échec ici ne doit jamais empêcher
  /// l'utilisateur de terminer sa session (même comportement que le web).
  Future<void> complete({
    required int userId,
    required int subjectId,
    required int durationMinutes,
    double? score,
    List<String>? keyPoints,
  }) async {
    try {
      await _api.dio.post('/ai/study-session/complete', data: {
        'user_id': userId,
        'subject_id': subjectId,
        'duration_minutes': durationMinutes,
        if (score != null) 'score': score,
        'key_points': keyPoints ?? [],
      });
    } catch (_) {
      // Non bloquant, parité avec StudySession.tsx (finishSession()).
    }
  }

  Future<List<StudySessionHistoryEntry>> history() async {
    final res = await _api.dio.get('/ai/study-session/history');
    final list = res.data as List? ?? [];
    return list
        .map((e) =>
            StudySessionHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
