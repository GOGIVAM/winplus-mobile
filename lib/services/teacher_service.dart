import 'api_client.dart';

class ApiPublishedContent {
  final int id;
  final String title;
  final String status;
  final int downloads;
  final double rating;
  final int revenue;
  final String type;
  const ApiPublishedContent({
    required this.id,
    required this.title,
    required this.status,
    required this.downloads,
    required this.rating,
    required this.revenue,
    required this.type,
  });

  factory ApiPublishedContent.fromJson(Map<String, dynamic> j) =>
      ApiPublishedContent(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'draft',
        downloads: j['downloadCount'] as int? ?? 0,
        rating: ((j['averageRating'] ?? 0) as num).toDouble(),
        revenue: j['revenue'] as int? ?? 0,
        type: j['category'] as String? ?? 'epreuve',
      );
}

class ApiSubmission {
  final int id;
  final String studentName;
  final String contentTitle;
  final String submittedAt;
  final bool corrected;
  final int? score;
  const ApiSubmission({
    required this.id,
    required this.studentName,
    required this.contentTitle,
    required this.submittedAt,
    required this.corrected,
    this.score,
  });

  factory ApiSubmission.fromJson(Map<String, dynamic> j) => ApiSubmission(
        id: j['id'] as int? ?? 0,
        studentName: j['studentName'] as String? ?? '',
        contentTitle: j['contentTitle'] as String? ?? '',
        submittedAt: j['submittedAt'] as String? ?? '',
        corrected: j['corrected'] as bool? ?? false,
        score: j['score'] as int?,
      );
}

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  final _api = ApiClient.instance;

  Future<List<ApiPublishedContent>> getMyContent() async {
    final res = await _api.dio.get('/teacher/content');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiPublishedContent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> publishContent({
    required String title,
    required String type,
    required String subjectCategory,
    required String level,
    required String exam,
    required double price,
    required bool isFree,
  }) async {
    try {
      await _api.dio.post('/teacher/content', data: {
        'title': title,
        'category': type,
        'subjectCategory': subjectCategory,
        'level': level,
        'exam': exam,
        'price': price,
        'isFree': isFree,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiSubmission>> getSubmissions() async {
    final res = await _api.dio.get('/teacher/submissions');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> correctSubmission(int id, int score, String feedback) async {
    try {
      await _api.dio.put('/teacher/submissions/$id', data: {
        'score': score,
        'feedback': feedback,
        'corrected': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createSession({
    required String title,
    required String date,
    required String link,
    required int durationMinutes,
    required int maxStudents,
  }) async {
    try {
      await _api.dio.post('/teacher/sessions', data: {
        'title': title,
        'scheduledAt': date,
        'meetingLink': link,
        'durationMinutes': durationMinutes,
        'maxParticipants': maxStudents,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getRevenueSummary() async {
    final res = await _api.dio.get('/teacher/revenue');
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getContentRevenue() async {
    try {
      final res = await _api.dio.get('/teacher/revenue/by-content');
      return (res.data as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteContent(int contentId) async {
    try {
      await _api.dio.delete('/teacher/content/$contentId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
