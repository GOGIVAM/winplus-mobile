import 'package:flutter/material.dart';

/// Durées et courbes d'animation communes à toute l'app, pour que chaque
/// transition (page, tap, apparition de liste) obéisse au même rythme au
/// lieu de valeurs ad hoc dispersées dans chaque écran.
class WinDurations {
  WinDurations._();
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 350);
  static const page = Duration(milliseconds: 300);
  static const stagger = Duration(milliseconds: 40);
}

class WinCurves {
  WinCurves._();
  static const standard = Curves.easeOutCubic;
  static const enter = Curves.easeOutQuart;
  static const exit = Curves.easeInCubic;
  static const tap = Curves.easeOut;
}

/// Transition de page commune (fondu + léger glissement vertical) à utiliser
/// partout à la place de [MaterialPageRoute], pour une navigation cohérente
/// dans toute l'app plutôt que le slide-from-right par défaut de Material.
class WinPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  WinPageRoute({required this.builder, super.settings})
      : super(
          transitionDuration: WinDurations.page,
          reverseTransitionDuration: WinDurations.page,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: WinCurves.enter);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
