import 'dart:async';
import 'package:flutter/material.dart';
import 'l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models.dart';
import 'services/session_manager.dart';
import 'services/user_service.dart';

/// Clé de la langue choisie sur l'appareil (conservée à la déconnexion).
const kLocalePrefKey = 'winplus_locale';

/// WINPLUS  État global léger (thème + rôle actif + langue).
/// Pour une app de production, remplacer par Riverpod / Provider / Bloc.
class WinAppState extends ChangeNotifier {
  bool _dark = false;
  WinRole _role = WinRole.student;
  Locale _locale = const Locale('fr');

  bool get dark => _dark;
  WinRole get role => _role;
  Locale get locale => _locale;

  void toggleTheme() {
    _dark = !_dark;
    notifyListeners();
  }

  void setDark(bool v) {
    _dark = v;
    notifyListeners();
  }

  void setRole(WinRole r) {
    _role = r;
    notifyListeners();
  }

  /// Lot 10.11 : langue au démarrage. Choix enregistré sur l'appareil,
  /// sinon langue du téléphone (anglais si le téléphone est en anglais,
  /// français sinon). Une fois connecté, [applyAccountLocale] aligne
  /// l'application sur User.Locale.
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocalePrefKey);
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _apply(
        code == 'fr' || code == 'en' ? code! : (device == 'en' ? 'en' : 'fr'));
  }

  /// Applique la langue du compte (User.Locale) après connexion ou au
  /// démarrage d'une session existante. Si le compte n'a pas encore de
  /// langue, on lui enregistre celle de l'application.
  Future<void> applyAccountLocale(String? accountLocale) async {
    if (accountLocale == 'fr' || accountLocale == 'en') {
      _apply(accountLocale!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocalePrefKey, accountLocale);
    } else {
      unawaited(
          UserService.instance.updateProfile(locale: _locale.languageCode));
    }
  }

  /// Change la langue de l'app, la persiste localement (SharedPreferences)
  /// et, si l'utilisateur est connecté, la synchronise sur son profil
  /// (User.Locale) afin qu'elle pilote aussi les emails transactionnels,
  /// les notifications et WinAI, et suive l'utilisateur d'un appareil à
  /// l'autre.
  Future<void> setLocale(String code) async {
    if (code != 'fr' && code != 'en') return;
    _apply(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocalePrefKey, code);
    if (await SessionManager.isLoggedIn()) {
      unawaited(UserService.instance.updateProfile(locale: code));
    }
  }

  void _apply(String code) {
    _locale = Locale(code);
    L10n.locale = _locale;
    notifyListeners();
  }
}

/// Fournit l'état à tout l'arbre via InheritedNotifier.
class WinAppScope extends InheritedNotifier<WinAppState> {
  const WinAppScope(
      {super.key, required WinAppState super.notifier, required super.child});
  static WinAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WinAppScope>()!.notifier!;
}
