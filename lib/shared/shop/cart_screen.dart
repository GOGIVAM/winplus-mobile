import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import '../../data/models.dart' show fmtXaf;
import '../../services/cart_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_motion_widgets.dart';
import '../../widgets/win_widgets.dart';
import 'checkout_screen.dart';

/// Panier (E35)  vraies données serveur (GET/POST/DELETE /api/cart), pas de
/// simulation. Composition carte produit (vignette + prix) cohérente avec le
/// reste du catalogue, résumé sous-total/TVA/total et code promo en pied de
/// page façon reçu.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  ApiCart? _cart;
  bool _error = false;
  final _promoCtrl = TextEditingController();
  bool _applyingPromo = false;
  String? _promoError;
  double? _promoDiscount;
  final Set<int> _removing = {};
  final Set<int> _hiding = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final cart = await CartService.instance.getCart();
      if (mounted) setState(() => _cart = cart);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _remove(ApiCartItem item) async {
    setState(() => _removing.add(item.id));
    final ok = await CartService.instance.removeItem(item.id);
    if (!mounted) return;
    if (ok) {
      // Fait disparaître la carte (fondu + réduction de hauteur) avant de
      // recharger le panier, pour éviter que l'article ne saute d'un coup.
      setState(() {
        _removing.remove(item.id);
        _hiding.add(item.id);
      });
      await Future.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      await _load();
      if (mounted) setState(() => _hiding.remove(item.id));
    } else {
      setState(() => _removing.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de retirer cet article.')));
    }
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _applyingPromo = true;
      _promoError = null;
    });
    final result = await CartService.instance.applyPromo(code);
    if (!mounted) return;
    setState(() {
      _applyingPromo = false;
      if (result.success) {
        _promoDiscount = result.discount;
      } else {
        _promoError = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final cart = _cart;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mon panier', style: WinType.headlineS(s.onStrong)),
      ),
      body: cart == null
          ? _error
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Impossible de charger le panier.',
                      style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  WinButton('Réessayer', onTap: _load),
                ]))
              : const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Votre panier est vide.',
                      style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 20),
                  WinButton('Explorer le catalogue',
                      icon: Icons.explore_outlined,
                      onTap: () => Navigator.pop(context)),
                ]))
              : Column(children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = cart.items[i];
                        final hiding = _hiding.contains(item.id);
                        return WinStaggerFade(
                          index: i,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOutCubic,
                            child: AnimatedOpacity(
                              opacity: hiding ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: hiding
                                  ? const SizedBox(width: double.infinity)
                                  : _CartItemCard(
                                      item: item,
                                      removing: _removing.contains(item.id),
                                      onRemove: () => _remove(item),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _CartSummary(
                    cart: cart,
                    promoCtrl: _promoCtrl,
                    applyingPromo: _applyingPromo,
                    promoError: _promoError,
                    promoDiscount: _promoDiscount,
                    onApplyPromo: _applyPromo,
                    onCheckout: () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const CheckoutScreen()))
                        .then((_) => _load()),
                  ),
                ]),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final ApiCartItem item;
  final bool removing;
  final VoidCallback onRemove;
  const _CartItemCard(
      {required this.item, required this.removing, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: EdgeInsets.zero,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image dominante avec prix incrusté et bouton de suppression en
        // pastille superposée  même langage que ContentCard (catalogue),
        // au lieu d'une simple icône plate + texte à côté.
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: BoxDecoration(
                color: s.primaryContainer,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(WinRadii.lg)),
              ),
              child:
                  Icon(Icons.description_outlined, size: 34, color: s.primary),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: removing
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 15, color: WinColors.ink600),
                      ),
                    ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                ),
                child: Text('${fmtXaf(item.price.round())} XAF',
                    style: WinType.labelS(WinColors.ink800)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: WinType.titleM(s.onStrong),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if ((item.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.description!,
                    style: WinType.labelS(s.onMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final ApiCart cart;
  final TextEditingController promoCtrl;
  final bool applyingPromo;
  final String? promoError;
  final double? promoDiscount;
  final VoidCallback onApplyPromo;
  final VoidCallback onCheckout;
  const _CartSummary({
    required this.cart,
    required this.promoCtrl,
    required this.applyingPromo,
    required this.promoError,
    required this.promoDiscount,
    required this.onApplyPromo,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
        boxShadow: WinShadows.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: WinTextField(
                hint: 'Code promo',
                icon: Icons.local_offer_outlined,
                controller: promoCtrl,
              ),
            ),
            const SizedBox(width: 8),
            WinButton('Appliquer',
                small: true, loading: applyingPromo, onTap: onApplyPromo),
          ]),
          if (promoError != null) ...[
            const SizedBox(height: 6),
            WinErrorShake(
                child:
                    Text(promoError!, style: WinType.labelS(WinColors.error))),
          ],
          if (promoDiscount != null && promoDiscount! > 0) ...[
            const SizedBox(height: 6),
            WinStaggerFade(
              index: 0,
              child: Text(
                  'Réduction appliquée : -${fmtXaf(promoDiscount!.round())} XAF',
                  style: WinType.labelS(WinColors.success)),
            ),
          ],
          const SizedBox(height: 14),
          _row(s, 'Sous-total', cart.subtotal),
          const SizedBox(height: 4),
          _row(s, 'TVA', cart.tax),
          const SizedBox(height: 8),
          const WinDivider(),
          const SizedBox(height: 8),
          Row(children: [
            Text('Total', style: WinType.headlineS(s.onStrong)),
            const Spacer(),
            WinAnimatedCounter(
              value: cart.total.round(),
              format: (v) => '${fmtXaf(v)} XAF',
              style: WinType.archivo(
                  size: 22, weight: FontWeight.w700, color: s.primary),
            ),
          ]),
          const SizedBox(height: 16),
          WinButton('Passer la commande',
              block: true, icon: Icons.arrow_forward, onTap: onCheckout),
        ]),
      ),
    );
  }

  Widget _row(WinScheme s, String label, double value) => Row(children: [
        Text(label, style: WinType.bodyM(s.onMuted)),
        const Spacer(),
        Text('${fmtXaf(value.round())} XAF', style: WinType.bodyM(s.onStrong)),
      ]);
}
