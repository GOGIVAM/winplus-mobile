import 'api_client.dart';
import 'local_cache_service.dart';

/// Plan Exam Coach actif de l'utilisateur connecté (voir ExamCoachController
/// côté backend : GET /exam-coach/active). Mis en cache (ExamCoachBox) pour
/// rester consultable hors ligne  c'est une donnée "Haute" priorité (révision
/// avant examen, moment où le réseau peut manquer).
class ApiExamCoachDayCompletion {
  final int dayNumber;
  final DateTime completedAt;
  final double? quizScore;
  const ApiExamCoachDayCompletion({
    required this.dayNumber,
    required this.completedAt,
    this.quizScore,
  });

  factory ApiExamCoachDayCompletion.fromJson(Map<String, dynamic> j) =>
      ApiExamCoachDayCompletion(
        dayNumber: j['dayNumber'] as int? ?? 0,
        completedAt:
            DateTime.tryParse(j['completedAt'] as String? ?? '') ?? DateTime.now(),
        quizScore: (j['quizScore'] as num?)?.toDouble(),
      );
}

class ApiExamCoachPlan {
  final int id;
  final String examType;
  final DateTime examDate;
  final double hoursPerDay;
  final double confidenceScore;
  final bool isActive;
  final String planJson;
  final DateTime createdAt;
  final List<ApiExamCoachDayCompletion> completedDays;

  const ApiExamCoachPlan({
    required this.id,
    required this.examType,
    required this.examDate,
    required this.hoursPerDay,
    required this.confidenceScore,
    required this.isActive,
    required this.planJson,
    required this.createdAt,
    this.completedDays = const [],
  });

  factory ApiExamCoachPlan.fromJson(Map<String, dynamic> j) => ApiExamCoachPlan(
        id: j['id'] as int? ?? 0,
        examType: j['examType'] as String? ?? '',
        examDate:
            DateTime.tryParse(j['examDate'] as String? ?? '') ?? DateTime.now(),
        hoursPerDay: ((j['hoursPerDay'] ?? 2) as num).toDouble(),
        confidenceScore: ((j['confidenceScore'] ?? 0) as num).toDouble(),
        isActive: j['isActive'] as bool? ?? true,
        planJson: j['planJson'] as String? ?? '{}',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        completedDays: ((j['completedDays'] as List?) ?? [])
            .map((e) => ApiExamCoachDayCompletion.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// État de la veille d'examen parentale sur le plan d'un enfant (voir
/// ExamCoachController : POST/GET/DELETE /exam-coach/{childId}/watch-mode).
class ApiWatchModeState {
  final bool active;
  final String? examType;
  final DateTime? examDate;
  const ApiWatchModeState({required this.active, this.examType, this.examDate});

  factory ApiWatchModeState.fromJson(Map<String, dynamic> j) =>
      ApiWatchModeState(
        active: j['active'] as bool? ?? false,
        examType: j['examType'] as String?,
        examDate: DateTime.tryParse(j['examDate'] as String? ?? ''),
      );
}

class ExamCoachService {
  ExamCoachService._();
  static final ExamCoachService instance = ExamCoachService._();

  final _api = ApiClient.instance;

  /// null si aucun plan actif (404 côté backend  état normal, pas une erreur).
  Future<ApiExamCoachPlan?> getActivePlan() async {
    try {
      final result = await LocalCacheService.cachedFetch<Map<String, dynamic>?>(
        box: LocalCacheService.examCoach,
        key: 'active_plan',
        fetchLiveRaw: () async =>
            (await _api.dio.get('/exam-coach/active')).data,
        parse: (raw) =>
            raw == null ? null : Map<String, dynamic>.from(raw as Map),
      );
      final data = result.value;
      return data == null ? null : ApiExamCoachPlan.fromJson(data);
    } catch (_) {
      // 404 (pas de plan actif) ou aucune donnée en cache : état vide normal.
      return null;
    }
  }

  /// POST /exam-coach  génère un nouveau plan WinAI (désactive l'ancien,
  /// voir ExamCoachController.CreatePlan côté backend  même endpoint que le
  /// web, examCoachService.ts createPlan).
  Future<ApiExamCoachPlan> createPlan({
    required String examType,
    required DateTime examDate,
    double hoursPerDay = 2.0,
  }) async {
    final res = await _api.dio.post('/exam-coach', data: {
      'examType': examType,
      'examDate': examDate.toIso8601String().split('T').first,
      'hoursPerDay': hoursPerDay,
    });
    await LocalCacheService.examCoach.delete('active_plan');
    return ApiExamCoachPlan.fromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /exam-coach/{id}/complete-day
  Future<void> completeDay(int planId, int dayNumber, {double? quizScore}) async {
    await _api.dio.put('/exam-coach/$planId/complete-day', data: {
      'dayNumber': dayNumber,
      if (quizScore != null) 'quizScore': quizScore,
    });
    await LocalCacheService.examCoach.delete('active_plan');
  }

  /// DELETE /exam-coach/{id}
  Future<void> deactivatePlan(int planId) async {
    await _api.dio.delete('/exam-coach/$planId');
    await LocalCacheService.examCoach.delete('active_plan');
  }

  // ── Mode veille d'examen (parent) ────────────────────────────────────────

  Future<ApiWatchModeState> getWatchMode(int childId) async {
    final res = await _api.dio.get('/exam-coach/$childId/watch-mode');
    return ApiWatchModeState.fromJson(res.data as Map<String, dynamic>);
  }

  /// Réutilise le plan actif de l'enfant s'il en a un ; sinon [examType] et
  /// [examDate] sont requis pour en créer un.
  Future<ApiWatchModeState> activateWatchMode(
    int childId, {
    String? examType,
    DateTime? examDate,
    double hoursPerDay = 2.0,
  }) async {
    final res = await _api.dio.post('/exam-coach/$childId/watch-mode', data: {
      if (examType != null) 'examType': examType,
      if (examDate != null) 'examDate': examDate.toIso8601String(),
      'hoursPerDay': hoursPerDay,
    });
    return ApiWatchModeState.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deactivateWatchMode(int childId) async {
    await _api.dio.delete('/exam-coach/$childId/watch-mode');
  }
}
