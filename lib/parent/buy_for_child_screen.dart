import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/parent_service.dart';
import '../services/subject_service.dart';
import '../shared/shop/account_required_purchase_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

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
  Future<void> _loadWallet() async {
    final wallet = await ParentService.instance.getWalletSummary();
    if (!mounted) return;
    setState(() {
      _wallet = wallet;
      _walletLoading = false;
    });
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
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.parentBuyTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WalletBanner(loading: _walletLoading, wallet: _wallet),
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
                    ? kid.level!
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
            context.l10n.parentBuyRecommended(_selected.firstName, _selected.level != null ? '  ${_selected.level}' : ''),
            style: WinType.archivo(size: 18, color: s.onStrong),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
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
                        onBuy: () => Navigator.push(
                          context,
                          WinPageRoute(
                              builder: (_) =>
                                  AccountRequiredPurchaseScreen(content: c)),
                        ),
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
  const _WalletBanner({required this.loading, required this.wallet});

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
    final w = wallet;
    if (w == null) {
      return WinAlert(
        context.l10n.parentBuyNoSubscription,
        type: BadgeColor.neutral,
        icon: Icons.info_outline,
      );
    }
    return WinCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(Icons.account_balance_wallet_outlined,
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
