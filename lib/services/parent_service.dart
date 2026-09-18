import 'api_client.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';

class ApiChild {
  final int id;
  final String firstName;
  final String lastName;
  final String? level;
  final String? avatarUrl;
  final String? schoolName;
  const ApiChild({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.level,
    this.avatarUrl,
    this.schoolName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApiChild.fromJson(Map<String, dynamic> j) => ApiChild(
        id: j['id'] as int? ?? 0,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        level: j['level'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        schoolName: j['schoolName'] as String?,
      );
}

class ApiChildActivity {
  final String type;
  final String description;
  final DateTime occurredAt;
  final int? score;
  const ApiChildActivity({
    required this.type,
    required this.description,
    required this.occurredAt,
    this.score,
  });

  factory ApiChildActivity.fromJson(Map<String, dynamic> j) => ApiChildActivity(
        type: j['type'] as String? ?? 'download',
        description: j['description'] as String? ?? '',
        occurredAt: DateTime.tryParse(j['occurredAt'] as String? ?? '') ??
            DateTime.now(),
        score: j['score'] as int?,
      );
}

class ApiChildStats {
  final int downloadsThisWeek;
  final int quizzesThisWeek;
  final double averageScore;
  final int aiSessionsThisWeek;
  const ApiChildStats({
    this.downloadsThisWeek = 0,
    this.quizzesThisWeek = 0,
    this.averageScore = 0,
    this.aiSessionsThisWeek = 0,
  });

  factory ApiChildStats.fromJson(Map<String, dynamic> j) => ApiChildStats(
        downloadsThisWeek: j['downloadsThisWeek'] as int? ?? 0,
        quizzesThisWeek: j['quizzesThisWeek'] as int? ?? 0,
        averageScore: ((j['averageScore'] ?? 0) as num).toDouble(),
        aiSessionsThisWeek: j['aiSessionsThisWeek'] as int? ?? 0,
      );
}

class ApiSubjectScore {
  final int subjectId;
  final String subjectTitle;
  final double averageScore;
  const ApiSubjectScore({
    required this.subjectId,
    required this.subjectTitle,
    required this.averageScore,
  });

  factory ApiSubjectScore.fromJson(Map<String, dynamic> j) => ApiSubjectScore(
        subjectId: j['subjectId'] as int? ?? 0,
        subjectTitle: j['subjectTitle'] as String? ?? 'Matière',
        averageScore: ((j['averageScore'] ?? 0) as num).toDouble(),
      );
}

class ApiLastQuiz {
  final String title;
  final double scorePercent;
  final int correctAnswers;
  final int totalQuestions;
  const ApiLastQuiz({
    required this.title,
    required this.scorePercent,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  factory ApiLastQuiz.fromJson(Map<String, dynamic> j) => ApiLastQuiz(
        title: j['title'] as String? ?? 'Quiz',
        scorePercent: ((j['scorePercent'] ?? 0) as num).toDouble(),
        correctAnswers: j['correctAnswers'] as int? ?? 0,
        totalQuestions: j['totalQuestions'] as int? ?? 0,
      );
}

/// GET /parent/children/{childId}/subject-scores  remplace les tableaux
/// codés en dur de child_activity_screen.dart (_childScores/_lastQuiz).
class ApiChildSubjectScores {
  final List<ApiSubjectScore> subjects;
  final ApiLastQuiz? lastQuiz;
  const ApiChildSubjectScores({required this.subjects, this.lastQuiz});

  factory ApiChildSubjectScores.fromJson(Map<String, dynamic> j) =>
      ApiChildSubjectScores(
        subjects: ((j['subjects'] as List?) ?? [])
            .map((e) => ApiSubjectScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastQuiz: j['lastQuiz'] == null
            ? null
            : ApiLastQuiz.fromJson(j['lastQuiz'] as Map<String, dynamic>),
      );
}

/// Alerte WinAI persistée (table .NET ParentAlert, alimentée par le calcul
/// Python  parent_alert_routes.py). Remplace l'ancien ApiWinAIAlert, qui
/// lisait GET /parent/alerts : cet endpoint lit la table Notifications
/// filtrée sur Type="ParentAlert", que plus rien n'écrit (legacy, voir le
/// commentaire de ParentAlertController côté backend)  il ne renvoyait donc
/// jamais rien en pratique. Les vraies alertes se lisent par enfant via
/// GET /parent-alerts/{childId}, comme le fait déjà le frontend web
/// (parentExtraService.getPersistedAlerts).
class ApiPersistedAlert {
  final int id;
  final int childId;
  final String type;
  final String severity;
  final String content;
  final bool isRead;
  final DateTime detectedAt;
  const ApiPersistedAlert({
    required this.id,
    required this.childId,
    required this.type,
    required this.severity,
    required this.content,
    required this.isRead,
    required this.detectedAt,
  });

  factory ApiPersistedAlert.fromJson(Map<String, dynamic> j,
          {required int fallbackChildId}) =>
      ApiPersistedAlert(
        id: j['id'] as int? ?? 0,
        childId: j['childId'] as int? ?? fallbackChildId,
        type: j['type'] as String? ?? 'Inactivite',
        severity: j['severity'] as String? ?? 'Low',
        content: j['content'] as String? ?? '',
        isRead: j['isRead'] as bool? ?? false,
        detectedAt: DateTime.tryParse(j['detectedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ApiGoal {
  final int id;
  final String? title;
  final String? description;
  final String? type;
  final String status;
  final DateTime targetDate;
  final int? progress;
  final int? proposedByUserId;
  const ApiGoal({
    required this.id,
    this.title,
    this.description,
    this.type,
    required this.status,
    required this.targetDate,
    this.progress,
    this.proposedByUserId,
  });

  factory ApiGoal.fromJson(Map<String, dynamic> j) => ApiGoal(
        // Le endpoint /parent/children/{childId}/goals (ParentService.cs
        // GetChildGoalsAsync) projette "goalId", pas "id"  lire "id" seul
        // faisait retomber silencieusement chaque objectif sur l'id 0.
        id: j['goalId'] as int? ?? j['id'] as int? ?? 0,
        title: j['title'] as String?,
        description: j['description'] as String?,
        type: j['type'] as String?,
        status: j['status'] as String? ?? 'Active',
        targetDate: DateTime.tryParse(j['targetDate'] as String? ?? '') ??
            DateTime.now(),
        progress: j['progress'] as int?,
        proposedByUserId: j['proposedByUserId'] as int?,
      );
}

class ParentService {
  ParentService._();
  static final ParentService instance = ParentService._();

  final _api = ApiClient.instance;

  /// Liste des enfants liés  mise en cache (ParentDashboardBox) : rejoue la
  /// dernière liste connue quand le réseau est indisponible plutôt que de
  /// laisser l'écran vide.
  Future<List<ApiChild>> getChildren() async {
    final result = await LocalCacheService.cachedFetch<List<ApiChild>>(
      box: LocalCacheService.parentDashboard,
      key: 'children',
      fetchLiveRaw: () async => (await _api.dio.get('/parent/children')).data,
      parse: (raw) => ((raw as List?) ?? [])
          .map((e) => ApiChild.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.value;
  }

  /// Rattachement/déliaison parent-enfant = toujours en ligne, jamais mis en
  /// file (requireOnline).
  Future<bool> addChild({required String email}) async {
    requireOnline();
    try {
      await _api.dio.post('/parent/children', data: {'email': email});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeChild(int childId) async {
    requireOnline();
    try {
      await _api.dio.delete('/parent/children/$childId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiChildActivity>> getChildActivity(int childId,
      {int page = 1, int pageSize = 20}) async {
    final result = await LocalCacheService.cachedFetch<List<ApiChildActivity>>(
      box: LocalCacheService.parentDashboard,
      key: 'activity_$childId',
      fetchLiveRaw: () async => (await _api.dio.get(
              '/parent/children/$childId/activity',
              queryParameters: {'page': page, 'pageSize': pageSize}))
          .data,
      parse: (raw) => ((raw as List?) ?? [])
          .map((e) => ApiChildActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.value;
  }

  Future<ApiChildStats> getChildStats(int childId) async {
    final res = await _api.dio.get('/parent/children/$childId/stats');
    return ApiChildStats.fromJson(res.data as Map<String, dynamic>? ?? {});
  }

  /// Score moyen par matière (30j) et dernier quiz complété  remplace les
  /// données codées en dur (_childScores/_lastQuiz) que child_activity_screen
  /// affichait comme si elles étaient réelles pour n'importe quel enfant.
  Future<ApiChildSubjectScores> getChildSubjectScores(int childId) async {
    final result = await LocalCacheService.cachedFetch<ApiChildSubjectScores>(
      box: LocalCacheService.parentDashboard,
      key: 'subject_scores_$childId',
      fetchLiveRaw: () async =>
          (await _api.dio.get('/parent/children/$childId/subject-scores')).data,
      parse: (raw) {
        final data = raw is Map ? raw['data'] : raw;
        return ApiChildSubjectScores.fromJson(
            Map<String, dynamic>.from(data as Map? ?? {}));
      },
    );
    return result.value;
  }

  /// Alertes WinAI réelles d'un enfant lié (ParentAlertController), mises en
  /// cache (ParentDashboardBox) par enfant.
  Future<List<ApiPersistedAlert>> getPersistedAlerts(int childId) async {
    final result = await LocalCacheService.cachedFetch<List<ApiPersistedAlert>>(
      box: LocalCacheService.parentDashboard,
      key: 'persisted_alerts_$childId',
      fetchLiveRaw: () async =>
          (await _api.dio.get('/parent-alerts/$childId')).data,
      parse: (raw) => ((raw as List?) ?? [])
          .map((e) => ApiPersistedAlert.fromJson(e as Map<String, dynamic>,
              fallbackChildId: childId))
          .toList(),
    );
    return result.value;
  }

  /// Alertes de tous les enfants liés, agrégées (pour un écran/bannière qui
  /// n'est pas déjà scopé à un enfant précis).
  Future<List<ApiPersistedAlert>> getAllPersistedAlerts(
      List<int> childIds) async {
    final all = <ApiPersistedAlert>[];
    for (final id in childIds) {
      try {
        all.addAll(await getPersistedAlerts(id));
      } catch (_) {
        // Un enfant en échec ne doit pas empêcher d'afficher les autres.
      }
    }
    all.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return all;
  }

  Future<void> markAlertRead(int alertId) async {
    try {
      await _api.dio.patch('/parent-alerts/$alertId/read');
    } catch (_) {}
  }

  /// Objectifs d'un enfant lié (Goal  voir GoalsController côté backend)
  /// mis en cache (ParentDashboardBox), complète alertes/activité/enfants
  /// pour le dashboard parent hors ligne.
  Future<List<ApiGoal>> getGoals(int childId) async {
    final result = await LocalCacheService.cachedFetch<List<ApiGoal>>(
      box: LocalCacheService.parentDashboard,
      key: 'goals_$childId',
      fetchLiveRaw: () async =>
          (await _api.dio.get('/parent/children/$childId/goals')).data,
      parse: (raw) {
        final data = raw is Map ? raw['data'] : raw;
        return ((data as List?) ?? [])
            .map((e) => ApiGoal.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return result.value;
  }
}
