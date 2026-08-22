import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.forgotPassword(email);
    if (!mounted) return;
    if (result.success) {
      setState(() { _loading = false; _sent = true; });
    } else {
      setState(() { _loading = false; _error = result.message ?? 'Erreur réseau.'; });
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Mot de passe oublié', style: WinType.displayS(s.onStrong)),
              const SizedBox(height: 8),
              Text(
                'Entrez votre adresse email, nous vous enverrons un lien de réinitialisation.',
                style: WinType.bodyM(s.onMuted),
              ),
              const SizedBox(height: 32),
              if (_sent) ...[
                WinAlert(
                  'Email envoyé à ${_ctrl.text.trim()}. Vérifiez aussi vos spams.',
                  type: BadgeColor.success,
                ),
                const SizedBox(height: 24),
                Text('Vous n\'avez pas reçu l\'email ?', style: WinType.bodyM(s.onMuted)),
                const SizedBox(height: 12),
                WinButton('Renvoyer l\'email',
                    variant: WinButtonVariant.outline,
                    block: true,
                    onTap: () => setState(() => _sent = false)),
              ] else ...[
                WinTextField(
                  label: 'Adresse email',
                  hint: 'votre@email.com',
                  icon: Icons.email_outlined,
                  controller: _ctrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  WinAlert(_error!, type: BadgeColor.error),
                ],
                const SizedBox(height: 24),
                WinButton('Envoyer le lien',
                    block: true,
                    loading: _loading,
                    onTap: _send),
              ],
              const SizedBox(height: 16),
              Center(
                child: WinButton('Retour à la connexion',
                    variant: WinButtonVariant.ghost,
                    onTap: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
