/// Configuration globale de l'application.
///
/// Environnement choisi à la compilation, sans toucher au code :
///   flutter run --dart-define=WINPLUS_ENV=integration
///   flutter build apk --dart-define=WINPLUS_ENV=integration
/// Sans option, l'application vise la production (winplus.cm).
/// L'intégration (base anonymisée, paiements simulés) sert à tester sans
/// risque pour les vraies données.
class AppConfig {
  AppConfig._();

  /// Mode développement désactivé : toutes les données proviennent de l'API réelle.
  static const bool devMode = false;

  /// « production » (par défaut) ou « integration ».
  static const String environment =
      String.fromEnvironment('WINPLUS_ENV', defaultValue: 'production');

  static const bool isIntegration = environment == 'integration';

  /// Adresse du site (liens partagés, vérification de certificat, liens
  /// profonds).
  static const String siteUrl =
      isIntegration ? 'https://integration.winplus.cm' : 'https://winplus.cm';

  /// URL de base de l'API backend.
  static const String apiBaseUrl = isIntegration
      ? 'https://api.integration.winplus.cm/api'
      : 'https://api.winplus.cm/api';

  /// Clé de l'API (sera remplacée par un token JWT à la connexion).
  static const String apiVersion = 'v1';

  /// Timeout des requêtes réseau en secondes.
  static const int networkTimeout = 30;
}
