import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_manager.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'welcome_screen.dart';

class PeriodicConfirmScreen extends StatefulWidget {
  final String email;
  const PeriodicConfirmScreen({super.key, required this.email});
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
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final local = parts[0];
    final domain = parts[1];
    final visible = local.length > 1 ? local[0] : local;
    return '$visible***@$domain';
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
    setState(() { _sending = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() { _sending = false; _codeSent = true; });
    _startResendCountdown();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _nodes.isNotEmpty) _nodes[0].requestFocus();
    });
  }

  Future<void> _confirm() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    // Mock: accept "123456" in devMode
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final isValid = _code == '123456';
    setState(() => _loading = false);
    if (isValid) {
      await SessionManager.setLastConfirmed();
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Code incorrect. Vérifiez votre email.');
    }
  }

  void _logout() {
    SessionManager.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
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
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: s.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, size: 40, color: s.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Vérifiez que c\'est bien vous',
                style: WinType.displayS(s.onStrong),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pour votre sécurité, confirmez votre identité (toutes les 20 jours)',
                style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _maskedEmail,
                style: WinType.bodyM(s.primary).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              if (!_codeSent) ...[
                // Step 1: envoyer le code
                WinButton(
                  'Envoyer le code',
                  block: true,
                  loading: _sending,
                  icon: Icons.send_outlined,
                  onTap: _sending ? null : _sendCode,
                ),
              ] else ...[
                // Step 2: saisir le code
                const WinAlert(
                  'Code envoyé à votre email',
                  type: BadgeColor.success,
                  icon: Icons.mark_email_read_outlined,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => SizedBox(
                    width: 44,
                    height: 56,
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: WinType.archivo(size: 22, color: s.onStrong),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: s.outline, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: s.primary, width: 2),
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
                  WinAlert(_error!, type: BadgeColor.error, icon: Icons.error_outline),
                ],
                const SizedBox(height: 24),
                WinButton(
                  'Confirmer',
                  block: true,
                  loading: _loading,
                  onTap: _loading ? null : _confirm,
                ),
                const SizedBox(height: 12),
                Center(
                  child: _countdown > 0
                      ? Text('Renvoyer le code dans ${_countdown}s',
                          style: WinType.labelM(s.onMuted))
                      : TextButton(
                          onPressed: _sendCode,
                          child: Text('Renvoyer le code',
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
                child: Text('Me déconnecter',
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
