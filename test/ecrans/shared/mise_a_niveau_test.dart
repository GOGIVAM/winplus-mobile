import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/subscription/upgrade_sheet.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Widget _ouvreur() => Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => UpgradeSheet.show(c, featureName: 'Exam Coach', requiredPlan: 'Premium'),
            child: const Text('mise a niveau'),
          ),
        ),
      ),
    );

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('UpgradeSheet', () {
    testWidgets('texte de la fonctionnalite et du plan requis, actions « voir » et « plus tard »', (tester) async {
      faux.repond('GET', '/pricing/catalog', {'data': {'student': []}});
      await monterEcran(tester, _ouvreur());
      await tester.tap(find.text('mise a niveau'));
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.subFeatureOfPlan('Premium')), findsOneWidget);
      expect(find.text(l.subFeatureAvailableFrom('Exam Coach', 'Premium')), findsOneWidget);
      expect(find.widgetWithText(WinButton, l.subSeePlans), findsOneWidget);
      expect(find.widgetWithText(WinButton, l.subLater), findsOneWidget);
    });

    testWidgets('« Plus tard » ferme la feuille', (tester) async {
      faux.repond('GET', '/pricing/catalog', {'data': {'student': []}});
      await monterEcran(tester, _ouvreur());
      await tester.tap(find.text('mise a niveau'));
      await reseau(tester);
      await tester.tap(find.widgetWithText(WinButton, L10n.current.subLater));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(find.byType(UpgradeSheet), findsNothing);
    });

    testWidgets('prix minimal mensuel lu dans la grille de l\'audience, plan gratuit ignore', (tester) async {
      faux.repond('GET', '/pricing/catalog', {
        'data': {
          'student': [
            {'planId': 1, 'name': 'Gratuit', 'isFree': true, 'prices': [{'period': 'monthly', 'priceTtc': 0}]},
            {'planId': 2, 'name': 'Premium', 'prices': [{'period': 'monthly', 'priceTtc': 3000}]},
            {'planId': 3, 'name': 'Max', 'prices': [{'period': 'monthly', 'priceTtc': 5000}]},
          ],
        },
      });
      await monterEcran(tester, _ouvreur());
      await tester.tap(find.text('mise a niveau'));
      await reseau(tester);
      expect(faux.recues('GET', '/pricing/catalog').single.queryParameters, {'audience': 'student'});
      expect(find.text(L10n.current.subFromPerMonth(fmtXaf(3000))), findsOneWidget);
    });

    testWidgets('compte etablissement : la grille n\'est pas interrogee', (tester) async {
      final etat = WinAppState()..setRole(WinRole.institution);
      await monterEcran(tester, _ouvreur(), etat: etat);
      await tester.tap(find.text('mise a niveau'));
      await reseau(tester);
      expect(faux.recues('GET', '/pricing/catalog'), isEmpty);
    });

    testWidgets('audience parent : la grille parent est demandee', (tester) async {
      faux.repond('GET', '/pricing/catalog', {'data': {'parent': []}});
      final etat = WinAppState()..setRole(WinRole.parent);
      await monterEcran(tester, _ouvreur(), etat: etat);
      await tester.tap(find.text('mise a niveau'));
      await reseau(tester);
      expect(faux.recues('GET', '/pricing/catalog').single.queryParameters, {'audience': 'parent'});
    });
  });
}
