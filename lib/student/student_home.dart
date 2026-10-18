import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/achievement_service.dart';
import '../services/student_service.dart';
import '../services/subject_service.dart';
import '../services/user_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_motion_widgets.dart';
import '../widgets/win_widgets.dart';
import 'content_detail_screen.dart';
import 'pending_goals_panel.dart';

String _fmtDate(DateTime d) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche'
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre'
  ];
  final day = days[d.weekday - 1];
  return '${day[0].toUpperCase()}${day.substring(1)} ${d.day} ${months[d.month - 1]} ${d.year}';
}

/// ===================== ACCUEIL ÉTUDIANT =====================
class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});
  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  ApiUserProfile? _profile;

  // Dashboard étudiant branché sur StudentController.cs réel (stats,
  // contenus en cours, prochaines échéances) et sur le streak et les badges
  // réels (AchievementService). `null` tant que non chargé : la valeur est
  // affichée « — » et les listes vides masquent leur section. Plus aucune
  // donnée de démonstration (WinData) : les recommandations WinAI et le flux
  // d'activité, sans endpoint serveur, ne sont plus affichés.
  ApiStudentStats? _stats;
  List<InProgressContent>? _continueLearning;
  List<ExamCountdown>? _upcomingEvents;
  int? _streak;
  int? _badges;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDashboard();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.instance.getProfile();
      if (mounted) {
        setState(() => _profile = p);
      }
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    try {
      final stats = await StudentService.instance.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
    try {
      final cont = await StudentService.instance.getContinueLearning();
      if (mounted) setState(() => _continueLearning = cont);
    } catch (_) {}
    try {
      final events =
          await StudentService.instance.getUpcomingEvents(limit: 3);
      if (mounted) setState(() => _upcomingEvents = events);
    } catch (_) {}
    try {
      final ach = await AchievementService.instance.getMyAchievements();
      if (mounted) {
        setState(() {
          _streak = ach.streak;
          _badges = ach.badges.where((b) => b.unlocked).length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    // Lot 9.7b : plus de palier (PlanTier) ; nom affiché tel que renvoyé
    // par le serveur, fonctions selon les droits.
    final sub = SubscriptionScope.of(context);

    final firstName = (_profile?.firstName ?? '').trim();
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12 ? 'Bonjour' : (hour < 18 ? 'Bon après-midi' : 'Bonsoir');

    final streakDays = _streak ?? 0;
    final avgScore =
        _stats != null ? '${_stats!.averageScore.round()}%' : '—';
    final weekHours = _stats != null
        ? '${_stats!.weeklyStudyHoursTotal.round()}h'
        : '—';
    final quizWeek =
        _stats != null ? '${_stats!.weeklyQuizCompleted}' : '—';
    final continueItems = _continueLearning ?? const <InProgressContent>[];
    final upcoming = _upcomingEvents ?? const <ExamCountdown>[];

    final String planLabel = sub.planName;
    final Color planColor = !sub.hasPlan
        ? WinColors.ink400
        : sub.has(EntitlementKeys.examCoach)
            ? WinColors.teal500
            : WinColors.blue500;

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // HERO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WinRadii.xl),
                  gradient: LinearGradient(
                      colors: [s.heroFrom, s.heroTo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_fmtDate(now),
                          style: WinType.labelS(WinColors.ink300)
                              .copyWith(letterSpacing: 0.8)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: planColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(WinRadii.full),
                            border: Border.all(
                                color: planColor.withValues(alpha: 0.4))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.workspace_premium_outlined,
                              size: 12, color: planColor),
                          const SizedBox(width: 4),
                          Text(planLabel,
                              style: WinType.manrope(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: planColor)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text.rich(TextSpan(
                        style: WinType.bodyL(WinColors.cream50),
                        children: [
                          TextSpan(
                              text: firstName.isEmpty
                                  ? '$greeting  '
                                  : '$greeting $firstName  '),
                          TextSpan(
                              text: '$streakDays jours',
                              style: WinType.archivo(
                                      size: 16, color: WinColors.teal400)
                                  .copyWith(fontStyle: FontStyle.italic)),
                          const TextSpan(text: " d'affilée !"),
                        ])),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _HeroStat(
                              value: WinStreakFlame(streakDays,
                                  light: true, size: 22),
                              title: "jours d'affilée",
                              sub: 'Streak')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _HeroStat(
                              value: Text(avgScore,
                                  style: WinType.archivo(
                                      size: 22, color: WinColors.teal400)),
                              title: 'score moyen',
                              sub: 'Cette semaine')),
                    ]),
                    const SizedBox(height: 10),
                    _HeroStat(
                      value: Text(weekHours,
                          style: WinType.archivo(
                              size: 22, color: WinColors.teal400)),
                      title: "d'étude cette semaine",
                      sub: 'Temps enregistré',
                    ),
                  ]),
            ),
            const SizedBox(height: 12),
            // Objectifs proposés par un parent, en attente de réponse
            const PendingGoalsPanel(),
            // UPGRADE BANNER  visible uniquement en plan Gratuit hors devMode
            if (!sub.hasPlan) _UpgradeBanner(s: s),
            const SizedBox(height: 4),
            // CHIPS
            SizedBox(
                height: 36,
                child:
                    ListView(scrollDirection: Axis.horizontal, children: const [
                  WinChip('Reprendre', icon: Icons.play_arrow_rounded),
                  SizedBox(width: 8),
                  WinChip('Mes Quiz', icon: Icons.check_circle_outline),
                  SizedBox(width: 8),
                  WinChip('Téléchargements', icon: Icons.download_outlined),
                ])),
            // 2.1  Continue Learning (contenus réellement commencés)
            if (continueItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionHeader("Continue où tu t'es arrêté"),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: continueItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _InProgressCard(item: continueItems[i]),
                ),
              ),
            ],
            // 2.3  Examens à venir (échéances réelles)
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionHeader('Examens à venir'),
              ...upcoming.take(2).map((exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExamCountdownCard(exam: exam),
                  )),
            ],
            // STATS
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: _StatCard(Icons.check_circle_outline,
                      quizWeek, 'Quiz / sem.')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(Icons.schedule, weekHours, 'Étude / sem.')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(Icons.emoji_events_outlined,
                      _badges != null ? '$_badges' : '—', 'Badges')),
            ]),
          ],
        ),
      ),
    ]);
  }
}

class _InProgressCard extends StatelessWidget {
  final InProgressContent item;
  const _InProgressCard({required this.item});

  /// Ouvre la vraie fiche du contenu (GET /subjects/{id}) : prix, niveau et
  /// droits viennent du serveur, jamais d'une fiche reconstituée localement.
  Future<void> _open(BuildContext context) async {
    final id = int.tryParse(item.contentId);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (id == null || id <= 0) return;
    try {
      final subject = await SubjectService.instance.getById(id);
      navigator.push(WinPageRoute(
          builder: (_) => ContentDetailScreen(content: subject.toContent())));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Ce contenu n'a pas pu être ouvert. Réessaie plus tard.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(item.subjectId);
    return SizedBox(
      width: 220,
      child: WinCard(
        padding: const EdgeInsets.all(12),
        onTap: () => _open(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(subj.icon, size: 18, color: subj.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.titleM(s.onStrong)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(item.lastOpened, style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 8),
          WinProgressBar(item.progressPct.toDouble(), height: 4),
          const SizedBox(height: 6),
          Row(children: [
            Text('${item.progressPct}%',
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Reprendre',
                  style: WinType.manrope(
                      size: 11, weight: FontWeight.w700, color: s.primary)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 11, color: s.primary),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _ExamCountdownCard extends StatelessWidget {
  final ExamCountdown exam;
  const _ExamCountdownCard({required this.exam});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(exam.subject);
    final urgentColor = exam.daysLeft <= 7 ? WinColors.error : s.primary;
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: subj.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WinRadii.sm)),
          child: Icon(subj.icon, size: 22, color: subj.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 2),
            Text('${subj.short} · ${exam.date}',
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${exam.daysLeft}',
              style: WinType.archivo(size: 28, color: urgentColor)),
          Text('jours', style: WinType.labelS(urgentColor)),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final Widget value;
  final String title, sub;
  const _HeroStat(
      {required this.value, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WinRadii.sm)),
      child: Row(children: [
        value,
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(title,
                  style: WinType.labelS(WinColors.cream100)
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(sub, style: WinType.labelS(WinColors.ink300)),
            ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatCard(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: s.primary),
        const SizedBox(height: 8),
        Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
        const SizedBox(height: 4),
        Text(label, style: WinType.labelM(s.onMuted)),
      ]),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final WinScheme s;
  const _UpgradeBanner({required this.s});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WinColors.teal50,
        borderRadius: BorderRadius.circular(WinRadii.sm),
        border: Border.all(color: WinColors.teal100),
      ),
      child: Row(children: [
        const Icon(Icons.bolt_outlined, size: 20, color: WinColors.teal600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Avec un abonnement, tout le catalogue s\'ouvre et WinAI vous accompagne davantage.',
            style: WinType.bodyS(WinColors.teal700)
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Voir',
                style: WinType.manrope(
                    size: 12,
                    weight: FontWeight.w700,
                    color: WinColors.teal600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_rounded,
                size: 12, color: WinColors.teal600),
          ]),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: WinType.archivo(size: 18, color: s.onStrong)),
    );
  }
}

/// Carte de contenu (catalogue).
class ContentCard extends StatefulWidget {
  final Content content;
  const ContentCard({super.key, required this.content});
  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  late bool _fav = widget.content.fav;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = widget.content;
    final subj = WinData.subjectById(content.subjectId);
    return WinCard(
      onTap: () => Navigator.push(context,
          WinPageRoute(builder: (_) => ContentDetailScreen(content: content))),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: Stack(fit: StackFit.expand, children: [
            Container(
              color: subj.color.withValues(alpha: 0.14),
              child:
                  Center(child: Icon(subj.icon, size: 40, color: subj.color)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(WinRadii.full),
                ),
                child: Text(contentTypeLabel(content.type),
                    style: WinType.labelS(Colors.white)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: WinFavoriteHeart(
                  active: _fav,
                  size: 16,
                  onTap: () => setState(() {
                    _fav = !_fav;
                    content.fav = _fav;
                  }),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: content.free ? WinColors.success : Colors.white,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                ),
                child: Text(
                    content.free ? 'Gratuit' : '${fmtXaf(content.price)} XAF',
                    style: WinType.labelS(
                            content.free ? Colors.white : WinColors.ink800)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.titleM(s.onStrong)),
              const Spacer(),
              Text('${subj.short} · ${content.level} · ${content.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.labelS(s.onMuted)),
            ]),
          ),
        ),
      ]),
    );
  }
}
