import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Portée proposée par le serveur (classe, niveau, plateforme).
class PeerScope {
  final String scope;
  final String label;
  final bool available;
  const PeerScope(this.scope, this.label, this.available);
}

/// Ligne d'une matière : moyenne de l'élève, et celle du groupe s'il compte
/// au moins 5 pairs (sinon [reasonMessage]).
class PeerSubject {
  final int subjectId;
  final String name;
  final double? userAvg;
  final double? groupAvg;
  final int? percentile;
  final String? reason;
  final String? reasonMessage;
  const PeerSubject({
    required this.subjectId,
    required this.name,
    this.userAvg,
    this.groupAvg,
    this.percentile,
    this.reason,
    this.reasonMessage,
  });
}

/// Comparaison anonyme (GET /student/peer-comparison). Les moyennes sont des
/// scores de quiz en pourcentage (0 à 100), affichés sur 20. Un champ absent
/// vaut null (le serveur omet les champs nuls).
class ApiPeerComparison {
  final bool hasData;
  final String scope;
  final List<PeerScope> scopes;
  final String? groupLabel;
  final double? userAvg;
  final double? groupAvg;
  final int? percentile;
  final double? topAvg;
  final int sampleSize;
  final String? reason;
  final String? reasonMessage;
  final List<PeerSubject> subjects;

  const ApiPeerComparison({
    required this.hasData,
    this.scope = 'platform',
    this.scopes = const [],
    this.groupLabel,
    this.userAvg,
    this.groupAvg,
    this.percentile,
    this.topAvg,
    this.sampleSize = 0,
    this.reason,
    this.reasonMessage,
    this.subjects = const [],
  });

  static double? _d(Object? v) => (v as num?)?.toDouble();

  factory ApiPeerComparison.fromJson(Map<String, dynamic> j) {
    final d = j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;
    final group = d['group'] is Map ? d['group'] as Map : null;
    return ApiPeerComparison(
      hasData: d['hasData'] == true,
      scope: d['scope']?.toString() ?? 'platform',
      scopes: (d['availableScopes'] is List ? d['availableScopes'] as List : const [])
          .whereType<Map>()
          .map((s) => PeerScope('${s['scope'] ?? ''}', '${s['label'] ?? ''}', s['available'] == true))
          .where((s) => s.scope.isNotEmpty)
          .toList(),
      groupLabel: group?['label'] as String?,
      userAvg: _d(d['userAvg']),
      groupAvg: _d(d['groupAvg']) ?? _d(d['peerAvg']),
      percentile: (d['percentile'] as num?)?.toInt(),
      topAvg: _d(d['topPerformersAvg']),
      sampleSize: (d['sampleSize'] as num?)?.toInt() ?? 0,
      reason: d['reason'] as String?,
      reasonMessage: d['reasonMessage'] as String?,
      subjects: (d['subjects'] is List ? d['subjects'] as List : const [])
          .whereType<Map>()
          .map((s) => PeerSubject(
                subjectId: (s['subjectId'] as num?)?.toInt() ?? 0,
                name: '${s['name'] ?? ''}',
                userAvg: _d(s['userAvg']),
                groupAvg: _d(s['groupAvg']),
                percentile: (s['percentile'] as num?)?.toInt(),
                reason: s['reason'] as String?,
                reasonMessage: s['reasonMessage'] as String?,
              ))
          .where((s) => s.name.isNotEmpty)
          .toList(),
    );
  }

  /// Comparaison affichable : l'élève et le groupe ont une moyenne, et le
  /// groupe compte au moins 5 élèves (sinon elle ne serait plus anonyme).
  bool get comparable => hasData && userAvg != null && groupAvg != null && sampleSize >= 5;
}

/// Section « Parmi les élèves » de « Mes rapports » (lot 7), comme
/// PeerComparison du site : portée au choix (ma classe, mon niveau, tous les
/// élèves) quand le serveur la propose, deux barres à la même échelle, mot
/// neutre, détail par matière ; pas de rang, pas de rouge.
class PeerComparisonSection extends StatefulWidget {
  const PeerComparisonSection({super.key});

  /// Lecture remplaçable dans les tests. [scope] null : portée par défaut
  /// du serveur (toute la plateforme).
  static Future<ApiPeerComparison> Function({String? scope}) fetch = ({String? scope}) async {
    final res = await ApiClient.instance.dio
        .get('/student/peer-comparison', queryParameters: scope == null ? null : {'scope': scope});
    return ApiPeerComparison.fromJson(res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : const {});
  };

  @override
  State<PeerComparisonSection> createState() => _PeerComparisonSectionState();
}

class _PeerComparisonSectionState extends State<PeerComparisonSection> {
  ApiPeerComparison? _data;
  bool _error = false;
  bool _loading = false;
  String? _scope;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _loading = true;
    });
    try {
      final d = await PeerComparisonSection.fetch(scope: _scope);
      if (mounted) setState(() => _data = d);
    } catch (_) {
      if (mounted && _data == null) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _choose(String scope) {
    if (scope == (_data?.scope ?? _scope)) return;
    _scope = scope;
    _load();
  }

  /// Pourcentage (0 à 100) vers une note sur 20.
  static double _on20(double v) => v / 5;
  static String _f(double v) => _on20(v).toStringAsFixed(1);

  Widget _bar(WinScheme s, String label, double value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: WinType.labelM(s.onStrong))),
            Text('${_f(value)} / 20', style: WinType.labelM(s.onStrong)),
          ]),
          const SizedBox(height: 4),
          WinProgressBar(value.clamp(0, 100).toDouble(), color: color, height: 8),
        ]),
      );

  /// Phrase d'une raison : celle du serveur en français, sinon la nôtre.
  String _reason(AppLocalizations l, String? code, String? message) {
    if (L10n.locale.languageCode == 'fr' && (message ?? '').trim().isNotEmpty) return message!.trim();
    return switch (code) {
      'no_class' => l.peersNoClass,
      'no_level' => l.peersNoLevel,
      'group_too_small' => l.peersTooSmall,
      _ => l.peersNotEnough,
    };
  }

  String _scopeLabel(AppLocalizations l, PeerScope sc) => switch (sc.scope) {
        'platform' => l.peersScopePlatform,
        'level' => l.peersScopeLevel,
        _ => sc.label.isNotEmpty ? sc.label : l.peersScopeClass,
      };

  Widget _subjects(WinScheme s, AppLocalizations l, List<PeerSubject> subjects) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(l.peersSubjects, style: WinType.titleS(s.onStrong)),
          const SizedBox(height: 6),
          for (final x in subjects)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.name, style: WinType.labelM(s.onStrong)),
                Text(
                    x.groupAvg != null && x.userAvg != null
                        ? l.peersSubjectLine(_f(x.userAvg!), _f(x.groupAvg!))
                        : [
                            if (x.userAvg != null) l.peersSubjectYou(_f(x.userAvg!)),
                            _reason(l, x.reason, x.reasonMessage),
                          ].join(' · '),
                    style: WinType.bodyS(s.onMuted)),
              ]),
            ),
        ],
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
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (d.userAvg != null) Text(l.peersYourAverage(_f(d.userAvg!)), style: WinType.titleS(s.onStrong)),
        Text(_reason(l, d.reason, d.reasonMessage), style: WinType.bodyM(s.onMuted)),
        if (d.subjects.isNotEmpty) _subjects(s, l, d.subjects),
      ]);
    } else {
      // Écart en points sur 20 : moins d'un point, « proche ».
      final diff = _on20(d.userAvg!) - _on20(d.groupAvg!);
      final position = diff.abs() < 1
          ? l.peersClose
          : diff > 0
              ? l.peersAbove
              : l.peersBelow;
      final groupName = d.scope == 'platform' || d.groupLabel == null ? null : d.groupLabel;
      body = WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(PhosphorIconsRegular.usersThree, color: s.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(position, style: WinType.titleM(s.onStrong))),
          ]),
          const SizedBox(height: 14),
          _bar(s, l.peersYou, d.userAvg!, WinColors.teal600),
          _bar(s, groupName == null ? l.peersAverage : l.peersGroupAverage(groupName), d.groupAvg!, s.outline2),
          if (d.topAvg != null) Text(l.peersTop(_f(d.topAvg!)), style: WinType.labelM(s.onMuted)),
          if ((d.percentile ?? 0) > 50) ...[
            const SizedBox(height: 6),
            Text(l.peersBetterThan(d.percentile!), style: WinType.bodyS(s.onMuted)),
          ],
          if (d.subjects.isNotEmpty) _subjects(s, l, d.subjects),
        ]),
      );
    }
    final scopes = d?.scopes ?? const <PeerScope>[];
    final current = d?.scope ?? _scope;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.peersTitle, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 2),
      Text(
          d == null || !d.comparable
              ? l.peersScopeGeneric
              : d.scope == 'platform'
                  ? l.peersScope(d.sampleSize)
                  : l.peersScopeGroup(d.sampleSize),
          style: WinType.bodyS(s.onMuted)),
      if (scopes.length > 1) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final sc in scopes)
            Opacity(
              opacity: sc.available ? 1 : 0.45,
              child: WinChip(_scopeLabel(l, sc),
                  active: sc.scope == current, onTap: sc.available && !_loading ? () => _choose(sc.scope) : null),
            ),
        ]),
      ],
      const SizedBox(height: 10),
      body,
    ]);
  }
}
