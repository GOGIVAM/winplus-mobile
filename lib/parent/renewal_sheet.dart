import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class RenewalSheet extends StatefulWidget {
  const RenewalSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const RenewalSheet(),
      );

  @override
  State<RenewalSheet> createState() => _RenewalSheetState();
}

class _RenewalSheetState extends State<RenewalSheet> {
  bool _annual = false;
  String _payment = 'mtn';
  bool _loading = false;
  String? _error;
  final _phoneCtrl = TextEditingController();

  static const int _monthlyPrice = 12000;

  int get _price => _annual ? (_monthlyPrice * 12 * 0.85).round() : _monthlyPrice;

  String get _priceLabel => _annual
      ? '${fmtXaf(_price)} XAF/an · -15% · Payé en une fois'
      : '${fmtXaf(_price)} XAF/mois';

  bool get _phoneValid => RegExp(r'^6[0-9]{8}$').hasMatch(_phoneCtrl.text.trim());

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_phoneValid) {
      setState(() => _error = 'Numéro invalide. Format : 6XX XXX XXX (9 chiffres)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Renouvellement confirmé !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: s.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Renouveler mon abonnement',
                style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 4),
            Text('Plan Famille · 12 000 XAF/mois',
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),

            // Toggle mensuel / annuel
            Container(
              decoration: BoxDecoration(
                color: s.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                _PeriodChip('Mensuel', !_annual, () => setState(() => _annual = false)),
                _PeriodChip('Annuel (-15%)', _annual, () => setState(() => _annual = true)),
              ]),
            ),
            const SizedBox(height: 16),

            // Résumé montant
            WinCard(
              child: Row(children: [
                Icon(Icons.receipt_outlined, size: 20, color: s.onFaint),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Montant à régler', style: WinType.labelM(s.onMuted)),
                  const SizedBox(height: 2),
                  Text(_priceLabel,
                      style: WinType.archivo(size: 16, color: s.onStrong)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // Mode de paiement
            Text('Moyen de paiement', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 12),
            Row(children: [
              _PayChip(
                label: 'MTN Mobile Money',
                color: const Color(0xFFFFCC00),
                selected: _payment == 'mtn',
                onTap: () => setState(() => _payment = 'mtn'),
              ),
              const SizedBox(width: 8),
              _PayChip(
                label: 'Orange Money',
                color: const Color(0xFFFF6600),
                selected: _payment == 'orange',
                onTap: () => setState(() => _payment = 'orange'),
              ),
            ]),
            const SizedBox(height: 16),

            // Numéro Mobile Money
            Text('Numéro Mobile Money', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                hintText: '6XX XXX XXX',
                hintStyle: WinType.bodyM(s.onFaint),
                prefixText: '+237 ',
                prefixStyle: WinType.bodyM(s.onMuted),
                filled: true,
                fillColor: s.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: s.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: s.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: s.primary, width: 2),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              WinAlert(_error!, type: BadgeColor.error, icon: Icons.error_outline),
            ],
            const SizedBox(height: 24),

            WinButton(
              'Confirmer le renouvellement',
              block: true,
              loading: _loading,
              icon: Icons.check_circle_outline,
              onTap: _loading ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? s.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: WinType.manrope(
              size: 13,
              weight: FontWeight.w600,
              color: selected ? s.onPrimary : s.onMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PayChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : s.outline, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: WinType.manrope(size: 12, weight: FontWeight.w600, color: s.onStrong),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
