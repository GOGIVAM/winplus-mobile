import 'package:flutter/material.dart';
import 'my_homework_screen.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/shop/cart_screen.dart';
import '../shared/shop/orders_screen.dart';
import 'student_home.dart';
import 'search_screen.dart';
import 'download_history_screen.dart';
import 'favorites_screen.dart';
import '../shared/concours_screen.dart';
import 'achievements_screen.dart';
import 'certificates_screen.dart';
import 'exam_coach_screen.dart';
import 'study_groups_screen.dart';
import 'study_session_screen.dart';
import 'student_reports_screen.dart';
import 'quiz_revision_screen.dart';
import 'my_courses_screen.dart';
import 'course_catalog_screen.dart';
import 'tutors/tutor_search_screen.dart';
import 'tutors/my_tutor_bookings_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/mobile_home.dart';
import '../widgets/win_motion_widgets.dart';
import '../widgets/win_screen.dart';
import '../shell/more_screen.dart';
import '../shared/visio/live_classes_screen.dart';
import '../shared/winai/winai_screen.dart';

export 'student_home.dart' show StudentHomeTab;

/// ===================== CATALOGUE =====================
class StudentCatalogTab extends StatefulWidget {
  const StudentCatalogTab({super.key});
  @override
  State<StudentCatalogTab> createState() => _StudentCatalogTabState();
}

class _StudentCatalogTabState extends State<StudentCatalogTab> {
  String _type = 'Tout';
  List<Content>? _allItems;
  bool _error = false;

  static const _types = [
    'Tout',
    'Épreuves',
    'Corrections',
    'Quiz',
    'Livres',
    'Packs'
  ];
  static const _contentTypeMap = {
    'Épreuves': ContentType.epreuve,
    'Corrections': ContentType.correction,
    'Quiz': ContentType.quiz,
    'Livres': ContentType.livre,
    'Packs': ContentType.pack,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _allItems = null;
      _error = false;
    });
    try {
      final page = await SubjectService.instance.getAll(pageSize: 50);
      if (mounted)
        setState(
            () => _allItems = page.items.map((s) => s.toContent()).toList());
    } catch (_) {
      // Pas de catalogue de démonstration : erreur affichée avec « Réessayer ».
      if (mounted)
        setState(() {
          _allItems = [];
          _error = true;
        });
    }
  }

  // Libellés affichés ; les valeurs des filtres restent celles d'origine.
  String _typeLabel(String t) => switch (t) {
        'Tout' => context.l10n.commonAll,
        'Épreuves' => context.l10n.studentTabsTypePapers,
        'Corrections' => context.l10n.studentTabsTypeCorrections,
        'Livres' => context.l10n.studentTabsTypeBooks,
        'Packs' => context.l10n.studentTabsTypePacks,
        _ => t,
      };

  List<Content> get _filtered {
    final all = _allItems ?? [];
    if (_type == 'Tout') return all;
    final ct = _contentTypeMap[_type];
    return ct == null ? all : all.where((c) => c.type == ct).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _filtered;
    final loaded = _allItems != null;

    // Pas de titre « Catalogue » dans la page : la barre du haut le porte
    // déjà. La page s'ouvre sur la recherche, comme l'accueil.
    return RefreshIndicator(
      color: WinColors.teal600,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.list(children: [
              MobileSearchBar(
                hint: l.mobileHomeSearchPaper,
                onSubmit: (q) => Navigator.push(context,
                    WinPageRoute(builder: (_) => SearchScreen(initialQuery: q))),
                onFilters: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const SearchScreen())),
              ),
              const SizedBox(height: 18),
              // Formations et répétiteurs : deux cartes photo côte à côte.
              Row(children: [
                Expanded(
                  child: WinEnter(
                    delay: const Duration(milliseconds: 80),
                    from: const Offset(0, 18),
                    child: _FeatureCard(
                      image: 'assets/home/hero-bibliotheque.webp',
                      icon: PhosphorIconsDuotone.graduationCap,
                      title: l.studentTabsStructuredCourses,
                      sub: l.studentTabsStructuredCoursesSub,
                      onTap: () => Navigator.push(
                          context,
                          WinPageRoute(
                              builder: (_) => const CourseCatalogScreen())),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WinEnter(
                    delay: const Duration(milliseconds: 160),
                    from: const Offset(0, 18),
                    child: _FeatureCard(
                      image: 'assets/home/hero-repetiteur-eleve.webp',
                      icon: PhosphorIconsDuotone.chalkboardTeacher,
                      title: l.studentTabsFindTutor,
                      sub: l.studentTabsFindTutorSub,
                      onTap: () => Navigator.push(
                          context,
                          WinPageRoute(
                              builder: (_) => const TutorSearchScreen())),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
            ]),
          ),
          // Types de contenu : pastilles qui défilent de côté.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TypePill(
                  label: _typeLabel(_types[i]),
                  active: _type == _types[i],
                  onTap: () => setState(() => _type = _types[i]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: Text(
                      loaded && !_error ? l.mobileCatalogCount(items.length) : '',
                      style: WinType.archivo(size: 19, color: s.onStrong)),
                ),
                WinPressable(
                  onTap: () => Navigator.push(context,
                      WinPageRoute(builder: (_) => const CartScreen())),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: MobileHomeColors.tint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const WinDuoIcon(PhosphorIconsDuotone.shoppingCart,
                          size: 19),
                      const SizedBox(width: 6),
                      Text(l.mobileCatalogCart,
                          style: WinType.manrope(
                              size: 13,
                              weight: FontWeight.w700,
                              color: MobileHomeColors.abyss)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          if (!loaded)
            const SliverFillRemaining(
                hasScrollBody: false, child: WinLoading())
          else if (_error)
            SliverFillRemaining(
              hasScrollBody: false,
              child: WinErrorState(
                  message: l.studentTabsCatalogLoadError, onRetry: _load),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: WinEmptyState(title: l.studentTabsNoContent),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70),
                itemCount: items.length,
                itemBuilder: (_, i) => WinStaggerFade(
                    key: ValueKey('$_type-${items[i].id}'),
                    index: i,
                    child: ContentCard(content: items[i])),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte photo d'accès (formations, répétiteurs) en tête du catalogue.
class _FeatureCard extends StatelessWidget {
  final String image;
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _FeatureCard(
      {required this.image,
      required this.icon,
      required this.title,
      required this.sub,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WinPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 148,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: MobileHomeColors.abyss)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x260B3530), Color(0xF20B3530)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: MobileHomeColors.tint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: WinDuoIcon(icon, size: 20),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.archivo(
                            size: 15, color: Colors.white, height: 1.15)),
                    const SizedBox(height: 3),
                    Text(sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.manrope(
                            size: 11,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: .8))),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Pastille de type de contenu : vert presque noir quand elle est choisie.
class _TypePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TypePill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: winReducedMotion(context) ? Duration.zero : WinDurations.base,
        curve: WinCurves.standard,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? MobileHomeColors.abyss : s.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active ? MobileHomeColors.abyss : s.outline),
        ),
        child: Text(label,
            style: WinType.manrope(
                size: 13.5,
                weight: FontWeight.w600,
                color: active ? Colors.white : s.onSurface)),
      ),
    );
  }
}

/// ===================== MON ESPACE =====================
class StudentSpaceTab extends StatefulWidget {
  const StudentSpaceTab({super.key});
  @override
  State<StudentSpaceTab> createState() => _StudentSpaceTabState();
}

/// Statistiques réelles (GET /student/stats) ; « — » tant qu'elles ne sont
/// pas chargées. Plus de score ni de temps d'étude de démonstration.
class _StudentSpaceTabState extends State<StudentSpaceTab> {
  ApiStudentStats? _stats;

  void _open(Widget page) =>
      Navigator.push(context, WinPageRoute(builder: (_) => page));

  @override
  void initState() {
    super.initState();
    StudentService.instance.getStats().then((st) {
      if (mounted) setState(() => _stats = st);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final avg = _stats != null ? '${_stats!.averageScore.round()}%' : '—';
    final week =
        _stats != null ? '${_stats!.weeklyStudyHoursTotal.round()}h' : '—';
    return Column(children: [
      Expanded(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(children: [
                Expanded(
                    child: WinStatCard(avg, context.l10n.studentReportsAvgScore, icon: PhosphorIconsRegular.trendUp)),
                const SizedBox(width: 10),
                Expanded(
                    child: WinStatCard(week, context.l10n.studentTabsStudyThisWeek, icon: PhosphorIconsRegular.clock)),
              ]),
              const SizedBox(height: 16),
              // Rangement par usage, le même que le menu de l'élève sur le
              // site : apprendre, s'entraîner, être accompagné, suivre sa
              // progression, gérer ses achats.
              _SpaceGroupTitle(context.l10n.spaceGroupLearn),
              MoreGroup(children: [
                MoreLine(
                    icon: PhosphorIconsRegular.monitorPlay,
                    label: context.l10n.studentMyCoursesTitle,
                    onTap: () => _open(const MyCoursesScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.compass,
                    label: context.l10n.studentTabsCourseCatalog,
                    onTap: () => _open(const CourseCatalogScreen())),
                // Lot 7 : calendrier, épreuves et conseils de chaque concours.
                MoreLine(
                    icon: PhosphorIconsRegular.graduationCap,
                    label: context.l10n.concTitle,
                    onTap: () => _open(const ConcoursHubScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.videoCamera,
                    label: context.l10n.liveTitle,
                    onTap: () => _open(const LiveClassesScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.heart,
                    label: context.l10n.studentTabsFavorites,
                    onTap: () => _open(const FavoritesScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.downloadSimple,
                    label: context.l10n.studentHubHistory,
                    onTap: () => _open(const DownloadHistoryScreen())),
              ]),
              const SizedBox(height: 18),
              _SpaceGroupTitle(context.l10n.spaceGroupPractice),
              MoreGroup(children: [
                // Lot 7 : devoirs des professeurs, examens blancs et devoirs
                // de l'établissement (comme /mes-devoirs du site).
                MoreLine(
                    icon: PhosphorIconsRegular.clipboardText,
                    label: context.l10n.hwTitle,
                    onTap: () => _open(const MyHomeworkScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.exam,
                    label: context.l10n.studentHubRevisionQuiz,
                    onTap: () => _open(const QuizRevisionScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.playCircle,
                    label: context.l10n.studentTabsGuidedSession,
                    onTap: () => _open(const StudySessionScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.graduationCap,
                    label: context.l10n.studentTabsExamCoach,
                    onTap: () => _open(const ExamCoachScreen())),
              ]),
              const SizedBox(height: 18),
              _SpaceGroupTitle(context.l10n.spaceGroupSupport),
              MoreGroup(children: [
                MoreLine(
                    icon: PhosphorIconsRegular.userFocus,
                    label: context.l10n.studentTabsFindTutor,
                    onTap: () => _open(const TutorSearchScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.calendarCheck,
                    label: context.l10n.studentTabsMyBookings,
                    onTap: () => _open(const MyTutorBookingsScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.usersThree,
                    label: context.l10n.studentLinksStudyGroups,
                    onTap: () => _open(const StudyGroupsScreen())),
              ]),
              const SizedBox(height: 18),
              _SpaceGroupTitle(context.l10n.spaceGroupProgress),
              MoreGroup(children: [
                MoreLine(
                    icon: PhosphorIconsRegular.chartBar,
                    label: context.l10n.studentReportsTitle,
                    onTap: () => _open(const StudentReportsScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.trophy,
                    label: context.l10n.studentHomeBadges,
                    onTap: () => _open(const AchievementsScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.medal,
                    label: context.l10n.studentTabsCertificates,
                    onTap: () => _open(const CertificatesScreen())),
              ]),
              const SizedBox(height: 18),
              _SpaceGroupTitle(context.l10n.spaceGroupPurchases),
              MoreGroup(children: [
                MoreLine(
                    icon: PhosphorIconsRegular.shoppingCart,
                    label: context.l10n.studentTabsMyCart,
                    onTap: () => _open(const CartScreen())),
                MoreLine(
                    icon: PhosphorIconsRegular.receipt,
                    label: context.l10n.studentTabsMyOrders,
                    onTap: () => _open(const OrdersScreen())),
              ]),
              const SizedBox(height: 18),
              // « Performance par matière » de démonstration retirée : aucun
              // score par matière n'est servi pour l'élève ; ses résultats
              // réels sont dans « Mes rapports ».
            ]),
      ),
    ]);
  }
}

/// Titre d'un groupe d'usage de « Mon espace ».
class _SpaceGroupTitle extends StatelessWidget {
  final String label;
  const _SpaceGroupTitle(this.label);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(label, style: WinType.titleL(s.onStrong)),
    );
  }
}

class StudentWinAITab extends StatelessWidget {
  final String? initialMessage;
  const StudentWinAITab({super.key, this.initialMessage});
  @override
  Widget build(BuildContext context) =>
      WinAIScreen(role: WinRole.student, initialMessage: initialMessage);
}
