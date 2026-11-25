import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Comparaison anonyme (GET /student/peer-comparison) : moyenne des scores
/// quotidiens des 30 derniers jours, sur 20, face à celle des autres élèves
/// actifs de la plateforme.
class ApiPeerComparison {
  final bool hasData;
  final double userAvg;
  final double peerAvg;
  final int percentile;
  final double topAvg;
  final int sampleSize;

  const ApiPeerComparison({
    required this.hasData,
    this.userAvg = 0,
    this.peerAvg = 0,
    this.percentile = 0,
    this.topAvg = 0,
    this.sampleSize = 0,
  });

  factory ApiPeerComparison.fromJson(Map<String, dynamic> j) {
    final d = j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;
    return ApiPeerComparison(
      hasData: d['hasData'] == true,
      userAvg: (d['userAvg'] as num?)?.toDouble() ?? 0,
      peerAvg: (d['peerAvg'] as num?)?.toDouble() ?? 0,
      percentile: (d['percentile'] as num?)?.toInt() ?? 0,
      topAvg: (d['topPerformersAvg'] as num?)?.toDouble() ?? 0,
      sampleSize: (d['sampleSize'] as num?)?.toInt() ?? 0,
    );
  }

  /// En dessous de 5 élèves, la comparaison n'a pas de sens (et ne serait
  /// plus vraiment anonyme).
  bool get comparable => hasData && sampleSize >= 5;
}

/// Section « Parmi les élèves » de « Mes rapports » (lot 7), comme
/// PeerComparison du site : deux barres à la même échelle (20 = pleine
/// largeur), chiffres écrits, mot neutre (au-dessus, proche, en dessous de la
/// moyenne) ; pas de rang, pas de rouge.
class PeerComparisonSection extends StatefulWidget {
  const PeerComparisonSection({super.key});

  /// Lecture remplaçable dans les tests.
  static Future<ApiPeerComparison> Function() fetch = () async {
    final res = await ApiClient.instance.dio.get('/student/peer-comparison');
    return ApiPeerComparison.fromJson(res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : const {});
  };

  @override
  State<PeerComparisonSection> createState() => _PeerComparisonSectionState();
}

class _PeerComparisonSectionState extends State<PeerComparisonSection> {
  ApiPeerComparison? _data;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final d = await PeerComparisonSection.fetch();
      if (mounted) setState(() => _data = d);
    } catch (_) {
      if (mounted && _data == null) setState(() => _error = true);
    }
  }

  static String _f(double v) => v.toStringAsFixed(1);

  Widget _bar(WinScheme s, String label, double value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: WinType.labelM(s.onStrong))),
            Text('${_f(value)} / 20', style: WinType.labelM(s.onStrong)),
          ]),
          const SizedBox(height: 4),
          WinProgressBar((value / 20 * 100).clamp(0, 100).toDouble(), color: color, height: 8),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget body;
    final d = _data;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (d == null) {
      body = const WinLoading();
    } else if (!d.comparable) {
      body = Text(l.peersNotEnough, style: WinType.bodyM(s.onMuted));
    } else {
      final diff = d.userAvg - d.peerAvg;
      final position = diff.abs() < 1
          ? l.peersClose
          : diff > 0
              ? l.peersAbove
              : l.peersBelow;
      body = WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(PhosphorIconsRegular.usersThree, color: s.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(position, style: WinType.titleM(s.onStrong))),
          ]),
          const SizedBox(height: 14),
          _bar(s, l.peersYou, d.userAvg, WinColors.teal600),
          _bar(s, l.peersAverage, d.peerAvg, s.outline2),
          Text(l.peersTop(_f(d.topAvg)), style: WinType.labelM(s.onMuted)),
          if (d.percentile > 50) ...[
            const SizedBox(height: 6),
            Text(l.peersBetterThan(d.percentile), style: WinType.bodyS(s.onMuted)),
          ],
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.peersTitle, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 2),
      Text(d != null && d.comparable ? l.peersScope(d.sampleSize) : l.peersScopeGeneric,
          style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 10),
      body,
    ]);
  }
}
