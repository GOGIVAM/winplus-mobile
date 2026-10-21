import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

enum LegalDoc { cgu, confidentialite }

class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  static Future<void> showCgu(BuildContext context) => Navigator.push(
        context,
        WinPageRoute(builder: (_) => const LegalScreen(doc: LegalDoc.cgu)),
      );

  static Future<void> showPrivacy(BuildContext context) => Navigator.push(
        context,
        WinPageRoute(
            builder: (_) => const LegalScreen(doc: LegalDoc.confidentialite)),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isCgu = doc == LegalDoc.cgu;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCgu ? l10n.legalCguTitle : l10n.legalPrivacyTitle,
          style: WinType.headlineS(s.onStrong),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children:
            isCgu ? _cguSections(s, l10n) : _privacySections(s, l10n),
      ),
    );
  }

  List<Widget> _cguSections(WinScheme s, AppLocalizations l10n) => [
        _meta(s, l10n.legalLastUpdated),
        _section(s, l10n.legalCgu1Title, l10n.legalCgu1Body),
        _section(s, l10n.legalCgu2Title, l10n.legalCgu2Body),
        _section(s, l10n.legalCgu3Title, l10n.legalCgu3Body),
        _section(s, l10n.legalCgu4Title, l10n.legalCgu4Body),
        _section(s, l10n.legalCgu5Title, l10n.legalCgu5Body),
        _section(s, l10n.legalCgu6Title, l10n.legalCgu6Body),
        _section(s, l10n.legalCgu7Title, l10n.legalCgu7Body),
        _section(s, l10n.legalCgu8Title, l10n.legalCgu8Body),
        _contact(s, l10n),
      ];

  List<Widget> _privacySections(WinScheme s, AppLocalizations l10n) =>
      [
        _meta(s, l10n.legalLastUpdated),
        _section(s, l10n.legalPriv1Title, l10n.legalPriv1Body),
        _section(s, l10n.legalPriv2Title, l10n.legalPriv2Body),
        _section(s, l10n.legalPriv3Title, l10n.legalPriv3Body),
        _section(s, l10n.legalPriv4Title, l10n.legalPriv4Body),
        _section(s, l10n.legalPriv5Title, l10n.legalPriv5Body),
        _section(s, l10n.legalPriv6Title, l10n.legalPriv6Body),
        _section(s, l10n.legalPriv7Title, l10n.legalPriv7Body),
        _contact(s, l10n),
      ];

  Widget _meta(WinScheme s, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(text, style: WinType.labelM(s.onMuted)),
      );

  Widget _section(WinScheme s, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: WinType.archivo(size: 15, color: s.onStrong)),
            const SizedBox(height: 8),
            Text(body, style: WinType.bodyS(s.onMuted)),
          ]),
        ),
      );

  Widget _contact(WinScheme s, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.legalContactTitle,
                style: WinType.archivo(size: 15, color: s.onStrong)),
            const SizedBox(height: 8),
            Text(
                l10n.legalContactBody,
                style: WinType.bodyS(s.onMuted)),
          ]),
        ),
      );
}
