import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/certificate_verify_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// « Vérifier un certificat » (lot 7), comme /verify/{code} du site : on
/// saisit le code imprimé sur le certificat ; l'écran dit s'il est authentique
/// et à qui il a été délivré.
class VerifyCertificateScreen extends StatefulWidget {
  final String? initialCode;
  const VerifyCertificateScreen({super.key, this.initialCode});

  @override
  State<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  CertificateCheck? _result;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Après la première image : _verify lit les traductions du contexte.
    if ((widget.initialCode ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _verify();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l = context.l10n;
    final code = _code.text.trim();
    if (code.length < 4) {
      setState(() => _error = l.certVerifyCodeRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await CertificateVerifyService.instance.verify(code);
      if (mounted) setState(() => _result = r);
    } catch (_) {
      if (mounted) setState(() => _error = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final r = _result;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.certVerifyTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.certVerifyIntro, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 16),
          WinTextField(label: l.certVerifyCode, controller: _code, icon: PhosphorIconsRegular.sealCheck),
          const SizedBox(height: 12),
          if (_error != null) ...[
            WinAlert(_error!, type: BadgeColor.error),
            const SizedBox(height: 12),
          ],
          WinButton(l.certVerifyButton,
              block: true, loading: _busy, icon: PhosphorIconsRegular.magnifyingGlass, onTap: _busy ? null : _verify),
          const SizedBox(height: 20),
          if (r != null && r.valid)
            WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WinBadge(l.certVerifyAuthentic, color: BadgeColor.success),
                const SizedBox(height: 10),
                if ((r.studentName ?? '').isNotEmpty) Text(r.studentName!, style: WinType.headlineS(s.onStrong)),
                if ((r.title ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.title!, style: WinType.bodyM(s.onStrong)),
                ],
                const SizedBox(height: 8),
                Text(
                    [
                      if (r.issuedAt != null) l.certVerifyIssued(WinFormat.dateShort(r.issuedAt!)),
                      // Lot 1 : la note du serveur est un pourcentage, affichée sur 20.
                      if (r.grade != null) l.certVerifyGrade(WinFormat.grade20(r.grade)),
                      if ((r.number ?? '').isNotEmpty) r.number!,
                    ].join(' · '),
                    style: WinType.labelM(s.onMuted)),
              ]),
            )
          else if (r != null)
            WinAlert(l.certVerifyInvalid, type: BadgeColor.error, icon: PhosphorIconsRegular.shieldWarning),
        ]),
      ),
    );
  }
}
