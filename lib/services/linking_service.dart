import '../services/api_client.dart';
import 'connectivity_service.dart';

class LinkingService {
  static final instance = LinkingService._();
  LinkingService._();

  Future<Map<String, dynamic>> getStudentLinks() =>
      ApiClient.instance.get('/student/links');

  Future<List<dynamic>> searchUsers(String q) async {
    final resp =
        await ApiClient.instance.get('/teacher-links/search', params: {'q': q});
    return resp as List;
  }

  /// Demande d'accès enseignant = toujours en ligne, jamais mise en file
  /// (requireOnline).
  Future<void> invite(int targetUserId) {
    requireOnline();
    return ApiClient.instance
        .post('/teacher-links/invite', data: {'targetUserId': targetUserId});
  }

  Future<List<dynamic>> getPendingInvitations() async {
    final resp = await ApiClient.instance.get('/teacher-links/pending');
    return resp as List;
  }

  Future<void> acceptInvitation(int linkId) {
    requireOnline();
    return ApiClient.instance.put('/teacher-links/$linkId/accept', data: {});
  }

  Future<void> rejectInvitation(int linkId) {
    requireOnline();
    return ApiClient.instance.put('/teacher-links/$linkId/reject', data: {});
  }

  Future<List<dynamic>> getMyLinks() async {
    final resp = await ApiClient.instance.get('/teacher-links/mine');
    return resp as List;
  }

  Future<void> deleteLink(int linkId) =>
      ApiClient.instance.delete('/teacher-links/$linkId');

  // ── Rattachements à un établissement (suivi 17.14) ──────────────────
  // Tant que l'élève n'a pas accepté, l'établissement ne peut ni réserver, ni
  // payer, ni attribuer un cours particulier pour lui. Le refus est réversible.

  /// Liste {id, institutionName, city, groupName, status: pending|accepted|refused}.
  Future<List<Map<String, dynamic>>> getInstitutionAttachments() async {
    final res = await ApiClient.instance.dio.get('/student/institution-attachments');
    final data = res.data;
    final list = data is Map ? data['data'] : data;
    return (list is List ? list : const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> respondInstitutionAttachment(int id, {required bool accept}) async {
    requireOnline();
    await ApiClient.instance.dio
        .put('/student/institution-attachments/$id/${accept ? 'accept' : 'refuse'}', data: {});
  }
}
