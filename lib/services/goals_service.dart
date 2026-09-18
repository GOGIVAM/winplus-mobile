import 'api_client.dart';

/// Workflow de proposition d'objectifs (Goal  GoalsController côté backend).
/// Deux origines pour un objectif actif : créé directement par l'élève, ou
/// proposé par un parent lié puis accepté/modifié par l'élève. Distinct de
/// WeeklyGoal (cibles hebdomadaires automatiques, pas de proposition).
class ApiGoalDetail {
  final int id;
  final int userId;
  final String? title;
  final String? description;
  final String? type;
  final int? progress;
  final String status;
  final int? proposedByUserId;
  final DateTime targetDate;
  const ApiGoalDetail({
    required this.id,
    required this.userId,
    this.title,
    this.description,
    this.type,
    this.progress,
    required this.status,
    this.proposedByUserId,
    required this.targetDate,
  });

  factory ApiGoalDetail.fromJson(Map<String, dynamic> j) => ApiGoalDetail(
        id: j['id'] as int? ?? 0,
        userId: j['userId'] as int? ?? 0,
        title: j['title'] as String?,
        description: j['description'] as String?,
        type: j['type'] as String?,
        progress: j['progress'] as int?,
        status: j['status'] as String? ?? 'Active',
        proposedByUserId: j['proposedByUserId'] as int?,
        targetDate: DateTime.tryParse(j['targetDate'] as String? ?? '') ??
            DateTime.now(),
      );
}

class GoalsService {
  GoalsService._();
  static final GoalsService instance = GoalsService._();

  final _api = ApiClient.instance;

  /// Mes propres objectifs (élève)  tous statuts confondus, le filtrage
  /// (Pending à traiter, Active en cours...) se fait côté appelant.
  Future<List<ApiGoalDetail>> getMyGoals() async {
    final res = await _api.dio.get('/student/goals');
    final data = res.data;
    final list = data is Map ? data['data'] as List? : data as List?;
    return (list ?? [])
        .map((e) => ApiGoalDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Le parent propose un objectif à un enfant lié. Toujours Pending à la création.
  Future<ApiGoalDetail> propose({
    required int childId,
    required String title,
    String? description,
    String? type,
    required DateTime deadline,
  }) async {
    final res = await _api.dio.post('/goals/propose', data: {
      'childId': childId,
      'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      'deadline': deadline.toIso8601String(),
    });
    final data = res.data as Map<String, dynamic>;
    return ApiGoalDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// L'élève accepte tel quel un objectif proposé. Pending → Active.
  Future<void> accept(int id) async {
    await _api.dio.post('/goals/$id/accept');
  }

  /// L'élève refuse un objectif proposé. Pending → Refused, définitif.
  Future<void> refuse(int id) async {
    await _api.dio.post('/goals/$id/refuse');
  }

  /// L'élève modifie une proposition (titre/description/échéance) et l'active
  /// dans le même geste  pas de re-validation parent.
  Future<void> modify(
    int id, {
    required String title,
    String? description,
    required DateTime deadline,
  }) async {
    await _api.dio.put('/goals/$id/modify', data: {
      'title': title,
      if (description != null) 'description': description,
      'deadline': deadline.toIso8601String(),
    });
  }

  /// L'élève crée directement un objectif, sans proposition parent. Active dès l'origine.
  Future<ApiGoalDetail> create({
    required String title,
    String? description,
    String? type,
    required DateTime deadline,
  }) async {
    final res = await _api.dio.post('/goals', data: {
      'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      'deadline': deadline.toIso8601String(),
    });
    final data = res.data as Map<String, dynamic>;
    return ApiGoalDetail.fromJson(data['data'] as Map<String, dynamic>);
  }
}
