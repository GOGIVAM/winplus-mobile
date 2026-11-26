import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Comparaison nationale anonyme (GET /institutions/{id}/benchmark, WinAI).
/// Moyennes et taux en pourcentage.
class NationalBenchmark {
  final double avg;
  final double nationalAvg;
  final double topQuartile;
  final int percentile;
  final double passRate;
  final double nationalPassRate;
  final String? strongest;
  final String? weakest;
  final double engagement;
  final double peerEngagement;
  final int students;

  const NationalBenchmark({
    this.avg = 0,
    this.nationalAvg = 0,
    this.topQuartile = 0,
    this.percentile = 0,
    this.passRate = 0,
    this.nationalPassRate = 0,
    this.strongest,
    this.weakest,
    this.engagement = 0,
    this.peerEngagement = 0,
    this.students = 0,
  });

  factory NationalBenchmark.fromJson(Map j) {
    final d = j['data'] is Map ? j['data'] as Map : j;
    double n(String k) => (d[k] as num?)?.toDouble() ?? 0;
    String? t(String k) => d[k] is String && (d[k] as String).trim().isNotEmpty ? (d[k] as String).trim() : null;
    return NationalBenchmark(
      avg: n('institution_avg_score'),
      nationalAvg: n('national_avg_score'),
      topQuartile: n('top_quartile_avg'),
      percentile: n('institution_percentile').round(),
      passRate: n('institution_pass_rate'),
      nationalPassRate: n('national_pass_rate'),
      strongest: t('strongest_subject'),
      weakest: t('weakest_subject_vs_peers'),
      engagement: n('engagement_rate'),
      peerEngagement: n('peer_engagement_avg'),
      students: n('student_count').round(),
    );
  }
}

/// Carte « Face à la moyenne nationale » (lot 7), comme BenchmarkPanel du
/// site. Rien si le service ne répond pas (la comparaison régionale reste).
class NationalBenchmarkCard extends StatefulWidget {
  const NationalBenchmarkCard({super.key});

  @override
  State<NationalBenchmarkCard> createState() => _NationalBenchmarkCardState();
}

class _NationalBenchmarkCardState extends State<NationalBenchmarkCard> {
  NationalBenchmark? _d;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = await InstitutionService.instance.getMyInstitutionId();
      if (id == null) return;
      final res = await ApiClient.instance.dio.get('/institutions/$id/benchmark');
      final d = NationalBenchmark.fromJson(res.data is Map ? res.data as Map : const {});
      if (mounted && d.nationalAvg > 0) setState(() => _d = d);
    } catch (_) {}
  }

  static String _on20(double v) => '${(v / 5).toStringAsFixed(1)} / 20';

  Widget _row(WinScheme s, String label, String mine, String ref, double mineV, double refV) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: WinType.labelM(s.onStrong))),
            Text(mine, style: WinType.labelM(mineV >= refV ? WinColors.success : WinColors.warn)),
          ]),
          const SizedBox(height: 4),
          WinProgressBar(mineV.clamp(0, 100).toDouble(), color: WinColors.teal600, height: 6),
          Text(ref, style: WinType.labelS(s.onMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.benchTitle, style: WinType.titleM(s.onStrong)),
        Text(l.benchSub(d.percentile), style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row(s, l.benchAverage, _on20(d.avg), l.benchNational(_on20(d.nationalAvg)), d.avg, d.nationalAvg),
            _row(s, l.benchPassRate, '${d.passRate.round()} %', l.benchNational('${d.nationalPassRate.round()} %'), d.passRate,
                d.nationalPassRate),
            _row(s, l.benchEngagement, '${d.engagement.round()} %', l.benchNational('${d.peerEngagement.round()} %'),
                d.engagement, d.peerEngagement),
            if (d.strongest != null || d.weakest != null) const SizedBox(height: 4),
            if (d.strongest != null)
              Row(children: [
                const Icon(PhosphorIconsRegular.trendUp, size: 16, color: WinColors.success),
                const SizedBox(width: 6),
                Expanded(child: Text(l.benchStrongest(d.strongest!), style: WinType.bodyS(s.onStrong))),
              ]),
            if (d.weakest != null)
              Row(children: [
                const Icon(PhosphorIconsRegular.trendDown, size: 16, color: WinColors.warn),
                const SizedBox(width: 6),
                Expanded(child: Text(l.benchWeakest(d.weakest!), style: WinType.bodyS(s.onStrong))),
              ]),
          ]),
        ),
      ]),
    );
  }
}
