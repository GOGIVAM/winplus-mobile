import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/chatbot_service.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Prévision de réussite (POST /institutions/class-prediction, WinAI).
class ClassPrediction {
  final int passRate;

  /// high, medium ou low.
  final String confidence;
  final int atRisk;
  final int toExcel;
  final int students;
  final num? vsLastYear;
  final List<String> riskFactors;
  final List<(String, String?, String?)> interventions;

  const ClassPrediction({
    this.passRate = 0,
    this.confidence = 'low',
    this.atRisk = 0,
    this.toExcel = 0,
    this.students = 0,
    this.vsLastYear,
    this.riskFactors = const [],
    this.interventions = const [],
  });

  factory ClassPrediction.fromJson(Map j) {
    final d = j['data'] is Map ? j['data'] as Map : j;
    int i(Object? v) => (v as num?)?.round() ?? 0;
    return ClassPrediction(
      passRate: i(d['predicted_pass_rate']),
      confidence: d['confidence']?.toString() ?? 'low',
      atRisk: i(d['at_risk_count']),
      toExcel: i(d['likely_to_excel_count']),
      students: i(d['student_count']),
      vsLastYear: d['comparison_to_last_year'] as num?,
      riskFactors: (d['key_risk_factors'] is List ? d['key_risk_factors'] as List : const [])
          .map((e) => '$e')
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      // Une intervention est un objet {intervention, impact, effort} ou un texte.
      interventions: (d['recommended_interventions'] is List ? d['recommended_interventions'] as List : const [])
          .map((e) => e is Map
              ? ('${e['intervention'] ?? ''}', e['impact'] as String?, e['effort'] as String?)
              : ('$e', null, null))
          .where((e) => e.$1.trim().isNotEmpty)
          .toList(),
    );
  }
}

/// « Prévision de réussite » de l'établissement (lot 7), comme
/// ClassPrediction du site : taux de réussite prévu, élèves en difficulté
/// et en avance, facteurs de risque, actions conseillées.
class ClassPredictionScreen extends StatefulWidget {
  const ClassPredictionScreen({super.key});

  @override
  State<ClassPredictionScreen> createState() => _ClassPredictionScreenState();
}

class _ClassPredictionScreenState extends State<ClassPredictionScreen> {
  ClassPrediction? _data;
  bool _loading = false;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await InstitutionService.instance.getMyInstitutionId();
      final res = await ApiClient.instance.dio
          .post('/institutions/class-prediction', data: {'institution_id': id, 'student_ids': const <int>[]});
      if (mounted) setState(() => _data = ClassPrediction.fromJson(res.data is Map ? res.data as Map : const {}));
    } on DioException catch (e) {
      final body = e.response?.data;
      final map = body is Map ? body : null;
      final text = map?['error'] ?? map?['message'] ?? map?['detail'];
      if (mounted) {
        setState(() => _error = text is String && text.trim().isNotEmpty
            ? text.trim()
            : ChatbotService.quotaRefusalMessage(e.response?.statusCode, body) ?? context.l10n.commonLoadError);
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.commonLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    final conf = switch (d?.confidence) {
      'high' => (l.predConfHigh, BadgeColor.success),
      'medium' => (l.predConfMedium, BadgeColor.blue),
      _ => (l.predConfLow, BadgeColor.neutral),
    };
    final mid = d == null ? 0 : (d.students - d.toExcel - d.atRisk).clamp(0, d.students);
    final total = d == null || d.students == 0 ? 1 : d.students;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.predTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.predIntro, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          WinButton(d == null ? l.predRun : l.predRerun,
              block: true,
              variant: d == null ? WinButtonVariant.accent : WinButtonVariant.outline,
              icon: PhosphorIconsRegular.sparkle,
              loading: _loading,
              onTap: _loading ? null : _run),
          if (_error != null) ...[const SizedBox(height: 10), WinAlert(_error!, type: BadgeColor.warn)],
          if (d != null) ...[
            const SizedBox(height: 16),
            WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(l.predPassRate, style: WinType.labelM(s.onMuted))),
                  WinBadge(conf.$1, color: conf.$2),
                ]),
                Text(WinFormat.percent(d.passRate), style: WinType.archivo(size: 32, color: s.onStrong)),
                if (d.vsLastYear != null)
                  Text(l.predVsLastYear('${d.vsLastYear! >= 0 ? '+' : ''}${d.vsLastYear}'), style: WinType.labelM(s.onMuted)),
                const SizedBox(height: 12),
                for (final (label, n, color) in [
                  (l.predExcel, d.toExcel, WinColors.success),
                  (l.predMiddle, mid, WinColors.teal600),
                  (l.predAtRisk, d.atRisk, WinColors.error),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text(label, style: WinType.labelM(s.onMuted))),
                      Expanded(child: WinProgressBar(n / total * 100, color: color, height: 8)),
                      SizedBox(width: 36, child: Text('$n', textAlign: TextAlign.end, style: WinType.labelM(s.onStrong))),
                    ]),
                  ),
              ]),
            ),
            if (d.riskFactors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.predRiskFactors, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 6),
              for (final f in d.riskFactors) Text('•  $f', style: WinType.bodyM(s.onStrong)),
            ],
            if (d.interventions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.predActions, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 6),
              for (final a in d.interventions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WinCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.$1, style: WinType.bodyM(s.onStrong)),
                      if (a.$2 != null || a.$3 != null)
                        Text([if (a.$2 != null) l.predImpact(a.$2!), if (a.$3 != null) l.predEffort(a.$3!)].join(' · '),
                            style: WinType.labelM(s.onMuted)),
                    ]),
                  ),
                ),
            ],
          ],
        ]),
      ),
    );
  }
}
