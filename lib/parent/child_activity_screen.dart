import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import 'album_tab.dart';
import 'encouragement_sheet.dart';
import 'exam_watch_mode_tab.dart';
import 'goal_proposal_tab.dart';
import 'portfolio_tab.dart';

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
  List<ApiPersistedAlert> _childAlerts = [];
  ApiChildSubjectScores? _subjectScores;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Avant : aucune gestion d'erreur ici  une exception (réseau, 500…)
    // laissait l'écran bloqué indéfiniment sur son indicateur de chargement.
    try {
      final stats = await ParentService.instance.getChildStats(widget.child.id);
      final activities =
          await ParentService.instance.getChildActivity(widget.child.id);
      final alerts =
          await ParentService.instance.getPersistedAlerts(widget.child.id);
      final subjectScores =
          await ParentService.instance.getChildSubjectScores(widget.child.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _activities = activities;
          _childAlerts = alerts;
          _subjectScores = subjectScores;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // _stats == null est le signal de chargement du build() ci-dessous
          // (L116)  lui donner une valeur, même vide, permet à l'écran de
          // sortir de l'état "chargement" au lieu d'y rester bloqué.
          _stats = const ApiChildStats();
          _activities = _activities ?? [];
          _childAlerts = [];
          _subjectScores = const ApiChildSubjectScores(subjects: []);
        });
      }
    }
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
          isScrollable: true,
          labelColor: s.primary,
          unselectedLabelColor: s.onFaint,
          indicatorColor: s.primary,
          labelStyle: WinType.manrope(size: 13, weight: FontWeight.w600),
          tabs: [
            Tab(text: context.l10n.parentChildTabActivity),
            Tab(text: context.l10n.studentQuizResults),
            Tab(text: context.l10n.parentChildTabGoals),
            Tab(text: context.l10n.parentChildTabExamWatch),
            Tab(text: context.l10n.parentChildTabPortrait),
            Tab(text: context.l10n.parentChildTabAlbum),
            Tab(text: context.l10n.commonWinaiAlerts),
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
                ),
                _ResultsTab(
                    scores: _subjectScores ??
                        const ApiChildSubjectScores(subjects: [])),
                GoalProposalTab(child: widget.child),
                ExamWatchModeTab(child: widget.child),
                PortfolioTab(child: widget.child),
                AlbumTab(child: widget.child),
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
                context.l10n.parentChildSeeResources,
                variant: WinButtonVariant.ghost,
                small: true,
                icon: Icons.library_books_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          context.l10n.parentChildCatalogFiltered(widget.child.firstName))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WinButton(
                context.l10n.parentChildGenerateQuiz,
                variant: WinButtonVariant.outline,
                small: true,
                icon: Icons.quiz_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(context.l10n.parentChildQuizGenerating)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            WinButton(
              context.l10n.parentChildEncourage,
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
  const _ActivityTab({required this.stats, required this.activities});

  /// Nombre d'activités (téléchargements/quiz/sessions IA) par jour de la
  /// semaine, sur les 7 derniers jours  dérivé de la vraie activité
  /// (ApiChildActivity.occurredAt) plutôt que d'une barre codée en dur.
  List<int> _weekCounts() {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    for (final a in activities) {
      if (a.occurredAt.isBefore(weekAgo)) continue;
      counts[a.occurredAt.weekday - 1]++;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final scoreColor = stats.averageScore >= 70
        ? WinColors.success
        : stats.averageScore >= 50
            ? WinColors.warn
            : WinColors.error;
    final weekCounts = _weekCounts();
    final maxCount =
        weekCounts.isEmpty ? 0 : weekCounts.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Score moyen (30 derniers jours, QuizAttempts  donnée réelle,
        // remplace l'ancien "score d'engagement" entièrement simulé).
        Center(
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: (stats.averageScore / 100).clamp(0, 1),
                  strokeWidth: 10,
                  backgroundColor: s.outline2,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${stats.averageScore.round()}',
                  style: WinType.archivo(
                      size: 32, weight: FontWeight.w700, color: s.onStrong),
                ),
                Text('/100', style: WinType.labelS(s.onMuted)),
              ]),
            ]),
            const SizedBox(height: 10),
            Text(context.l10n.parentChildAvgScore30, style: WinType.labelM(s.onMuted)),
          ]),
        ),
        const SizedBox(height: 24),
        // Stats boxes
        Row(children: [
          Expanded(
              child: _StatBox(
                  icon: Icons.download_outlined,
                  value: '${stats.downloadsThisWeek}',
                  label: context.l10n.parentChildDownloadsWeek,
                  color: WinColors.blue500)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.trending_up,
                  value: '${stats.averageScore.round()}%',
                  label: context.l10n.parentChildAvgScoreShort,
                  color: s.primary)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.quiz_outlined,
                  value: '${stats.quizzesThisWeek}',
                  label: context.l10n.parentChildQuizWeek,
                  color: WinColors.success)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatBox(
                  icon: Icons.auto_awesome_outlined,
                  value: '${stats.aiSessionsThisWeek}',
                  label: context.l10n.parentChildAiWeek,
                  color: s.secondary)),
        ]),
        const SizedBox(height: 24),
        Text(context.l10n.parentChildActivityWeek, style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        WinCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val = weekCounts[i];
              const maxH = 60.0;
              final h =
                  val == 0 || maxCount == 0 ? 4.0 : (val / maxCount) * maxH;
              return Expanded(
                child: Column(children: [
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: val == 0
                          ? s.outline2
                          : s.primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(WinRadii.full),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(WinFormat.weekdayShortCap(i + 1), style: WinType.labelS(s.onMuted)),
                ]),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.parentChildRecentActivity, style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Text(context.l10n.parentChildNoRecentActivity, style: WinType.bodyM(s.onMuted))
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
    if (diff.inMinutes < 1) return L10n.current.studentNotifJustNow;
    if (diff.inMinutes < 60) return L10n.current.studentNotifMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return L10n.current.studentNotifHoursAgo(diff.inHours);
    return L10n.current.parentDaysAgo(diff.inDays);
  }
}

// ---- Tab Résultats ----

class _ResultsTab extends StatelessWidget {
  final ApiChildSubjectScores scores;
  const _ResultsTab({required this.scores});

  Color _scoreColor(double pct) => pct >= 70
      ? WinColors.success
      : pct >= 50
          ? WinColors.warn
          : WinColors.error;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subjects = [...scores.subjects]
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
    final quiz = scores.lastQuiz;

    if (subjects.isEmpty && quiz == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: s.onFaint),
            const SizedBox(height: 12),
            Text(context.l10n.parentChildNoResults,
                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final best = subjects.isNotEmpty ? subjects.first : null;
    final worst = subjects.isNotEmpty ? subjects.last : null;
    final quizPct = quiz?.scorePercent ?? 0;
    final quizBadgeColor = quizPct >= 70
        ? BadgeColor.success
        : quizPct >= 50
            ? BadgeColor.warn
            : BadgeColor.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (subjects.isNotEmpty) ...[
          Text(context.l10n.parentChildScoreBySubject,
              style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 16),
          WinCard(
            child: Column(
              children: subjects.map((entry) {
                final color = _scoreColor(entry.averageScore);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.menu_book_outlined,
                              size: 15, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(entry.subjectTitle,
                                  style: WinType.labelM(s.onStrong))),
                          Text('${entry.averageScore.round()}%',
                              style: WinType.archivo(size: 14, color: color)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(WinRadii.full),
                          child: LinearProgressIndicator(
                            value: (entry.averageScore / 100).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: s.outline2,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (best != null && worst != null && subjects.length > 1)
          Row(children: [
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.emoji_events,
                            size: 14, color: WinColors.gold),
                        const SizedBox(width: 4),
                        Text(context.l10n.parentChildBestSubject,
                            style: WinType.labelS(s.onMuted)),
                      ]),
                      const SizedBox(height: 4),
                      Text(best.subjectTitle,
                          style: WinType.titleM(s.onStrong)),
                      Text('${best.averageScore.round()}%',
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
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: WinColors.warn),
                        const SizedBox(width: 4),
                        Text(context.l10n.parentChildToWorkOn, style: WinType.labelS(s.onMuted)),
                      ]),
                      const SizedBox(height: 4),
                      Text(worst.subjectTitle,
                          style: WinType.titleM(s.onStrong)),
                      Text('${worst.averageScore.round()}%',
                          style:
                              WinType.archivo(size: 18, color: WinColors.warn)),
                    ]),
              ),
            ),
          ]),
        if (quiz != null) ...[
          const SizedBox(height: 16),
          WinCard(
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WinColors.successBg,
                  borderRadius: BorderRadius.circular(WinRadii.sm),
                ),
                child: const Icon(Icons.quiz_outlined,
                    size: 20, color: WinColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.parentChildLastQuiz, style: WinType.labelM(s.onMuted)),
                      const SizedBox(height: 2),
                      Text(
                          '${quiz.title} · ${quiz.correctAnswers}/${quiz.totalQuestions}',
                          style: WinType.titleM(s.onStrong)),
                    ]),
              ),
              WinBadge('${quiz.scorePercent.round()}%', color: quizBadgeColor),
            ]),
          ),
        ],
      ],
    );
  }
}

// ---- Tab Alertes WinAI ----

class _AlertsTab extends StatelessWidget {
  final List<ApiPersistedAlert> alerts;
  final String childName;
  const _AlertsTab({required this.alerts, required this.childName});

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return L10n.current.studentNotifJustNow;
    if (diff.inMinutes < 60) return L10n.current.studentNotifMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return L10n.current.studentNotifHoursAgo(diff.inHours);
    return L10n.current.parentDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    if (alerts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline,
              size: 48, color: WinColors.success),
          const SizedBox(height: 12),
          Text(
            context.l10n.parentChildAllGood,
            style: WinType.titleM(s.onStrong),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.parentChildRegular(childName),
            style: WinType.bodyM(s.onMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(context.l10n.commonWinaiAlerts, style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        ...alerts.map((a) {
          // Sévérité (Low/Medium/High), pas le type de signal, porte le niveau de gravité.
          final BadgeColor badgeColor = switch (a.severity) {
            'High' => BadgeColor.error,
            'Medium' => BadgeColor.warn,
            _ => BadgeColor.blue,
          };
          final Color iconColor = switch (a.severity) {
            'High' => WinColors.error,
            'Medium' => WinColors.warn,
            _ => WinColors.blue500,
          };
          final IconData icon = switch (a.severity) {
            'High' => Icons.error_outline,
            'Medium' => Icons.warning_amber_outlined,
            _ => Icons.info_outline,
          };
          final String badgeLabel = switch (a.severity) {
            'High' => context.l10n.parentAlertBadgeHigh,
            'Medium' => context.l10n.parentAlertBadgeMedium,
            _ => context.l10n.parentAlertBadgeInfo,
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
                          Text(_relTime(a.detectedAt),
                              style: WinType.labelS(s.onFaint)),
                        ]),
                        const SizedBox(height: 6),
                        Text(a.content, style: WinType.bodyS(s.onMuted)),
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
