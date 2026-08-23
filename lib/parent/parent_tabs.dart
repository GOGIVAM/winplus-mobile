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
import 'subscription_status_screen.dart';
import '../app_config.dart';
import '../shared/messaging/messaging_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../shared/subscription/pricing_screen.dart';


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
                      Text('BONJOUR',
                          style: WinType.labelS(WinColors.ink300)
                              .copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(
                          style: WinType.bodyL(WinColors.cream50),
                          children: [
                            const TextSpan(text: 'Vous avez '),
                            TextSpan(
                                text: '${kids.length} enfant${kids.length > 1 ? 's' : ''}',
                                style: WinType.archivo(
                                        size: 16, color: WinColors.teal400)
                                    .copyWith(fontStyle: FontStyle.italic)),
                            const TextSpan(text: ' suivis sur WinPlus.'),
                          ])),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: _PHeroStat('${kids.length}', 'enfants suivis', 'Total')),
                        const SizedBox(width: 10),
                        const Expanded(child: _PHeroStat('—', 'score moyen', 'Cette semaine')),
                      ]),
                    ]),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WinAIAlertsScreen())),
                child: Row(children: [
                  Text('Alertes & conseils WinAI',
                      style: WinType.archivo(size: 18, color: s.onStrong)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
                ]),
              ),
              const SizedBox(height: 12),
              if (_children == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text('Mes enfants', style: WinType.archivo(size: 18, color: s.onStrong)),
                const SizedBox(height: 12),
                ...kids.map((k) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChildCard(child: k))),
              ],
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
            _Row(Icons.chat_outlined, 'Messages',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MessagingScreen()))),
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
