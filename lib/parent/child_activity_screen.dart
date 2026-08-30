import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'encouragement_sheet.dart';

class ChildActivityScreen extends StatefulWidget {
  final ApiChild child;
  const ChildActivityScreen({super.key, required this.child});
  @override
  State<ChildActivityScreen> createState() => _ChildActivityScreenState();
}

class _ChildActivityScreenState extends State<ChildActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  ApiChildStats? _stats;
  List<ApiChildActivity>? _activities;
  List<ApiWinAIAlert> _childAlerts = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stats = await ParentService.instance.getChildStats(widget.child.id);
    final activities =
        await ParentService.instance.getChildActivity(widget.child.id);
    final allAlerts = await ParentService.instance.getAlerts();
    if (mounted)
      setState(() {
        _stats = stats;
        _activities = activities;
        _childAlerts =
            allAlerts.where((a) => a.childId == widget.child.id).toList();
      });
  }

  EngagementScore get _engScore {
    final id = 'k${widget.child.id}';
    return WinData.engagementScores.firstWhere(
      (e) => e.childId == id,
      orElse: () => const EngagementScore('fallback', 72, 64, 'up'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          WinAvatar(widget.child.fullName, size: 32),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.child.firstName, style: WinType.headlineS(s.onStrong)),
            if (widget.child.level != null && widget.child.level!.isNotEmpty)
              Text(widget.child.level!, style: WinType.labelS(s.onMuted)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() {
                _stats = null;
                _activities = null;
              });
              _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: s.primary,
          unselectedLabelColor: s.onFaint,
          indicatorColor: s.primary,
          labelStyle: WinType.manrope(size: 13, weight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Activité'),
            Tab(text: 'Résultats'),
            Tab(text: 'Alertes WinAI'),
          ],
        ),
      ),
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _ActivityTab(
                  stats: _stats!,
                  activities: _activities ?? [],
                  engScore: _engScore,
                ),
                _ResultsTab(child: widget.child),
                _AlertsTab(
                    alerts: _childAlerts, childName: widget.child.firstName),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Expanded(
              child: WinButton(
                'Voir ressources',
                variant: WinButtonVariant.ghost,
                small: true,
                icon: Icons.library_books_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Catalogue filtré pour ${widget.child.firstName}')),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WinButton(
                'Générer un quiz',
                variant: WinButtonVariant.outline,
                small: true,
                icon: Icons.quiz_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Quiz en cours de génération...')),
                ),
              ),
            ),
            const SizedBox(width: 8),
            WinButton(
              'Encourager',
              variant: WinButtonVariant.secondary,
              small: true,
              onTap: () => EncouragementSheet.show(
                context,
                widget.child,
                childScore: _stats?.averageScore.round(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---- Tab Activité ----

class _ActivityTab extends StatelessWidget {
  final ApiChildStats stats;
  final List<ApiChildActivity> activities;
  final EngagementScore engScore;
  const _ActivityTab(
      {required this.stats, required this.activities, required this.engScore});

  // minutes×10 mock, Lun–Dim
  static const _sessionBars = [50, 70, 40, 80, 60, 30, 0];
  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final delta = engScore.score - engScore.prevScore;
    final deltaLabel =
        delta >= 0 ? '+$delta cette semaine' : '$delta cette semaine';
    final scoreColor = engScore.score >= 70
        ? WinColors.success
        : engScore.score >= 50
            ? WinColors.warn
            : WinColors.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Score engagement
        Center(
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: engScore.score / 100,
                  strokeWidth: 10,
                  backgroundColor: s.outline2,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${engScore.score}',
                  style: WinType.archivo(
                      size: 32, weight: FontWeight.w700, color: s.onStrong),
                ),
                Text('/100', style: WinType.labelS(s.onMuted)),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                engScore.trend == 'up'
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 16,
                color: engScore.trend == 'up'
                    ? WinColors.success
                    : WinColors.error,
              ),
              const SizedBox(width: 4),
              Text(deltaLabel,
                  style: WinType.labelM(engScore.trend == 'up'
                      ? WinColors.success
                      : WinColors.error)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        // Stats boxes
        Row(children: [
          Expanded(
              child: _StatBox(
                  icon: Icons.download_outlined,
                  value: '${stats.downloadsThisWeek}',
                  label: 'Téléch./sem.',
                  color: WinColors.blue500)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.trending_up,
                  value: '${stats.averageScore.round()}%',
                  label: 'Score moy.',
                  color: s.primary)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.quiz_outlined,
                  value: '${stats.quizzesThisWeek}',
                  label: 'Quiz/sem.',
                  color: WinColors.success)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.auto_awesome_outlined,
                  value: '${stats.aiSessionsThisWeek}',
                  label: 'IA/sem.',
                  color: s.secondary)),
        ]),
        const SizedBox(height: 24),
        Text('Sessions cette semaine', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        WinCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val = _sessionBars[i];
              final maxH = 60.0;
              final h = val == 0 ? 4.0 : (val / 80.0) * maxH;
              return Expanded(
                child: Column(children: [
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: val == 0
                          ? s.outline2
                          : s.primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_dayLabels[i], style: WinType.labelS(s.onMuted)),
                ]),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Text('Activité récente', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Text('Aucune activité récente.', style: WinType.bodyM(s.onMuted))
        else
          ...activities.take(10).toList().asMap().entries.map((e) {
            final ev = e.value;
            final isLast = e.key == activities.take(10).length - 1;
            final Color dot = switch (ev.type) {
              'quiz' => s.primary,
              'download' => WinColors.blue500,
              'ai_chat' => WinColors.teal500,
              _ => s.onFaint,
            };
            final IconData icon = switch (ev.type) {
              'quiz' => Icons.quiz_outlined,
              'download' => Icons.download_outlined,
              'ai_chat' => Icons.auto_awesome_outlined,
              _ => Icons.circle_outlined,
            };
            return IntrinsicHeight(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: dot, shape: BoxShape.circle)),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: s.outline2)),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(ev.description,
                                style: WinType.titleM(s.onStrong)),
                            Text(_fmtDate(ev.occurredAt),
                                style: WinType.labelM(s.onMuted)),
                          ])),
                      if (ev.score != null)
                        WinBadge('${ev.score}/20', color: BadgeColor.success),
                      const SizedBox(width: 4),
                      Icon(icon, size: 16, color: dot),
                    ]),
                  ),
                ),
              ]),
            );
          }),
      ],
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}

// ---- Tab Résultats ----

class _ResultsTab extends StatelessWidget {
  final ApiChild child;
  const _ResultsTab({required this.child});

  // Per-child subject scores keyed by child id → subject id → score%
  static const Map<int, Map<String, int>> _childScores = {
    1: {'math': 82, 'pc': 74, 'chimie': 61, 'fr': 88},
    2: {'math': 91, 'pc': 85, 'chimie': 78, 'fr': 70},
    3: {'math': 55, 'pc': 62, 'chimie': 48, 'fr': 71},
  };

  // Per-child last quiz: title, score label, badge%
  static const Map<int, (String, String, int)> _lastQuiz = {
    1: ('Quiz Maths · 4/5', '80%', 80),
    2: ('Quiz PC · 5/5', '100%', 100),
    3: ('Quiz Chimie · 2/5', '40%', 40),
  };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final scores = _childScores[child.id] ?? _childScores[1]!;
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sortedEntries.first;
    final worst = sortedEntries.last;
    final quiz = _lastQuiz[child.id] ?? _lastQuiz[1]!;
    final quizBadgeColor = quiz.$3 >= 70
        ? BadgeColor.success
        : quiz.$3 >= 50
            ? BadgeColor.warn
            : BadgeColor.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Score moyen par matière', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 16),
        WinCard(
          child: Column(
            children: sortedEntries.map((entry) {
              final subj = WinData.subjectById(entry.key);
              final pct = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(subj.icon, size: 15, color: subj.color),
                        const SizedBox(width: 6),
                        Text(subj.short, style: WinType.labelM(s.onStrong)),
                        const Spacer(),
                        Text('$pct%',
                            style:
                                WinType.archivo(size: 14, color: subj.color)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: s.outline2,
                          valueColor: AlwaysStoppedAnimation(subj.color),
                        ),
                      ),
                    ]),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: WinCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.emoji_events, size: 14, color: WinColors.gold),
                      const SizedBox(width: 4),
                      Text('Meilleure matière', style: WinType.labelS(s.onMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Text(WinData.subjectById(best.key).short,
                        style: WinType.titleM(s.onStrong)),
                    Text('${best.value}%',
                        style: WinType.archivo(
                            size: 18, color: WinColors.success)),
                  ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: WinCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: WinColors.warn),
                      const SizedBox(width: 4),
                      Text('À travailler', style: WinType.labelS(s.onMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Text(WinData.subjectById(worst.key).short,
                        style: WinType.titleM(s.onStrong)),
                    Text('${worst.value}%',
                        style:
                            WinType.archivo(size: 18, color: WinColors.warn)),
                  ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        WinCard(
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WinColors.successBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.quiz_outlined,
                  size: 20, color: WinColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dernier quiz', style: WinType.labelM(s.onMuted)),
                    const SizedBox(height: 2),
                    Text('${quiz.$1}  ${quiz.$2}',
                        style: WinType.titleM(s.onStrong)),
                  ]),
            ),
            WinBadge(quiz.$2, color: quizBadgeColor),
          ]),
        ),
      ],
    );
  }
}

// ---- Tab Alertes WinAI ----

class _AlertsTab extends StatelessWidget {
  final List<ApiWinAIAlert> alerts;
  final String childName;
  const _AlertsTab({required this.alerts, required this.childName});

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    if (alerts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline, size: 48, color: WinColors.success),
          const SizedBox(height: 12),
          Text(
            'Tout va bien !',
            style: WinType.titleM(s.onStrong),
          ),
          const SizedBox(height: 4),
          Text(
            '$childName est régulier(e) dans ses révisions.',
            style: WinType.bodyM(s.onMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Alertes WinAI', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        ...alerts.map((a) {
          final BadgeColor badgeColor = switch (a.type) {
            'danger' => BadgeColor.error,
            'warning' => BadgeColor.warn,
            'tip' => BadgeColor.blue,
            _ => BadgeColor.blue,
          };
          final Color iconColor = switch (a.type) {
            'danger' => WinColors.error,
            'warning' => WinColors.warn,
            'tip' => WinColors.blue500,
            _ => WinColors.blue500,
          };
          final IconData icon = switch (a.type) {
            'danger' => Icons.error_outline,
            'warning' => Icons.warning_amber_outlined,
            'tip' => Icons.lightbulb_outline,
            _ => Icons.info_outline,
          };
          final String badgeLabel = switch (a.type) {
            'danger' => 'Alerte',
            'warning' => 'Attention',
            'tip' => 'Conseil',
            _ => 'Info',
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WinCard(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          WinBadge(badgeLabel, color: badgeColor),
                          const Spacer(),
                          Text(_relTime(a.createdAt),
                              style: WinType.labelS(s.onFaint)),
                        ]),
                        const SizedBox(height: 6),
                        Text(a.message, style: WinType.bodyS(s.onMuted)),
                      ]),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ---- Shared widget ----

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: WinType.archivo(
                size: 16, weight: FontWeight.w700, color: s.onStrong)),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    );
  }
}
