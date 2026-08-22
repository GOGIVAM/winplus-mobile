import 'api_client.dart';

enum PaymentMethod { mtnMomo, orangeMoney }

class ApiPaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed'
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

class ApiPaymentStatus {
  final String id;
  final String status;
  final String? message;
  const ApiPaymentStatus({
    required this.id,
    required this.status,
    this.message,
  });

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get isFailed => status == 'failed' || status == 'error';

  factory ApiPaymentStatus.fromJson(Map<String, dynamic> j) => ApiPaymentStatus(
        id: j['id'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        message: j['message'] as String?,
      );
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  Future<ApiPaymentIntent?> initiate({
    required int planId,
    required PaymentMethod method,
    required String phoneNumber,
    required bool yearly,
  }) async {
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

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final res = await _api.dio.get('/payments/history');
      final list = res.data as List? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
