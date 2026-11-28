import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../shared/downloads/my_downloads_screen.dart';
import '../shared/legal_screen.dart';
import '../shared/pending_actions_screen.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../widgets/account_settings_switches.dart';
import '../widgets/biometric_toggle.dart';
import '../widgets/language_selector.dart';
import 'change_password_screen.dart';
import 'two_factor_settings_screen.dart';

import 'delete_account.dart';
import 'more_screen.dart';

/// Activation de la double authentification proposée dans Paramètres. Faux
/// tant que le site ne demande pas le code à la connexion : un compte activé
/// depuis le téléphone ne pourrait plus se connecter sur le site
/// (frontend-3e prévient quand c'est en production). L'étape du code à la
/// connexion du mobile, elle, est active.
const bool kTwoFactorSetupAvailable = false;

/// Paramètres de l'application, les mêmes pour tous les espaces : langue,
/// mode sombre, déverrouillage par empreinte, notifications et
/// confidentialité du compte, actions en attente d'envoi et pages légales. Ouvert depuis l'onglet « Plus ».
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final state = WinAppScope.of(context);
    return MorePage(
      title: l.settingsTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.translate,
                label: l.language,
                trailing: const LanguageToggle()),
            MoreLine(
                icon: PhosphorIconsRegular.moon,
                label: l.commonDarkMode,
                trailing: Switch(
                    value: state.dark,
                    activeThumbColor: s.primary,
                    onChanged: state.setDark)),
          ]),
          const SizedBox(height: 8),
          const BiometricToggle(),
          const SizedBox(height: 16),
          // Préférences du compte, enregistrées sur le serveur.
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.password,
                label: l.studentProfileChangePwd,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => const ChangePasswordScreen()))),
            // Double authentification pour tous les comptes (serveur 2a006d2),
            // masquée tant que la connexion du site ne demande pas le code.
            if (kTwoFactorSetupAvailable)
            MoreLine(
                icon: PhosphorIconsRegular.shieldCheck,
                label: l.twoFaTitle,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => const TwoFactorSettingsScreen()))),
            MoreLine(
                icon: PhosphorIconsRegular.bell,
                label: l.studentNotifTitle,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => AccountSettingsScreen(
                            kind: AccountSettingsKind.notifications,
                            title: l.studentNotifTitle)))),
            MoreLine(
                icon: PhosphorIconsRegular.lockKey,
                label: l.studentProfileTabPrivacy,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => AccountSettingsScreen(
                            kind: AccountSettingsKind.privacy,
                            title: l.studentProfileTabPrivacy)))),
          ]),
          const SizedBox(height: 16),
          MoreGroup(children: [
            // Hors ligne : place occupée sur le téléphone, puis actions en
            // attente du réseau.
            MoreLine(
                icon: PhosphorIconsRegular.downloadSimple,
                label: l.dlTitle,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(builder: (_) => const MyDownloadsScreen()))),
            MoreLine(
                icon: PhosphorIconsRegular.clockCounterClockwise,
                label: l.pendingTitle,
                onTap: () => Navigator.push(
                    context,
                    WinPageRoute(
                        builder: (_) => const PendingActionsScreen()))),
          ]),
          const SizedBox(height: 16),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.fileText,
                label: l.studentHubTerms,
                onTap: () => LegalScreen.showCgu(context)),
            MoreLine(
                icon: PhosphorIconsRegular.shieldCheck,
                label: l.studentHubPrivacy,
                onTap: () => LegalScreen.showPrivacy(context)),
          ]),
          const SizedBox(height: 16),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.trash,
                label: l.studentProfileDeleteAccount,
                onTap: () => confirmDeleteAccount(context)),
          ]),
        ],
      ),
    );
  }
}
