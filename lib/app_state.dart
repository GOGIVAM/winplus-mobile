import 'dart:async';
import 'dart:ui' show Brightness, PlatformDispatcher;
import 'package:flutter/material.dart';
import 'l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models.dart';
import 'services/session_manager.dart';
import 'services/user_service.dart';

/// Clé de la langue choisie sur l'appareil (conservée à la déconnexion).
const kLocalePrefKey = 'winplus_locale';

/// Clé du thème choisi sur l'appareil (« dark » ou « light » ; absente :
/// l'application suit le réglage du téléphone).
const kThemePrefKey = 'winplus_theme';

/// WINPLUS  État global léger (thème + rôle actif + langue).
/// Pour une app de production, remplacer par Riverpod / Provider / Bloc.
class WinAppState extends ChangeNotifier {
  /// Choix fait dans l'application ; `null` : suivre le réglage du téléphone.
  bool? _darkChoice;
  WinRole _role = WinRole.student;
  Locale _locale = const Locale('fr');

  /// Mode sombre : le choix fait dans l'application, sinon celui du téléphone.
  bool get dark =>
      _darkChoice ??
      PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  /// Vrai tant qu'aucun choix n'a été fait dans l'application.
  bool get followsSystemTheme => _darkChoice == null;
  WinRole get role => _role;
  Locale get locale => _locale;

  void toggleTheme() => setDark(!dark);

  void setDark(bool v) {
    _darkChoice = v;
    notifyListeners();
    unawaited(_saveTheme());
  }

  /// Revenir au réglage du téléphone.
  void followSystemTheme() {
    _darkChoice = null;
    notifyListeners();
    unawaited(_saveTheme());
  }

  /// Le téléphone vient de changer de mode clair ou sombre.
  void systemThemeChanged() {
    if (_darkChoice == null) notifyListeners();
  }

  /// Thème au démarrage : le choix enregistré sur l'appareil, sinon le
  /// réglage du téléphone.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kThemePrefKey);
    if (saved == 'dark' || saved == 'light') {
      _darkChoice = saved == 'dark';
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_darkChoice == null) {
        await prefs.remove(kThemePrefKey);
      } else {
        await prefs.setString(kThemePrefKey, _darkChoice! ? 'dark' : 'light');
      }
    } catch (_) {
      // Le choix reste valable pour la session en cours.
    }
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
