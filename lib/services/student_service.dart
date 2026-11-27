import 'api_client.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';

/// Module 24 (lot 8) : remplace les données fictives du dashboard étudiant
/// (lib/student/student_home.dart, lib/student/student_tabs.dart) par de
/// vrais appels à StudentController.cs (déjà livré au lot 2/4, jamais
/// consommé côté mobile jusqu'ici).
class StudentService {
  StudentService._();
  static final StudentService instance = StudentService._();

  final _api = ApiClient.instance;

  /// GET /student/stats — statistiques réelles (streak non inclus ici : voir
  /// UsersController.GetUserStatistics, déjà câblé par achievement_service).
  Future<ApiStudentStats> getStats() async {
    final res = await _api.dio.get('/student/stats');
    final data = (res.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>? ??
        const {};
    return ApiStudentStats.fromJson(data);
  }

  /// GET /student/reports?period= — rapport de progression calculé par le
  /// serveur (quiz, sessions d'étude, téléchargements), comme le site.
  /// [periodDays] : 7, 30, 90 ou 365.
  Future<ApiStudentReport> getReport(int periodDays) async {
    final res = await _api.dio
        .get('/student/reports', queryParameters: {'period': periodDays});
    final body = res.data;
    final data = body is Map && body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : const <String, dynamic>{};
    return ApiStudentReport.fromJson(data);
  }

  /// GET /student/learning/continue — formations en cours, non terminées.
  Future<List<InProgressContent>> getContinueLearning() async {
    final res = await _api.dio.get('/student/learning/continue');
    final list = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      final progress = ((j['progress'] ?? 0) as num).round();
      return InProgressContent(
        (j['subjectId'] ?? 0).toString(),
        j['title'] as String? ?? '',
        j['category'] as String? ?? 'math',
        progress,
        '',
      );
    }).toList();
  }

  /// GET /student/events/upcoming — prochaines échéances réelles (examens,
  /// renouvellements...), remplace WinData.upcomingExams.
  Future<List<ExamCountdown>> getUpcomingEvents({int limit = 5}) async {
    final res = await _api.dio
        .get('/student/events/upcoming', queryParameters: {'limit': limit});
    final list = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    final now = DateTime.now();
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      final start = DateTime.tryParse(j['startDate'] as String? ?? '');
      final daysLeft = start == null ? 0 : start.difference(now).inDays;
      return ExamCountdown(
        j['title'] as String? ?? '',
        start == null
            ? ''
            : WinFormat.dateNumeric(start),
        daysLeft,
        'math',
      );
    }).toList();
  }
}

class ApiStudentStats {
  final double averageScore;
  final double hoursSpent;
  final int quizCompleted;
  final int weeklyQuizCompleted;
  final List<double> weeklyStudyHours;
  final int totalDownloads;
  const ApiStudentStats({
    required this.averageScore,
    required this.hoursSpent,
    required this.quizCompleted,
    required this.weeklyQuizCompleted,
    required this.weeklyStudyHours,
    required this.totalDownloads,
  });

  double get weeklyStudyHoursTotal =>
      weeklyStudyHours.fold(0.0, (a, b) => a + b);

  /// Lot 1 : moyenne des quiz en note sur 20 ; « – » tant qu'aucun quiz
  /// n'est noté (le serveur envoie alors 0).
  /// Le serveur envoie 0 quand aucun quiz n'a de note, même si des quiz sont
  /// comptés (quizCompleted) : 0 vaut donc « pas de moyenne ».
  String get averageGrade =>
      averageScore == 0 ? WinFormat.none : WinFormat.grade20(averageScore);

  factory ApiStudentStats.fromJson(Map<String, dynamic> j) => ApiStudentStats(
        averageScore: ((j['averageScore'] ?? 0) as num).toDouble(),
        hoursSpent: ((j['hoursSpent'] ?? 0) as num).toDouble(),
        quizCompleted: j['quizCompleted'] as int? ?? 0,
        weeklyQuizCompleted: j['weeklyQuizCompleted'] as int? ?? 0,
        weeklyStudyHours: (j['weeklyStudyHours'] as List? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        totalDownloads: j['totalDownloads'] as int? ?? 0,
      );
}

/// Rapport de progression de l'élève (GET /student/reports). Les valeurs
/// absentes (aucun quiz sur la période) restent nulles : l'écran affiche
/// « — » au lieu d'un chiffre inventé.
class ApiStudentReport {
  final int periodDays;
  final int? avgScore;
  final int quizTotal;
  final int? quizSuccessRate;
  final double studyHours;
  final int downloads;
  final List<({String subject, int score, int quizzes})> subjectScores;
  final List<({DateTime weekStart, int? score, int quizzes})> weeklyScores;
  final String? bestSubject;
  final String? weakestSubject;

  const ApiStudentReport({
    required this.periodDays,
    this.avgScore,
    this.quizTotal = 0,
    this.quizSuccessRate,
    this.studyHours = 0,
    this.downloads = 0,
    this.subjectScores = const [],
    this.weeklyScores = const [],
    this.bestSubject,
    this.weakestSubject,
  });

  static int? _int(Object? v) => v is num ? v.round() : null;

  factory ApiStudentReport.fromJson(Map<String, dynamic> j) => ApiStudentReport(
        periodDays: _int(j['periodDays']) ?? 30,
        avgScore: _int(j['avgScore']),
        quizTotal: _int(j['quizTotal']) ?? 0,
        quizSuccessRate: _int(j['quizSuccessRate']),
        studyHours: (j['studyHours'] as num?)?.toDouble() ?? 0,
        downloads: _int(j['downloads']) ?? 0,
        subjectScores: [
          for (final e in (j['subjectScores'] as List? ?? const []))
            if (e is Map)
              (
                subject: e['subject']?.toString() ?? '',
                score: _int(e['score']) ?? 0,
                quizzes: _int(e['quizzes']) ?? 0,
              ),
        ],
        weeklyScores: [
          for (final e in (j['weeklyScores'] as List? ?? const []))
            if (e is Map)
              (
                weekStart: DateTime.tryParse(e['weekStart']?.toString() ?? '') ??
                    DateTime.now(),
                score: _int(e['score']),
                quizzes: _int(e['quizzes']) ?? 0,
              ),
        ],
        bestSubject: j['bestSubject'] as String?,
        weakestSubject: j['weakestSubject'] as String?,
      );

  /// Aucun quiz terminé sur la période.
  bool get isEmpty => quizTotal == 0;
}