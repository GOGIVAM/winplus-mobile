import 'package:flutter/material.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/theme/win_theme.dart';

/// Enveloppe minimale pour monter un widget de l'application : etat global
/// (langue, theme), schema de couleurs WinPlus, traductions et un Scaffold.
/// Le widget est centre : il prend sa taille naturelle.
Widget appli(Widget enfant, {WinAppState? etat, WinScheme schema = WinScheme.light}) {
  return WinAppScope(
    notifier: etat ?? WinAppState(),
    child: WinTheme(
      scheme: schema,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: Center(child: enfant)),
      ),
    ),
  );
}
