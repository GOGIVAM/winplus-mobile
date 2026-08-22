import 'api_client.dart';
import 'payment_service.dart';

class ApiGuestOrderResult {
  final String orderId;
  final String? ussdCode;
  final String message;
  const ApiGuestOrderResult({
    required this.orderId,
    this.ussdCode,
    required this.message,
  });
}

class GuestOrderService {
  GuestOrderService._();
  static final GuestOrderService instance = GuestOrderService._();

  final _api = ApiClient.instance;

  Future<ApiGuestOrderResult?> placeOrder({
    required int subjectId,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required PaymentMethod method,
  }) async {
    try {
      final res = await _api.dio.post('/orders/guest', data: {
        'subjectId': subjectId,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'paymentMethod': method == PaymentMethod.mtnMomo ? 'mtn_momo' : 'orange_money',
      });
      final d = res.data as Map<String, dynamic>;
      return ApiGuestOrderResult(
        orderId: d['orderId']?.toString() ?? '',
        ussdCode: d['ussdCode'] as String?,
        message: d['message'] as String? ?? 'Commande initiée.',
      );
    } catch (_) {
      return null;
    }
  }
}
