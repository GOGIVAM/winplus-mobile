import 'package:dio/dio.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';

/// Évènement publié sur la plateforme (entité Event, GET /parent/events/upcoming).
class ApiUpcomingEvent {
  final String title;
  final String type;
  final DateTime? startDate;
  const ApiUpcomingEvent(
      {required this.title, required this.type, required this.startDate});

  factory ApiUpcomingEvent.fromJson(Map<String, dynamic> j) => ApiUpcomingEvent(
        title: j['title'] as String? ?? '',
        type: j['eventType'] as String? ?? 'event',
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '')?.toLocal(),
      );
}

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

class ApiParentProfile {
  final int parentId;
  final String name;
  final String email;
  const ApiParentProfile(
      {required this.parentId, required this.name, required this.email});

  factory ApiParentProfile.fromJson(Map<String, dynamic> j) =>
      ApiParentProfile(
        parentId: j['parentId'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
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

/// Solde de portefeuille parent (voir ParentCreditsController.cs côté
/// backend : GET /parent/credits). Module 24 (lot 8, rattrapage 16.1) :
/// l'écran "Acheter pour mon enfant" n'affichait jusqu'ici aucun solde réel
/// bien qu'un endpoint existe déjà  simple câblage, aucune route serveur
/// nouvelle.
class ApiParentWalletSummary {
  final String? planName;
  final double creditsLeft;
  final double allocationRemaining;
  final double permanent;
  final String currency;
  const ApiParentWalletSummary({
    this.planName,
    required this.creditsLeft,
    required this.allocationRemaining,
    required this.permanent,
    this.currency = 'XAF',
  });

  factory ApiParentWalletSummary.fromJson(Map<String, dynamic> j) =>
      ApiParentWalletSummary(
        planName: j['planName'] as String?,
        creditsLeft: ((j['creditsLeft'] ?? 0) as num).toDouble(),
        allocationRemaining: ((j['allocationRemaining'] ?? 0) as num).toDouble(),
        permanent: ((j['permanent'] ?? 0) as num).toDouble(),
        currency: j['currency'] as String? ?? 'XAF',
      );
}

/// Lot 9.7b : paiement réel du parent (GET /parent/payments) : commande
/// (catalogue, formation, abonnement) ou mouvement du portefeuille.
class ApiParentPayment {
  final String kind; // order | wallet | recharge
  final String label;
  final double amountXaf;
  final bool isDebit;
  final String status; // paid | pending | failed | refunded | refund_requested
  final String method;
  final DateTime date;
  const ApiParentPayment({
    required this.kind,
    required this.label,
    required this.amountXaf,
    required this.isDebit,
    required this.status,
    required this.method,
    required this.date,
  });

  factory ApiParentPayment.fromJson(Map<String, dynamic> j) => ApiParentPayment(
        kind: j['kind'] as String? ?? 'order',
        label: j['label'] as String? ?? 'Paiement',
        amountXaf: ((j['amountXaf'] ?? 0) as num).toDouble(),
        isDebit: (j['direction'] as String? ?? 'debit') == 'debit',
        status: j['status'] as String? ?? 'paid',
        method: j['method'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class ApiParentPayments {
  final List<ApiParentPayment> items;
  final double monthSpentXaf;
  const ApiParentPayments({required this.items, required this.monthSpentXaf});
}

/// Lot 9.7b (étude 1.4) : enfant lié et couverture par le plan du parent.
class ApiCoveredChild {
  final int studentId;
  final String name;
  final bool covered;
  final bool chosen;
  const ApiCoveredChild({required this.studentId, required this.name, required this.covered, required this.chosen});

  factory ApiCoveredChild.fromJson(Map<String, dynamic> j) => ApiCoveredChild(
        studentId: (j['studentId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        covered: j['covered'] as bool? ?? false,
        chosen: j['chosen'] as bool? ?? false,
      );
}

class ApiCoveredChildren {
  final int? max;
  final bool selectionNeeded;
  final bool customSelection;
  final bool canChange;
  final DateTime? nextChangeAt;
  final List<ApiCoveredChild> children;
  const ApiCoveredChildren({
    required this.max,
    required this.selectionNeeded,
    required this.customSelection,
    required this.canChange,
    required this.nextChangeAt,
    required this.children,
  });

  factory ApiCoveredChildren.fromJson(Map<String, dynamic> j) => ApiCoveredChildren(
        max: (j['max'] as num?)?.toInt(),
        selectionNeeded: j['selectionNeeded'] as bool? ?? false,
        customSelection: j['customSelection'] as bool? ?? false,
        canChange: j['canChange'] as bool? ?? false,
        nextChangeAt: DateTime.tryParse(j['nextChangeAt'] as String? ?? '')?.toLocal(),
        children: ((j['children'] as List?) ?? [])
            .map((e) => ApiCoveredChild.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Choix des enfants couverts refusé par le serveur (message en français).
class CoveredChildrenException implements Exception {
  final String message;
  const CoveredChildrenException(this.message);
  @override
  String toString() => message;
}

class ParentService {
  ParentService._();
  static final ParentService instance = ParentService._();

  final _api = ApiClient.instance;

  /// Liste des enfants liés  mise en cache (ParentDashboardBox) : rejoue la
  /// dernière liste connue quand le réseau est indisponible plutôt que de
  /// laisser l'écran vide.
  /// Module 24 (lot 8) : GET /parent/profile — nom réel, remplace
  /// WinData.parentAccount.name utilisé jusqu'ici dans parent_tabs.dart.
  /// Le plan/les crédits restent sur SubscriptionService.getCurrent(), déjà
  /// chargé par ParentDashTab (ApiActiveSubscription.planName).
  Future<ApiParentProfile?> getProfile() async {
    try {
      final res = await _api.dio.get('/parent/profile');
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      return data == null ? null : ApiParentProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Solde de portefeuille réel (dotation mensuelle + recharge), pour
  /// l'écran d'achat pour un enfant. `null` si le parent n'a pas
  /// d'abonnement payant actif (ParentCreditsController renvoie data: null
  /// dans ce cas, état normal  pas une erreur).
  Future<ApiParentWalletSummary?> getWalletSummary() async {
    try {
      final res = await _api.dio.get('/parent/credits');
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      return data == null ? null : ApiParentWalletSummary.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Évènements à venir publiés sur la plateforme (GET /parent/events/upcoming),
  /// remplace WinData.upcomingEvents. Liste vide si rien n'est publié ou si le
  /// serveur ne répond pas : l'accueil masque alors la section.
  Future<List<ApiUpcomingEvent>> getUpcomingEvents({int limit = 5}) async {
    try {
      final res = await _api.dio
          .get('/parent/events/upcoming', queryParameters: {'limit': limit});
      final list = (res.data as Map<String, dynamic>)['data'];
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ApiUpcomingEvent.fromJson)
          .where((e) => e.title.trim().isNotEmpty && e.startDate != null)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Lot 9.7b : historique réel des paiements (remplace la liste fictive de
  /// l'écran Paiements). Null si le serveur ne répond pas.
  Future<ApiParentPayments?> getPayments({int limit = 50}) async {
    try {
      final res = await _api.dio.get('/parent/payments', queryParameters: {'limit': limit});
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ApiParentPayments(
        items: ((data['items'] as List?) ?? [])
            .map((e) => ApiParentPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        monthSpentXaf: ((data['monthSpentXaf'] ?? 0) as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lot 9.7b : enfants couverts par le plan (GET /parent/covered-children).
  Future<ApiCoveredChildren?> getCoveredChildren() async {
    try {
      final res = await _api.dio.get('/parent/covered-children');
      return res.data is Map<String, dynamic>
          ? ApiCoveredChildren.fromJson(res.data as Map<String, dynamic>)
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Enregistre le choix ; lève [CoveredChildrenException] avec le message
  /// du serveur (choix invalide, changement déjà fait dans la période).
  Future<ApiCoveredChildren> setCoveredChildren(List<int> studentIds) async {
    try {
      final res = await _api.dio.put('/parent/covered-children', data: {'studentIds': studentIds});
      return ApiCoveredChildren.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw CoveredChildrenException(
          (data is Map ? data['error'] as String? : null) ?? "Le choix n'a pas pu être enregistré.");
    }
  }

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
  /// Dernier message d'erreur du serveur pour [addChild] (ex. limite
  /// children.max du plan, lot 9.7b), ou null.
  String? lastAddChildError;

  Future<bool> addChild({required String email}) async {
    requireOnline();
    lastAddChildError = null;
    try {
      await _api.dio.post('/parent/children', data: {'email': email});
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) lastAddChildError = data['error'] as String;
      return false;
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
