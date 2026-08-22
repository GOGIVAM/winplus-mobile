import 'package:shared_preferences/shared_preferences.dart';

/// Stockage persistant du token JWT et des infos de session.
class SessionManager {
  SessionManager._();
  static const _keyToken = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String email,
    required String role,
    required String name,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, accessToken);
    await p.setString(_keyRefresh, refreshToken);
    await p.setInt(_keyUserId, userId);
    await p.setString(_keyUserEmail, email);
    await p.setString(_keyUserRole, role);
    await p.setString(_keyUserName, name);
  }

  static Future<String?> getAccessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyToken);
  }

  static Future<String?> getRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyRefresh);
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

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
