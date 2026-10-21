import 'api_client.dart';
import '../l10n/l10n.dart';

/// Lot 9.6 (suivi 17.5) : support de séance généré par WinAI (cours, quiz,
/// exercices), parité web. Le tuteur génère (débité sur SON usage WinAI),
/// relit, modifie et partage ; les élèves de la séance consultent et
/// répondent ; le payeur consulte. Tout s'affiche dans l'application : aucun
/// téléchargement de fichier.

List<String> _strings(dynamic v) => (v as List? ?? []).map((e) => e.toString()).toList();

class MaterialQuizOption {
  String id;
  String text;
  MaterialQuizOption({required this.id, required this.text});
  factory MaterialQuizOption.fromJson(Map<String, dynamic> j) =>
      MaterialQuizOption(id: j['id']?.toString() ?? '', text: j['text']?.toString() ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class MaterialQuizQuestion {
  String id;
  String text;
  List<MaterialQuizOption> options;
  /// Null tant que l'élève n'a pas répondu, et toujours pour le payeur.
  String? correctOptionId;
  String? explanation;
  MaterialQuizQuestion({required this.id, required this.text, required this.options, this.correctOptionId, this.explanation});
  factory MaterialQuizQuestion.fromJson(Map<String, dynamic> j) => MaterialQuizQuestion(
        id: j['id']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        options: (j['options'] as List? ?? []).map((e) => MaterialQuizOption.fromJson(e as Map<String, dynamic>)).toList(),
        correctOptionId: j['correctOptionId'] as String?,
        explanation: j['explanation'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options.map((o) => o.toJson()).toList(),
        'correctOptionId': correctOptionId,
        'explanation': explanation,
      };
}

class MaterialExercise {
  String id;
  String title;
  String statement;
  String difficulty; // facile | moyen | difficile
  List<String> hints;
  /// Corrigé, null tant que l'élève n'a pas rendu ses réponses.
  String? solution;
  MaterialExercise({required this.id, required this.title, required this.statement, this.difficulty = 'moyen', this.hints = const [], this.solution});
  factory MaterialExercise.fromJson(Map<String, dynamic> j) => MaterialExercise(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        statement: j['statement']?.toString() ?? '',
        difficulty: j['difficulty']?.toString() ?? 'moyen',
        hints: _strings(j['hints']),
        solution: j['solution'] as String?,
      );
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'statement': statement, 'difficulty': difficulty, 'hints': hints, 'solution': solution};
}

class MaterialSection {
  String title;
  String content;
  String? example;
  MaterialSection({required this.title, required this.content, this.example});
  factory MaterialSection.fromJson(Map<String, dynamic> j) =>
      MaterialSection(title: j['title']?.toString() ?? '', content: j['content']?.toString() ?? '', example: j['example'] as String?);
  Map<String, dynamic> toJson() => {'title': title, 'content': content, 'example': example};
}

class SessionMaterialContent {
  String title;
  String? subject;
  String? level;
  List<String> objectives;
  String introduction;
  List<MaterialSection> sections;
  String summary;
  List<String> keyPoints;
  List<MaterialQuizQuestion> quiz;
  List<MaterialExercise> exercises;
  String? groupNote;

  SessionMaterialContent({
    required this.title,
    this.subject,
    this.level,
    this.objectives = const [],
    this.introduction = '',
    this.sections = const [],
    this.summary = '',
    this.keyPoints = const [],
    this.quiz = const [],
    this.exercises = const [],
    this.groupNote,
  });

  factory SessionMaterialContent.fromJson(Map<String, dynamic> j) {
    final course = j['course'] as Map<String, dynamic>? ?? const {};
    return SessionMaterialContent(
      title: j['title']?.toString() ?? '',
      subject: j['subject'] as String?,
      level: j['level'] as String?,
      objectives: _strings(j['objectives']),
      introduction: course['introduction']?.toString() ?? '',
      sections: (course['sections'] as List? ?? []).map((e) => MaterialSection.fromJson(e as Map<String, dynamic>)).toList(),
      summary: course['summary']?.toString() ?? '',
      keyPoints: _strings(course['keyPoints']),
      quiz: (j['quiz'] as List? ?? []).map((e) => MaterialQuizQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      exercises: (j['exercises'] as List? ?? []).map((e) => MaterialExercise.fromJson(e as Map<String, dynamic>)).toList(),
      groupNote: j['groupNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'level': level,
        'objectives': objectives,
        'course': {
          'introduction': introduction,
          'sections': sections.map((s) => s.toJson()).toList(),
          'summary': summary,
          'keyPoints': keyPoints,
        },
        'quiz': quiz.map((q) => q.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'groupNote': groupNote,
      };

  /// Copie profonde, pour éditer sans toucher la vue chargée.
  SessionMaterialContent copy() => SessionMaterialContent.fromJson(Map<String, dynamic>.from(toJson()));
}

class MaterialQuestionResult {
  final String questionId;
  final String? answer;
  final String? correctOptionId;
  final bool isCorrect;
  const MaterialQuestionResult({required this.questionId, this.answer, this.correctOptionId, this.isCorrect = false});
  factory MaterialQuestionResult.fromJson(Map<String, dynamic> j) => MaterialQuestionResult(
        questionId: j['questionId']?.toString() ?? '',
        answer: j['answer'] as String?,
        correctOptionId: j['correctOptionId'] as String?,
        isCorrect: j['isCorrect'] == true,
      );
}

class MaterialResult {
  final int studentUserId;
  final String? studentName;
  final int materialVersion;
  final int quizScore;
  final int quizTotal;
  final DateTime? submittedAt;
  final bool isOutdated;
  final List<MaterialQuestionResult> questions;
  final Map<String, String> exerciseAnswers;
  const MaterialResult({
    required this.studentUserId,
    this.studentName,
    this.materialVersion = 1,
    this.quizScore = 0,
    this.quizTotal = 0,
    this.submittedAt,
    this.isOutdated = false,
    this.questions = const [],
    this.exerciseAnswers = const {},
  });
  factory MaterialResult.fromJson(Map<String, dynamic> j) => MaterialResult(
        studentUserId: (j['studentUserId'] as num?)?.toInt() ?? 0,
        studentName: j['studentName'] as String?,
        materialVersion: (j['materialVersion'] as num?)?.toInt() ?? 1,
        quizScore: (j['quizScore'] as num?)?.toInt() ?? 0,
        quizTotal: (j['quizTotal'] as num?)?.toInt() ?? 0,
        submittedAt: j['submittedAt'] != null ? DateTime.tryParse(j['submittedAt'].toString()) : null,
        isOutdated: j['isOutdated'] == true,
        questions: (j['questions'] as List? ?? []).map((e) => MaterialQuestionResult.fromJson(e as Map<String, dynamic>)).toList(),
        exerciseAnswers: (j['exerciseAnswers'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}

class SessionMaterialView {
  final int bookingId;
  final String viewerRole; // tutor | participant | payer
  final String bookingStatus;
  final String? subject;
  final List<String> topics;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String? tutorName;
  final int participantCount;
  final List<({int userId, String? name})> participants;
  final bool exists;
  final String? status; // draft | shared
  final int? version;
  final int? sharedVersion;
  final bool hasUnsharedChanges;
  final DateTime? sharedAt;
  final bool autoGenerated;
  final SessionMaterialContent? content;
  final bool solutionsIncluded;
  final bool canGenerate;
  final bool canEdit;
  final bool canShare;
  final bool canSubmit;
  final String? blockedReason;
  final MaterialResult? myResult;
  final List<MaterialResult> results;

  const SessionMaterialView({
    required this.bookingId,
    required this.viewerRole,
    required this.bookingStatus,
    this.subject,
    this.topics = const [],
    required this.sessionDate,
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes = 0,
    this.tutorName,
    this.participantCount = 1,
    this.participants = const [],
    this.exists = false,
    this.status,
    this.version,
    this.sharedVersion,
    this.hasUnsharedChanges = false,
    this.sharedAt,
    this.autoGenerated = false,
    this.content,
    this.solutionsIncluded = false,
    this.canGenerate = false,
    this.canEdit = false,
    this.canShare = false,
    this.canSubmit = false,
    this.blockedReason,
    this.myResult,
    this.results = const [],
  });

  bool get isTutor => viewerRole == 'tutor';
  bool get isParticipant => viewerRole == 'participant';

  factory SessionMaterialView.fromJson(Map<String, dynamic> j) => SessionMaterialView(
        bookingId: (j['bookingId'] as num?)?.toInt() ?? 0,
        viewerRole: j['viewerRole']?.toString() ?? 'payer',
        bookingStatus: j['bookingStatus']?.toString() ?? '',
        subject: j['subject'] as String?,
        topics: _strings(j['topics']),
        sessionDate: DateTime.tryParse(j['sessionDate']?.toString() ?? '') ?? DateTime.now(),
        startTime: j['startTime']?.toString() ?? '',
        endTime: j['endTime']?.toString() ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        tutorName: j['tutorName'] as String?,
        participantCount: (j['participantCount'] as num?)?.toInt() ?? 1,
        participants: (j['participants'] as List? ?? [])
            .map((e) => (userId: ((e as Map)['userId'] as num?)?.toInt() ?? 0, name: e['name'] as String?))
            .toList(),
        exists: j['exists'] == true,
        status: j['status'] as String?,
        version: (j['version'] as num?)?.toInt(),
        sharedVersion: (j['sharedVersion'] as num?)?.toInt(),
        hasUnsharedChanges: j['hasUnsharedChanges'] == true,
        sharedAt: j['sharedAt'] != null ? DateTime.tryParse(j['sharedAt'].toString()) : null,
        autoGenerated: j['autoGenerated'] == true,
        content: j['content'] is Map<String, dynamic> ? SessionMaterialContent.fromJson(j['content'] as Map<String, dynamic>) : null,
        solutionsIncluded: j['solutionsIncluded'] == true,
        canGenerate: j['canGenerate'] == true,
        canEdit: j['canEdit'] == true,
        canShare: j['canShare'] == true,
        canSubmit: j['canSubmit'] == true,
        blockedReason: j['blockedReason'] as String?,
        myResult: j['myResult'] is Map<String, dynamic> ? MaterialResult.fromJson(j['myResult'] as Map<String, dynamic>) : null,
        results: (j['results'] as List? ?? []).map((e) => MaterialResult.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Libellés du statut du support dans les listes de séances.
Map<String, String> get kSessionMaterialStatusLabels {
  final l = L10n.current;
  return {
    'draft': l.svcMaterialDraft,
    'shared': l.svcMaterialShared,
    'shared_with_changes': l.svcMaterialSharedWithChanges,
  };
}

class TutorSessionMaterialService {
  TutorSessionMaterialService._();
  static final TutorSessionMaterialService instance = TutorSessionMaterialService._();
  final _api = ApiClient.instance;

  SessionMaterialView _view(dynamic data) {
    final map = data is Map<String, dynamic> && data['bookingId'] == null && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return SessionMaterialView.fromJson(map);
  }

  Future<SessionMaterialView> get(int bookingId) async => _view((await _api.dio.get('/tutor-bookings/$bookingId/material')).data);

  Future<SessionMaterialView> generate(int bookingId, {String? instructions}) async => _view((await _api.dio.post(
        '/tutor-bookings/$bookingId/material/generate',
        data: {'instructions': (instructions == null || instructions.trim().isEmpty) ? null : instructions.trim()},
      ))
          .data);

  Future<SessionMaterialView> update(int bookingId, SessionMaterialContent content) async =>
      _view((await _api.dio.put('/tutor-bookings/$bookingId/material', data: {'content': content.toJson()})).data);

  Future<SessionMaterialView> share(int bookingId) async =>
      _view((await _api.dio.post('/tutor-bookings/$bookingId/material/share', data: {})).data);

  Future<SessionMaterialView> submit(int bookingId, Map<String, String> quizAnswers, Map<String, String> exerciseAnswers) async =>
      _view((await _api.dio.post('/tutor-bookings/$bookingId/material/submit',
              data: {'quizAnswers': quizAnswers, 'exerciseAnswers': exerciseAnswers}))
          .data);

  Future<bool> getAutoGenerate() async {
    final res = await _api.dio.get('/tutor-bookings/session-material/settings');
    final data = res.data;
    return data is Map && data['autoGenerateOnAccept'] == true;
  }

  Future<bool> setAutoGenerate(bool value) async {
    final res = await _api.dio.put('/tutor-bookings/session-material/settings', data: {'autoGenerateOnAccept': value});
    final data = res.data;
    return data is Map && data['autoGenerateOnAccept'] == true;
  }

  /// Message d'erreur du serveur (403 plan, 402 budget WinAI, 400 statut…).
  static String? errorMessage(Object e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      if (data is Map && data['error'] is String) return data['error'] as String;
    } catch (_) {}
    return null;
  }
}
