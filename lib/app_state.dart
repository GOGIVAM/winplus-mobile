import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models.dart';
import 'services/session_manager.dart';
import 'services/user_service.dart';

const _kLocaleKey = 'winplus_locale';

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

  /// Restaure la langue choisie précédemment (appelé une fois au démarrage).
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code != null && (code == 'fr' || code == 'en')) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Change la langue de l'app, la persiste localement (SharedPreferences)
  /// et, si l'utilisateur est connecté, la synchronise sur son profil
  /// (User.Locale) afin qu'elle pilote aussi les emails transactionnels et
  /// suive l'utilisateur d'un appareil à l'autre.
  Future<void> setLocale(String code) async {
    if (code != 'fr' && code != 'en') return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, code);
    if (await SessionManager.isLoggedIn()) {
      unawaited(UserService.instance.updateProfile(locale: code));
    }
  }
}

/// Fournit l'état à tout l'arbre via InheritedNotifier.
class WinAppScope extends InheritedNotifier<WinAppState> {
  const WinAppScope(
      {super.key, required WinAppState super.notifier, required super.child});
  static WinAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WinAppScope>()!.notifier!;
}
