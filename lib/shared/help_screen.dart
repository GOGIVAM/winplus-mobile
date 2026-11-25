import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/session_manager.dart';
import '../services/support_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Adresse du support (e-mails redirigés et lus par l'équipe).
const kSupportEmail = 'support@winplus.cm';

/// « Aide et contact » (lot 7), comme les pages Aide et FAQ du site :
/// questions fréquentes en panneaux dépliables, puis « Nous écrire ».
///
/// « Nous écrire » envoie le message au support (POST /support/contact,
/// gardé par le serveur et transmis à l'équipe), avec confirmation dans
/// l'écran. En secours (serveur sans cette route, 404), « Écrire par
/// e-mail » ouvre l'application e-mail avec un message prérempli.
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

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  Map<String, String> _errors = {};
  String? _formError;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    // Compte connecté : nom et e-mail déjà remplis.
    SessionManager.getUserName().then((v) {
      if (mounted && v != null && _name.text.isEmpty) _name.text = v;
    });
    SessionManager.getUserEmail().then((v) {
      if (mounted && v != null && _email.text.isEmpty) _email.text = v;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Mêmes règles que le serveur, vérifiées avant l'envoi.
  Map<String, String> _validate(AppLocalizations l) {
    final e = <String, String>{};
    final name = _name.text.trim(), email = _email.text.trim();
    if (name.length < 2) e['name'] = l.helpErrName;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) e['email'] = l.helpErrEmail;
    if (_subject.text.trim().length < 3) e['subject'] = l.helpErrSubject;
    if (_message.text.trim().length < 10) e['message'] = l.helpErrMessage;
    return e;
  }

  Future<void> _send() async {
    final l = context.l10n;
    final errors = _validate(l);
    setState(() {
      _errors = errors;
      _formError = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _sending = true);
    try {
      await SupportService.instance.contact(
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on SupportContactException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.tooMany) {
          _formError = l.helpTooMany;
        } else if (e.unavailable) {
          _formError = l.helpUnavailable;
        } else if (e.fieldErrors.isNotEmpty) {
          _errors = e.fieldErrors;
        } else {
          _formError = l.helpSendError;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _formError = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _fieldError(WinScheme s, String key) {
    final msg = _errors[key];
    if (msg == null) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(msg, style: WinType.labelS(Theme.of(context).colorScheme.error)),
    );
  }

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
    if (_sent) {
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(title: Text(l.helpTitle)),
        body: WinEmptyState(
          icon: PhosphorIconsRegular.checkCircle,
          title: l.helpSentTitle,
          message: l.helpSentText,
          actionLabel: l.commonBack,
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
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
              Text(l.helpFormIntro, style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 14),
              WinTextField(label: l.helpFormName, controller: _name),
              _fieldError(s, 'name'),
              WinTextField(
                  label: l.helpFormEmail, controller: _email, keyboardType: TextInputType.emailAddress),
              _fieldError(s, 'email'),
              WinTextField(label: l.helpFormSubject, controller: _subject),
              _fieldError(s, 'subject'),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 12,
                maxLength: 5000,
                decoration: InputDecoration(labelText: l.helpFormMessage, alignLabelWithHint: true),
              ),
              _fieldError(s, 'message'),
              if (_formError != null) ...[
                WinAlert(_formError!, type: BadgeColor.error),
                const SizedBox(height: 12),
              ],
              WinButton(l.commonSend,
                  block: true,
                  loading: _sending,
                  icon: PhosphorIconsRegular.paperPlaneTilt,
                  onTap: _sending ? null : _send),
              const SizedBox(height: 20),
              Text(l.helpWriteText, style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 6),
              SelectableText(kSupportEmail, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 10),
              WinButton(l.helpWriteButton,
                  block: true,
                  variant: WinButtonVariant.outline,
                  icon: PhosphorIconsRegular.envelopeSimple,
                  onTap: _write),
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
