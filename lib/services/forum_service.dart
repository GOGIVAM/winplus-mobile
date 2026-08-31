import '../services/api_client.dart';

class ForumService {
  static final instance = ForumService._();
  ForumService._();

  Future<Map<String, dynamic>> getThreads({String? category, int page = 1, int pageSize = 20}) async {
    final qs = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (category != null && category != 'all') qs['category'] = category;
    final resp = await ApiClient.instance.get('/forums/threads', params: qs);
    return resp as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPosts(int threadId) async {
    final resp = await ApiClient.instance.get('/forums/threads/$threadId/posts');
    if (resp is Map) return (resp['posts'] as List?) ?? [];
    return resp as List;
  }

  Future<Map<String, dynamic>> createThread({
    required String title,
    required String content,
    required String category,
    String? tag,
  }) async {
    return await ApiClient.instance.post('/forums/threads', data: {
      'title': title,
      'content': content,
      'category': category,
      if (tag != null) 'tag': tag,
    });
  }

  Future<void> reply(int threadId, String content) async {
    await ApiClient.instance.post('/forums/threads/$threadId/posts', data: {'content': content});
  }

  Future<void> vote(int postId, String type) async {
    await ApiClient.instance.post('/forums/posts/$postId/vote', data: {'type': type});
  }
}
