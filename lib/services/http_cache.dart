import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'connectivity_service.dart';
import 'session_manager.dart';

/// Règle de lecture commune du mode hors ligne (lot 3) : chaque lecture
/// réussie est gardée, par compte ; sans réseau, ou quand le serveur ne
/// répond pas, le client sert la dernière version connue au lieu d'une
/// erreur. Placée une fois dans ApiClient, elle vaut pour tous les services
/// au lieu d'être recopiée dans chacun.
///
/// Ne sont jamais gardés :
/// - ce qui doit rester en ligne : connexion, paiements, WinAI, flux de
///   notifications ;
/// - les contenus protégés : leçons de formation (déjà chiffrées par
///   CourseOfflineService), supports de séance, et toute réponse qui n'est
///   pas du JSON (PDF, images, vidéos). Épreuves et corrigés restent non
///   téléchargeables (décision produit, module 44).
///
/// Une réponse du serveur en erreur (404, 403…) n'est jamais remplacée par
/// le cache : c'est une vraie réponse. Seule l'absence de réponse l'est.
class HttpCache {
  HttpCache._();
  static final HttpCache instance = HttpCache._();

  static const boxName = 'http_cache';

  /// Nombre de lectures gardées, tous comptes confondus ; au-delà, les plus
  /// anciennes partent.
  static const maxEntries = 600;

  static const _excludedPrefixes = [
    '/auth',
    '/payments',
    '/notifications/sse',
    '/chatbot',
    '/ai/',
    '/wallet/topup',
  ];
  static final _excludedPatterns = [
    RegExp(r'^/courses/[^/]+/play'),
    RegExp(r'^/tutor-bookings/[^/]+/material'),
  ];

  _Store? _store;

  /// Faux dans les isolats de fond (service de notifications, tâche
  /// périodique) : Hive n'y est pas initialisé, et ils n'affichent rien.
  bool enabled = true;

  /// Ouverture déjà tentée sans succès : on ne réessaie plus à chaque
  /// réponse (chaque essai relevait une erreur de Hive).
  bool _unavailable = false;

  /// Date de la plus ancienne donnée servie depuis le cache depuis le
  /// dernier succès réseau ; null quand tout vient du serveur. Alimente le
  /// bandeau « hors ligne, données du … ».
  final ValueNotifier<DateTime?> servedFromCacheSince =
      ValueNotifier<DateTime?>(null);

  /// Tests : stockage en mémoire, vidé à chaque appel.
  @visibleForTesting
  void useMemoryStore() {
    _store = _MemoryStore();
    enabled = true;
    _unavailable = false;
    servedFromCacheSince.value = null;
  }

  Future<_Store?> _open() async {
    if (!enabled) return null;
    if (_store != null) return _store;
    if (_unavailable) return null;
    try {
      _store = _HiveStore(await Hive.openBox(boxName));
    } catch (e) {
      // Hive non initialisé (isolat de fond, outil) : pas de cache.
      _unavailable = true;
      debugPrint('HttpCache indisponible : $e');
      return null;
    }
    return _store;
  }

  static bool isCacheable(RequestOptions o) {
    if (o.method.toUpperCase() != 'GET') return false;
    if (o.responseType != ResponseType.json) return false;
    final path = o.path;
    if (_excludedPrefixes.any(path.startsWith)) return false;
    if (_excludedPatterns.any((r) => r.hasMatch(path))) return false;
    return true;
  }

  static Future<String?> _key(RequestOptions o) async {
    final user = await SessionManager.getUserId();
    if (user == null) return null;
    final q = o.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = q.map((e) => '${e.key}=${e.value}').join('&');
    final key = '$user|${o.path}?$query';
    // Hive refuse les clés de plus de 255 caractères : au-delà, la fin est
    // remplacée par une empreinte stable (FNV-1a), le préfixe du compte reste.
    if (key.length <= 200) return key;
    return '${key.substring(0, 150)}#${_fnv1a(key)}';
  }

  static String _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// Absence de réponse du serveur (coupure, délai dépassé) : seul cas où
  /// la dernière version connue remplace la réponse.
  static bool isNetworkFailure(DioException e) => switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          true,
        DioExceptionType.unknown => e.response == null,
        _ => false,
      };

  Future<void> save(Response res) async {
    final o = res.requestOptions;
    if (!isCacheable(o)) return;
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) return;
    final data = res.data;
    if (data is! Map && data is! List) return;
    final key = await _key(o);
    final store = await _open();
    if (key == null || store == null) return;
    await store.put(key, {
      'data': data,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await _trim(store);
    // Une lecture réelle a réussi : le réseau est revenu.
    servedFromCacheSince.value = null;
  }

  /// Dernière version connue de cette lecture, ou null.
  Future<Response?> lookup(RequestOptions o) async {
    if (!isCacheable(o)) return null;
    final key = await _key(o);
    final store = await _open();
    if (key == null || store == null) return null;
    final entry = store.get(key);
    if (entry is! Map) return null;
    final savedAt = DateTime.tryParse(entry['savedAt'] as String? ?? '');
    if (savedAt != null) {
      final since = servedFromCacheSince.value;
      if (since == null || savedAt.isBefore(since)) {
        servedFromCacheSince.value = savedAt;
      }
    }
    return Response(
      requestOptions: o,
      data: _deepCopy(entry['data']),
      statusCode: 200,
      extra: {'fromCache': true, 'savedAt': savedAt},
    );
  }

  /// À la déconnexion : rien du compte qui part ne reste sur le téléphone.
  Future<void> clearForUser(int? userId) async {
    servedFromCacheSince.value = null;
    final store = await _open();
    if (store == null) return;
    if (userId == null) {
      await store.clear();
      return;
    }
    final prefix = '$userId|';
    for (final k in store.keys.where((k) => k.startsWith(prefix)).toList()) {
      await store.delete(k);
    }
  }

  Future<void> _trim(_Store store) async {
    final keys = store.keys.toList();
    if (keys.length <= maxEntries) return;
    final dated = <MapEntry<String, String>>[];
    for (final k in keys) {
      final e = store.get(k);
      dated.add(MapEntry(k, e is Map ? (e['savedAt'] as String? ?? '') : ''));
    }
    dated.sort((a, b) => a.value.compareTo(b.value));
    for (final e in dated.take(keys.length - maxEntries)) {
      await store.delete(e.key);
    }
  }

  /// Hive rend des Map<dynamic, dynamic> : les services attendent les mêmes
  /// types que ceux du JSON décodé (Map<String, dynamic>, List<dynamic>).
  static dynamic _deepCopy(dynamic v) {
    if (v is Map) {
      return <String, dynamic>{
        for (final e in v.entries) e.key.toString(): _deepCopy(e.value),
      };
    }
    if (v is List) return v.map(_deepCopy).toList();
    return v;
  }
}

/// Intercepteur du client : sert le cache sans réseau, le remplit au retour.
class HttpCacheInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Hors ligne connu : réponse immédiate depuis le cache, sans attendre
    // le délai de connexion (jusqu'à 30 s par écran sinon).
    if (!ConnectivityService.instance.isOnline &&
        HttpCache.isCacheable(options)) {
      final cached = await _safeLookup(options);
      if (cached != null) return handler.resolve(cached);
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    if (response.extra['fromCache'] != true) {
      // Le cache ne doit jamais retenir ni casser une réponse : une erreur
      // ou une écriture lente est ignorée, la réponse part quand même.
      try {
        await HttpCache.instance
            .save(response)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('HttpCache : réponse non gardée ($e)');
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (HttpCache.isNetworkFailure(err)) {
      final cached = await _safeLookup(err.requestOptions);
      if (cached != null) return handler.resolve(cached);
    }
    handler.next(err);
  }

  static Future<Response?> _safeLookup(RequestOptions o) async {
    try {
      return await HttpCache.instance
          .lookup(o)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('HttpCache : lecture impossible ($e)');
      return null;
    }
  }
}

abstract class _Store {
  Iterable<String> get keys;
  dynamic get(String key);
  Future<void> put(String key, Map<String, dynamic> value);
  Future<void> delete(String key);
  Future<void> clear();
}

class _HiveStore implements _Store {
  final Box _box;
  _HiveStore(this._box);
  @override
  Iterable<String> get keys => _box.keys.map((k) => k.toString());
  @override
  dynamic get(String key) => _box.get(key);
  @override
  Future<void> put(String key, Map<String, dynamic> value) =>
      _box.put(key, value);
  @override
  Future<void> delete(String key) => _box.delete(key);
  @override
  Future<void> clear() => _box.clear();
}

class _MemoryStore implements _Store {
  final Map<String, dynamic> _m = {};
  @override
  Iterable<String> get keys => _m.keys;
  @override
  dynamic get(String key) => _m[key];
  @override
  Future<void> put(String key, Map<String, dynamic> value) async =>
      _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<void> clear() async => _m.clear();
}
