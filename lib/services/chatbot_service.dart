import 'dart:math';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'connectivity_service.dart';

class ApiWinAIMemory {
  final int id;
  final String type;
  final String content;
  final DateTime createdAt;
  const ApiWinAIMemory({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  factory ApiWinAIMemory.fromJson(Map<String, dynamic> j) => ApiWinAIMemory(
        id: j['id'] as int? ?? 0,
        type: j['type'] as String? ?? 'general',
        content: j['content'] as String? ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

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

  /// Génération IA = toujours en ligne. Contrairement aux autres méthodes de
  /// ce service (qui retournent null en cas d'échec), certains refus renvoient
  /// directement un message explicite comme "réponse" : c'est ce que les
  /// écrans de chat (élève, parent, enseignant, établissement) affichent déjà
  /// tel quel, sans changement de signature à répercuter sur chacun d'eux.
  ///
  ///  - hors-ligne : message d'erreur hors-ligne ;
  ///  - 402 (Partie 8.10) : message serveur — limite de session (5 h) ou
  ///    hebdomadaire (7 jours) atteinte et heure de reprise, sans nombre de
  ///    tokens. Il était auparavant avalé en null (« Désolé, je n'ai pas pu
  ///    répondre ») ;
  ///  - 503 quota_unavailable : message serveur de maintenance.
  /// Toute autre erreur renvoie null, comme avant.
  ///
  /// Le corps suit SendMessageRequest (.NET) : le champ texte est `content`
  /// (l'ancien `message` n'était pas lié au DTO, qui exige Content : chaque
  /// envoi finissait en 400 avalé). `clientMessageId` identifie ce message
  /// pour l'idempotence du décompte (8.7) : un nouvel identifiant par envoi.
  Future<String?> sendMessage({
    required String message,
    int? sessionId,
    String? context,
  }) async {
    if (!ConnectivityService.instance.isOnline) {
      return const OfflineActionException().message;
    }
    try {
      final res = await _api.dio.post('/chatbot/message', data: {
        'content': message,
        if (sessionId != null) 'conversationId': sessionId,
        if (context != null) 'context': context,
        'clientMessageId': _newClientMessageId(),
      });
      final d = res.data as Map<String, dynamic>?;
      final assistant = d?['assistantMessage'] as Map<String, dynamic>?;
      return assistant?['content'] as String?
          ?? d?['reply'] as String?
          ?? d?['message'] as String?;
    } on DioException catch (e) {
      return quotaRefusalMessage(e.response?.statusCode, e.response?.data);
    } catch (_) {
      return null;
    }
  }

  /// Message à afficher pour un refus de quota WinAI, ou null si l'erreur
  /// n'en est pas un. Public pour être réutilisable par d'autres appels IA.
  static String? quotaRefusalMessage(int? status, Object? body) {
    final map = body is Map ? body : null;
    final serverMessage = map?['message'];
    final msg = serverMessage is String && serverMessage.isNotEmpty
        ? serverMessage
        : null;
    if (status == 402) {
      return msg ??
          'Vous avez atteint votre limite WinAI. Passez à un plan supérieur pour continuer.';
    }
    if (status == 503 && map?['error'] == 'quota_unavailable') {
      return msg ??
          'WinAI est momentanément indisponible. Réessayez dans quelques minutes.';
    }
    return null;
  }

  static final Random _rng = Random.secure();

  /// UUID v4 (RFC 4122), sans dépendance supplémentaire.
  static String _newClientMessageId() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    final hex = List<String>.generate(16, h).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<bool> deleteSession(int sessionId) async {
    try {
      await _api.dio.delete('/chatbot/conversations/$sessionId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ApiWinAIMemory>> getMemories() async {
    try {
      final res = await _api.dio.get('/chatbot/memories');
      final list = res.data as List? ?? [];
      return list
          .map((e) => ApiWinAIMemory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteMemory(int id) async {
    try {
      await _api.dio.delete('/chatbot/memories/$id');
      return true;
    } catch (_) {
      return false;
    }
  }
}
