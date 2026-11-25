import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_profile_service.dart';
import 'package:winplus/teacher/tutor_group_pricing_editor.dart';
import 'package:winplus/teacher/tutor_pricing_grid_editor.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);
Finder _puce(String libelle) => find.widgetWithText(WinChip, libelle);

/// Ecran tres haut : les editeurs sont construits en entier, sans defilement.
Future<void> monterHaut(WidgetTester tester, Widget enfant) async {
  telephone(tester);
  tester.view.physicalSize = const Size(800, 3000);
  await monter(tester, ecran(enfant));
  await reseau(tester);
}

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  // ── Prix de groupe ────────────────────────────────────────────────────

  group('GroupPricingValue', () {
    test('profil individuel : methode « none », 4 eleves et 150 % par defaut', () {
      final v = GroupPricingValue.fromProfile(TutorProfile.fromJson({'id': 1, 'userId': 1}));
      expect(v.method, 'none');
      expect(v.maxGroupSize, 4);
      expect(v.flatPercent, 150);
      expect(v.discounts, isEmpty);
    });

    test('profil de groupe : reprend la methode, la taille et les paliers', () {
      final v = GroupPricingValue.fromProfile(TutorProfile.fromJson({
        'id': 1,
        'userId': 1,
        'groupPricingMethod': 'per_student',
        'maxGroupSize': 6,
        'groupDiscounts': [
          {'minGroupSize': 3, 'percentDiscount': 20},
        ],
      }));
      expect(v.method, 'per_student');
      expect(v.maxGroupSize, 6);
      expect(v.discounts.single.percentDiscount, 20);
    });

    test('charge utile : individuel = methode seule et aucun palier', () {
      expect(const GroupPricingValue().toPayload(), {
        'updateGroupPricing': true,
        'groupPricingMethod': 'none',
        'groupDiscounts': [],
      });
    });

    test('charge utile : prix fixe = taille et pourcentage, sans paliers', () {
      const v = GroupPricingValue(method: 'flat', maxGroupSize: 5, flatPercent: 180, discounts: [TutorGroupDiscount(minGroupSize: 3, percentDiscount: 20)]);
      expect(v.toPayload(), {
        'updateGroupPricing': true,
        'groupPricingMethod': 'flat',
        'maxGroupSize': 5,
        'groupFlatPricePercent': 180,
        'groupDiscounts': [],
      });
    });

    test('charge utile : prix par eleve = taille et paliers, sans pourcentage fixe', () {
      const v = GroupPricingValue(method: 'per_student', maxGroupSize: 5, discounts: [TutorGroupDiscount(minGroupSize: 3, percentDiscount: 20)]);
      final p = v.toPayload();
      expect(p.containsKey('groupFlatPricePercent'), isFalse);
      expect(p['maxGroupSize'], 5);
      expect(p['groupDiscounts'], [
        {'minGroupSize': 3, 'percentDiscount': 20},
      ]);
    });
  });

  group('TutorGroupPricingEditor', () {
    late GroupPricingValue valeur;

    Future<void> monterEditeur(WidgetTester tester, {GroupPricingValue depart = const GroupPricingValue(), String? matiere = 'Mathématiques'}) async {
      valeur = depart;
      await monterHaut(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (c, set) => TutorGroupPricingEditor(
                value: valeur,
                subject: matiere,
                level: 'Terminale',
                onChanged: (v) => set(() => valeur = v),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('individuel : trois methodes, aucune reglage de taille', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      expect(find.text(l.teacherGroupTitle), findsOneWidget);
      expect(tester.widget<WinChip>(_puce(l.teacherGroupMethodNone)).active, isTrue);
      expect(_puce(l.teacherGroupMethodPerStudent), findsOneWidget);
      expect(_puce(l.teacherGroupMethodFlat), findsOneWidget);
      expect(find.text(l.teacherGroupMaxSizeLabel), findsNothing);
    });

    testWidgets('prix par eleve : taille maximale, ajout et suppression de paliers', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(_puce(l.teacherGroupMethodPerStudent));
      await pomper(tester);
      expect(valeur.method, 'per_student');
      expect(find.text(l.teacherGroupMaxSizeLabel), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // Premier palier : des 2 eleves, 10 %.
      await tester.tap(find.text(l.teacherPricingAddTier));
      await pomper(tester);
      expect(valeur.discounts.map((d) => (d.minGroupSize, d.percentDiscount)), [(2, 10)]);
      // Deuxieme palier : des 3 eleves, 15 %.
      await tester.tap(find.text(l.teacherPricingAddTier));
      await pomper(tester);
      expect(valeur.discounts.map((d) => (d.minGroupSize, d.percentDiscount)), [(2, 10), (3, 15)]);
      // Pourcentage du premier palier : pas de 5.
      await tester.tap(find.byIcon(PhosphorIconsRegular.plusCircle).at(1));
      await pomper(tester);
      expect(valeur.discounts.first.percentDiscount, 15);
      // Suppression du premier palier.
      await tester.tap(find.byTooltip(l.teacherPricingRemoveTier).first);
      await pomper(tester);
      expect(valeur.discounts.map((d) => d.minGroupSize), [3]);
    });

    testWidgets('cinq paliers au plus : le bouton d\'ajout disparait', (tester) async {
      await monterEditeur(
        tester,
        depart: GroupPricingValue(
          method: 'per_student',
          maxGroupSize: 8,
          discounts: [for (var i = 0; i < 5; i++) TutorGroupDiscount(minGroupSize: 2 + i, percentDiscount: 10)],
        ),
      );
      expect(find.text(L10n.current.teacherPricingAddTier), findsNothing);
    });

    testWidgets('taille maximale : bornee entre 2 et 20 eleves', (tester) async {
      await monterEditeur(tester, depart: const GroupPricingValue(method: 'flat', maxGroupSize: 2));
      IconButton bouton(Finder icone) => tester.widget<IconButton>(find.ancestor(of: icone, matching: find.byType(IconButton)));
      // Premiere ligne = taille maximale.
      expect(bouton(find.byIcon(PhosphorIconsRegular.minusCircle).first).onPressed, isNull);
      await tester.tap(find.byIcon(PhosphorIconsRegular.plusCircle).first);
      await pomper(tester);
      expect(valeur.maxGroupSize, 3);
    });

    testWidgets('prix fixe : pourcentage par pas de 10, minimum 100 %', (tester) async {
      await monterEditeur(tester, depart: const GroupPricingValue(method: 'flat', flatPercent: 110));
      IconButton bouton(Finder icone) => tester.widget<IconButton>(find.ancestor(of: icone, matching: find.byType(IconButton)));
      final moins = find.byIcon(PhosphorIconsRegular.minusCircle).at(1);
      await tester.tap(moins);
      await pomper(tester);
      expect(valeur.flatPercent, 100);
      expect(bouton(find.byIcon(PhosphorIconsRegular.minusCircle).at(1)).onPressed, isNull);
      expect(find.text(L10n.current.teacherGroupFlatExample), findsOneWidget);
    });

    testWidgets('suggestion sans matiere : message, aucun appel', (tester) async {
      await monterEditeur(tester, matiere: null);
      await tester.tap(find.text(L10n.current.teacherGroupSuggest));
      await pomper(tester);
      expect(find.text(L10n.current.teacherGroupSubjectsFirst), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('suggestion WinAI : reglages proposes, appliquer « prix par eleve » les reprend', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {
        'group': {
          'max_group_size': 5,
          'discounts': [
            {'min_group_size': 3, 'percent_discount': 25},
          ],
          'flat_price_percent': 170,
          'based_on': 'market_data',
          'sample_size': 12,
          'explanation': 'Selon le marche',
        },
      });
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(find.text(l.teacherGroupSuggest));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-profile/me/suggest-rate').single.data as Map;
      expect(envoi, {'subject': 'Mathématiques', 'level': 'Terminale', 'include_group': true});
      expect(find.text('${l.teacherGroupSuggested} ${l.teacherGroupBasedOn(12)}'), findsOneWidget);
      expect(find.text(l.teacherGroupMaxSizeLine(5)), findsOneWidget);
      expect(find.text(l.teacherGroupPerStudentLine(3, 25)), findsOneWidget);
      expect(find.text(l.teacherGroupFlatLine(170)), findsOneWidget);
      expect(find.text('Selon le marche'), findsOneWidget);
      await tester.tap(_bouton(l.teacherGroupApplyPerStudent));
      await pomper(tester);
      expect(valeur.method, 'per_student');
      expect(valeur.maxGroupSize, 5);
      expect(valeur.flatPercent, 170);
      expect(valeur.discounts.single.percentDiscount, 25);
      expect(find.text('Selon le marche'), findsNothing);
    });

    testWidgets('suggestion : « Prix fixe » applique la methode fixe, « Ignorer » ferme la carte', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {
        'group': {'max_group_size': 3, 'discounts': [], 'flat_price_percent': 160, 'explanation': 'Estimation'},
      });
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(find.text(l.teacherGroupSuggest));
      await reseau(tester);
      expect(find.text('${l.teacherGroupSuggested} ${l.teacherGroupEstimate}'), findsOneWidget);
      await tester.tap(_bouton(l.teacherPricingIgnore));
      await pomper(tester);
      expect(find.text(l.teacherGroupSuggested), findsNothing);
      expect(valeur.method, 'none');
      await tester.tap(find.text(l.teacherGroupSuggest));
      await reseau(tester);
      await tester.tap(_bouton(l.teacherGroupApplyFlat));
      await pomper(tester);
      expect(valeur.method, 'flat');
      expect(valeur.flatPercent, 160);
    });

    testWidgets('suggestion indisponible (reponse sans reglages ou erreur) : message', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {});
      await monterEditeur(tester);
      await tester.tap(find.text(L10n.current.teacherGroupSuggest));
      await reseau(tester);
      expect(find.text(L10n.current.teacherGroupSuggestError), findsOneWidget);
    });

    testWidgets('suggestion en erreur serveur : meme message', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {}, statut: 500);
      await monterEditeur(tester);
      await tester.tap(find.text(L10n.current.teacherGroupSuggest));
      await reseau(tester);
      expect(find.text(L10n.current.teacherGroupSuggestError), findsOneWidget);
    });
  });

  // ── Grille tarifaire ──────────────────────────────────────────────────

  group('TutorPricingGrid', () {
    test('charge utile : tarifs, modulations et paliers de duree', () {
      const g = TutorPricingGrid(
        rates: [TutorRate(subject: 'Maths', mode: 'online', hourlyRateXaf: 900)],
        modifiers: [TutorRateModifier(label: 'Soir', daysOfWeek: [1, 2], startTime: '18:00', endTime: '21:00', percentAdjustment: 10)],
        discounts: [TutorDurationDiscount(minDurationMinutes: 120, percentDiscount: 5)],
      );
      expect(g.toPayload(), {
        'rates': [
          {'subject': 'Maths', 'mode': 'online', 'hourlyRateXaf': 900},
        ],
        'rateModifiers': [
          {'label': 'Soir', 'daysOfWeek': [1, 2], 'startTime': '18:00', 'endTime': '21:00', 'percentAdjustment': 10},
        ],
        'durationDiscounts': [
          {'minDurationMinutes': 120, 'percentDiscount': 5},
        ],
      });
    });

    test('grille vide : trois listes vides', () {
      expect(const TutorPricingGrid().toPayload(), {'rates': [], 'rateModifiers': [], 'durationDiscounts': []});
    });
  });

  group('TutorPricingGridEditor', () {
    late TutorPricingGrid grille;

    Future<void> monterEditeur(
      WidgetTester tester, {
      TutorPricingGrid depart = const TutorPricingGrid(),
      List<String> matieres = const ['Mathématiques', 'Physique'],
      bool enLigne = true,
      bool presentiel = false,
    }) async {
      grille = depart;
      await monterHaut(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (c, set) => TutorPricingGridEditor(
                value: grille,
                subjects: matieres,
                offersOnline: enLigne,
                offersInPerson: presentiel,
                level: 'Terminale',
                onChanged: (g) => set(() => grille = g),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('grille vide : titres des trois blocs et boutons d\'ajout', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      expect(find.text(l.teacherPricingGridTitle), findsOneWidget);
      expect(find.text(l.teacherPricingBaseTitle), findsOneWidget);
      expect(find.text(l.teacherPricingModTitle), findsOneWidget);
      expect(find.text(l.teacherPricingDurTitle), findsOneWidget);
      expect(_bouton(l.teacherPricingAddRate), findsOneWidget);
      expect(_bouton(l.teacherPricingAddMod), findsOneWidget);
      expect(_bouton(l.teacherPricingAddTierPlus), findsOneWidget);
    });

    testWidgets('ajouter un tarif : matiere et mode par defaut, montant saisi, suppression', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherPricingAddRate));
      await pomper(tester);
      expect(grille.rates.single.subject, 'Mathématiques');
      expect(grille.rates.single.mode, 'online');
      expect(grille.rates.single.hourlyRateXaf, 0);
      await tester.enterText(find.widgetWithText(TextFormField, 'XAF/h'), '900');
      await pomper(tester);
      expect(grille.rates.single.hourlyRateXaf, 900);
      await tester.tap(find.byTooltip(l.teacherPricingRemoveRate));
      await pomper(tester);
      expect(grille.rates, isEmpty);
    });

    testWidgets('sans mode en ligne : le premier mode propose est le presentiel', (tester) async {
      await monterEditeur(tester, enLigne: false, presentiel: true);
      await tester.tap(_bouton(L10n.current.teacherPricingAddRate));
      await pomper(tester);
      expect(grille.rates.single.mode, 'in_person');
    });

    testWidgets('tarif existant : montant prérempli', (tester) async {
      await monterEditeur(tester, depart: const TutorPricingGrid(rates: [TutorRate(subject: 'Physique', hourlyRateXaf: 1200)]));
      expect(find.widgetWithText(TextFormField, '1200'), findsOneWidget);
    });

    testWidgets('modulation : ajout (Soir +10 %, semaine 18h-21h), jours, pourcentage et suppression', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherPricingAddMod));
      await pomper(tester);
      final m = grille.modifiers.single;
      expect(m.label, 'Soir');
      expect(m.daysOfWeek, [1, 2, 3, 4, 5]);
      expect(m.startTime, '18:00');
      expect(m.endTime, '21:00');
      expect(m.percentAdjustment, 10);
      expect(find.byType(FilterChip), findsNWidgets(7));
      // Retire le premier jour de semaine puis ajoute le dimanche (index 0).
      await tester.tap(find.byType(FilterChip).at(1));
      await pomper(tester);
      expect(grille.modifiers.single.daysOfWeek, [2, 3, 4, 5]);
      await tester.tap(find.byType(FilterChip).at(0));
      await pomper(tester);
      expect(grille.modifiers.single.daysOfWeek, [0, 2, 3, 4, 5]);
      // Pourcentage negatif possible (reduction).
      await tester.enterText(find.widgetWithText(TextFormField, '10'), '-15');
      await pomper(tester);
      expect(grille.modifiers.single.percentAdjustment, -15);
      // Saisie illisible : 0.
      await tester.enterText(find.widgetWithText(TextFormField, '-15'), 'x');
      await pomper(tester);
      expect(grille.modifiers.single.percentAdjustment, 0);
      await tester.tap(find.byTooltip(l.teacherPricingRemoveMod));
      await pomper(tester);
      expect(grille.modifiers, isEmpty);
    });

    testWidgets('modulations : dix au plus, le bouton d\'ajout disparait', (tester) async {
      await monterEditeur(
        tester,
        depart: TutorPricingGrid(modifiers: [
          for (var i = 0; i < 10; i++) TutorRateModifier(label: 'M$i', percentAdjustment: 5),
        ]),
      );
      expect(_bouton(L10n.current.teacherPricingAddMod), findsNothing);
    });

    testWidgets('degressivite : palier par defaut (2 h, 5 %), 3 h au second, pourcentage saisi, suppression', (tester) async {
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherPricingAddTierPlus));
      await pomper(tester);
      expect(grille.discounts.single.minDurationMinutes, 120);
      expect(grille.discounts.single.percentDiscount, 5);
      await tester.tap(_bouton(l.teacherPricingAddTierPlus));
      await pomper(tester);
      expect(grille.discounts.map((d) => d.minDurationMinutes), [120, 180]);
      await tester.enterText(find.widgetWithText(TextFormField, '5').first, '12');
      await pomper(tester);
      expect(grille.discounts.first.percentDiscount, 12);
      await tester.tap(find.byTooltip(l.teacherPricingRemoveTier).first);
      await pomper(tester);
      expect(grille.discounts.map((d) => d.minDurationMinutes), [180]);
    });

    testWidgets('paliers de duree : cinq au plus', (tester) async {
      await monterEditeur(
        tester,
        depart: TutorPricingGrid(discounts: [
          for (var i = 0; i < 5; i++) TutorDurationDiscount(minDurationMinutes: 120 + i * 30, percentDiscount: 5),
        ]),
      );
      expect(_bouton(L10n.current.teacherPricingAddTierPlus), findsNothing);
    });

    testWidgets('suggestion sans matiere : message, aucun appel', (tester) async {
      await monterEditeur(tester, matieres: const []);
      await tester.tap(_bouton(L10n.current.teacherPricingSuggest));
      await pomper(tester);
      expect(find.text(L10n.current.teacherPricingSubjectsFirst), findsOneWidget);
      expect(faux.requetes, isEmpty);
    });

    testWidgets('suggestion WinAI : demande avec matieres, modes et niveau ; grille proposee puis appliquee', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {
        'grid': {
          'base_rates': [
            {'subject': 'Mathématiques', 'mode': 'online', 'hourly_rate_xaf': 1500},
          ],
          'modifiers': [],
          'duration_discounts': [
            {'min_duration_minutes': 120, 'percent_discount': 10},
          ],
          'explanation': 'Selon le marche',
        },
      });
      await monterEditeur(tester, presentiel: true);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherPricingSuggest));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-profile/me/suggest-rate').single.data as Map;
      expect(envoi['subjects'], ['Mathématiques', 'Physique']);
      expect(envoi['modes'], ['online', 'in_person']);
      expect(envoi['level'], 'Terminale');
      expect(envoi['include_grid'], true);
      expect(find.text(l.teacherPricingSuggested), findsOneWidget);
      expect(find.text('Selon le marche'), findsOneWidget);
      await tester.tap(_bouton(l.studentCatalogApply));
      await pomper(tester);
      expect(grille.rates.single.hourlyRateXaf, 1500);
      expect(grille.discounts.single.percentDiscount, 10);
      expect(find.text(l.teacherPricingSuggested), findsNothing);
      // Le champ du tarif est reconstruit avec la valeur proposee.
      expect(find.widgetWithText(TextFormField, '1500'), findsOneWidget);
    });

    testWidgets('suggestion : « Ignorer » ferme la carte sans changer la grille', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {
        'grid': {'base_rates': [], 'modifiers': [], 'duration_discounts': [], 'explanation': 'x'},
      });
      await monterEditeur(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherPricingSuggest));
      await reseau(tester);
      await tester.tap(_bouton(l.teacherPricingIgnore));
      await pomper(tester);
      expect(find.text(l.teacherPricingSuggested), findsNothing);
      expect(grille.rates, isEmpty);
    });

    testWidgets('suggestion en erreur serveur : message', (tester) async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {}, statut: 500);
      await monterEditeur(tester);
      await tester.tap(_bouton(L10n.current.teacherPricingSuggest));
      await reseau(tester);
      expect(find.text(L10n.current.teacherPricingSuggestError), findsOneWidget);
    });
  });
}
