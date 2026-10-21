import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/parent_service.dart';
import '../services/subscription_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

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
      setState(() {
        _error = true;
        _errorMsg = L10n.current.parentAddChildInvalidEmail;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
    });
    bool ok = false;
    try {
      ok = await ParentService.instance.addChild(email: email);
    } on OfflineActionException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg = e.message;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      setState(() => _success = true);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      setState(() {
        _error = true;
        _errorMsg = ParentService.instance.lastAddChildError ?? L10n.current.parentAddChildNotFound;
      });
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
    // Lot 9.7b : le plan gratuit suit 1 enfant (children.max) ; le serveur
    // refuse au-delà (403 children_limit). Plus de test sur un nom de plan.
    final sub = SubscriptionScope.of(context);
    final maxChildren = sub.limit(EntitlementKeys.childrenMax);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.parentAddChildTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!sub.has(EntitlementKeys.childrenCatalog))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: WinAlert(
                maxChildren == ApiEntitlements.unlimited
                    ? context.l10n.parentAddChildNoCatalog
                    : context.l10n.parentAddChildPlanLimit(maxChildren),
                type: BadgeColor.warn,
              ),
            ),
          if (_success)
            WinAlert(context.l10n.parentAddChildSuccess,
                type: BadgeColor.success)
          else ...[
            Text(
              context.l10n.parentAddChildIntro,
              style: WinType.bodyM(s.onSurface),
            ),
            const SizedBox(height: 24),
            WinTextField(
              label: context.l10n.parentAddChildEmailLabel,
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
              context.l10n.parentAddChildLink,
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
