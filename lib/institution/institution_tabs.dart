import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

Color _actColor(int a) => a < 50 ? WinColors.error : (a < 70 ? WinColors.warn : WinColors.success);

Widget _instHeader(BuildContext context, String? title) {
  final s = WinTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      if (title == null) Image.asset('assets/winplus-logo.png', width: 40)
      else Text(title, style: WinType.fraunces(size: 22, color: s.onStrong)),
      const Spacer(),
      Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
      const SizedBox(width: 14),
      Container(width: 34, height: 34, decoration: BoxDecoration(color: WinColors.goldBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.apartment_outlined, size: 18, color: WinColors.gold)),
    ]),
  );
}

Widget _statCard(BuildContext c, IconData icon, String value, String label) {
  final s = WinTheme.of(c);
  return WinCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 20, color: s.primary),
    const SizedBox(height: 8),
    Text(value, style: WinType.fraunces(size: 22, color: s.onStrong)),
    Text(label, style: WinType.labelM(s.onMuted)),
  ]));
}

class _GroupRow extends StatelessWidget {
  final Group g;
  final VoidCallback? onTap;
  const _GroupRow({required this.g, this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(onTap: onTap, child: Row(children: [
      Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(10)), child: Text('${g.students}', style: WinType.fraunces(size: 16, color: s.primary))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.name, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: WinProgressBar(g.activity.toDouble(), color: _actColor(g.activity))), const SizedBox(width: 8), Text('${g.activity}%', style: WinType.labelM(s.onMuted))]),
      ])),
      const SizedBox(width: 10),
      Column(children: [Text('${g.avgScore}%', style: WinType.fraunces(size: 16, color: s.onStrong)), Text('score', style: WinType.labelS(s.onFaint))]),
    ]));
  }
}

/// ===================== ACCUEIL =====================
class InstitutionDashTab extends StatelessWidget {
  const InstitutionDashTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final total = WinData.groups.fold(0, (a, g) => a + g.students);
    final avgAct = (WinData.groups.fold(0, (a, g) => a + g.activity) / WinData.groups.length).round();
    final avgScore = (WinData.groups.fold(0, (a, g) => a + g.avgScore) / WinData.groups.length).round();
    return Column(children: [
      _instHeader(context, null),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [s.heroFrom, s.heroTo], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LYCÉE BILINGUE DE YAOUNDÉ', style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text.rich(TextSpan(style: WinType.bodyL(WinColors.cream50), children: [
              TextSpan(text: '$total élèves', style: WinType.fraunces(size: 16, color: WinColors.teal400).copyWith(fontStyle: FontStyle.italic)),
              const TextSpan(text: ' répartis en '),
              TextSpan(text: '${WinData.groups.length} groupes', style: WinType.fraunces(size: 16, color: WinColors.teal400).copyWith(fontStyle: FontStyle.italic)),
              const TextSpan(text: ' actifs sur WinPlus.'),
            ])),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _instHeroStat('$avgAct%', 'activité moyenne')),
              const SizedBox(width: 10),
              Expanded(child: _instHeroStat('$avgScore%', 'score moyen')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _statCard(context, Icons.people_outline, '$total', 'Élèves')), const SizedBox(width: 10), Expanded(child: _statCard(context, Icons.grid_view_outlined, '${WinData.groups.length}', 'Groupes'))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _statCard(context, Icons.layers_outlined, '248', 'Licences')), const SizedBox(width: 10), Expanded(child: _statCard(context, Icons.trending_up, '$avgScore%', 'Score moyen'))]),
        const SizedBox(height: 24),
        Text('Alertes WinAI', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        WinCard(child: Row(children: [const WinAIOrb(size: 26), const SizedBox(width: 12), Expanded(child: Text('Le groupe BTS Info 1 montre une activité faible (34%). Envisage une session de remobilisation.', style: WinType.bodyS(s.onSurface)))])),
        const SizedBox(height: 16),
        Text('Groupes', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ...WinData.groups.take(3).map((g) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _GroupRow(g: g))),
      ])),
    ]);
  }
}

Widget _instHeroStat(String value, String title) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(value, style: WinType.fraunces(size: 22, color: WinColors.teal400)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: WinType.labelS(WinColors.cream100).copyWith(fontWeight: FontWeight.w600))),
      ]),
    );

/// ===================== GROUPES =====================
class InstitutionGroupsTab extends StatelessWidget {
  const InstitutionGroupsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _instHeader(context, 'Groupes'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: WinTextField(icon: Icons.search, hint: 'Rechercher un groupe…')),
      const SizedBox(height: 12),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), itemCount: WinData.groups.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _GroupRow(g: WinData.groups[i], onTap: () {}))),
    ]);
  }
}

/// ===================== CATALOGUE =====================
class InstitutionCatalogTab extends StatelessWidget {
  const InstitutionCatalogTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      _instHeader(context, 'Catalogue'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: WinCard(bg: WinColors.teal50, child: Row(children: [const Icon(Icons.info_outline, size: 18, color: WinColors.teal700), const SizedBox(width: 10), Expanded(child: Text('Licence établissement : contenus assignables à tous tes groupes.', style: WinType.bodyS(WinColors.teal700).copyWith(fontWeight: FontWeight.w600)))]))),
      const SizedBox(height: 12),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), itemCount: WinData.catalog.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) {
        final item = WinData.catalog[i];
        final subj = WinData.subjectById(item.subjectId);
        return WinCard(padding: const EdgeInsets.all(12), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: subj.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(subj.icon, size: 22, color: subj.color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.titleM(s.onStrong)), Text('${subj.short} · ${item.level}', style: WinType.labelM(s.onMuted))])),
          WinButton('Assigner', variant: WinButtonVariant.outline, small: true, icon: Icons.add),
        ]));
      })),
    ]);
  }
}

/// ===================== ANALYTICS =====================
class InstitutionAnalyticsTab extends StatelessWidget {
  const InstitutionAnalyticsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      _instHeader(context, 'Analytics'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Row(children: [Expanded(child: _statCard(context, Icons.schedule, '1 240 h', "Étude (sem.)")), const SizedBox(width: 10), Expanded(child: _statCard(context, Icons.check_circle_outline, '386', 'Quiz complétés'))]),
        const SizedBox(height: 20),
        Text('Performance par groupe', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ...WinData.groups.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          SizedBox(width: 84, child: Text(g.name, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
          Expanded(child: WinProgressBar(g.avgScore.toDouble(), color: _actColor(g.avgScore))),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('${g.avgScore}%', textAlign: TextAlign.right, style: WinType.labelM(s.onMuted))),
        ]))),
        const SizedBox(height: 12),
        Text('Matières les plus étudiées', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ...[('math', 82), ('pc', 64), ('svt', 58), ('fr', 47)].map((e) {
          final subj = WinData.subjectById(e.$1);
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            SizedBox(width: 84, child: Text(subj.short, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
            Expanded(child: WinProgressBar(e.$2.toDouble(), color: subj.color)),
            const SizedBox(width: 8),
            SizedBox(width: 32, child: Text('${e.$2}%', textAlign: TextAlign.right, style: WinType.labelM(s.onMuted))),
          ]));
        }),
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
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Compte', style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Center(child: Column(children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: WinColors.goldBg, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.apartment_outlined, size: 40, color: WinColors.gold)),
          const SizedBox(height: 12),
          Text('Lycée Bilingue de Yaoundé', style: WinType.fraunces(size: 22, color: s.onStrong)),
          Text('Établissement secondaire · 161 élèves', style: WinType.bodyM(s.onMuted)),
        ])),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: s.inkCard, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.shield_outlined, size: 20, color: WinColors.teal400), const SizedBox(width: 8), Expanded(child: Text('Licence Établissement', style: WinType.titleL(WinColors.cream50))), const WinBadge('Active', color: BadgeColor.teal)]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Licences utilisées', style: WinType.bodyS(WinColors.ink200)), Text('248 / 300', style: WinType.bodyS(WinColors.cream50).copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 8),
            const WinProgressBar(82, color: WinColors.teal400),
            const SizedBox(height: 10),
            Text('Renouvellement le 1er septembre 2026', style: WinType.labelM(WinColors.ink300)),
          ]),
        ),
        const SizedBox(height: 20),
        _Row(Icons.people_outline, 'Administrateurs', trailing: const WinBadge('3', color: BadgeColor.blue)),
        _Row(Icons.grid_view_outlined, 'Groupes & classes', trailing: WinBadge('${WinData.groups.length}')),
        _Row(Icons.receipt_long_outlined, 'Facturation & reçus'),
        _Row(Icons.dark_mode_outlined, 'Mode sombre', trailing: Switch(value: state.dark, activeColor: s.primary, onChanged: (_) => state.toggleTheme())),
        _Row(Icons.language, 'Langue', trailing: const WinBadge('FR')),
        const SizedBox(height: 8),
        TextButton(onPressed: () {}, child: Text('Se déconnecter', style: WinType.manrope(size: 14, weight: FontWeight.w600, color: WinColors.error))),
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
        Expanded(child: Text(label, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w500))),
        trailing ?? Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
      ]),
    );
  }
}
