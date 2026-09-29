import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../services/subscription_service.dart';

class SubscriptionNotifier extends ChangeNotifier {
  ActiveSubscription _sub = const ActiveSubscription(
    tier: PlanTier.libre,
    planName: 'Libre',
    expiresAt: '',
    autoRenew: false,
  );

  Future<void> loadFromApi() async {
    final apiSub = await SubscriptionService.instance.getCurrent();
    if (apiSub == null) return;
    _sub = ActiveSubscription(
      tier: _parseTier(apiSub.tier),
      planName: apiSub.planName,
      expiresAt: apiSub.expiresAt.toIso8601String(),
      autoRenew: apiSub.autoRenew,
      downloadsUsed: apiSub.downloadsUsed,
      downloadsLimit: apiSub.downloadsLimit,
      quizUsedToday: apiSub.quizUsedToday,
      quizDailyLimit: apiSub.quizDailyLimit,
      aiUsageMultiplier: apiSub.aiUsageMultiplier,
      aiQuotaExhausted: apiSub.aiQuotaExhausted,
    );
    notifyListeners();
  }

  static PlanTier _parseTier(String t) => switch (t) {
        'standard' => PlanTier.standard,
        'premium' => PlanTier.premium,
        'famille' || 'family' || 'family_plus' => PlanTier.famille,
        _ => PlanTier.libre,
      };

  ActiveSubscription get subscription => _sub;
  PlanTier get tier => _sub.tier;

  bool get canDownload =>
      _sub.downloadsLimit == 0 || _sub.downloadsUsed < _sub.downloadsLimit;

  bool get canTakeQuiz =>
      _sub.quizDailyLimit == 0 || _sub.quizUsedToday < _sub.quizDailyLimit;

  /// Indicatif seulement : le serveur reste seul juge (402 à l'épuisement).
  bool get canUseAI => !_sub.aiQuotaExhausted;

  bool get isPremium => _sub.isPremium;
  bool get isFree => _sub.isFree;

  void setPlan(PlanTier tier) {
    _sub = ActiveSubscription(
      tier: tier,
      planName: tier.name,
      expiresAt: '',
      autoRenew: true,
    );
    notifyListeners();
  }

  void recordDownload() {
    _sub = ActiveSubscription(
      tier: _sub.tier,
      planName: _sub.planName,
      expiresAt: _sub.expiresAt,
      autoRenew: _sub.autoRenew,
      downloadsUsed: _sub.downloadsUsed + 1,
      downloadsLimit: _sub.downloadsLimit,
      quizUsedToday: _sub.quizUsedToday,
      quizDailyLimit: _sub.quizDailyLimit,
      aiUsageMultiplier: _sub.aiUsageMultiplier,
      aiQuotaExhausted: _sub.aiQuotaExhausted,
    );
    notifyListeners();
  }

  void recordQuiz() {
    _sub = ActiveSubscription(
      tier: _sub.tier,
      planName: _sub.planName,
      expiresAt: _sub.expiresAt,
      autoRenew: _sub.autoRenew,
      downloadsUsed: _sub.downloadsUsed,
      downloadsLimit: _sub.downloadsLimit,
      quizUsedToday: _sub.quizUsedToday + 1,
      quizDailyLimit: _sub.quizDailyLimit,
      aiUsageMultiplier: _sub.aiUsageMultiplier,
      aiQuotaExhausted: _sub.aiQuotaExhausted,
    );
    notifyListeners();
  }
}

class SubscriptionScope extends InheritedNotifier<SubscriptionNotifier> {
  const SubscriptionScope({
    super.key,
    required SubscriptionNotifier super.notifier,
    required super.child,
  });

  static SubscriptionNotifier of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SubscriptionScope>()!
      .notifier!;
}
