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

/// Un cours en direct de la liste commune (GET /visio/mes-cours) : séance
/// d'un professeur ou tutorat en ligne, quel que soit le rôle.
class ApiLiveClass {
  final VisioType type;
  final int id;
  final String title;
  final String? subject;
  final DateTime start;
  final DateTime end;

  /// animateur, participant, ou enfant (parent : consultation seulement).
  final String role;
  final String host;
  final String? child;
  final bool pendingPayment;

  /// a_venir, ouverte ou terminee.
  final String state;
  final int recordings;

  const ApiLiveClass({
    required this.type,
    required this.id,
    required this.title,
    this.subject,
    required this.start,
    required this.end,
    required this.role,
    required this.host,
    this.child,
    required this.pendingPayment,
    required this.state,
    required this.recordings,
  });

  static ApiLiveClass? fromJson(Map<String, dynamic> j) {
    final type = visioTypeFrom(j['type']?.toString() ?? '');
    final start = DateTime.tryParse(j['debut']?.toString() ?? '')?.toLocal();
    if (type == null || start == null) return null;
    return ApiLiveClass(
      type: type,
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['titre']?.toString() ?? '',
      subject: j['matiere'] as String?,
      start: start,
      end: DateTime.tryParse(j['fin']?.toString() ?? '')?.toLocal() ?? start,
      role: j['role']?.toString() ?? 'participant',
      host: j['animateur']?.toString() ?? '',
      child: (j['enfant'] as String?)?.trim().isEmpty ?? true ? null : j['enfant'] as String,
      pendingPayment: j['enAttentePaiement'] == true,
      state: j['etat']?.toString() ?? 'a_venir',
      recordings: (j['enregistrements'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isHost => role == 'animateur';
  bool get isChildView => role == 'enfant';

  /// Peut entrer dans la salle : pas le parent, pas un paiement en attente,
  /// pas une séance terminée.
  bool get canEnter => !isChildView && !pendingPayment && state != 'terminee';
}

/// Fiche d'une séance en direct (GET /visio/seance/{id}), pour le lien
/// partagé /sessions/{id} : de quoi s'inscrire puis entrer.
class ApiLiveSession {
  final int id;
  final String title;
  final String? description;
  final String? subject;
  final String? level;
  final DateTime start;
  final DateTime end;
  final bool free;
  final num? priceXaf;
  final int? seatsLeft;
  final bool cancelled;
  final String? externalLink;
  final String? teacher;

  /// animateur, inscrit, paiement_en_attente ou aucun.
  final String myRole;

  /// a_venir, ouverte, terminee ou annulee.
  final String state;

  const ApiLiveSession({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.level,
    required this.start,
    required this.end,
    required this.free,
    this.priceXaf,
    this.seatsLeft,
    required this.cancelled,
    this.externalLink,
    this.teacher,
    required this.myRole,
    required this.state,
  });

  factory ApiLiveSession.fromJson(Map<String, dynamic> j) {
    final start = DateTime.tryParse(j['debut']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final prof = j['professeur'];
    final link = (j['lienExterne'] as String?)?.trim();
    return ApiLiveSession(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['titre']?.toString() ?? '',
      description: j['description'] as String?,
      subject: j['matiere'] as String?,
      level: j['niveau'] as String?,
      start: start,
      end: DateTime.tryParse(j['fin']?.toString() ?? '')?.toLocal() ?? start,
      free: j['gratuit'] != false,
      priceXaf: j['prixXaf'] as num?,
      seatsLeft: (j['placesRestantes'] as num?)?.toInt(),
      cancelled: j['annulee'] == true,
      externalLink: (link == null || link.isEmpty) ? null : link,
      teacher: prof is Map ? prof['nom']?.toString() : null,
      myRole: j['monRole']?.toString() ?? 'aucun',
      state: j['etat']?.toString() ?? 'a_venir',
    );
  }

  bool get canEnter =>
      (myRole == 'animateur' || myRole == 'inscrit') && !cancelled && state != 'terminee';
}

/// Enregistrement d'une séance : lien présigné valable 6 heures.
class ApiVisioRecording {
  final int id;
  final String fileName;
  final int sizeBytes;
  final DateTime? createdAt;
  final String url;

  const ApiVisioRecording({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    this.createdAt,
    required this.url,
  });

  factory ApiVisioRecording.fromJson(Map<String, dynamic> j) => ApiVisioRecording(
        id: (j['id'] as num?)?.toInt() ?? 0,
        fileName: j['fileName']?.toString() ?? '',
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
        url: j['url']?.toString() ?? '',
      );
}

/// Refus d'inscription avec le message du serveur (complet, déjà inscrit,
/// paiement impossible…).
class LiveEnrollException implements Exception {
  final String? message;
  const LiveEnrollException(this.message);
}

class VisioService {
  VisioService._();
  static final VisioService instance = VisioService._();
  final _api = ApiClient.instance;

  static Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is Map<String, dynamic>) return d;
      return body;
    }
    return const {};
  }

  /// Tous les cours en direct de la personne (30 jours passés, 90 à venir),
  /// triés par le serveur : ouverts, à venir, terminés.
  Future<List<ApiLiveClass>> myClasses() async {
    final res = await _api.dio.get('/visio/mes-cours');
    final body = res.data;
    final list = body is Map ? body['data'] : body;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApiLiveClass.fromJson)
        .whereType<ApiLiveClass>()
        .toList();
  }

  /// Fiche d'une séance. [VisioException] notFound si elle n'existe pas.
  Future<ApiLiveSession> session(int id) async {
    try {
      final res = await _api.dio.get('/visio/seance/$id');
      return ApiLiveSession.fromJson(_data(res.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const VisioException(VisioRefusal.notFound);
      rethrow;
    }
  }

  /// Inscription (POST /sessions/{id}/enroll) ; [phone] pour une séance
  /// payante (paiement Mobile Money à valider sur le téléphone).
  Future<void> enroll(int id, {String? phone}) async {
    try {
      await _api.dio.post('/sessions/$id/enroll',
          data: {if (phone != null && phone.isNotEmpty) 'phone': phone});
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response != null) {
        throw LiveEnrollException(data is Map ? data['error']?.toString() : null);
      }
      rethrow;
    }
  }

  Future<List<ApiVisioRecording>> recordings(VisioType type, int id) async {
    try {
      final res = await _api.dio.get('/visio/enregistrements',
          queryParameters: {'type': type.name, 'id': id});
      final list = _data(res.data)['liste'];
      if (list is! List) return const [];
      return list.whereType<Map<String, dynamic>>().map(ApiVisioRecording.fromJson).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const VisioException(VisioRefusal.notFound);
      rethrow;
    }
  }

  /// Signal de présence pour l'appel du professeur : arrivee, present
  /// (toutes les minutes), depart. Renvoie l'identifiant du passage, à
  /// renvoyer ensuite.
  Future<int?> presence(VisioType type, int id, String event, {int? presenceId}) async {
    final res = await _api.dio.post('/visio/presence', data: {
      'type': type.name,
      'id': id,
      'evenement': event,
      if (presenceId != null) 'presenceId': presenceId,
    });
    return (_data(res.data)['presenceId'] as num?)?.toInt();
  }

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
