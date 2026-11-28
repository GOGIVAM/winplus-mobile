import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shell/settings_screen.dart' show kTwoFactorSetupAvailable;
import 'package:winplus/shell/two_factor_reminder.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Widget _page() => const Scaffold(body: Column(children: [TwoFactorReminderCard()]));

/// Rappel de la double authentification (decision de Georges du 28/11) :
/// facultative, jamais pour un compte protege, « Plus tard » = 30 jours.
void main() {
  late FauxReseau faux;

  testWidgets('compte non protege : carte avec Activer et Plus tard ; Plus tard la retire pour 30 jours', (tester) async {
    faux = preparerEnvironnement();
    faux.repond('GET', '/users/2fa/status', {'isEnabled': false});
    await monterEcran(tester, _page());
    final l = L10n.current;
    if (!kTwoFactorSetupAvailable) {
      expect(find.text(l.twoFaReminderTitle), findsNothing);
      return;
    }
    expect(find.text(l.twoFaReminderTitle), findsOneWidget);
    expect(_bouton(l.twoFaEnable), findsOneWidget);
    await tester.tap(_bouton(l.twoFaReminderLater));
    await reseau(tester);
    expect(find.text(l.twoFaReminderTitle), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    final jusqua = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(TwoFactorReminderCard.prefKey)!);
    expect(jusqua.difference(DateTime.now()).inDays, inInclusiveRange(29, 30));
  });

  testWidgets('compte deja protege : aucune carte', (tester) async {
    faux = preparerEnvironnement();
    faux.repond('GET', '/users/2fa/status', {'isEnabled': true});
    await monterEcran(tester, _page());
    expect(find.text(L10n.current.twoFaReminderTitle), findsNothing);
  });

  testWidgets('Plus tard encore en cours : ni carte ni appel au serveur', (tester) async {
    faux = preparerEnvironnement(prefs: {
      TwoFactorReminderCard.prefKey: DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch,
    });
    faux.repond('GET', '/users/2fa/status', {'isEnabled': false});
    await monterEcran(tester, _page());
    expect(find.text(L10n.current.twoFaReminderTitle), findsNothing);
    expect(faux.recues('GET', '/users/2fa/status'), isEmpty);
  });

  testWidgets('serveur en panne : aucune carte', (tester) async {
    faux = preparerEnvironnement();
    faux.repond('GET', '/users/2fa/status', {}, statut: 500);
    await monterEcran(tester, _page());
    expect(find.text(L10n.current.twoFaReminderTitle), findsNothing);
  });
}
