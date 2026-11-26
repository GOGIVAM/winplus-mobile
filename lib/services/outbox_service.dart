import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_client.dart';
import 'connectivity_service.dart';
import 'http_cache.dart';
import 'secure_hive.dart';

/// Action en attente d'envoi, telle que la montre l'écran « En attente
/// d'envoi ».
class OutboxEntry {
  final String id;
  final String type;

  /// Code du libellé affiché (voir PendingActionsScreen).
  final String label;
  final DateTime createdAt;
  final int attempts;

  /// Abandonnée après trop d'échecs, ou refusée par le serveur : la
  /// personne peut la relancer ou la supprimer.
  final bool failed;
  final String? error;

  const OutboxEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAt,
    required this.attempts,
    required this.failed,
    this.error,
  });
}

/// Résultat d'une écriture passée par [OutboxService.sendOrQueue].
enum SendOutcome { sent, queued }

/// File d'attente des actions faites hors ligne (lot 3).
///
/// Chaque action reçoit une clé unique. Pendant son envoi, le client joint
/// cette clé à ses écritures (en-tête Idempotency-Key) : si la réponse du
/// serveur s'est perdue et que l'action repart, le serveur renvoie la
/// première réponse au lieu de l'exécuter deux fois.
///
/// Une coupure ne compte pas comme un essai : la file s'arrête et repart au
/// retour du réseau. Une erreur du serveur compte : après [maxAttempts]
/// essais, l'action passe en échec. Un refus définitif (4xx) la met en échec
/// tout de suite. Les actions en échec restent visibles, relançables et
/// supprimables.
///
/// Jamais utilisée pour ce qui doit rester en ligne : paiements, crédits,
/// liaison parent-enfant, WinAI, réservations, inscription et connexion.
class OutboxService {
  OutboxService._();
  static final OutboxService instance = OutboxService._();

  static const _boxName = 'outbox';
  static const maxAttempts = 5;

  /// Action générique : une écriture simple (méthode, chemin, données).
  static const httpType = 'http';

  /// Clé de zone portée pendant l'envoi d'une action (lue par ApiClient).
  static const zoneKey = #outboxIdempotencyKey;

  Box? _box;

  final Map<String, Future<bool> Function(Map<String, dynamic> payload)>
      _handlers = {};
  bool _flushing = false;
  StreamSubscription<bool>? _connSub;

  Future<void> init() async {
    _box ??= await SecureHive.open(_boxName);
    _count();
    _registerHttpHandler();
    _connSub ??= ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) flush();
    });
  }

  /// Tests : file en mémoire, vide.
  @visibleForTesting
  Future<void> initForTest() async {
    await _box?.close();
    _box = await Hive.openBox('${_boxName}_test_${_rng.nextInt(1 << 32)}',
        bytes: Uint8List(0));
    _flushing = false;
    _count();
    _registerHttpHandler();
  }

  Box get _b => _box!;

  /// Nombre d'actions en attente (en échec comprises), pour le bandeau des
  /// espaces.
  final ValueNotifier<int> pending = ValueNotifier<int>(0);

  void _count() => pending.value = _box?.length ?? 0;

  static final _rng = Random.secure();

  /// Clé unique d'une action (128 bits, hexadécimal).
  static String newKey() =>
      List.generate(16, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();

  void registerHandler(String type,
      Future<bool> Function(Map<String, dynamic> payload) handler) {
    _handlers[type] = handler;
  }

  void _registerHttpHandler() {
    _handlers[httpType] ??= (payload) async {
      await ApiClient.instance.dio.request(
        payload['path'] as String,
        data: payload['data'],
        options: Options(method: payload['method'] as String),
      );
      return true;
    };
  }

  /// Ajoute une action à la file. [payload] doit être encodable JSON simple
  /// (Map/List/String/num/bool) : c'est ce qui sera rejoué tel quel.
  /// [key] : la clé déjà utilisée pour un premier essai, s'il y en a eu un.
  Future<void> enqueue(String type, Map<String, dynamic> payload,
      {String? key, String? label}) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_b.length}';
    await _b.put(id, {
      'type': type,
      'label': label ?? type,
      'key': key ?? newKey(),
      'payload': payload,
      'attempts': 0,
      'failed': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _count();
  }

  /// Écriture simple, envoyée tout de suite ; sans réponse du serveur
  /// (coupure, délai dépassé), mise en file et renvoyée au retour du réseau,
  /// une seule fois. Un refus du serveur remonte comme avant (DioException).
  Future<SendOutcome> sendOrQueue({
    required String method,
    required String path,
    Object? data,
    required String label,
  }) async {
    final key = newKey();
    final payload = {'method': method, 'path': path, 'data': data};
    if (ConnectivityService.instance.isOnline) {
      try {
        await runWithKey(
            key,
            () => ApiClient.instance.dio
                .request(path, data: data, options: Options(method: method)));
        return SendOutcome.sent;
      } on DioException catch (e) {
        if (!HttpCache.isNetworkFailure(e)) rethrow;
      }
    }
    await enqueue(httpType, payload, key: key, label: label);
    return SendOutcome.queued;
  }

  /// Exécute [body] avec la clé d'idempotence [key] (lue par ApiClient pour
  /// les écritures faites pendant ce temps).
  static Future<T> runWithKey<T>(String key, Future<T> Function() body) =>
      runZoned(body, zoneValues: {zoneKey: key});

  int get pendingCount => _box?.length ?? 0;

  /// Nombre d'actions en attente pour un type donné.
  int pendingCountFor(String type) =>
      _b.values.where((v) => (v as Map)['type'] == type).length;

  /// Actions en attente, de la plus ancienne à la plus récente.
  List<OutboxEntry> get entries {
    if (_box == null) return const [];
    return [
      for (final k in _b.keys)
        if (_b.get(k) case final Map e)
          OutboxEntry(
            id: k.toString(),
            type: e['type'] as String? ?? '',
            label: e['label'] as String? ?? e['type'] as String? ?? '',
            createdAt: DateTime.tryParse(e['createdAt'] as String? ?? '') ??
                DateTime.now(),
            attempts: e['attempts'] as int? ?? 0,
            failed: e['failed'] as bool? ?? false,
            error: e['error'] as String?,
          ),
    ];
  }

  /// Relance une action en échec.
  Future<void> retry(String id) async {
    final e = _b.get(id);
    if (e is! Map) return;
    await _b.put(id, {...Map<String, dynamic>.from(e), 'failed': false, 'attempts': 0, 'error': null});
    await flush();
  }

  /// Abandonne une action.
  Future<void> remove(String id) async {
    await _b.delete(id);
    _count();
  }

  Future<void> _markAttempt(dynamic id, Map entry, String? error,
      {bool definitive = false}) async {
    final attempts = (entry['attempts'] as int? ?? 0) + 1;
    await _b.put(id, {
      ...Map<String, dynamic>.from(entry),
      'attempts': attempts,
      'failed': definitive || attempts >= maxAttempts,
      'error': error,
    });
  }

  /// Rejoue chaque action en attente, dans l'ordre d'ajout.
  Future<void> flush() async {
    if (_flushing || _box == null) return;
    if (!ConnectivityService.instance.isOnline) return;
    _flushing = true;
    try {
      final keys = _b.keys.toList();
      for (final id in keys) {
        final entry = _b.get(id);
        if (entry is! Map) continue;
        if (entry['failed'] == true) continue;
        final type = entry['type'] as String?;
        final payload =
            Map<String, dynamic>.from(entry['payload'] as Map? ?? {});
        final handler = type == null ? null : _handlers[type];

        // Type inconnu (version précédente) : abandonné plutôt que bloquant.
        if (handler == null) {
          await _b.delete(id);
          continue;
        }

        final key = entry['key'] as String? ?? newKey();
        try {
          final ok = await runWithKey(key, () => handler(payload));
          if (ok) {
            await _b.delete(id);
          } else {
            await _markAttempt(id, entry, null);
          }
        } on DioException catch (e) {
          // Coupure : pas un essai ; la file reprendra au retour du réseau.
          if (HttpCache.isNetworkFailure(e)) break;
          final code = e.response?.statusCode ?? 0;
          final refused = code >= 400 && code < 500 && code != 401 && code != 408 && code != 429;
          final data = e.response?.data;
          final message = data is Map ? data['error']?.toString() : null;
          await _markAttempt(id, entry, message, definitive: refused);
        } catch (e) {
          await _markAttempt(id, entry, null);
        }
      }
    } finally {
      _flushing = false;
      _count();
    }
  }
}
