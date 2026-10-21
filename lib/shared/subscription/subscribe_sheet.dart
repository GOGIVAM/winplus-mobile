import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models.dart' show fmtXaf;
import '../../l10n/l10n.dart';
import '../../services/subscription_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'subscription_notifier.dart';

/// Lot 9.7b, étape 3 : feuille unique de souscription, de renouvellement et
/// de changement de plan (parité web). Le prix affiché est celui que le
/// serveur facturera réellement (POST /subscriptions/quote : version publiée,
/// période, remise ou essai, prorata d'une montée, descente programmée).
/// Paiement Mobile Money ou par le solde ; renouvellement automatique par le
/// solde au choix (3 jours de grâce si le solde manque).
class SubscribeSheet extends StatefulWidget {
  final int planId;
  final String planName;
  final List<String> periods;
  final String initialPeriod;
  const SubscribeSheet({
    super.key,
    required this.planId,
    required this.planName,
    this.periods = const ['monthly', 'quarterly', 'yearly'],
    this.initialPeriod = 'monthly',
  });

  static Future<bool?> show(BuildContext context,
          {required int planId,
          required String planName,
          List<String> periods = const ['monthly', 'quarterly', 'yearly'],
          String initialPeriod = 'monthly'}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SubscribeSheet(
            planId: planId, planName: planName, periods: periods, initialPeriod: initialPeriod),
      );

  @override
  State<SubscribeSheet> createState() => _SubscribeSheetState();
}

String? _periodLabel(AppLocalizations l, String p) => switch (p) {
      'monthly' => l.subPeriodMonthly,
      'quarterly' => l.subPeriodQuarterly,
      'yearly' => l.subPeriodYearly,
      _ => null,
    };

class _SubscribeSheetState extends State<SubscribeSheet> {
  late String _period;
  final _phoneCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  String? _promo;
  String _method = 'mobile_money';
  bool _autoRenew = false;
  ApiSubscriptionQuote? _quote;
  String? _quoteError;
  bool _loading = false;
  String? _error, _done;

  @override
  void initState() {
    super.initState();
    _period = widget.periods.contains(widget.initialPeriod) ? widget.initialPeriod : widget.periods.first;
    _loadQuote();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  String _serverMessage(Object e, String fallback) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] is String) return d['error'] as String;
    }
    return fallback;
  }

  Future<void> _loadQuote() async {
    setState(() {
      _quote = null;
      _quoteError = null;
    });
    try {
      final q = await SubscriptionService.instance
          .quote(planId: widget.planId, period: _period, promoCode: _promo);
      if (!mounted) return;
      setState(() {
        _quote = q;
        if (_promo != null && q.promoError != null) {
          _quoteError = q.promoError;
          _promo = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _quoteError = _serverMessage(e, L10n.current.subQuoteUnavailable));
    }
  }

  bool get _needsPhone => (_quote?.amountDue ?? 0) > 0 && _method == 'mobile_money';

  Future<void> _pay() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (_needsPhone && digits.length < 9) {
      setState(() => _error = L10n.current.subEnterMomoNumber);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await SubscriptionService.instance.purchasePlan(
        planId: widget.planId,
        period: _period,
        method: (_quote?.amountDue ?? 0) > 0 ? _method : 'balance',
        phone: _needsPhone ? (digits.startsWith('237') ? digits : '237$digits') : null,
        promoCode: _promo,
        autoRenew: _autoRenew,
      );
      if (!mounted) return;
      await SubscriptionScope.of(context).loadFromApi();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _done = r.status == 'payment_pending'
            ? L10n.current.subPaymentInitiated
            : (r.message.isNotEmpty ? r.message : L10n.current.subActivated);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _serverMessage(e, L10n.current.subFinalizeFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final q = _quote;
    final change = q?.change;
    final due = q?.amountDue ?? 0;
    final l = context.l10n;
    final label = change == 'downgrade'
        ? l.subScheduleChange
        : change == 'trial'
            ? l.subStartTrial
            : due <= 0
                ? l.subActivate
                : l.shopPayAmount(fmtXaf(due.round()));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
            color: s.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: s.outline2, borderRadius: BorderRadius.circular(WinRadii.full)),
                  margin: const EdgeInsets.only(bottom: 16)),
            ),
            Text(widget.planName, style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 12),
            if (_done != null) ...[
              WinAlert(_done!, type: BadgeColor.success),
              const SizedBox(height: 16),
              WinButton(l.commonClose, block: true, variant: WinButtonVariant.outline, onTap: () => Navigator.pop(context, true)),
            ] else ...[
              if (widget.periods.length > 1)
                Wrap(spacing: 8, children: [
                  for (final p in widget.periods)
                    WinChip(_periodLabel(l, p) ?? p, active: _period == p, onTap: () {
                      setState(() => _period = p);
                      _loadQuote();
                    }),
                ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: s.surface2, borderRadius: BorderRadius.circular(WinRadii.md), border: Border.all(color: s.outline)),
                child: q == null
                    ? Text(_quoteError ?? l.subComputingPrice, style: WinType.bodyS(s.onMuted))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _line(s, l.subPeriodTtc(_periodLabel(l, q.billingPeriod) ?? q.billingPeriod), '${fmtXaf(q.listPrice.round())} XAF'),
                        if (q.discount > 0 && change != 'trial')
                          _line(s, l.subDiscount(q.promoCode ?? ''), '− ${fmtXaf(q.discount.round())} XAF', color: WinColors.success),
                        if (q.prorataCredit > 0)
                          _line(s, l.subUnusedPeriod, '− ${fmtXaf(q.prorataCredit.round())} XAF', color: WinColors.success),
                        const SizedBox(height: 6),
                        _line(s, l.subDueNow, '${fmtXaf(due.round())} XAF', bold: true),
                        const SizedBox(height: 6),
                        Text(q.message, style: WinType.labelM(s.onMuted)),
                      ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: WinTextField(controller: _promoCtrl, hint: l.shopPromoCode)),
                const SizedBox(width: 8),
                WinButton(l.shopApply, variant: WinButtonVariant.outline, onTap: () {
                  final code = _promoCtrl.text.trim().toUpperCase();
                  if (code.isEmpty) return;
                  setState(() => _promo = code);
                  _loadQuote();
                }),
              ]),
              if (_quoteError != null && q != null) ...[
                const SizedBox(height: 6),
                Text(_quoteError!, style: WinType.labelM(WinColors.error)),
              ],
              if (due > 0 && change != 'downgrade') ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, children: [
                  WinChip('Mobile Money', active: _method == 'mobile_money', onTap: () => setState(() => _method = 'mobile_money')),
                  WinChip(l.subMyBalance, active: _method == 'balance', onTap: () => setState(() => _method = 'balance')),
                ]),
              ],
              if (_needsPhone) ...[
                const SizedBox(height: 12),
                WinTextField(controller: _phoneCtrl, hint: '6XX XXX XXX', keyboardType: TextInputType.phone),
              ],
              if (change != 'downgrade') ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoRenew,
                  onChanged: (v) => setState(() => _autoRenew = v),
                  title: Text(l.subAutoRenew, style: WinType.bodyS(s.onSurface)),
                  subtitle: Text(l.subAutoRenewHint, style: WinType.labelS(s.onMuted)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                WinAlert(_error!, type: BadgeColor.error),
              ],
              const SizedBox(height: 14),
              WinButton(_loading ? l.subPleaseWait : label, block: true, onTap: (_loading || q == null) ? null : _pay),
              const SizedBox(height: 8),
              Text(l.subFooterTtc,
                  style: WinType.labelS(s.onFaint), textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _line(WinScheme s, String left, String right, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Expanded(child: Text(left, style: (bold ? WinType.titleM(s.onStrong) : WinType.bodyS(s.onSurface)).copyWith(color: color))),
          Text(right, style: (bold ? WinType.titleM(s.onStrong) : WinType.bodyS(s.onSurface)).copyWith(color: color)),
        ]),
      );
}
