import 'api_client.dart';
import 'local_downloads_service.dart';
import '../data/models.dart';

class SubjectPage {
  final List<ApiSubject> items;
  final int totalCount;
  final int page;
  final int totalPages;
  const SubjectPage(this.items, this.totalCount, this.page, this.totalPages);
}

class ApiSubject {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? subjectCategory;
  final String? level;
  final String? difficulty;
  final int? year;
  final int downloadCount;
  final bool isFree;
  final double price;
  final String? documentUrl;
  final String? correctionUrl;
  final double? rating;
  final int ratingsCount;
  const ApiSubject({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.subjectCategory,
    this.level,
    this.difficulty,
    this.year,
    this.downloadCount = 0,
    this.isFree = false,
    this.price = 0,
    this.documentUrl,
    this.correctionUrl,
    this.rating,
    this.ratingsCount = 0,
  });

  factory ApiSubject.fromJson(Map<String, dynamic> j) => ApiSubject(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        category: j['category'] as String?,
        subjectCategory: j['subjectCategory'] as String?,
        level: j['level'] as String?,
        difficulty: j['difficulty'] as String?,
        year: j['year'] as int?,
        downloadCount: j['downloadCount'] as int? ?? 0,
        isFree: j['isFree'] as bool? ?? false,
        price: ((j['price'] ?? 0) as num).toDouble(),
        documentUrl: j['documentUrl'] as String?,
        correctionUrl: j['correctionUrl'] as String?,
        rating: ((j['averageRating'] ?? 0) as num).toDouble(),
        ratingsCount: j['ratingsCount'] as int? ?? 0,
      );
}

extension ApiSubjectToContent on ApiSubject {
  Content toContent() => Content(
        id: '$id',
        title: title,
        subjectId: _subjectCategoryToId(subjectCategory ?? category),
        exam: level ?? 'BAC',
        level: level ?? 'Terminale',
        type: _categoryToContentType(category),
        year: year ?? DateTime.now().year,
        price: price.round(),
        rating100: ((rating ?? 0) * 10).round(),
        ratings: ratingsCount,
        downloads: downloadCount,
        free: isFree,
        description: description,
        documentUrl: documentUrl,
      );
}

String _subjectCategoryToId(String? cat) => switch (cat?.toLowerCase()) {
      'mathematiques' || 'maths' || 'math' || 'mathematique' => 'math',
      'physique-chimie' || 'physique' || 'chimie' || 'pc' => 'pc',
      'svt' || 'biologie' || 'sciences naturelles' => 'svt',
      'français' || 'francais' || 'litterature' => 'fr',
      'histoire-geo' || 'histoire' || 'geographie' || 'hg' => 'hg',
      'philosophie' || 'philo' => 'philo',
      'anglais' || 'english' => 'en',
      _ => 'math',
    };

ContentType _categoryToContentType(String? cat) => switch (cat?.toLowerCase()) {
      'epreuve' || 'épreuve' || 'epreuves' => ContentType.epreuve,
      'correction' || 'corrections' => ContentType.correction,
      'quiz' => ContentType.quiz,
      'livre' || 'livres' || 'book' => ContentType.livre,
      'pack' || 'packs' => ContentType.pack,
      _ => ContentType.epreuve,
    };

class SubjectService {
  SubjectService._();
  static final SubjectService instance = SubjectService._();

  final _api = ApiClient.instance;

  Future<SubjectPage> getAll({
    String? q,
    String? category,
    String? level,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final res = await _api.dio.get('/subjects', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List? ?? [])
        .map((e) => ApiSubject.fromJson(e as Map<String, dynamic>))
        .toList();
    return SubjectPage(
      items,
      data['totalCount'] as int? ?? items.length,
      data['page'] as int? ?? page,
      data['totalPages'] as int? ?? 1,
    );
  }

  Future<ApiSubject> getById(int id) async {
    final res = await _api.dio.get('/subjects/$id');
    return ApiSubject.fromJson(res.data as Map<String, dynamic>);
  }

  /// Incrémente le compteur de téléchargement côté serveur ET télécharge
  /// réellement le fichier (documentUrl) vers le stockage privé de l'app.
  /// L'ancienne version n'appelait que le compteur  "un abus de langage" :
  /// le fichier restait distant, seule une ligne de log était écrite.
  /// Un échec de l'un n'annule pas l'autre : le compteur est une métrique
  /// serveur indépendante de la réussite du téléchargement local.
  Future<bool> download(int subjectId) async {
    bool counterOk = false;
    try {
      await _api.dio.post('/subjects/$subjectId/download');
      counterOk = true;
    } catch (_) {
      counterOk = false;
    }

    try {
      final subject = await getById(subjectId);
      final url = subject.documentUrl;
      if (url != null && url.isNotEmpty) {
        await LocalDownloadsService.instance.download(
          contentId: '$subjectId',
          url: url,
          suggestedFileName: subject.title,
        );
        return true;
      }
    } catch (_) {
      // Le fichier n'a pas pu être récupéré (réseau, URL absente…) : le
      // contenu reste consultable à distance comme avant, juste pas hors
      // ligne. On ne fait pas échouer toute l'action pour autant si au
      // moins le compteur est passé.
    }

    return counterOk;
  }
}
