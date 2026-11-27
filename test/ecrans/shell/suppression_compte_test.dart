import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shell/settings_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Suppression du compte depuis « Parametres », pour tous les comptes.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'parent'}));

  Future<void> ouvrir(WidgetTester tester) async {
    await monterEcran(tester, const SettingsScreen());
    final ligne = find.text(L10n.current.studentProfileDeleteAccount);
    await tester.scrollUntilVisible(ligne, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(ligne);
    await pomper(tester);
  }

  testWidgets('annuler : rien ne part, le compte reste ouvert', (tester) async {
    await ouvrir(tester);
    final l = L10n.current;
    expect(find.text(l.settingsDeleteBody), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, l.commonCancel));
    await reseau(tester);
    expect(faux.recues('DELETE', '/users/me'), isEmpty);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('confirmer : le compte est supprime puis l\'ecran de connexion s\'affiche', (tester) async {
    faux.repond('DELETE', '/users/me', {'success': true});
    await ouvrir(tester);
    await tester.tap(find.widgetWithText(TextButton, L10n.current.commonDelete));
    await reseau(tester);
    expect(faux.recues('DELETE', '/users/me'), hasLength(1));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('refus du serveur (titulaire du portefeuille) : son message s\'affiche, le compte reste ouvert', (tester) async {
    faux.repond('DELETE', '/users/me', {'success': false, 'code': 'wallet_holder', 'error': 'Transferez d\'abord le portefeuille.'}, statut: 409);
    await ouvrir(tester);
    await tester.tap(find.widgetWithText(TextButton, L10n.current.commonDelete));
    await reseau(tester);
    expect(find.text('Transferez d\'abord le portefeuille.'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
