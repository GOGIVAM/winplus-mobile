import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/achievement_service.dart';
import '../services/student_service.dart';
import '../services/subject_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_motion_widgets.dart';
import '../widgets/win_widgets.dart';
import 'content_detail_screen.dart';
import 'pending_goals_panel.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../shell/shell_nav.dart';
import '../widgets/mobile_home.dart';
import '../shared/subscription/pricing_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import 'achievements_screen.dart';
import 'certificates_screen.dart';
import 'download_history_screen.dart';
import 'exam_coach_screen.dart';
import 'favorites_screen.dart';
import 'my_courses_screen.dart';
import 'quiz_revision_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import 'student_reports_screen.dart';
import 'study_groups_screen.dart';
import 'study_session_screen.dart';
import 'tutors/my_tutor_bookings_screen.dart';
import 'tutors/tutor_search_screen.dart';

/// ===================== ACCUEIL ÉTUDIANT =====================
class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});
  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
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
    _loadDashboard();
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

  /// Reprend le contenu ouvert le plus récemment ; sans contenu commencé,
  /// l'historique des épreuves et quiz.
  void _resume() {
    final items = _continueLearning ?? const <InProgressContent>[];
    if (items.isNotEmpty) {
      _openContent(context, items.first);
    } else {
      _push(const DownloadHistoryScreen());
    }
  }

  void _push(Widget screen) =>
      Navigator.push(context, WinPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final upcoming = _upcomingEvents ?? const <ExamCountdown>[];
    final st = _stats;
    final started = _continueLearning ?? const <InProgressContent>[];

    return MobileHomeView(
      onRefresh: _loadDashboard,
      search: MobileSearchBar(
        hint: l.mobileHomeSearchPaper,
        onSubmit: (q) => _push(SearchScreen(initialQuery: q)),
        onFilters: () => ShellNav.go(context, 1),
      ),
      forYou: MobileForYou(slides: [
        MobileSlide(
            tag: l.mobileHomeEyebrow,
            title: l.mobileHomeStudentTitle,
            meta: l.mobileHomeStudentMeta,
            cta: l.mobileHomeStudentCta,
            onCta: () => _push(const StudySessionScreen()),
            image: 'assets/home/hero-eleve-confiance.webp'),
        MobileSlide(
            tag: l.mobileHomeResumeTag,
            title: l.mobileHomeResumeTitle,
            meta: started.isNotEmpty
                ? started.first.title
                : l.mobileHomeResumeMeta,
            cta: l.mobileHomeResumeCta,
            onCta: _resume,
            image: 'assets/home/epreuves.webp'),
        MobileSlide(
            tag: l.mobileHomeCoachTag,
            title: l.mobileHomeCoachTitle,
            meta: l.mobileHomeCoachMeta,
            cta: l.mobileHomeCoachCta,
            onCta: () => _push(const ExamCoachScreen()),
            image: 'assets/home/eleves-classe.jpg'),
        MobileSlide(
            tag: l.mobileHomePapersTag,
            title: l.mobileHomePapersTitle,
            meta: l.mobileHomePapersMeta,
            cta: l.mobileHomePapersCta,
            onCta: () => ShellNav.go(context, 1),
            image: 'assets/home/hero-bibliotheque.webp'),
      ]),
      quick: MobileQuickAccess(
        title: l.mobileHomeQuick,
        shortcuts: [
          MobileShortcut(
              label: l.mobileHomeQuiz,
              icon: PhosphorIconsDuotone.exam,
              onTap: () => _push(const QuizHubScreen())),
          MobileShortcut(
              label: l.mobileHomePapers,
              icon: PhosphorIconsDuotone.bookOpenText,
              onTap: () => ShellNav.go(context, 1)),
          MobileShortcut(
              label: l.mobileHomeRevisions,
              icon: PhosphorIconsDuotone.cards,
              onTap: () => _push(const QuizRevisionScreen())),
          MobileShortcut(
              label: l.mobileHomeGroups,
              icon: PhosphorIconsDuotone.usersThree,
              onTap: () => _push(const StudyGroupsScreen())),
        ],
        more: [
          MobileShortcut(
              label: l.studentMyCoursesTitle,
              icon: PhosphorIconsDuotone.graduationCap,
              onTap: () => _push(const MyCoursesScreen())),
          MobileShortcut(
              label: l.studentTabsFindTutor,
              icon: PhosphorIconsDuotone.chalkboardTeacher,
              onTap: () => _push(const TutorSearchScreen())),
          MobileShortcut(
              label: l.studentTabsMyBookings,
              icon: PhosphorIconsDuotone.calendarCheck,
              onTap: () => _push(const MyTutorBookingsScreen())),
          MobileShortcut(
              label: l.studentTabsFavorites,
              icon: PhosphorIconsDuotone.heart,
              onTap: () => _push(const FavoritesScreen())),
          MobileShortcut(
              label: l.studentHomeBadges,
              icon: PhosphorIconsDuotone.medal,
              onTap: () => _push(const AchievementsScreen())),
          MobileShortcut(
              label: l.studentTabsCertificates,
              icon: PhosphorIconsDuotone.certificate,
              onTap: () => _push(const CertificatesScreen())),
          MobileShortcut(
              label: l.studentReportsTitle,
              icon: PhosphorIconsDuotone.chartLineUp,
              onTap: () => _push(const StudentReportsScreen())),
          MobileShortcut(
              label: l.studentHubHistory,
              icon: PhosphorIconsDuotone.clockCounterClockwise,
              onTap: () => _push(const DownloadHistoryScreen())),
        ],
      ),
      stats: MobileStatsStrip(items: [
        MobileStat(
            label: l.studentReportsAvgScore,
            value: st != null ? '${st.averageScore.round()}%' : '—',
            caption: l.mobileHomeThisWeek,
            tone: MobileStatTone.teal,
            onTap: () => _push(const StudentReportsScreen())),
        MobileStat(
            label: l.mobileHomeStatStudy,
            value: st != null ? '${st.weeklyStudyHoursTotal.round()} h' : '—',
            caption: l.mobileHomeThisWeek,
            onTap: () => _push(const StudentReportsScreen())),
        MobileStat(
            label: l.mobileHomeStatQuiz,
            value: st != null ? '${st.weeklyQuizCompleted}' : '—',
            tone: MobileStatTone.gold,
            onTap: () => _push(const QuizHubScreen())),
        MobileStat(
            label: l.mobileHomeStatStreak,
            value: _streak != null ? l.mobileHomeDays(_streak!) : '—',
            tone: MobileStatTone.ink,
            onTap: () => _push(const AchievementsScreen())),
        MobileStat(
            label: l.studentHomeBadges,
            value: _badges != null ? '$_badges' : '—',
            onTap: () => _push(const AchievementsScreen())),
        // Offre en cours (l'ancien badge du bandeau) ; sans offre, ouvre les
        // tarifs (l'ancienne bannière « passer à une offre »).
        MobileStat(
            label: l.studentHubSubscription,
            value: SubscriptionScope.of(context).planName,
            caption: SubscriptionScope.of(context).hasPlan
                ? null
                : l.studentHomeUpgrade,
            tone: MobileStatTone.teal,
            onTap: () => _push(const PricingScreen())),
      ]),
      below: [
        // Objectifs proposés par un parent, en attente de réponse
        const PendingGoalsPanel(key: ValueKey('goals')),
        // Autres contenus commencés : le plus récent est déjà repris par la
        // carte « Reprends là où tu en étais ».
        if (started.length > 1)
          MobileSection(
            key: const ValueKey('continue'),
            title: l.studentHomeContinue,
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: started.length - 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _InProgressCard(item: started[i + 1]),
              ),
            ),
          ),
        // Examens à venir (échéances réelles)
        if (upcoming.isNotEmpty)
          MobileSection(
            key: const ValueKey('exams'),
            title: l.studentHomeUpcomingExams,
            child: Column(children: [
              for (final exam in upcoming.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExamCountdownCard(exam: exam),
                ),
            ]),
          ),
      ],
    );
  }
}

/// Ouvre la vraie fiche du contenu (GET /subjects/{id}) : prix, niveau et
/// droits viennent du serveur, jamais d'une fiche reconstituée localement.
Future<void> _openContent(BuildContext context, InProgressContent item) async {
  final id = int.tryParse(item.contentId);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (id == null || id <= 0) return;
  try {
    final subject = await SubjectService.instance.getById(id);
    navigator.push(WinPageRoute(
        builder: (_) => ContentDetailScreen(content: subject.toContent())));
  } catch (_) {
    messenger.showSnackBar(
        SnackBar(content: Text(L10n.current.studentHomeOpenFailed)));
  }
}

class _InProgressCard extends StatelessWidget {
  final InProgressContent item;
  const _InProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(item.subjectId);
    return SizedBox(
      width: 220,
      child: WinCard(
        padding: const EdgeInsets.all(12),
        onTap: () => _openContent(context, item),
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
          Text('${item.progressPct}%',
              style: WinType.labelM(s.primary)
                  .copyWith(fontWeight: FontWeight.w600)),
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
          Text(context.l10n.studentHomeDaysLabel, style: WinType.labelS(urgentColor)),
        ]),
      ]),
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
    return WinPressable(
      onTap: () => Navigator.push(context,
          WinPageRoute(builder: (_) => ContentDetailScreen(content: content))),
      borderRadius: BorderRadius.circular(16),
      pressedScale: 0.97,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.outline),
          boxShadow: s.dark
              ? const []
              : const [
                  BoxShadow(
                      color: Color(0x0F0F2A35),
                      blurRadius: 14,
                      offset: Offset(0, 6)),
                ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 11,
            child: Stack(fit: StackFit.expand, children: [
              // Visuel : la couleur de la matière en dégradé doux et son
              // pictogramme dans un rond blanc.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      subj.color.withValues(alpha: 0.20),
                      subj.color.withValues(alpha: 0.07),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: subj.color.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Icon(subj.icon, size: 28, color: subj.color),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(WinRadii.full),
                  ),
                  child: Text(contentTypeLabel(content.type),
                      style: WinType.manrope(
                          size: 11,
                          weight: FontWeight.w700,
                          color: MobileHomeColors.abyss)),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
            ]),
          ),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.manrope(
                            size: 13.5,
                            weight: FontWeight.w700,
                            height: 1.25,
                            color: s.onStrong)),
                    const SizedBox(height: 4),
                    Text(
                        '${subj.short} · ${ClassLevels.label(content.level)} · ${content.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.labelS(s.onMuted)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: content.free
                            ? WinColors.successBg
                            : MobileHomeColors.tint,
                        borderRadius: BorderRadius.circular(WinRadii.full),
                      ),
                      child: Text(
                          content.free
                              ? context.l10n.commonFree
                              : '${fmtXaf(content.price)} XAF',
                          style: WinType.manrope(
                              size: 12,
                              weight: FontWeight.w800,
                              color: content.free
                                  ? WinColors.success
                                  : MobileHomeColors.abyss)),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}
