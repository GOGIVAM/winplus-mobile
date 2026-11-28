import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/two_factor_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/external_links.dart';
import '../widgets/win_screen.dart';
import 'more_screen.dart';
import '../widgets/win_widgets.dart';

/// Double authentification, pour tous les comptes (Paramètres) :
/// - désactivée : activer, ajouter WinPlus dans l'application
///   d'authentification (lien sur ce téléphone, clé à saisir, QR code pour
///   un autre appareil), confirmer par un premier code ;
/// - codes de secours montrés une seule fois, à copier ;
/// - activée : nouveaux codes de secours, désactivation (mot de passe et code).
class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});
  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  final _svc = TwoFactorService.instance;
  TwoFactorStatus? _status;
  bool _failed = false;
  TwoFactorSetup? _setup;
  List<String>? _codes;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _status = null;
    });
    try {
      final st = await _svc.status();
      if (mounted) setState(() => _status = st);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } on TwoFactorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.twoFaError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enable() => _run(() async {
        final setup = await _svc.enable();
        if (mounted) setState(() => _setup = setup);
      });

  Future<void> _confirm() => _run(() async {
        final codes = await _svc.verify(_code.text);
        if (!mounted) return;
        _code.clear();
        setState(() {
          _setup = null;
          _codes = codes;
        });
      });

  void _finishCodes() {
    setState(() => _codes = null);
    _load();
  }

  /// Demande un code (et le mot de passe pour la désactivation).
  Future<({String code, String password})?> _ask(String title, {required bool withPassword}) {
    final code = TextEditingController();
    final pwd = TextEditingController();
    final l = context.l10n;
    return showDialog<({String code, String password})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (withPassword) ...[
            WinTextField(label: l.twoFaPasswordLabel, controller: pwd, obscure: true),
            const SizedBox(height: 12),
          ],
          WinTextField(
              label: withPassword ? l.twoFaCodeLabel : l.twoFaAppCodeLabel,
              controller: code,
              keyboardType: TextInputType.visiblePassword),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, (code: code.text, password: pwd.text)),
              child: Text(l.commonConfirm)),
        ],
      ),
    );
  }

  Future<void> _newCodes() async {
    final r = await _ask(context.l10n.twoFaNewCodes, withPassword: false);
    if (r == null || !mounted) return;
    await _run(() async {
      final codes = await _svc.newBackupCodes(r.code);
      if (mounted) setState(() => _codes = codes);
    });
  }

  Future<void> _disable() async {
    final r = await _ask(context.l10n.twoFaDisable, withPassword: true);
    if (r == null || !mounted) return;
    await _run(() async {
      await _svc.disable(password: r.password, code: r.code);
      await _load();
    });
  }

  void _copy(String text, String done) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = WinTheme.of(context);
    Widget body;
    if (_failed) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (_status == null) {
      body = const WinLoading();
    } else {
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        Text(l.twoFaIntro, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 16),
        if (_codes != null)
          ..._codesView(s)
        else if (_setup != null)
          ..._setupView(s)
        else
          ..._statusView(s),
        if (_error != null) ...[
          const SizedBox(height: 12),
          WinAlert(_error!, type: BadgeColor.error),
        ],
      ]);
    }
    return MorePage(title: l.twoFaTitle, child: body);
  }

  List<Widget> _statusView(WinScheme s) {
    final l = context.l10n;
    final st = _status!;
    return [
      WinCard(
        child: Row(children: [
          Icon(st.isEnabled ? PhosphorIconsFill.shieldCheck : PhosphorIconsRegular.shield,
              size: 28, color: st.isEnabled ? s.primary : s.onFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  st.isEnabled
                      ? (st.enabledAt != null ? l.twoFaEnabledSince(WinFormat.date(st.enabledAt!)) : l.twoFaEnabled)
                      : l.twoFaDisabled,
                  style: WinType.titleM(s.onStrong)),
              if (st.isEnabled)
                Text(l.twoFaBackupLeft(st.backupCodesCount), style: WinType.bodyS(s.onMuted)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      if (!st.isEnabled)
        WinButton(l.twoFaEnable, block: true, loading: _busy, onTap: _enable)
      else ...[
        WinButton(l.twoFaNewCodes,
            block: true, variant: WinButtonVariant.outline, loading: _busy, onTap: _newCodes),
        const SizedBox(height: 10),
        WinButton(l.twoFaDisable, block: true, variant: WinButtonVariant.outline, onTap: _busy ? null : _disable),
      ],
    ];
  }

  List<Widget> _setupView(WinScheme s) {
    final l = context.l10n;
    final setup = _setup!;
    return [
      Text(l.twoFaStep1, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 10),
      if (setup.otpauthUrl != null) ...[
        WinButton(l.twoFaOpenApp,
            block: true,
            icon: PhosphorIconsRegular.arrowSquareOut,
            onTap: () => ExternalLinks.open(setup.otpauthUrl!)),
        const SizedBox(height: 12),
      ],
      Text(l.twoFaKeyLabel, style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 6),
      WinCard(
        child: Row(children: [
          Expanded(child: SelectableText(setup.secretGrouped, style: WinType.titleM(s.onStrong))),
          IconButton(
              tooltip: l.twoFaCopyKey,
              icon: Icon(PhosphorIconsRegular.copy, color: s.primary),
              onPressed: () => _copy(setup.secret, l.twoFaKeyCopied)),
        ]),
      ),
      if (setup.qrPng != null) ...[
        const SizedBox(height: 12),
        Text(l.twoFaQrHint, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Image.memory(setup.qrPng!, width: 180, height: 180),
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text(l.twoFaStep2, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 10),
      WinTextField(label: l.authTwoFactorCode, controller: _code, keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      WinButton(l.twoFaConfirm, block: true, loading: _busy, onTap: _confirm),
    ];
  }

  List<Widget> _codesView(WinScheme s) {
    final l = context.l10n;
    final codes = _codes!;
    return [
      Text(l.twoFaBackupTitle, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 6),
      WinAlert(l.twoFaBackupHint, type: BadgeColor.warn),
      const SizedBox(height: 12),
      WinCard(
        child: Wrap(spacing: 16, runSpacing: 10, children: [
          for (final c in codes) SelectableText(c, style: WinType.titleM(s.onStrong)),
        ]),
      ),
      const SizedBox(height: 16),
      WinButton(l.twoFaCopyCodes,
          block: true,
          variant: WinButtonVariant.outline,
          icon: PhosphorIconsRegular.copy,
          onTap: () => _copy(codes.join('\n'), l.twoFaCopied)),
      const SizedBox(height: 10),
      WinButton(l.twoFaDone, block: true, onTap: _finishCodes),
    ];
  }
}
