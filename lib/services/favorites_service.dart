import 'api_client.dart';

class ApiFavorite {
  final int id;
  final int subjectId;
  final String subjectTitle;
  final DateTime addedAt;
  const ApiFavorite({
    required this.id,
    required this.subjectId,
    required this.subjectTitle,
    required this.addedAt,
  });

  factory ApiFavorite.fromJson(Map<String, dynamic> j) => ApiFavorite(
        id: j['id'] as int,
        subjectId: j['subjectId'] as int,
        subjectTitle: j['subjectTitle'] as String? ?? '',
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final _api = ApiClient.instance;

  Future<List<ApiFavorite>> getAll() async {
    final res = await _api.dio.get('/favorites');
    final list = res.data as List? ?? [];
    return list.map((e) => ApiFavorite.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> add(int subjectId) async {
    try {
      await _api.dio.post('/favorites/$subjectId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int favoriteId) async {
    try {
      await _api.dio.delete('/favorites/$favoriteId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
