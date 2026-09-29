import 'api_client.dart';
import 'connectivity_service.dart';
import 'outbox_service.dart';

class ApiConversation {
  final int id;
  final String participantName;
  final String participantRole;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  const ApiConversation({
    required this.id,
    required this.participantName,
    required this.participantRole,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ApiConversation.fromJson(Map<String, dynamic> j) => ApiConversation(
        id: j['id'] as int? ?? 0,
        participantName: j['participantName'] as String? ?? '',
        participantRole: j['participantRole'] as String? ?? 'teacher',
        avatarUrl: j['avatarUrl'] as String?,
        lastMessage: j['lastMessage'] as String?,
        lastMessageAt: DateTime.tryParse(j['lastMessageAt'] as String? ?? ''),
        unreadCount: j['unreadCount'] as int? ?? 0,
      );
}

class ApiMessage {
  final int id;
  final String content;
  final bool isFromMe;
  final DateTime sentAt;
  const ApiMessage({
    required this.id,
    required this.content,
    required this.isFromMe,
    required this.sentAt,
  });

  factory ApiMessage.fromJson(Map<String, dynamic> j) => ApiMessage(
        id: j['id'] as int? ?? 0,
        content: j['content'] as String? ?? '',
        isFromMe: j['isFromMe'] as bool? ?? false,
        sentAt:
            DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final _api = ApiClient.instance;

  Future<List<ApiConversation>> getConversations() async {
    final res = await _api.dio.get('/messages/conversations');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApiMessage>> getMessages(int conversationId) async {
    final res =
        await _api.dio.get('/messages/conversations/$conversationId/messages');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Enregistre le rejeu des messages mis en file hors ligne  à appeler une
  /// fois au démarrage (voir main.dart).
  static void registerOutboxHandler() {
    OutboxService.instance.registerHandler('message_send', (payload) async {
      await ApiClient.instance.dio.post(
        '/messages/conversations/${payload['conversationId']}/messages',
        data: {'content': payload['content']},
      );
      return true;
    });
  }

  Future<bool> sendMessage(int conversationId, String content) async {
    try {
      await _api.dio
          .post('/messages/conversations/$conversationId/messages', data: {
        'content': content,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Envoie immédiatement si en ligne ; sinon met le message en file
  /// (OutboxService) pour un envoi automatique au retour du réseau, plutôt
  /// que de perdre silencieusement le contenu saisi.
  Future<bool> sendMessageQueueable(int conversationId, String content) async {
    if (ConnectivityService.instance.isOnline) {
      final ok = await sendMessage(conversationId, content);
      if (ok) return true;
    }
    await OutboxService.instance.enqueue('message_send', {
      'conversationId': conversationId,
      'content': content,
    });
    return true; // mis en file avec succès  affiché comme envoyé/en attente côté UI
  }

  Future<int?> startConversation(int recipientId,
      {String firstMessage = ''}) async {
    try {
      final res = await _api.dio.post('/messages/conversations', data: {
        'participantId': recipientId,
        'firstMessage': firstMessage.isNotEmpty ? firstMessage : 'Bonjour',
      });
      final d = res.data as Map<String, dynamic>?;
      return d?['conversationId'] as int? ?? d?['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> markRead(int conversationId) async {
    try {
      await _api.dio.put('/messages/conversations/$conversationId/read');
    } catch (_) {}
  }
}
