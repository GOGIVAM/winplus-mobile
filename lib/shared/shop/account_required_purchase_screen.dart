import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../auth/role_screen.dart';
import '../../data/models.dart';
import '../../services/session_manager.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Écran « Acheter » d'un contenu payant.
///
/// Décision 9.2 du suivi : le parcours de commande invité est supprimé, un
/// compte est obligatoire pour acheter. Cet écran remplace l'ancien
/// formulaire « Commander sans compte » (GuestOrderScreen), qui appelait un
/// endpoint `/orders/guest` inexistant côté serveur.
///
/// - Sans session : redirection vers la connexion ou l'inscription avant
///   tout paiement.
/// - Avec session : l'achat intégré à l'application (panier, commande,
///   paiement Mobile Money) relève du lot 8 ; en attendant, l'utilisateur est
///   orienté vers son compte web, et le contenu acheté sera accessible ici.
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
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Acheter', style: WinType.headlineS(s.onStrong)),
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
                    child: Icon(Icons.description_outlined,
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
            Text('Un compte est nécessaire pour acheter',
                style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 8),
            Text(
                'Connectez-vous ou créez un compte avant le paiement : '
                'le contenu acheté est rattaché à votre compte et reste '
                'accessible sur tous vos appareils.',
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),
            WinButton('Se connecter',
                block: true,
                icon: Icons.login,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()))),
            const SizedBox(height: 10),
            WinButton('Créer un compte',
                block: true,
                variant: WinButtonVariant.outline,
                icon: Icons.person_add_alt_1_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RoleScreen()))),
          ] else ...[
            Text('Achat depuis votre compte',
                style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 8),
            Text(
                'Le paiement dans l\'application arrive bientôt. En attendant, '
                'achetez ce contenu depuis votre compte sur winplus.cm avec '
                'les mêmes identifiants : il sera ensuite disponible ici.',
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),
            WinButton('Retour',
                block: true,
                variant: WinButtonVariant.outline,
                onTap: () => Navigator.pop(context)),
          ],
        ],
      ),
    );
  }
}
