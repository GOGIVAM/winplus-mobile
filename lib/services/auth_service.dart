import 'package:dio/dio.dart';
import '../l10n/l10n.dart';
import 'api_client.dart';
import 'background_notifications.dart';
import 'course_offline_service.dart';
import 'http_cache.dart';
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

/// Réponse de POST /auth/google : session ouverte, ou choix du profil
/// demandé (compte Google encore inconnu de WinPlus).
class GoogleAuthResult {
  final bool success;
  final bool needsRole;
  final String? idToken;
  final String? message;
  final String? locale;
  const GoogleAuthResult(
      {this.success = false,
      this.needsRole = false,
      this.idToken,
      this.message,
      this.locale});
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
      final data = e.response?.data is Map<String, dynamic> ? e.response!.data as Map<String, dynamic> : null;
      final code = data?['errorCode'] as String?;
      return AuthResult(
        success: false,
        message: signInMessage(e.response?.statusCode, code),
        errorCode: code,
      );
    }
  }

  /// Message de connexion refusée, dans la langue de l'application. Le
  /// serveur renvoie ses messages en anglais (« Invalid email or password ») :
  /// seul son code d'erreur est repris.
  static String signInMessage(int? status, String? errorCode) {
    final l = L10n.current;
    if (status == null) return l.authErrNetwork;
    if (status == 429 || errorCode == 'TOO_MANY_ATTEMPTS') return l.authErrTooManyAttempts;
    return switch (errorCode) {
      'EMAIL_NOT_VERIFIED' => l.authErrEmailNotVerified,
      'ACCOUNT_INACTIVE' => l.authErrAccountInactive,
      _ when status == 401 => l.wrongCredentials,
      _ => l.svcLoginFailed,
    };
  }

  /// Identifiant client Google (public), lu sur le serveur qui garde le
  /// secret. `null` : connexion Google non configurée côté serveur.
  Future<String?> googleClientId() async {
    try {
      final res = await _api.dio.get('/auth/google/client');
      final id = (res.data as Map<String, dynamic>?)?['clientId'] as String?;
      return (id == null || id.isEmpty) ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Connexion avec le jeton d'identité Google (même route que le site).
  /// Compte existant (lié à Google, ou même adresse e-mail) : session
  /// ouverte. Compte inconnu : [GoogleAuthResult.needsRole], à rappeler avec
  /// le même [idToken] et le [role] choisi.
  Future<GoogleAuthResult> googleSignIn(String idToken, {String? role}) async {
    try {
      final res = await _api.dio.post('/auth/google', data: {
        'idToken': idToken,
        if (role != null) 'role': role,
        'locale': L10n.code,
        // Application mobile : jetons dans la réponse (pas de cookie).
        'rememberMe': true,
      });
      final d = res.data as Map<String, dynamic>;
      if (d['needsRole'] == true) {
        return GoogleAuthResult(
            needsRole: true, idToken: d['idToken'] as String? ?? idToken);
      }
      final u = d['user'] as Map<String, dynamic>;
      await SessionManager.save(
        accessToken: d['accessToken'] as String,
        refreshToken: d['refreshToken'] as String,
        userId: u['id'] as int,
        email: u['email'] as String,
        role: (u['role'] as String?) ?? 'student',
        name: '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim(),
      );
      return GoogleAuthResult(success: true, locale: u['locale'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      return GoogleAuthResult(
          message: data is Map ? data['error'] as String? : null);
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
      await SessionManager.markIdentityChecked();
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
    // Plus d'écoute ni de vérification de fond pour le compte qui part.
    await BackgroundNotifications.stopForAccount();
    // Lectures gardées pour le hors ligne : effacées avec le compte.
    await HttpCache.instance.clearForUser(await SessionManager.getUserId());
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
