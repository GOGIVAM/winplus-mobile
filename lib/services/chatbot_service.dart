import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'connectivity_service.dart';
import '../l10n/l10n.dart';

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
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
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
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
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
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        lastMessage: j['lastMessage'] as String?,
      );
}

class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();

  final _api = ApiClient.instance;

  /// Lot 9.7b (18.21) : mode « base de connaissance » du chat, désactivé
  /// par défaut, partagé par tous les écrans de chat et envoyé avec chaque
  /// message (`knowledgeBase`). Activé, la recherche dans les cours et les
  /// fichiers de l'utilisateur est faite et son coût décompté.
  final ValueNotifier<bool> knowledgeBase = ValueNotifier<bool>(false);

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
  ///  - 402 (Partie 8.10) : message serveur limite de session (5 h) ou
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
      return OfflineActionException().message;
    }
    try {
      final res = await _api.dio.post('/chatbot/message', data: {
        'content': message,
        if (sessionId != null) 'conversationId': sessionId,
        if (context != null) 'context': context,
        'clientMessageId': _newClientMessageId(),
        'knowledgeBase': knowledgeBase.value,
      });
      final d = res.data as Map<String, dynamic>?;
      final assistant = d?['assistantMessage'] as Map<String, dynamic>?;
      return assistant?['content'] as String? ??
          d?['reply'] as String? ??
          d?['message'] as String?;
    } on DioException catch (e) {
      return quotaRefusalMessage(e.response?.statusCode, e.response?.data);
    } catch (_) {
      return null;
    }
  }

  /// Réponse WinAI écrite en direct (POST /chatbot/stream, comme le site).
  /// [onText] reçoit le texte complet de la réponse à chaque fragment reçu.
  /// Renvoie le texte final, un message de refus (hors ligne, quota), ou
  /// null. Sans fragment dans les 15 premières secondes, ou si le flux casse
  /// avant le premier, la réponse passe par la route classique (comme le
  /// site), en une fois.
  Future<String?> streamMessage({
    required String message,
    int? conversationId,
    required void Function(String text) onText,
    void Function(int conversationId)? onConversation,
  }) async {
    if (!ConnectivityService.instance.isOnline) {
      return OfflineActionException().message;
    }
    final clientMessageId = _newClientMessageId();
    final full = StringBuffer();
    var gotToken = false;
    Future<String?> fallback() => sendMessage(message: message, sessionId: conversationId);
    try {
      final res = await _api.dio.post<ResponseBody>(
        '/chatbot/stream',
        data: {
          'message': message,
          if (conversationId != null) 'conversationId': conversationId,
          'forceLanguage': L10n.isEn ? 'english' : 'french',
          'clientMessageId': clientMessageId,
          'knowledgeBase': knowledgeBase.value,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      final body = res.data;
      if (body == null) return fallback();
      final lines = utf8.decoder
          .bind(body.stream)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 15), onTimeout: (sink) {
        // Rien depuis 15 s : avant le premier fragment, on abandonne le flux.
        if (!gotToken) sink.close();
      });
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final chunk = line.substring(5).trim();
        if (chunk == '[DONE]') break;
        var token = chunk;
        try {
          final parsed = jsonDecode(chunk);
          if (parsed is Map) {
            final id = parsed['conversationId'];
            if (id is num) onConversation?.call(id.toInt());
            if (parsed['error'] != null && !gotToken) return fallback();
            token = (parsed['delta'] ?? parsed['content'] ?? parsed['token'] ?? '')
                .toString();
          }
        } catch (_) {
          // Fragment en texte brut.
        }
        if (token.isEmpty) continue;
        gotToken = true;
        full.write(token);
        onText(full.toString());
      }
      if (!gotToken) return fallback();
      return full.toString();
    } on DioException catch (e) {
      // Refus avant le flux : corps JSON à lire depuis le flux de réponse.
      final status = e.response?.statusCode;
      Object? data = e.response?.data;
      if (data is ResponseBody) {
        try {
          data = jsonDecode(await utf8.decoder.bind(data.stream).join());
        } catch (_) {
          data = null;
        }
      }
      final refusal = quotaRefusalMessage(status, data) ??
          (status == 403 && data is Map ? data['message'] as String? : null);
      if (refusal != null) return refusal;
      if (gotToken) return full.toString();
      return fallback();
    } catch (_) {
      if (gotToken) return full.toString();
      return fallback();
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
      return msg ?? L10n.current.svcWinaiLimit;
    }
    if (status == 503 && map?['error'] == 'quota_unavailable') {
      return msg ?? L10n.current.svcWinaiUnavailable;
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

  /// Lève une erreur si le serveur ne répond pas (la feuille des mémoires
  /// affiche alors son message d'erreur, pas « aucune mémoire »).
  Future<List<ApiWinAIMemory>> getMemories() async {
    final res = await _api.dio.get('/chatbot/memories');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiWinAIMemory.fromJson(e as Map<String, dynamic>))
        .toList();
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
