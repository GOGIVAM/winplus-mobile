import 'package:flutter/material.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
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

Widget _instHeroStat(String value, String title) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(value, style: WinType.archivo(size: 22, color: WinColors.teal400)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: WinType.labelS(WinColors.cream100)
                    .copyWith(fontWeight: FontWeight.w600))),
      ]),
    );

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
                  borderRadius: BorderRadius.circular(10)),
              child: Text('${g.memberCount}',
                  style: WinType.archivo(size: 16, color: s.primary))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(g.name, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 2),
                Text(g.level, style: WinType.labelM(s.onMuted)),
              ])),
          const SizedBox(width: 10),
          Text('${g.memberCount} élèves', style: WinType.labelM(s.onFaint)),
        ]),
        if (showActions) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: WinButton(
              'Voir élèves',
              small: true,
              icon: Icons.people_outline,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GroupMembersScreen(
                          groupId: g.id, groupName: g.name))),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: WinButton(
              'Attribuer ressources',
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Attribuer à ${group.name}',
                  style: WinType.titleL(s.onStrong)),
              const SizedBox(height: 4),
              Text(
                  'Sélectionnez des contenus depuis le catalogue pour les affecter à ce groupe.',
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 20),
              WinButton('Parcourir le catalogue',
                  block: true,
                  icon: Icons.layers_outlined,
                  onTap: () => Navigator.pop(context)),
              const SizedBox(height: 10),
              WinButton('Annuler',
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await InstitutionService.instance.getGroups();
    final atRisk = await InstitutionService.instance.getAtRiskStudents();
    if (mounted)
      setState(() {
        _groups = groups;
        _atRiskCount = atRisk.length;
      });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final groups = _groups ?? [];
    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                      colors: [s.heroFrom, s.heroTo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(WinData.institutionStats.name,
                                style: WinType.archivo(
                                    size: 15, color: WinColors.cream50)),
                            const SizedBox(height: 2),
                            Text('Plan ${WinData.institutionStats.plan}',
                                style: WinType.labelS(WinColors.ink300)),
                          ])),
                      Stack(clipBehavior: Clip.none, children: [
                        const Icon(Icons.notifications_outlined,
                            color: WinColors.cream100, size: 26),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                                color: WinColors.error, shape: BoxShape.circle),
                          ),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _instHeroStat(
                              '${WinData.institutionStats.activeStudentsToday}',
                              'actifs auj.')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _instHeroStat(
                              '${WinData.institutionStats.avgSuccessRate}%',
                              'taux réussite')),
                    ]),
                  ]),
            ),
            const SizedBox(height: 16),
            if (_groups == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              // KPIs grille 2x2
              Builder(builder: (ctx) {
                const st = WinData.institutionStats;
                final pctActive =
                    (st.activeStudentsToday / st.licensesTotal * 100).round();
                final pctLic =
                    (st.licensesUsed / st.licensesTotal * 100).round();
                return Column(children: [
                  Row(children: [
                    Expanded(
                        child: _statCard(
                            ctx,
                            Icons.people_outline,
                            '${st.activeStudentsToday} / ${st.licensesTotal}',
                            'Élèves actifs ($pctActive%)')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(ctx, Icons.trending_up_outlined,
                            '${st.avgSuccessRate}%', 'Taux réussite')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: _statCard(ctx, Icons.psychology_outlined,
                            '${st.quizThisWeek}', 'Quiz cette semaine')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(
                            ctx,
                            Icons.vpn_key_outlined,
                            '${st.licensesUsed} / ${st.licensesTotal}',
                            'Licences ($pctLic%)')),
                  ]),
                ]);
              }),
              const SizedBox(height: 16),
              // Alert élèves à risque
              if (_atRiskCount > 0) ...[
                WinCard(
                  bg: WinColors.errorBg,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AtRiskScreen())),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: WinColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            '$_atRiskCount élèves nécessitent une attention urgente',
                            style: WinType.bodyS(WinColors.error)
                                .copyWith(fontWeight: FontWeight.w600))),
                    const Spacer(),
                    const Icon(Icons.arrow_forward,
                        color: WinColors.error, size: 18),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              // Bouton Plan d'action IA
              WinButton("Plan d'action IA",
                  block: true,
                  icon: Icons.auto_awesome_outlined,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActionPlanScreen()))),
              const SizedBox(height: 16),
              // Section matières les plus étudiées
              Text('Matières les plus étudiées',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...() {
                const subjStats = WinData.subjectStats;
                final maxSess = subjStats.isEmpty
                    ? 1
                    : subjStats.fold(
                        0, (m, st) => st.sessions > m ? st.sessions : m);
                const rangs = ['1.', '2.', '3.', '4.'];
                return subjStats.take(4).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final st = entry.value;
                  final pct = st.sessions / maxSess * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WinCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(rangs[i],
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(st.subject,
                                      style: WinType.titleM(s.onStrong))),
                              Text('${st.sessions} sessions',
                                  style: WinType.labelM(s.onMuted)),
                            ]),
                            const SizedBox(height: 8),
                            WinProgressBar(pct),
                          ],
                        )),
                  );
                });
              }(),
              const SizedBox(height: 16),
              Text('Actions rapides',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: WinButton('Annuaire',
                        variant: WinButtonVariant.outline,
                        block: true,
                        icon: Icons.people_outline,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StudentDirectoryScreen())))),
                const SizedBox(width: 10),
                Expanded(
                    child: WinButton('Rapports',
                        variant: WinButtonVariant.outline,
                        block: true,
                        icon: Icons.bar_chart_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReportsScreen())))),
              ]),
              const SizedBox(height: 24),
              Text('Alertes WinAI',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              WinCard(
                  child: Row(children: [
                const WinAIOrb(size: 26),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Analysez les performances de vos groupes et identifiez les élèves à risque.',
                        style: WinType.bodyS(s.onSurface))),
              ])),
              const SizedBox(height: 16),
              Text('Groupes',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...groups.take(3).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupRow(g: g))),
            ],
          ])),
    ]);
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
      const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:
              WinTextField(icon: Icons.search, hint: 'Rechercher un groupe…')),
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
                      WinButton('Créer un groupe',
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: Icons.add, onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
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
                        'Licence établissement : contenus assignables à tous vos groupes.',
                        style: WinType.bodyS(WinColors.teal700)
                            .copyWith(fontWeight: FontWeight.w600))),
              ]))),
      const SizedBox(height: 12),
      Expanded(
          child: items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(
                      child: Text('Aucun contenu disponible.',
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
                                      borderRadius: BorderRadius.circular(12)),
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
                                    Text('${subj.short} · ${item.level ?? ''}',
                                        style: WinType.labelM(s.onMuted)),
                                  ])),
                              const WinButton('Assigner',
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
                      'Téléch./mois')),
              const SizedBox(width: 10),
              Expanded(
                  child: _statCard(
                      context,
                      Icons.check_circle_outline,
                      _analytics != null
                          ? '${_analytics!.quizzesThisMonth}'
                          : '',
                      'Quiz/mois')),
            ]),
            const SizedBox(height: 10),
            WinButton('Élèves à risque',
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.warning_amber_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AtRiskScreen()))),
            const SizedBox(height: 10),
            WinButton('Plan d\'action WinAI',
                variant: WinButtonVariant.ghost,
                block: true,
                icon: Icons.auto_awesome_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ActionPlanScreen()))),
            const SizedBox(height: 20),
            if (_groups == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('Performance par groupe',
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
              const SizedBox(height: 12),
              Text('Matières les plus étudiées',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...() {
                const nameToId = <String, String>{
                  'Mathématiques': 'math',
                  'Physique-Chimie': 'pc',
                  'Français': 'fr',
                  'SVT': 'svt',
                };
                const subjStats = WinData.subjectStats;
                final maxSess = subjStats.isEmpty
                    ? 1
                    : subjStats.fold(
                        0, (m, st) => st.sessions > m ? st.sessions : m);
                return subjStats.map((st) {
                  final subj =
                      WinData.subjectById(nameToId[st.subject] ?? 'math');
                  final pct = (st.sessions / maxSess * 100).round();
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        SizedBox(
                            width: 84,
                            child: Text(subj.short,
                                style: WinType.bodyM(s.onStrong)
                                    .copyWith(fontWeight: FontWeight.w600))),
                        Expanded(
                            child: WinProgressBar(pct.toDouble(),
                                color: subj.color)),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 32,
                            child: Text('$pct%',
                                textAlign: TextAlign.right,
                                style: WinType.labelM(s.onMuted))),
                      ]));
                });
              }(),
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
              child: Text('Compte',
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
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.apartment_outlined,
                      size: 40, color: WinColors.gold)),
              const SizedBox(height: 12),
              Text(WinData.institutionStats.name,
                  style: WinType.archivo(size: 22, color: s.onStrong)),
              Text('Plan ${WinData.institutionStats.plan} · Compte actif',
                  style: WinType.bodyM(s.onMuted)),
            ])),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: s.inkCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.shield_outlined,
                          size: 20, color: WinColors.teal400),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Licence Établissement',
                              style: WinType.titleL(WinColors.cream50))),
                      const WinBadge('Active', color: BadgeColor.teal),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Licences utilisées',
                              style: WinType.bodyS(WinColors.ink200)),
                          Text(
                              '${fmtXaf(WinData.institutionStats.licensesUsed)} / ${fmtXaf(WinData.institutionStats.licensesTotal)}',
                              style: WinType.bodyS(WinColors.cream50)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ]),
                    const SizedBox(height: 8),
                    WinProgressBar(WinData.institutionStats.licensesUsed /
                        WinData.institutionStats.licensesTotal *
                        100),
                  ]),
            ),
            const SizedBox(height: 20),
            const _Row(Icons.people_outline, 'Administrateurs',
                trailing: WinBadge('3', color: BadgeColor.blue)),
            const _Row(Icons.grid_view_outlined, 'Groupes & classes'),
            const _Row(Icons.receipt_long_outlined, 'Facturation & reçus'),
            _Row(Icons.bar_chart_outlined, 'Rapports exportables',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()))),
            _Row(Icons.dark_mode_outlined, 'Mode sombre',
                trailing: Switch(
                    value: state.dark,
                    activeThumbColor: s.primary,
                    onChanged: (_) => state.toggleTheme())),
            const _Row(Icons.language, 'Langue', trailing: WinBadge('FR')),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (r) => false,
                  );
                },
                child: Text('Se déconnecter',
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
  const InstitutionWinAITab({super.key});
  @override
  State<InstitutionWinAITab> createState() => _InstitutionWinAITabState();
}

class _InstitutionWinAITabState extends State<InstitutionWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text})> _msgs = [];
  bool _thinking = false;

  static const _suggestions = [
    'Analyse de cohorte',
    'Élèves à risque',
    'Plan d\'action prioritaire',
    'Benchmark national',
  ];

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
        text: reply ?? 'Désolé, je n\'ai pas pu répondre. Réessaie.'
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
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
                  Text('Ton auditeur analytique & stratège institutionnel',
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
                                    borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.psychology_rounded, size: 15, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Text('Mémoire WinAI', style: WinType.manrope(size: 13, weight: FontWeight.w600, color: const Color(0xFF8B5CF6))),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF8B5CF6)),
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
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: s.primary)),
                          const SizedBox(width: 8),
                          Text('WinAI réfléchit…',
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text,
                          style: WinType.bodyM(
                              m.me ? WinColors.cream50 : s.onSurface)),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(children: [
          Expanded(
              child: WinTextField(
                  hint: 'Analyse, benchmark, plan d\'action…',
                  controller: _ctrl)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
                width: 48,
                height: 50,
                decoration: BoxDecoration(
                    color: s.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.send, size: 20, color: s.onPrimary)),
          ),
        ]),
      ),
    ]);
  }
}
