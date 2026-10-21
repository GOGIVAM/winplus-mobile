import 'dart:math';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'connectivity_service.dart';

/// Portefeuille professeur (lot 2, Module 5) : miroir exact des routes
/// serveur utilisées par le web (/api/wallet, /api/withdrawals,
/// /api/payments). Aucune règle de calcul de solde ici : le serveur décide
/// (minimum, solde, statut réel du transfert), le mobile affiche et prévient.

/// Erreur d'appel exploitable par l'écran : message serveur, code HTTP,
/// session expirée ou absence de réseau.
class WalletApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final num? availableXaf;
  const WalletApiException(this.message,
      {this.statusCode, this.code, this.availableXaf});

  bool get sessionExpired => statusCode == 401;
  bool get offline => statusCode == null;
  bool get insufficientBalance => statusCode == 402;

  @override
  String toString() => message;
}

WalletApiException _toWalletError(Object e, String fallback) {
  if (e is WalletApiException) return e;
  if (e is OfflineActionException) return WalletApiException(e.message);
  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;
    String? code;
    num? available;
    if (data is Map) {
      serverMessage = (data['error'] ?? data['message']) as String?;
      code = data['code'] as String?;
      available = data['balanceXaf'] as num?;
    }
    if (status == null) {
      return const WalletApiException(
          'Connexion impossible. Vérifie ton réseau et réessaie.');
    }
    if (status == 401) {
      return const WalletApiException('Ta session a expiré. Reconnecte-toi.',
          statusCode: 401);
    }
    // Refus de la politique « adresse vérifiée » (corps vide côté serveur).
    if (status == 403 && serverMessage == null) {
      return const WalletApiException(
          'Action non autorisée : vérifie ton adresse e-mail pour effectuer un retrait.',
          statusCode: 403);
    }
    return WalletApiException(serverMessage ?? fallback,
        statusCode: status, code: code, availableXaf: available);
  }
  return WalletApiException(fallback);
}

/// Identifiant unique d'une soumission : un rejeu (double appui, réseau
/// coupé puis renvoi) renvoie la même demande côté serveur, sans doublon.
String newClientRequestId() {
  final r = Random.secure();
  final bytes = List<int>.generate(12, (_) => r.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-$hex';
}

int _int(dynamic v) => (v as num?)?.round() ?? 0;

Map<String, dynamic> _unwrap(dynamic body) {
  if (body is Map<String, dynamic>) {
    final d = body['data'];
    if (d is Map<String, dynamic>) return d;
    return body;
  }
  return <String, dynamic>{};
}

class WalletWithdrawal {
  final int id;
  final String status;
  final int amountXaf;
  final String operator;
  final String phoneMasked;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final String? failureReason;
  final bool inProgress;

  const WalletWithdrawal({
    required this.id,
    required this.status,
    required this.amountXaf,
    required this.operator,
    required this.phoneMasked,
    this.requestedAt,
    this.processedAt,
    this.failureReason,
    required this.inProgress,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed' || status == 'cancelled';
  bool get isTerminal => isCompleted || isFailed;
  String get operatorLabel => operator == 'orange' ? 'Orange Money' : 'MTN MoMo';

  factory WalletWithdrawal.fromJson(Map<String, dynamic> j) => WalletWithdrawal(
        id: _int(j['id']),
        status: j['status'] as String? ?? 'pending',
        amountXaf: _int(j['amountXaf'] ?? j['amount']),
        operator: j['operator'] as String? ?? 'mtn',
        phoneMasked: j['phoneMasked'] as String? ?? '',
        requestedAt: DateTime.tryParse(j['requestedAt'] as String? ?? ''),
        processedAt: DateTime.tryParse(j['processedAt'] as String? ?? ''),
        failureReason: j['failureReason'] as String?,
        inProgress: j['inProgress'] as bool? ?? false,
      );
}

class WalletSummary {
  final int availableXaf;
  final int pendingXaf;
  final int engagedXaf;
  final bool isAnomaly;
  final int minWithdrawalXaf;
  final int minRechargeXaf;
  final WalletWithdrawal? activeWithdrawal;

  const WalletSummary({
    required this.availableXaf,
    required this.pendingXaf,
    required this.engagedXaf,
    required this.isAnomaly,
    required this.minWithdrawalXaf,
    required this.minRechargeXaf,
    this.activeWithdrawal,
  });

  bool get isEmpty => availableXaf == 0 && pendingXaf == 0 && engagedXaf == 0;

  factory WalletSummary.fromJson(Map<String, dynamic> j) => WalletSummary(
        availableXaf: _int(j['availableXaf']),
        pendingXaf: _int(j['pendingXaf']),
        engagedXaf: _int(j['engagedXaf']),
        isAnomaly: j['isAnomaly'] as bool? ?? false,
        minWithdrawalXaf: _int(j['minWithdrawalXaf'] ?? 500),
        minRechargeXaf: _int(j['minRechargeXaf'] ?? 100),
        activeWithdrawal: j['activeWithdrawal'] is Map<String, dynamic>
            ? WalletWithdrawal.fromJson(
                j['activeWithdrawal'] as Map<String, dynamic>)
            : null,
      );
}

/// Sources filtrables de l'historique, identiques au web et au serveur.
const walletSources = <(String, String)>[
  ('all', 'Tout'),
  ('catalogue', 'Ventes'),
  ('cours_particulier', 'Cours particuliers'),
  ('affiliation', 'Affiliation'),
  ('recharge', 'Recharges'),
  ('credit_admin', 'Crédits admin'),
  ('achat', 'Achats'),
  ('retrait', 'Retraits'),
];

class WalletEntry {
  final int id;
  final DateTime? date;
  final String source;
  final String label;
  final int amountXaf;
  final String status; // completed | pending | reversed

  const WalletEntry({
    required this.id,
    this.date,
    required this.source,
    required this.label,
    required this.amountXaf,
    required this.status,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> j) => WalletEntry(
        id: _int(j['id']),
        date: DateTime.tryParse(j['date'] as String? ?? ''),
        source: j['source'] as String? ?? 'autre',
        label: j['label'] as String? ?? '',
        amountXaf: _int(j['amountXaf']),
        status: j['status'] as String? ?? 'completed',
      );
}

class WalletEntriesPage {
  final List<WalletEntry> items;
  final int total;
  const WalletEntriesPage(this.items, this.total);
}

class WalletRechargeStart {
  final int paymentId;
  final int amountXaf;
  const WalletRechargeStart(this.paymentId, this.amountXaf);
}

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  final _api = ApiClient.instance;

  Future<WalletSummary> getSummary() async {
    try {
      final res = await _api.dio.get('/wallet/me');
      return WalletSummary.fromJson(_unwrap(res.data));
    } catch (e) {
      throw _toWalletError(e, 'Impossible de charger ton solde.');
    }
  }

  Future<WalletEntriesPage> getEntries(
      {String source = 'all', int page = 1, int pageSize = 20}) async {
    try {
      final res = await _api.dio.get('/wallet/me/entries',
          queryParameters: {'source': source, 'page': page, 'pageSize': pageSize});
      final d = _unwrap(res.data);
      final items = (d['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WalletEntry.fromJson)
          .toList();
      return WalletEntriesPage(items, _int(d['total']));
    } catch (e) {
      throw _toWalletError(e, 'Impossible de charger l\'historique.');
    }
  }

  Future<WalletWithdrawal?> getActiveWithdrawal() async {
    try {
      final res = await _api.dio.get('/withdrawals/active');
      final body = res.data;
      final d = body is Map<String, dynamic> ? body['data'] : null;
      return d is Map<String, dynamic> ? WalletWithdrawal.fromJson(d) : null;
    } catch (e) {
      throw _toWalletError(e, 'Impossible de vérifier le retrait en cours.');
    }
  }

  /// Statut réel du retrait (le serveur le relit chez NotchPay s'il est en cours).
  Future<WalletWithdrawal> getWithdrawal(int id) async {
    try {
      final res = await _api.dio.get('/withdrawals/status/$id');
      return WalletWithdrawal.fromJson(_unwrap(res.data));
    } catch (e) {
      throw _toWalletError(e, 'Impossible de lire le statut du retrait.');
    }
  }

  /// Demande de retrait. Jamais mise en file hors ligne : échec explicite.
  Future<WalletWithdrawal> requestWithdrawal({
    required String operator,
    required String phone,
    required int amountXaf,
    required String clientRequestId,
  }) async {
    try {
      requireOnline();
      final res = await _api.dio.post('/withdrawals', data: {
        'operator': operator,
        'phone': phone,
        'amount': amountXaf,
        'clientRequestId': clientRequestId,
      });
      return WalletWithdrawal.fromJson(_unwrap(res.data));
    } catch (e) {
      throw _toWalletError(e, 'Le retrait n\'a pas pu être enregistré.');
    }
  }

  /// Recharge Mobile Money par le parcours d'encaissement existant.
  Future<WalletRechargeStart> startRecharge({
    required String operator,
    required String phone,
    required int amountXaf,
    required String clientRequestId,
  }) async {
    try {
      requireOnline();
      final res = await _api.dio.post('/wallet/recharge', data: {
        'amount': amountXaf,
        'operator': operator,
        'phone': phone,
        'clientRequestId': clientRequestId,
      });
      final d = _unwrap(res.data);
      return WalletRechargeStart(_int(d['paymentId']), _int(d['amountXaf']));
    } catch (e) {
      throw _toWalletError(e, 'La recharge n\'a pas pu être lancée.');
    }
  }

  /// Statut d'un paiement (recharge) : pending | completed | failed | expired | cancelled.
  Future<(String status, String? message)> getPaymentStatus(int paymentId) async {
    try {
      final res = await _api.dio.get('/payments/$paymentId/status');
      final j = res.data as Map<String, dynamic>? ?? {};
      return (
        (j['status'] as String? ?? 'pending').toLowerCase(),
        j['errorMessage'] as String?,
      );
    } catch (e) {
      throw _toWalletError(e, 'Impossible de lire le statut du paiement.');
    }
  }
}
