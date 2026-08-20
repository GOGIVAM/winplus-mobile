import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

Color _trendColor(int s) =>
    s < 50 ? WinColors.error : (s < 75 ? WinColors.warn : WinColors.success);

/// ===================== ACCUEIL PARENT =====================
class ParentDashTab extends StatelessWidget {
  const ParentDashTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final kids = WinData.children;
    final avg =
        (kids.map((k) => k.weekScore).reduce((a, b) => a + b) / kids.length)
            .round();
    return Column(children: [
      _ParentTopBar(),
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
                      Text('BONJOUR MME NKONO',
                          style: WinType.labelS(WinColors.ink300)
                              .copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(
                          style: WinType.bodyL(WinColors.cream50),
                          children: [
                            const TextSpan(text: 'Vos '),
                            TextSpan(
                                text: '${kids.length} enfants',
                                style: WinType.fraunces(
                                        size: 16, color: WinColors.teal400)
                                    .copyWith(fontStyle: FontStyle.italic)),
                            const TextSpan(text: ' ont étudié '),
                            TextSpan(
                                text: '13h 30',
                                style: WinType.fraunces(
                                        size: 16, color: WinColors.teal400)
                                    .copyWith(fontStyle: FontStyle.italic)),
                            const TextSpan(text: ' cette semaine.'),
                          ])),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: _PHeroStat(
                                '$avg%', 'score moyen', 'Cette semaine')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _PHeroStat(
                                '8', 'quiz complétés', 'Tous enfants')),
                      ]),
                    ]),
              ),
              const SizedBox(height: 24),
              Text('Alertes & conseils WinAI',
                  style: WinType.fraunces(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...kids.map((k) {
                final warn = k.alertType == 'warn';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WinCard(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WinAIOrb(size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Text(k.name,
                                      style: WinType.titleM(s.onStrong)),
                                  const SizedBox(width: 8),
                                  WinBadge(
                                      warn
                                          ? 'À surveiller'
                                          : 'Sur la bonne voie',
                                      color: warn
                                          ? BadgeColor.warn
                                          : BadgeColor.success)
                                ]),
                                const SizedBox(height: 4),
                                Text(k.alertMsg,
                                    style: WinType.bodyS(s.onMuted)),
                              ])),
                        ]),
                  ),
                );
              }),
              const SizedBox(height: 14),
              Text('Mes enfants',
                  style: WinType.fraunces(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              ...kids.map((k) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChildCard(child: k))),
            ]),
      ),
    ]);
  }
}

class _PHeroStat extends StatelessWidget {
  final String value, title, sub;
  const _PHeroStat(this.value, this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(value,
            style: WinType.fraunces(size: 24, color: WinColors.teal400)),
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

class ChildCard extends StatelessWidget {
  final Child child;
  const ChildCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      child: Row(children: [
        WinAvatar(child.name,
            size: 48,
            progress: child.progress.toDouble(),
            color: WinColors.blue100),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(child.name, style: WinType.titleL(s.onStrong)),
            if (child.streak > 0) ...[
              const SizedBox(width: 8),
              WinStreakFlame(child.streak, size: 16)
            ]
          ]),
          const SizedBox(height: 2),
          Text('${child.level} · actif ${child.lastActive}',
              style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: WinProgressBar(child.weekScore.toDouble(),
                    color: _trendColor(child.weekScore))),
            const SizedBox(width: 8),
            Text('${child.weekScore}%', style: WinType.labelM(s.onMuted))
          ]),
        ])),
        Icon(Icons.chevron_right, color: WinColors.ink300),
      ]),
    );
  }
}

class _ParentTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Image.asset('assets/winplus-logo.png', width: 40),
        const Spacer(),
        Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
        const SizedBox(width: 14),
        const WinAvatar('Mme Nkono', size: 34, color: WinColors.blue100),
      ]),
    );
  }
}

/// ===================== ENFANTS =====================
class ParentChildrenTab extends StatelessWidget {
  const ParentChildrenTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mes enfants',
                  style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            ...WinData.children.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChildCard(child: k))),
            const SizedBox(height: 4),
            WinButton('Ajouter un enfant',
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.add),
          ])),
    ]);
  }
}

/// ===================== RESSOURCES =====================
class ParentResourcesTab extends StatelessWidget {
  const ParentResourcesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final reco = WinData.catalog.where((c) => !c.free).take(4).toList();
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Ressources',
                  style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            WinCard(
                child: Row(children: [
              const WinAIOrb(size: 26),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      "D'après les résultats d'Ahmed, ces ressources cibleront ses points faibles.",
                      style: WinType.bodyS(WinColors.ink700)))
            ])),
            const SizedBox(height: 16),
            Text('Recommandées par WinAI',
                style: WinType.fraunces(size: 18, color: s.onStrong)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
              children:
                  reco.map((c) => _ParentContentCard(content: c)).toList(),
            ),
          ])),
    ]);
  }
}

class _ParentContentCard extends StatelessWidget {
  final Content content;
  const _ParentContentCard({required this.content});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(content.subjectId);
    return WinCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              height: 92,
              decoration: BoxDecoration(
                  color: subj.color.withOpacity(0.12),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child:
                  Center(child: Icon(subj.icon, size: 38, color: subj.color))),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: 38,
                        child: Text(content.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WinType.titleM(s.onStrong))),
                    const SizedBox(height: 8),
                    Text('${fmtXaf(content.price)}\u00a0XAF',
                        style: WinType.fraunces(size: 18, color: s.onStrong)),
                  ])),
        ]));
  }
}

/// ===================== PAIEMENTS =====================
class ParentPaymentsTab extends StatelessWidget {
  const ParentPaymentsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final history = [
      ('Pack ENSP 2020–2023', '8 juin · MTN', 8000),
      ('Abonnement Premium  Ahmed', '1 juin · Orange', 5000),
      ('Correction BAC C Physique', '28 mai · MTN', 3000),
      ('Abonnement Standard  Léa', '25 mai · Orange', 2500),
    ];
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Paiements',
                  style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      colors: [s.heroFrom, s.heroTo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DÉPENSES CE MOIS',
                        style: WinType.labelS(WinColors.ink300)
                            .copyWith(letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Text('18 500 XAF',
                        style: WinType.fraunces(
                            size: 32, color: WinColors.cream50)),
                  ]),
            ),
            const SizedBox(height: 20),
            Text('Historique',
                style: WinType.fraunces(size: 18, color: s.onStrong)),
            const SizedBox(height: 12),
            WinCard(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(children: [
                  for (int i = 0; i < history.length; i++)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: i < history.length - 1
                              ? Border(bottom: BorderSide(color: s.outline))
                              : null),
                      child: Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                                color: WinColors.successBg,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                size: 16, color: WinColors.success)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(history[i].$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: WinType.bodyM(s.onStrong)
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(history[i].$2,
                                  style: WinType.labelM(s.onMuted)),
                            ])),
                        Text('−${fmtXaf(history[i].$3)}',
                            style:
                                WinType.fraunces(size: 15, color: s.onStrong)),
                      ]),
                    ),
                ])),
          ])),
    ]);
  }
}

/// ===================== PROFIL =====================
class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = WinAppScope.of(context);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Profil',
                  style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            Center(
                child: Column(children: [
              const WinAvatar('Mme Nkono', size: 80, color: WinColors.blue100),
              const SizedBox(height: 12),
              Text('Mme Solange Nkono',
                  style: WinType.fraunces(size: 22, color: s.onStrong)),
              Text('Parent · 2 enfants', style: WinType.bodyM(s.onMuted)),
            ])),
            const SizedBox(height: 20),
            _Row(Icons.people_outline, 'Mes enfants',
                trailing: const WinBadge('2', color: BadgeColor.blue)),
            _Row(Icons.account_balance_wallet_outlined, 'Moyens de paiement'),
            _Row(Icons.dark_mode_outlined, 'Mode sombre',
                trailing: Switch(
                    value: state.dark,
                    activeColor: s.primary,
                    onChanged: (_) => state.toggleTheme())),
            _Row(Icons.language, 'Langue', trailing: const WinBadge('FR')),
            _Row(Icons.shield_outlined, 'Confidentialité & sécurité'),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () {},
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
  const _Row(this.icon, this.label, {this.trailing});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
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
            Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
      ]),
    );
  }
}
