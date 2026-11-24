import 'package:dio/dio.dart';

import 'api_client.dart';

/// Type de salle de la visio WinPlus (même valeurs que le site,
/// /visio/:type/:id).
enum VisioType {
  /// Séance d'enseignement en direct d'un professeur (élèves inscrits).
  seance,

  /// Réservation de répétiteur en ligne (individuelle ou de groupe).
  tutorat,
}

VisioType? visioTypeFrom(String value) => switch (value) {
      'seance' => VisioType.seance,
      'tutorat' => VisioType.tutorat,
      _ => null,
    };

/// Accès à une salle : domaine Jitsi, nom de la salle et jeton signé par le
/// serveur (GET /visio/jeton), valable pour cette salle seulement.
class ApiVisioAccess {
  final String domain;
  final String room;
  final String token;
  final bool moderator;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String name;

  const ApiVisioAccess({
    required this.domain,
    required this.room,
    required this.token,
    required this.moderator,
    required this.title,
    this.start,
    this.end,
    required this.name,
  });

  factory ApiVisioAccess.fromJson(Map<String, dynamic> j) => ApiVisioAccess(
        domain: j['domaine']?.toString() ?? 'visio.winplus.cm',
        room: j['salle']?.toString() ?? '',
        token: j['jeton']?.toString() ?? '',
        moderator: j['moderateur'] == true,
        title: j['titre']?.toString() ?? '',
        start: DateTime.tryParse(j['debut']?.toString() ?? '')?.toLocal(),
        end: DateTime.tryParse(j['fin']?.toString() ?? '')?.toLocal(),
        name: j['nom']?.toString() ?? '',
      );

  /// Adresse web de la salle, jeton compris. Le paramètre
  /// disableDeepLinking évite la page « ouvrir dans l'application Jitsi »
  /// que Jitsi montre aux navigateurs de téléphone.
  Uri get webUrl => Uri.parse(
      'https://$domain/${Uri.encodeComponent(room)}?jwt=${Uri.encodeQueryComponent(token)}'
      '#config.disableDeepLinking=true&config.prejoinConfig.enabled=false'
      '&userInfo.displayName=${Uri.encodeComponent('"$name"')}');
}

/// Raison pour laquelle la salle ne s'ouvre pas.
enum VisioRefusal {
  /// La salle ouvre 30 minutes avant le début ([VisioException.opensAt]).
  notYet,

  /// Séance terminée depuis plus d'une heure.
  ended,

  /// Séance inexistante, ou la personne n'y est pas inscrite.
  notFound,

  /// Visio non configurée sur le serveur (503).
  unavailable,
}

class VisioException implements Exception {
  final VisioRefusal reason;
  final DateTime? opensAt;
  const VisioException(this.reason, {this.opensAt});
}

class VisioService {
  VisioService._();
  static final VisioService instance = VisioService._();
  final _api = ApiClient.instance;

  /// Jeton d'accès à la salle. Lève [VisioException] pour un refus du
  /// serveur (pas encore ouverte, terminée, introuvable, visio désactivée) ;
  /// toute autre erreur (réseau, panne) remonte telle quelle.
  Future<ApiVisioAccess> access(VisioType type, int id) async {
    try {
      final res = await _api.dio
          .get('/visio/jeton', queryParameters: {'type': type.name, 'id': id});
      final body = res.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return ApiVisioAccess.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final code = data is Map ? data['code']?.toString() : null;
      if (status == 409) {
        if (code == 'terminee') throw const VisioException(VisioRefusal.ended);
        final opens = data is Map
            ? DateTime.tryParse(data['ouverture']?.toString() ?? '')?.toLocal()
            : null;
        throw VisioException(VisioRefusal.notYet, opensAt: opens);
      }
      if (status == 404) throw const VisioException(VisioRefusal.notFound);
      if (status == 503) throw const VisioException(VisioRefusal.unavailable);
      rethrow;
    }
  }
}
