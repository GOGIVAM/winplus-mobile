import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// Fiche d'un établissement, telle que son compte peut la relire et la
/// modifier (GET et PUT /institution/profile).
class InstitutionProfile {
  final int id;
  final String name, code, country, city, region, address, phone, email;
  final String type, subsystem, teaching;
  final List<String> cycles, goals;
  final int studentsEstimate;
  final String? logoUrl;

  const InstitutionProfile({
    required this.id,
    this.name = '',
    this.code = '',
    this.country = '',
    this.city = '',
    this.region = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.type = '',
    this.subsystem = '',
    this.teaching = '',
    this.cycles = const [],
    this.goals = const [],
    this.studentsEstimate = 0,
    this.logoUrl,
  });

  factory InstitutionProfile.fromJson(Map<String, dynamic> j) {
    String str(Object? v) => v is String ? v.trim() : '';
    List<String> list(Object? v) =>
        (v is List ? v : const []).whereType<String>().toList();
    final logo = str(j['logoUrl']);
    return InstitutionProfile(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: str(j['name']),
      code: str(j['code']),
      country: str(j['country']),
      city: str(j['city']),
      region: str(j['region']),
      address: str(j['address']),
      phone: str(j['phone']),
      email: str(j['email']),
      type: str(j['type']),
      subsystem: str(j['subsystem']),
      teaching: str(j['teaching']),
      cycles: list(j['cycles']),
      goals: list(j['goals']),
      studentsEstimate: (j['studentsEstimate'] as num?)?.toInt() ?? 0,
      logoUrl: logo.isEmpty ? null : logo,
    );
  }
}

class InstitutionProfileException implements Exception {
  final String message;
  final String? code;
  final int? status;
  const InstitutionProfileException(this.message, {this.code, this.status});

  /// Le serveur ne connaît pas (encore) la route.
  bool get routeMissing => status == 404 && code == null || status == 405;

  /// Compte pas encore rattaché à un établissement.
  bool get notLinked => code == 'etablissement_non_rattache';

  @override
  String toString() => message;
}

/// Valeurs permises par le serveur, dans l'ordre d'affichage.
class InstitutionChoices {
  InstitutionChoices._();
  static const types = [
    'ecole_primaire',
    'college',
    'lycee',
    'lycee_technique',
    'universite',
    'grande_ecole',
    'centre_formation',
    'centre_concours',
  ];
  static const cycles = ['primaire', 'secondaire', 'superieur', 'concours'];
  static const subsystems = ['fr', 'en', 'bilingue'];
  static const teachings = ['general', 'technique', 'both'];
  static const goals = [
    'suivi',
    'examens',
    'devoirs',
    'parents',
    'enseignants',
    'orientation',
  ];
}

class InstitutionProfileService {
  InstitutionProfileService._();
  static final InstitutionProfileService instance =
      InstitutionProfileService._();

  final _api = ApiClient.instance;

  InstitutionProfileException _fail(Object error) {
    final fallback = L10n.current.commonLoadError;
    if (error is! DioException) return InstitutionProfileException(fallback);
    final body = error.response?.data;
    final map = body is Map ? body : const {};
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return InstitutionProfileException(
        text(map['message']) ?? text(map['error']) ?? fallback,
        code: text(map['code']),
        status: error.response?.statusCode);
  }

  static Map<String, dynamic> _data(Object? body) {
    final map = body is Map ? body : const {};
    final data = map['data'];
    return Map<String, dynamic>.from(data is Map ? data : map);
  }

  Future<InstitutionProfile> load() async {
    try {
      final res = await _api.dio.get('/institution/profile');
      return InstitutionProfile.fromJson(_data(res.data));
    } catch (e) {
      throw _fail(e);
    }
  }

  /// Enregistre les champs de [changes] (seuls les champs envoyés changent).
  /// Le nom n'est jamais appliqué directement : la demande part à l'équipe
  /// WinPlus, et [nameChangeRequested] le signale.
  Future<({InstitutionProfile profile, bool nameChangeRequested})> save(
      Map<String, dynamic> changes) async {
    try {
      final res = await _api.dio.put('/institution/profile', data: changes);
      final body = res.data;
      return (
        profile: InstitutionProfile.fromJson(_data(body)),
        nameChangeRequested:
            body is Map && body['nameChangeRequested'] == true,
      );
    } catch (e) {
      throw _fail(e);
    }
  }
}
