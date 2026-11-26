import 'api_client.dart';

/// Quiz que l'enfant n'a pas encore tenté (GET /parent/quizzes/available).
class ChildQuiz {
  final int id;
  final String title;
  final String subject;
  final int questionCount;
  const ChildQuiz(this.id, this.title, this.subject, this.questionCount);
}

/// Fiche de révision de l'enfant (GET /parent/revisions/available).
class ChildSheet {
  final int id;
  final String title;
  final String subject;
  const ChildSheet(this.id, this.title, this.subject);
}

/// Achat fait pour l'enfant et s'il l'a déjà ouvert (1 à 30 jours après).
class PurchaseImpact {
  final int contentId;
  final String? title;
  final DateTime? purchasedAt;
  final bool consulted;
  final DateTime? firstConsultedAt;
  const PurchaseImpact(this.contentId, this.title, this.purchasedAt, this.consulted, this.firstConsultedAt);
}

/// Chiffres du mois d'un enfant pour la comparaison entre enfants.
class ChildSummary {
  final int childId;
  final String name;
  final double avgScore;
  final int quizCount;
  final int activeDays;
  const ChildSummary(this.childId, this.name, this.avgScore, this.quizCount, this.activeDays);
}

class ChildrenInsights {
  final List<ChildSummary> children;
  final List<String> insights;
  const ChildrenInsights(this.children, this.insights);
}

/// Suivi d'un enfant par le parent (lot 7), comme RecommendedContentCard,
/// PurchaseImpactCard et ChildrenComparison du site.
class ParentFollowService {
  ParentFollowService._();
  static final ParentFollowService instance = ParentFollowService._();
  final _api = ApiClient.instance;

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    return (raw is List ? raw : const []).whereType<Map<String, dynamic>>().toList();
  }

  static DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

  Future<List<ChildQuiz>> quizzes(int childId, {int limit = 5}) async {
    final res = await _api.dio.get('/parent/quizzes/available', queryParameters: {'childId': childId, 'limit': limit});
    return _list(res.data)
        .map((j) => ChildQuiz((j['id'] as num?)?.toInt() ?? 0, '${j['title'] ?? ''}', '${j['subject'] ?? ''}',
            (j['questionCount'] as num?)?.toInt() ?? 0))
        .toList();
  }

  Future<List<ChildSheet>> sheets(int childId, {int limit = 5}) async {
    final res = await _api.dio.get('/parent/revisions/available', queryParameters: {'childId': childId, 'limit': limit});
    return _list(res.data)
        .map((j) => ChildSheet((j['id'] as num?)?.toInt() ?? 0, '${j['title'] ?? ''}', '${j['subject'] ?? ''}'))
        .toList();
  }

  Future<List<PurchaseImpact>> purchases(int childId) async {
    final res = await _api.dio.get('/parent/purchases/$childId/impact');
    return _list(res.data)
        .map((j) => PurchaseImpact((j['contentId'] as num?)?.toInt() ?? 0, j['contentTitle'] as String?,
            _date(j['purchaseDate']), j['consulted'] == true, _date(j['firstConsultedAt'])))
        .toList();
  }

  /// Comparaison entre enfants (service WinAI, champs en snake_case).
  Future<ChildrenInsights> childrenInsights(List<int> childIds) async {
    final res = await _api.dio.get('/parent/children-insights', queryParameters: {'childIds': childIds.join(',')});
    final body = res.data is Map ? res.data as Map : const {};
    final d = body['data'] is Map ? body['data'] as Map : body;
    final children = (d['children_summary'] is List ? d['children_summary'] as List : const [])
        .whereType<Map>()
        .map((c) => ChildSummary(
              (c['child_id'] as num?)?.toInt() ?? 0,
              '${c['child_name'] ?? ''}',
              (c['avg_score'] as num?)?.toDouble() ?? 0,
              (c['quiz_count'] as num?)?.toInt() ?? 0,
              (c['active_days'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final insights = (d['insights'] is List ? d['insights'] as List : const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
    return ChildrenInsights(children, insights);
  }

  /// Préférence « comparer mes enfants », enregistrée aussi au serveur.
  Future<void> setComparison(bool enabled) =>
      _api.dio.put('/parent/settings', data: {'childrenComparison': enabled});
}
