import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../data/reference_data.dart';
import '../data/models.dart';
import '../services/parent_service.dart';
import '../services/subject_service.dart';
import '../services/connectivity_service.dart';
import '../services/order_service.dart';
import '../shared/shop/checkout_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';

/// Achat d'un contenu pour un enfant (lot 6), partagé par l'écran « Acheter
/// pour un enfant » et le catalogue du parent : confirmation, paiement par le
/// portefeuille, ou par Mobile Money quand le solde ne suffit pas.
Future<void> acheterPourEnfant(BuildContext context, Content c, ApiChild enfant) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final subjectId = int.tryParse(c.id);
  if (subjectId == null) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.parentBuyConfirmTitle(enfant.firstName)),
      content: Text(l.parentBuyConfirmBody(c.title, fmtXaf(c.price), enfant.firstName)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.parentBuyConfirm)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final ChildPurchaseResult res;
  try {
    res = await ParentService.instance.purchaseSubjectForChild(subjectId, enfant.id);
  } on OfflineActionException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }
  if (!context.mounted) return;

  if (res.done) {
    messenger.showSnackBar(
        SnackBar(content: Text(l.parentBuyDone(c.title, enfant.firstName))));
    return;
  }
  if (!res.needsMobileMoney) {
    messenger.showSnackBar(SnackBar(content: Text(res.message ?? '')));
    return;
  }

  // Solde insuffisant : la commande est créée, il reste à la régler.
  final prix = res.price ?? c.price.toDouble();
  final payer = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.parentBuyTopUpTitle),
      content: Text(l.parentBuyTopUpBody(
          fmtXaf((res.missing ?? prix).round()), fmtXaf(prix.round()))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.parentBuyPayMomo)),
      ],
    ),
  );
  if (payer != true || !context.mounted) return;
  final commande = await OrderService.instance.getOrderById(res.orderId!);
  if (!context.mounted) return;
  await Navigator.push(
      context,
      WinPageRoute(
          builder: (_) => CheckoutScreen(
              pending: PendingOrderPayment(
                  orderId: res.orderId!,
                  orderNumber: commande?.orderNumber ?? '#${res.orderId}',
                  amount: commande?.totalAmount ?? prix,
                  title: c.title))));
}

class BuyForChildScreen extends StatefulWidget {
  final List<ApiChild> children;
  const BuyForChildScreen({super.key, required this.children});

  @override
  State<BuyForChildScreen> createState() => _BuyForChildScreenState();
}

class _BuyForChildScreenState extends State<BuyForChildScreen> {
  int _selectedChildIndex = 0;
  List<Content> _catalog = [];
  bool _loading = true;
  ApiParentWalletSummary? _wallet;
  bool _walletLoading = true;

  ApiChild get _selected => widget.children[_selectedChildIndex];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadWallet();
  }

  // Module 24 (lot 8, rattrapage 16.1) : solde réel du portefeuille parent
  // (GET /parent/credits via ParentCreditsController), remplace l'absence
  // totale d'indication de solde sur cet écran.
  bool _walletError = false;

  Future<void> _loadWallet() async {
    setState(() {
      _walletLoading = true;
      _walletError = false;
    });
    try {
      final wallet = await ParentService.instance.getWalletSummary();
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _walletLoading = false;
      });
    } catch (_) {
      // Panne : « Impossible de charger », pas « pas d'abonnement ».
      if (!mounted) return;
      setState(() {
        _walletError = true;
        _walletLoading = false;
      });
    }
  }

  Future<void> _acheter(Content c) async {
    await acheterPourEnfant(context, c, _selected);
    if (mounted) _loadWallet();
  }

  // Module 24 (lot 8) : catalogue réel filtré par le niveau de l'enfant
  // sélectionné (GET /subjects?level=...), remplace WinData.catalog.
  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    try {
      final level = _selected.level;
      var page = await SubjectService.instance
          .getAll(level: (level == null || level.isEmpty) ? null : level, pageSize: 6);
      if (page.items.length < 3 && level != null && level.isNotEmpty) {
        // Pas assez de résultats pour ce niveau précis : retombe sur le
        // catalogue général plutôt qu'un écran quasi vide.
        page = await SubjectService.instance.getAll(pageSize: 6);
      }
      if (!mounted) return;
      setState(() {
        _catalog = page.items.map((s) => s.toContent()).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _catalog = [];
          _loading = false;
        });
      }
    }
  }

  void _selectChild(int i) {
    setState(() => _selectedChildIndex = i);
    _loadCatalog();
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
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.parentBuyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WalletBanner(
              loading: _walletLoading,
              wallet: _wallet,
              error: _walletError,
              onRetry: _loadWallet),
          const SizedBox(height: 20),
          Text(context.l10n.parentBuyWhichChild,
              style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final kid = widget.children[i];
                final sel = i == _selectedChildIndex;
                final levelLabel = kid.level != null && kid.level!.isNotEmpty
                    ? ClassLevels.label(kid.level)
                    : context.l10n.roleStudent;
                return GestureDetector(
                  onTap: () => _selectChild(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? s.primary : s.surface2,
                      borderRadius: BorderRadius.circular(WinRadii.full),
                      border: Border.all(color: sel ? s.primary : s.outline),
                    ),
                    child: Text(
                      '${kid.firstName} ($levelLabel)',
                      style: WinType.manrope(
                        size: 13,
                        weight: FontWeight.w600,
                        color: sel ? s.onPrimary : s.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.parentBuyRecommended(_selected.firstName, _selected.level != null ? '  ${ClassLevels.label(_selected.level)}' : ''),
            style: WinType.archivo(size: 18, color: s.onStrong),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: const WinLoading(),
            )
          else if (_catalog.isEmpty)
            Text(context.l10n.parentBuyNoContent,
                style: WinType.bodyM(s.onMuted))
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
              children: _catalog
                  .map((c) => _CatalogCard(
                        content: c,
                        childName: _selected.firstName,
                        onBuy: () => _acheter(c),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _WalletBanner extends StatelessWidget {
  final bool loading;
  final ApiParentWalletSummary? wallet;
  final bool error;
  final VoidCallback onRetry;
  const _WalletBanner(
      {required this.loading,
      required this.wallet,
      required this.error,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (loading) {
      return const WinCard(
        padding: EdgeInsets.all(16),
        child: SizedBox(
            height: 20,
            child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)))),
      );
    }
    if (error) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinAlert(context.l10n.commonLoadError, icon: PhosphorIconsRegular.warningCircle),
        TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
      ]);
    }
    final w = wallet;
    if (w == null) {
      return WinAlert(
        context.l10n.parentBuyNoSubscription,
        type: BadgeColor.neutral,
        icon: PhosphorIconsRegular.info,
      );
    }
    return WinCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(PhosphorIconsRegular.wallet,
            size: 22, color: s.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.parentBuyBalance,
                  style: WinType.labelM(s.onMuted)),
              Text('${fmtXaf(w.creditsLeft.round())} ${w.currency}',
                  style: WinType.titleM(s.onStrong)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (w.planName != null) WinBadge(w.planName!, color: BadgeColor.teal),
      ]),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Content content;
  final String childName;
  final VoidCallback onBuy;
  const _CatalogCard(
      {required this.content, required this.childName, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(content.subjectId);
    return WinCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: subj.color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(WinRadii.lg)),
            ),
            child: Center(child: Icon(subj.icon, size: 34, color: subj.color)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  child: Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.titleM(s.onStrong),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(subj.icon, size: 13, color: subj.color),
                  const SizedBox(width: 4),
                  Text(subj.short, style: WinType.labelS(s.onMuted)),
                ]),
                const SizedBox(height: 6),
                Text(
                  content.free ? context.l10n.commonFree : '${fmtXaf(content.price)} XAF',
                  style: WinType.archivo(size: 15, color: s.onStrong),
                ),
                const SizedBox(height: 8),
                WinButton(
                  context.l10n.parentBuyFor(childName),
                  small: true,
                  block: true,
                  onTap: onBuy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
