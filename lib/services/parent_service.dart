import 'api_client.dart';

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
  final String type; // 'download', 'quiz', 'ai_chat'
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
        occurredAt:
            DateTime.tryParse(j['occurredAt'] as String? ?? '') ?? DateTime.now(),
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

class ApiWinAIAlert {
  final int id;
  final String type; // 'danger', 'warning', 'tip'
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? childId;
  final String? childName;
  const ApiWinAIAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.childId,
    this.childName,
  });

  factory ApiWinAIAlert.fromJson(Map<String, dynamic> j) => ApiWinAIAlert(
        id: j['id'] as int? ?? 0,
        type: j['type'] as String? ?? 'tip',
        message: j['message'] as String? ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: j['isRead'] as bool? ?? false,
        childId: j['childId'] as int?,
        childName: j['childName'] as String?,
      );
}

class ParentService {
  ParentService._();
  static final ParentService instance = ParentService._();

  final _api = ApiClient.instance;

  Future<List<ApiChild>> getChildren() async {
    final res = await _api.dio.get('/parent/children');
    final list = res.data as List? ?? [];
    return list.map((e) => ApiChild.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> addChild({
    required String firstName,
    required String lastName,
    required String level,
    String? schoolName,
  }) async {
    try {
      await _api.dio.post('/parent/children', data: {
        'firstName': firstName,
        'lastName': lastName,
        'level': level,
        if (schoolName != null) 'schoolName': schoolName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeChild(int childId) async {
    try {
      await _api.dio.delete('/parent/children/$childId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiChildActivity>> getChildActivity(int childId,
      {int page = 1, int pageSize = 20}) async {
    final res = await _api.dio.get('/parent/children/$childId/activity',
        queryParameters: {'page': page, 'pageSize': pageSize});
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiChildActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiChildStats> getChildStats(int childId) async {
    final res = await _api.dio.get('/parent/children/$childId/stats');
    return ApiChildStats.fromJson(res.data as Map<String, dynamic>? ?? {});
  }

  Future<List<ApiWinAIAlert>> getAlerts() async {
    final res = await _api.dio.get('/parent/alerts');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiWinAIAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAlertRead(int alertId) async {
    try {
      await _api.dio.put('/parent/alerts/$alertId/read');
    } catch (_) {}
  }
}
