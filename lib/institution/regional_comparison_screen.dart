import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Écart d'une matière : l'établissement face à la moyenne des autres.
class RegionalSubject {
  final String subject;

  /// Moyennes des quiz sur 100 (affichées sur 20).
  final double mine;
  final double? region;
  final double? best;
  final int quizzes;

  const RegionalSubject({required this.subject, required this.mine, this.region, this.best, this.quizzes = 0});

  factory RegionalSubject.fromJson(Map<String, dynamic> j) => RegionalSubject(
        subject: j['subject']?.toString() ?? '',
        mine: (j['mine'] as num?)?.toDouble() ?? 0,
        region: (j['region'] as num?)?.toDouble(),
        best: (j['best'] as num?)?.toDouble(),
        quizzes: (j['quizzes'] as num?)?.toInt() ?? 0,
      );
}

/// GET /institution/comparison : rang anonyme de l'établissement dans sa
/// région (sinon sa ville, sinon le pays) sur 90 jours.
class RegionalComparison {
  final bool available;
  final String? reason;
  final String scope;
  final int institutions;
  final int rank;
  final int percentile;
  final double mine;
  final double regionAverage;
  final double best;
  final int students;
  final List<RegionalSubject> subjects;

  const RegionalComparison({
    required this.available,
    this.reason,
    this.scope = '',
    this.institutions = 0,
    this.rank = 0,
    this.percentile = 0,
    this.mine = 0,
    this.regionAverage = 0,
    this.best = 0,
    this.students = 0,
    this.subjects = const [],
  });

  factory RegionalComparison.fromJson(Map<String, dynamic> body) {
    final j = body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body;
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return RegionalComparison(
      available: j['available'] == true,
      reason: j['reason'] as String?,
      scope: j['scope']?.toString() ?? '',
      institutions: i('institutions'),
      rank: i('rank'),
      percentile: i('percentile'),
      mine: n('mine'),
      regionAverage: n('regionAverage'),
      best: n('best'),
      students: i('students'),
      subjects: (j['subjects'] is List ? j['subjects'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(RegionalSubject.fromJson)
          .toList(),
    );
  }
}

/// « Comparaison régionale » de l'établissement (lot 7), comme
/// RegionalComparison du site : rang parmi les établissements comparables,
/// moyenne face à la moyenne et à la meilleure, écart par matière. Aucun
/// autre établissement n'est nommé.
class RegionalComparisonScreen extends StatefulWidget {
  const RegionalComparisonScreen({super.key});

  /// Lecture remplaçable dans les tests.
  static Future<RegionalComparison> Function() fetch = () async {
    final res = await ApiClient.instance.dio.get('/institution/comparison');
    return RegionalComparison.fromJson(res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : const {});
  };

  @override
  State<RegionalComparisonScreen> createState() => _RegionalComparisonScreenState();
}

class _RegionalComparisonScreenState extends State<RegionalComparisonScreen> {
  RegionalComparison? _data;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final d = await RegionalComparisonScreen.fetch();
      if (mounted) setState(() => _data = d);
    } catch (_) {
      if (mounted && _data == null) setState(() => _error = true);
    }
  }

  /// Score sur 100 vers une note sur 20, une décimale.
  static String on20(double? v) => v == null ? '–' : '${(v / 5).toStringAsFixed(1)} / 20';

  Widget _bar(WinScheme s, String label, double value, Color color, {bool strong = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: strong ? WinType.titleS(s.onStrong) : WinType.labelM(s.onStrong))),
            Text(on20(value), style: WinType.labelM(s.onStrong)),
          ]),
          const SizedBox(height: 4),
          WinProgressBar(value.clamp(0, 100).toDouble(), color: color, height: 8),
        ]),
      );

  Widget _subject(WinScheme s, AppLocalizations l, RegionalSubject x) {
    final gap = x.region == null ? null : (x.mine - x.region!) / 5;
    final flat = gap == null || gap.abs() < 0.3;
    final (IconData icon, Color color) = flat
        ? (PhosphorIconsRegular.minus, s.onMuted)
        : gap > 0
            ? (PhosphorIconsRegular.trendUp, WinColors.success)
            : (PhosphorIconsRegular.trendDown, WinColors.error);
    final gapText = gap == null ? '–' : '${gap > 0 ? '+' : ''}${gap.toStringAsFixed(1)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.subject, style: WinType.titleS(s.onStrong)),
              const SizedBox(height: 2),
              Text(l.regCmpSubjectLine(on20(x.mine), on20(x.region)), style: WinType.labelM(s.onMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(gapText, style: WinType.labelM(color)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (d == null) {
      body = const WinLoading();
    } else if (!d.available) {
      // La raison du serveur est en français ; en anglais, phrase générique.
      final reason = L10n.locale.languageCode == 'fr' && (d.reason ?? '').isNotEmpty ? d.reason! : l.regCmpNoneText;
      body = WinEmptyState(
        icon: PhosphorIconsRegular.mapPin,
        title: l.regCmpNoneTitle,
        message: reason,
        actionLabel: l.commonRetry,
        onAction: _load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.regCmpIntro(d.scope, d.institutions), style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          WinCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(PhosphorIconsRegular.ranking, color: s.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(l.regCmpRank(d.rank, d.institutions), style: WinType.titleM(s.onStrong))),
              ]),
              const SizedBox(height: 4),
              Text(l.regCmpBetter(d.percentile), style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 14),
              _bar(s, l.regCmpYours, d.mine, WinColors.teal600, strong: true),
              _bar(s, l.regCmpAverage(d.scope), d.regionAverage, s.outline2),
              _bar(s, l.regCmpBest, d.best, s.outline2),
              Text(l.regCmpStudents(d.students), style: WinType.labelM(s.onMuted)),
            ]),
          ),
          if (d.subjects.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l.regCmpSubjects, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            for (final x in d.subjects) _subject(s, l, x),
          ],
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.regCmpTitle)),
      body: SafeArea(child: body),
    );
  }
}
