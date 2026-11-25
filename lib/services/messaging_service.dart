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

/// Message cité par une réponse (aperçu renvoyé par le serveur).
class ApiMessageReply {
  final int id;
  final String content;
  final bool isFromMe;
  const ApiMessageReply({required this.id, required this.content, required this.isFromMe});

  static ApiMessageReply? fromJson(dynamic j) => j is Map
      ? ApiMessageReply(
          id: (j['id'] as num?)?.toInt() ?? 0,
          content: j['content']?.toString() ?? '',
          isFromMe: j['isFromMe'] == true,
        )
      : null;
}

/// Réaction (emoji) d'un participant ; une seule par personne et par message.
class ApiReaction {
  final String emoji;
  final bool isMine;
  const ApiReaction({required this.emoji, required this.isMine});

  factory ApiReaction.fromJson(Map<String, dynamic> j) =>
      ApiReaction(emoji: j['emoji']?.toString() ?? '', isMine: j['isMine'] == true);

  static List<ApiReaction> listFrom(dynamic raw) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(ApiReaction.fromJson).toList()
      : const [];
}

class ApiMessage {
  final int id;
  final String content;
  final bool isFromMe;
  final DateTime sentAt;
  final bool isDeleted;
  final ApiMessageReply? replyTo;
  final List<ApiReaction> reactions;
  const ApiMessage({
    required this.id,
    required this.content,
    required this.isFromMe,
    required this.sentAt,
    this.isDeleted = false,
    this.replyTo,
    this.reactions = const [],
  });

  factory ApiMessage.fromJson(Map<String, dynamic> j) => ApiMessage(
        id: j['id'] as int? ?? 0,
        content: j['content'] as String? ?? '',
        isFromMe: j['isFromMe'] as bool? ?? false,
        sentAt:
            DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
        isDeleted: j['isDeleted'] == true,
        replyTo: ApiMessageReply.fromJson(j['replyTo']),
        reactions: ApiReaction.listFrom(j['reactions']),
      );

  ApiMessage withReactions(List<ApiReaction> r) => ApiMessage(
        id: id,
        content: content,
        isFromMe: isFromMe,
        sentAt: sentAt,
        isDeleted: isDeleted,
        replyTo: replyTo,
        reactions: r,
      );

  /// Ma réaction actuelle, ou null.
  String? get myReaction {
    for (final r in reactions) {
      if (r.isMine) return r.emoji;
    }
    return null;
  }
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
        data: {
          'content': payload['content'],
          if (payload['replyToMessageId'] != null)
            'replyToMessageId': payload['replyToMessageId'],
        },
      );
      return true;
    });
  }

  /// [replyTo] : identifiant du message cité (réponse).
  Future<bool> sendMessage(int conversationId, String content, {int? replyTo}) async {
    try {
      await _api.dio
          .post('/messages/conversations/$conversationId/messages', data: {
        'content': content,
        if (replyTo != null) 'replyToMessageId': replyTo,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Envoie immédiatement si en ligne ; sinon met le message en file
  /// (OutboxService) pour un envoi automatique au retour du réseau, plutôt
  /// que de perdre silencieusement le contenu saisi.
  Future<bool> sendMessageQueueable(int conversationId, String content, {int? replyTo}) async {
    if (ConnectivityService.instance.isOnline) {
      final ok = await sendMessage(conversationId, content, replyTo: replyTo);
      if (ok) return true;
    }
    await OutboxService.instance.enqueue('message_send', {
      'conversationId': conversationId,
      'content': content,
      if (replyTo != null) 'replyToMessageId': replyTo,
    });
    return true; // mis en file avec succès  affiché comme envoyé/en attente côté UI
  }

  /// Ajoute, change ou retire (même emoji) ma réaction ; renvoie les
  /// réactions du message après le changement. Lève une erreur en cas
  /// d'échec (l'écran remet l'état précédent).
  Future<List<ApiReaction>> react(int messageId, String emoji) async {
    final res = await _api.dio.post('/messages/$messageId/react', data: {'emoji': emoji});
    return ApiReaction.listFrom(res.data);
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
      // Hors ligne : la lecture part au retour du réseau (lot 3).
      await OutboxService.instance.sendOrQueue(
          method: 'PUT',
          path: '/messages/conversations/$conversationId/read',
          label: 'conversation_read');
    } catch (_) {}
  }
}
