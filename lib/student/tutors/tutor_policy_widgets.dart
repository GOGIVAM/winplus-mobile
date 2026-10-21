import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
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
      context.l10n.tutoringPolicyFull(full),
      if (none < full)
        context.l10n.tutoringPolicyPartial(widget.partialRefundPercent, none, full),
      none > 0
          ? context.l10n.tutoringPolicyNone(none)
          : context.l10n.tutoringPolicyUntilStart,
      if (!widget.compact)
        context.l10n.tutoringPolicyTutorCancels,
      p != null
          ? context.l10n.tutoringPolicyWalletFee(p.feePercentLabel)
          : context.l10n.tutoringPolicyWallet,
      if (p != null)
        context.l10n.tutoringPolicyDispute(p.disputeWindowHours),
    ];
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: WinColors.teal700),
          const SizedBox(width: 8),
          Expanded(
              child: Text(context.l10n.tutoringPolicyCardTitle,
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
          child: Text(context.l10n.tutoringPolicyRead,
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
        title: Text(context.l10n.studentHubTutorPolicy, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _error
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  WinAlert(context.l10n.tutoringPolicyLoadError,
                      type: BadgeColor.error),
                  const SizedBox(height: 12),
                  WinButton(context.l10n.commonRetry,
                      variant: WinButtonVariant.outline, onTap: _load),
                ]),
              ))
            : p == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                          context.l10n.tutoringPolicyIntro,
                          style: WinType.bodyS(s.onMuted)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Fact('${p.disputeWindowHours} h',
                            context.l10n.tutoringPolicyFactDispute),
                        _Fact(context.l10n.tutoringPolicyFactImmediate, context.l10n.tutoringPolicyFactRefund),
                        _Fact(context.l10n.tutoringPercent(p.feePercentLabel),
                            context.l10n.tutoringPolicyFactFee),
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
                        Text(context.l10n.tutoringPolicyVersion(_frDate(p.version)),
                            style: WinType.labelS(s.onFaint)),
                    ],
                  ),
      ),
    );
  }

  static String _frDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return WinFormat.dateNumeric(d);
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
