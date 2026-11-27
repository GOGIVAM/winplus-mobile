import 'package:flutter/material.dart';
import '../shared/visio/visio_screen.dart';
import '../services/visio_service.dart';
import '../widgets/external_links.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'teacher_courses_screen.dart';
import 'teacher_class_detail_screen.dart';
import '../widgets/win_widgets.dart';
import 'content_publish_screen.dart';
import 'content_actions_sheet.dart';
import 'correction_queue_screen.dart';
import 'session_create_screen.dart';
import 'teacher_links_screen.dart';
import 'tutor_profile_screen.dart';
import 'tutor_bookings_screen.dart';
import 'teacher_wallet_view.dart';
import '../l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../shell/shell_nav.dart';
import '../student/search_screen.dart';
import '../widgets/mobile_home.dart';
import '../widgets/win_screen.dart';
import '../shared/winai/winai_screen.dart';
import 'dart:async';
import '../services/tutor_profile_service.dart';
import 'teacher_students_view.dart';

BadgeColor _statusColor(String s) => switch (s) {
      'Publié' => BadgeColor.success,
      'published' => BadgeColor.success,
      'En révision' => BadgeColor.warn,
      'pending' => BadgeColor.warn,
      _ => BadgeColor.neutral,
    };

String _statusLabel(String s) => switch (s) {
      'published' => L10n.current.commonPublished,
      'pending' => L10n.current.teacherContentStatusReview,
      'draft' => L10n.current.commonDraft,
      'Publié' => L10n.current.commonPublished,
      'En révision' => L10n.current.teacherContentStatusReview,
      'Brouillon' => L10n.current.commonDraft,
      _ => s,
    };

/// ===================== ACCUEIL =====================
class TeacherDashTab extends StatefulWidget {
  const TeacherDashTab({super.key});
  @override
  State<TeacherDashTab> createState() => _TeacherDashTabState();
}

class _TeacherDashTabState extends State<TeacherDashTab> {
  List<ApiPublishedContent>? _content;
  ApiTeacherStats? _stats;
  int _pendingCorrections = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Profil de répétiteur déjà actif : la carte « Activez le mode
  /// répétiteur » ne s'affiche plus (lot 8 : elle était proposée à un
  /// répétiteur déjà en ligne).
  bool _isTutor = false;

  Future<void> _load() async {
    unawaited(TutorProfileService.instance.isActiveTutor().then((active) {
      if (mounted && active != _isTutor) setState(() => _isTutor = active);
    }).catchError((_) {}));
    try {
      final results = await Future.wait([
        TeacherService.instance.getMyContent(),
        TeacherService.instance.getStats(),
        TeacherService.instance.getSubmissions(),
      ]);
      if (mounted) {
        setState(() {
          _content = results[0] as List<ApiPublishedContent>;
          _stats = results[1] as ApiTeacherStats;
          _pendingCorrections = (results[2] as List<ApiSubmission>)
              .where((s) => !s.corrected)
              .length;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _content = [];
          _stats = null;
        });
      }
    }
  }

  void _push(Widget screen) =>
      Navigator.push(context, WinPageRoute(builder: (_) => screen));

  Future<void> _publish() async {
    await Navigator.push(
        context, WinPageRoute(builder: (_) => const ContentPublishScreen()));
    setState(() => _content = null);
    _load();
  }

  Future<void> _corrections() async {
    await Navigator.push(
        context, WinPageRoute(builder: (_) => const CorrectionQueueScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final content = _content ?? [];
    final published = content
        .where((c) => c.status == 'published' || c.status == 'Publié')
        .toList();
    final totalDl = content.fold(0, (a, c) => a + c.downloads);
    final avgRating = published.isEmpty
        ? 0.0
        : published.fold(0.0, (a, c) => a + c.rating) / published.length;
    final subScope = SubscriptionScope.of(context);
    // Lot 9.7b (étude section 3) : les publications du catalogue sont
    // illimitées pour tous les plans ; l'ancien plafond de 2 publications du
    // plan gratuit (mobile seulement) est retiré.
    final sharePct = subScope.limit(EntitlementKeys.teacherShare);

    final weeklyRev = _stats?.weeklyRevenue ?? [0, 0, 0, 0];
    final maxRev = weeklyRev.reduce((a, b) => a > b ? a : b);
    final pendingCorrections = _pendingCorrections;
    final loaded = _content != null;

    return MobileHomeView(
      onRefresh: _load,
      search: MobileSearchBar(
        hint: l.mobileHomeSearchPaper,
        onSubmit: (q) => _push(SearchScreen(initialQuery: q)),
        onFilters: () => _push(const SearchScreen()),
      ),
      forYou: MobileForYou(slides: [
        if (pendingCorrections > 0)
          MobileSlide(
              tag: l.mobileHomeEyebrow,
              title: l.mobileHomeCorrectTitle(pendingCorrections),
              meta: l.mobileHomeCorrectMeta,
              cta: l.mobileHomeCorrectCta,
              onCta: _corrections,
              image: 'assets/home/hero-repetiteur-eleve.webp')
        else
          MobileSlide(
              tag: l.mobileHomeEyebrow,
              title: l.mobileHomePublishTitle,
              meta: l.mobileHomePublishMeta,
              cta: l.mobileHomePublishCta,
              onCta: _publish,
              image: 'assets/home/hero-repetiteur-eleve.webp'),
        if (!_isTutor)
        MobileSlide(
            tag: l.mobileHomeTeachTutorTag,
            title: l.mobileHomeTeachTutorTitle,
            meta: l.mobileHomeTeachTutorMeta,
            cta: l.mobileHomeTeachTutorCta,
            onCta: () => _push(const TutorProfileScreen()),
            image: 'assets/home/eleve-ecrit.jpg'),
        MobileSlide(
            tag: l.mobileHomeCoursesTag,
            title: l.mobileHomeCoursesTitle,
            meta: l.mobileHomeCoursesMeta,
            cta: l.mobileHomeCoursesCta,
            onCta: () => _push(const TeacherCoursesScreen()),
            image: 'assets/home/hero-bibliotheque.webp'),
      ]),
      quick: MobileQuickAccess(
        title: l.mobileHomeQuick,
        shortcuts: [
          MobileShortcut(
              label: l.mobileHomeClasses,
              icon: PhosphorIconsDuotone.chalkboardTeacher,
              onTap: () => ShellNav.go(context, 2)),
          MobileShortcut(
              label: l.mobileHomeCorrections,
              icon: PhosphorIconsDuotone.checkSquareOffset,
              count: pendingCorrections,
              onTap: _corrections),
          MobileShortcut(
              label: l.mobileHomeSessions,
              icon: PhosphorIconsDuotone.calendarDots,
              onTap: () => ShellNav.go(context, 3)),
          MobileShortcut(
              label: l.mobileHomeRevenue,
              icon: PhosphorIconsDuotone.wallet,
              onTap: () => ShellNav.go(context, 4)),
        ],
        more: [
          MobileShortcut(
              label: l.forumPublish,
              icon: PhosphorIconsDuotone.uploadSimple,
              onTap: _publish),
          MobileShortcut(
              label: l.shellTabContent,
              icon: PhosphorIconsDuotone.files,
              onTap: () => ShellNav.go(context, 1)),
          MobileShortcut(
              label: l.mobileHomeCoursesTag,
              icon: PhosphorIconsDuotone.graduationCap,
              onTap: () => _push(const TeacherCoursesScreen())),
          MobileShortcut(
              label: l.teacherProfileTitle,
              icon: PhosphorIconsDuotone.identificationBadge,
              onTap: () => _push(const TutorProfileScreen())),
          MobileShortcut(
              label: l.teacherClassesMyBookings,
              icon: PhosphorIconsDuotone.calendarCheck,
              onTap: () => _push(const TutorBookingsScreen())),
          MobileShortcut(
              label: l.teacherClassesMyLinks,
              icon: PhosphorIconsDuotone.link,
              onTap: () => _push(const TeacherLinksScreen())),
        ],
      ),
      stats: MobileStatsStrip(items: [
        MobileStat(
            label: l.teacherDashPublishedContent,
            value: loaded ? '${published.length}' : '—',
            tone: MobileStatTone.teal,
            onTap: () => ShellNav.go(context, 1)),
        MobileStat(
            label: l.teacherDashMonthRevenue,
            value: _stats != null
                ? '${fmtXaf(_stats!.thisMonthRevenue)} XAF'
                : '—',
            tone: MobileStatTone.ink,
            onTap: () => ShellNav.go(context, 4)),
        MobileStat(
            label: l.teacherDashDownloads,
            value: loaded ? '$totalDl' : '—',
            onTap: () => ShellNav.go(context, 1)),
        MobileStat(
            label: l.teacherDashAvgRating,
            value: avgRating > 0 ? WinFormat.decimal(avgRating) : '—',
            caption: avgRating > 0 ? l.teacherDashOutOf5 : null,
            tone: MobileStatTone.gold),
        MobileStat(
            label: l.teacherDashActiveStudents,
            value: _stats != null ? '${_stats!.activeStudents}' : '—',
            onTap: () => ShellNav.go(context, 2)),
        MobileStat(
            label: l.mobileHomeShare,
            value: sharePct > 0 ? WinFormat.percent(sharePct) : '—',
            caption: subScope.planName,
            tone: MobileStatTone.teal),
      ]),
      below: [
        // Revenus des quatre dernières semaines (le total du mois est dans
        // la bande de chiffres).
        MobileSection(
          key: const ValueKey('revenue'),
          title: l.teacherDashLast4Weeks,
          actionLabel: l.mobileHomeRevenue,
          onAction: () => ShellNav.go(context, 4),
          child: WinCard(
            child: SizedBox(
              height: 78,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (i) {
                  final val = weeklyRev[i];
                  final h = maxRev == 0 ? 4.0 : (val / maxRev) * 60.0;
                  return Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Les barres montent l'une après l'autre.
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: h.clamp(4.0, 60.0)),
                            duration: winReducedMotion(context)
                                ? Duration.zero
                                : Duration(milliseconds: 500 + 120 * i),
                            curve: WinCurves.enter,
                            builder: (_, v, __) => Container(
                              height: v,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: i == 3
                                    ? s.primary
                                    : s.primary.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(WinRadii.full)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(l.studentReportsWeekShort(i + 1),
                              style: WinType.labelS(s.onFaint)),
                        ]),
                  );
                }),
              ),
            ),
          ),
        ),
        // 4. « Vos insights » de démonstration (meilleur vendeur,
        // audience, +12 %) retirés : aucun calcul serveur ne
        // les produit ; les chiffres réels sont au-dessus.

        // 5. Contenus récents (3 derniers)
        MobileSection(
          key: const ValueKey('recent'),
          title: l.teacherDashRecentContent,
          actionLabel: content.isNotEmpty ? l.commonSeeAll : null,
          onAction: () => ShellNav.go(context, 1),
          child: !loaded
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: const WinLoading())
              : content.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.teacherDashNoContent,
                          style: WinType.bodyM(s.onMuted)),
                    ))
                  : Column(children: [
                      for (final c in content.take(3))
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ContentRow(
                                c: c,
                                onChanged: () {
                                  setState(() => _content = null);
                                  _load();
                                })),
                    ]),
        ),
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  final ApiPublishedContent c;
  final VoidCallback? onChanged;
  const _ContentRow({required this.c, this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: s.primaryContainer,
                  borderRadius: BorderRadius.circular(WinRadii.sm)),
              child:
                  Icon(PhosphorIconsRegular.fileText, size: 20, color: s.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 4),
                Text(
                    '${context.l10n.teacherDashDownloadsCount(c.downloads)}${c.rating > 0 ? '  ·  ${WinFormat.decimal(c.rating)}' : ''}',
                    style: WinType.labelM(s.onMuted)),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            WinBadge(_statusLabel(c.status), color: _statusColor(c.status)),
            if (c.revenue > 0)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${fmtXaf(c.revenue)} XAF',
                      style: WinType.labelM(s.onMuted))),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                ContentActionsSheet.show(context, c, onChanged: onChanged),
            child: Icon(PhosphorIconsBold.dotsThreeVertical, size: 20, color: s.onFaint),
          ),
        ]));
  }
}

/// ===================== CONTENUS =====================
class TeacherContentTab extends StatefulWidget {
  const TeacherContentTab({super.key});
  @override
  State<TeacherContentTab> createState() => _TeacherContentTabState();
}

class _TeacherContentTabState extends State<TeacherContentTab> {
  String _f = 'Tout';
  List<ApiPublishedContent>? _all;
  final _filters = const ['Tout', 'Publié', 'En révision', 'Brouillon'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TeacherService.instance.getMyContent();
      if (mounted) setState(() => _all = data);
    } catch (_) {
      if (mounted) setState(() => _all = []);
    }
  }

  String _filterLabel(BuildContext context, String f) => switch (f) {
        'Publié' => context.l10n.commonPublished,
        'En révision' => context.l10n.teacherContentStatusReview,
        'Brouillon' => context.l10n.commonDraft,
        _ => context.l10n.commonAll,
      };

  List<ApiPublishedContent> get _items {
    final all = _all ?? [];
    if (_f == 'Tout') return all;
    final normalized = switch (_f) {
      'Publié' => 'published',
      'En révision' => 'pending',
      'Brouillon' => 'draft',
      _ => _f.toLowerCase(),
    };
    return all.where((c) => c.status == normalized || c.status == _f).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Bannière formations structurées
      GestureDetector(
        onTap: () => Navigator.push(context,
            WinPageRoute(builder: (_) => const TeacherCoursesScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [WinColors.teal900, WinColors.teal850],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(WinRadii.lg),
          ),
          child: Row(children: [
            const Icon(PhosphorIconsRegular.monitorPlay,
                color: WinColors.teal400, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentMyCoursesTitle, style: WinType.titleM(Colors.white)),
                  Text(context.l10n.teacherContentCoursesBanner,
                      style: WinType.labelS(Colors.white54)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WinColors.teal600,
                borderRadius: BorderRadius.circular(WinRadii.full),
              ),
              child: Text(context.l10n.teacherContentManage,
                  style: WinType.labelS(Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
      SizedBox(
          height: 36,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => WinChip(_filterLabel(context, _filters[i]),
                  active: _f == _filters[i],
                  onTap: () => setState(() => _f = _filters[i])))),
      const SizedBox(height: 12),
      Expanded(
          child: _all == null
              ? const WinLoading()
              : _items.isEmpty
                  ? Center(child: Builder(builder: (ctx) {
                      final s = WinTheme.of(ctx);
                      return Text(ctx.l10n.teacherContentEmpty,
                          style: WinType.bodyM(s.onMuted));
                    }))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _ContentRow(c: _items[i], onChanged: _load))),
    ]);
  }
}

/// ===================== ÉTUDIANTS =====================
class TeacherStudentsTab extends StatefulWidget {
  const TeacherStudentsTab({super.key});
  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

/// Module 12 : classes réelles du professeur (plus de listes codées en dur).
/// L'onglet « Étudiants » global a été retiré : le seul regroupement
/// d'élèves que le serveur connaît réellement est par classe (voir l'audit
/// du module  GET /teacher/students/recent est une route sans rapport,
/// non filtrée par professeur, qu'il aurait été trompeur de brancher ici).
class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  /// Deux sous-sections (demande de Georges, 26/11) : « Mes élèves » (tous
  /// les élèves, chacun avec ses classes) et « Mes classes ». Avant, les
  /// classes et les liens vers les élèves s'empilaient sur une seule page.
  bool _studentsView = true;
  bool _showArchived = false;
  List<ApiTeacherClass>? _classes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final classes = await TeacherService.instance.getClasses(includeInactive: _showArchived);
      if (mounted) setState(() => _classes = classes);
    } catch (_) {
      if (mounted) setState(() { _classes = []; _error = L10n.current.teacherClassesLoadError; });
    }
  }

  void _showCreateClassSheet() {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    bool busy = false;
    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return StatefulBuilder(builder: (ctx, setSheetState) {
          Future<void> submit() async {
            if (nameCtrl.text.trim().length < 2 || levelCtrl.text.trim().isEmpty || yearCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ctx.l10n.teacherClassesRequired)));
              return;
            }
            setSheetState(() => busy = true);
            try {
              await TeacherService.instance.createClass(
                name: nameCtrl.text.trim(),
                level: levelCtrl.text.trim(),
                academicYear: yearCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassesCreated(nameCtrl.text.trim()))));
              }
            } catch (_) {
              setSheetState(() => busy = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassesCreateError)));
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: s.outline, borderRadius: BorderRadius.circular(WinRadii.full)))),
                    Text(ctx.l10n.teacherClassesCreate, style: WinType.archivo(size: 18, color: s.onStrong)),
                    const SizedBox(height: 16),
                    WinTextField(label: ctx.l10n.teacherClassesName, hint: ctx.l10n.teacherClassesNameHint, icon: PhosphorIconsRegular.chalkboardTeacher, controller: nameCtrl),
                    const SizedBox(height: 12),
                    WinTextField(label: ctx.l10n.commonLevel, hint: ctx.l10n.teacherClassesLevelHint, icon: PhosphorIconsRegular.graduationCap, controller: levelCtrl),
                    const SizedBox(height: 12),
                    WinTextField(label: ctx.l10n.teacherClassesYear, hint: ctx.l10n.teacherClassesYearHint, icon: PhosphorIconsRegular.calendarBlank, controller: yearCtrl),
                    const SizedBox(height: 20),
                    WinButton(busy ? ctx.l10n.studentGroupsCreating : ctx.l10n.studentGroupsCreateBtn, block: true, icon: PhosphorIconsRegular.plus, loading: busy, onTap: submit),
                  ]),
            ),
          );
        });
      },
    );
  }

  Future<void> _classAction(ApiTeacherClass klass) async {
    if (!klass.isActive) {
      try {
        await TeacherService.instance.reactivateClass(klass.id);
        await _load();
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassesReactivateError)));
      }
      return;
    }
    final result = await Navigator.push<bool>(context,
        WinPageRoute(builder: (_) => TeacherClassDetailScreen(initialClass: klass)));
    if (result != false) await _load();
  }

  Future<void> _deleteOrDeactivate(ApiTeacherClass klass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(klass.studentCount > 0 ? ctx.l10n.teacherClassesDeactivateTitle : ctx.l10n.teacherClassesDeleteTitle),
        content: Text(klass.studentCount > 0
            ? ctx.l10n.teacherClassesDeactivateBody(klass.name, klass.studentCount)
            : ctx.l10n.teacherClassesDeleteBody(klass.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (klass.studentCount > 0) {
        await TeacherService.instance.deactivateClass(klass.id);
      } else {
        await TeacherService.instance.deleteClass(klass.id);
      }
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.teacherClassesActionFailed)));
    }
  }

  /// Liaisons directes et réservations : sous « Mes élèves ».
  List<Widget> _studentLinks() => [
        WinButton(context.l10n.teacherClassesMyLinks,
            variant: WinButtonVariant.outline,
            block: true,
            icon: PhosphorIconsRegular.link,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TeacherLinksScreen()))),
        const SizedBox(height: 10),
        WinButton(context.l10n.teacherClassesMyBookings,
            variant: WinButtonVariant.outline,
            block: true,
            icon: PhosphorIconsRegular.calendarCheck,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TutorBookingsScreen()))),
        const SizedBox(height: 10),
        WinButton(context.l10n.teacherProfileTitle,
            variant: WinButtonVariant.ghost,
            block: true,
            icon: PhosphorIconsRegular.graduationCap,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TutorProfileScreen()))),
      ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(child: WinChip(l.teacherStudentsTabStudents, active: _studentsView, onTap: () => setState(() => _studentsView = true))),
          const SizedBox(width: 8),
          Expanded(child: WinChip(l.teacherStudentsTabClasses, active: !_studentsView, onTap: () => setState(() => _studentsView = false))),
        ]),
      ),
      Expanded(child: _studentsView ? TeacherStudentsView(footer: _studentLinks()) : _classesList()),
    ]);
  }

  Widget _classesList() {
    final s = WinTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(children: [
          Expanded(child: Text(context.l10n.teacherClassesTitle, style: WinType.archivo(size: 18, color: s.onStrong))),
          WinChip(_showArchived ? context.l10n.teacherClassesHideInactive : context.l10n.teacherClassesShowInactive,
              active: _showArchived,
              onTap: () { setState(() => _showArchived = !_showArchived); _load(); }),
        ]),
        const SizedBox(height: 10),
        if (_classes == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: const WinLoading())
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(_error!, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              WinButton(context.l10n.commonRetry, icon: PhosphorIconsRegular.arrowClockwise, onTap: _load),
            ]),
          )
        else if (_classes!.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(PhosphorIconsRegular.chalkboardTeacher, size: 48, color: s.onFaint),
              const SizedBox(height: 8),
              Text(_showArchived ? context.l10n.teacherClassesNone : context.l10n.teacherClassesNoneYet, style: WinType.bodyM(s.onMuted)),
            ]),
          )
        else
          ..._classes!.map((cl) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: cl.isActive ? 1 : 0.6,
                  child: WinCard(
                    padding: const EdgeInsets.all(14),
                    child: InkWell(
                      onTap: () => _classAction(cl),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(WinRadii.sm)),
                          child: Icon(PhosphorIconsRegular.chalkboardTeacher, size: 20, color: s.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cl.name, style: WinType.titleM(s.onStrong), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Row(children: [
                                Text(context.l10n.teacherClassesStudents(cl.studentCount), style: WinType.labelM(s.onMuted)),
                                if (cl.classAverage != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(PhosphorIconsRegular.chartBar, size: 12, color: cl.classAverage! >= 70 ? WinColors.success : WinColors.warn),
                                  const SizedBox(width: 2),
                                  Text(context.l10n.teacherClassesAverage(WinFormat.grade20(cl.classAverage)), style: WinType.labelM(cl.classAverage! >= 70 ? WinColors.success : WinColors.warn)),
                                ],
                                if (cl.pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  WinBadge(context.l10n.teacherClassToMark(cl.pendingCount), color: BadgeColor.warn),
                                ],
                                if (!cl.isActive) ...[
                                  const SizedBox(width: 8),
                                  Text(context.l10n.teacherClassesInactive, style: WinType.labelM(s.onFaint)),
                                ],
                              ]),
                            ])),
                        if (cl.isActive)
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.trash, size: 19, color: s.onFaint),
                            onPressed: () => _deleteOrDeactivate(cl),
                          )
                        else
                          Icon(PhosphorIconsRegular.clockCounterClockwise, size: 18, color: s.primary),
                      ]),
                    ),
                  ),
                ),
              )),
        WinButton(context.l10n.teacherClassesCreate,
            variant: WinButtonVariant.outline, block: true, icon: PhosphorIconsRegular.plus, onTap: _showCreateClassSheet),
      ],
    );
  }
}

/// ===================== SESSIONS =====================
/// Séances du professeur (cours en direct qu'il a planifiés), lues sur le
/// serveur pour les 14 prochains jours, comme le calendrier du site. Avant :
/// deux séances inventées (« 14:00 – 15:30 ») et des boutons sans action.
class TeacherSessionsTab extends StatefulWidget {
  const TeacherSessionsTab({super.key});
  @override
  State<TeacherSessionsTab> createState() => _TeacherSessionsTabState();
}

class _TeacherSessionsTabState extends State<TeacherSessionsTab> {
  List<ApiTeachingSession>? _sessions;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _sessions = null;
    });
    final now = DateTime.now();
    try {
      final list = await TeacherService.instance.getMySessions(
        // Depuis le début de la journée : une séance en cours reste visible.
        from: DateTime(now.year, now.month, now.day),
        to: now.add(const Duration(days: 14)),
      );
      if (mounted) setState(() => _sessions = list);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessions = const [];
          _error = true;
        });
      }
    }
  }

  Future<void> _plan() async {
    await Navigator.push(
        context, WinPageRoute(builder: (_) => const SessionCreateScreen()));
    if (mounted) _load();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final same = d.year == now.year && d.month == now.month && d.day == now.day;
    final weekday = WinFormat.weekday(d.weekday);
    final date = WinFormat.dayMonth(d);
    return same
        ? context.l10n.teacherSessionsToday(weekday, date)
        : context.l10n.teacherSessionsDay(weekday, date);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final sessions = _sessions;
    final children = <Widget>[];
    if (sessions == null) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 48),
        child: const WinLoading(),
      ));
    } else if (_error) {
      children.addAll([
        const SizedBox(height: 32),
        Text(l.teacherSessionsLoadError,
            textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 12),
        WinButton(l.commonRetry, variant: WinButtonVariant.outline, onTap: _load),
      ]);
    } else if (sessions.isEmpty) {
      children.addAll([
        const SizedBox(height: 32),
        Text(l.teacherSessionsEmpty,
            textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
      ]);
    } else {
      String? lastDay;
      for (final se in sessions) {
        final day = _dayLabel(se.start);
        if (day != lastDay) {
          if (lastDay != null) children.add(const SizedBox(height: 8));
          children.addAll([
            Text(day, style: WinType.titleS(s.onMuted)),
            const SizedBox(height: 12),
          ]);
          lastDay = day;
        }
        children.add(_SessionCard(session: se));
      }
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ...children,
          const SizedBox(height: 8),
          WinButton(l.teacherSessionsPlan,
              variant: WinButtonVariant.outline,
              block: true,
              icon: PhosphorIconsRegular.plus,
              onTap: _plan),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ApiTeachingSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final se = session;
    final now = DateTime.now();
    // « Bientôt » : commence dans l'heure, ou déjà commencée et pas finie.
    final soon = !se.isCancelled &&
        se.start.difference(now).inMinutes <= 60 &&
        se.end.isAfter(now);
    final time = '${WinFormat.time(se.start)} – ${WinFormat.time(se.end)}';
    final color = se.isCancelled ? s.onFaint : (soon ? WinColors.teal500 : WinColors.blue500);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 40, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(se.title, style: WinType.titleM(s.onStrong)),
                Text('$time · ${l.teacherSessionsEnrolled(se.enrolledCount)}',
                    style: WinType.labelM(s.onMuted)),
              ]),
            ),
            if (se.isCancelled)
              WinBadge(l.teacherSessionsCancelled)
            else if (soon)
              WinBadge(l.teacherSessionsSoon, color: BadgeColor.error),
          ]),
          // Séance en direct sans lien externe : salle de visio WinPlus,
          // animée par le professeur (même règle que le site).
          if (se.hasWinPlusVisio) ...[
            const SizedBox(height: 12),
            WinButton(l.visioStart,
                variant: soon ? WinButtonVariant.accent : WinButtonVariant.outline,
                block: true,
                small: true,
                icon: PhosphorIconsRegular.videoCamera,
                onTap: () => VisioScreen.open(context, VisioType.seance, se.id,
                    title: se.title)),
          ],
          // Lien de la séance (Meet, Zoom…).
          if (se.externalLink != null && !se.isCancelled) ...[
            const SizedBox(height: 12),
            WinButton(l.teacherSessionsJoin,
                variant: soon ? WinButtonVariant.accent : WinButtonVariant.outline,
                block: true,
                small: true,
                icon: PhosphorIconsRegular.videoCamera,
                onTap: () => ExternalLinks.open(se.externalLink!)),
          ],
        ]),
      ),
    );
  }
}

/// ===================== REVENUS =====================
/// Lot 2, Module 5 : portefeuille réel (solde unifié, historique du journal,
/// retrait Mobile Money automatisé, recharge), en parité avec le web. L'ancien
/// onglet affichait un solde de repli (184 500), une courbe, une commission et
/// des transactions inventés, y compris quand l'appel réseau échouait.
class TeacherRevenueTab extends StatelessWidget {
  const TeacherRevenueTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const Column(children: [Expanded(child: TeacherWalletView())]);
}

/// WinAI de cet espace : l'écran est commun aux quatre espaces
/// (shared/winai/winai_screen.dart), seuls les textes et les outils changent.
class TeacherWinAITab extends StatelessWidget {
  final String? initialMessage;
  const TeacherWinAITab({super.key, this.initialMessage});
  @override
  Widget build(BuildContext context) =>
      WinAIScreen(role: WinRole.teacher, initialMessage: initialMessage);
}
