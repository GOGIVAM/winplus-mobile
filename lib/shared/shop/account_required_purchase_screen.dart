import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import '../../auth/login_screen.dart';
import '../../auth/role_screen.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../services/cart_service.dart';
import '../../services/session_manager.dart';
import 'cart_screen.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Écran « Acheter » d'un contenu payant.
///
/// Décision 9.2 du suivi : le parcours de commande invité est supprimé, un
/// compte est obligatoire pour acheter. Cet écran remplace l'ancien
/// formulaire « Commander sans compte » (GuestOrderScreen), qui appelait un
/// endpoint `/orders/guest` inexistant côté serveur.
///
/// - Sans session : redirection vers la connexion ou l'inscription avant
///   tout paiement.
/// - Avec session : ajout au panier, puis commande et paiement Mobile Money
///   dans l'application (lot 6 du plan de correction mobile).
class AccountRequiredPurchaseScreen extends StatefulWidget {
  final Content content;
  const AccountRequiredPurchaseScreen({super.key, required this.content});

  @override
  State<AccountRequiredPurchaseScreen> createState() =>
      _AccountRequiredPurchaseScreenState();
}

class _AccountRequiredPurchaseScreenState
    extends State<AccountRequiredPurchaseScreen> {
  bool? _loggedIn;
  bool _adding = false;

  Future<void> _ajouterAuPanier() async {
    final id = int.tryParse(widget.content.id);
    final messenger = ScaffoldMessenger.of(context);
    if (id == null) return;
    setState(() => _adding = true);
    final cart = await CartService.instance.addItem(id);
    if (!mounted) return;
    setState(() => _adding = false);
    if (cart == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(L10n.current.shopUnexpectedError)));
      return;
    }
    Navigator.pushReplacement(
        context, WinPageRoute(builder: (_) => const CartScreen()));
  }

  @override
  void initState() {
    super.initState();
    SessionManager.isLoggedIn().then((v) {
      if (mounted) setState(() => _loggedIn = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = widget.content;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.shopBuy),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          WinCard(
            padding: EdgeInsets.zero,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: s.surface2,
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(WinRadii.lg)),
                ),
                child: Center(
                    child: Icon(PhosphorIconsRegular.fileText,
                        size: 32, color: s.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: WinType.titleM(s.onStrong),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.primaryContainer,
                        borderRadius: BorderRadius.circular(WinRadii.full),
                      ),
                      child: Text('${fmtXaf(c.price)} XAF',
                          style: WinType.labelM(s.primary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )),
              const SizedBox(width: 14),
            ]),
          ),
          const SizedBox(height: 20),
          if (_loggedIn == null)
            const Center(child: CircularProgressIndicator())
          else if (_loggedIn == false) ...[
            Text(context.l10n.shopAccountRequiredTitle,
                style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 8),
            Text(context.l10n.shopAccountRequiredBody,
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),
            WinButton(context.l10n.login,
                block: true,
                icon: PhosphorIconsRegular.signIn,
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const LoginScreen()))),
            const SizedBox(height: 10),
            WinButton(context.l10n.createAccount,
                block: true,
                variant: WinButtonVariant.outline,
                icon: PhosphorIconsRegular.userPlus,
                onTap: () => Navigator.push(
                    context, WinPageRoute(builder: (_) => const RoleScreen()))),
          ] else ...[
            // Connecté (par exemple après s'être connecté depuis cet écran) :
            // achat dans l'application, par le panier et Mobile Money.
            Text(context.l10n.shopBuyInAppTitle,
                style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 8),
            Text(context.l10n.shopBuyInAppBody,
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),
            WinButton(context.l10n.studentViewerAddToCart,
                block: true,
                loading: _adding,
                icon: PhosphorIconsRegular.shoppingCart,
                onTap: _adding ? null : _ajouterAuPanier),
          ],
        ],
      ),
    );
  }
}
