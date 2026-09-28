import 'package:dio/dio.dart';
import 'api_client.dart';
import 'connectivity_service.dart';

enum PaymentMethod { mtnMomo, orangeMoney }

/// Réponse d'initiation NotchPay pour l'achat d'une commande catalogue
/// (POST /api/payments/initiate  InitiatePaymentRequest/Response).
class ApiOrderPaymentIntent {
  final int paymentId;
  final String? notchpayReference;
  final String status;
  final String? authorizationUrl;
  final double amount;
  final String currency;
  const ApiOrderPaymentIntent({
    required this.paymentId,
    this.notchpayReference,
    required this.status,
    this.authorizationUrl,
    required this.amount,
    required this.currency,
  });

  factory ApiOrderPaymentIntent.fromJson(Map<String, dynamic> j) =>
      ApiOrderPaymentIntent(
        paymentId: (j['paymentId'] as num?)?.toInt() ?? 0,
        notchpayReference: j['notchpayReference'] as String?,
        status: j['status'] as String? ?? 'pending',
        authorizationUrl: j['authorizationUrl'] as String?,
        amount: ((j['amount'] ?? 0) as num).toDouble(),
        currency: j['currency'] as String? ?? 'XAF',
      );
}

class OrderPaymentException implements Exception {
  final String message;
  const OrderPaymentException(this.message);
}

class ApiPaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String? paymentUrl;
  final String? ussdCode;
  const ApiPaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentUrl,
    this.ussdCode,
  });

  factory ApiPaymentIntent.fromJson(Map<String, dynamic> j) => ApiPaymentIntent(
        id: j['id'] as String? ?? '',
        amount: ((j['amount'] ?? 0) as num).toDouble(),
        currency: j['currency'] as String? ?? 'XAF',
        status: j['status'] as String? ?? 'pending',
        paymentUrl: j['paymentUrl'] as String?,
        ussdCode: j['ussdCode'] as String?,
      );
}

/// Miroir de PaymentStatusResponse (backend)  Id est un int côté serveur,
/// jamais une chaîne, et le message d'erreur est porté par "errorMessage",
/// pas "message" (l'ancien code lisait les deux mauvais champs, ce qui
/// levait une exception de cast et masquait silencieusement l'échec).
class ApiPaymentStatus {
  final String id;
  final String status;
  final String? message;
  const ApiPaymentStatus({
    required this.id,
    required this.status,
    this.message,
  });

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'success';
  bool get isFailed =>
      status.toLowerCase() == 'failed' || status.toLowerCase() == 'error';

  factory ApiPaymentStatus.fromJson(Map<String, dynamic> j) => ApiPaymentStatus(
        id: (j['id'] ?? '').toString(),
        status: j['status'] as String? ?? 'pending',
        message: j['errorMessage'] as String? ?? j['message'] as String?,
      );
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  /// Les paiements ne sont jamais mis en file hors ligne : throw explicite
  /// plutôt qu'un échec silencieux (voir requireOnline).
  Future<ApiPaymentIntent?> initiate({
    required int planId,
    required PaymentMethod method,
    required String phoneNumber,
    required bool yearly,
  }) async {
    requireOnline();
    try {
      final res = await _api.dio.post('/payments/initiate', data: {
        'planId': planId,
        'method': method == PaymentMethod.mtnMomo ? 'mtn_momo' : 'orange_money',
        'phoneNumber': phoneNumber,
        'billing': yearly ? 'yearly' : 'monthly',
      });
      return ApiPaymentIntent.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ApiPaymentStatus?> checkStatus(String paymentId) async {
    try {
      final res = await _api.dio.get('/payments/$paymentId/status');
      return ApiPaymentStatus.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Initie le paiement Mobile Money d'une commande catalogue (panier). Le
  /// montant est celui de la commande créée côté serveur (Order.TotalAmount),
  /// pas une valeur recalculée côté client.
  Future<ApiOrderPaymentIntent> initiateForOrder({
    required int orderId,
    required String phone,
    required double amount,
    String? email,
  }) async {
    requireOnline();
    try {
      final res = await _api.dio.post('/payments/initiate', data: {
        'orderId': orderId,
        'phone': phone,
        'amount': amount,
        if (email != null) 'email': email,
      });
      return ApiOrderPaymentIntent.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          data is Map ? (data['message'] ?? data['error']) as String? : null;
      throw OrderPaymentException(msg ?? 'Impossible d\'initier le paiement.');
    }
  }

  /// La réponse réelle est { payments: [...], total, page, limit }, jamais un
  /// tableau nu  "res.data as List?" levait une exception à chaque appel
  /// (Map n'est pas List), silencieusement avalée par le catch, donc
  /// l'historique de paiement était toujours vide en pratique.
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final res = await _api.dio.get('/payments/history');
      final data = res.data;
      final list = data is Map ? data['payments'] as List? : data as List?;
      return (list ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
