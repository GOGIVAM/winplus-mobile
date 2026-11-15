import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';

/// Reconfirmation périodique d'identité, affichée au démarrage quand le
/// serveur la demande (GET /auth/reconfirmation-status, tous les 35 jours).
/// Comme sur le site : pas de retour arrière, l'utilisateur confirme avec le
/// code reçu par e-mail ou se déconnecte.
class PeriodicConfirmScreen extends StatefulWidget {
  final ReconfirmationStatus status;
  const PeriodicConfirmScreen({super.key, required this.status});
  @override
  State<PeriodicConfirmScreen> createState() => _PeriodicConfirmScreenState();
}

class _PeriodicConfirmScreenState extends State<PeriodicConfirmScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _sending = false;
  bool _loading = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _startResendCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await AuthService.instance.sendPeriodicCode();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (res.success) {
        _codeSent = true;
      } else {
        _error = res.message;
      }
    });
    if (!res.success) return;
    for (final c in _ctrls) {
      c.clear();
    }
    _startResendCountdown();
    _nodes[0].requestFocus();
  }

  Future<void> _confirm() async {
    if (_code.length < 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AuthService.instance.verifyPeriodicCode(_code);
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message;
      });
      return;
    }
    // Identité confirmée : l'espace du compte, sans retour possible ici.
    final roleStr = await SessionManager.getUserRole();
    if (!mounted) return;
    WinAppScope.of(context).setRole(winRoleFromString(roleStr));
    Navigator.of(context).pushAndRemoveUntil(
      WinPageRoute(builder: (_) => const RoleShell()),
      (r) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      WinPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: s.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, size: 40, color: s.primary),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.authVerifyItsYou,
                style: WinType.displayS(s.onStrong),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPeriodicIntro(widget.status.windowDays),
                style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (widget.status.maskedEmail.isNotEmpty)
              Text(
                widget.status.maskedEmail,
                style: WinType.bodyM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              if (!_codeSent) ...[
                // Step 1: envoyer le code. Un refus d'envoi (trop de
                // demandes, réseau) doit se voir ici, avant les cases.
                if (_error != null) ...[
                  WinAlert(_error!,
                      type: BadgeColor.error, icon: Icons.error_outline),
                  const SizedBox(height: 16),
                ],
                WinButton(
                  l10n.authSendCode,
                  block: true,
                  loading: _sending,
                  icon: Icons.send_outlined,
                  onTap: _sending ? null : _sendCode,
                ),
              ] else ...[
                // Step 2: saisir le code
                WinAlert(
                  l10n.authCodeSentEmail,
                  type: BadgeColor.success,
                  icon: Icons.mark_email_read_outlined,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                      6,
                      (i) => SizedBox(
                            width: 44,
                            height: 56,
                            child: TextField(
                              controller: _ctrls[i],
                              focusNode: _nodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style:
                                  WinType.archivo(size: 22, color: s.onStrong),
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(WinRadii.md),
                                  borderSide:
                                      BorderSide(color: s.outline, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(WinRadii.md),
                                  borderSide:
                                      BorderSide(color: s.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: s.surface,
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 5) {
                                  _nodes[i + 1].requestFocus();
                                } else if (v.isEmpty && i > 0) {
                                  _nodes[i - 1].requestFocus();
                                }
                                if (_code.length == 6) _confirm();
                              },
                            ),
                          )),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  WinAlert(_error!,
                      type: BadgeColor.error, icon: Icons.error_outline),
                ],
                const SizedBox(height: 24),
                WinButton(
                  l10n.commonConfirm,
                  block: true,
                  loading: _loading,
                  onTap: _loading ? null : _confirm,
                ),
                const SizedBox(height: 12),
                Center(
                  child: _countdown > 0
                      ? Text(l10n.authResendIn(_countdown),
                          style: WinType.labelM(s.onMuted))
                      : TextButton(
                          onPressed: _sendCode,
                          child: Text(l10n.authResendCode,
                              style: WinType.manrope(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: s.primary)),
                        ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: _logout,
                child: Text(l10n.authLogMeOut,
                    style: WinType.labelM(s.onMuted)
                        .copyWith(decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
