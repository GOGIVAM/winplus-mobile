import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auth/login_screen.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme/win_motion.dart';

/// Déconnexion après confirmation, la même pour tous les comptes (l'élève
/// seul avait une confirmation). Le dialogue se ferme par son propre
/// contexte : celui de l'écran fermerait l'écran dans la coque.
Future<void> confirmSignOut(BuildContext context) async {
  final l = context.l10n;
  final student = WinAppScope.of(context).role == WinRole.student;
  final navigator = Navigator.of(context, rootNavigator: true);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.studentHubLogoutTitle),
      // Tu pour l'élève, vous pour les autres comptes.
      content: Text(student ? l.studentHubLogoutBody : l.signOutBodyFormal),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.studentHubLogoutConfirm)),
      ],
    ),
  );
  if (ok != true) return;
  await AuthService.instance.signOut();
  navigator.pushAndRemoveUntil(
    WinPageRoute(builder: (_) => const LoginScreen()),
    (r) => false,
  );
}
