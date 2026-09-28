import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiOrderItem {
  final int subjectId;
  final String? title;
  final double price;
  const ApiOrderItem(
      {required this.subjectId, this.title, required this.price});

  factory ApiOrderItem.fromJson(Map<String, dynamic> j) => ApiOrderItem(
        subjectId: (j['subjectId'] as num?)?.toInt() ?? 0,
        title: j['subject'] is Map
            ? (j['subject'] as Map)['title'] as String?
            : null,
        price: ((j['priceAtPurchase'] ?? 0) as num).toDouble(),
      );
}

/// Commande (GET/POST /api/orders  OrdersController). Status brut serveur :
/// "Pending", "Completed", "Failed", "Refunded", "cancelled", "refund_requested"...
class ApiOrder {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final List<ApiOrderItem> items;
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.items = const [],
  });

  factory ApiOrder.fromJson(Map<String, dynamic> j) => ApiOrder(
        id: (j['id'] as num?)?.toInt() ?? 0,
        orderNumber: j['orderNumber'] as String? ?? '',
        totalAmount: ((j['totalAmount'] ?? 0) as num).toDouble(),
        status: j['status'] as String? ?? 'Pending',
        paymentMethod: j['paymentMethod'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        items: ((j['items'] as List?) ?? [])
            .map((e) => ApiOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isRefundRequested => status.toLowerCase() == 'refund_requested';
}

class OrderCreateException implements Exception {
  final String message;
  const OrderCreateException(this.message);
}

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final _api = ApiClient.instance;

  /// Crée la commande à partir du panier serveur de l'utilisateur connecté.
  /// [paymentMethod] est indicatif ("mobile_money") : le paiement réel est
  /// initié séparément via PaymentService.initiateForOrder.
  Future<ApiOrder> createOrder({String paymentMethod = 'mobile_money'}) async {
    try {
      final res = await _api.dio
          .post('/orders', data: {'paymentMethod': paymentMethod});
      return ApiOrder.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['error'] as String? : null;
      throw OrderCreateException(msg ?? 'Impossible de créer la commande.');
    }
  }

  Future<List<ApiOrder>> getOrders({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _api.dio.get('/orders',
          queryParameters: {'page': page, 'pageSize': pageSize});
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];
      return items
          .map((e) => ApiOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ApiOrder?> getOrderById(int id) async {
    try {
      final res = await _api.dio.get('/orders/$id');
      return ApiOrder.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getOrderStatus(int id) async {
    try {
      final res = await _api.dio.get('/orders/$id/status');
      final data = res.data as Map<String, dynamic>;
      final inner = data['data'] as Map<String, dynamic>?;
      return inner?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelOrder(int id) async {
    try {
      await _api.dio.post('/orders/$id/cancel');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestRefund(int id) async {
    try {
      await _api.dio.post('/orders/$id/refund');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Facture PDF brute (bytes)  affichée dans une visionneuse intégrée,
  /// jamais écrite sur le disque (même politique que les documents du
  /// catalogue, voir document_viewer_screen.dart).
  Future<List<int>?> getInvoiceBytes(int id) async {
    try {
      final res = await _api.dio.get<List<int>>(
        '/orders/$id/invoice',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }
}
