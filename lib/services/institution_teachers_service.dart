import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// Refus lisible du serveur.
class InstitutionTeachersException implements Exception {
  final String message;
  const InstitutionTeachersException(this.message);
  @override
  String toString() => message;
}

/// Enseignant affilié à l'établissement, avec ses chiffres et ses classes.
class InstitutionTeacher {
  final int linkId;
  final int id;
  final String name;
  final String? email;
  final DateTime? since;
  final int contents;
  final int published;
  final int quizzes;
  final List<(int, String)> classes;

  const InstitutionTeacher({
    required this.linkId,
    required this.id,
    required this.name,
    this.email,
    this.since,
    this.contents = 0,
    this.published = 0,
    this.quizzes = 0,
    this.classes = const [],
  });
}

/// Demande d'affiliation en attente (reçue d'un enseignant ou envoyée).
class AffiliationRequest {
  final int linkId;
  final int teacherId;
  final String name;
  final String? email;
  final DateTime? createdAt;
  const AffiliationRequest(this.linkId, this.teacherId, this.name, this.email, this.createdAt);
}

class InstitutionTeachersData {
  final List<InstitutionTeacher> teachers;
  final List<AffiliationRequest> received;
  final List<AffiliationRequest> sent;
  const InstitutionTeachersData(this.teachers, this.received, this.sent);
}

/// Enseignant trouvé par la recherche (pour l'inviter).
class TeacherHit {
  final int id;
  final String name;
  final String? email;
  const TeacherHit(this.id, this.name, this.email);
}

/// Enseignants de l'établissement (lot 7), comme InstitutionTeachers du
/// site : affiliés et leurs classes, demandes reçues et envoyées,
/// invitation, retrait d'une classe, fin d'affiliation.
class InstitutionTeachersService {
  InstitutionTeachersService._();
  static final InstitutionTeachersService instance = InstitutionTeachersService._();
  final _api = ApiClient.instance;

  static String _name(Map j) {
    final n = '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim();
    return n.isNotEmpty ? n : '${j['email'] ?? ''}';
  }

  static DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

  static InstitutionTeachersException _error(Object e) {
    if (e is InstitutionTeachersException) return e;
    if (e is DioException) {
      final body = e.response?.data;
      final text = body is Map ? (body['error'] ?? body['message']) : null;
      if (text is String && text.trim().isNotEmpty) return InstitutionTeachersException(text.trim());
    }
    return InstitutionTeachersException(L10n.current.commonLoadError);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw _error(e);
    }
  }

  static List<Map> _maps(Object? v) => (v is List ? v : const []).whereType<Map>().toList();

  Future<InstitutionTeachersData> load() => _guard(() async {
        final res = await _api.dio.get('/institution/teachers');
        final body = res.data is Map ? res.data as Map : const {};
        final d = body['data'] is Map ? body['data'] as Map : body;
        AffiliationRequest req(Map j) => AffiliationRequest((j['linkId'] as num?)?.toInt() ?? 0,
            (j['id'] as num?)?.toInt() ?? 0, _name(j), j['email'] as String?, _date(j['createdAt']));
        return InstitutionTeachersData(
          _maps(d['teachers'])
              .map((j) => InstitutionTeacher(
                    linkId: (j['linkId'] as num?)?.toInt() ?? 0,
                    id: (j['id'] as num?)?.toInt() ?? 0,
                    name: _name(j),
                    email: j['email'] as String?,
                    since: _date(j['since']),
                    contents: (j['contents'] as num?)?.toInt() ?? 0,
                    published: (j['published'] as num?)?.toInt() ?? 0,
                    quizzes: (j['quizzes'] as num?)?.toInt() ?? 0,
                    classes: _maps(j['classes'])
                        .map((c) => ((c['id'] as num?)?.toInt() ?? 0, '${c['name'] ?? ''}'))
                        .toList(),
                  ))
              .toList(),
          _maps(d['received']).map(req).toList(),
          _maps(d['sent']).map(req).toList(),
        );
      });

  Future<void> assign(int groupId, int teacherId) =>
      _guard(() => _api.dio.post('/institution/teachers/groups/$groupId', data: {'teacherId': teacherId}));

  Future<void> unassign(int groupId, int teacherId) =>
      _guard(() => _api.dio.delete('/institution/teachers/groups/$groupId/$teacherId'));

  Future<List<TeacherHit>> search(String q) => _guard(() async {
        if (q.trim().length < 2) return const <TeacherHit>[];
        final res = await _api.dio.get('/institution-network/search-teachers', queryParameters: {'q': q.trim()});
        final raw = res.data is Map ? (res.data as Map)['data'] : res.data;
        return _maps(raw)
            .map((j) => TeacherHit((j['id'] as num?)?.toInt() ?? 0, _name(j), j['email'] as String?))
            .toList();
      });

  Future<void> invite(int teacherId) =>
      _guard(() => _api.dio.post('/institution-network/affiliation/request', data: {'teacherId': teacherId}));

  Future<void> accept(int linkId) => _guard(() => _api.dio.put('/institution-network/affiliation/$linkId/accept'));

  Future<void> reject(int linkId) => _guard(() => _api.dio.put('/institution-network/affiliation/$linkId/reject'));

  /// Annule une invitation envoyée ou met fin à une affiliation.
  Future<void> revoke(int linkId) => _guard(() => _api.dio.delete('/institution-network/affiliation/$linkId'));
}
