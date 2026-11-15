import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/add_child_screen.dart';
import 'package:winplus/parent/covered_children_screen.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  group('AddChildScreen', () {
    testWidgets('droit « catalogue enfants » absent : avertissement sur la limite du plan', (tester) async {
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 1});
      await monterEcran(tester, const AddChildScreen(), abonnement: abo);
      expect(find.text(L10n.current.parentAddChildPlanLimit(1)), findsOneWidget);
    });

    testWidgets('plan illimite sans catalogue : message dedie', (tester) async {
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': -1});
      await monterEcran(tester, const AddChildScreen(), abonnement: abo);
      expect(find.text(L10n.current.parentAddChildNoCatalog), findsOneWidget);
    });

    testWidgets('droit « catalogue enfants » present : aucun avertissement', (tester) async {
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 3, 'children.catalog': true});
      await monterEcran(tester, const AddChildScreen(), abonnement: abo);
      expect(find.text(L10n.current.parentAddChildPlanLimit(3)), findsNothing);
      expect(find.text(L10n.current.parentAddChildIntro), findsOneWidget);
    });

    testWidgets('adresse invalide : message et aucun appel', (tester) async {
      await monterEcran(tester, const AddChildScreen());
      await tester.enterText(find.byType(TextField), 'pas-une-adresse');
      await tester.tap(_bouton(L10n.current.parentAddChildLink));
      await reseau(tester);
      expect(find.text(L10n.current.parentAddChildInvalidEmail), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('modifier le champ efface le message d\'erreur', (tester) async {
      await monterEcran(tester, const AddChildScreen());
      await tester.tap(_bouton(L10n.current.parentAddChildLink));
      await reseau(tester);
      expect(find.text(L10n.current.parentAddChildInvalidEmail), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a');
      await pomper(tester);
      expect(find.text(L10n.current.parentAddChildInvalidEmail), findsNothing);
    });

    testWidgets('refus du serveur : son message (limite du plan) est affiche', (tester) async {
      faux.repond('POST', '/parent/children', {'error': 'Limite de 1 enfant atteinte'}, statut: 403);
      await monterEcran(tester, const AddChildScreen());
      await tester.enterText(find.byType(TextField), 'enfant@x.cm');
      await tester.tap(_bouton(L10n.current.parentAddChildLink));
      await reseau(tester);
      expect(find.text('Limite de 1 enfant atteinte'), findsOneWidget);
    });

    testWidgets('refus sans message : « enfant introuvable »', (tester) async {
      faux.repond('POST', '/parent/children', {}, statut: 404);
      await monterEcran(tester, const AddChildScreen());
      await tester.enterText(find.byType(TextField), 'enfant@x.cm');
      await tester.tap(_bouton(L10n.current.parentAddChildLink));
      await reseau(tester);
      expect(find.text(L10n.current.parentAddChildNotFound), findsOneWidget);
    });

    testWidgets('succes : confirmation puis fermeture avec le resultat « vrai »', (tester) async {
      faux.repond('POST', '/parent/children', {});
      Object? resultat;
      await monterEcran(tester, lanceur(const AddChildScreen(), surResultat: (r) => resultat = r));
      await ouvrir(tester);
      await tester.enterText(find.byType(TextField), ' enfant@x.cm ');
      await tester.tap(_bouton(L10n.current.parentAddChildLink));
      await reseau(tester);
      expect(faux.requetes.single.data, {'email': 'enfant@x.cm'});
      expect(find.text(L10n.current.parentAddChildSuccess), findsOneWidget);
      // Fermeture apres 1,8 s, puis animation de retour.
      await pomper(tester, const Duration(milliseconds: 1900));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 600));
      expect(find.byType(AddChildScreen), findsNothing);
      expect(resultat, true);
    });
  });

  group('CoveredChildrenScreen', () {
    Map<String, dynamic> statut({bool choix = true, bool peutChanger = true, int max = 1, String? prochain}) => {
          'max': max,
          'selectionNeeded': choix,
          'canChange': peutChanger,
          'customSelection': false,
          if (prochain != null) 'nextChangeAt': prochain,
          'children': [
            {'studentId': 1, 'name': 'Ada', 'covered': true},
            {'studentId': 2, 'name': 'Bob', 'covered': false},
          ],
        };

    testWidgets('erreur de chargement : message et « Reessayer »', (tester) async {
      faux.repond('GET', '/parent/covered-children', [1]);
      await monterEcran(tester, const CoveredChildrenScreen());
      expect(find.text(L10n.current.parentCoveredLoadError), findsOneWidget);
      faux.repond('GET', '/parent/covered-children', statut(choix: false));
      await tester.tap(_bouton(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text(L10n.current.parentCoveredLoadError), findsNothing);
    });

    testWidgets('aucun choix necessaire : phrase « jusqu\'a N » ou « tous »', (tester) async {
      faux.repond('GET', '/parent/covered-children', statut(choix: false, max: 3));
      await monterEcran(tester, const CoveredChildrenScreen());
      expect(find.text(L10n.current.parentCoveredUpTo(3)), findsOneWidget);
    });

    testWidgets('choix necessaire : enfants, badge « couvert », enregistrement inactif tant que rien ne change', (tester) async {
      faux.repond('GET', '/parent/covered-children', statut());
      await monterEcran(tester, const CoveredChildrenScreen());
      final l = L10n.current;
      expect(find.text(l.parentCoveredSubOne(1, 2)), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text(l.parentCoveredBadge), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.parentCoveredSave)).onTap, isNull);
    });

    testWidgets('avec un seul siege, choisir un autre enfant remplace le precedent puis enregistre', (tester) async {
      faux.repond('GET', '/parent/covered-children', statut());
      faux.repond('PUT', '/parent/covered-children', statut());
      await monterEcran(tester, const CoveredChildrenScreen());
      await tester.tap(find.text('Bob'));
      await pomper(tester);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final enregistrer = _bouton(L10n.current.parentCoveredSave);
      await tester.ensureVisible(enregistrer);
      await pomper(tester);
      expect(tester.widget<WinButton>(enregistrer).onTap, isNotNull);
      await tester.tap(enregistrer);
      await reseau(tester);
      expect(faux.recues('PUT', '/parent/covered-children').single.data, {'studentIds': [2]});
      expect(find.text(L10n.current.parentCoveredSaved), findsOneWidget);
    });

    testWidgets('changement deja fait : liste figee et date du prochain changement', (tester) async {
      faux.repond('GET', '/parent/covered-children', statut(peutChanger: false, prochain: '2026-07-01T12:00:00Z'));
      await monterEcran(tester, const CoveredChildrenScreen());
      await tester.tap(find.text('Bob'));
      await pomper(tester);
      expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'le choix ne bouge pas');
      final attendu = L10n.current.parentCoveredNextChange(WinFormat.date(DateTime.utc(2026, 7, 1, 12).toLocal()));
      expect(find.textContaining(attendu, findRichText: true), findsOneWidget);
    });

    testWidgets('refus du serveur a l\'enregistrement : son message, puis rechargement', (tester) async {
      faux.repond('GET', '/parent/covered-children', statut());
      faux.repond('PUT', '/parent/covered-children', {'error': 'Un changement par periode'}, statut: 409);
      await monterEcran(tester, const CoveredChildrenScreen());
      await tester.tap(find.text('Bob'));
      await pomper(tester);
      final enregistrer = _bouton(L10n.current.parentCoveredSave);
      await tester.ensureVisible(enregistrer);
      await pomper(tester);
      await tester.tap(enregistrer);
      await reseau(tester);
      expect(find.text('Un changement par periode'), findsOneWidget);
      expect(faux.recues('GET', '/parent/covered-children'), hasLength(2));
    });

    test('CoveredChildrenException expose son message', () {
      expect(const CoveredChildrenException('x').message, 'x');
    });
  });
}
