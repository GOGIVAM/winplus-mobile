import 'package:dio/dio.dart';
import '../app_config.dart';
import '../l10n/l10n.dart';
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
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Seule une requête faite avec une session peut l'avoir perdue : un
        // refus à la connexion (mauvais mot de passe) n'est pas une
        // expiration.
        final sent = e.requestOptions.headers['Authorization'];
        final hadSession = sent != null;
        if (e.response?.statusCode == 401 && hadSession) {
          final refreshed = await _refreshOnce(sent.toString());
          if (refreshed) {
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
          // En arrière-plan, un renouvellement refusé ne déconnecte pas :
          // l'application ouverte a pu renouveler au même instant, elle
          // reste seule juge de l'expiration.
          if (!backgroundMode) await _expireSession();
        }
        handler.next(e);
      },
    ));

    return d;
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
  Future<bool>? _refreshing;

  /// Vrai dans les isolats de fond (service de notifications, tâche
  /// périodique) : voir le refus de renouvellement ci-dessus.
  bool backgroundMode = false;

  /// Isolats de fond : le renouvellement est-il permis maintenant ? Le
  /// service de notifications le refuse quand l'application est ouverte,
  /// pour ne jamais renouveler en même temps qu'elle.
  Future<bool> Function()? mayRefresh;

  Future<bool> _refreshOnce(String sentAuthorization) {
    return _refreshing ??= _tryRefresh(sentAuthorization)
        .whenComplete(() => _refreshing = null);
  }

  Future<bool> _tryRefresh(String sentAuthorization) async {
    // Un autre isolat a peut-être déjà renouvelé : on relit le trousseau,
    // et si le jeton d'accès a changé, on rejoue avec lui sans consommer le
    // jeton de renouvellement (le serveur le remplace à chaque usage).
    SessionManager.reload();
    final stored = await SessionManager.getAccessToken();
    if (stored != null && stored.isNotEmpty && 'Bearer $stored' != sentAuthorization) {
      return true;
    }
    final allowed = mayRefresh;
    if (allowed != null && !await allowed()) return false;
    final refresh = await SessionManager.getRefreshToken();
    if (refresh == null) return false;
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
      return true;
    } catch (_) {
      return false;
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
