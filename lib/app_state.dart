import 'package:flutter/material.dart';
import 'data/models.dart';

/// WINPLUS  État global léger (thème + rôle actif).
/// Pour une app de production, remplacer par Riverpod / Provider / Bloc.
class WinAppState extends ChangeNotifier {
  bool _dark = false;
  WinRole _role = WinRole.student;

  bool get dark => _dark;
  WinRole get role => _role;

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
}

/// Fournit l'état à tout l'arbre via InheritedNotifier.
class WinAppScope extends InheritedNotifier<WinAppState> {
  const WinAppScope(
      {super.key, required WinAppState super.notifier, required super.child});
  static WinAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WinAppScope>()!.notifier!;
}
