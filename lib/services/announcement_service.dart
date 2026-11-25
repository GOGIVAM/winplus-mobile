import 'package:dio/dio.dart';

import 'api_client.dart';

/// Annonce reçue d'un établissement (élève ou parent).
class ApiReceivedAnnouncement {
  final int id;
  final String title;
  final String content;

  /// info, important ou urgent.
  final String type;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? institutionName;
  final String? groupName;

  const ApiReceivedAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.createdAt,
    this.expiresAt,
    this.institutionName,
    this.groupName,
  });

  factory ApiReceivedAnnouncement.fromJson(Map<String, dynamic> j) => ApiReceivedAnnouncement(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
        type: j['type']?.toString() ?? 'info',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
        expiresAt: DateTime.tryParse(j['expiresAt']?.toString() ?? '')?.toLocal(),
        institutionName: j['institutionName'] as String?,
        groupName: j['groupName'] as String?,
      );
}

/// Annonce envoyée par l'établissement.
class ApiSentAnnouncement {
  final int id;
  final String title;
  final String content;

  /// students, parents ou all.
  final String audience;
  final String type;
  final int recipientCount;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final int? groupId;
  final String? groupName;

  const ApiSentAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.audience,
    required this.type,
    required this.recipientCount,
    this.expiresAt,
    this.createdAt,
    this.groupId,
    this.groupName,
  });

  factory ApiSentAnnouncement.fromJson(Map<String, dynamic> j) => ApiSentAnnouncement(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
        audience: j['audience']?.toString() ?? 'all',
        type: j['type']?.toString() ?? 'info',
        recipientCount: (j['recipientCount'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(j['expiresAt']?.toString() ?? '')?.toLocal(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
        groupId: (j['groupId'] as num?)?.toInt(),
        groupName: j['groupName'] as String?,
      );

  bool get expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

/// Refus du serveur à la création ou à la suppression, avec son message.
class AnnouncementException implements Exception {
  final String? message;
  const AnnouncementException(this.message);
}

/// Annonces d'établissement (lot 7), comme le site.
class AnnouncementService {
  AnnouncementService._();
  static final AnnouncementService instance = AnnouncementService._();
  final _api = ApiClient.instance;

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    return raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];
  }

  static AnnouncementException _refusal(DioException e) {
    final d = e.response?.data;
    return AnnouncementException(d is Map ? d['error']?.toString() : null);
  }

  /// Annonces reçues (élève : ses établissements ; parent : ceux de ses
  /// enfants), non expirées, les plus récentes d'abord (20 au plus).
  Future<List<ApiReceivedAnnouncement>> feed() async {
    final res = await _api.dio.get('/institution/announcements/feed');
    return _list(res.data).map(ApiReceivedAnnouncement.fromJson).toList();
  }

  /// Annonces envoyées par l'établissement connecté.
  Future<List<ApiSentAnnouncement>> sent() async {
    final res = await _api.dio.get('/institution/announcements');
    return _list(res.data).map(ApiSentAnnouncement.fromJson).toList();
  }

  /// Publie une annonce ; renvoie le nombre de destinataires notifiés.
  Future<int> create({
    required String title,
    required String content,
    required String audience,
    required String type,
    int? groupId,
    DateTime? expiresAt,
  }) async {
    try {
      final res = await _api.dio.post('/institution/announcements', data: {
        'title': title,
        'content': content,
        'audience': audience,
        'type': type,
        if (groupId != null) 'studyGroupId': groupId,
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      });
      final d = res.data is Map ? (res.data as Map)['data'] : null;
      return (d is Map ? (d['recipientCount'] as num?)?.toInt() : null) ?? 0;
    } on DioException catch (e) {
      if (e.response != null) throw _refusal(e);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('/institution/announcements/$id');
    } on DioException catch (e) {
      if (e.response != null) throw _refusal(e);
      rethrow;
    }
  }
}
