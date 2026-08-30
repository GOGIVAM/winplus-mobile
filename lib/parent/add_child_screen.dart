import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});
  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false, _success = false, _error = false;
  String? _errorMsg;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() { _error = true; _errorMsg = 'Veuillez saisir un email valide.'; });
      return;
    }
    setState(() { _loading = true; _error = false; });
    final ok = await ParentService.instance.addChild(email: email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      setState(() => _success = true);
      Future.delayed(const Duration(milliseconds: 1800),
          () { if (mounted) Navigator.pop(context, true); });
    } else {
      setState(() { _error = true; _errorMsg = 'Aucun élève trouvé avec cet email, ou déjà lié.'; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isFree = SubscriptionScope.of(context).isFree;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ajouter un enfant', style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isFree)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: WinAlert(
                'Le plan Boutique Libre n\'inclut pas le suivi parental. Passez au plan Famille pour accéder aux alertes WinAI.',
                type: BadgeColor.warn,
              ),
            ),
          if (_success)
            const WinAlert('Enfant ajouté à votre compte avec succès.', type: BadgeColor.success)
          else ...[
            Text(
              'Entrez l\'adresse email du compte WinPlus de votre enfant pour le lier à votre espace parent.',
              style: WinType.bodyM(s.onSurface),
            ),
            const SizedBox(height: 24),
            WinTextField(
              label: 'Email de l\'enfant *',
              hint: 'ahmed@example.com',
              icon: Icons.email_outlined,
              controller: _emailCtrl,
              onChanged: (_) => setState(() => _error = false),
            ),
            if (_error && _errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMsg!, style: WinType.labelM(WinColors.error)),
              ),
            const SizedBox(height: 32),
            WinButton(
              'Lier l\'enfant',
              block: true,
              loading: _loading,
              onTap: _loading ? null : _submit,
            ),
          ],
        ]),
      ),
    );
  }
}
