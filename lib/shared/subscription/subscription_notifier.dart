import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/subscription_service.dart';

/// Lot 9.7b : état d'abonnement de l'application, fondé sur les DROITS
/// effectifs renvoyés par le serveur (GET /api/subscriptions/me, champ
/// entitlements). Plus aucun palier (PlanTier) ni nom de plan n'est testé :
/// l'interface demande une clé (catalog.access, ai.feature.exam_coach,
/// favorites.max…). Le serveur reste seul juge (403 / 402 en cas de refus).
class SubscriptionNotifier extends ChangeNotifier {
  ApiActiveSubscription? _sub;
  ApiEntitlements _ent = const ApiEntitlements();

  Future<void> loadFromApi() async {
    final apiSub = await SubscriptionService.instance.getCurrent();
    if (apiSub == null) return;
    _sub = apiSub;
    _ent = apiSub.entitlements;
    notifyListeners();
  }

  ApiActiveSubscription? get current => _sub;
  ApiEntitlements get entitlements => _ent;

  /// Vrai si un plan payant (ou un essai) est en vigueur.
  bool get hasPlan => _sub?.hasPlan ?? false;
  String get planName => _sub?.planName ?? L10n.current.commonFree;
  int get aiMultiplier => _ent.aiMultiplier;

  bool has(String key) => _ent.has(key);
  int limit(String key) => _ent.limit(key);
  bool allowsOneMore(String key, int current) => _ent.allowsOneMore(key, current);

  /// Indicatif seulement : le serveur reste seul juge (402 à l'épuisement).
  bool get canUseAI => !(_sub?.aiQuotaExhausted ?? false);
}

/// Clés de droits lues par l'application (Services/Entitlements/EntitlementCatalog.cs).
class EntitlementKeys {
  static const catalogAccess = 'catalog.access';
  static const examCoach = 'ai.feature.exam_coach';
  static const studySession = 'ai.feature.study_session';
  static const studyPlan = 'ai.feature.study_plan';
  static const attachments = 'ai.feature.attachments';
  static const childrenMax = 'children.max';
  static const childrenCatalog = 'children.catalog';
  static const realtimeAlerts = 'parent.realtime_alerts';
  static const favoritesMax = 'favorites.max';
  static const groupsMax = 'groups.max_owned';
  static const teacherShare = 'teacher.revenue_share';
  static const maxClasses = 'teacher.max_classes';
  static const quizGeneration = 'ai.feature.quiz_generation';
  static const correctionAssist = 'ai.feature.correction_assist';
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
