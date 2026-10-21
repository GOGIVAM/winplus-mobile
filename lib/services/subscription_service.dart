import 'api_client.dart';
import '../l10n/l10n.dart';

/// Droit affiché sur une carte de plan (lot 9.7b) : uniquement des droits
/// réellement appliqués par le serveur.
class ApiPlanFeature {
  final String key, label, display;
  final bool included;
  const ApiPlanFeature({required this.key, required this.label, required this.display, required this.included});
  factory ApiPlanFeature.fromJson(Map<String, dynamic> j) => ApiPlanFeature(
        key: j['key'] as String? ?? '',
        label: j['label'] as String? ?? '',
        display: j['display'] as String? ?? '',
        included: j['included'] as bool? ?? false,
      );
}

/// Carte publique d'un plan (GET /api/pricing/catalog) : version publiée,
/// prix TTC par période (monthly, quarterly, yearly), droits.
class ApiPlanCard {
  final int planId;
  final String name;
  final String? description;
  final String audience;
  final bool isFree, isPopular;
  final Map<String, double> prices;
  final int aiMultiplier;
  final List<ApiPlanFeature> features;
  const ApiPlanCard({
    required this.planId,
    required this.name,
    this.description,
    required this.audience,
    required this.isFree,
    required this.isPopular,
    required this.prices,
    required this.aiMultiplier,
    required this.features,
  });

  double? priceFor(String period) => prices[period];

  factory ApiPlanCard.fromJson(Map<String, dynamic> j) => ApiPlanCard(
        planId: j['planId'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        audience: j['audience'] as String? ?? 'student',
        isFree: j['isFree'] as bool? ?? false,
        isPopular: j['isPopular'] as bool? ?? false,
        prices: {
          for (final p in (j['prices'] as List? ?? []).cast<Map<String, dynamic>>())
            (p['period'] as String? ?? 'monthly'): ((p['priceTtc'] ?? 0) as num).toDouble(),
        },
        aiMultiplier: (j['aiMultiplier'] as num?)?.toInt() ?? 1,
        features: (j['features'] as List? ?? [])
            .map((e) => ApiPlanFeature.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Devis d'abonnement (POST /api/subscriptions/quote) : prix réellement facturé.
class ApiSubscriptionQuote {
  final String planName, billingPeriod, change, message;
  final double listPrice, discount, prorataCredit, amountDue;
  final int? trialDays;
  final String? promoCode, promoError;
  const ApiSubscriptionQuote({
    required this.planName,
    required this.billingPeriod,
    required this.change,
    required this.message,
    required this.listPrice,
    required this.discount,
    required this.prorataCredit,
    required this.amountDue,
    this.trialDays,
    this.promoCode,
    this.promoError,
  });
  factory ApiSubscriptionQuote.fromJson(Map<String, dynamic> j) => ApiSubscriptionQuote(
        planName: j['planName'] as String? ?? '',
        billingPeriod: j['billingPeriod'] as String? ?? 'monthly',
        change: j['change'] as String? ?? 'new',
        message: j['message'] as String? ?? '',
        listPrice: ((j['listPriceTtc'] ?? 0) as num).toDouble(),
        discount: ((j['discountTtc'] ?? 0) as num).toDouble(),
        prorataCredit: ((j['prorataCreditTtc'] ?? 0) as num).toDouble(),
        amountDue: ((j['amountDueTtc'] ?? 0) as num).toDouble(),
        trialDays: (j['trialDays'] as num?)?.toInt(),
        promoCode: j['promoCode'] as String?,
        promoError: j['promoError'] as String?,
      );
}

/// Résultat d'un achat : activated, scheduled (descente à l'échéance) ou
/// payment_pending (confirmation Mobile Money attendue).
class ApiPurchaseResult {
  final String status, message;
  final int? paymentId;
  final double amount;
  const ApiPurchaseResult({required this.status, required this.message, this.paymentId, this.amount = 0});
}

/// Droits effectifs (lot 9.7b, GET /api/me/entitlements). L'application ne
/// teste jamais un nom de plan : elle lit ces clés (booléens, ou entiers où
/// -1 = illimité). Les quotas WinAI ne sont jamais exposés en tokens (8.3).
class ApiEntitlements {
  static const int unlimited = -1;
  final String? audience;
  final int aiMultiplier;
  final Map<String, dynamic> values;
  const ApiEntitlements({this.audience, this.aiMultiplier = 1, this.values = const {}});

  factory ApiEntitlements.fromJson(Map<String, dynamic>? j) => ApiEntitlements(
        audience: j?['audience'] as String?,
        aiMultiplier: (j?['aiMultiplier'] as num?)?.toInt() ?? 1,
        values: (j?['entitlements'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  bool has(String key) => values[key] == true;

  /// Valeur entière d'un droit (-1 = illimité).
  int limit(String key) => (values[key] as num?)?.toInt() ?? 0;

  bool isUnlimited(String key) => limit(key) == unlimited;

  bool allowsOneMore(String key, int current) => isUnlimited(key) || current < limit(key);
}

class ApiActiveSubscription {
  final int id;

  /// Lot 9.7b : vrai si un plan payant (ou un essai) est en vigueur.
  final bool hasPlan;

  /// Id du plan (famille), requis pour changer de plan ou renouveler.
  final int pricingPlanId;
  final String planName;

  /// free, active, trialing (essai), past_due (grâce).
  final String status;

  /// monthly, quarterly, yearly (null sans plan).
  final String? billingPeriod;
  final DateTime? expiresAt;
  final DateTime? graceUntil;
  final bool autoRenew;
  final bool cancelAtPeriodEnd;

  /// Montant TTC réellement payé pour la période en cours.
  final double price;
  final String? pendingPlanName;
  final ApiEntitlements entitlements;

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
    required this.hasPlan,
    required this.pricingPlanId,
    required this.planName,
    required this.status,
    this.billingPeriod,
    this.expiresAt,
    this.graceUntil,
    this.autoRenew = false,
    this.cancelAtPeriodEnd = false,
    this.price = 0,
    this.pendingPlanName,
    this.entitlements = const ApiEntitlements(),
    this.aiUsageMultiplier = 1,
    this.aiUsageLabel = '',
    this.aiQuotaExhausted = false,
    this.aiLimitReached,
    this.aiLimitResetsAt,
    this.aiLimitMessage,
  });

  bool get isInGrace => status == 'past_due';
  bool get isTrial => status == 'trialing';

  factory ApiActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ApiActiveSubscription(
        id: j['id'] as int? ?? 0,
        hasPlan: j['hasPlan'] as bool? ?? false,
        pricingPlanId: j['pricingPlanId'] as int? ?? 0,
        planName: j['planName'] as String? ?? 'Gratuit',
        status: j['status'] as String? ?? 'free',
        billingPeriod: j['billingPeriod'] as String?,
        expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? ''),
        graceUntil: DateTime.tryParse(j['graceUntil'] as String? ?? ''),
        autoRenew: j['autoRenew'] as bool? ?? false,
        cancelAtPeriodEnd: j['cancelAtPeriodEnd'] as bool? ?? false,
        price: ((j['price'] ?? 0) as num).toDouble(),
        pendingPlanName: j['pendingPlanName'] as String?,
        entitlements: ApiEntitlements.fromJson(j['entitlements'] as Map<String, dynamic>?),
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

  /// Plans en vente d'un public (student, parent, teacher), depuis la grille
  /// versionnée du serveur (lot 9.7b) : plus aucun plan écrit en dur.
  Future<List<ApiPlanCard>> getCatalog(String audience) async {
    final res = await _api.dio
        .get('/pricing/catalog', queryParameters: {'audience': audience});
    final data = (res.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>? ?? {};
    final list = data[audience] as List? ?? [];
    return list
        .map((e) => ApiPlanCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiSubscriptionQuote> quote({required int planId, required String period, String? promoCode}) async {
    final res = await _api.dio.post('/subscriptions/quote', data: {
      'planId': planId,
      'billingPeriod': period,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
    });
    return ApiSubscriptionQuote.fromJson(res.data as Map<String, dynamic>);
  }

  /// Souscription, montée, descente ou essai : solde (balance) ou Mobile
  /// Money (numéro requis). Lève une erreur Dio portant le message serveur.
  Future<ApiPurchaseResult> purchasePlan({
    required int planId,
    required String period,
    required String method,
    String? phone,
    String? promoCode,
    bool autoRenew = false,
  }) async {
    final res = await _api.dio.post('/subscriptions/purchase', data: {
      'planId': planId,
      'billingPeriod': period,
      'method': method,
      if (phone != null) 'phone': phone,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      'autoRenew': autoRenew,
    });
    final d = res.data as Map<String, dynamic>? ?? {};
    return ApiPurchaseResult(
      status: d['status'] as String? ?? 'activated',
      message: d['message'] as String? ?? '',
      paymentId: (d['paymentId'] as num?)?.toInt(),
      amount: ((d['amount'] ?? 0) as num).toDouble(),
    );
  }

  Future<bool> resume() async {
    try {
      await _api.dio.post('/subscriptions/me/resume');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAutoRenew(bool enabled) async {
    try {
      await _api.dio.put('/subscriptions/me/auto-renew', data: {'enabled': enabled});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelPending() async {
    try {
      await _api.dio.delete('/subscriptions/me/pending');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Recharge de tokens WinAI par le solde (paquets ; prix TTC fixé par l'admin).
  Future<String> topUpWinAi({int packs = 1}) async {
    final res = await _api.dio.post('/winai/topup', data: {
      'packs': packs,
      'requestId': '${DateTime.now().microsecondsSinceEpoch}',
    });
    return (res.data as Map<String, dynamic>?)?['message'] as String? ?? L10n.current.svcTopUpDone;
  }

  Future<ApiEntitlements?> getEntitlements() async {
    try {
      final res = await _api.dio.get('/me/entitlements');
      return ApiEntitlements.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ApiActiveSubscription?> getCurrent() async {
    try {
      final res = await _api.dio.get('/subscriptions/me');
      return ApiActiveSubscription.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
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
