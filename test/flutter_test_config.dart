import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Chargé automatiquement par `flutter test` avant chaque fichier de test.
///
/// Les tests d'écran (testWidgets) ont par défaut une limite de 10 minutes,
/// que l'option --timeout ne remplace pas : un écran qui attend un appel
/// réseau jamais simulé bloquait toute la suite. Une minute suffit
/// largement à n'importe quel test de ce projet.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is AutomatedTestWidgetsFlutterBinding) {
    binding.defaultTestTimeout = const Timeout(Duration(seconds: 60));
  }
  await testMain();
}
