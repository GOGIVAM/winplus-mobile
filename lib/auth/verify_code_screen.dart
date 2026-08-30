import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'email_verified_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});
  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  bool _loading = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) { t.cancel(); } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.verifyEmail(widget.email, _code);
    if (!mounted) return;
    if (result.success) {
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const EmailVerifiedScreen()));
    } else {
      setState(() { _loading = false; _error = result.message ?? 'Code invalide.'; });
    }
  }

  Future<void> _resend() async {
    _startTimer();
    await AuthService.instance.resendVerification(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text('Vérification email', style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text('Un code à 6 chiffres a été envoyé à votre adresse.',
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _CodeBox(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _nodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _nodes[i - 1].requestFocus();
                  }
                  setState(() {});
                },
              )),
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              WinAlert(_error!, type: BadgeColor.error),
              const SizedBox(height: 16),
            ],
            WinButton('Vérifier',
                block: true,
                loading: _loading,
                onTap: _code.length == 6 ? _verify : null),
              const SizedBox(height: 20),
              Center(
                child: _countdown > 0
                    ? Text('Renvoyer le code (${_countdown}s)',
                        style: WinType.bodyM(s.onFaint))
                    : GestureDetector(
                        onTap: _resend,
                        child: Text('Renvoyer le code',
                            style: WinType.bodyM(s.primary)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _CodeBox({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: WinType.archivo(size: 22, color: s.onStrong),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: s.outline, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: WinColors.teal500, width: 2),
          ),
          fillColor: s.surface,
          filled: true,
        ),
      ),
    );
  }
}
