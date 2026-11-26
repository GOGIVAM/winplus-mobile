import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/chatbot_service.dart';
import '../services/session_manager.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Analyse WinAI des élèves d'un contenu (POST /teacher/class-analysis).
class ClassAnalysis {
  final double avgScore;
  final int students;
  final int excellent;
  final int good;
  final int struggling;
  final int atRisk;
  final List<(String, double)> hardest;
  final List<String> mistakes;
  final List<String> actions;

  const ClassAnalysis({
    this.avgScore = 0,
    this.students = 0,
    this.excellent = 0,
    this.good = 0,
    this.struggling = 0,
    this.atRisk = 0,
    this.hardest = const [],
    this.mistakes = const [],
    this.actions = const [],
  });

  static List<String> _l(Object? v) => (v is List ? v : const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

  factory ClassAnalysis.fromJson(Map j) {
    final d = j['data'] is Map ? j['data'] as Map : j;
    final m = d['mastery_distribution'] is Map ? d['mastery_distribution'] as Map : const {};
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    return ClassAnalysis(
      avgScore: (d['avg_score'] as num?)?.toDouble() ?? 0,
      students: i(d['student_count']),
      excellent: i(m['excellent']),
      good: i(m['good']),
      struggling: i(m['struggling']),
      atRisk: i(m['at_risk']),
      hardest: (d['hardest_questions'] is List ? d['hardest_questions'] as List : const [])
          .whereType<Map>()
          .map((q) => ('${q['topic'] ?? q['question_id'] ?? ''}', (q['wrong_answer_rate'] as num?)?.toDouble() ?? 0))
          .toList(),
      mistakes: _l(d['common_mistakes']),
      actions: _l(d['recommended_actions']),
    );
  }
}

/// « Analyse de classe » du professeur (lot 7), comme ClassAnalysis du
/// site : choisir un contenu publié, puis WinAI analyse ses élèves (niveau
/// moyen, répartition, questions les plus ratées, erreurs fréquentes,
/// actions conseillées). Débité sur la consommation WinAI.
class ClassAnalysisScreen extends StatefulWidget {
  const ClassAnalysisScreen({super.key});

  @override
  State<ClassAnalysisScreen> createState() => _ClassAnalysisScreenState();
}

class _ClassAnalysisScreenState extends State<ClassAnalysisScreen> {
  List<ApiPublishedContent>? _contents;
  ApiPublishedContent? _selected;
  ClassAnalysis? _data;
  bool _loading = false;
  bool _error = false;
  String? _refusal;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _error = false);
    try {
      final all = await TeacherService.instance.getMyContent();
      if (mounted) setState(() => _contents = all.where((c) => c.status == 'published').toList());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _analyse(ApiPublishedContent c) async {
    setState(() {
      _selected = c;
      _loading = true;
      _data = null;
      _refusal = null;
    });
    try {
      final teacherId = await SessionManager.getUserId();
      final res = await ApiClient.instance.dio
          .post('/teacher/class-analysis', data: {'teacher_id': teacherId, 'content_id': c.id});
      if (mounted) setState(() => _data = ClassAnalysis.fromJson(res.data is Map ? res.data as Map : const {}));
    } on DioException catch (e) {
      final body = e.response?.data;
      final map = body is Map ? body : null;
      final text = map?['error'] ?? map?['message'] ?? map?['detail'];
      if (mounted) {
        setState(() => _refusal = text is String && text.trim().isNotEmpty
            ? text.trim()
            : ChatbotService.quotaRefusalMessage(e.response?.statusCode, body) ?? context.l10n.commonLoadError);
      }
    } catch (_) {
      if (mounted) setState(() => _refusal = context.l10n.commonLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _list(WinScheme s, String title, IconData icon, List<String> items) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: s.primary),
            const SizedBox(width: 8),
            Text(title, style: WinType.titleS(s.onStrong)),
          ]),
          const SizedBox(height: 6),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('•  $t', style: WinType.bodyM(s.onStrong)),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final contents = _contents;
    final d = _data;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _loadContents);
    } else if (contents == null) {
      body = const WinLoading();
    } else if (contents.isEmpty) {
      body = WinEmptyState(icon: PhosphorIconsRegular.chartPie, title: l.canNoContentTitle, message: l.canNoContentText);
    } else {
      final total = d == null ? 0 : d.excellent + d.good + d.struggling + d.atRisk;
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Text(l.canIntro, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final c in contents)
            WinChip(c.title, active: _selected?.id == c.id, onTap: _loading ? null : () => _analyse(c)),
        ]),
        const SizedBox(height: 12),
        if (_loading) const WinLoading(),
        if (_refusal != null) WinAlert(_refusal!, type: BadgeColor.warn),
        if (d != null) ...[
          Row(children: [
            Expanded(
                child: WinStatCard('${(d.avgScore / 5).toStringAsFixed(1)} / 20', l.canAverage,
                    icon: PhosphorIconsRegular.chartBar)),
            const SizedBox(width: 10),
            Expanded(child: WinStatCard('${d.students}', l.canStudents, icon: PhosphorIconsRegular.users)),
          ]),
          if (total > 0) ...[
            const SizedBox(height: 16),
            Text(l.canMastery, style: WinType.titleS(s.onStrong)),
            const SizedBox(height: 8),
            for (final (label, n, color) in [
              (l.canExcellent, d.excellent, WinColors.success),
              (l.canGood, d.good, WinColors.teal600),
              (l.canStruggling, d.struggling, WinColors.warn),
              (l.canAtRisk, d.atRisk, WinColors.error),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 110, child: Text(label, style: WinType.labelM(s.onMuted))),
                  Expanded(child: WinProgressBar(n / total * 100, color: color, height: 8)),
                  SizedBox(width: 32, child: Text('$n', textAlign: TextAlign.end, style: WinType.labelM(s.onStrong))),
                ]),
              ),
          ],
          if (d.hardest.isNotEmpty)
            _list(s, l.canHardest, PhosphorIconsRegular.warningCircle,
                [for (final q in d.hardest) l.canWrongRate(q.$1, q.$2.round())]),
          if (d.mistakes.isNotEmpty) _list(s, l.canMistakes, PhosphorIconsRegular.xCircle, d.mistakes),
          if (d.actions.isNotEmpty) _list(s, l.canActions, PhosphorIconsRegular.lightbulb, d.actions),
        ],
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.canTitle)),
      body: SafeArea(child: body),
    );
  }
}
