import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/mock_data.dart';
import '../../app_config.dart';
import '../../services/subscription_service.dart';

class SubscriptionNotifier extends ChangeNotifier {
  ActiveSubscription _sub = WinData.currentSubscription;

  Future<void> loadFromApi() async {
    final apiSub = await SubscriptionService.instance.getCurrent();
    if (apiSub == null) return;
    final tier = _parseTier(apiSub.tier);
    _sub = ActiveSubscription(
      tier: tier,
      planName: apiSub.planName,
      expiresAt: apiSub.expiresAt.toIso8601String(),
      autoRenew: apiSub.autoRenew,
      downloadsUsed: apiSub.downloadsUsed,
      downloadsLimit: apiSub.downloadsLimit,
      quizUsedToday: apiSub.quizUsedToday,
      quizDailyLimit: apiSub.quizDailyLimit,
      aiMessagesUsed: apiSub.aiMessagesUsed,
      aiMessagesLimit: apiSub.aiMessagesLimit,
    );
    notifyListeners();
  }

  static PlanTier _parseTier(String t) => switch (t) {
        'standard' => PlanTier.standard,
        'premium' => PlanTier.premium,
        'famille' || 'family' => PlanTier.famille,
        _ => PlanTier.libre,
      };

  ActiveSubscription get subscription => _sub;
  PlanTier get tier => _sub.tier;

  // En dev mode, tout est déverrouillé.
  bool get canDownload => AppConfig.devMode ||
      _sub.downloadsLimit == 0 || _sub.downloadsUsed < _sub.downloadsLimit;

  bool get canTakeQuiz => AppConfig.devMode ||
      _sub.quizDailyLimit == 0 || _sub.quizUsedToday < _sub.quizDailyLimit;

  bool get canUseAI => AppConfig.devMode ||
      _sub.aiMessagesLimit == 0 || _sub.aiMessagesUsed < _sub.aiMessagesLimit;

  bool get isPremium => AppConfig.devMode || _sub.isPremium;
  bool get isFree => !AppConfig.devMode && _sub.isFree;

  void setPlan(PlanTier tier) {
    final plan = WinData.pricingPlans.firstWhere((p) => p.tier == tier);
    _sub = ActiveSubscription(
      tier: tier,
      planName: plan.name,
      expiresAt: '21 août 2027',
      autoRenew: true,
      downloadsLimit: plan.downloadLimit ?? 0,
      quizDailyLimit: plan.quizDailyLimit ?? 0,
      aiMessagesLimit: plan.aiMessages ?? 0,
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
      aiMessagesUsed: _sub.aiMessagesUsed,
      aiMessagesLimit: _sub.aiMessagesLimit,
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
      aiMessagesUsed: _sub.aiMessagesUsed,
      aiMessagesLimit: _sub.aiMessagesLimit,
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

  static SubscriptionNotifier of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SubscriptionScope>()!.notifier!;
}
