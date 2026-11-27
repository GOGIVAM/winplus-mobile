import 'package:dio/dio.dart';

import 'api_client.dart';

/// Période de l'analyse de l'établissement (paramètre period du serveur).
enum AnalyticsPeriod {
  week('7d'),
  month('30d'),
  term('term'),
  year('year');

  final String code;
  const AnalyticsPeriod(this.code);
}

/// Chiffres clés de la période, avec ceux de la période précédente (même
/// durée) pour la tendance. Les moyennes sont des pourcentages 0-100 (null
/// sans quiz sur la période).
class AnalyticsKpis {
  final int enrolled;
  final int neverLoggedIn;
  final int active;
  final int? activePrev;
  final double? avgScore;
  final double? avgScorePrev;
  final int quizzes;
  final int? quizzesPrev;
  const AnalyticsKpis({
    this.enrolled = 0,
    this.neverLoggedIn = 0,
    this.active = 0,
    this.activePrev,
    this.avgScore,
    this.avgScorePrev,
    this.quizzes = 0,
    this.quizzesPrev,
  });

  factory AnalyticsKpis.fromJson(Map j) => AnalyticsKpis(
        enrolled: (j['enrolled'] as num?)?.toInt() ?? 0,
        neverLoggedIn: (j['neverLoggedIn'] as num?)?.toInt() ?? 0,
        active: (j['active'] as num?)?.toInt() ?? 0,
        activePrev: (j['activePrev'] as num?)?.toInt(),
        avgScore: (j['avgScore'] as num?)?.toDouble(),
        avgScorePrev: (j['avgScorePrev'] as num?)?.toDouble(),
        quizzes: (j['quizzes'] as num?)?.toInt() ?? 0,
        quizzesPrev: (j['quizzesPrev'] as num?)?.toInt(),
      );
}

class AnalyticsWeek {
  final DateTime weekStart;
  final int active;
  final int quizzes;
  final double? avgScore;
  const AnalyticsWeek(this.weekStart, this.active, this.quizzes, this.avgScore);

  factory AnalyticsWeek.fromJson(Map j) => AnalyticsWeek(
        DateTime.tryParse('${j['weekStart'] ?? ''}') ?? DateTime.now(),
        (j['active'] as num?)?.toInt() ?? 0,
        (j['quizzes'] as num?)?.toInt() ?? 0,
        (j['avgScore'] as num?)?.toDouble(),
      );
}

class AnalyticsGroup {
  final int id;
  final String name;
  final int students;
  final int active;
  final double? avgScore;
  const AnalyticsGroup(this.id, this.name, this.students, this.active, this.avgScore);

  factory AnalyticsGroup.fromJson(Map j) => AnalyticsGroup(
        (j['id'] as num?)?.toInt() ?? 0,
        '${j['name'] ?? ''}',
        (j['students'] as num?)?.toInt() ?? 0,
        (j['active'] as num?)?.toInt() ?? 0,
        (j['avgScore'] as num?)?.toDouble(),
      );
}

class AnalyticsSubject {
  final String subject;
  final int attempts;
  final double? avgScore;
  const AnalyticsSubject(this.subject, this.attempts, this.avgScore);

  factory AnalyticsSubject.fromJson(Map j) => AnalyticsSubject(
        '${j['subject'] ?? ''}',
        (j['attempts'] as num?)?.toInt() ?? 0,
        (j['avgScore'] as num?)?.toDouble(),
      );
}

class AnalyticsRiskStudent {
  final int studentId;
  final String name;
  final String? groupName;
  final String riskReason;
  const AnalyticsRiskStudent(this.studentId, this.name, this.groupName, this.riskReason);

  factory AnalyticsRiskStudent.fromJson(Map j) => AnalyticsRiskStudent(
        (j['studentId'] as num?)?.toInt() ?? 0,
        '${j['name'] ?? ''}',
        j['groupName'] as String?,
        '${j['riskReason'] ?? ''}',
      );
}

/// Analyse de l'établissement (GET /institution/analytics/overview), pour
/// l'onglet Analyses refait à la demande de Georges (G8).
class InstitutionOverview {
  final AnalyticsKpis kpis;
  final List<AnalyticsWeek> weekly;
  final List<AnalyticsGroup> groups;
  final List<AnalyticsSubject> subjects;
  final int downloads;
  final int homeworkGiven;
  final int homeworkSubmitted;
  final int mockExamsTaken;
  final int riskCritical;
  final int riskModerate;
  final List<AnalyticsRiskStudent> riskTop;

  /// Vrai quand l'ancienne route a servi de repli (serveur pas encore à
  /// jour) : seuls les chiffres clés sont connus.
  final bool partial;

  const InstitutionOverview({
    this.kpis = const AnalyticsKpis(),
    this.weekly = const [],
    this.groups = const [],
    this.subjects = const [],
    this.downloads = 0,
    this.homeworkGiven = 0,
    this.homeworkSubmitted = 0,
    this.mockExamsTaken = 0,
    this.riskCritical = 0,
    this.riskModerate = 0,
    this.riskTop = const [],
    this.partial = false,
  });

  bool get hasActivity => kpis.active > 0 || kpis.quizzes > 0 || downloads > 0;

  factory InstitutionOverview.fromJson(Map body) {
    final d = body['data'] is Map ? body['data'] as Map : body;
    List<T> list<T>(String k, T Function(Map) f) =>
        (d[k] is List ? d[k] as List : const []).whereType<Map>().map(f).toList();
    final content = d['content'] is Map ? d['content'] as Map : const {};
    final risk = d['atRisk'] is Map ? d['atRisk'] as Map : const {};
    int n(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
    return InstitutionOverview(
      kpis: AnalyticsKpis.fromJson(d['kpis'] is Map ? d['kpis'] as Map : const {}),
      weekly: list('weekly', AnalyticsWeek.fromJson),
      groups: list('groups', AnalyticsGroup.fromJson),
      subjects: list('subjects', AnalyticsSubject.fromJson),
      downloads: n(content, 'downloads'),
      homeworkGiven: n(content, 'homeworkGiven'),
      homeworkSubmitted: n(content, 'homeworkSubmitted'),
      mockExamsTaken: n(content, 'mockExamsTaken'),
      riskCritical: n(risk, 'critical'),
      riskModerate: n(risk, 'moderate'),
      riskTop: (risk['top'] is List ? risk['top'] as List : const [])
          .whereType<Map>()
          .map(AnalyticsRiskStudent.fromJson)
          .toList(),
    );
  }

  /// Repli sur GET /institution/analytics (chiffres du mois seulement).
  factory InstitutionOverview.fromLegacy(Map j) => InstitutionOverview(
        kpis: AnalyticsKpis(
          enrolled: (j['totalStudents'] as num?)?.toInt() ?? 0,
          active: (j['activeStudents'] as num?)?.toInt() ?? 0,
          avgScore: (j['averageScore'] as num?)?.toDouble(),
          quizzes: (j['quizzesThisMonth'] as num?)?.toInt() ?? 0,
        ),
        downloads: (j['downloadsThisMonth'] as num?)?.toInt() ?? 0,
        partial: true,
      );
}

class InstitutionAnalyticsService {
  InstitutionAnalyticsService._();
  static final InstitutionAnalyticsService instance = InstitutionAnalyticsService._();

  final _api = ApiClient.instance;

  Future<InstitutionOverview> overview(AnalyticsPeriod period, {int? groupId}) async {
    try {
      final res = await _api.dio.get('/institution/analytics/overview', queryParameters: {
        'period': period.code,
        if (groupId != null) 'groupId': groupId,
      });
      return InstitutionOverview.fromJson(res.data is Map ? res.data as Map : const {});
    } on DioException catch (e) {
      // Serveur pas encore à jour : chiffres du mois de l'ancienne route.
      if (e.response?.statusCode != 404 || groupId != null) rethrow;
      final res = await _api.dio.get('/institution/analytics');
      return InstitutionOverview.fromLegacy(res.data is Map ? res.data as Map : const {});
    }
  }
}
