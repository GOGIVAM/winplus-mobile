import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import '../../data/models.dart' show fmtXaf;
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_motion_widgets.dart';
import '../../widgets/win_widgets.dart';
import 'orders_screen.dart';

/// Checkout (E36 récapitulatif + E37 paiement + E38 succès), en 2 étapes avec
/// stepper numéroté (même langage que le flow de réservation tuteur) :
/// 1. Récapitulatif + numéro Mobile Money  crée la commande puis initie le
///    paiement NotchPay (POST /orders puis POST /payments/initiate).
/// 2. Attente de confirmation (sondage du statut, comme la réservation).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0;
  ApiCart? _cart;
  bool _loadingCart = true;

  String _method = 'mtn';
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  ApiOrder? _order;
  ApiOrderPaymentIntent? _intent;
  ApiPaymentStatus? _status;
  Timer? _pollTimer;
  DateTime? _pollStarted;
  bool _pollTimedOut = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    final cart = await CartService.instance.getCart();
    if (mounted)
      setState(() {
        _cart = cart;
        _loadingCart = false;
      });
  }

  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('237') && digits.length > 9) {
      digits = digits.substring(digits.length - 9);
    }
    return digits;
  }

  Future<void> _submit() async {
    final cart = _cart;
    if (cart == null || cart.items.isEmpty) return;
    final phone = _normalizePhone(_phoneCtrl.text);
    if (phone.length < 9) {
      setState(() => _submitError = 'Numéro de téléphone invalide.');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      // 1. Crée la commande à partir du panier serveur.
      final order = await OrderService.instance
          .createOrder(paymentMethod: 'mobile_money');
      // 2. Initie le paiement NotchPay pour cette commande.
      final intent = await PaymentService.instance.initiateForOrder(
        orderId: order.id,
        phone: phone.startsWith('237') ? phone : '237$phone',
        amount: order.totalAmount,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _intent = intent;
        _submitting = false;
        _step = 1;
      });
      _startPolling(intent.paymentId);
    } on OrderCreateException catch (e) {
      if (mounted)
        setState(() {
          _submitting = false;
          _submitError = e.message;
        });
    } on OrderPaymentException catch (e) {
      if (mounted)
        setState(() {
          _submitting = false;
          _submitError = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _submitting = false;
          _submitError = 'Erreur inattendue. Réessayez.';
        });
    }
  }

  void _startPolling(int paymentId) {
    _pollStarted = DateTime.now();
    setState(() => _pollTimedOut = false);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_pollStarted!);
      if (elapsed > const Duration(minutes: 5)) {
        t.cancel();
        setState(() => _pollTimedOut = true);
        return;
      }
      final status =
          await PaymentService.instance.checkStatus(paymentId.toString());
      if (!mounted || status == null) return;
      setState(() => _status = status);
      if (status.isCompleted || status.isFailed) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final titles = ['Récapitulatif & paiement', 'Confirmation'];
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titles[_step], style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: _CheckoutStepper(step: _step),
          ),
          Expanded(
            child:
                _step == 0 ? _buildStepPayment(s) : _buildStepConfirmation(s),
          ),
        ]),
      ),
    );
  }

  Widget _buildStepPayment(WinScheme s) {
    if (_loadingCart) return const Center(child: CircularProgressIndicator());
    final cart = _cart;
    if (cart == null || cart.items.isEmpty) {
      return Center(
          child:
              Text('Votre panier est vide.', style: WinType.bodyM(s.onMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${cart.itemsCount} article${cart.itemsCount > 1 ? 's' : ''}',
                style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 10),
            ...cart.items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                        child: Text(i.title,
                            style: WinType.bodyS(s.onMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('${fmtXaf(i.price.round())} XAF',
                        style: WinType.bodyS(s.onMuted)),
                  ]),
                )),
            const WinDivider(),
            const SizedBox(height: 8),
            Row(children: [
              Text('Total TTC', style: WinType.titleM(s.onStrong)),
              const Spacer(),
              Text('${fmtXaf(cart.total.round())} XAF',
                  style: WinType.archivo(
                      size: 20, weight: FontWeight.w700, color: s.primary)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Mode de paiement', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _PaymentMethodTile(
                  label: 'MTN MoMo',
                  icon: Icons.phone_android,
                  color: WinColors.warn,
                  selected: _method == 'mtn',
                  onTap: () => setState(() => _method = 'mtn'))),
          const SizedBox(width: 10),
          Expanded(
              child: _PaymentMethodTile(
                  label: 'Orange Money',
                  icon: Icons.phone_android,
                  color: WinColors.error,
                  selected: _method == 'orange',
                  onTap: () => setState(() => _method = 'orange'))),
        ]),
        const SizedBox(height: 16),
        WinTextField(
            label: 'Numéro de téléphone',
            hint: '6XX XXX XXX',
            icon: Icons.phone_outlined,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          WinErrorShake(child: WinAlert(_submitError!, type: BadgeColor.error)),
        ],
        const SizedBox(height: 24),
        WinButton('Payer ${fmtXaf(cart.total.round())} XAF',
            block: true,
            loading: _submitting,
            onTap: _submitting ? null : _submit),
        const SizedBox(height: 8),
        Text('Vous recevrez une notification USSD pour valider.',
            style: WinType.bodyS(s.onFaint), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildStepConfirmation(WinScheme s) {
    final status = _status;
    if (status != null && status.isCompleted) return _buildSuccess(s);
    if (status != null && status.isFailed) return _buildFailed(s);
    if (_pollTimedOut) return _buildTimedOut(s);
    return _buildWaiting(s);
  }

  Widget _buildWaiting(WinScheme s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const WinPendingPulse(
              child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 20),
          Text('En attente de confirmation…',
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Valide le paiement via le message USSD envoyé sur ton téléphone.',
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center),
          if (_intent?.notchpayReference != null) ...[
            const SizedBox(height: 12),
            Text('Réf. : ${_intent!.notchpayReference}',
                style: WinType.labelS(s.onFaint)),
          ],
        ]),
      ),
    );
  }

  Widget _buildTimedOut(WinScheme s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_bottom_outlined, size: 48, color: s.onFaint),
          const SizedBox(height: 16),
          Text('Toujours en attente',
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Le paiement met plus de temps que prévu. Vous pouvez vérifier plus tard dans "Mes commandes".',
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton('Vérifier maintenant',
              variant: WinButtonVariant.outline,
              onTap: () => _startPolling(_intent!.paymentId)),
          const SizedBox(height: 10),
          WinButton('Voir mes commandes',
              variant: WinButtonVariant.ghost,
              onTap: () => Navigator.pushReplacement(
                  context, WinPageRoute(builder: (_) => const OrdersScreen()))),
        ]),
      ),
    );
  }

  Widget _buildFailed(WinScheme s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const WinErrorShake(
              child: Icon(Icons.cancel_outlined,
                  size: 48, color: WinColors.error)),
          const SizedBox(height: 16),
          Text('Paiement échoué',
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_status?.message ?? 'Le paiement n\'a pas pu être confirmé.',
              style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton('Réessayer',
              onTap: () => setState(() {
                    _step = 0;
                    _order = null;
                    _intent = null;
                    _status = null;
                  })),
        ]),
      ),
    );
  }

  Widget _buildSuccess(WinScheme s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        const Center(child: WinSuccessCheck(size: 72)),
        const SizedBox(height: 12),
        WinStaggerFade(
          index: 0,
          child: Center(
            child: Text('Paiement confirmé !',
                style: WinType.archivo(size: 20, color: s.onStrong),
                textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 8),
        WinStaggerFade(
          index: 1,
          child: Center(
            child: Text('Vos contenus sont maintenant disponibles.',
                style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          ),
        ),
        if (_order != null) ...[
          const SizedBox(height: 20),
          WinStaggerFade(
            index: 2,
            child: WinCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _RecapRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Commande',
                      value: _order!.orderNumber),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.payments_outlined, size: 18, color: s.onFaint),
                    const SizedBox(width: 10),
                    Text('Montant', style: WinType.bodyS(s.onMuted)),
                    const Spacer(),
                    WinAnimatedCounter(
                      value: _order!.totalAmount.round(),
                      style: WinType.titleM(s.onStrong),
                      format: (v) => '${fmtXaf(v)} XAF',
                    ),
                  ]),
                ])),
          ),
        ],
        const SizedBox(height: 24),
        WinStaggerFade(
          index: 3,
          child: WinButton('Voir mes commandes',
              block: true,
              onTap: () => Navigator.pushReplacement(
                  context, WinPageRoute(builder: (_) => const OrdersScreen()))),
        ),
        const SizedBox(height: 10),
        WinStaggerFade(
          index: 4,
          child: WinButton('Retour au catalogue',
              variant: WinButtonVariant.outline,
              block: true,
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ),
      ],
    );
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _RecapRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: s.onFaint),
      const SizedBox(width: 10),
      Text(label, style: WinType.bodyS(s.onMuted)),
      const Spacer(),
      Text(value, style: WinType.titleM(s.onStrong)),
    ]);
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentMethodTile({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WinRadii.md),
          border: Border.all(
              color: selected ? s.primary : s.outline, width: selected ? 2 : 1),
          color: selected ? s.primaryContainer : s.cardBg,
        ),
        child: Column(children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(label, style: WinType.labelM(s.onStrong)),
        ]),
      ),
    );
  }
}

/// Stepper 2 étapes, même composant visuel que la réservation tuteur.
class _CheckoutStepper extends StatelessWidget {
  final int step;
  const _CheckoutStepper({required this.step});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    const count = 2;
    return Row(
        children: List.generate(count * 2 - 1, (i) {
      if (i.isOdd) {
        final done = (i ~/ 2) < step;
        return Expanded(
            child: Container(
                height: 2, color: done ? WinColors.teal400 : s.outline));
      }
      final idx = i ~/ 2;
      final active = idx == step;
      final done = idx < step;
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              active ? WinColors.teal400 : (done ? WinColors.teal50 : s.chipBg),
          border:
              Border.all(color: active || done ? WinColors.teal400 : s.outline),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: WinColors.teal700)
            : Text('${idx + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : s.onMuted)),
      );
    }));
  }
}
