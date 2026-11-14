import 'package:flutter/widgets.dart';

/// Donne aux onglets de la coquille ([RoleShell]) le moyen d'ouvrir un autre
/// onglet de la barre du bas : l'accueil s'en sert pour ses raccourcis
/// (catalogue, messages, revenus…) sans dupliquer ces écrans.
class ShellNav extends InheritedWidget {
  final ValueChanged<int> goTab;
  const ShellNav({super.key, required this.goTab, required super.child});

  /// Ouvre l'onglet [index] de la barre du bas ; sans coquille, ne fait rien.
  static void go(BuildContext context, int index) =>
      context.getInheritedWidgetOfExactType<ShellNav>()?.goTab(index);

  @override
  bool updateShouldNotify(ShellNav oldWidget) => false;
}
