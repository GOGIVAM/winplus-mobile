import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../services/guest_order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

class GuestOrderScreen extends StatefulWidget {
  final Content content;
  const GuestOrderScreen({super.key, required this.content});
  @override
  State<GuestOrderScreen> createState() => _GuestOrderScreenState();
}

class _GuestOrderScreenState extends State<GuestOrderScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.mtnMomo;
  bool _placing = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (first.isEmpty || last.isEmpty || phone.isEmpty || email.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }

    final subjectId = int.tryParse(widget.content.id);
    if (subjectId == null) {
      setState(() => _error = 'Contenu invalide.');
      return;
    }

    setState(() { _placing = true; _error = null; });

    final result = await GuestOrderService.instance.placeOrder(
      subjectId: subjectId,
      firstName: first,
      lastName: last,
      phone: phone,
      email: email,
      method: _method,
    );

    if (!mounted) return;
    setState(() => _placing = false);

    if (result == null) {
      setState(() => _error = 'Erreur lors de la commande. Réessayez.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _OrderConfirmScreen(
          result: result,
          method: _method,
          email: email,
        ),
      ),
    );
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
        title: Text('Commander sans compte', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          WinCard(
            child: Row(children: [
              Container(
                width: 52, height: 52,
                color: s.surface2,
                child: Center(child: Icon(Icons.description_outlined, size: 28, color: s.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: WinType.titleM(s.onStrong), maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${fmtXaf(c.price)} XAF', style: WinType.headlineS(s.primary)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Vos informations', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: WinTextField(
              hint: 'Prénom',
              controller: _firstCtrl,
            )),
            const SizedBox(width: 10),
            Expanded(child: WinTextField(
              hint: 'Nom',
              controller: _lastCtrl,
            )),
          ]),
          const SizedBox(height: 10),
          WinTextField(
            hint: 'Numéro de téléphone',
            controller: _phoneCtrl,
          ),
          const SizedBox(height: 10),
          WinTextField(
            hint: 'Adresse email (pour recevoir le fichier)',
            controller: _emailCtrl,
          ),
          const SizedBox(height: 20),
          Text('Mode de paiement', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          _MethodTile(
            label: 'MTN Mobile Money',
            icon: Icons.phone_android,
            color: WinColors.warn,
            selected: _method == PaymentMethod.mtnMomo,
            onTap: () => setState(() => _method = PaymentMethod.mtnMomo),
          ),
          const SizedBox(height: 8),
          _MethodTile(
            label: 'Orange Money',
            icon: Icons.phone_android,
            color: WinColors.error,
            selected: _method == PaymentMethod.orangeMoney,
            onTap: () => setState(() => _method = PaymentMethod.orangeMoney),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WinColors.error.withValues(alpha: 0.08),
                border: Border.all(color: WinColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 16, color: WinColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: WinType.bodyS(WinColors.error))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          WinButton(
            'Payer ${fmtXaf(c.price)} XAF',
            block: true,
            icon: Icons.payment_outlined,
            loading: _placing,
            onTap: _placeOrder,
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline, size: 14, color: s.onFaint),
            const SizedBox(width: 6),
            Text('Le fichier sera envoyé à votre adresse email.',
                style: WinType.labelS(s.onFaint)),
          ]),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: s.cardBg,
          border: Border.all(
            color: selected ? s.primary : s.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: WinType.titleM(s.onStrong))),
          if (selected)
            Icon(Icons.check_circle, size: 20, color: s.primary)
          else
            Icon(Icons.circle_outlined, size: 20, color: s.onFaint),
        ]),
      ),
    );
  }
}

class _OrderConfirmScreen extends StatelessWidget {
  final ApiGuestOrderResult result;
  final PaymentMethod method;
  final String email;
  const _OrderConfirmScreen({
    required this.result,
    required this.method,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: WinColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('Commande reçue !', style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(result.message, style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center),
            if (result.ussdCode != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: s.surface2,
                  border: Border.all(color: s.outline),
                ),
                child: Column(children: [
                  Text('Code USSD à composer',
                      style: WinType.labelM(s.onMuted)),
                  const SizedBox(height: 8),
                  Text(result.ussdCode!,
                      style: WinType.displayS(s.onStrong).copyWith(
                          fontFamily: 'monospace', letterSpacing: 2)),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.email_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Livraison par email', style: WinType.titleM(s.onStrong))),
                ]),
                const SizedBox(height: 6),
                Text('Après confirmation du paiement, le fichier sera envoyé à $email.',
                    style: WinType.bodyS(s.onMuted)),
              ]),
            ),
            const Spacer(),
            WinButton('Retour à l\'accueil', block: true,
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
          ]),
        ),
      ),
    );
  }
}
