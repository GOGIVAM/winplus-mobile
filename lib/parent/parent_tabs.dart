import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/chatbot_service.dart';
import '../widgets/winai_memories_sheet.dart';
import '../services/connectivity_service.dart';
import '../services/local_cache_service.dart';
import '../services/parent_service.dart';
import '../services/subject_service.dart';
import '../services/subscription_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/offline_banner.dart';
import '../widgets/win_widgets.dart';
import 'child_activity_screen.dart';
import 'add_child_screen.dart';
import 'winai_alerts_screen.dart';
import 'subscription_status_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../shared/subscription/pricing_screen.dart';
import 'buy_for_child_screen.dart';
import 'covered_children_screen.dart';
import '../shared/tutoring_for_students_screen.dart';
import '../shared/legal_screen.dart';
import '../widgets/knowledge_base_toggle.dart';

/// ===================== ACCUEIL PARENT =====================

const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche'
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre'
];

class ParentDashTab extends StatefulWidget {
  const ParentDashTab({super.key});
  @override
  State<ParentDashTab> createState() => _ParentDashTabState();
}

class _ParentDashTabState extends State<ParentDashTab> {
  List<ApiChild>? _children;
  List<ApiPersistedAlert> _alerts = [];
  ApiActiveSubscription? _sub;
  ApiParentProfile? _profile;
  // Solde réel du portefeuille (GET /parent/credits) ; null sans abonnement.
  ApiParentWalletSummary? _wallet;
  bool _walletLoaded = false;
  List<ApiUpcomingEvent> _events = [];
  // Module 24 (lot 8) : scores réels par enfant (ParentService.getChildStats),
  // chargés une fois les enfants connus. `null` tant que non chargé pour
  // chaque enfant : évite d'afficher un score à 0 trompeur pendant l'attente.
  final Map<int, double> _childScores = {};
  bool _offline = !ConnectivityService.instance.isOnline;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _load();
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (mounted) setState(() => _offline = !online);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    // getChildren()/getAlerts() retombent déjà sur le cache (ParentDashboardBox)
    // en cas d'échec réseau  ce try/catch ne couvre que le cas "jamais mis
    // en cache et hors ligne dès le premier lancement", pour ne jamais rester
    // bloqué sur le spinner (contrairement au comportement précédent, qui
    // n'avait aucune gestion d'erreur ici).
    try {
      final kids = await ParentService.instance.getChildren();
      final alerts = await ParentService.instance
          .getAllPersistedAlerts(kids.map((c) => c.id).toList());
      final sub = await SubscriptionService.instance.getCurrent();
      final profile = await ParentService.instance.getProfile();
      final wallet = await ParentService.instance.getWalletSummary();
      final events = await ParentService.instance.getUpcomingEvents();
      if (mounted)
        setState(() {
          _children = kids;
          _alerts = alerts;
          _sub = sub;
          _profile = profile;
          _wallet = wallet;
          _walletLoaded = true;
          _events = events;
        });
      // Scores réels par enfant, en arrière-plan : ne bloque pas l'affichage
      // de la liste d'enfants si un enfant particulier échoue.
      for (final child in kids) {
        ParentService.instance.getChildStats(child.id).then((stats) {
          if (mounted) {
            setState(() => _childScores[child.id] = stats.averageScore);
          }
        }).catchError((_) {});
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _children = [];
          _alerts = [];
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final kids = _children ?? [];
    // Module 24 (lot 8) : les enfants suivis étaient déjà chargés depuis le
    // serveur (_children) mais l'affichage retombait sur
    // WinData.trackedChildren (données de démonstration), confirmé par
    // SUIVI_VERSEMENTS_ET_CORRECTIONS.md. Le score moyen par enfant vient de
    // ParentService.getChildStats, chargé séparément (voir _load()).
    final tracked = kids
        .map((c) => TrackedChild(
              id: c.id.toString(),
              name: c.fullName,
              level: c.level ?? '',
              avgScore: (_childScores[c.id] ?? 0).round(),
              trend: Trend.stable,
              lastActiveAt: DateTime.now(),
            ))
        .toList();
    // Évènements réels uniquement : fin de période de l'abonnement en cours
    // (GET /subscriptions/me) et évènements publiés sur la plateforme
    // (GET /parent/events/upcoming). Sans aucun des deux, la section est masquée.
    final events = <UpcomingEvent>[
      if (_sub != null && _sub!.hasPlan && _sub!.expiresAt != null &&
          _sub!.expiresAt!.isAfter(DateTime.now()))
        UpcomingEvent(
            type: 'renewal',
            label: 'Fin de période · plan ${_sub!.planName}',
            date: _sub!.expiresAt!),
      ..._events.map((e) =>
          UpcomingEvent(type: e.type, label: e.title, date: e.startDate!)),
    ];

    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12 ? 'Bonjour' : (hour < 18 ? 'Bon après-midi' : 'Bonsoir');
    final firstName = (_profile?.name ?? '').trim().split(' ').first;
    final dateLabel =
        '${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]} ${now.year}';
    final hasPlan = _sub != null && _sub!.hasPlan;
    final planLabel = hasPlan ? 'Plan ${_sub!.planName}' : 'Sans abonnement';

    // Crédits : solde réel du portefeuille (GET /parent/credits : dotation du
    // plan restante + recharges). Null sans abonnement payant actif.
    final wallet = _wallet;
    final creditsAvail = wallet?.creditsLeft.round() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_offline && _children != null)
          OfflineBanner(
              updatedAt: LocalCacheService.lastUpdatedAt(
                  LocalCacheService.parentDashboard, 'children')),

        // ── Hero gradient ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WinRadii.xl),
              gradient: LinearGradient(
                  colors: [s.heroFrom, s.heroTo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateLabel,
                style: WinType.labelS(WinColors.ink300)
                    .copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(firstName.isEmpty ? greeting : '$greeting $firstName',
                style: WinType.archivo(size: 20, color: WinColors.cream50)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: WinColors.teal400.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(WinRadii.full)),
                child: Text(planLabel,
                    style: WinType.manrope(
                        size: 11,
                        weight: FontWeight.w600,
                        color: WinColors.teal300)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: _PHeroStat(
                      '${tracked.length}', 'enfants suivis', 'Total')),
              const SizedBox(width: 10),
              Expanded(
                  child: _PHeroStat(
                      wallet == null ? '—' : '${fmtXaf(creditsAvail)} XAF',
                      'crédits dispo',
                      'Solde')),
            ]),
          ]),
        ),

        // ── Carte crédits ─────────────────────────────────────────
        const SizedBox(height: 16),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: WinColors.teal500),
              const SizedBox(width: 8),
              Text('Crédits disponibles', style: WinType.titleM(s.onStrong)),
            ]),
            const SizedBox(height: 12),
            if (!_walletLoaded)
              Text('Chargement du solde…', style: WinType.labelS(s.onMuted))
            else if (wallet == null)
              Text(
                  'Aucun crédit : les crédits sont versés avec un abonnement parent actif.',
                  style: WinType.bodyS(s.onMuted))
            else ...[
              Text('${fmtXaf(creditsAvail)} XAF',
                  style: WinType.manrope(
                      size: 13,
                      weight: FontWeight.w700,
                      color: WinColors.teal600)),
              const SizedBox(height: 4),
              Text(
                  'Dont ${fmtXaf(wallet.allocationRemaining.round())} XAF de dotation du plan'
                  ' et ${fmtXaf(wallet.permanent.round())} XAF de recharges',
                  style: WinType.labelS(s.onMuted)),
            ],
            if (_sub != null && _sub!.hasPlan && _sub!.expiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Plan ${_sub!.planName} · Fin de période dans ${_sub!.expiresAt!.difference(DateTime.now()).inDays} jours',
                style: WinType.labelS(s.onMuted),
              ),
            ],
            const SizedBox(height: 12),
            WinButton('Voir l\'abonnement',
                variant: WinButtonVariant.ghost,
                small: true,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => const SubscriptionStatusScreen()))),
          ]),
        ),

        // ── Alertes WinAI ─────────────────────────────────────────
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const WinAIAlertsScreen())),
          child: Row(children: [
            const WinAIOrb(size: 20),
            const SizedBox(width: 10),
            Text('Alertes & conseils WinAI',
                style: WinType.archivo(size: 16, color: s.onStrong)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: WinColors.ink300),
          ]),
        ),
        if (_alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          WinAlert(_alerts.first.content,
              type: BadgeColor.warn, icon: Icons.warning_amber_rounded),
        ],

        // ── Mes enfants (cards horizontales scrollables) ──────────
        const SizedBox(height: 20),
        Row(children: [
          Text('Mes enfants',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const Spacer(),
          if (tracked.isNotEmpty)
            GestureDetector(
              onTap: () {},
              child: Text('Voir tout', style: WinType.labelM(s.primary)),
            ),
        ]),
        const SizedBox(height: 12),
        if (_children == null)
          const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()))
        else if (tracked.isEmpty)
          WinCard(
            child: Text(
                'Aucun enfant suivi. Ajoutez un enfant depuis l\'onglet Enfants.',
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

        // ── Évènements à venir (réels uniquement) ─────────────────
        if (events.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Évènements à venir',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ...events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EventTile(event: e),
              )),
        ],

        // ── Acheter pour un enfant ────────────────────────────────
        const SizedBox(height: 8),
        WinButton(
          'Acheter du contenu pour un enfant',
          block: true,
          icon: Icons.shopping_bag_outlined,
          onTap: kids.isEmpty
              ? null
              : () => Navigator.push(
                  context,
                  WinPageRoute(
                      builder: (_) => BuyForChildScreen(children: kids))),
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
          borderRadius: BorderRadius.circular(WinRadii.md)),
      child: Row(children: [
        Text(value, style: WinType.archivo(size: 24, color: WinColors.teal400)),
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
          WinPageRoute(builder: (_) => ChildActivityScreen(child: child))),
      child: Row(children: [
        WinAvatar(child.fullName, size: 48, color: WinColors.blue100),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

    final IconData trendIcon = child.trend == Trend.up
        ? Icons.trending_up_rounded
        : child.trend == Trend.down
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final Color trendColor = child.trend == Trend.up
        ? WinColors.success
        : child.trend == Trend.down
            ? WinColors.error
            : WinColors.ink300;

    final firstName = child.name.split(' ').first;
    final lastName =
        child.name.split(' ').length > 1 ? child.name.split(' ').last : '';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          WinPageRoute(
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
            borderRadius: BorderRadius.circular(WinRadii.lg),
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
            Icon(trendIcon, size: 14, color: trendColor),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
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
    final daysLabel =
        days <= 0 ? "aujourd'hui" : 'dans $days jour${days > 1 ? 's' : ''}';
    return GestureDetector(
      onTap: isRenewal
          ? () => Navigator.push(context,
              WinPageRoute(builder: (_) => const SubscriptionStatusScreen()))
          : null,
      child: WinCard(
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(WinRadii.sm)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(event.label,
                    style: WinType.titleM(s.onStrong),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(daysLabel, style: WinType.labelM(s.onMuted)),
              ])),
          if (isRenewal) Icon(Icons.chevron_right, size: 16, color: s.onFaint),
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
    // Lot 9.7b : limite children.max du plan (1 sans abonnement), appliquée
    // aussi par le serveur ; plus de test sur un nom de plan.
    final sub = SubscriptionScope.of(context);
    final atChildLimit = !sub.allowsOneMore(EntitlementKeys.childrenMax, kids.length);
    final childLimit = sub.limit(EntitlementKeys.childrenMax);
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
                        WinButton('$childLimit enfant${childLimit > 1 ? 's' : ''} max avec votre plan',
                            variant: WinButtonVariant.outline,
                            block: true,
                            icon: Icons.lock_outline,
                            onTap: () => Navigator.push(
                                context,
                                WinPageRoute(
                                    builder: (_) => const PricingScreen())))
                      else
                        WinButton('Ajouter un enfant',
                            variant: WinButtonVariant.outline,
                            block: true,
                            icon: Icons.add, onTap: () async {
                          await Navigator.push(
                              context,
                              WinPageRoute(
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
                children:
                    reco.map((c) => _ParentContentCard(content: c)).toList(),
              ),
            const SizedBox(height: 20),
            WinButton(
              'Acheter du contenu pour un enfant',
              block: true,
              icon: Icons.shopping_bag_outlined,
              onTap: _children.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) =>
                              BuyForChildScreen(children: _children))),
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
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(WinRadii.lg))),
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
/// Lot 9.7b : historique RÉEL des paiements du parent (GET /parent/payments :
/// commandes payées par Mobile Money ou par le solde, achats pour un enfant,
/// cours particuliers, recharges). Remplace la liste et le total fictifs.
class ParentPaymentsTab extends StatefulWidget {
  const ParentPaymentsTab({super.key});
  @override
  State<ParentPaymentsTab> createState() => _ParentPaymentsTabState();
}

class _ParentPaymentsTabState extends State<ParentPaymentsTab> {
  ApiParentPayments? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await ParentService.instance.getPayments();
    if (!mounted) return;
    setState(() {
      _data = data;
      _failed = data == null;
      _loading = false;
    });
  }

  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _subtitle(ApiParentPayment p) {
    final d = p.date;
    final status = switch (p.status) {
      'pending' => ' · en attente',
      'failed' => ' · échoué',
      'refunded' => ' · remboursé',
      'refund_requested' => ' · remboursement demandé',
      _ => '',
    };
    return '${d.day} ${_months[d.month - 1]} ${d.year} · ${p.method}$status';
  }

  Widget _row(WinScheme s, ApiParentPayment p, bool last) {
    final paid = p.status == 'paid';
    final icon = paid
        ? (p.isDebit ? Icons.check : Icons.add)
        : p.status == 'pending'
            ? Icons.schedule
            : Icons.close;
    final sign = p.isDebit ? '−' : '+';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: s.outline))),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: paid ? WinColors.successBg : s.surface2,
                shape: BoxShape.circle),
            child: Icon(icon,
                size: 16, color: paid ? WinColors.success : s.onMuted)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.bodyM(s.onStrong)
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(_subtitle(p), style: WinType.labelM(s.onMuted)),
            ])),
        Text('$sign${fmtXaf(p.amountXaf.round())}',
            style: WinType.archivo(size: 15, color: s.onStrong)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _data?.items ?? const <ApiParentPayment>[];
    final spent = _loading
        ? '…'
        : _data == null
            ? ''
            : '${fmtXaf(_data!.monthSpentXaf.round())} XAF';
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Paiements',
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(
          child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(WinRadii.xl),
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
                      Text(spent,
                          style: WinType.archivo(
                              size: 32, color: WinColors.cream50)),
                    ]),
              ),
              const SizedBox(height: 20),
              Text('Historique',
                  style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()))
              else if (_failed)
                WinCard(
                    child: Column(children: [
                  Text("L'historique n'a pas pu être chargé.",
                      style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 10),
                  WinButton('Réessayer', icon: Icons.refresh, onTap: _load),
                ]))
              else if (items.isEmpty)
                WinCard(
                    child: Text(
                        'Aucun paiement pour le moment. Vos achats, abonnements et recharges apparaîtront ici.',
                        style: WinType.bodyM(s.onMuted)))
              else
                WinCard(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(children: [
                      for (int i = 0; i < items.length; i++)
                        _row(s, items[i], i == items.length - 1),
                    ])),
            ]),
      )),
    ]);
  }
}

/// ===================== PROFIL =====================
class ParentProfileTab extends StatefulWidget {
  const ParentProfileTab({super.key});
  @override
  State<ParentProfileTab> createState() => _ParentProfileTabState();
}

/// Profil parent : identité (GET /parent/profile), plan (GET /subscriptions/me),
/// solde (GET /parent/credits), enfants liés (GET /parent/children) et alertes
/// WinAI non lues (GET /parent-alerts/{id}). Plus aucune donnée de démonstration.
class _ParentProfileTabState extends State<ParentProfileTab> {
  ApiParentProfile? _profile;
  ApiActiveSubscription? _sub;
  ApiParentWalletSummary? _wallet;
  List<ApiChild> _children = [];
  final Map<int, double> _scores = {};
  int _unreadAlerts = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ParentService.instance.getProfile();
      final sub = await SubscriptionService.instance.getCurrent();
      final wallet = await ParentService.instance.getWalletSummary();
      final kids = await ParentService.instance.getChildren();
      final alerts = await ParentService.instance
          .getAllPersistedAlerts(kids.map((c) => c.id).toList());
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _sub = sub;
        _wallet = wallet;
        _children = kids;
        _unreadAlerts = alerts.where((a) => !a.isRead).length;
        _loaded = true;
      });
      for (final child in kids) {
        ParentService.instance.getChildStats(child.id).then((stats) {
          if (mounted) setState(() => _scores[child.id] = stats.averageScore);
        }).catchError((_) {});
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = WinAppScope.of(context);
    final name = (_profile?.name ?? '').trim();
    final email = (_profile?.email ?? '').trim();
    final hasPlan = _sub != null && _sub!.hasPlan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Avatar + identité ────────────────────────────────────
        Center(
          child: Column(children: [
            WinAvatar(name.isEmpty ? 'Parent' : name,
                size: 80, color: WinColors.blue100),
            const SizedBox(height: 12),
            Text(name.isEmpty ? (_loaded ? 'Mon compte' : '…') : name,
                style: WinType.archivo(size: 22, color: s.onStrong)),
            if (email.isNotEmpty)
              Text(email, style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: WinColors.teal500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(WinRadii.full),
                  border: Border.all(
                      color: WinColors.teal500.withValues(alpha: 0.4))),
              child: Text(hasPlan ? 'Plan ${_sub!.planName}' : 'Sans abonnement',
                  style: WinType.manrope(
                      size: 12,
                      weight: FontWeight.w700,
                      color: WinColors.teal600)),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Stats rapides ────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _StatBox(_loaded ? '${_children.length}' : '…', 'Enfants',
                  Icons.child_care_outlined, WinColors.blue500)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  _wallet == null
                      ? '—'
                      : '${fmtXaf(_wallet!.creditsLeft.round())} XAF',
                  'Crédits',
                  Icons.account_balance_wallet_outlined,
                  WinColors.teal500)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(_loaded ? '$_unreadAlerts' : '…', 'Alertes WinAI',
                  Icons.notifications_outlined, WinColors.warn)),
        ]),
        const SizedBox(height: 20),

        // ── Enfants liés ─────────────────────────────────────────
        if (_children.isNotEmpty) ...[
          Text('Enfants suivis', style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 10),
          ..._children.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => ChildActivityScreen(child: c))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: s.surface2,
                        borderRadius: BorderRadius.circular(WinRadii.md),
                        border: Border.all(color: s.outline)),
                    child: Row(children: [
                      WinAvatar(c.fullName, size: 36, color: WinColors.blue100),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(c.firstName.isEmpty ? c.fullName : c.firstName,
                                style: WinType.bodyM(s.onStrong)
                                    .copyWith(fontWeight: FontWeight.w600)),
                            Text(c.level ?? c.schoolName ?? 'Élève',
                                style: WinType.labelS(s.onMuted)),
                          ])),
                      if (_scores[c.id] != null)
                        Text('${_scores[c.id]!.round()}%',
                            style: WinType.labelM(s.onMuted)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: WinColors.ink300),
                    ]),
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],

        // ── Paramètres ───────────────────────────────────────────
        const SizedBox(height: 4),
        _Row(Icons.account_balance_wallet_outlined, 'Mon abonnement',
            onTap: () => Navigator.push(
                context,
                WinPageRoute(
                    builder: (_) => const SubscriptionStatusScreen()))),
        _Row(Icons.autorenew, 'Gérer l\'abonnement',
            onTap: () => Navigator.push(
                context,
                WinPageRoute(
                    builder: (_) => const SubscriptionStatusScreen()))),
        // Lot 9.3 : attribuer un tuteur, réserver pour ses enfants.
        _Row(Icons.school_outlined, 'Cours particuliers de mes enfants',
            onTap: () => Navigator.push(context,
                WinPageRoute(builder: (_) => const TutoringForStudentsScreen()))),
        // Lot 9.7b : choix des enfants couverts par le plan (catalogue, bonus WinAI, alertes).
        _Row(Icons.verified_user_outlined, 'Enfants couverts par mon plan',
            onTap: () => Navigator.push(context,
                WinPageRoute(builder: (_) => const CoveredChildrenScreen()))),
        _Row(Icons.payment_outlined, 'Paiements & historique',
            onTap: () => Navigator.push(context,
                WinPageRoute(builder: (_) => const _PaymentsScreen()))),
        _Row(Icons.notifications_outlined, 'Notifications',
            trailing: Switch(
                value: true, activeThumbColor: s.primary, onChanged: (_) {})),
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
              WinPageRoute(builder: (_) => const WelcomeScreen()),
              (r) => false,
            );
          },
          child: Text('Se déconnecter',
              style: WinType.manrope(
                  size: 14, weight: FontWeight.w600, color: WinColors.error)),
        ),
      ],
    );
  }
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
          borderRadius: BorderRadius.circular(WinRadii.md),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: WinType.manrope(
                    size: 13, weight: FontWeight.w800, color: s.onStrong),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
              const Icon(Icons.chevron_right,
                  size: 18, color: WinColors.ink300),
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
  final String? initialMessage;
  const ParentWinAITab({super.key, this.initialMessage});
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
        text: reply ?? 'Désolé, je n\'ai pas pu répondre. Réessaie.'
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
                    Text('Ton conseiller familial chaleureux',
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
                                      color: WinColors.blue500
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(WinRadii.md),
                                      border: Border.all(
                                          color: WinColors.blue500
                                              .withValues(alpha: 0.25))),
                                  alignment: Alignment.centerLeft,
                                  child: Text(q,
                                      style: WinType.manrope(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: WinColors.blue500),
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
                          Text('Mémoire WinAI',
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
                    hint: 'Posez votre question sur la scolarité…',
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
