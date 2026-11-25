import 'api_client.dart';

class ApiAffiliateAccount {
  final String code;
  final String referralUrl;
  final num commissionRate;
  final String status;
  const ApiAffiliateAccount({
    required this.code,
    required this.referralUrl,
    required this.commissionRate,
    required this.status,
  });

  factory ApiAffiliateAccount.fromJson(Map<String, dynamic> j) => ApiAffiliateAccount(
        code: j['code']?.toString() ?? '',
        referralUrl: j['referralUrl']?.toString() ?? '',
        commissionRate: (j['commissionRate'] as num?) ?? 0,
        status: j['status']?.toString() ?? 'active',
      );
}

class ApiAffiliateStats {
  final int clicks;
  final int conversions;
  final num pending;
  final num confirmed;
  final num paid;
  const ApiAffiliateStats({
    required this.clicks,
    required this.conversions,
    required this.pending,
    required this.confirmed,
    required this.paid,
  });

  factory ApiAffiliateStats.fromJson(Map<String, dynamic> j) => ApiAffiliateStats(
        clicks: (j['totalClicks'] as num?)?.toInt() ?? 0,
        conversions: (j['totalConversions'] as num?)?.toInt() ?? 0,
        pending: (j['pendingEarnings'] as num?) ?? 0,
        confirmed: (j['confirmedEarnings'] as num?) ?? 0,
        paid: (j['paidEarnings'] as num?) ?? 0,
      );
}

class ApiAffiliateCommission {
  final int id;
  final String orderNumber;
  final num orderAmount;
  final num amount;

  /// pending, confirmed, paid ou reversed.
  final String status;
  final DateTime? createdAt;

  const ApiAffiliateCommission({
    required this.id,
    required this.orderNumber,
    required this.orderAmount,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory ApiAffiliateCommission.fromJson(Map<String, dynamic> j) => ApiAffiliateCommission(
        id: (j['id'] as num?)?.toInt() ?? 0,
        orderNumber: j['orderNumber']?.toString() ?? '',
        orderAmount: (j['orderAmount'] as num?) ?? 0,
        amount: (j['commissionAmount'] as num?) ?? 0,
        status: j['status']?.toString() ?? 'pending',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
      );
}

class AffiliateOverview {
  final ApiAffiliateAccount account;
  final ApiAffiliateStats stats;
  final List<ApiAffiliateCommission> commissions;
  const AffiliateOverview({required this.account, required this.stats, required this.commissions});
}

/// Programme d'affiliation du professeur (lot 7), comme
/// AffiliateProgramPanel du site : lien de parrainage, chiffres, commissions.
class AffiliateService {
  AffiliateService._();
  static final AffiliateService instance = AffiliateService._();
  final _api = ApiClient.instance;

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  /// GET /affiliate/me crée le compte d'affiliation au premier appel ; les
  /// statistiques et commissions viennent ensuite.
  Future<AffiliateOverview> overview() async {
    final account = ApiAffiliateAccount.fromJson(_map((await _api.dio.get('/affiliate/me')).data));
    final stats = ApiAffiliateStats.fromJson(_map((await _api.dio.get('/affiliate/me/stats')).data));
    final raw = (await _api.dio.get('/affiliate/me/commissions')).data;
    final list = raw is Map ? raw['data'] : raw;
    return AffiliateOverview(
      account: account,
      stats: stats,
      commissions: (list is List ? list : const [])
          .whereType<Map<String, dynamic>>()
          .map(ApiAffiliateCommission.fromJson)
          .toList(),
    );
  }
}
