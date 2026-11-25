import 'dart:convert';

import 'api_client.dart';

/// Concours ou examen suivi par WinPlus. Le sigle est le même dans toutes
/// les langues ; [slug] sert aux routes du serveur (comme le site).
class ConcoursSchool {
  final String slug;
  final String name;
  const ConcoursSchool(this.slug, this.name);
}

/// Les quatorze concours et examens de la page /concours du site, dans le
/// même ordre.
const concoursSchools = [
  // Nom propre identique dans toutes les langues (échappé pour le garde-fou des textes).
  ConcoursSchool('ens', 'ENS Yaound\u00e9'),
  ConcoursSchool('polytechnique', 'Polytechnique'),
  ConcoursSchool('enam', 'ENAM'),
  ConcoursSchool('fmsb', 'FMSB'),
  ConcoursSchool('essec', 'ESSEC'),
  ConcoursSchool('enset', 'ENSET'),
  ConcoursSchool('bac', 'BAC'),
  ConcoursSchool('bepc', 'BEPC'),
  ConcoursSchool('probatoire', 'Probatoire'),
  ConcoursSchool('fasa', 'FASA'),
  ConcoursSchool('ibaf', 'IBAF'),
  ConcoursSchool('iut', 'IUT'),
  ConcoursSchool('gce-o-level', 'GCE O Level'),
  ConcoursSchool('gce-a-level', 'GCE A Level'),
];

class ConcoursFaq {
  final String question;
  final String answer;
  const ConcoursFaq(this.question, this.answer);
}

/// Calendrier et informations officielles d'une session (ConcoursEventDto).
class ConcoursEvent {
  final int id;
  final String slug;
  final int year;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? examDate;
  final DateTime? resultsDate;
  final String? location;
  final int? feeXaf;
  final String? officialUrl;

  /// open, upcoming, closed ou unknown.
  final String registrationStatus;
  final DateTime? sourceCheckedAt;
  final List<String> sources;
  final Map<String, dynamic> _raw;

  ConcoursEvent._(this._raw)
      : id = (_raw['id'] as num?)?.toInt() ?? 0,
        slug = _raw['slug']?.toString() ?? '',
        year = (_raw['year'] as num?)?.toInt() ?? 0,
        registrationStart = _date(_raw['registrationStartDate']),
        registrationEnd = _date(_raw['registrationEndDate']),
        examDate = _date(_raw['examDate']),
        resultsDate = _date(_raw['resultsDate']),
        location = _text(_raw['location']),
        feeXaf = (_raw['enrollmentFeeXaf'] as num?)?.toInt(),
        officialUrl = _text(_raw['officialRegistrationUrl']),
        registrationStatus = _raw['registrationStatus']?.toString() ?? 'unknown',
        sourceCheckedAt = _date(_raw['sourceCheckedAt']),
        sources = (_raw['sourceUrl']?.toString() ?? '')
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

  factory ConcoursEvent.fromJson(Map<String, dynamic> j) => ConcoursEvent._(j);

  static DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  static String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Champ traduisible : la version anglaise (suffixe En) si elle existe et
  /// que l'application est en anglais, sinon le français.
  String? field(String name, String languageCode) {
    if (languageCode == 'en') {
      final en = _text(_raw['${name}En']);
      if (en != null) return en;
    }
    return _text(_raw[name]);
  }

  String name(String languageCode) => field('name', languageCode) ?? slug.toUpperCase();

  /// Conseils : une ligne par conseil.
  List<String> tips(String languageCode) =>
      (field('tips', languageCode) ?? '').split('\n').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  /// FAQ saisie par l'équipe : JSON [{question, answer}] ; illisible = vide.
  List<ConcoursFaq> faq(String languageCode) {
    final raw = field('faqJson', languageCode);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((m) => ConcoursFaq('${m['question'] ?? ''}'.trim(), '${m['answer'] ?? ''}'.trim()))
          .where((f) => f.question.isNotEmpty && f.answer.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Prochaine date utile (inscriptions, épreuve, résultats), ou null.
  DateTime? nextDate(DateTime now) {
    final dates = [registrationStart, registrationEnd, examDate, resultsDate].whereType<DateTime>().where((d) => d.isAfter(now)).toList()
      ..sort();
    return dates.isEmpty ? null : dates.first;
  }
}

/// Une épreuve publiée (sujet d'annales) d'un concours.
class ConcoursExam {
  final int id;
  final int subjectId;
  final String title;
  final String category;
  final int year;
  final bool isFree;
  final num price;
  final bool hasCorrection;

  const ConcoursExam({
    required this.id,
    required this.subjectId,
    required this.title,
    this.category = '',
    this.year = 0,
    this.isFree = false,
    this.price = 0,
    this.hasCorrection = false,
  });

  factory ConcoursExam.fromJson(Map<String, dynamic> j) => ConcoursExam(
        id: (j['id'] as num?)?.toInt() ?? 0,
        subjectId: (j['subjectId'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        year: (j['year'] as num?)?.toInt() ?? 0,
        isFree: j['isFree'] == true,
        price: (j['price'] as num?) ?? 0,
        hasCorrection: j['hasCorrection'] == true,
      );
}

/// Chiffres réels d'un concours (GET /exams/stats/{type}).
class ConcoursStats {
  final int total;
  final int withCorrection;
  final int free;
  final List<(String, int)> categories;
  final List<int> years;
  final List<ConcoursExam> exams;

  const ConcoursStats({
    this.total = 0,
    this.withCorrection = 0,
    this.free = 0,
    this.categories = const [],
    this.years = const [],
    this.exams = const [],
  });

  factory ConcoursStats.fromJson(Map<String, dynamic> j) => ConcoursStats(
        total: (j['totalExams'] as num?)?.toInt() ?? 0,
        withCorrection: (j['withCorrection'] as num?)?.toInt() ?? 0,
        free: (j['freeExams'] as num?)?.toInt() ?? 0,
        categories: (j['categories'] is List ? j['categories'] as List : const [])
            .whereType<Map>()
            .map((c) => ('${c['name'] ?? ''}', (c['count'] as num?)?.toInt() ?? 0))
            .where((c) => c.$1.isNotEmpty)
            .toList(),
        years: (j['years'] is List ? j['years'] as List : const []).whereType<num>().map((y) => y.toInt()).toList(),
        exams: (j['exams'] is List ? j['exams'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(ConcoursExam.fromJson)
            .toList(),
      );
}

/// Concours et examens (lot 7), comme les pages /concours du site :
/// calendrier officiel (GET /concours-events), épreuves publiées et
/// matières (GET /exams/stats/{type}).
class ConcoursService {
  ConcoursService._();
  static final ConcoursService instance = ConcoursService._();
  final _api = ApiClient.instance;

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  /// Sessions publiées de l'année en cours et de la suivante, par slug (la
  /// plus proche gardée quand un concours a deux sessions).
  Future<Map<String, ConcoursEvent>> events() async {
    final res = await _api.dio.get('/concours-events');
    final raw = res.data is Map ? res.data['data'] : res.data;
    final out = <String, ConcoursEvent>{};
    for (final j in (raw is List ? raw : const []).whereType<Map<String, dynamic>>()) {
      final e = ConcoursEvent.fromJson(j);
      out.putIfAbsent(e.slug, () => e);
    }
    return out;
  }

  /// Dernière session publiée d'un concours, ou null.
  Future<ConcoursEvent?> event(String slug) async {
    try {
      final res = await _api.dio.get('/concours-events/$slug');
      final j = _map(res.data);
      return j.isEmpty ? null : ConcoursEvent.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<ConcoursStats> stats(String slug) async {
    final res = await _api.dio.get('/exams/stats/$slug');
    return ConcoursStats.fromJson(_map(res.data));
  }
}
