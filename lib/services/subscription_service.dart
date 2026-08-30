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
  final String planName;
  final String tier;
  final String status;
  final DateTime expiresAt;
  final bool autoRenew;
  final int downloadsUsed;
  final int downloadsLimit;
  final int quizUsedToday;
  final int quizDailyLimit;
  final int aiMessagesUsed;
  final int aiMessagesLimit;
  const ApiActiveSubscription({
    required this.id,
    required this.planName,
    required this.tier,
    required this.status,
    required this.expiresAt,
    required this.autoRenew,
    this.downloadsUsed = 0,
    this.downloadsLimit = 0,
    this.quizUsedToday = 0,
    this.quizDailyLimit = 0,
    this.aiMessagesUsed = 0,
    this.aiMessagesLimit = 0,
  });

  bool get isFree => tier == 'free' || tier == 'libre';
  bool get isActive => status == 'active';

  factory ApiActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ApiActiveSubscription(
        id: j['id'] as int? ?? 0,
        planName: j['planName'] as String? ?? '',
        tier: j['tier'] as String? ?? 'free',
        status: j['status'] as String? ?? 'active',
        expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
        autoRenew: j['autoRenew'] as bool? ?? false,
        downloadsUsed: j['downloadsUsed'] as int? ?? 0,
        downloadsLimit: j['downloadsLimit'] as int? ?? 0,
        quizUsedToday: j['quizUsedToday'] as int? ?? 0,
        quizDailyLimit: j['quizDailyLimit'] as int? ?? 0,
        aiMessagesUsed: j['aiMessagesUsed'] as int? ?? 0,
        aiMessagesLimit: j['aiMessagesLimit'] as int? ?? 0,
      );
}

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final _api = ApiClient.instance;

  Future<List<ApiPlan>> getPlans(String category) async {
    final res = await _api.dio.get('/pricing/plans',
        queryParameters: {'category': category});
    final list = res.data as List? ?? [];
    return list.map((e) => ApiPlan.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<bool> cancel() async {
    try {
      await _api.dio.post('/subscriptions/me/cancel');
      return true;
    } catch (_) {
      return false;
    }
  }
}
