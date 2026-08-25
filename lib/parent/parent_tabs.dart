import 'package:flutter/material.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/parent_service.dart';
import '../services/subject_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'child_activity_screen.dart';
import 'add_child_screen.dart';
import 'winai_alerts_screen.dart';
import 'subscription_status_screen.dart' hide RenewalSheet;
import '../app_config.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../shared/subscription/pricing_screen.dart';
import 'renewal_sheet.dart';
import 'buy_for_child_screen.dart';


/// ===================== ACCUEIL PARENT =====================
class ParentDashTab extends StatefulWidget {
  const ParentDashTab({super.key});
  @override
  State<ParentDashTab> createState() => _ParentDashTabState();
}

class _ParentDashTabState extends State<ParentDashTab> {
  List<ApiChild>? _children;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kids = await ParentService.instance.getChildren();
    if (mounted) setState(() => _children = kids);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final kids = _children ?? [];
    const events = WinData.childEvents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Hero gradient ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                  colors: [s.heroFrom, s.heroTo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BONJOUR', style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Row(children: [
              Text('Mme Nkono', style: WinType.archivo(size: 20, color: WinColors.cream50)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: WinColors.teal400.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Plan Famille',
                    style: WinType.manrope(size: 11, weight: FontWeight.w600, color: WinColors.teal300)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _PHeroStat('${kids.length}', 'enfants suivis', 'Total')),
              const SizedBox(width: 10),
              Expanded(child: _PHeroStat('${fmtXaf(WinData.parentAccount.creditsAvailable)} XAF', 'crédits dispo', 'Plan Famille 💰')),
            ]),
          ]),
        ),

        // ── Alertes WinAI ─────────────────────────────────────────
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WinAIAlertsScreen())),
          child: Row(children: [
            const WinAIOrb(size: 20),
            const SizedBox(width: 10),
            Text('Alertes & conseils WinAI', style: WinType.archivo(size: 16, color: s.onStrong)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
          ]),
        ),

        // ── Mes enfants (cards horizontales scrollables) ──────────
        const SizedBox(height: 20),
        Row(children: [
          Text('Mes enfants', style: WinType.archivo(size: 18, color: s.onStrong)),
          const Spacer(),
          if (kids.isNotEmpty)
            GestureDetector(
              onTap: () {},
              child: Text('Voir tout', style: WinType.labelM(s.primary)),
            ),
        ]),
        const SizedBox(height: 12),
        if (_children == null)
          const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
        else if (kids.isEmpty)
          WinCard(
            child: Text('Aucun enfant suivi. Ajoutez un enfant depuis l\'onglet Enfants.',
                style: WinType.bodyS(s.onMuted)),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kids.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _ChildSummaryCard(child: kids[i]),
            ),
          ),

        // ── Évènements à venir ────────────────────────────────────
        const SizedBox(height: 24),
        Text('Évènements à venir', style: WinType.archivo(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ...events.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _EventTile(event: e),
        )),

        // ── Acheter pour un enfant ────────────────────────────────
        const SizedBox(height: 8),
        WinButton(
          'Acheter du contenu pour un enfant',
          block: true,
          icon: Icons.shopping_bag_outlined,
          onTap: kids.isEmpty
              ? null
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BuyForChildScreen(children: kids))),
        ),
      ],
    );
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(value,
            style: WinType.archivo(size: 24, color: WinColors.teal400)),
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
  final ApiChild child;
  const ChildCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChildActivityScreen(child: child))),
      child: Row(children: [
        WinAvatar(child.fullName, size: 48, color: WinColors.blue100),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(child.fullName, style: WinType.titleL(s.onStrong)),
          const SizedBox(height: 2),
          Text(child.level ?? child.schoolName ?? 'Élève',
              style: WinType.labelM(s.onMuted)),
        ])),
        const Icon(Icons.chevron_right, color: WinColors.ink300),
      ]),
    );
  }
}


class _ChildSummaryCard extends StatelessWidget {
  final ApiChild child;
  const _ChildSummaryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final eng = WinData.engagementScores.firstWhere(
      (e) => e.childId == 'k${child.id}',
      orElse: () => const EngagementScore('_', 72, 64, 'up'),
    );
    final isUp = eng.trend == 'up';
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChildActivityScreen(child: child))),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WinAvatar(child.fullName, size: 36, color: WinColors.blue100),
          const SizedBox(height: 8),
          Text(child.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.titleM(s.onStrong)),
          Text(child.level ?? 'Élève',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.labelS(s.onMuted)),
          const Spacer(),
          Row(children: [
            Text('${eng.score}/100',
                style: WinType.archivo(size: 13, color: s.primary)),
            const SizedBox(width: 4),
            Icon(
              isUp ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: isUp ? WinColors.success : WinColors.error,
            ),
          ]),
        ]),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final ChildEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isRenewal = event.type == 'renewal';
    final icon = isRenewal ? Icons.autorenew : Icons.event_available_outlined;
    final color = isRenewal ? WinColors.warn : s.primary;
    return GestureDetector(
      onTap: isRenewal ? () => RenewalSheet.show(context) : null,
      child: WinCard(
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title,
                style: WinType.titleM(s.onStrong),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${event.childName} · ${event.date}',
                style: WinType.labelM(s.onMuted)),
          ])),
          if (isRenewal)
            Icon(Icons.chevron_right, size: 16, color: s.onFaint),
        ]),
      ),
    );
  }
}

/// ===================== ENFANTS =====================
class ParentChildrenTab extends StatefulWidget {
  const ParentChildrenTab({super.key});
  @override
  State<ParentChildrenTab> createState() => _ParentChildrenTabState();
}

class _ParentChildrenTabState extends State<ParentChildrenTab> {
  List<ApiChild>? _children;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kids = await ParentService.instance.getChildren();
    if (mounted) setState(() => _children = kids);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final kids = _children ?? [];
    final atChildLimit = !AppConfig.devMode &&
        SubscriptionScope.of(context).isFree &&
        kids.isNotEmpty;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mes enfants',
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(
          child: _children == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    ...kids.map((k) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChildCard(child: k))),
                    const SizedBox(height: 4),
                    if (atChildLimit)
                      WinButton('1 enfant max (plan gratuit)',
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: Icons.lock_outline,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const PricingScreen())))
                    else
                      WinButton('Ajouter un enfant',
                          variant: WinButtonVariant.outline,
                          block: true,
                          icon: Icons.add,
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const AddChildScreen()));
                            _load();
                          }),
                  ])),
    ]);
  }
}

/// ===================== RESSOURCES =====================
class ParentResourcesTab extends StatefulWidget {
  const ParentResourcesTab({super.key});
  @override
  State<ParentResourcesTab> createState() => _ParentResourcesTabState();
}

class _ParentResourcesTabState extends State<ParentResourcesTab> {
  List<Content>? _reco;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await SubjectService.instance.getAll(pageSize: 4);
      if (mounted) {
        setState(() => _reco = page.items
            .where((s) => !s.isFree)
            .take(4)
            .map((s) => s.toContent())
            .toList());
      }
    } catch (_) {
      if (mounted) setState(() => _reco = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final reco = _reco;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Ressources',
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
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
                      "D'après les résultats de vos enfants, ces ressources cibleront leurs points faibles.",
                      style: WinType.bodyS(WinColors.ink700)))
            ])),
            const SizedBox(height: 16),
            Text('Recommandées par WinAI',
                style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 12),
            if (reco == null)
              const Center(child: CircularProgressIndicator())
            else if (reco.isEmpty)
              Text('Aucun contenu disponible.', style: WinType.bodyM(s.onMuted))
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: reco.map((c) => _ParentContentCard(content: c)).toList(),
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
                  color: subj.color.withValues(alpha: 0.12),
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
                        style: WinType.archivo(size: 18, color: s.onStrong)),
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
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
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
                        style: WinType.archivo(
                            size: 32, color: WinColors.cream50)),
                  ]),
            ),
            const SizedBox(height: 20),
            Text('Historique',
                style: WinType.archivo(size: 18, color: s.onStrong)),
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
                                WinType.archivo(size: 15, color: s.onStrong)),
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
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
            Center(
                child: Column(children: [
              const WinAvatar('Mme Nkono', size: 80, color: WinColors.blue100),
              const SizedBox(height: 12),
              Text('Mme Solange Nkono',
                  style: WinType.archivo(size: 22, color: s.onStrong)),
              Text('Parent · 2 enfants', style: WinType.bodyM(s.onMuted)),
            ])),
            const SizedBox(height: 20),
            const _Row(Icons.people_outline, 'Mes enfants',
                trailing: WinBadge('2', color: BadgeColor.blue)),
            _Row(Icons.account_balance_wallet_outlined, 'Mon abonnement',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SubscriptionStatusScreen()))),
            _Row(Icons.autorenew, 'Gérer l\'abonnement',
                onTap: () => RenewalSheet.show(context)),
            _Row(Icons.payment_outlined, 'Paiements & historique',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _PaymentsScreen()))),
            _Row(Icons.dark_mode_outlined, 'Mode sombre',
                trailing: Switch(
                    value: state.dark,
                    activeThumbColor: s.primary,
                    onChanged: (_) => state.toggleTheme())),
            const _Row(Icons.language, 'Langue', trailing: WinBadge('FR')),
            const _Row(Icons.shield_outlined, 'Confidentialité & sécurité'),
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
              const Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
        ]),
      ),
    );
  }
}

class _PaymentsScreen extends StatelessWidget {
  const _PaymentsScreen();
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
        title: Text('Paiements', style: WinType.headlineS(s.onStrong)),
      ),
      body: const ParentPaymentsTab(),
    );
  }
}
