import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../widgets/language_selector.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../services/chatbot_service.dart';
import '../services/institution_service.dart';
import '../widgets/winai_memories_sheet.dart';
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
import '../widgets/knowledge_base_toggle.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../shell/shell_nav.dart';
import '../widgets/mobile_home.dart';

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
              icon: Icons.people_outline,
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
              icon: Icons.library_add_outlined,
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
                  icon: Icons.layers_outlined,
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

  Future<void> _load() async {
    final results = await Future.wait([
      InstitutionService.instance.getGroups(),
      InstitutionService.instance.getAtRiskStudents(),
      InstitutionService.instance.getAnalytics(),
    ]);
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
            caption: pctLic.isEmpty ? null : pctLic.trim(),
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
          child: _groups == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await InstitutionService.instance.getGroups();
    if (mounted) setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              WinTextField(icon: Icons.search, hint: context.l10n.instGroupSearch)),
      const SizedBox(height: 12),
      Expanded(
          child: _groups == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _groups!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _GroupRow(g: _groups![i], showActions: true),
                      ),
                      const SizedBox(height: 14),
                      WinButton(context.l10n.studentGroupsCreate,
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: Icons.add, onTap: () async {
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await SubjectService.instance.getAll(pageSize: 40);
      if (mounted) setState(() => _items = page.items);
    } catch (_) {
      if (mounted) setState(() => _items = []);
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
                const Icon(Icons.info_outline,
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
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(
                      child: Text(context.l10n.studentTabsNoContent,
                          style: WinType.bodyM(s.onMuted)))
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
                              WinButton(context.l10n.instCatalogAssign,
                                  variant: WinButtonVariant.outline,
                                  small: true,
                                  icon: Icons.add),
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

  Future<void> _load() async {
    final analytics = await InstitutionService.instance.getAnalytics();
    final groups = await InstitutionService.instance.getGroups();
    if (mounted)
      setState(() {
        _analytics = analytics;
        _groups = groups;
      });
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
                      Icons.schedule,
                      _analytics != null
                          ? '${_analytics!.downloadsThisMonth}'
                          : '',
                      context.l10n.instAnalyticsDownloadsMonth)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statCard(
                      context,
                      Icons.check_circle_outline,
                      _analytics != null
                          ? '${_analytics!.quizzesThisMonth}'
                          : '',
                      context.l10n.instAnalyticsQuizMonth)),
            ]),
            const SizedBox(height: 10),
            WinButton(context.l10n.instRiskTitle,
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.warning_amber_outlined,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const AtRiskScreen()))),
            const SizedBox(height: 10),
            WinButton(context.l10n.instPlanTitle,
                variant: WinButtonVariant.ghost,
                block: true,
                icon: Icons.auto_awesome_outlined,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const ActionPlanScreen()))),
            const SizedBox(height: 20),
            if (_groups == null)
              const Center(child: CircularProgressIndicator())
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
class InstitutionAccountTab extends StatelessWidget {
  const InstitutionAccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = WinAppScope.of(context);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.shellTabAccount,
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            Center(
                child: Column(children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: WinColors.goldBg,
                      borderRadius: BorderRadius.circular(WinRadii.lg)),
                  child: const Icon(Icons.apartment_outlined,
                      size: 40, color: WinColors.gold)),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: InstitutionService.instance.getMyInstitutionName(),
                builder: (_, snap) => Text(
                    snap.data ??
                        (snap.connectionState == ConnectionState.done
                            ? context.l10n.instMySchool
                            : '…'),
                    style: WinType.archivo(size: 22, color: s.onStrong)),
              ),
              Text(context.l10n.instAccountSchool, style: WinType.bodyM(s.onMuted)),
            ])),
            const SizedBox(height: 20),
            // Lot 9.7b, étape 4 : licence réelle (sièges, renouvellement),
            // à la place de la carte « Licences utilisées » fictive.
            GestureDetector(
              onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const LicenseScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: s.inkCard, borderRadius: BorderRadius.circular(WinRadii.lg)),
                child: Row(children: [
                  const Icon(Icons.shield_outlined, size: 20, color: WinColors.teal400),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.l10n.instAccountLicense, style: WinType.titleL(WinColors.cream50))),
                  const Icon(Icons.chevron_right, color: WinColors.cream50),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _Row(Icons.people_outline, context.l10n.instAccountAdmins),
            _Row(Icons.grid_view_outlined, context.l10n.instAccountGroups),
            _Row(Icons.receipt_long_outlined, context.l10n.instAccountBilling),
            // Lot 9.3 : attribution de tuteurs, réservations et portefeuille institution.
            _Row(Icons.school_outlined, context.l10n.instAccountTutoring,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const TutoringForStudentsScreen()))),
            // Lot 9.5 (17.11) : caution des répétiteurs rattachés pour le présentiel.
            _Row(Icons.verified_user_outlined, context.l10n.instEndorseScreenTitle,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const TutorEndorsementsScreen()))),
            _Row(Icons.bar_chart_outlined, context.l10n.instAccountReports,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const ReportsScreen()))),
            _Row(Icons.dark_mode_outlined, context.l10n.commonDarkMode,
                trailing: Switch(
                    value: state.dark,
                    activeThumbColor: s.primary,
                    onChanged: (_) => state.toggleTheme())),
            _Row(Icons.language, context.l10n.language,
            trailing: const LanguageToggle()),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    WinPageRoute(builder: (_) => const WelcomeScreen()),
                    (r) => false,
                  );
                },
                child: Text(context.l10n.commonLogout,
                    style: WinType.manrope(
                        size: 14,
                        weight: FontWeight.w600,
                        color: WinColors.error))),
          ])),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Row(this.icon, this.label, {this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: s.outline))),
        child: Row(children: [
          Icon(icon, size: 20, color: s.onFaint),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: WinType.bodyM(s.onStrong)
                      .copyWith(fontWeight: FontWeight.w500))),
          trailing ??
              const Icon(Icons.chevron_right,
                  size: 18, color: WinColors.ink300),
        ]),
      ),
    );
  }
}

/// ===================== WINAI =====================
class InstitutionWinAITab extends StatefulWidget {
  final String? initialMessage;
  const InstitutionWinAITab({super.key, this.initialMessage});
  @override
  State<InstitutionWinAITab> createState() => _InstitutionWinAITabState();
}

class _InstitutionWinAITabState extends State<InstitutionWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text})> _msgs = [];
  bool _thinking = false;

  List<String> get _suggestions => [
    context.l10n.instAiSuggestion1,
    context.l10n.instRiskTitle,
    context.l10n.instAiSuggestion3,
    context.l10n.instAiSuggestion4,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _send(widget.initialMessage));
    }
  }

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add((me: true, text: t));
      _ctrl.clear();
      _thinking = true;
    });
    final reply = await ChatbotService.instance.sendMessage(message: t);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add((
        me: false,
        text: reply ?? L10n.current.studentTabsAiNoReply
      ));
    });
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
        title: Text('WinAI', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        Expanded(
          child: _msgs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const Spacer(),
                    const WinAIOrb(size: 80),
                    const SizedBox(height: 20),
                    Text('WinAI',
                        style: WinType.archivo(size: 28, color: s.onStrong)),
                    const SizedBox(height: 6),
                    Text(context.l10n.instAiTagline,
                        style: WinType.bodyM(s.onMuted),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: _suggestions
                          .map((q) => GestureDetector(
                                onTap: () => _send(q),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: WinColors.teal500
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(WinRadii.md),
                                      border: Border.all(
                                          color: WinColors.teal500
                                              .withValues(alpha: 0.25))),
                                  alignment: Alignment.centerLeft,
                                  child: Text(q,
                                      style: WinType.manrope(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: WinColors.teal600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => showWinAIMemoriesSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(WinRadii.full),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.psychology_rounded,
                              size: 15, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 8),
                          Text(context.l10n.commonWinaiMemory,
                              style: WinType.manrope(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6))),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Color(0xFF8B5CF6)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _msgs.length + (_thinking ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_thinking && i == _msgs.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: s.cardBg,
                              border: Border.all(color: s.cardBorder),
                              borderRadius: BorderRadius.circular(WinRadii.lg)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: s.primary)),
                            const SizedBox(width: 8),
                            Text(context.l10n.commonWinaiThinking,
                                style: WinType.bodyS(s.onMuted)),
                          ]),
                        ),
                      );
                    }
                    final m = _msgs[i];
                    return Align(
                      alignment:
                          m.me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: m.me ? WinColors.ink800 : s.cardBg,
                          border: m.me ? null : Border.all(color: s.cardBorder),
                          borderRadius: BorderRadius.circular(WinRadii.lg),
                        ),
                        child: Text(m.text,
                            style: WinType.bodyM(
                                m.me ? WinColors.cream50 : s.onSurface)),
                      ),
                    );
                  },
                ),
        ),
        const KnowledgeBaseToggle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(children: [
            Expanded(
                child: WinTextField(
                    hint: context.l10n.instAiHint,
                    controller: _ctrl)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(color: s.primary, shape: BoxShape.circle),
                  child: Icon(Icons.send, size: 20, color: s.onPrimary)),
            ),
          ]),
        ),
      ]),
    );
  }
}
