import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../data/reference_data.dart';
import '../services/institution_service.dart';
import '../services/subject_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'at_risk_screen.dart';
import 'action_plan_screen.dart';
import 'group_create_screen.dart';
import 'group_members_screen.dart';
import 'student_directory_screen.dart';
import 'reports_screen.dart';
import 'tutor_endorsements_screen.dart';
import 'license_screen.dart';
import '../shared/tutoring_for_students_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../shell/shell_nav.dart';
import '../widgets/mobile_home.dart';
import '../widgets/win_screen.dart';
import '../shared/winai/winai_screen.dart';
import '../shell/more_screen.dart';
import '../shared/net_image.dart';
import 'institution_profile_screen.dart';
import '../services/institution_profile_service.dart';

Widget _statCard(BuildContext c, IconData icon, String value, String label) {
  final s = WinTheme.of(c);
  return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: s.primary),
        const SizedBox(height: 8),
        Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
        Text(label, style: WinType.labelM(s.onMuted)),
      ]));
}

class _GroupRow extends StatelessWidget {
  final ApiGroup g;
  final VoidCallback? onTap;
  final bool showActions;
  const _GroupRow({required this.g, this.onTap, this.showActions = false});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      onTap: showActions ? null : onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: s.primaryContainer,
                  borderRadius: BorderRadius.circular(WinRadii.sm)),
              child: Text('${g.memberCount}',
                  style: WinType.archivo(size: 16, color: s.primary))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(g.name, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 2),
                Text(ClassLevels.label(g.level), style: WinType.labelM(s.onMuted)),
              ])),
          const SizedBox(width: 10),
          Text(context.l10n.instDashStudentsCount(g.memberCount), style: WinType.labelM(s.onFaint)),
        ]),
        if (showActions) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: WinButton(
              context.l10n.instGroupSeeStudents,
              small: true,
              icon: PhosphorIconsRegular.users,
              onTap: () => Navigator.push(
                  context,
                  WinPageRoute(
                      builder: (_) => GroupMembersScreen(
                          groupId: g.id, groupName: g.name))),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: WinButton(
              context.l10n.instGroupAssignResources,
              small: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.folderPlus,
              onTap: () => _showAssignSheet(context, g),
            )),
          ]),
        ],
      ]),
    );
  }

  void _showAssignSheet(BuildContext context, ApiGroup group) {
    final s = WinTheme.of(context);
    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      backgroundColor: s.bg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: s.outline,
                          borderRadius: BorderRadius.circular(WinRadii.full)))),
              const SizedBox(height: 16),
              Text(context.l10n.instGroupAssignTo(group.name),
                  style: WinType.titleL(s.onStrong)),
              const SizedBox(height: 4),
              Text(
                  context.l10n.instGroupAssignInfo,
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 20),
              WinButton(context.l10n.instGroupBrowseCatalog,
                  block: true,
                  icon: PhosphorIconsRegular.stack,
                  onTap: () => Navigator.pop(context)),
              const SizedBox(height: 10),
              WinButton(context.l10n.commonCancel,
                  block: true,
                  variant: WinButtonVariant.ghost,
                  onTap: () => Navigator.pop(context)),
            ]),
      ),
    );
  }
}

/// ===================== ACCUEIL =====================
class InstitutionDashTab extends StatefulWidget {
  const InstitutionDashTab({super.key});
  @override
  State<InstitutionDashTab> createState() => _InstitutionDashTabState();
}

class _InstitutionDashTabState extends State<InstitutionDashTab> {
  List<ApiGroup>? _groups;
  int _atRiskCount = 0;
  ApiInstitutionAnalytics? _analytics;
  // Identité et licence réelles (GET /institution/me, /institution/license),
  // à la place de WinData.institutionStats (nom, plan, licences fictifs).
  ApiInstitutionLicenseSummary? _license;

  @override
  void initState() {
    super.initState();
    _load();
    InstitutionService.instance.getLicenseSummary().then((l) {
      if (mounted) setState(() => _license = l);
    });
  }

  bool _failed = false;

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    final List<Object> results;
    try {
      results = await Future.wait([
        InstitutionService.instance.getGroups(),
        InstitutionService.instance.getAtRiskStudents(),
        InstitutionService.instance.getAnalytics(),
      ]);
    } catch (_) {
      // Lot 8 : panne du serveur, plus de chargement sans fin.
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) {
      setState(() {
        _groups = results[0] as List<ApiGroup>;
        _atRiskCount = (results[1] as List<ApiAtRiskStudent>).length;
        _analytics = results[2] as ApiInstitutionAnalytics;
      });
    }
  }

  void _push(Widget screen) =>
      Navigator.push(context, WinPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final groups = _groups ?? [];
    // Chiffres réels uniquement (GET /institution/analytics et
    // /institution/license) ; « — » quand ils manquent.
    final a = _analytics;
    final lic = _license;
    final pctActive = a != null && a.totalStudents > 0
        ? ' (${(a.activeStudents / a.totalStudents * 100).round()}%)'
        : '';
    final pctLic = lic != null && lic.studentSeats > 0
        ? ' (${(lic.studentSeatsUsed / lic.studentSeats * 100).round()}%)'
        : '';

    return MobileHomeView(
      onRefresh: _load,
      search: MobileSearchBar(
        hint: l.mobileHomeSearchStudent,
        onSubmit: (_) => _push(const StudentDirectoryScreen()),
        onFilters: () => _push(const StudentDirectoryScreen()),
      ),
      forYou: MobileForYou(slides: [
        MobileSlide(
            tag: l.mobileHomeEyebrow,
            title: l.mobileHomeInstTitle,
            meta: _atRiskCount > 0
                ? l.mobileHomeAtRiskMeta(_atRiskCount)
                : l.mobileHomeInstMeta,
            cta: l.mobileHomeInstCta,
            onCta: () => _push(const AtRiskScreen()),
            image: 'assets/home/hero-bibliotheque.webp'),
        MobileSlide(
            tag: l.mobileHomeReportTag,
            title: l.mobileHomeReportTitle,
            meta: l.mobileHomeReportMeta,
            cta: l.mobileHomeReportCta,
            onCta: () => _push(const ReportsScreen()),
            image: 'assets/home/eleves-classe.jpg'),
        MobileSlide(
            tag: l.mobileHomePlanTag,
            title: l.mobileHomePlanTitle,
            meta: l.mobileHomePlanMeta,
            cta: l.mobileHomePlanCta,
            onCta: () => _push(const ActionPlanScreen()),
            image: 'assets/home/eleve-ecrit.jpg'),
      ]),
      quick: MobileQuickAccess(
        title: l.mobileHomeQuick,
        shortcuts: [
          MobileShortcut(
              label: l.mobileHomeClasses,
              icon: PhosphorIconsDuotone.student,
              onTap: () => ShellNav.go(context, 1)),
          MobileShortcut(
              label: l.mobileHomeDirectory,
              icon: PhosphorIconsDuotone.addressBook,
              onTap: () => _push(const StudentDirectoryScreen())),
          MobileShortcut(
              label: l.mobileHomeAnalytics,
              icon: PhosphorIconsDuotone.chartBar,
              onTap: () => ShellNav.go(context, 3)),
          MobileShortcut(
              label: l.mobileHomeLicense,
              icon: PhosphorIconsDuotone.identificationCard,
              onTap: () => _push(const LicenseScreen())),
        ],
        more: [
          MobileShortcut(
              label: l.studentGroupsCreate,
              icon: PhosphorIconsDuotone.usersThree,
              onTap: () => _push(const GroupCreateScreen())),
          MobileShortcut(
              label: l.instAccountTutoring,
              icon: PhosphorIconsDuotone.chalkboardTeacher,
              onTap: () => _push(const TutoringForStudentsScreen())),
          MobileShortcut(
              label: l.instEndorseScreenTitle,
              icon: PhosphorIconsDuotone.sealCheck,
              onTap: () => _push(const TutorEndorsementsScreen())),
          MobileShortcut(
              label: l.shellTabAccount,
              icon: PhosphorIconsDuotone.buildings,
              onTap: () => ShellNav.go(context, 4)),
        ],
      ),
      stats: MobileStatsStrip(items: [
        MobileStat(
            label: l.mobileHomeStatActive,
            value: a != null ? '${a.activeStudents} / ${a.totalStudents}' : '—',
            caption: pctActive.isEmpty ? null : pctActive.trim(),
            tone: MobileStatTone.teal,
            onTap: () => ShellNav.go(context, 3)),
        MobileStat(
            label: l.studentReportsAvgScore,
            value: a != null ? '${a.averageScore.round()}%' : '—',
            tone: MobileStatTone.ink,
            onTap: () => ShellNav.go(context, 3)),
        MobileStat(
            label: l.instDashQuizMonth,
            value: a != null ? '${a.quizzesThisMonth}' : '—',
            tone: MobileStatTone.gold),
        MobileStat(
            label: l.instLicenseStudentSeats,
            value: lic != null
                ? '${lic.studentSeatsUsed} / ${lic.studentSeats}'
                : l.teacherProfileNoneF,
            // Formule de la licence (l'ancien en-tête de l'accueil).
            caption: lic != null
                ? '${l.instLicenseHeading(lic.tier)}$pctLic'
                : l.instDashNoLicense,
            onTap: () => _push(const LicenseScreen())),
      ]),
      below: [
        MobileSection(
          key: const ValueKey('winai'),
          title: l.commonWinaiAlerts,
          child: WinCard(
              child: Row(children: [
            const WinAIOrb(size: 26),
            const SizedBox(width: 12),
            Expanded(
                child: Text(l.instDashAlertsInfo,
                    style: WinType.bodyS(s.onSurface))),
          ])),
        ),
        MobileSection(
          key: const ValueKey('groups'),
          title: l.shellTabGroups,
          actionLabel: groups.isNotEmpty ? l.commonSeeAll : null,
          onAction: () => ShellNav.go(context, 1),
          child: _failed
              ? WinErrorState(message: l.commonLoadError, onRetry: _load)
              : _groups == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: WinLoading())
              : Column(children: [
                  for (final g in groups.take(3))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GroupRow(
                            g: g,
                            onTap: () => _push(GroupMembersScreen(
                                groupId: g.id, groupName: g.name)))),
                ]),
        ),
      ],
    );
  }
}

/// ===================== GROUPES =====================
class InstitutionGroupsTab extends StatefulWidget {
  const InstitutionGroupsTab({super.key});
  @override
  State<InstitutionGroupsTab> createState() => _InstitutionGroupsTabState();
}

class _InstitutionGroupsTabState extends State<InstitutionGroupsTab> {
  List<ApiGroup>? _groups;
  String _query = '';

  /// Groupes dont le nom contient le texte cherché.
  List<ApiGroup> get _shown => _query.isEmpty
      ? _groups!
      : _groups!.where((g) => g.name.toLowerCase().contains(_query)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _failed = false;

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    try {
      final groups = await InstitutionService.instance.getGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WinTextField(
              icon: PhosphorIconsRegular.magnifyingGlass,
              hint: context.l10n.instGroupSearch,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()))),
      const SizedBox(height: 12),
      Expanded(
          child: _failed
              ? WinErrorState(message: context.l10n.commonLoadError, onRetry: _load)
              : _groups == null
              ? const WinLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _GroupRow(g: _shown[i], showActions: true),
                      ),
                      const SizedBox(height: 14),
                      WinButton(context.l10n.studentGroupsCreate,
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: PhosphorIconsRegular.plus, onTap: () async {
                        await Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const GroupCreateScreen()));
                        _load();
                      }),
                    ])),
    ]);
  }
}

/// ===================== CATALOGUE =====================
class InstitutionCatalogTab extends StatefulWidget {
  const InstitutionCatalogTab({super.key});
  @override
  State<InstitutionCatalogTab> createState() => _InstitutionCatalogTabState();
}

class _InstitutionCatalogTabState extends State<InstitutionCatalogTab> {
  List<ApiSubject>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await SubjectService.instance.getAll(pageSize: 40);
      if (mounted) {
        setState(() {
          _items = page.items;
          _failed = false;
        });
      }
    } catch (_) {
      // Une panne n'est pas un catalogue vide.
      if (mounted) {
        setState(() {
          _items = [];
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _items;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WinCard(
              bg: WinColors.teal50,
              child: Row(children: [
                const Icon(PhosphorIconsRegular.info,
                    size: 18, color: WinColors.teal700),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        context.l10n.instCatalogLicenseInfo,
                        style: WinType.bodyS(WinColors.teal700)
                            .copyWith(fontWeight: FontWeight.w600))),
              ]))),
      const SizedBox(height: 12),
      Expanded(
          child: items == null
              ? const WinLoading()
              : _failed
                  ? WinErrorState(
                      message: context.l10n.commonLoadError,
                      onRetry: () {
                        setState(() => _items = null);
                        _load();
                      })
                  : items.isEmpty
                  ? WinEmptyState(title: context.l10n.studentTabsNoContent)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final subj =
                            WinData.subjectById(item.toContent().subjectId);
                        return WinCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: subj.color.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(WinRadii.sm)),
                                  child: Icon(subj.icon,
                                      size: 22, color: subj.color)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: WinType.titleM(s.onStrong)),
                                    Text('${subj.short} · ${ClassLevels.label(item.level)}',
                                        style: WinType.labelM(s.onMuted)),
                                  ])),
                            ]));
                      },
                    )),
    ]);
  }
}

/// ===================== ANALYTICS =====================
class InstitutionAnalyticsTab extends StatefulWidget {
  const InstitutionAnalyticsTab({super.key});
  @override
  State<InstitutionAnalyticsTab> createState() =>
      _InstitutionAnalyticsTabState();
}

class _InstitutionAnalyticsTabState extends State<InstitutionAnalyticsTab> {
  ApiInstitutionAnalytics? _analytics;
  List<ApiGroup>? _groups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _failed = false;

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    try {
      final analytics = await InstitutionService.instance.getAnalytics();
      final groups = await InstitutionService.instance.getGroups();
      if (mounted)
        setState(() {
          _analytics = analytics;
          _groups = groups;
        });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final groups = _groups ?? [];

    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
            Row(children: [
              Expanded(
                  child: _statCard(
                      context,
                      PhosphorIconsRegular.clock,
                      _analytics != null
                          ? '${_analytics!.downloadsThisMonth}'
                          : '',
                      context.l10n.instAnalyticsDownloadsMonth)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statCard(
                      context,
                      PhosphorIconsRegular.checkCircle,
                      _analytics != null
                          ? '${_analytics!.quizzesThisMonth}'
                          : '',
                      context.l10n.instAnalyticsQuizMonth)),
            ]),
            const SizedBox(height: 10),
            WinButton(context.l10n.instRiskTitle,
                variant: WinButtonVariant.outline,
                block: true,
                icon: PhosphorIconsRegular.warning,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const AtRiskScreen()))),
            const SizedBox(height: 10),
            WinButton(context.l10n.instPlanTitle,
                variant: WinButtonVariant.ghost,
                block: true,
                icon: winAIIconData,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const ActionPlanScreen()))),
            const SizedBox(height: 20),
            if (_failed)
              WinErrorState(message: context.l10n.commonLoadError, onRetry: _load)
            else if (_groups == null)
              const WinLoading()
            else ...[
              Text(context.l10n.instAnalyticsByGroup,
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...groups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      SizedBox(
                          width: 84,
                          child: Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WinType.bodyM(s.onStrong)
                                  .copyWith(fontWeight: FontWeight.w600))),
                      Expanded(
                          child: WinProgressBar(
                              g.memberCount.toDouble().clamp(0, 100))),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 40,
                          child: Text('${g.memberCount}',
                              textAlign: TextAlign.right,
                              style: WinType.labelM(s.onMuted))),
                    ]),
                  )),
            ],
          ])),
    ]);
  }
}

/// ===================== COMPTE =====================
class InstitutionAccountTab extends StatefulWidget {
  const InstitutionAccountTab({super.key});
  @override
  State<InstitutionAccountTab> createState() => _InstitutionAccountTabState();
}

class _InstitutionAccountTabState extends State<InstitutionAccountTab> {
  InstitutionProfile? _profile;
  String? _fallbackName;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fiche de l'établissement ; à défaut (serveur plus ancien), son seul nom.
  Future<void> _load() async {
    try {
      final p = await InstitutionProfileService.instance.load();
      if (mounted) {
        setState(() {
          _profile = p;
          _loaded = true;
        });
      }
    } on InstitutionProfileException {
      String? name;
      try {
        name = await InstitutionService.instance.getMyInstitutionName();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _fallbackName = name;
          _loaded = true;
        });
      }
    }
  }

  Future<void> _edit() async {
    await Navigator.push(context,
        WinPageRoute(builder: (_) => const InstitutionProfileScreen()));
    if (mounted) _load();
  }

  void _open(Widget page) =>
      Navigator.push(context, WinPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final p = _profile;
    final name = p?.name.isNotEmpty == true
        ? p!.name
        : (_fallbackName ?? (_loaded ? l.instMySchool : '\u2026'));
    final details = [
      if (p != null && p.type.isNotEmpty) institutionTypeLabel(context, p.type),
      if (p != null && p.city.isNotEmpty) p.city,
    ].join(' \u00b7 ');
    final gold = winTone(s, BadgeColor.gold);
    Widget logo() => Container(
        color: gold.bg,
        child: Icon(PhosphorIconsRegular.buildings, size: 30, color: gold.fg));
    Widget title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(t, style: WinType.titleL(s.onStrong)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Identité de l'établissement, ouvre sa fiche.
        WinCard(
          onTap: _edit,
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(WinRadii.lg),
              child: SizedBox(
                width: 60,
                height: 60,
                child: p?.logoUrl == null
                    ? logo()
                    : NetImage(p!.logoUrl!, error: (_) => logo()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.headlineS(s.onStrong)),
                    const SizedBox(height: 2),
                    Text(details.isEmpty ? l.instAccountSchool : details,
                        style: WinType.bodyS(s.onMuted)),
                  ]),
            ),
            Icon(PhosphorIconsRegular.caretRight, color: s.onFaint),
          ]),
        ),

        title(l.instAccountGroupSchool),
        MoreGroup(children: [
          MoreLine(
              icon: PhosphorIconsRegular.pencilSimple,
              label: l.instProfileTitle,
              onTap: _edit),
          MoreLine(
              icon: PhosphorIconsRegular.shield,
              label: l.instAccountLicense,
              onTap: () => _open(const LicenseScreen())),
          MoreLine(
              icon: PhosphorIconsRegular.chartBar,
              label: l.instAccountReports,
              onTap: () => _open(const ReportsScreen())),
        ]),

        title(l.instAccountGroupTutoring),
        MoreGroup(children: [
          // Attribution de tuteurs, réservations et portefeuille.
          MoreLine(
              icon: PhosphorIconsRegular.graduationCap,
              label: l.instAccountTutoring,
              onTap: () => _open(const TutoringForStudentsScreen())),
          // Caution des répétiteurs rattachés, pour le présentiel.
          MoreLine(
              icon: PhosphorIconsRegular.shieldCheck,
              label: l.instEndorseScreenTitle,
              onTap: () => _open(const TutorEndorsementsScreen())),
        ]),
      ],
    );
  }
}

/// WinAI de cet espace : l'écran est commun aux quatre espaces
/// (shared/winai/winai_screen.dart), seuls les textes et les outils changent.
class InstitutionWinAITab extends StatelessWidget {
  final String? initialMessage;
  const InstitutionWinAITab({super.key, this.initialMessage});
  @override
  Widget build(BuildContext context) =>
      WinAIScreen(role: WinRole.institution, initialMessage: initialMessage);
}
