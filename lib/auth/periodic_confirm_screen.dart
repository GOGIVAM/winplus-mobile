import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class PeriodicConfirmScreen extends StatefulWidget {
  final String email;
  const PeriodicConfirmScreen({super.key, required this.email});
  @override
  State<PeriodicConfirmScreen> createState() => _PeriodicConfirmScreenState();
}

class _PeriodicConfirmScreenState extends State<PeriodicConfirmScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  Timer? _timer;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
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
    final visible = local.length > 3 ? local.substring(0, 3) : local;
    return '$visible***@$domain';
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _confirm() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.verifyEmail(widget.email, _code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      Navigator.pop(context);
    } else {
      setState(() => _error = result.message ?? 'Code incorrect. Réessaie.');
    }
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vérification périodique',
                  style: WinType.displayS(s.onStrong)),
              const SizedBox(height: 12),
              Text(
                'Pour ta sécurité, WinPlus demande une confirmation toutes les 30 à 45 jours. Saisis le code envoyé à ton adresse email.',
                style: WinType.bodyM(s.onMuted),
              ),
              const SizedBox(height: 8),
              Text(_maskedEmail,
                  style: WinType.bodyM(s.primary)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
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
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: WinType.bodyS(WinColors.error)),
              ],
              const SizedBox(height: 24),
              WinButton('Confirmer',
                  block: true,
                  loading: _loading,
                  onTap: _confirm),
              const SizedBox(height: 12),
              Center(
                child: _countdown > 0
                    ? Text('Renvoyer le code dans ${_countdown}s',
                        style: WinType.labelM(s.onMuted))
                    : TextButton(
                        onPressed: _startTimer,
                        child: Text('Renvoyer le code',
                            style: WinType.manrope(
                                size: 14,
                                weight: FontWeight.w600,
                                color: s.primary)),
                      ),
              ),
              const SizedBox(height: 8),
              WinButton('Déconnexion',
                  variant: WinButtonVariant.ghost,
                  block: true,
                  onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
