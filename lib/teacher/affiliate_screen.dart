import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/models.dart' show fmtXaf;
import '../l10n/l10n.dart';
import '../services/affiliate_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/external_links.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Affiliation » du professeur (lot 7), comme AffiliateProgramPanel du
/// site : son lien de parrainage (copier, partager), ses chiffres et ses
/// commissions sur les achats faits par les personnes qu'il a amenées.
class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});

  /// Partage du lien ; remplaçable dans les tests.
  static Future<void> Function(String url, String subject) share =
      (url, subject) => ExternalLinks.share(url, subject: subject);

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> {
  AffiliateOverview? _data;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final d = await AffiliateService.instance.overview();
      if (mounted) setState(() => _data = d);
    } catch (_) {
      if (mounted && _data == null) setState(() => _error = true);
    }
  }

  Future<void> _copy(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = context.l10n.affLinkCopied;
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  void _share(String url) => AffiliateScreen.share(url, context.l10n.affShareSubject);

  String _xaf(num v) => '${fmtXaf(v.round())} XAF';

  (String, BadgeColor) _status(AppLocalizations l, String status) => switch (status) {
        'paid' => (l.affStatusPaid, BadgeColor.success),
        'confirmed' => (l.affStatusConfirmed, BadgeColor.teal),
        'reversed' => (l.affStatusReversed, BadgeColor.neutral),
        _ => (l.affStatusPending, BadgeColor.warn),
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (d == null) {
      body = const WinLoading();
    } else {
      final url = d.account.referralUrl;
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.affIntro, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          WinCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.affLinkTitle, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 2),
              Text(l.affRate(d.account.commissionRate.toString()), style: WinType.labelM(s.onMuted)),
              const SizedBox(height: 10),
              SelectableText(url, style: WinType.bodyM(s.onStrong)),
              Text(l.affCode(d.account.code), style: WinType.labelM(s.onMuted)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: WinButton(l.affCopy,
                      block: true,
                      variant: WinButtonVariant.outline,
                      icon: PhosphorIconsRegular.copy,
                      onTap: () => _copy(url)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WinButton(l.affShare,
                      block: true, icon: PhosphorIconsRegular.shareNetwork, onTap: () => _share(url)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: WinStatCard('${d.stats.clicks}', l.affClicks, icon: PhosphorIconsRegular.cursorClick)),
            const SizedBox(width: 10),
            Expanded(child: WinStatCard('${d.stats.conversions}', l.affConversions, icon: PhosphorIconsRegular.userPlus)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: WinStatCard(_xaf(d.stats.confirmed + d.stats.paid), l.affEarned, icon: PhosphorIconsRegular.wallet)),
            const SizedBox(width: 10),
            Expanded(child: WinStatCard(_xaf(d.stats.pending), l.affPending, icon: PhosphorIconsRegular.hourglass)),
          ]),
          const SizedBox(height: 20),
          Text(l.affCommissions, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          if (d.commissions.isEmpty)
            WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.affEmpty, style: WinType.bodyM(s.onMuted)),
                const SizedBox(height: 12),
                WinButton(l.affShareMyLink,
                    block: true, icon: PhosphorIconsRegular.shareNetwork, onTap: () => _share(url)),
              ]),
            )
          else
            for (final c in d.commissions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WinCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_xaf(c.amount), style: WinType.titleM(s.onStrong)),
                        Text(
                            [
                              if (c.createdAt != null) WinFormat.dateShort(c.createdAt!),
                              l.affOrder(c.orderNumber, _xaf(c.orderAmount)),
                            ].join(' · '),
                            style: WinType.labelM(s.onMuted)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    WinBadge(_status(l, c.status).$1, color: _status(l, c.status).$2),
                  ]),
                ),
              ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.affTitle)),
      body: SafeArea(child: body),
    );
  }
}
