import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shell/change_password_screen.dart';
import 'package:winplus/shell/settings_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Changement du mot de passe depuis « Parametres », pour tous les comptes.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'institution'}));

  Finder bouton() => find.widgetWithText(WinButton, L10n.current.studentProfileChangePwd);

  Future<void> saisir(WidgetTester tester, String actuel, String nouveau, String confirmation) async {
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), actuel);
    await tester.enterText(champs.at(1), nouveau);
    await tester.enterText(champs.at(2), confirmation);
    await pomper(tester);
    await tester.tap(bouton());
    await reseau(tester);
  }

  testWidgets('Parametres : la ligne « Changer le mot de passe » ouvre l\'ecran', (tester) async {
    await monterEcran(tester, const SettingsScreen());
    final ligne = find.text(L10n.current.studentProfileChangePwd);
    await tester.scrollUntilVisible(ligne, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(ligne);
    await reseau(tester);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('champs vides, mot de passe trop court, confirmation differente : rien ne part', (tester) async {
    await monterEcran(tester, const ChangePasswordScreen());
    final l = L10n.current;
    await tester.tap(bouton());
    await pomper(tester);
    expect(find.widgetWithText(WinAlert, l.fillAllFields), findsOneWidget);
    await saisir(tester, 'ancien', 'court', 'court');
    expect(find.widgetWithText(WinAlert, l.authRule8), findsOneWidget);
    await saisir(tester, 'ancien', 'nouveau-mot', 'autre-mot-1');
    expect(find.widgetWithText(WinAlert, l.studentProfilePwdMismatch), findsOneWidget);
    expect(faux.recues('POST', '/auth/change-password'), isEmpty);
  });

  testWidgets('envoi : mot de passe actuel et nouveau, message puis retour', (tester) async {
    faux.repond('POST', '/auth/change-password', {'success': true});
    // Ouvert depuis Parametres : l'ecran se referme sur lui apres le succes.
    await monterEcran(tester, const SettingsScreen());
    final ligne = find.text(L10n.current.studentProfileChangePwd);
    await tester.scrollUntilVisible(ligne, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(ligne);
    await reseau(tester);
    await saisir(tester, 'ancien', 'nouveau-mot', 'nouveau-mot');
    expect(faux.recues('POST', '/auth/change-password').single.data, {'currentPassword': 'ancien', 'newPassword': 'nouveau-mot'});
    expect(find.text(L10n.current.studentProfilePwdChanged), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });

  testWidgets('refus du serveur : « mot de passe actuel incorrect », la saisie reste', (tester) async {
    faux.repond('POST', '/auth/change-password', {'error': 'x'}, statut: 400);
    await monterEcran(tester, const ChangePasswordScreen());
    await saisir(tester, 'faux', 'nouveau-mot', 'nouveau-mot');
    expect(find.widgetWithText(WinAlert, L10n.current.studentProfilePwdWrong), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });
}
