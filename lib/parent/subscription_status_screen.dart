import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/parent_service.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({super.key});
  @override
  State<SubscriptionStatusScreen> createState() => _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  ApiActiveSubscription? _sub;
  List<ApiChild>? _children;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sub = await SubscriptionService.instance.getCurrent();
    final children = await ParentService.instance.getChildren();
    if (mounted) setState(() { _sub = sub; _children = children; });
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = _sub;
    final children = _children ?? [];

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mon Abonnement', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() { _sub = null; _children = null; }); _load(); },
          ),
        ],
      ),
      body: sub == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: s.cardBg,
                    borderRadius: BorderRadius.zero,
                    border: Border(
                      top: BorderSide(color: s.primary, width: 4),
                      left: BorderSide(color: s.cardBorder),
                      right: BorderSide(color: s.cardBorder),
                      bottom: BorderSide(color: s.cardBorder),
                    ),
                    boxShadow: WinShadows.md,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(sub.planName, style: WinType.displayS(s.onStrong)),
                      const Spacer(),
                      WinBadge(sub.isActive ? 'Actif' : 'Inactif',
                          color: sub.isActive ? BadgeColor.success : BadgeColor.error),
                    ]),
                    const SizedBox(height: 6),
                    Text('Expire le ${_fmtDate(sub.expiresAt)}', style: WinType.bodyS(s.onMuted)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.refresh, size: 14, color: s.onFaint),
                      const SizedBox(width: 4),
                      Text(sub.autoRenew ? 'Renouvellement automatique activé' : 'Renouvellement manuel',
                          style: WinType.labelM(s.onFaint)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                Text('Utilisation ce mois', style: WinType.headlineS(s.onStrong)),
                const SizedBox(height: 12),
                _UsageRow(icon: Icons.download_outlined, label: 'Téléchargements',
                    used: sub.downloadsUsed, limit: sub.downloadsLimit,
                    unlimited: sub.downloadsLimit == 0),
                const SizedBox(height: 10),
                _UsageRow(icon: Icons.quiz_outlined, label: "Quiz aujourd'hui",
                    used: sub.quizUsedToday, limit: sub.quizDailyLimit,
                    unlimited: sub.quizDailyLimit == 0),
                const SizedBox(height: 10),
                _UsageRow(icon: Icons.auto_awesome_outlined, label: 'Messages WinAI',
                    used: sub.aiMessagesUsed, limit: sub.aiMessagesLimit,
                    unlimited: sub.aiMessagesLimit == 0),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Mes enfants', style: WinType.headlineS(s.onStrong)),
                  const SizedBox(height: 12),
                  ...children.map((child) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WinCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        WinAvatar(child.fullName, size: 40),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(child.fullName, style: WinType.titleM(s.onStrong)),
                          Text(child.level ?? child.schoolName ?? 'Élève', style: WinType.labelM(s.onMuted)),
                        ])),
                        const WinBadge('Actif', color: BadgeColor.teal),
                      ]),
                    ),
                  )),
                ],
                const SizedBox(height: 20),
                Text('Historique des paiements', style: WinType.headlineS(s.onStrong)),
                const SizedBox(height: 12),
                ...[
                  ('15 août 2026', sub.planName, 2500),
                  ('15 juil. 2026', sub.planName, 2500),
                  ('15 juin 2026', sub.planName, 2500),
                ].map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WinCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Icon(Icons.receipt_long_outlined, size: 18, color: s.onFaint),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.$2, style: WinType.titleM(s.onStrong)),
                        Text(p.$1, style: WinType.labelM(s.onMuted)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${fmtXaf(p.$3)} XAF', style: WinType.titleM(s.onStrong)),
                        const WinBadge('Payé', color: BadgeColor.success),
                      ]),
                    ]),
                  ),
                )),
                const SizedBox(height: 24),
                WinButton('Renouveler maintenant',
                    block: true, icon: Icons.refresh,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => RenewalSheet(planId: sub.id),
                    )),
                const SizedBox(height: 10),
                WinButton('Changer de plan',
                    variant: WinButtonVariant.outline, block: true, onTap: () {}),
              ],
            ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used, limit;
  final bool unlimited;
  const _UsageRow({required this.icon, required this.label,
      required this.used, required this.limit, required this.unlimited});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: s.primary),
          const SizedBox(width: 8),
          Text(label, style: WinType.titleM(s.onStrong)),
          const Spacer(),
          Text(unlimited ? 'Illimité' : '$used/$limit',
              style: WinType.labelM(unlimited ? WinColors.success : s.onMuted)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
        if (!unlimited) ...[
          const SizedBox(height: 8),
          WinProgressBar(limit == 0 ? 0 : used / limit * 100),
        ],
      ]),
    );
  }
}

class RenewalSheet extends StatefulWidget {
  final int planId;
  const RenewalSheet({super.key, required this.planId});
  @override
  State<RenewalSheet> createState() => _RenewalSheetState();
}

class _RenewalSheetState extends State<RenewalSheet> {
  String _method = 'mtn';
  final _phoneCtrl = TextEditingController();
  bool _loading = false, _done = false;

  Future<void> _pay() async {
    if (_phoneCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final intent = await PaymentService.instance.initiate(
      planId: widget.planId,
      method: _method == 'mtn' ? PaymentMethod.mtnMomo : PaymentMethod.orangeMoney,
      phoneNumber: _phoneCtrl.text.trim(),
      yearly: false,
    );
    if (!mounted) return;
    if (intent != null) {
      setState(() { _loading = false; _done = true; });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'initiation du paiement.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, color: s.outline2, margin: const EdgeInsets.only(bottom: 20)),
        Text('Renouveler l\'abonnement', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 4),
        Text('2 500 XAF / mois', style: WinType.archivo(size: 28, weight: FontWeight.w700, color: s.primary)),
        const SizedBox(height: 20),
        if (_done) ...[
          const WinAlert('Paiement initié ! Confirmez le paiement sur votre téléphone.',
              type: BadgeColor.success),
          const SizedBox(height: 8),
          Text('Vous recevrez une notification USSD pour valider.',
              style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          WinButton('Fermer', block: true, variant: WinButtonVariant.outline,
              onTap: () => Navigator.pop(context)),
        ] else ...[
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _method = 'mtn'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _method == 'mtn' ? s.primary : s.outline,
                      width: _method == 'mtn' ? 2 : 1),
                  color: _method == 'mtn' ? s.primaryContainer : s.cardBg,
                ),
                child: Column(children: [
                  const Icon(Icons.phone_android, size: 24, color: WinColors.warn),
                  const SizedBox(height: 4),
                  Text('MTN MoMo', style: WinType.labelM(s.onStrong)),
                ]),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _method = 'orange'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _method == 'orange' ? s.primary : s.outline,
                      width: _method == 'orange' ? 2 : 1),
                  color: _method == 'orange' ? s.primaryContainer : s.cardBg,
                ),
                child: Column(children: [
                  const Icon(Icons.phone_android, size: 24, color: WinColors.error),
                  const SizedBox(height: 4),
                  Text('Orange Money', style: WinType.labelM(s.onStrong)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 16),
          WinTextField(label: 'Numéro de téléphone', hint: '+237 6XX XXX XXX',
              icon: Icons.phone_outlined, controller: _phoneCtrl,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          WinButton('Payer maintenant', block: true, loading: _loading, onTap: _pay),
          const SizedBox(height: 10),
          Text('Vous recevrez une notification USSD pour valider.',
              style: WinType.bodyS(s.onFaint), textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}
