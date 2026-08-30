import 'package:flutter/material.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/chatbot_service.dart';
import '../services/parent_service.dart';
import '../services/subject_service.dart';
import '../services/subscription_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'child_activity_screen.dart';
import 'add_child_screen.dart';
import 'winai_alerts_screen.dart';
import 'subscription_status_screen.dart' hide RenewalSheet;
import '../shared/subscription/subscription_notifier.dart';
import '../shared/subscription/pricing_screen.dart';
import 'renewal_sheet.dart';
import 'buy_for_child_screen.dart';
import '../shared/legal_screen.dart';


/// ===================== ACCUEIL PARENT =====================

const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

class ParentDashTab extends StatefulWidget {
  const ParentDashTab({super.key});
  @override
  State<ParentDashTab> createState() => _ParentDashTabState();
}

class _ParentDashTabState extends State<ParentDashTab> {
  List<ApiChild>? _children;
  List<ApiWinAIAlert> _alerts = [];
  ApiActiveSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kids = await ParentService.instance.getChildren();
    final alerts = await ParentService.instance.getAlerts();
    final sub = await SubscriptionService.instance.getCurrent();
    if (mounted) setState(() { _children = kids; _alerts = alerts; _sub = sub; });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final kids = _children ?? [];
    final tracked = WinData.trackedChildren;
    final events = WinData.upcomingEvents;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Bonjour' : (hour < 18 ? 'Bon après-midi' : 'Bonsoir');
    final firstName = WinData.parentAccount.name.split(' ').first;
    final dateLabel = '${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]} ${now.year}';

    // Crédits
    final creditsAvail = WinData.parentAccount.creditsAvailable;
    final creditsTotal = WinData.parentAccount.creditsTotal;
    final creditsPct = creditsTotal > 0 ? creditsAvail / creditsTotal * 100 : 0.0;

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
            Text(dateLabel, style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('$greeting $firstName',
                style: WinType.archivo(size: 20, color: WinColors.cream50)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: WinColors.teal400.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Plan ${WinData.parentAccount.plan}',
                    style: WinType.manrope(size: 11, weight: FontWeight.w600, color: WinColors.teal300)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _PHeroStat('${tracked.length}', 'enfants suivis', 'Total')),
              const SizedBox(width: 10),
              Expanded(child: _PHeroStat('${fmtXaf(creditsAvail)} XAF', 'crédits dispo', 'Solde')),
            ]),
          ]),
        ),

        // ── Carte crédits ─────────────────────────────────────────
        const SizedBox(height: 16),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 20, color: WinColors.teal500),
              const SizedBox(width: 8),
              Text('Crédits disponibles', style: WinType.titleM(s.onStrong)),
            ]),
            const SizedBox(height: 12),
            WinProgressBar(creditsPct, height: 8, color: WinColors.teal500),
            const SizedBox(height: 8),
            Row(children: [
              Text('${fmtXaf(creditsAvail)} XAF',
                  style: WinType.manrope(size: 13, weight: FontWeight.w700, color: WinColors.teal600)),
              Text(' / ${fmtXaf(creditsTotal)} XAF',
                  style: WinType.labelS(s.onMuted)),
            ]),
            if (_sub != null) ...[
              const SizedBox(height: 6),
              Text(
                'Plan ${_sub!.planName} · Renouvellement dans ${_sub!.expiresAt.difference(DateTime.now()).inDays} jours',
                style: WinType.labelS(s.onMuted),
              ),
            ],
            const SizedBox(height: 12),
            WinButton('Voir l\'abonnement',
                variant: WinButtonVariant.ghost, small: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionStatusScreen()))),
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
        if (_alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          WinAlert(_alerts.first.message, type: BadgeColor.warn, icon: Icons.warning_amber_rounded),
        ],

        // ── Mes enfants (cards horizontales scrollables) ──────────
        const SizedBox(height: 20),
        Row(children: [
          Text('Mes enfants', style: WinType.archivo(size: 18, color: s.onStrong)),
          const Spacer(),
          if (tracked.isNotEmpty)
            GestureDetector(
              onTap: () {},
              child: Text('Voir tout', style: WinType.labelM(s.primary)),
            ),
        ]),
        const SizedBox(height: 12),
        if (_children == null)
          const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
        else if (tracked.isEmpty)
          WinCard(
            child: Text('Aucun enfant suivi. Ajoutez un enfant depuis l\'onglet Enfants.',
                style: WinType.bodyS(s.onMuted)),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tracked.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _TrackedChildCard(child: tracked[i]),
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


class _TrackedChildCard extends StatelessWidget {
  final TrackedChild child;
  const _TrackedChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final now = DateTime.now();
    final diff = now.difference(child.lastActiveAt);

    final Color statusColor;
    final String statusLabel;
    if (diff.inHours < 24) {
      statusColor = WinColors.success;
      statusLabel = 'Actif';
    } else if (diff.inDays == 1) {
      statusColor = WinColors.warn;
      statusLabel = 'Hier';
    } else {
      statusColor = WinColors.error;
      statusLabel = 'Inactif';
    }

    final Color scoreColor = child.avgScore >= 70
        ? WinColors.success
        : child.avgScore >= 50
            ? WinColors.warn
            : WinColors.error;

    final String trendSymbol = child.trend == Trend.up
        ? '↗'
        : child.trend == Trend.down
            ? '↘'
            : '→';
    final Color trendColor = child.trend == Trend.up
        ? WinColors.success
        : child.trend == Trend.down
            ? WinColors.error
            : WinColors.ink300;

    final firstName = child.name.split(' ').first;
    final lastName = child.name.split(' ').length > 1 ? child.name.split(' ').last : '';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChildActivityScreen(
                  child: ApiChild(
                      id: child.id.hashCode,
                      firstName: firstName,
                      lastName: lastName,
                      level: child.level,
                      schoolName: '')))),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WinAvatar(child.name, size: 44, color: WinColors.blue100),
          const SizedBox(height: 8),
          Text(firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.titleM(s.onStrong)),
          Text(child.level,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Text('${child.avgScore}%',
                style: WinType.archivo(size: 14, color: scoreColor)),
            const SizedBox(width: 6),
            Text(trendSymbol,
                style: WinType.manrope(size: 14, weight: FontWeight.w700, color: trendColor)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(statusLabel, style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final UpcomingEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isRenewal = event.type == 'renewal';
    final icon = isRenewal ? Icons.autorenew : Icons.event_available_outlined;
    final color = isRenewal ? WinColors.warn : s.primary;
    final days = event.date.difference(DateTime.now()).inDays;
    final daysLabel = days <= 0 ? "aujourd'hui" : 'dans $days jour${days > 1 ? 's' : ''}';
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
            Text(event.label,
                style: WinType.titleM(s.onStrong),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(daysLabel, style: WinType.labelM(s.onMuted)),
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
    final atChildLimit = SubscriptionScope.of(context).isFree && kids.isNotEmpty;
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
  List<ApiChild> _children = [];

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
    try {
      final kids = await ParentService.instance.getChildren();
      if (mounted) setState(() => _children = kids);
    } catch (_) {}
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
            const SizedBox(height: 20),
            WinButton(
              'Acheter du contenu pour un enfant',
              block: true,
              icon: Icons.shopping_bag_outlined,
              onTap: _children.isEmpty
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => BuyForChildScreen(children: _children))),
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
    final acct = WinData.parentAccount;
    final tracked = WinData.trackedChildren;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
          // ── Avatar + identité ────────────────────────────────────
          Center(
            child: Column(children: [
              WinAvatar(acct.name, size: 80, color: WinColors.blue100),
              const SizedBox(height: 12),
              Text(acct.name, style: WinType.archivo(size: 22, color: s.onStrong)),
              Text('parent@winplus.cm', style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: WinColors.teal500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WinColors.teal500.withValues(alpha: 0.4))),
                child: Text('Plan ${acct.plan}',
                    style: WinType.manrope(size: 12, weight: FontWeight.w700, color: WinColors.teal600)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Stats rapides ────────────────────────────────────────
          Row(children: [
            Expanded(child: _StatBox(
                '${tracked.length}', 'Enfants', Icons.child_care_outlined, WinColors.blue500)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(
                '${fmtXaf(acct.creditsAvailable)} XAF', 'Crédits', Icons.account_balance_wallet_outlined, WinColors.teal500)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(
                '${_alertCount(tracked)}', 'Alertes WinAI', Icons.notifications_outlined, WinColors.warn)),
          ]),
          const SizedBox(height: 20),

          // ── Enfants liés ─────────────────────────────────────────
          if (tracked.isNotEmpty) ...[
            Text('Enfants suivis', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 10),
            ...tracked.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChildActivityScreen(child: ApiChild(
                      id: c.id.hashCode,
                      firstName: c.name.split(' ').first,
                      lastName: c.name.split(' ').length > 1 ? c.name.split(' ').last : '',
                      level: c.level, schoolName: '')))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: s.surface2, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: s.outline)),
                  child: Row(children: [
                    WinAvatar(c.name, size: 36, color: WinColors.blue100),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name.split(' ').first, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
                      Text(c.level, style: WinType.labelS(s.onMuted)),
                    ])),
                    Container(width: 8, height: 8, decoration: BoxDecoration(
                        color: DateTime.now().difference(c.lastActiveAt).inHours < 24
                            ? WinColors.success : WinColors.warn,
                        shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${c.avgScore}%', style: WinType.labelM(s.onMuted)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: WinColors.ink300),
                  ]),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],

          // ── Paramètres ───────────────────────────────────────────
          const SizedBox(height: 4),
          _Row(Icons.account_balance_wallet_outlined, 'Mon abonnement',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SubscriptionStatusScreen()))),
          _Row(Icons.autorenew, 'Gérer l\'abonnement',
              onTap: () => RenewalSheet.show(context)),
          _Row(Icons.payment_outlined, 'Paiements & historique',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _PaymentsScreen()))),
          _Row(Icons.notifications_outlined, 'Notifications',
              trailing: Switch(value: true, activeThumbColor: s.primary, onChanged: (_) {})),
          _Row(Icons.dark_mode_outlined, 'Mode sombre',
              trailing: Switch(
                  value: state.dark,
                  activeThumbColor: s.primary,
                  onChanged: (_) => state.toggleTheme())),
          const _Row(Icons.language, 'Langue', trailing: WinBadge('FR')),
          _Row(Icons.shield_outlined, 'Politique de confidentialité',
              onTap: () => LegalScreen.showPrivacy(context)),
          _Row(Icons.article_outlined, 'Conditions d\'utilisation',
              onTap: () => LegalScreen.showCgu(context)),
          const SizedBox(height: 16),
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
                style: WinType.manrope(size: 14, weight: FontWeight.w600, color: WinColors.error)),
          ),
      ],
    );
  }

  int _alertCount(List<TrackedChild> children) =>
      children.where((c) => c.avgScore < 60).length;
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatBox(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: WinType.manrope(size: 13, weight: FontWeight.w800, color: s.onStrong),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    );
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

/// ===================== WINAI =====================
class ParentWinAITab extends StatefulWidget {
  const ParentWinAITab({super.key});
  @override
  State<ParentWinAITab> createState() => _ParentWinAITabState();
}

class _ParentWinAITabState extends State<ParentWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text})> _msgs = [];
  bool _thinking = false;

  static const _suggestions = [
    'Mon enfant est en difficulté',
    'Plan de révision maison',
    'Analyse ses résultats',
    'Comment le motiver ?',
  ];

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    setState(() { _msgs.add((me: true, text: t)); _ctrl.clear(); _thinking = true; });
    final reply = await ChatbotService.instance.sendMessage(message: t);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add((me: false, text: reply ?? 'Désolé, je n\'ai pas pu répondre. Réessaie.'));
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
                  Text('WinAI', style: WinType.archivo(size: 28, color: s.onStrong)),
                  const SizedBox(height: 6),
                  Text('Ton conseiller familial chaleureux',
                      style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: _suggestions.map((q) => GestureDetector(
                      onTap: () => _send(q),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: WinColors.blue500.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WinColors.blue500.withValues(alpha: 0.25))),
                        alignment: Alignment.centerLeft,
                        child: Text(q,
                            style: WinType.manrope(
                                size: 13,
                                weight: FontWeight.w600,
                                color: WinColors.blue500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    )).toList(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: s.cardBg,
                            border: Border.all(color: s.cardBorder),
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: s.primary)),
                          const SizedBox(width: 8),
                          Text('WinAI réfléchit…', style: WinType.bodyS(s.onMuted)),
                        ]),
                      ),
                    );
                  }
                  final m = _msgs[i];
                  return Align(
                    alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.me ? WinColors.ink800 : s.cardBg,
                        border: m.me ? null : Border.all(color: s.cardBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text,
                          style: WinType.bodyM(m.me ? WinColors.cream50 : s.onSurface)),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(children: [
          Expanded(child: WinTextField(
              hint: 'Posez votre question sur la scolarité…', controller: _ctrl)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
                width: 48,
                height: 50,
                decoration:
                    BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.send, size: 20, color: s.onPrimary)),
          ),
        ]),
      ),
    ]);
  }
}
