import '../services/api_client.dart';
import 'connectivity_service.dart';

class LinkingService {
  static final instance = LinkingService._();
  LinkingService._();

  Future<Map<String, dynamic>> getStudentLinks() =>
      ApiClient.instance.get('/student/links');

  Future<List<dynamic>> searchUsers(String q) async {
    final resp = await ApiClient.instance.get('/teacher-links/search', params: {'q': q});
    return resp as List;
  }

  /// Demande d'accès enseignant = toujours en ligne, jamais mise en file
  /// (requireOnline).
  Future<void> invite(int targetUserId) {
    requireOnline();
    return ApiClient.instance.post('/teacher-links/invite', data: {'targetUserId': targetUserId});
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
}
