import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Note de révision d'une épreuve, gardée sur le serveur.
class ApiRevisionNote {
  final int id;
  final String content;
  final DateTime? createdAt;
  const ApiRevisionNote({required this.id, required this.content, this.createdAt});

  factory ApiRevisionNote.fromJson(Map<String, dynamic> j) => ApiRevisionNote(
        id: (j['id'] as num?)?.toInt() ?? 0,
        content: j['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
      );
}

class RevisionNotesPayload {
  final List<ApiRevisionNote> notes;
  final List<String> tags;
  const RevisionNotesPayload({required this.notes, required this.tags});
}

/// Notes et étiquettes de révision d'une épreuve (lot 7), comme
/// RevisionNotes du site (GET/POST/DELETE /revision-notes, étiquettes par
/// /revision-notes/tags/toggle) : elles suivent l'élève sur le site et sur
/// un autre téléphone.
///
/// Les anciennes notes gardées sur le téléphone (clés notes_{id} et
/// tags_{id}) servent de file d'attente : [syncLocal] les envoie, puis ne
/// les efface qu'une fois arrivées ; une note écrite sans réseau y est
/// ajoutée et partira à la prochaine ouverture.
class RevisionNotesService {
  RevisionNotesService._();
  static final RevisionNotesService instance = RevisionNotesService._();
  final _api = ApiClient.instance;

  static const maxLength = 300;
  static String _notesKey(int subjectId) => 'notes_$subjectId';
  static String _tagsKey(int subjectId) => 'tags_$subjectId';

  static Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  Future<RevisionNotesPayload> load(int subjectId) async {
    final res = await _api.dio.get('/revision-notes', queryParameters: {'subjectId': subjectId});
    final d = _data(res.data);
    return RevisionNotesPayload(
      notes: (d['notes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ApiRevisionNote.fromJson)
          .toList(),
      tags: (d['tags'] as List? ?? const []).map((e) => '$e').toList(),
    );
  }

  Future<ApiRevisionNote> add(int subjectId, String content) async {
    final res = await _api.dio.post('/revision-notes', data: {'subjectId': subjectId, 'content': content});
    return ApiRevisionNote.fromJson(_data(res.data));
  }

  Future<void> delete(int id) => _api.dio.delete('/revision-notes/$id');

  Future<List<String>> toggleTag(int subjectId, String label) async {
    final res = await _api.dio.post('/revision-notes/tags/toggle', data: {'subjectId': subjectId, 'label': label});
    return (_data(res.data)['tags'] as List? ?? const []).map((e) => '$e').toList();
  }

  // ---- File locale (anciennes notes et notes écrites hors ligne) ----

  Future<List<String>> pendingNotes(int subjectId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_notesKey(subjectId));
    if (raw == null) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _setPending(int subjectId, List<String> notes) async {
    final p = await SharedPreferences.getInstance();
    if (notes.isEmpty) {
      await p.remove(_notesKey(subjectId));
    } else {
      await p.setString(_notesKey(subjectId), jsonEncode(notes));
    }
  }

  /// Garde une note sur le téléphone, pour l'envoyer plus tard.
  Future<void> keepPending(int subjectId, String content) async {
    final list = [...await pendingNotes(subjectId), content];
    await _setPending(subjectId, list);
  }

  Future<void> removePending(int subjectId, String content) async {
    final list = [...await pendingNotes(subjectId)]..remove(content);
    await _setPending(subjectId, list);
  }

  /// Envoie les notes et étiquettes gardées sur le téléphone ; chacune n'est
  /// effacée qu'une fois arrivée (un échec la garde pour la prochaine fois).
  /// Les étiquettes locales ne sont reprises que si le serveur n'en a aucune.
  /// Renvoie les notes créées sur le serveur.
  Future<List<ApiRevisionNote>> syncLocal(int subjectId, {required List<String> serverTags}) async {
    final created = <ApiRevisionNote>[];
    final remaining = <String>[];
    for (final n in await pendingNotes(subjectId)) {
      final text = n.trim();
      if (text.isEmpty) continue;
      try {
        created.add(await add(subjectId, text.length > maxLength ? text.substring(0, maxLength) : text));
      } catch (_) {
        remaining.add(n);
      }
    }
    await _setPending(subjectId, remaining);

    final p = await SharedPreferences.getInstance();
    final rawTags = p.getString(_tagsKey(subjectId));
    if (rawTags != null) {
      try {
        if (serverTags.isEmpty) {
          for (final t in List<String>.from(jsonDecode(rawTags) as List)) {
            await toggleTag(subjectId, t);
          }
        }
        await p.remove(_tagsKey(subjectId));
      } catch (_) {
        // Gardées pour la prochaine ouverture.
      }
    }
    return created;
  }
}
