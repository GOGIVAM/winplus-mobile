import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// Élément de « Ma bibliothèque » : contenu acheté ou rangé (favori organisé).
class LibraryItem {
  final int subjectId;
  final String title;
  final String? thumbnailUrl;
  final String? category;
  final int? favoriteId;
  final int? collectionId;
  final String? collectionName;
  final List<String> tags;
  final String? notes;
  final DateTime? acquiredAt;

  /// purchased (acheté, pas encore rangé) ou organized.
  final String source;

  const LibraryItem({
    required this.subjectId,
    required this.title,
    this.thumbnailUrl,
    this.category,
    this.favoriteId,
    this.collectionId,
    this.collectionName,
    this.tags = const [],
    this.notes,
    this.acquiredAt,
    this.source = 'organized',
  });

  bool get annotated => tags.isNotEmpty || (notes ?? '').trim().isNotEmpty;

  factory LibraryItem.fromJson(Map<String, dynamic> j) => LibraryItem(
        subjectId: (j['subjectId'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        category: j['category'] as String?,
        favoriteId: (j['favoriteId'] as num?)?.toInt(),
        collectionId: (j['collectionId'] as num?)?.toInt(),
        collectionName: j['collectionName'] as String?,
        tags: (j['tags'] is List ? j['tags'] as List : const []).map((e) => '$e').toList(),
        notes: j['notes'] as String?,
        acquiredAt: DateTime.tryParse(j['acquiredAt']?.toString() ?? '')?.toLocal(),
        source: j['source']?.toString() ?? 'organized',
      );
}

/// Dossier de la bibliothèque (FavoriteCollection).
class LibraryFolder {
  final int id;
  final String name;
  const LibraryFolder(this.id, this.name);

  factory LibraryFolder.fromJson(Map<String, dynamic> j) =>
      LibraryFolder((j['id'] as num?)?.toInt() ?? 0, j['name']?.toString() ?? '');
}

/// Classe du professeur, pour « Assigner à une classe ».
class LibraryClass {
  final int id;
  final String name;
  const LibraryClass(this.id, this.name);
}

/// Refus lisible (dossier introuvable, limite de favoris, solde insuffisant…).
class LibraryException implements Exception {
  final String message;
  final int? status;

  /// 402 sur une assignation : solde du portefeuille insuffisant.
  final num? balanceXaf;
  final num? requiredXaf;
  const LibraryException(this.message, {this.status, this.balanceXaf, this.requiredXaf});

  @override
  String toString() => message;
}

/// « Ma bibliothèque » du professeur (lot 7), comme TeacherLibrary du site :
/// GET /library/me (achats et contenus rangés), POST /library/{id}/organize
/// (dossier, tags, notes), dossiers (/favorite-collections) et assignation
/// d'un contenu à une classe (POST /teacher/classes/{id}/content).
class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();
  final _api = ApiClient.instance;

  /// Tags proposés (enregistrés en français, comme sur le site).
  static const suggestedTags = ['À réviser', 'Difficile', 'Maîtrisé', 'À acheter'];

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    return (raw is List ? raw : const []).whereType<Map<String, dynamic>>().toList();
  }

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  static LibraryException _error(Object e) {
    if (e is LibraryException) return e;
    final l = L10n.current;
    if (e is DioException) {
      final body = e.response?.data;
      final map = body is Map ? body : null;
      final text = map?['error'] ?? map?['message'];
      return LibraryException(
        text is String && text.trim().isNotEmpty ? text.trim() : l.commonLoadError,
        status: e.response?.statusCode,
        balanceXaf: map?['balanceXaf'] as num?,
        requiredXaf: map?['requiredXaf'] as num?,
      );
    }
    return LibraryException(l.commonLoadError);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw _error(e);
    }
  }

  Future<List<LibraryItem>> items({String? q, int? collectionId, bool annotatedOnly = false, String? tag}) =>
      _guard(() async {
        final res = await _api.dio.get('/library/me', queryParameters: {
          if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
          if (collectionId != null) 'collectionId': collectionId,
          if (annotatedOnly) 'annotatedOnly': true,
          if ((tag ?? '').trim().isNotEmpty) 'tag': tag!.trim(),
        });
        return _list(res.data).map(LibraryItem.fromJson).toList();
      });

  /// Range un contenu. [collectionId] null + [clearCollection] = « Sans dossier ».
  Future<void> organize(int subjectId,
          {int? collectionId, bool clearCollection = false, List<String>? tags, String? notes}) =>
      _guard(() => _api.dio.post('/library/$subjectId/organize', data: {
            if (clearCollection) 'clearCollection': true,
            if (!clearCollection && collectionId != null) 'collectionId': collectionId,
            if (tags != null) 'tags': tags,
            if (notes != null) 'notes': notes,
          }));

  Future<List<LibraryFolder>> folders() => _guard(() async {
        final res = await _api.dio.get('/favorite-collections');
        return _list(res.data).map(LibraryFolder.fromJson).toList();
      });

  /// Description, couleur et icône vides : le serveur les déclare non
  /// nulles, un nom seul pourrait être refusé.
  Future<LibraryFolder> createFolder(String name) => _guard(() async {
        final res = await _api.dio.post('/favorite-collections',
            data: {'name': name.trim(), 'description': '', 'color': '', 'icon': ''});
        final j = _map(res.data);
        return LibraryFolder((j['id'] as num?)?.toInt() ?? 0, j['name']?.toString() ?? name.trim());
      });

  Future<void> renameFolder(int id, String name) => _guard(() =>
      _api.dio.put('/favorite-collections/$id', data: {'name': name.trim(), 'description': '', 'color': '', 'icon': ''}));

  Future<void> deleteFolder(int id) => _guard(() => _api.dio.delete('/favorite-collections/$id'));

  Future<List<LibraryClass>> classes() => _guard(() async {
        final res = await _api.dio.get('/teacher/classes');
        return _list(res.data)
            .map((j) => LibraryClass((j['id'] as num?)?.toInt() ?? 0, j['name']?.toString() ?? ''))
            .toList();
      });

  /// Assigne un contenu à une classe. Renvoie le montant débité du
  /// portefeuille (0 si le professeur possède déjà le contenu).
  Future<num> assignToClass(int classId, int subjectId) => _guard(() async {
        final res = await _api.dio.post('/teacher/classes/$classId/content', data: {'subjectId': subjectId});
        return (_map(res.data)['priceCharged'] as num?) ?? 0;
      });
}
