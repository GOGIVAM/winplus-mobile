import 'api_client.dart';

class ApiPlan {
  final int id;
  final String name;
  final String tier;
  final String category;
  final double priceMonthly;
  final double priceYearly;
  final List<String> features;
  final bool isPopular;
  const ApiPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.category,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
    this.isPopular = false,
  });

  factory ApiPlan.fromJson(Map<String, dynamic> j) => ApiPlan(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        tier: j['tier'] as String? ?? '',
        category: j['category'] as String? ?? 'student',
        priceMonthly: ((j['priceMonthly'] ?? 0) as num).toDouble(),
        priceYearly: ((j['priceYearly'] ?? 0) as num).toDouble(),
        features: (j['features'] as List? ?? []).cast<String>(),
        isPopular: j['isPopular'] as bool? ?? false,
      );
}

class ApiActiveSubscription {
  final int id;

  /// Id du PricingPlan (distinct de [id], celui de la Subscription elle-même)
  ///  c'est celui-ci qu'il faut envoyer pour se réabonner/renouveler via
  /// SubscriptionService.purchase.
  final int pricingPlanId;
  final String planName;
  final String tier;
  final String status;
  final DateTime expiresAt;
  final bool autoRenew;
  final double price;
  final int downloadsUsed;
  final int downloadsLimit;
  final int quizUsedToday;
  final int quizDailyLimit;

  /// Partie 8.3 : usage WinAI relatif au plan gratuit (1 = gratuit), jamais
  /// un compteur brut. Remplace aiMessagesUsed/aiMessagesLimit, retirés de
  /// GET /api/subscriptions/me (le quota est désormais en tokens réels).
  final int aiUsageMultiplier;
  final String aiUsageLabel;
  final bool aiQuotaExhausted;

  /// Partie 8.10 : limite atteinte 'session' (5 h glissantes), 'week'
  /// (7 jours glissants) ou null. Plus de plafond mensuel.
  final String? aiLimitReached;

  /// Heure (UTC) à laquelle l'utilisateur pourra de nouveau écrire ; null si
  /// aucune limite n'est atteinte.
  final DateTime? aiLimitResetsAt;

  /// Message serveur prêt à afficher (sans nombre de tokens) ; null sinon.
  final String? aiLimitMessage;
  const ApiActiveSubscription({
    required this.id,
    required this.pricingPlanId,
    required this.planName,
    required this.tier,
    required this.status,
    required this.expiresAt,
    required this.autoRenew,
    this.price = 0,
    this.downloadsUsed = 0,
    this.downloadsLimit = 0,
    this.quizUsedToday = 0,
    this.quizDailyLimit = 0,
    this.aiUsageMultiplier = 1,
    this.aiUsageLabel = '',
    this.aiQuotaExhausted = false,
    this.aiLimitReached,
    this.aiLimitResetsAt,
    this.aiLimitMessage,
  });

  bool get isFree => tier == 'free' || tier == 'libre';
  bool get isActive => status == 'active';

  factory ApiActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ApiActiveSubscription(
        id: j['id'] as int? ?? 0,
        pricingPlanId: j['pricingPlanId'] as int? ?? 0,
        planName: j['planName'] as String? ?? '',
        tier: j['tier'] as String? ?? 'free',
        status: j['status'] as String? ?? 'active',
        expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
        autoRenew: j['autoRenew'] as bool? ?? false,
        price: ((j['price'] ?? 0) as num).toDouble(),
        downloadsUsed: j['downloadsUsed'] as int? ?? 0,
        downloadsLimit: j['downloadsLimit'] as int? ?? 0,
        quizUsedToday: j['quizUsedToday'] as int? ?? 0,
        quizDailyLimit: j['quizDailyLimit'] as int? ?? 0,
        aiUsageMultiplier: (j['aiUsageMultiplier'] as num?)?.toInt() ?? 1,
        aiUsageLabel: j['aiUsageLabel'] as String? ?? '',
        aiQuotaExhausted: j['aiQuotaExhausted'] as bool? ?? false,
        aiLimitReached: j['aiLimitReached'] as String?,
        aiLimitResetsAt:
            DateTime.tryParse(j['aiLimitResetsAt'] as String? ?? ''),
        aiLimitMessage: j['aiLimitMessage'] as String?,
      );
}

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final _api = ApiClient.instance;

  Future<List<ApiPlan>> getPlans(String category) async {
    final res = await _api.dio
        .get('/pricing/plans', queryParameters: {'category': category});
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiActiveSubscription?> getCurrent() async {
    try {
      final res = await _api.dio.get('/subscriptions/me');
      return ApiActiveSubscription.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> subscribe(int planId, {bool yearly = false}) async {
    try {
      await _api.dio.post('/subscriptions', data: {
        'planId': planId,
        'billing': yearly ? 'yearly' : 'monthly',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Souscrit/renouvelle avec paiement Mobile Money (POST /subscriptions/purchase,
  /// crée l'Order ET initie le paiement NotchPay en un seul appel). Remplace
  /// l'ancien usage de PaymentService.initiate() pour ce cas : ce dernier
  /// attend un OrderId déjà existant (Order/{id}), pas un planId  aucun des
  /// deux DTOs ne correspondait au corps réellement envoyé, donc l'ancien
  /// appel échouait systématiquement (validation 400 côté backend).
  Future<int?> purchase({
    required int planId,
    required String phone,
    bool yearly = false,
  }) async {
    final res = await _api.dio.post('/subscriptions/purchase', data: {
      'planId': planId,
      'phone': phone,
      'billing': yearly ? 'yearly' : 'monthly',
    });
    final d = res.data as Map<String, dynamic>?;
    return d?['paymentId'] as int?;
  }

  Future<bool> cancel() async {
    try {
      await _api.dio.post('/subscriptions/me/cancel');
      return true;
    } catch (_) {
      return false;
    }
  }
}
