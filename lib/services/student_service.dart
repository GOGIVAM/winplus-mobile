import 'api_client.dart';
import '../data/models.dart';

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
            : '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}',
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
