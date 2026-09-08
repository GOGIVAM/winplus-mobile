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

class ApiTeacherStats {
  final int thisMonthRevenue;
  final List<int> weeklyRevenue;
  final int activeStudents;
  const ApiTeacherStats({
    required this.thisMonthRevenue,
    required this.weeklyRevenue,
    required this.activeStudents,
  });
}

class ApiTeacherClass {
  final String id, name;
  final int studentCount, avgScore;
  const ApiTeacherClass({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.avgScore,
  });
}

class ApiTeacherStudent {
  final String id, name, level;
  final int avgScore;
  final bool trendUp;
  const ApiTeacherStudent({
    required this.id,
    required this.name,
    required this.level,
    required this.avgScore,
    required this.trendUp,
  });
}

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  final _api = ApiClient.instance;

  /// Crée une session d'enseignement (POST /api/sessions). `date` vient d'un
  /// champ texte libre (pas encore un vrai sélecteur date/heure côté écran) :
  /// on tente un parse ISO, sinon on programme demain à défaut plutôt que
  /// d'échouer silencieusement.
  Future<bool> createSession({
    required String title,
    required String date,
    String? link,
    int durationMinutes = 60,
    int? maxStudents,
  }) async {
    try {
      final startDate = DateTime.tryParse(date) ?? DateTime.now().add(const Duration(days: 1));
      await _api.dio.post('/sessions', data: {
        'title': title,
        'type': 'live',
        'startDate': startDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'maxParticipants': maxStudents,
        'externalLink': link,
        'isFree': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiPublishedContent>> getMyContent() async {
    final res = await _api.dio.get('/teacher/contents/mine');
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
    required int price,
    String? description,
  }) async {
    try {
      await _api.dio.post('/teacher/contents', data: {
        'title': title,
        'category': type,
        'subjectCategory': subjectCategory,
        'level': level,
        'price': price,
        if (description != null) 'description': description,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiSubmission>> getSubmissions() async {
    final res = await _api.dio.get('/teacher/corrections/pending');
    final raw = res.data;
    final list = raw is List ? raw : (raw as Map<String, dynamic>?)?['items'] as List? ?? [];
    return list
        .map((e) => ApiSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Note une copie précise. Route réellement exposée par le backend :
  /// POST /api/corrections/{id} avec {note, comment, status} (contrat déjà
  /// utilisé par CorrectionQueue.tsx côté web) — PUT /teacher/corrections/pending
  /// n'a jamais existé côté .NET, cet appel échouait toujours en 404.
  Future<bool> correctSubmission(int submissionId, int score, [String? feedback]) async {
    try {
      await _api.dio.post('/corrections/$submissionId', data: {
        'note': score,
        'comment': feedback,
        'status': 'submitted',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getRevenueSummary() async {
    try {
      final res = await _api.dio.get('/teacher/revenues');
      return res.data as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getContentRevenue() async {
    try {
      final res = await _api.dio.get('/teacher/revenue-share');
      return (res.data as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteContent(int contentId) async {
    try {
      await _api.dio.delete('/teacher/contents/$contentId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ApiTeacherStats> getStats() async {
    final res = await _api.dio.get('/teacher/stats');
    final j = res.data as Map<String, dynamic>;
    return ApiTeacherStats(
      thisMonthRevenue: (j['thisMonthRevenue'] as num?)?.toInt() ?? 0,
      weeklyRevenue: (j['weeklyRevenue'] as List?)?.cast<int>() ?? [0, 0, 0, 0],
      activeStudents: j['activeStudents'] as int? ?? 0,
    );
  }

  Future<List<ApiTeacherClass>> getClasses() async {
    final res = await _api.dio.get('/teacher/classes');
    final list = res.data as List? ?? [];
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      return ApiTeacherClass(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        studentCount: j['studentCount'] as int? ?? 0,
        avgScore: j['avgScore'] as int? ?? 0,
      );
    }).toList();
  }

  Future<List<ApiTeacherStudent>> getStudents() async {
    final res = await _api.dio.get('/teacher/students/recent');
    final list = res.data as List? ?? [];
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      return ApiTeacherStudent(
        id: (j['id'] ?? '').toString(),
        name: j['name'] as String? ?? '',
        level: j['level'] as String? ?? '',
        avgScore: j['avgScore'] as int? ?? 0,
        trendUp: j['trendUp'] as bool? ?? true,
      );
    }).toList();
  }
}
