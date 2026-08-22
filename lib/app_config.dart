/// Configuration globale de l'application.
/// En mode développement, tous les verrous d'abonnement sont désactivés.
class AppConfig {
  AppConfig._();

  /// Mettre à false avant le déploiement en production.
  static const bool devMode = true;

  /// URL de base de l'API backend.
  static const String apiBaseUrl = 'https://api.winplus.cm/api';

  /// Clé de l'API (sera remplacée par un token JWT à la connexion).
  static const String apiVersion = 'v1';

  /// Timeout des requêtes réseau en secondes.
  static const int networkTimeout = 30;
}
