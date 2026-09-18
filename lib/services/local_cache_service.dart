import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache local structuré (Hive) pour les données déjà affichées à
/// l'utilisateur : chaque écran principal peut donc se relancer avec sa
/// dernière donnée connue quand le réseau est indisponible, au lieu d'un
/// écran vide + bouton Réessayer.
///
/// Chaque box stocke le JSON brut renvoyé par l'API (pas les objets Dart
/// parsés) sous la clé `'data'`, plus un horodatage sous `'updatedAt'`
/// (ISO 8601) utilisé par la bannière "Dernière mise à jour". Les DTO
/// `fromJson` existants restent la seule source de vérité pour le parsing :
/// aucun TypeAdapter Hive dédié n'est nécessaire, Hive sait déjà sérialiser
/// Map/List/String/num/bool nativement.
class LocalCacheService {
  LocalCacheService._();

  static const parentDashboardBoxName = 'ParentDashboardBox';
  static const studentDashboardBoxName = 'StudentDashboardBox';
  static const examCoachBoxName = 'ExamCoachBox';
  static const reportsBoxName = 'ReportsBox';

  static bool _initialized = false;

  /// À appeler une fois, avant runApp().
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(parentDashboardBoxName),
      Hive.openBox(studentDashboardBoxName),
      Hive.openBox(examCoachBoxName),
      Hive.openBox(reportsBoxName),
    ]);
    _initialized = true;
  }

  static Box get parentDashboard => Hive.box(parentDashboardBoxName);
  static Box get studentDashboard => Hive.box(studentDashboardBoxName);
  static Box get examCoach => Hive.box(examCoachBoxName);
  static Box get reports => Hive.box(reportsBoxName);

  static void _put(Box box, String key, dynamic rawJson) {
    box.put(key, {
      'data': rawJson,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? _get(Box box, String key) {
    final entry = box.get(key);
    if (entry is Map) return Map<String, dynamic>.from(entry);
    return null;
  }

  /// Date de dernière écriture réussie pour une clé, ou null si jamais
  /// mise en cache  alimente la bannière "Dernière mise à jour : [date]".
  static DateTime? lastUpdatedAt(Box box, String key) {
    final entry = _get(box, key);
    final raw = entry?['updatedAt'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Exécute [fetchLiveRaw] ; en cas de succès, met le résultat brut en cache
  /// sous [key] dans [box] et le retourne (`fromCache: false`). En cas
  /// d'échec réseau (pas de réponse du serveur), retombe sur la dernière
  /// valeur mise en cache si elle existe (`fromCache: true`, [updatedAt]
  /// renseigné) ; sinon relance l'exception d'origine.
  ///
  /// Ne retombe PAS sur le cache pour une réponse HTTP valide mais en erreur
  /// (404, 403…) : ça, c'est une réponse réelle du serveur (ex. "plus de plan
  /// actif" après désactivation), pas une coupure réseau  la resservir
  /// depuis un cache périmé afficherait une donnée fausse comme si elle
  /// était à jour. Seule l'absence de réponse (timeout, pas de connexion)
  /// déclenche le repli.
  static Future<CachedResult<T>> cachedFetch<T>({
    required Box box,
    required String key,
    required Future<dynamic> Function() fetchLiveRaw,
    required T Function(dynamic rawJson) parse,
  }) async {
    try {
      final raw = await fetchLiveRaw();
      _put(box, key, raw);
      return CachedResult(parse(raw),
          fromCache: false, updatedAt: DateTime.now());
    } catch (e) {
      if (e is DioException && e.response != null) {
        // 404 = absence confirmée par le serveur (ex. plan désactivé) : on
        // vide l'entrée pour qu'une coupure réseau ultérieure ne resserve
        // pas cette donnée périmée comme si elle existait encore.
        if (e.response!.statusCode == 404) await box.delete(key);
        rethrow;
      }

      final cached = _get(box, key);
      if (cached != null) {
        final updatedAt =
            DateTime.tryParse(cached['updatedAt'] as String? ?? '');
        return CachedResult(parse(cached['data']),
            fromCache: true, updatedAt: updatedAt);
      }
      rethrow;
    }
  }
}

/// Résultat d'un [LocalCacheService.cachedFetch] : la valeur, son origine
/// (réseau ou cache), et la date de la donnée servie (utile pour la bannière
/// "Dernière mise à jour : [date]" même quand la valeur vient du réseau).
class CachedResult<T> {
  final T value;
  final bool fromCache;
  final DateTime? updatedAt;
  const CachedResult(this.value, {required this.fromCache, this.updatedAt});
}
