import 'package:dio/dio.dart';

import 'api_client.dart';

/// Avis élève sur une séance de répétition terminée (Module 6 — avis
/// répétiteurs, professeur_complete.md).
class TutorReview {
  final int id;
  final int tutorBookingId;
  final String? studentName;
  final String? studentAvatarUrl;
  final int rating;
  final String? comment;
  final String? tutorReply;
  final DateTime? tutorRepliedAt;
  final DateTime? createdAt;

  const TutorReview({
    required this.id,
    required this.tutorBookingId,
    this.studentName,
    this.studentAvatarUrl,
    required this.rating,
    this.comment,
    this.tutorReply,
    this.tutorRepliedAt,
    this.createdAt,
  });

  factory TutorReview.fromJson(Map<String, dynamic> j) => TutorReview(
        id: j['id'] as int? ?? 0,
        tutorBookingId: j['tutorBookingId'] as int? ?? 0,
        studentName: j['studentName'] as String?,
        studentAvatarUrl: j['studentAvatarUrl'] as String?,
        rating: j['rating'] as int? ?? 0,
        comment: j['comment'] as String?,
        tutorReply: j['tutorReply'] as String?,
        tutorRepliedAt: j['tutorRepliedAt'] != null ? DateTime.tryParse(j['tutorRepliedAt'] as String) : null,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}

class TutorReviewService {
  TutorReviewService._();
  static final TutorReviewService instance = TutorReviewService._();
  final _api = ApiClient.instance;

  /// L'élève laisse un avis sur une séance terminée (ou contestée). Une
  /// seule fois par réservation ; le serveur renvoie une erreur sinon.
  Future<TutorReview> submit(int tutorBookingId, int rating, {String? comment}) async {
    try {
      final res = await _api.dio.post('/tutor-reviews', data: {
        'tutorBookingId': tutorBookingId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      return TutorReview.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? data?['message'] as String? ?? 'Impossible d\'envoyer l\'avis.');
    }
  }

  /// Le répétiteur répond publiquement à un avis laissé sur son profil.
  Future<TutorReview> reply(int reviewId, String reply) async {
    try {
      final res = await _api.dio.post('/tutor-reviews/$reviewId/reply', data: {'reply': reply});
      return TutorReview.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? data?['message'] as String? ?? 'Impossible d\'envoyer la réponse.');
    }
  }

  /// Avis publics d'un répétiteur (fiche publique), paginés.
  Future<List<TutorReview>> getForTutor(int tutorUserId, {int page = 1, int pageSize = 20}) async {
    final res = await _api.dio.get('/tutor-reviews/tutor/$tutorUserId', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data;
    final list = data is Map<String, dynamic> ? (data['items'] as List? ?? []) : (data as List? ?? []);
    return list.map((e) => TutorReview.fromJson(e as Map<String, dynamic>)).toList();
  }
}
