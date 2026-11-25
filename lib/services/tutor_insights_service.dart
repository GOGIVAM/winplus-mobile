import 'dart:convert';

import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';
import 'chatbot_service.dart';

/// Élève suivi en cours particuliers (au moins une séance effectuée).
class TutoredStudent {
  final int userId;
  final String name;
  final int sessions;
  final String? lastSubject;
  const TutoredStudent({required this.userId, required this.name, this.sessions = 0, this.lastSubject});

  factory TutoredStudent.fromJson(Map<String, dynamic> j) => TutoredStudent(
        userId: (j['studentUserId'] as num?)?.toInt() ?? 0,
        name: j['studentName']?.toString() ?? '',
        sessions: (j['sessionsCount'] as num?)?.toInt() ?? 0,
        lastSubject: j['lastSubject'] as String?,
      );
}

/// Rapport mensuel de coaching WinAI. Le serveur garde le JSON du générateur
/// dans `content` ; un ancien rapport en texte simple reste lisible.
class CoachingReport {
  final int id;
  final String monthLabel;
  final DateTime? generatedAt;
  final String text;
  final List<String> strengths;
  final List<String> improving;
  final List<String> stagnation;
  final List<String> recommendations;

  const CoachingReport({
    required this.id,
    required this.monthLabel,
    this.generatedAt,
    this.text = '',
    this.strengths = const [],
    this.improving = const [],
    this.stagnation = const [],
    this.recommendations = const [],
  });

  factory CoachingReport.fromJson(Map<String, dynamic> j) {
    final raw = j['content']?.toString() ?? '';
    Map<String, dynamic>? parsed;
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) parsed = d;
    } catch (_) {}
    List<String> list(String k) => (parsed?[k] is List ? parsed![k] as List : const []).map((e) => '$e').toList();
    return CoachingReport(
      id: (j['id'] as num?)?.toInt() ?? 0,
      monthLabel: j['monthLabel']?.toString() ?? '',
      generatedAt: DateTime.tryParse(j['generatedAt']?.toString() ?? '')?.toLocal(),
      text: parsed == null ? raw : (parsed['report_text']?.toString() ?? ''),
      strengths: list('strengths'),
      improving: list('subjects_improving'),
      stagnation: list('stagnation_patterns'),
      recommendations: list('recommendations'),
    );
  }

  bool get isEmpty =>
      text.trim().isEmpty && strengths.isEmpty && improving.isEmpty && stagnation.isEmpty && recommendations.isEmpty;
}

/// Refus ou échec lisible (pas assez de séances, limite WinAI…).
class TutorInsightsException implements Exception {
  final String message;
  final int? status;
  const TutorInsightsException(this.message, {this.status});

  bool get isQuota => status == 402 || status == 403;

  @override
  String toString() => message;
}

/// WinAI côté répétiteur (lot 7), comme TutorCoachingPanel et la fiche
/// d'élève de TutorBookingRequests du site : rapport mensuel de coaching et
/// fiche de révision par élève (générée, modifiable, enregistrée).
class TutorInsightsService {
  TutorInsightsService._();
  static final TutorInsightsService instance = TutorInsightsService._();
  final _api = ApiClient.instance;

  static Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  static TutorInsightsException error(Object e) {
    if (e is TutorInsightsException) return e;
    final l = L10n.current;
    if (e is! DioException || e.response == null) return TutorInsightsException(l.commonLoadError);
    final status = e.response!.statusCode;
    final body = e.response!.data;
    final map = body is Map ? body : null;
    final text = [map?['message'], map?['error'], map?['detail']]
        .firstWhere((v) => v is String && v.trim().isNotEmpty, orElse: () => null) as String?;
    final fallback = ChatbotService.quotaRefusalMessage(status == 403 ? 402 : status, body) ?? l.commonLoadError;
    return TutorInsightsException(text?.trim() ?? fallback, status: status);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw error(e);
    }
  }

  /// Dernier rapport, ou null s'il n'y en a pas encore (404).
  Future<CoachingReport?> latestReport() => _guard(() async {
        try {
          final res = await _api.dio.get('/tutor-insights/coaching-report/latest');
          return CoachingReport.fromJson(_map(res.data));
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });

  /// Génère le rapport du mois en cours (débité sur la consommation WinAI).
  Future<CoachingReport> generateReport() => _guard(() async {
        final res = await _api.dio.post('/tutor-insights/coaching-report/generate-now', data: const {});
        return CoachingReport.fromJson(_map(res.data));
      });

  Future<List<TutoredStudent>> students() => _guard(() async {
        final res = await _api.dio.get('/tutor-insights/students');
        final raw = res.data is Map ? res.data['data'] : res.data;
        return (raw is List ? raw : const []).whereType<Map<String, dynamic>>().map(TutoredStudent.fromJson).toList();
      });

  /// Fiche enregistrée pour cet élève, ou null.
  Future<String?> savedSheet(int studentUserId) => _guard(() async {
        try {
          final res = await _api.dio.get('/tutor-insights/revision-sheet/$studentUserId');
          return _map(res.data)['content']?.toString();
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });

  /// WinAI rédige une fiche à partir des comptes-rendus de séance.
  Future<String> generateSheet(int studentUserId) => _guard(() async {
        final res = await _api.dio.post('/tutor-insights/revision-sheet/$studentUserId/generate', data: const {});
        return _map(res.data)['sheet_text']?.toString() ?? '';
      });

  Future<void> saveSheet(int studentUserId, String content, {String? subject}) => _guard(() =>
      _api.dio.put('/tutor-insights/revision-sheet/$studentUserId', data: {'subject': subject, 'content': content}));
}
