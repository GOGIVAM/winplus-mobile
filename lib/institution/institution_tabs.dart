import 'package:flutter/material.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../services/institution_service.dart';
import '../services/subject_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'at_risk_screen.dart';
import 'action_plan_screen.dart';
import 'group_create_screen.dart';


Widget _instHeader(BuildContext context, String? title) {
  final s = WinTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      if (title == null) Image.asset('assets/winplus-logo.png', width: 40)
      else Text(title, style: WinType.archivo(size: 22, color: s.onStrong)),
      const Spacer(),
      Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
      const SizedBox(width: 14),
      Container(width: 34, height: 34,
          decoration: BoxDecoration(color: WinColors.goldBg, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.apartment_outlined, size: 18, color: WinColors.gold)),
    ]),
  );
}

Widget _statCard(BuildContext c, IconData icon, String value, String label) {
  final s = WinTheme.of(c);
  return WinCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 20, color: s.primary),
    const SizedBox(height: 8),
    Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
    Text(label, style: WinType.labelM(s.onMuted)),
  ]));
}

Widget _instHeroStat(String value, String title) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
  child: Row(children: [
    Text(value, style: WinType.archivo(size: 22, color: WinColors.teal400)),
    const SizedBox(width: 10),
    Expanded(child: Text(title, style: WinType.labelS(WinColors.cream100).copyWith(fontWeight: FontWeight.w600))),
  ]),
);

class _GroupRow extends StatelessWidget {
  final ApiGroup g;
  final VoidCallback? onTap;
  const _GroupRow({required this.g, this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(onTap: onTap, child: Row(children: [
      Container(width: 44, height: 44, alignment: Alignment.center,
          decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(10)),
          child: Text('${g.memberCount}', style: WinType.archivo(size: 16, color: s.primary))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.name, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 2),
        Text(g.level, style: WinType.labelM(s.onMuted)),
      ])),
      const SizedBox(width: 10),
      Text('${g.memberCount} élèves', style: WinType.labelM(s.onFaint)),
    ]));
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
  ApiInstitutionAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await InstitutionService.instance.getGroups();
    final analytics = await InstitutionService.instance.getAnalytics();
    if (mounted) setState(() { _groups = groups; _analytics = analytics; });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final groups = _groups ?? [];
    final analytics = _analytics;
    final total = analytics?.totalStudents ?? groups.fold<int>(0, (a, g) => a + g.memberCount);

    return Column(children: [
      _instHeader(context, null),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [s.heroFrom, s.heroTo],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ÉTABLISSEMENT', style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text.rich(TextSpan(style: WinType.bodyL(WinColors.cream50), children: [
              TextSpan(text: '$total élèves', style: WinType.archivo(size: 16, color: WinColors.teal400).copyWith(fontStyle: FontStyle.italic)),
              const TextSpan(text: ' répartis en '),
              TextSpan(text: '${groups.length} groupes', style: WinType.archivo(size: 16, color: WinColors.teal400).copyWith(fontStyle: FontStyle.italic)),
              const TextSpan(text: ' actifs sur WinPlus.'),
            ])),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _instHeroStat(
                  analytics != null ? '${analytics.activeStudents}' : '—', 'élèves actifs')),
              const SizedBox(width: 10),
              Expanded(child: _instHeroStat(
                  analytics != null ? '${analytics.averageScore.round()}%' : '—', 'score moyen')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (_groups == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Row(children: [
            Expanded(child: _statCard(context, Icons.people_outline, '$total', 'Élèves')),
            const SizedBox(width: 10),
            Expanded(child: _statCard(context, Icons.grid_view_outlined, '${groups.length}', 'Groupes')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statCard(context, Icons.download_outlined,
                '${analytics?.downloadsThisMonth ?? '—'}', 'Téléch./mois')),
            const SizedBox(width: 10),
            Expanded(child: _statCard(context, Icons.quiz_outlined,
                '${analytics?.quizzesThisMonth ?? '—'}', 'Quiz/mois')),
          ]),
          const SizedBox(height: 24),
          Text('Alertes WinAI', style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          WinCard(child: Row(children: [
            const WinAIOrb(size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text('Analysez les performances de vos groupes et identifiez les élèves à risque.',
                style: WinType.bodyS(s.onSurface))),
          ])),
          const SizedBox(height: 16),
          Text('Groupes', style: WinType.archivo(size: 18, color: s.onStrong)),
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
      _instHeader(context, 'Groupes'),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: WinTextField(icon: Icons.search, hint: 'Rechercher un groupe…')),
      const SizedBox(height: 12),
      Expanded(child: _groups == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _groups!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _GroupRow(g: _groups![i], onTap: () {}),
              ),
              const SizedBox(height: 14),
              WinButton('Créer un groupe',
                  variant: WinButtonVariant.outline,
                  block: true,
                  icon: Icons.add,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GroupCreateScreen()));
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
      _instHeader(context, 'Catalogue'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WinCard(bg: WinColors.teal50, child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: WinColors.teal700),
            const SizedBox(width: 10),
            Expanded(child: Text('Licence établissement : contenus assignables à tous vos groupes.',
                style: WinType.bodyS(WinColors.teal700).copyWith(fontWeight: FontWeight.w600))),
          ]))),
      const SizedBox(height: 12),
      Expanded(child: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text('Aucun contenu disponible.', style: WinType.bodyM(s.onMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final subj = WinData.subjectById(item.toContent().subjectId);
                    return WinCard(padding: const EdgeInsets.all(12), child: Row(children: [
                      Container(width: 48, height: 48,
                          decoration: BoxDecoration(color: subj.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(subj.icon, size: 22, color: subj.color)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.titleM(s.onStrong)),
                        Text('${subj.short} · ${item.level ?? ''}', style: WinType.labelM(s.onMuted)),
                      ])),
                      const WinButton('Assigner', variant: WinButtonVariant.outline, small: true, icon: Icons.add),
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
  State<InstitutionAnalyticsTab> createState() => _InstitutionAnalyticsTabState();
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
    if (mounted) setState(() { _analytics = analytics; _groups = groups; });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final groups = _groups ?? [];

    return Column(children: [
      _instHeader(context, 'Analytics'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Row(children: [
          Expanded(child: _statCard(context, Icons.schedule,
              _analytics != null ? '${_analytics!.downloadsThisMonth}' : '—', 'Téléch./mois')),
          const SizedBox(width: 10),
          Expanded(child: _statCard(context, Icons.check_circle_outline,
              _analytics != null ? '${_analytics!.quizzesThisMonth}' : '—', 'Quiz/mois')),
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
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ActionPlanScreen()))),
        const SizedBox(height: 20),
        if (_groups == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Text('Performance par groupe', style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ...groups.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: 84, child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
              Expanded(child: WinProgressBar(g.memberCount.toDouble().clamp(0, 100))),
              const SizedBox(width: 8),
              SizedBox(width: 40, child: Text('${g.memberCount}', textAlign: TextAlign.right,
                  style: WinType.labelM(s.onMuted))),
            ]),
          )),
          const SizedBox(height: 12),
          Text('Matières les plus étudiées', style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ...[('math', 82), ('pc', 64), ('svt', 58), ('fr', 47)].map((e) {
            final subj = WinData.subjectById(e.$1);
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
              SizedBox(width: 84, child: Text(subj.short,
                  style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
              Expanded(child: WinProgressBar(e.$2.toDouble(), color: subj.color)),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('${e.$2}%', textAlign: TextAlign.right,
                  style: WinType.labelM(s.onMuted))),
            ]));
          }),
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
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Compte', style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Center(child: Column(children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(color: WinColors.goldBg, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.apartment_outlined, size: 40, color: WinColors.gold)),
          const SizedBox(height: 12),
          Text('Établissement WinPlus', style: WinType.archivo(size: 22, color: s.onStrong)),
          Text('Compte institution actif', style: WinType.bodyM(s.onMuted)),
        ])),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: s.inkCard, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.shield_outlined, size: 20, color: WinColors.teal400),
              const SizedBox(width: 8),
              Expanded(child: Text('Licence Établissement', style: WinType.titleL(WinColors.cream50))),
              const WinBadge('Active', color: BadgeColor.teal),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Licences utilisées', style: WinType.bodyS(WinColors.ink200)),
              Text('— / —', style: WinType.bodyS(WinColors.cream50).copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            const WinProgressBar(0),
          ]),
        ),
        const SizedBox(height: 20),
        const _Row(Icons.people_outline, 'Administrateurs', trailing: WinBadge('3', color: BadgeColor.blue)),
        const _Row(Icons.grid_view_outlined, 'Groupes & classes'),
        const _Row(Icons.receipt_long_outlined, 'Facturation & reçus'),
        _Row(Icons.dark_mode_outlined, 'Mode sombre',
            trailing: Switch(value: state.dark, activeThumbColor: s.primary, onChanged: (_) => state.toggleTheme())),
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
                style: WinType.manrope(size: 14, weight: FontWeight.w600, color: WinColors.error))),
      ])),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _Row(this.icon, this.label, {this.trailing});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      height: 54,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.outline))),
      child: Row(children: [
        Icon(icon, size: 20, color: s.onFaint),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w500))),
        trailing ?? const Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
      ]),
    );
  }
}
