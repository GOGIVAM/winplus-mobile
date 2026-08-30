import 'api_client.dart';

class ApiChatMessage {
  final String role;
  final String content;
  final DateTime createdAt;
  const ApiChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> j) => ApiChatMessage(
        role: j['role'] as String? ?? 'assistant',
        content: j['content'] as String? ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class ApiChatSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final String? lastMessage;
  const ApiChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.lastMessage,
  });

  factory ApiChatSession.fromJson(Map<String, dynamic> j) => ApiChatSession(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? 'Conversation',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        lastMessage: j['lastMessage'] as String?,
      );
}

class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();

  final _api = ApiClient.instance;

  Future<List<ApiChatSession>> getSessions() async {
    final res = await _api.dio.get('/chatbot/conversations');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw as Map<String, dynamic>?)?['conversations'] as List? ?? [];
    return list
        .map((e) => ApiChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApiChatMessage>> getHistory(int sessionId) async {
    final res = await _api.dio.get('/chatbot/conversations/$sessionId');
    final conv = res.data as Map<String, dynamic>?;
    final list = conv?['messages'] as List? ?? [];
    return list
        .map((e) => ApiChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> sendMessage({
    required String message,
    int? sessionId,
    String? context,
  }) async {
    try {
      final res = await _api.dio.post('/chatbot/message', data: {
        'message': message,
        if (sessionId != null) 'conversationId': sessionId,
        if (context != null) 'context': context,
      });
      final d = res.data as Map<String, dynamic>?;
      final assistant = d?['assistantMessage'] as Map<String, dynamic>?;
      return assistant?['content'] as String?
          ?? d?['reply'] as String?
          ?? d?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSession(int sessionId) async {
    try {
      await _api.dio.delete('/chatbot/conversations/$sessionId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
