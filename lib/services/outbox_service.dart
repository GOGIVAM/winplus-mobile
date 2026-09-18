import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'connectivity_service.dart';

/// File d'attente pour les actions réalisées hors ligne : réponses de quiz et
/// messages DirectMessage envoyés sans réseau (voir la liste "toujours en
/// ligne" ci-dessous  jamais utilisée pour paiements, crédits, liaison
/// parent-enfant, génération IA ou demandes d'accès enseignant, qui doivent
/// échouer explicitement hors ligne plutôt que d'être mises en file).
///
/// Chaque service concerné (QuizService, MessagingService) s'enregistre une
/// fois via [registerHandler] avec le type d'action qu'il sait rejouer,
/// plutôt que d'être connu ici en dur  évite un import circulaire et garde
/// l'outbox agnostique du contenu qu'elle transporte.
class OutboxService {
  OutboxService._();
  static final OutboxService instance = OutboxService._();

  static const _boxName = 'outbox';
  Box? _box;

  final Map<String, Future<bool> Function(Map<String, dynamic> payload)>
      _handlers = {};
  bool _flushing = false;
  StreamSubscription<bool>? _connSub;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
    _connSub ??= ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) flush();
    });
  }

  Box get _b => _box!;

  void registerHandler(String type,
      Future<bool> Function(Map<String, dynamic> payload) handler) {
    _handlers[type] = handler;
  }

  /// Ajoute une action à la file. [payload] doit être encodable JSON simple
  /// (Map/List/String/num/bool) : c'est ce qui sera rejoué tel quel lors du
  /// [flush].
  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_b.length}';
    await _b.put(id, {
      'type': type,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  int get pendingCount => _b.length;

  /// Nombre d'actions en attente pour un type donné (ex. affichage "3 messages
  /// en attente d'envoi" dans un écran spécifique).
  int pendingCountFor(String type) =>
      _b.values.where((v) => (v as Map)['type'] == type).length;

  /// Rejoue chaque action en attente, dans l'ordre d'ajout. Une action dont
  /// le handler échoue reste en file (nouvelle tentative au prochain flush) ;
  /// une action dont le type n'a pas (ou plus) de handler enregistré est
  /// abandonnée plutôt que de bloquer la file indéfiniment.
  Future<void> flush() async {
    if (_flushing || _box == null) return;
    if (!ConnectivityService.instance.isOnline) return;
    _flushing = true;
    try {
      final keys = _b.keys.toList();
      for (final key in keys) {
        final entry = _b.get(key);
        if (entry is! Map) continue;
        final type = entry['type'] as String?;
        final payload =
            Map<String, dynamic>.from(entry['payload'] as Map? ?? {});
        final handler = type == null ? null : _handlers[type];

        if (handler == null) {
          await _b.delete(key);
          continue;
        }

        try {
          final ok = await handler(payload);
          if (ok) await _b.delete(key);
        } catch (_) {
          // Réseau probablement reperdu en cours de vidage : on arrête ce
          // passage, l'action reste en file pour le prochain retour en ligne.
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }
}
