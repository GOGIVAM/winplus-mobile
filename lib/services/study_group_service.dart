import 'api_client.dart';

/// Groupes d'étude collaboratifs (voir StudyGroupsController.cs côté
/// backend : GET/POST /api/study-groups, mêmes endpoints que le web
/// studentExtraService.getStudyGroups/createStudyGroup/joinStudyGroup).
/// Module 24 (lot 8, rattrapage 16.3) : remplace l'écran mobile 100%
/// simulé (classement et groupes fictifs, code "ABC123" codé en dur).
class ApiStudyGroup {
  final int id;
  final String name;
  final String? subject;
  final String? description;
  final String joinCode;
  final String? role;
  final bool isOwner;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  const ApiStudyGroup({
    required this.id,
    required this.name,
    this.subject,
    this.description,
    required this.joinCode,
    this.role,
    required this.isOwner,
    required this.memberCount,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory ApiStudyGroup.fromJson(Map<String, dynamic> j) => ApiStudyGroup(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        subject: j['subject'] as String?,
        description: j['description'] as String?,
        joinCode: j['joinCode'] as String? ?? '',
        role: j['role'] as String?,
        isOwner: j['isOwner'] as bool? ?? false,
        memberCount: j['memberCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        lastActivityAt: DateTime.tryParse(j['lastActivityAt'] as String? ?? ''),
      );
}

class ApiStudyGroupMember {
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? level;
  final String role;
  const ApiStudyGroupMember({
    required this.userId,
    this.firstName,
    this.lastName,
    this.level,
    required this.role,
  });

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  factory ApiStudyGroupMember.fromJson(Map<String, dynamic> j) => ApiStudyGroupMember(
        userId: j['userId'] as int? ?? 0,
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        level: j['level'] as String?,
        role: j['role'] as String? ?? 'member',
      );
}

class ApiStudyGroupDetail extends ApiStudyGroup {
  final List<ApiStudyGroupMember> members;
  const ApiStudyGroupDetail({
    required super.id,
    required super.name,
    super.subject,
    super.description,
    required super.joinCode,
    required super.isOwner,
    required super.memberCount,
    required super.createdAt,
    required this.members,
  });

  factory ApiStudyGroupDetail.fromJson(Map<String, dynamic> j) => ApiStudyGroupDetail(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        subject: j['subject'] as String?,
        description: j['description'] as String?,
        joinCode: j['joinCode'] as String? ?? '',
        isOwner: j['isOwner'] as bool? ?? false,
        memberCount: ((j['members'] as List?) ?? []).length,
        createdAt: DateTime.now(),
        members: ((j['members'] as List?) ?? [])
            .map((e) => ApiStudyGroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class StudyGroupJoinResult {
  final int id;
  final String name;
  final bool alreadyMember;
  const StudyGroupJoinResult({required this.id, required this.name, required this.alreadyMember});
}

class StudyGroupService {
  StudyGroupService._();
  static final StudyGroupService instance = StudyGroupService._();

  final _api = ApiClient.instance;

  Future<List<ApiStudyGroup>> getMine() async {
    final res = await _api.dio.get('/study-groups/me');
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => ApiStudyGroup.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<ApiStudyGroupDetail> getOne(int id) async {
    final res = await _api.dio.get('/study-groups/$id');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ApiStudyGroupDetail.fromJson(data);
  }

  Future<ApiStudyGroup> create({required String name, String? subject, String? description}) async {
    final res = await _api.dio.post('/study-groups', data: {
      'name': name,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ApiStudyGroup.fromJson(data);
  }

  Future<StudyGroupJoinResult> join(String code) async {
    final res = await _api.dio.post('/study-groups/join', data: {'code': code});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return StudyGroupJoinResult(
      id: data['id'] as int? ?? 0,
      name: data['name'] as String? ?? '',
      alreadyMember: data['alreadyMember'] as bool? ?? false,
    );
  }

  Future<void> leave(int id) async {
    await _api.dio.delete('/study-groups/$id/leave');
  }
}
