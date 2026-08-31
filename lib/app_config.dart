/// Configuration globale de l'application.
/// En mode développement, tous les verrous d'abonnement sont désactivés.
class AppConfig {
  AppConfig._();

  /// Mode développement désactivé  toutes les données proviennent de l'API réelle.
  static const bool devMode = false;

  /// URL de base de l'API backend.
  static const String apiBaseUrl = 'https://api.winplus.cm/api';

  /// Clé de l'API (sera remplacée par un token JWT à la connexion).
  static const String apiVersion = 'v1';

  /// Timeout des requêtes réseau en secondes.
  static const int networkTimeout = 30;
}
