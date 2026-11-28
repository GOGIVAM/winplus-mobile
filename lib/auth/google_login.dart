import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../shell/role_shell.dart';
import '../theme/win_motion.dart';
import 'role_screen.dart';
import 'two_factor_login_screen.dart';

/// Connexion avec Google sur mobile (lot 2).
///
/// Le téléphone affiche le choix du compte Google, puis envoie le jeton
/// d'identité obtenu à POST /auth/google, la même route que le site. Le jeton
/// est émis pour l'identifiant client « Web » du site (serverClientId), lu sur
/// le serveur : c'est lui que le serveur vérifie. L'identifiant « Android »
/// (nom du paquet et empreinte de la clé de signature) est déclaré dans la
/// console Google Cloud et n'apparaît pas dans le code.
class GoogleLogin {
  GoogleLogin._();

  static String? _initialisePour;

  /// Lance la connexion. Gère seul la suite : espace du compte, choix du
  /// profil pour un nouveau compte, ou message d'erreur.
  static Future<void> start(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final clientId = await AuthService.instance.googleClientId();
    if (clientId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleUnavailable)));
      return;
    }

    String? idToken;
    try {
      if (_initialisePour != clientId) {
        await GoogleSignIn.instance.initialize(serverClientId: clientId);
        _initialisePour = clientId;
      }
      // Toujours proposer le choix du compte (plusieurs comptes sur le téléphone).
      await GoogleSignIn.instance.signOut();
      final compte = await GoogleSignIn.instance.authenticate();
      idToken = compte.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleFailed)));
      return;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleFailed)));
      return;
    }
    if (idToken == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleFailed)));
      return;
    }

    final res = await AuthService.instance.googleSignIn(idToken);
    if (!context.mounted) return;
    if (res.needsRole) {
      // Compte Google inconnu : choisir son profil, puis créer le compte.
      Navigator.push(context,
          WinPageRoute(builder: (_) => RoleScreen(googleIdToken: res.idToken)));
      return;
    }
    if (res.twoFactorToken != null) {
      // Double authentification active : le code avant la session.
      final retour = await Navigator.push<String>(context,
          WinPageRoute(builder: (_) => TwoFactorLoginScreen(twoFactorToken: res.twoFactorToken!)));
      if (retour != null) messenger.showSnackBar(SnackBar(content: Text(retour)));
      return;
    }
    if (!res.success) {
      messenger.showSnackBar(
          SnackBar(content: Text(res.message ?? l10n.authGoogleFailed)));
      return;
    }
    await openAccountSpace(context, res.locale);
  }

  /// Fin de connexion commune : rôle, langue du compte, abonnement, puis
  /// l'espace du compte à la place de tous les écrans d'authentification.
  static Future<void> openAccountSpace(BuildContext context, String? locale) async {
    final roleStr = await SessionManager.getUserRole();
    if (!context.mounted) return;
    final appState = WinAppScope.of(context);
    appState.setRole(winRoleFromString(roleStr));
    unawaited(appState.applyAccountLocale(locale));
    SubscriptionScope.of(context).loadFromApi();
    Navigator.pushAndRemoveUntil(context,
        WinPageRoute(builder: (_) => const RoleShell()), (r) => false);
  }
}
