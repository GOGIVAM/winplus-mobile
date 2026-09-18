import 'api_client.dart';
import 'local_cache_service.dart';

/// Rapport destiné au parent (ParentReport côté backend). Version résumée
/// (liste), sans le contenu complet.
class ApiParentReport {
  final int id;
  final int? childId;
  final String reportType;
  final String? capsuleText;
  final bool isRead;
  final DateTime createdAt;

  const ApiParentReport({
    required this.id,
    this.childId,
    required this.reportType,
    this.capsuleText,
    required this.isRead,
    required this.createdAt,
  });

  factory ApiParentReport.fromJson(Map<String, dynamic> j) => ApiParentReport(
        id: j['id'] as int? ?? 0,
        childId: j['childId'] as int?,
        reportType: j['reportType'] as String? ?? '',
        capsuleText: j['capsuleText'] as String?,
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Portefeuille de compétences  portrait stable de l'apprenant, recalculé
/// une fois par mois (MonthlyPortfolioService). Trois textes descriptifs
/// uniquement : jamais de score, de jauge chiffrée ni de comparaison entre
/// enfants.
class ApiPortfolio {
  final String? regularite;
  final String? autonomie;
  final String? curiosite;
  final DateTime updatedAt;
  const ApiPortfolio(
      {this.regularite,
      this.autonomie,
      this.curiosite,
      required this.updatedAt});

  factory ApiPortfolio.fromJson(Map<String, dynamic> j) => ApiPortfolio(
        regularite: j['regularite'] as String?,
        autonomie: j['autonomie'] as String?,
        curiosite: j['curiosite'] as String?,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Album de fin d'année  récit généré une fois par an (YearlyAlbumService),
/// consulté uniquement dans l'app (pas d'export ni de partage).
class ApiAlbum {
  final String? schoolYear;
  final String? subjectsWorked;
  final String? progression;
  final List<String> topContents;
  final String? goalsSummary;
  final List<String> intensityWeeks;
  final String? bulletin;
  final DateTime updatedAt;
  const ApiAlbum({
    this.schoolYear,
    this.subjectsWorked,
    this.progression,
    this.topContents = const [],
    this.goalsSummary,
    this.intensityWeeks = const [],
    this.bulletin,
    required this.updatedAt,
  });

  factory ApiAlbum.fromJson(Map<String, dynamic> j) => ApiAlbum(
        schoolYear: j['schoolYear'] as String?,
        subjectsWorked: j['subjectsWorked'] as String?,
        progression: j['progression'] as String?,
        topContents: ((j['topContents'] as List?) ?? []).cast<String>(),
        goalsSummary: j['goalsSummary'] as String?,
        intensityWeeks: ((j['intensityWeeks'] as List?) ?? []).cast<String>(),
        bulletin: j['bulletin'] as String?,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Rapports reçus (hebdomadaire, capsule)  mis en cache (ReportsBox) pour
/// rester consultables hors ligne (priorité Moyenne : "déjà reçus").
class ReportsService {
  ReportsService._();
  static final ReportsService instance = ReportsService._();

  final _api = ApiClient.instance;

  Future<List<ApiParentReport>> getReportsForChild(int childId,
      {String? reportType}) async {
    final result = await LocalCacheService.cachedFetch<List<ApiParentReport>>(
      box: LocalCacheService.reports,
      key: 'reports_$childId${reportType != null ? '_$reportType' : ''}',
      fetchLiveRaw: () async => (await _api.dio.get(
              '/parent-reports/child/$childId',
              queryParameters:
                  reportType != null ? {'reportType': reportType} : null))
          .data,
      parse: (raw) => ((raw as List?) ?? [])
          .map((e) => ApiParentReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.value;
  }

  /// Dernière capsule hebdomadaire d'un enfant (dashboard uniquement),
  /// null si aucune n'existe encore (404 = état normal, pas une erreur).
  Future<String?> getLatestCapsule(int childId) async {
    try {
      final result = await LocalCacheService.cachedFetch<Map<String, dynamic>?>(
        box: LocalCacheService.reports,
        key: 'capsule_$childId',
        fetchLiveRaw: () async =>
            (await _api.dio.get('/parent-reports/capsule/$childId')).data,
        parse: (raw) =>
            raw == null ? null : Map<String, dynamic>.from(raw as Map),
      );
      return result.value?['capsuleText'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// null si aucun portefeuille calculé pour l'instant (404, état normal).
  Future<ApiPortfolio?> getPortfolio(int childId) async {
    try {
      final result = await LocalCacheService.cachedFetch<Map<String, dynamic>?>(
        box: LocalCacheService.reports,
        key: 'portfolio_$childId',
        fetchLiveRaw: () async =>
            (await _api.dio.get('/parent-reports/$childId/portefeuille')).data,
        parse: (raw) =>
            raw == null ? null : Map<String, dynamic>.from(raw as Map),
      );
      final data = result.value;
      return data == null ? null : ApiPortfolio.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// null si aucun album généré pour l'instant (404, déclenchement admin manuel).
  Future<ApiAlbum?> getAlbum(int childId) async {
    try {
      final result = await LocalCacheService.cachedFetch<Map<String, dynamic>?>(
        box: LocalCacheService.reports,
        key: 'album_$childId',
        fetchLiveRaw: () async =>
            (await _api.dio.get('/parent-reports/$childId/album')).data,
        parse: (raw) =>
            raw == null ? null : Map<String, dynamic>.from(raw as Map),
      );
      final data = result.value;
      return data == null ? null : ApiAlbum.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
