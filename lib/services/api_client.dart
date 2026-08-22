import 'package:dio/dio.dart';
import '../app_config.dart';
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
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Tentative de refresh
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await SessionManager.getAccessToken();
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final res = await d.fetch(opts);
              return handler.resolve(res);
            } catch (_) {}
          }
          await SessionManager.clear();
        }
        handler.next(e);
      },
    ));

    return d;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await SessionManager.getRefreshToken();
    if (refresh == null) return false;
    try {
      final res = await Dio().post(
        '${AppConfig.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data as Map<String, dynamic>;
      final userId = await SessionManager.getUserId();
      final role = await SessionManager.getUserRole() ?? 'student';
      final name = await SessionManager.getUserName() ?? '';
      await SessionManager.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: userId ?? 0,
        email: '',
        role: role,
        name: name,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> get<T>(String path,
      {Map<String, dynamic>? params,
      T Function(dynamic)? fromJson}) async {
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
