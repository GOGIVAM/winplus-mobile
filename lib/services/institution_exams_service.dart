import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();
double? _num(Object? v) => (v as num?)?.toDouble();
int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Refus lisible du serveur (classe introuvable, période invalide…).
class InstitutionExamsException implements Exception {
  final String message;
  const InstitutionExamsException(this.message);
  @override
  String toString() => message;
}

/// Examen blanc programmé par l'établissement. Les notes sont des
/// pourcentages (0 à 100).
class MockExam {
  final int id;
  final String title;
  final String? subject;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final int durationMinutes;
  final DateTime? publishedAt;
  final List<String> groups;
  final int expected;
  final int submitted;
  final double? average;

  const MockExam({
    required this.id,
    required this.title,
    this.subject,
    this.opensAt,
    this.closesAt,
    this.durationMinutes = 0,
    this.publishedAt,
    this.groups = const [],
    this.expected = 0,
    this.submitted = 0,
    this.average,
  });

  factory MockExam.fromJson(Map<String, dynamic> j) => MockExam(
        id: _int(j['id']),
        title: j['title']?.toString() ?? '',
        subject: j['subject'] as String?,
        opensAt: _date(j['opensAt']),
        closesAt: _date(j['closesAt']),
        durationMinutes: _int(j['durationMinutes']),
        publishedAt: _date(j['resultsPublishedAt']),
        groups: (j['groups'] is List ? j['groups'] as List : const []).whereType<Map>().map((g) => '${g['name'] ?? ''}').toList(),
        expected: _int(j['expected']),
        submitted: _int(j['submitted']),
        average: _num(j['average']),
      );

  /// upcoming, open, closed (à publier) ou published.
  String state(DateTime now) {
    if (publishedAt != null) return 'published';
    if (opensAt != null && now.isBefore(opensAt!)) return 'upcoming';
    if (closesAt != null && now.isAfter(closesAt!)) return 'closed';
    return 'open';
  }
}

class RankingLine {
  final int rank;
  final String name;
  final String group;
  final double score;
  final int minutes;
  const RankingLine(this.rank, this.name, this.group, this.score, this.minutes);
}

class ClassLine {
  final String name;
  final int students;
  final int submitted;
  final double? average;
  final double? best;
  const ClassLine(this.name, this.students, this.submitted, this.average, this.best);
}

/// Classement d'un examen blanc (GET /institution/mock-exams/{id}/ranking).
class MockExamRanking {
  final MockExam exam;
  final List<RankingLine> ranking;
  final List<(String, String)> absent;
  final List<ClassLine> byClass;

  /// Répartition des notes : (de, à, nombre) en pourcentage.
  final List<(int, int, int)> buckets;

  const MockExamRanking(this.exam, this.ranking, this.absent, this.byClass, this.buckets);

  factory MockExamRanking.fromJson(Map<String, dynamic> j) => MockExamRanking(
        MockExam.fromJson(j),
        (j['ranking'] is List ? j['ranking'] as List : const [])
            .whereType<Map>()
            .map((r) => RankingLine(_int(r['rank']), '${r['name'] ?? ''}', '${r['groupName'] ?? ''}',
                _num(r['score']) ?? 0, _int(r['minutes'])))
            .toList(),
        (j['absent'] is List ? j['absent'] as List : const [])
            .whereType<Map>()
            .map((a) => ('${a['name'] ?? ''}', '${a['groupName'] ?? ''}'))
            .toList(),
        (j['byClass'] is List ? j['byClass'] as List : const [])
            .whereType<Map>()
            .map((c) => ClassLine('${c['groupName'] ?? ''}', _int(c['students']), _int(c['submitted']),
                _num(c['average']), _num(c['best'])))
            .toList(),
        (j['buckets'] is List ? j['buckets'] as List : const [])
            .whereType<Map>()
            .map((b) => (_int(b['from']), _int(b['to']), _int(b['count'])))
            .toList(),
      );
}

/// Devoir donné par l'établissement à une classe.
class InstitutionHomework {
  final int id;
  final String title;
  final String? instructions;
  final DateTime? dueDate;
  final String? groupName;
  final String? subject;
  final int students;
  final int done;
  final double? average;

  const InstitutionHomework({
    required this.id,
    required this.title,
    this.instructions,
    this.dueDate,
    this.groupName,
    this.subject,
    this.students = 0,
    this.done = 0,
    this.average,
  });

  factory InstitutionHomework.fromJson(Map<String, dynamic> j) => InstitutionHomework(
        id: _int(j['id']),
        title: j['title']?.toString() ?? j['quizTitle']?.toString() ?? '',
        instructions: j['instructions'] as String?,
        dueDate: _date(j['dueDate']),
        groupName: j['groupName'] as String?,
        subject: j['quizSubject'] as String?,
        students: _int(j['students']),
        done: _int(j['done']),
        average: _num(j['averageScore']),
      );
}

/// Avancement d'un élève sur un devoir : done, late ou pending.
class HomeworkProgress {
  final int studentId;
  final String name;
  final String status;
  final double? score;
  const HomeworkProgress(this.studentId, this.name, this.status, this.score);

  factory HomeworkProgress.fromJson(Map<String, dynamic> j) {
    final n = '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim();
    return HomeworkProgress(_int(j['id']), n.isNotEmpty ? n : '${j['email'] ?? ''}',
        j['status']?.toString() ?? 'pending', _num(j['score']));
  }
}

/// Quiz ou épreuve choisi comme sujet d'un examen blanc.
class ExamPick {
  final bool isExam;
  final int id;
  final String title;
  final String? meta;
  const ExamPick({required this.isExam, required this.id, required this.title, this.meta});
}

class SubjectLine {
  final String subject;
  final double average;
  final int quizzes;
  final double? classAverage;
  const SubjectLine(this.subject, this.average, this.quizzes, this.classAverage);
}

/// Bulletin calculé (BulletinData du serveur). Moyennes en pourcentage.
class BulletinData {
  final int studentId;
  final String studentName;
  final String institutionName;
  final List<String> classes;
  final DateTime? from;
  final DateTime? to;
  final double? average;
  final double? classAverage;
  final int? rank;
  final int? classSize;
  final List<SubjectLine> subjects;
  final int homeworkGiven;
  final int homeworkDone;
  final double? homeworkAverage;
  final int activeDays;
  final int studyMinutes;
  final int quizCount;

  const BulletinData({
    required this.studentId,
    required this.studentName,
    this.institutionName = '',
    this.classes = const [],
    this.from,
    this.to,
    this.average,
    this.classAverage,
    this.rank,
    this.classSize,
    this.subjects = const [],
    this.homeworkGiven = 0,
    this.homeworkDone = 0,
    this.homeworkAverage,
    this.activeDays = 0,
    this.studyMinutes = 0,
    this.quizCount = 0,
  });

  factory BulletinData.fromJson(Map<String, dynamic> j) => BulletinData(
        studentId: _int(j['studentId']),
        studentName: j['studentName']?.toString() ?? '',
        institutionName: j['institutionName']?.toString() ?? '',
        classes: (j['classes'] is List ? j['classes'] as List : const []).map((e) => '$e').toList(),
        from: _date(j['from']),
        to: _date(j['to']),
        average: _num(j['average']),
        classAverage: _num(j['classAverage']),
        rank: (j['rank'] as num?)?.toInt(),
        classSize: (j['classSize'] as num?)?.toInt(),
        subjects: (j['subjects'] is List ? j['subjects'] as List : const [])
            .whereType<Map>()
            .map((s) => SubjectLine('${s['subject'] ?? ''}', _num(s['average']) ?? 0, _int(s['quizzes']), _num(s['classAverage'])))
            .toList(),
        homeworkGiven: _int(j['homeworkGiven']),
        homeworkDone: _int(j['homeworkDone']),
        homeworkAverage: _num(j['homeworkAverage']),
        activeDays: _int(j['activeDays']),
        studyMinutes: _int(j['studyMinutes']),
        quizCount: _int(j['quizCount']),
      );
}

/// Bulletin partagé (résumé de liste).
class BulletinSummary {
  final int id;
  final int studentId;
  final String? studentName;
  final String periodLabel;
  final DateTime? sharedAt;
  final String? institutionName;
  const BulletinSummary(this.id, this.studentId, this.studentName, this.periodLabel, this.sharedAt, this.institutionName);

  factory BulletinSummary.fromJson(Map<String, dynamic> j) => BulletinSummary(_int(j['id']), _int(j['studentId']),
      j['studentName'] as String?, j['periodLabel']?.toString() ?? '', _date(j['sharedAt']), j['institutionName'] as String?);
}

/// Bulletin partagé complet (GET /institution/bulletins/{id}).
class SharedBulletin {
  final int id;
  final String periodLabel;
  final DateTime? sharedAt;
  final String? appreciation;
  final String? institutionName;
  final BulletinData? data;
  const SharedBulletin(this.id, this.periodLabel, this.sharedAt, this.appreciation, this.institutionName, this.data);

  factory SharedBulletin.fromJson(Map<String, dynamic> j) => SharedBulletin(
        _int(j['id']),
        j['periodLabel']?.toString() ?? '',
        _date(j['sharedAt']),
        j['appreciation'] as String?,
        j['institutionName'] as String?,
        j['bulletin'] is Map<String, dynamic> ? BulletinData.fromJson(j['bulletin'] as Map<String, dynamic>) : null,
      );
}

/// Examens blancs et bulletins de l'établissement (lot 7), comme
/// InstitutionMockExams et InstitutionBulletins du site.
class InstitutionExamsService {
  InstitutionExamsService._();
  static final InstitutionExamsService instance = InstitutionExamsService._();
  final _api = ApiClient.instance;

  static dynamic _data(dynamic body) => body is Map && body.containsKey('data') ? body['data'] : body;

  static List<Map<String, dynamic>> _list(dynamic body) {
    final d = _data(body);
    final l = d is Map ? (d['items'] ?? d['exams']) : d;
    return (l is List ? l : const []).whereType<Map<String, dynamic>>().toList();
  }

  static InstitutionExamsException _error(Object e) {
    if (e is InstitutionExamsException) return e;
    if (e is DioException) {
      final body = e.response?.data;
      final map = body is Map ? body : null;
      final text = map?['error'] ?? map?['message'];
      if (text is String && text.trim().isNotEmpty) return InstitutionExamsException(text.trim());
    }
    return InstitutionExamsException(L10n.current.commonLoadError);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw _error(e);
    }
  }

  /// Date envoyée en UTC (le serveur compare à DateTime.UtcNow).
  static String _iso(DateTime d) => d.toUtc().toIso8601String();
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Examens blancs ──────────────────────────────────────────────────────

  Future<List<MockExam>> mockExams() => _guard(() async {
        final res = await _api.dio.get('/institution/mock-exams');
        return _list(res.data).map(MockExam.fromJson).toList();
      });

  Future<List<ExamPick>> searchSubjects(String q, {required bool exams}) => _guard(() async {
        if (q.trim().length < 2) return const <ExamPick>[];
        if (exams) {
          final res = await _api.dio.get('/exams/search',
              queryParameters: {'searchTerm': q.trim(), 'onlyPublished': true, 'pageSize': 10});
          return _list(res.data).map((x) {
            final meta = [x['category'] ?? x['subject'], x['year']].where((v) => v != null && '$v'.isNotEmpty).join(' · ');
            return ExamPick(isExam: true, id: _int(x['id']), title: '${x['title'] ?? ''}', meta: meta.isEmpty ? null : meta);
          }).toList();
        }
        final res = await _api.dio.get('/quizzes/search', queryParameters: {'q': q.trim(), 'pageSize': 10});
        return _list(res.data)
            .map((x) => ExamPick(isExam: false, id: _int(x['id']), title: '${x['title'] ?? ''}', meta: x['subject'] as String?))
            .toList();
      });

  /// Programme un examen blanc ; renvoie le nombre d'élèves convoqués.
  Future<int> createMockExam({
    required List<int> groupIds,
    required ExamPick subject,
    String? title,
    required DateTime opensAt,
    required DateTime closesAt,
    required int durationMinutes,
  }) =>
      _guard(() async {
        final res = await _api.dio.post('/institution/mock-exams', data: {
          'groupIds': groupIds,
          'quizId': subject.isExam ? null : subject.id,
          'examId': subject.isExam ? subject.id : null,
          if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
          'opensAt': _iso(opensAt),
          'closesAt': _iso(closesAt),
          'durationMinutes': durationMinutes,
        });
        final d = _data(res.data);
        return d is Map ? _int(d['students']) : 0;
      });

  Future<MockExamRanking> ranking(int id) => _guard(() async {
        final res = await _api.dio.get('/institution/mock-exams/$id/ranking');
        final d = _data(res.data);
        return MockExamRanking.fromJson(d is Map<String, dynamic> ? d : const {});
      });

  Future<void> publish(int id) => _guard(() => _api.dio.post('/institution/mock-exams/$id/publish', data: const {}));

  Future<void> deleteMockExam(int id) => _guard(() => _api.dio.delete('/institution/mock-exams/$id'));

  // ── Devoirs de l'établissement ──────────────────────────────────────────

  Future<List<InstitutionHomework>> homework() => _guard(() async {
        final res = await _api.dio.get('/institution/homework');
        return _list(res.data).map(InstitutionHomework.fromJson).toList();
      });

  /// Donne un devoir (quiz ou épreuve) à une classe ; date limite facultative.
  Future<void> createHomework({
    required int groupId,
    required ExamPick subject,
    String? title,
    String? instructions,
    DateTime? dueDate,
  }) =>
      _guard(() => _api.dio.post('/institution/homework', data: {
            'studyGroupId': groupId,
            'quizId': subject.isExam ? null : subject.id,
            'examId': subject.isExam ? subject.id : null,
            if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
            if ((instructions ?? '').trim().isNotEmpty) 'instructions': instructions!.trim(),
            if (dueDate != null) 'dueDate': _iso(dueDate),
          }));

  Future<List<HomeworkProgress>> homeworkProgress(int id) => _guard(() async {
        final res = await _api.dio.get('/institution/homework/$id/progress');
        return _list(res.data).map(HomeworkProgress.fromJson).toList();
      });

  Future<void> deleteHomework(int id) => _guard(() => _api.dio.delete('/institution/homework/$id'));

  // ── Bulletins ───────────────────────────────────────────────────────────

  Future<BulletinData> preview(int studentId, DateTime from, DateTime to) => _guard(() async {
        final res = await _api.dio.get('/institution/bulletins/preview',
            queryParameters: {'studentId': studentId, 'from': _day(from), 'to': _day(to)});
        final d = _data(res.data);
        return BulletinData.fromJson(d is Map<String, dynamic> ? d : const {});
      });

  /// Appréciation proposée par WinAI (ou calculée si WinAI ne répond pas).
  Future<String> appreciation(int studentId, DateTime from, DateTime to, String periodLabel) => _guard(() async {
        final res = await _api.dio.post('/institution/bulletins/appreciation', data: {
          'studentId': studentId,
          'from': _day(from),
          'to': _day(to),
          'periodLabel': periodLabel,
        });
        final d = _data(res.data);
        return d is Map ? '${d['appreciation'] ?? ''}'.trim() : '';
      });

  /// Enregistre et partage le bulletin (élève et parents) ; renvoie le
  /// nombre de parents prévenus.
  Future<int> share(int studentId, DateTime from, DateTime to, String periodLabel, String? appreciation) =>
      _guard(() async {
        final res = await _api.dio.post('/institution/bulletins', data: {
          'studentId': studentId,
          'from': _day(from),
          'to': _day(to),
          'periodLabel': periodLabel.trim(),
          'appreciation': (appreciation ?? '').trim().isEmpty ? null : appreciation!.trim(),
        });
        final d = _data(res.data);
        return d is Map ? _int(d['parents']) : 0;
      });

  /// Bulletins partagés par l'établissement.
  Future<List<BulletinSummary>> sharedBulletins({int? studentId}) => _guard(() async {
        final res = await _api.dio
            .get('/institution/bulletins', queryParameters: studentId == null ? null : {'studentId': studentId});
        return _list(res.data).map(BulletinSummary.fromJson).toList();
      });

  /// Bulletins reçus (élève, ou parent pour ses enfants).
  Future<List<BulletinSummary>> myBulletins() => _guard(() async {
        final res = await _api.dio.get('/institution/bulletins/mine');
        return _list(res.data).map(BulletinSummary.fromJson).toList();
      });

  Future<SharedBulletin> bulletin(int id) => _guard(() async {
        final res = await _api.dio.get('/institution/bulletins/$id');
        final d = _data(res.data);
        return SharedBulletin.fromJson(d is Map<String, dynamic> ? d : const {});
      });

  Future<void> deleteBulletin(int id) => _guard(() => _api.dio.delete('/institution/bulletins/$id'));
}
