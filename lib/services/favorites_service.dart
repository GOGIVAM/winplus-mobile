import 'api_client.dart';
import 'outbox_service.dart';

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
        // Le serveur renvoie l'entité Favorite : le titre est dans subject.
        subjectTitle: j['subjectTitle'] as String? ??
            (j['subject'] is Map ? (j['subject'] as Map)['title'] as String? : null) ??
            '',
        addedAt:
            DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final _api = ApiClient.instance;

  Future<List<ApiFavorite>> getAll() async {
    // Réponse paginée { items, totalCount, … } (lot 8 : l'application
    // attendait une liste et affichait « Impossible de charger les favoris »).
    final res = await _api.dio.get('/favorites', queryParameters: {'pageSize': 100});
    final body = res.data;
    final list = body is List
        ? body
        : body is Map
            ? (body['items'] ?? body['Items'] ?? body['data']) as List? ?? const []
            : const [];
    return list
        .map((e) => ApiFavorite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Hors ligne, l'ajout part au retour du réseau (lot 3) : il compte comme
  /// fait pour l'écran.
  Future<bool> add(int subjectId) async {
    try {
      await OutboxService.instance.sendOrQueue(
          method: 'POST', path: '/favorites/$subjectId', label: 'favorite_add');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [subjectId] : le serveur retire le favori par sujet (DELETE
  /// /favorites/{subjectId}) ; avant, l'identifiant du favori était envoyé
  /// et un autre favori pouvait être retiré (audit du 27/11).
  Future<bool> remove(int subjectId) async {
    try {
      await OutboxService.instance.sendOrQueue(
          method: 'DELETE',
          path: '/favorites/$subjectId',
          label: 'favorite_remove');
      return true;
    } catch (_) {
      return false;
    }
  }
}
