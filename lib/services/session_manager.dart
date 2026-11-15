import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage persistant de la session.
///
/// Les jetons (accès et renouvellement) sont dans le trousseau sécurisé de
/// l'appareil (Keystore Android, Keychain iOS), plus dans les préférences en
/// clair. Les sessions ouvertes par une version précédente sont reprises au
/// premier accès : le jeton est recopié dans le trousseau puis effacé des
/// préférences. Les informations non sensibles (identifiant, rôle, nom,
/// e-mail) restent dans les préférences.
class SessionManager {
  SessionManager._();
  static const _keyToken = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';
  // Même clé que kLocalePrefKey (app_state.dart).
  static const _keyLocale = 'winplus_locale';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Copie en mémoire des jetons : chaque requête lit le jeton d'accès, le
  /// trousseau est trop lent pour être interrogé à chaque fois.
  static String? _access;
  static String? _refresh;
  static bool _loaded = false;

  static Future<void> _load() async {
    if (_loaded) return;
    _access = await _secure.read(key: _keyToken);
    _refresh = await _secure.read(key: _keyRefresh);
    // Reprise d'une session enregistrée en clair par une version précédente.
    final p = await SharedPreferences.getInstance();
    final oldAccess = p.getString(_keyToken);
    final oldRefresh = p.getString(_keyRefresh);
    if (_access == null && oldAccess != null) {
      _access = oldAccess;
      await _secure.write(key: _keyToken, value: oldAccess);
    }
    if (_refresh == null && oldRefresh != null) {
      _refresh = oldRefresh;
      await _secure.write(key: _keyRefresh, value: oldRefresh);
    }
    if (oldAccess != null) await p.remove(_keyToken);
    if (oldRefresh != null) await p.remove(_keyRefresh);
    _loaded = true;
  }

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String email,
    required String role,
    required String name,
  }) async {
    await updateTokens(accessToken: accessToken, refreshToken: refreshToken);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyUserId, userId);
    await p.setString(_keyUserEmail, email);
    await p.setString(_keyUserRole, role);
    await p.setString(_keyUserName, name);
  }

  /// Remplace seulement les jetons (renouvellement, reconfirmation), sans
  /// toucher à l'identité enregistrée.
  static Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _load();
    _access = accessToken;
    await _secure.write(key: _keyToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refresh = refreshToken;
      await _secure.write(key: _keyRefresh, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    await _load();
    return _access;
  }

  static Future<String?> getRefreshToken() async {
    await _load();
    return _refresh;
  }

  static Future<int?> getUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyUserId);
  }

  static Future<String?> getUserRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyUserRole);
  }

  static Future<String?> getUserName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyUserName);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyUserEmail);
  }

  static Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _secure.delete(key: _keyToken);
    await _secure.delete(key: _keyRefresh);
    final p = await SharedPreferences.getInstance();
    // Lot 10.11 : la langue choisie survit à la déconnexion (écran
    // d'accueil et connexion suivante dans la même langue).
    final locale = p.getString(_keyLocale);
    await p.clear();
    if (locale != null) await p.setString(_keyLocale, locale);
  }

  /// Tests uniquement : oublie la copie en mémoire, pour relire le stockage
  /// simulé préparé par le test.
  static void resetForTest() {
    _access = null;
    _refresh = null;
    _loaded = false;
  }
}
