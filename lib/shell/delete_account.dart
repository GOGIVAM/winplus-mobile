import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';

/// Suppression du compte, depuis « Paramètres », pour tous les comptes (le
/// profil de l'élève la proposait seul). Confirmation, suppression sur le
/// serveur, puis retour à l'écran de connexion. Un refus du serveur
/// (titulaire du portefeuille d'un établissement, par exemple) s'affiche
/// tel quel et le compte reste ouvert.
Future<void> confirmDeleteAccount(BuildContext context) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final ok = await showDialog<bool>(
    context: context,
    // Le dialogue se ferme par son propre contexte.
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WinRadii.xl)),
      title: Text(l.studentProfileDeleteTitle),
      content: Text(l.settingsDeleteBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonDelete)),
      ],
    ),
  );
  if (ok != true) return;
  final error = await UserService.instance.deleteAccount();
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(l.settingsDeleted)));
  await AuthService.instance.signOut();
  navigator.pushAndRemoveUntil(
    WinPageRoute(builder: (_) => const LoginScreen()),
    (r) => false,
  );
}
