import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/session_manager.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Adresse du support (e-mails redirigés et lus par l'équipe).
const kSupportEmail = 'support@winplus.cm';

/// « Aide et contact » (lot 7), comme les pages Aide et FAQ du site :
/// questions fréquentes en panneaux dépliables, puis « Nous écrire ».
///
/// Le formulaire du site envoie vers une route qui n'existe pas (les messages
/// sont perdus) : ici, « Écrire au support » ouvre l'application e-mail du
/// téléphone avec un message prérempli (compte et profil), qui part
/// réellement. À remplacer par un envoi direct quand le serveur aura une
/// route de contact.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  /// Ouverture du message ; remplaçable dans les tests.
  static Future<bool> Function(Uri uri) mailer =
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _open;

  /// Aucune application e-mail n'a pu s'ouvrir : l'adresse et « Copier ».
  bool _noMailApp = false;

  List<(String, String)> _faq(AppLocalizations l) => [
        (l.helpQ1, l.helpA1),
        (l.helpQ2, l.helpA2),
        (l.helpQ3, l.helpA3),
        (l.helpQ4, l.helpA4),
        (l.helpQ5, l.helpA5),
        (l.helpQ6, l.helpA6),
        (l.helpQ7, l.helpA7),
        (l.helpQ8, l.helpA8),
      ];

  Future<void> _write() async {
    final l = context.l10n;
    final email = await SessionManager.getUserEmail() ?? '';
    final role = await SessionManager.getUserRole() ?? '';
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: _query({'subject': l.helpMailSubject, 'body': l.helpMailBody(email, role)}),
    );
    var ok = false;
    try {
      ok = await HelpScreen.mailer(uri);
    } catch (_) {
      ok = false;
    }
    if (mounted) setState(() => _noMailApp = !ok);
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.helpCopied;
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }

  /// mailto attend %20 pour les espaces (pas « + »).
  static String _query(Map<String, String> p) => p.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final faq = _faq(l);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.helpTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.helpFaq, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          WinCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              for (var i = 0; i < faq.length; i++) ...[
                if (i > 0) Divider(height: 1, color: s.outline),
                InkWell(
                  onTap: () => setState(() => _open = _open == i ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(faq[i].$1, style: WinType.titleM(s.onStrong))),
                        Icon(_open == i ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                            size: 18, color: s.onFaint),
                      ]),
                      if (_open == i) ...[
                        const SizedBox(height: 8),
                        Text(faq[i].$2, style: WinType.bodyM(s.onMuted)),
                      ],
                    ]),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          Text(l.helpWrite, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          WinCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.helpWriteText, style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 6),
              SelectableText(kSupportEmail, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 14),
              WinButton(l.helpWriteButton,
                  block: true, icon: PhosphorIconsRegular.envelopeSimple, onTap: _write),
              if (_noMailApp) ...[
                const SizedBox(height: 12),
                WinAlert(l.helpNoMailApp, icon: PhosphorIconsRegular.info),
                const SizedBox(height: 8),
                WinButton(l.helpCopy,
                    block: true,
                    variant: WinButtonVariant.outline,
                    icon: PhosphorIconsRegular.copy,
                    onTap: _copy),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
