import 'api_client.dart';

class ApiGroup {
  final int id;
  final String name;
  final String? description;
  final int memberCount;
  final String level;
  const ApiGroup({
    required this.id,
    required this.name,
    this.description,
    this.memberCount = 0,
    required this.level,
  });

  factory ApiGroup.fromJson(Map<String, dynamic> j) => ApiGroup(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        memberCount: j['memberCount'] as int? ?? 0,
        level: j['level'] as String? ?? '',
      );
}

class ApiGroupMember {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final double averageScore;
  final int activityScore;
  const ApiGroupMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.averageScore = 0,
    this.activityScore = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApiGroupMember.fromJson(Map<String, dynamic> j) => ApiGroupMember(
        id: j['id'] as int? ?? 0,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        email: j['email'] as String?,
        averageScore: ((j['averageScore'] ?? 0) as num).toDouble(),
        activityScore: j['activityScore'] as int? ?? 0,
      );
}

class ApiAtRiskStudent {
  final int id;
  final String firstName;
  final String lastName;
  final String? groupName;
  final double riskScore; // 0-1, higher = more at risk
  final String riskReason;
  const ApiAtRiskStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.groupName,
    required this.riskScore,
    required this.riskReason,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApiAtRiskStudent.fromJson(Map<String, dynamic> j) => ApiAtRiskStudent(
        id: j['id'] as int? ?? 0,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        groupName: j['groupName'] as String?,
        riskScore: ((j['riskScore'] ?? 0) as num).toDouble(),
        riskReason: j['riskReason'] as String? ?? '',
      );
}

class ApiInstitutionAnalytics {
  final int totalStudents;
  final int activeStudents;
  final double averageScore;
  final int downloadsThisMonth;
  final int quizzesThisMonth;
  final Map<String, int> activityByDay;
  const ApiInstitutionAnalytics({
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.averageScore = 0,
    this.downloadsThisMonth = 0,
    this.quizzesThisMonth = 0,
    this.activityByDay = const {},
  });

  factory ApiInstitutionAnalytics.fromJson(Map<String, dynamic> j) =>
      ApiInstitutionAnalytics(
        totalStudents: j['totalStudents'] as int? ?? 0,
        activeStudents: j['activeStudents'] as int? ?? 0,
        averageScore: ((j['averageScore'] ?? 0) as num).toDouble(),
        downloadsThisMonth: j['downloadsThisMonth'] as int? ?? 0,
        quizzesThisMonth: j['quizzesThisMonth'] as int? ?? 0,
        activityByDay: (j['activityByDay'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int? ?? 0)),
      );
}

class InstitutionService {
  InstitutionService._();
  static final InstitutionService instance = InstitutionService._();

  final _api = ApiClient.instance;

  Future<List<ApiGroup>> getGroups() async {
    final res = await _api.dio.get('/institution/groups');
    final list = res.data as List? ?? [];
    return list.map((e) => ApiGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> createGroup({
    required String name,
    required String level,
    String? description,
  }) async {
    try {
      await _api.dio.post('/institution/groups', data: {
        'name': name,
        'level': level,
        if (description != null) 'description': description,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    try {
      await _api.dio.delete('/institution/groups/$groupId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiGroupMember>> getGroupMembers(int groupId) async {
    final res = await _api.dio.get('/institution/groups/$groupId/members');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiGroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> addMemberToGroup(int groupId, String email) async {
    try {
      await _api.dio
          .post('/institution/groups/$groupId/members', data: {'email': email});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(int groupId, int memberId) async {
    try {
      await _api.dio.delete('/institution/groups/$groupId/members/$memberId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiAtRiskStudent>> getAtRiskStudents() async {
    final res = await _api.dio.get('/institution/at-risk');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiAtRiskStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiInstitutionAnalytics> getAnalytics() async {
    final res = await _api.dio.get('/institution/analytics');
    return ApiInstitutionAnalytics.fromJson(
        res.data as Map<String, dynamic>? ?? {});
  }

  Future<String?> getActionPlan() async {
    try {
      final res = await _api.dio.get('/institution/action-plan');
      return (res.data as Map<String, dynamic>?)?['plan'] as String?;
    } catch (_) {
      return null;
    }
  }
}
