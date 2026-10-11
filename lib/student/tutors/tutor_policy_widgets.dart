import 'package:flutter/material.dart';
import '../../services/tutor_booking_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Ouvre la politique de tutorat publique (lot 9.2, 17.10). L'écran ne
/// demande aucune connexion : l'endpoint est anonyme.
void openTutorPolicy(BuildContext context) {
  Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TutorPolicyScreen()));
}

/// Réglages d'annulation effectifs d'un tuteur (bornés par la plateforme),
/// règle des frais Mobile Money, délai de contestation, et lien vers la
/// politique. Les chiffres viennent du serveur (profil du tuteur et
/// GET /tutor-policy), comme sur le web.
class TutorCancellationPolicyCard extends StatefulWidget {
  final int fullRefundHours;
  final int partialRefundPercent;
  final int noRefundHours;
  final bool compact;

  const TutorCancellationPolicyCard({
    super.key,
    required this.fullRefundHours,
    required this.partialRefundPercent,
    required this.noRefundHours,
    this.compact = false,
  });

  @override
  State<TutorCancellationPolicyCard> createState() =>
      _TutorCancellationPolicyCardState();
}

class _TutorCancellationPolicyCardState
    extends State<TutorCancellationPolicyCard> {
  TutorPolicy? _policy;

  @override
  void initState() {
    super.initState();
    TutorBookingService.instance.getPolicy().then((p) {
      if (mounted) setState(() => _policy = p);
    }).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final full = widget.fullRefundHours;
    final none = widget.noRefundHours;
    final p = _policy;
    final lines = <String>[
      'Remboursement intégral si tu annules au moins $full h avant la séance.',
      if (none < full)
        '${widget.partialRefundPercent} % remboursés entre $none h et $full h avant.',
      none > 0
          ? 'Aucun remboursement à moins de $none h.'
          : 'Remboursement possible jusqu\'au début de la séance.',
      if (!widget.compact)
        'Si le tuteur annule, refuse ou ne répond pas : remboursement intégral.',
      p != null
          ? 'Remboursements versés immédiatement sur ton portefeuille WinPlus. Si tu annules une séance payée par Mobile Money, ${p.feePercentLabel} % de frais de l\'opérateur sont déduits ; aucun frais pour un paiement par solde.'
          : 'Remboursements versés immédiatement sur ton portefeuille WinPlus.',
      if (p != null)
        'Après la séance, tu as ${p.disputeWindowHours} h pour la contester.',
    ];
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: WinColors.teal700),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Politique d\'annulation de ce tuteur',
                  style: WinType.titleM(s.onStrong))),
        ]),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('•  ', style: WinType.bodyS(s.onMuted)),
                Expanded(child: Text(l, style: WinType.bodyS(s.onMuted))),
              ]),
            )),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => openTutorPolicy(context),
          child: Text('Lire la politique de tutorat',
              style: WinType.labelM(WinColors.teal700)
                  .copyWith(decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }
}

/// Politique de tutorat publique, même source que la page web
/// /politique-tutorat (GET /api/tutor-policy).
class TutorPolicyScreen extends StatefulWidget {
  const TutorPolicyScreen({super.key});

  @override
  State<TutorPolicyScreen> createState() => _TutorPolicyScreenState();
}

class _TutorPolicyScreenState extends State<TutorPolicyScreen> {
  TutorPolicy? _policy;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final p = await TutorBookingService.instance.getPolicy();
      if (mounted) setState(() => _policy = p);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final p = _policy;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text('Politique de tutorat', style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _error
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const WinAlert('Impossible de charger la politique.',
                      type: BadgeColor.error),
                  const SizedBox(height: 12),
                  WinButton('Réessayer',
                      variant: WinButtonVariant.outline, onTap: _load),
                ]),
              ))
            : p == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                          'Les règles communes à toutes les séances de cours particuliers réservées sur WinPlus.',
                          style: WinType.bodyS(s.onMuted)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Fact('${p.disputeWindowHours} h',
                            'pour contester une séance'),
                        const _Fact('Immédiat', 'remboursement au portefeuille'),
                        _Fact('${p.feePercentLabel} %',
                            'de frais Mobile Money si tu annules toi-même'),
                      ]),
                      const SizedBox(height: 12),
                      ...p.sections.map((sec) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: WinCard(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sec.title,
                                        style: WinType.titleM(s.onStrong)),
                                    const SizedBox(height: 8),
                                    ...sec.paragraphs.map((t) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Text(t,
                                              style: WinType.bodyS(s.onSurface)),
                                        )),
                                  ]),
                            ),
                          )),
                      if (p.version.isNotEmpty)
                        Text('Version du ${_frDate(p.version)}.',
                            style: WinType.labelS(s.onFaint)),
                    ],
                  ),
      ),
    );
  }

  static String _frDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _Fact extends StatelessWidget {
  final String value;
  final String label;
  const _Fact(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: s.chipBg,
        borderRadius: BorderRadius.circular(WinRadii.sm),
        border: Border.all(color: s.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 2),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    );
  }
}
