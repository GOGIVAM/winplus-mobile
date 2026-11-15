import 'package:dio/dio.dart';
import '../l10n/l10n.dart';
import 'api_client.dart';
import 'course_offline_service.dart';
import 'session_manager.dart';
import 'user_service.dart';
import '../data/models.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final String? locale;
  const AuthResult(
      {required this.success, this.message, this.errorCode, this.locale});
}

/// Réponse de GET /auth/reconfirmation-status.
class ReconfirmationStatus {
  final bool required;
  final int windowDays;
  final String maskedEmail;
  const ReconfirmationStatus(
      {required this.required,
      required this.windowDays,
      required this.maskedEmail});

  factory ReconfirmationStatus.fromJson(Map<String, dynamic> j) =>
      ReconfirmationStatus(
        required: j['required'] == true,
        windowDays: (j['windowDays'] as num?)?.toInt() ?? 35,
        maskedEmail: (j['maskedEmail'] as String?) ?? '',
      );
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
      final u = d['user'] as Map<String, dynamic>;
      await SessionManager.save(
        accessToken: d['accessToken'] as String,
        refreshToken: d['refreshToken'] as String,
        userId: u['id'] as int,
        email: u['email'] as String,
        role: (u['role'] as String?) ?? 'student',
        name: '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim(),
      );
      return AuthResult(success: true, locale: u['locale'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
        success: false,
        message: data?['error'] as String? ?? L10n.current.svcLoginFailed,
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
        // Lot 10.11 : le compte naît dans la langue de l'application.
        'locale': L10n.code,
      });
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
        success: false,
        message: data?['error'] as String? ?? L10n.current.svcSignupFailed,
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
        message: data?['error'] as String? ?? L10n.current.svcInvalidCode,
      );
    }
  }

  Future<AuthResult> resendVerification(String email) async {
    try {
      await _api.dio.post('/auth/resend-verification', data: {'email': email});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? L10n.current.commonNetworkError);
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _api.dio.post('/auth/forgot-password', data: {'email': email});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? L10n.current.commonNetworkError);
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
          message: data?['error'] as String? ?? L10n.current.commonNetworkError);
    }
  }

  /// Reconfirmation périodique d'identité : le serveur dit si elle est due
  /// (GET /auth/reconfirmation-status, fenêtre de 35 jours). Null si le
  /// serveur ne répond pas (hors ligne compris) : on ne bloque jamais
  /// l'utilisateur pour ça, comme le site.
  Future<ReconfirmationStatus?> reconfirmationStatus() async {
    try {
      final res = await _api.dio.get('/auth/reconfirmation-status');
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] ?? body) as Map<String, dynamic>;
      return ReconfirmationStatus.fromJson(d);
    } catch (_) {
      return null;
    }
  }

  /// Envoie le code de reconfirmation par e-mail.
  Future<AuthResult> sendPeriodicCode() async {
    try {
      await _api.dio.post('/auth/send-confirmation-code', data: {});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data;
      return AuthResult(
          success: false,
          message: (data is Map ? data['error'] as String? : null) ??
              L10n.current.commonNetworkError);
    }
  }

  /// Vérifie le code ; le serveur renvoie des jetons neufs, enregistrés ici.
  Future<AuthResult> verifyPeriodicCode(String code) async {
    try {
      final res = await _api.dio
          .post('/auth/verify-confirmation', data: {'code': code});
      final d = res.data as Map<String, dynamic>;
      final access = d['accessToken'] as String?;
      if (access != null && access.isNotEmpty) {
        await SessionManager.updateTokens(
            accessToken: access, refreshToken: d['refreshToken'] as String?);
      }
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data;
      return AuthResult(
          success: false,
          message: (data is Map ? data['error'] as String? : null) ??
              L10n.current.authCodeIncorrect,
          errorCode: data is Map ? data['errorCode'] as String? : null);
    }
  }

  Future<void> signOut() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {}
    // Module 27 (lot 8) : purge la clé de chiffrement et les leçons de
    // formation téléchargées hors-ligne du compte courant, avant d'effacer
    // la session elle-même (SessionManager.getUserId() doit encore
    // répondre).
    await CourseOfflineService.instance.wipeForLogout();
    await SessionManager.clear();
    // Le badge de notifications ne doit pas survivre au compte précédent.
    UserService.instance.resetNotifications();
  }

  Future<AuthResult> enable2FA() async {
    try {
      await _api.dio.post('/auth/2fa/enable');
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? L10n.current.commonNetworkError);
    }
  }

  Future<AuthResult> disable2FA() async {
    try {
      await _api.dio.post('/auth/2fa/disable');
      return const AuthResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      return AuthResult(
          success: false,
          message: data?['error'] as String? ?? L10n.current.commonNetworkError);
    }
  }
}
