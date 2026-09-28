import 'package:dio/dio.dart';
import 'api_client.dart';

/// Article du panier serveur (GET /api/cart). Le prix vient du serveur, pas
/// du client (Module 17 : tout prix envoyé par le client est ignoré côté
/// backend, seul celui stocké au panier compte).
class ApiCartItem {
  final int id, subjectId;
  final String title;
  final String? description, image;
  final double price;
  final DateTime addedAt;
  const ApiCartItem({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.image,
    required this.price,
    required this.addedAt,
  });

  factory ApiCartItem.fromJson(Map<String, dynamic> j) => ApiCartItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        subjectId: (j['subjectId'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        image: j['image'] as String?,
        price: ((j['price'] ?? 0) as num).toDouble(),
        addedAt:
            DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Panier complet, TVA incluse côté serveur (19,25 %  voir CartController).
class ApiCart {
  final List<ApiCartItem> items;
  final int itemsCount;
  final double subtotal, discount, tax, total;
  final String currency;
  const ApiCart({
    required this.items,
    required this.itemsCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.currency,
  });

  static const empty = ApiCart(
      items: [],
      itemsCount: 0,
      subtotal: 0,
      discount: 0,
      tax: 0,
      total: 0,
      currency: 'XAF');

  factory ApiCart.fromJson(Map<String, dynamic> j) => ApiCart(
        items: ((j['items'] as List?) ?? [])
            .map((e) => ApiCartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        itemsCount: (j['itemsCount'] as num?)?.toInt() ?? 0,
        subtotal: ((j['subtotal'] ?? 0) as num).toDouble(),
        discount: ((j['discount'] ?? 0) as num).toDouble(),
        tax: ((j['tax'] ?? 0) as num).toDouble(),
        total: ((j['total'] ?? 0) as num).toDouble(),
        currency: j['currency'] as String? ?? 'XAF',
      );
}

class ApiPromoResult {
  final bool success;
  final String? error;
  final double discount, finalAmount;
  const ApiPromoResult(
      {required this.success,
      this.error,
      this.discount = 0,
      this.finalAmount = 0});
}

/// Panier serveur (Module 17 / décision 9.2 : compte obligatoire pour
/// acheter, donc toujours appelé authentifié  jamais de deviceId côté
/// mobile, contrairement au panier anonyme web).
class CartService {
  CartService._();
  static final CartService instance = CartService._();

  final _api = ApiClient.instance;

  Future<ApiCart> getCart() async {
    try {
      final res = await _api.dio.get('/cart');
      return ApiCart.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return ApiCart.empty;
    }
  }

  Future<ApiCart?> addItem(int subjectId) async {
    try {
      final res =
          await _api.dio.post('/cart/items', data: {'subjectId': subjectId});
      return ApiCart.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeItem(int cartItemId) async {
    try {
      await _api.dio.delete('/cart/items/$cartItemId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _api.dio.delete('/cart');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ApiPromoResult> applyPromo(String code) async {
    try {
      final res = await _api.dio.post('/cart/promo', data: {'code': code});
      final data = res.data as Map<String, dynamic>;
      return ApiPromoResult(
        success: data['success'] as bool? ?? false,
        discount: ((data['discount'] ?? 0) as num).toDouble(),
        finalAmount: ((data['finalAmount'] ?? 0) as num).toDouble(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['error'] as String? : null;
      return ApiPromoResult(
          success: false, error: msg ?? 'Code promo invalide.');
    }
  }

  Future<void> removePromo() async {
    try {
      await _api.dio.delete('/cart/promo');
    } catch (_) {}
  }
}
