import 'package:dio/dio.dart';
import 'api_client.dart';
import 'session_manager.dart';
import '../data/models.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? errorCode;
  const AuthResult({required this.success, this.message, this.errorCode});
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  Future<AuthResult> signIn(String email, String password) async {
    try {
      final res = await _api.dio.post('/auth/signin', data: {
        'email': email,
        'password': password,
      });
      final d = res.data as Map<String, dynamic>;
      final user = d['user'] as Map<String, dynamic>;
      await SessionManager.save(
        accessToken: d['accessToken'] as String,
        refreshToken: d['refreshToken'] as String,
        userId: user['id'] as int,
        email: user['email'] as String,
        role: (user['role'] as String?) ?? 'student',
        name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      );
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
        success: false,
        message: data?['error'] as String? ?? 'Connexion impossible',
        errorCode: data?['errorCode'] as String?,
      );
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    WinRole role = WinRole.student,
  }) async {
    try {
      await _api.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null) 'phone': phone,
        'role': role.name,
      });
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
        success: false,
        message: data?['error'] as String? ?? 'Inscription impossible',
      );
    }
  }

  Future<AuthResult> verifyEmail(String email, String code) async {
    try {
      await _api.dio.post('/auth/verify-email', data: {
        'email': email,
        'code': code,
      });
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
        success: false,
        message: data?['error'] as String? ?? 'Code invalide',
      );
    }
  }

  Future<AuthResult> resendVerification(String email) async {
    try {
      await _api.dio
          .post('/auth/resend-verification', data: {'email': email});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? 'Erreur réseau');
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _api.dio
          .post('/auth/forgot-password', data: {'email': email});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? 'Erreur réseau');
    }
  }

  Future<AuthResult> resetPassword(String token, String password) async {
    try {
      await _api.dio.post('/auth/reset-password',
          data: {'token': token, 'newPassword': password});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? 'Erreur réseau');
    }
  }

  Future<void> signOut() async {
    try {
      await _api.dio.post('/auth/signout');
    } catch (_) {}
    await SessionManager.clear();
  }

  Future<AuthResult> enable2FA() async {
    try {
      await _api.dio.post('/auth/2fa/enable');
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(success: false,
          message: data?['error'] as String? ?? 'Erreur réseau');
    }
  }

  Future<AuthResult> disable2FA() async {
    try {
      await _api.dio.post('/auth/2fa/disable');
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(success: false,
          message: data?['error'] as String? ?? 'Erreur réseau');
    }
  }
}
