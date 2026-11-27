import 'api_client.dart';

class ApiInstitutionStudent {
  final int id;

  /// Compte de l'élève (id est la ligne de rattachement à l'établissement).
  final int studentId;
  final String firstName;
  final String lastName;
  final String email;
  final String? level;
  final String? group;
  final String? matricule;
  final double? averageScore;
  final bool isActive;

  const ApiInstitutionStudent({
    required this.id,
    this.studentId = 0,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.level,
    this.group,
    this.matricule,
    this.averageScore,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApiInstitutionStudent.fromJson(Map<String, dynamic> j) =>
      ApiInstitutionStudent(
        id: j['id'] as int? ?? 0,
        studentId: (j['studentId'] as num?)?.toInt() ?? (j['id'] as int? ?? 0),
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        email: j['email'] as String? ?? '',
        level: j['level'] as String?,
        group: j['group'] as String?,
        matricule: j['matricule'] as String?,
        // Le serveur nomme la moyenne « avgScore » (en pourcentage).
        averageScore:
            ((j['avgScore'] ?? j['averageScore']) as num?)?.toDouble(),
        isActive: j['isActive'] as bool? ?? true,
      );
}

class ApiInstitutionKpis {
  final int totalStudents;

  /// Élèves connectés dans les dernières 24 heures.
  final int activeStudents;

  /// Moyenne des quiz en pourcentage ; null tant qu'aucun quiz n'est fait.
  final double? averageScore;

  const ApiInstitutionKpis({
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.averageScore,
  });

  /// Le serveur enveloppe la réponse : { data: { studentsTotal, activeToday,
  /// avgScore, ... } }. Les anciens noms restent lus.
  factory ApiInstitutionKpis.fromJson(Map<String, dynamic> j) {
    final d = j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : j;
    num? n(String a, String b) => (d[a] ?? d[b]) as num?;
    return ApiInstitutionKpis(
      totalStudents: n('studentsTotal', 'totalStudents')?.toInt() ?? 0,
      activeStudents: n('activeToday', 'activeStudents')?.toInt() ?? 0,
      averageScore: n('avgScore', 'averageScore')?.toDouble(),
    );
  }
}

/// Une page de l'annuaire : les élèves, leur nombre total et le nombre de
/// classes de l'établissement (null si le serveur ne le donne pas).
class ApiStudentDirectoryPage {
  final List<ApiInstitutionStudent> students;
  final int total;
  final int? groupCount;
  const ApiStudentDirectoryPage(
      {required this.students, required this.total, this.groupCount});
}

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
  final String level;
  final double riskScore;
  final String riskReason;
  final String weakSubject;
  final int weakScore;

  /// Moyenne des quiz sur 30 jours, en pourcentage ; null sans quiz.
  final int? globalScore;

  /// Faux quand l'élève n'a fait aucun quiz : pas de note à afficher.
  final bool hasScores;
  final int inactiveDays;
  const ApiAtRiskStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.groupName,
    this.level = '',
    required this.riskScore,
    required this.riskReason,
    this.weakSubject = '',
    this.weakScore = 0,
    this.globalScore,
    this.hasScores = false,
    this.inactiveDays = 0,
  });

  String get fullName => '$firstName $lastName'.trim();
  /// D'après le risque calculé par le serveur (0 à 1) ; sans lui (ancien
  /// serveur), d'après la note et l'inactivité.
  bool get isCritical => riskScore > 0
      ? riskScore >= 0.75
      : (hasScores && (globalScore ?? 100) < 40) || inactiveDays > 7;

  factory ApiAtRiskStudent.fromJson(Map<String, dynamic> j) => ApiAtRiskStudent(
        id: j['id'] as int? ?? 0,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        groupName: j['groupName'] as String?,
        level: j['level'] as String? ?? '',
        // De 0 à 1 ; une valeur sur 100 (ancien serveur) est ramenée à 1.
        riskScore: switch (((j['riskScore'] ?? 0) as num).toDouble()) {
          final r when r > 1 => r / 100,
          final r => r,
        },
        riskReason: j['riskReason'] as String? ?? '',
        weakSubject: j['weakSubject'] as String? ?? '',
        weakScore: (j['weakScore'] as num?)?.round() ?? 0,
        globalScore: (j['globalScore'] as num?)?.round(),
        // L'ancien serveur envoyait 0 en dur sans « hasScores ».
        hasScores: j['hasScores'] as bool? ??
            ((j['globalScore'] as num? ?? 0) > 0),
        inactiveDays: (j['inactiveDays'] as num?)?.toInt() ?? 0,
      );
}

class ApiInstitutionAnalytics {
  final int totalStudents;
  final int activeStudents;
  /// Pourcentage 0-100 ; null sans quiz (le serveur omet le champ : un 0
  /// affichait « 0/20 » à côté d'élèves notés).
  final double? averageScore;
  final int downloadsThisMonth;
  final int quizzesThisMonth;
  final Map<String, int> activityByDay;
  const ApiInstitutionAnalytics({
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.averageScore,
    this.downloadsThisMonth = 0,
    this.quizzesThisMonth = 0,
    this.activityByDay = const {},
  });

  factory ApiInstitutionAnalytics.fromJson(Map<String, dynamic> j) =>
      ApiInstitutionAnalytics(
        totalStudents: j['totalStudents'] as int? ?? 0,
        activeStudents: j['activeStudents'] as int? ?? 0,
        averageScore: (j['averageScore'] as num?)?.toDouble(),
        downloadsThisMonth: j['downloadsThisMonth'] as int? ?? 0,
        quizzesThisMonth: j['quizzesThisMonth'] as int? ?? 0,
        activityByDay: (j['activityByDay'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int? ?? 0)),
      );
}

/// Une action du plan WinAI (réponse Python relayée par
/// GET /api/institution/action-plan : actions[].priority/action/effort/estimated_impact).
class ApiActionPlanItem {
  final int priority;
  final String action;
  final String effort;
  final String estimatedImpact;
  const ApiActionPlanItem({
    required this.priority,
    required this.action,
    this.effort = '',
    this.estimatedImpact = '',
  });

  factory ApiActionPlanItem.fromJson(Map<String, dynamic> j) =>
      ApiActionPlanItem(
        priority: (j['priority'] as num?)?.toInt() ?? 0,
        action: j['action']?.toString() ?? '',
        effort: j['effort']?.toString() ?? '',
        estimatedImpact: j['estimated_impact']?.toString() ?? '',
      );
}

/// Plan d'action hebdomadaire WinAI de l'établissement.
class ApiActionPlan {
  final List<ApiActionPlanItem> actions;
  final String? weekLabel;
  final int studentCount;
  final int atRiskCount;
  final int inactiveCount;

  /// Renseigné par .NET quand aucun élève n'est rattaché (liste vide légitime).
  final String? message;

  const ApiActionPlan({
    this.actions = const [],
    this.weekLabel,
    this.studentCount = 0,
    this.atRiskCount = 0,
    this.inactiveCount = 0,
    this.message,
  });

  factory ApiActionPlan.fromJson(Map<String, dynamic> j) {
    final ctx = j['context'] as Map<String, dynamic>? ?? const {};
    return ApiActionPlan(
      actions: (j['actions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ApiActionPlanItem.fromJson)
          .where((a) => a.action.isNotEmpty)
          .toList(),
      weekLabel: j['week_label'] as String?,
      studentCount: (ctx['student_count'] as num?)?.toInt() ?? 0,
      atRiskCount: (ctx['at_risk_count'] as num?)?.toInt() ?? 0,
      inactiveCount: (ctx['inactive_count'] as num?)?.toInt() ?? 0,
      message: j['message'] as String?,
    );
  }
}

/// Licence en cours de l'établissement (GET /institution/license), résumé
/// affiché sur l'accueil. `null` côté service quand aucune licence n'est active.
class ApiInstitutionLicenseSummary {
  final String tier;
  final String status;
  final int studentSeats;
  final int studentSeatsUsed;
  const ApiInstitutionLicenseSummary({
    required this.tier,
    required this.status,
    required this.studentSeats,
    required this.studentSeatsUsed,
  });

  factory ApiInstitutionLicenseSummary.fromJson(Map<String, dynamic> j) =>
      ApiInstitutionLicenseSummary(
        tier: j['tier'] as String? ?? '',
        status: j['status'] as String? ?? '',
        studentSeats: (j['studentSeats'] as num?)?.toInt() ?? 0,
        studentSeatsUsed: (j['studentSeatsUsed'] as num?)?.toInt() ?? 0,
      );
}

class InstitutionService {
  InstitutionService._();
  static final InstitutionService instance = InstitutionService._();

  final _api = ApiClient.instance;

  /// Nom réel de l'établissement rattaché au compte (GET /institution/me),
  /// remplace WinData.institutionStats.name. Null si non rattaché.
  Future<String?> getMyInstitutionName() async {
    try {
      final res = await _api.dio.get('/institution/me');
      final body = res.data;
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      final name = (data['name'] as String?)?.trim();
      return (name == null || name.isEmpty) ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Licence en cours (GET /institution/license) ; null sans licence active
  /// ou en cas d'erreur réseau.
  Future<ApiInstitutionLicenseSummary?> getLicenseSummary() async {
    try {
      final res = await _api.dio.get('/institution/license');
      final lic = (res.data as Map<String, dynamic>?)?['license'];
      return lic is Map<String, dynamic>
          ? ApiInstitutionLicenseSummary.fromJson(lic)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ApiGroup>> getGroups() async {
    final res = await _api.dio.get('/institution/groups');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> createGroup({
    required String name,
    required String level,
    String? description,
  }) async =>
      await createGroupWithId(
          name: name, level: level, description: description) !=
      null;

  /// Crée le groupe et renvoie son identifiant (pour y ajouter les élèves
  /// choisis), ou null en cas d'échec.
  Future<int?> createGroupWithId({
    required String name,
    required String level,
    String? description,
  }) async {
    try {
      final res = await _api.dio.post('/institution/groups', data: {
        'name': name,
        'level': level,
        if (description != null) 'description': description,
      });
      final body = res.data;
      final data = body is Map && body['data'] is Map ? body['data'] : body;
      final id = data is Map ? data['id'] : null;
      // Ancienne réponse sans identifiant : le groupe existe quand même.
      return id is num ? id.toInt() : 0;
    } catch (_) {
      return null;
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

  /// Module 23 : lisait un champ `plan` que Python ne renvoie pas (toujours
  /// null) et avalait les erreurs. Renvoie désormais le plan réel ; une erreur
  /// réseau ou serveur remonte à l'écran, qui affiche un état d'échec.
  Future<ApiActionPlan> getActionPlan() async {
    final res = await _api.dio.get('/institution/action-plan');
    return ApiActionPlan.fromJson(res.data as Map<String, dynamic>? ?? {});
  }

  Future<int?> getMyInstitutionId() async {
    try {
      final res = await _api.dio.get('/institution/me');
      // Le serveur enveloppe la réponse : { data: { id, name, ... }, success }.
      final body = res.data as Map<String, dynamic>?;
      final data = body?['data'] is Map<String, dynamic>
          ? body!['data'] as Map<String, dynamic>
          : body;
      return (data?['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<List<ApiInstitutionStudent>> getStudentDirectory(
    int institutionId, {
    String? q,
    int page = 1,
    int pageSize = 50,
  }) async =>
      (await getStudentDirectoryPage(institutionId,
              q: q, page: page, pageSize: pageSize))
          .students;

  /// Le serveur répond { data: [...], total, filters: { groups, levels } }
  /// (le mobile lisait « items » : l'annuaire restait vide).
  Future<ApiStudentDirectoryPage> getStudentDirectoryPage(
    int institutionId, {
    String? q,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _api.dio.get(
      '/institution/$institutionId/students',
      queryParameters: {
        // Le serveur lit « search » (avant : « q », ignoré : la recherche
        // de l'annuaire ne filtrait rien).
        if (q != null && q.isNotEmpty) 'search': q,
        'page': page,
        'pageSize': pageSize,
      },
    );
    final data = res.data;
    final list =
        (data is Map ? (data['data'] ?? data['items']) : data) as List? ?? [];
    final students = list
        .whereType<Map>()
        .map((e) => ApiInstitutionStudent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final filters = data is Map ? data['filters'] : null;
    final groups = filters is Map ? filters['groups'] : null;
    return ApiStudentDirectoryPage(
      students: students,
      total: data is Map
          ? (data['total'] as num?)?.toInt() ?? students.length
          : students.length,
      groupCount: groups is List ? groups.length : null,
    );
  }

  Future<ApiInstitutionKpis> getInstitutionKpis(int institutionId) async {
    try {
      final res = await _api.dio.get('/institution/$institutionId/kpis');
      return ApiInstitutionKpis.fromJson(
          res.data as Map<String, dynamic>? ?? {});
    } catch (_) {
      return const ApiInstitutionKpis();
    }
  }

  Future<bool> addInstitutionStudent(
    int institutionId,
    String email, {
    String? level,
    String? group,
    String? matricule,
  }) async {
    try {
      await _api.dio.post(
        '/institution/$institutionId/students/import',
        data: {
          'rows': [
            {
              'email': email,
              if (level != null) 'level': level,
              if (group != null) 'group': group,
              if (matricule != null) 'matricule': matricule,
            }
          ],
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
