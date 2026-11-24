import 'dart:async';

import 'package:dio/dio.dart';
import '../app_config.dart';
import '../l10n/l10n.dart';
import 'http_cache.dart';
import 'outbox_service.dart';
import 'session_manager.dart';

/// Client Dio centralisé avec intercepteur JWT automatique et refresh token.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _build();

  Dio get dio => _dio;

  Dio _build() {
    final d = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: AppConfig.networkTimeout),
      receiveTimeout: const Duration(seconds: AppConfig.networkTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SessionManager.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Lot 10.11 : langue de l'application pour les réponses du serveur.
        options.headers['Accept-Language'] = L10n.code;
        // Lot 3 : écriture envoyée par la file d'attente (ou avant d'y
        // entrer) : clé unique, pour que le serveur ignore un double envoi.
        // Une clé par écriture (méthode et chemin), au cas où une action en
        // ferait plusieurs.
        final outboxKey = Zone.current[OutboxService.zoneKey];
        if (outboxKey is String && options.method.toUpperCase() != 'GET') {
          options.headers['Idempotency-Key'] =
              '$outboxKey-${_shortHash('${options.method} ${options.path}')}';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Seule une requête faite avec une session peut l'avoir perdue : un
        // refus à la connexion (mauvais mot de passe) n'est pas une
        // expiration.
        final sent = e.requestOptions.headers['Authorization'];
        final hadSession = sent != null;
        if (e.response?.statusCode == 401 && hadSession) {
          final outcome = await _refreshOnce(sent.toString());
          if (outcome == _Refresh.renewed) {
            final token = await SessionManager.getAccessToken();
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final res = await d.fetch(opts);
              return handler.resolve(res);
            } on DioException catch (retry) {
              return handler.next(retry);
            }
          }
          // Seul un refus du serveur met fin à la session. Une coupure, un
          // délai dépassé ou une panne du serveur pendant le renouvellement
          // la laissent intacte : la requête échoue comme hors ligne, le
          // renouvellement repartira à la suivante. Avant, toute erreur
          // déconnectait (une coupure toutes les 15 minutes suffisait).
          // En arrière-plan, même un refus ne déconnecte pas : l'application
          // ouverte a pu renouveler au même instant, elle reste seule juge.
          if (outcome == _Refresh.refused && !backgroundMode) {
            await _expireSession();
          }
        }
        handler.next(e);
      },
    ));
    // Mode hors ligne (lot 3) : après l'intercepteur de session, pour que
    // l'échec réseau d'une requête lui parvienne une fois les 401 traités.
    d.interceptors.add(HttpCacheInterceptor());

    return d;
  }

  static String _shortHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// Appelé une fois quand la session est perdue (renouvellement refusé) :
  /// main.dart y ramène l'utilisateur à la connexion avec un message.
  void Function()? onSessionExpired;

  bool _expiring = false;

  Future<void> _expireSession() async {
    if (_expiring) return;
    _expiring = true;
    try {
      await SessionManager.clear();
      onSessionExpired?.call();
    } finally {
      _expiring = false;
    }
  }

  /// Renouvellement en cours, partagé : plusieurs requêtes refusées en même
  /// temps attendent le même renouvellement. Sans cela, le serveur, qui
  /// remplace le jeton de renouvellement à chaque usage, refusait le second
  /// et déconnectait l'utilisateur.
  Future<_Refresh>? _refreshing;

  /// Vrai dans les isolats de fond (service de notifications, tâche
  /// périodique) : voir le refus de renouvellement ci-dessus.
  bool backgroundMode = false;

  /// Isolats de fond : le renouvellement est-il permis maintenant ? Le
  /// service de notifications le refuse quand l'application est ouverte,
  /// pour ne jamais renouveler en même temps qu'elle.
  Future<bool> Function()? mayRefresh;

  Future<_Refresh> _refreshOnce(String sentAuthorization) {
    return _refreshing ??= _tryRefresh(sentAuthorization)
        .whenComplete(() => _refreshing = null);
  }

  Future<_Refresh> _tryRefresh(String sentAuthorization) async {
    // Un autre isolat a peut-être déjà renouvelé : on relit le trousseau,
    // et si le jeton d'accès a changé, on rejoue avec lui sans consommer le
    // jeton de renouvellement (le serveur le remplace à chaque usage).
    SessionManager.reload();
    final stored = await SessionManager.getAccessToken();
    if (stored != null && stored.isNotEmpty && 'Bearer $stored' != sentAuthorization) {
      return _Refresh.renewed;
    }
    final allowed = mayRefresh;
    if (allowed != null && !await allowed()) return _Refresh.unavailable;
    final refresh = await SessionManager.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return _Refresh.refused;
    try {
      // Client sans intercepteur (un 401 ici ne doit pas relancer de
      // renouvellement), mais même transport que le client principal.
      final bare = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: AppConfig.networkTimeout),
        receiveTimeout: const Duration(seconds: AppConfig.networkTimeout),
        headers: {'Content-Type': 'application/json'},
      ))
        ..httpClientAdapter = _dio.httpClientAdapter;
      final r = await bare.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = r.data as Map<String, dynamic>;
      // Seuls les jetons changent : l'identité enregistrée (e-mail, rôle,
      // nom) reste. L'ancienne version effaçait l'e-mail à chaque fois.
      await SessionManager.updateTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String?,
      );
      return _Refresh.renewed;
    } on DioException catch (e) {
      // Le serveur refuse le jeton de renouvellement : fin de session.
      final code = e.response?.statusCode;
      if (code == 400 || code == 401 || code == 403) return _Refresh.refused;
      // Coupure, délai dépassé, panne du serveur : la session reste.
      return _Refresh.unavailable;
    } catch (_) {
      // Réponse inattendue (corps illisible) : pas une preuve de refus.
      return _Refresh.unavailable;
    }
  }

  Future<T> get<T>(String path,
      {Map<String, dynamic>? params, T Function(dynamic)? fromJson}) async {
    final r = await _dio.get(path, queryParameters: params);
    return fromJson != null ? fromJson(r.data) : r.data as T;
  }

  Future<T> post<T>(String path,
      {dynamic data, T Function(dynamic)? fromJson}) async {
    final r = await _dio.post(path, data: data);
    return fromJson != null ? fromJson(r.data) : r.data as T;
  }

  Future<T> put<T>(String path,
      {dynamic data, T Function(dynamic)? fromJson}) async {
    final r = await _dio.put(path, data: data);
    return fromJson != null ? fromJson(r.data) : r.data as T;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}

/// Issue d'un renouvellement du jeton d'accès.
enum _Refresh {
  /// Nouveau jeton (ou déjà renouvelé par un autre isolat).
  renewed,

  /// Le serveur refuse le jeton de renouvellement : la session est finie.
  refused,

  /// Serveur injoignable ou en panne : la session reste.
  unavailable,
}

/// Vrai quand le serveur répond « introuvable » (404) : pour une lecture,
/// c'est une absence normale (pas de plan, pas encore d'album). Toute autre
/// erreur (panne, réseau sans copie locale) doit remonter jusqu'à l'écran,
/// qui affiche « erreur, réessayer » plutôt qu'un faux état vide.
bool isNotFound(Object e) =>
    e is DioException && e.response?.statusCode == 404;
