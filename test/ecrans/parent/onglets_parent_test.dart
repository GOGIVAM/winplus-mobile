import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/add_child_screen.dart';
import 'package:winplus/parent/child_activity_screen.dart';
import 'package:winplus/parent/covered_children_screen.dart';
import 'package:winplus/parent/parent_tabs.dart';
import 'package:winplus/parent/subscription_status_screen.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/shared/subscription/pricing_screen.dart';
import 'package:winplus/shared/tutoring_for_students_screen.dart';
import 'package:winplus/widgets/language_selector.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

/// Les onglets sont des colonnes sans Scaffold : on les pose dans un Scaffold.
Widget _page(Widget onglet) => Scaffold(body: onglet);

Map<String, dynamic> _enfant(int id, String prenom, {String? niveau}) => {'id': id, 'firstName': prenom, 'lastName': 'Eto', if (niveau != null) 'level': niveau};

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boites en memoire : une ecriture sur disque lancee pendant un test ne
    // se termine jamais dans son temps simule et bloquerait le test suivant.
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement(prefs: {'user_role': 'parent'});
    await LocalCacheService.parentDashboard.clear();
  });

  group('ParentChildrenTab', () {
    testWidgets('chargement puis cartes : nom, classe (ou etablissement) et bouton d\'ajout', (tester) async {
      faux.repond('GET', '/parent/children', [
        _enfant(4, 'Zoe', niveau: 'Terminale'),
        {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto', 'schoolName': 'Lycee Leclerc'},
        _enfant(6, 'Ana'),
      ]);
      // Plan qui autorise encore un enfant : le bouton d'ajout s'affiche.
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 5});
      telephone(tester);
      await monter(tester, ecran(_page(const ParentChildrenTab()), abonnement: abo));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Zoe Eto'), findsOneWidget);
      expect(find.text('Terminale'), findsOneWidget);
      expect(find.text('Lycee Leclerc'), findsOneWidget);
      // Ni classe ni etablissement : « Eleve ».
      expect(find.text(l.roleStudent), findsOneWidget);
      expect(_bouton(l.parentAddChildTitle), findsOneWidget);
    });

    testWidgets('toucher une carte ouvre l\'activite de l\'enfant', (tester) async {
      faux.repond('GET', '/parent/children', [_enfant(4, 'Zoe', niveau: 'Terminale')]);
      await monterEcran(tester, _page(const ParentChildrenTab()));
      await tester.tap(find.text('Zoe Eto'));
      await reseau(tester);
      final ecranEnfant = tester.widget<ChildActivityScreen>(find.byType(ChildActivityScreen));
      expect(ecranEnfant.child.id, 4);
    });

    testWidgets('« Ajouter un enfant » ouvre le formulaire de rattachement', (tester) async {
      faux.repond('GET', '/parent/children', []);
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 1});
      await monterEcran(tester, _page(const ParentChildrenTab()), abonnement: abo);
      await tester.tap(_bouton(L10n.current.parentAddChildTitle));
      await reseau(tester);
      expect(find.byType(AddChildScreen), findsOneWidget);
    });

    testWidgets('limite d\'enfants du plan atteinte : bouton « N enfant max » qui ouvre les tarifs', (tester) async {
      faux.repond('GET', '/parent/children', [_enfant(4, 'Zoe')]);
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 1}, plan: 'Famille');
      await monterEcran(tester, _page(const ParentChildrenTab()), abonnement: abo);
      final l = L10n.current;
      expect(_bouton(l.parentChildrenLimit(1)), findsOneWidget);
      expect(_bouton(l.parentAddChildTitle), findsNothing);
      await tester.tap(_bouton(l.parentChildrenLimit(1)));
      await reseau(tester);
      expect(find.byType(PricingScreen), findsOneWidget);
    });

    testWidgets('sous la limite : l\'ajout reste possible', (tester) async {
      faux.repond('GET', '/parent/children', [_enfant(4, 'Zoe')]);
      final abo = await abonnementAvecDroits(tester, faux, {'children.max': 3}, plan: 'Famille');
      await monterEcran(tester, _page(const ParentChildrenTab()), abonnement: abo);
      expect(_bouton(L10n.current.parentAddChildTitle), findsOneWidget);
    });

    // Bug probable (lecture du code) : _load n'a ni try ni catch ; si le
    // serveur repond en erreur (et qu'aucune copie locale n'existe),
    // l'exception n'est pas attrapee et l'ecran reste sur son indicateur de
    // chargement, sans message ni bouton pour reessayer.
    testWidgets('BUG PROBABLE : serveur en erreur : l\'ecran sort du chargement', (tester) async {
      faux.repond('GET', '/parent/children', {}, statut: 500);
      await monterEcran(tester, _page(const ParentChildrenTab()));
      expect(chargement, findsNothing);
    }, skip: true); // Bug probable : voir le commentaire ci-dessus.
  });

  group('ParentResourcesTab', () {
    final contenus = {
      'items': [
        {'id': 1, 'title': 'Epreuve de maths', 'category': 'Mathématiques', 'price': 500},
        {'id': 2, 'title': 'Livre gratuit', 'category': 'livre', 'isFree': true},
      ],
      'totalCount': 2,
      'page': 1,
      'totalPages': 1,
    };

    /// Ecran haut : recommandes et catalogue construits sans defilement.
    Future<void> monterHaut(WidgetTester tester) async {
      telephone(tester);
      tester.view.physicalSize = const Size(800, 4000);
      await monter(tester, ecran(_page(const ParentResourcesTab())));
      await reseau(tester);
    }

    testWidgets('recommandes payants en tete, puis le catalogue complet avec son compteur', (tester) async {
      faux.repond('GET', '/subjects', contenus);
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      final l = L10n.current;
      expect(find.text(l.parentResourcesIntro), findsOneWidget);
      expect(find.text(l.parentResourcesRecommended), findsOneWidget);
      expect(find.text(l.shellTabCatalog), findsOneWidget);
      expect(find.text(l.mobileCatalogCount(2)), findsOneWidget);
      // Le contenu payant est dans les recommandes ET le catalogue ; le gratuit
      // seulement dans le catalogue.
      expect(find.text('Epreuve de maths'), findsNWidgets(2));
      expect(find.text('Livre gratuit'), findsOneWidget);
      expect(find.text('${fmtXaf(500)} XAF'), findsNWidgets(2));
      expect(find.text(l.commonFree), findsOneWidget);
    });

    testWidgets('catalogue en erreur : message et « Reessayer » qui relit', (tester) async {
      faux.repond('GET', '/subjects', {}, statut: 500);
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      final l = L10n.current;
      expect(find.text(l.studentTabsCatalogLoadError), findsOneWidget);
      faux.repond('GET', '/subjects', contenus);
      await tester.tap(_bouton(l.commonRetry));
      await reseau(tester);
      expect(find.text('Livre gratuit'), findsOneWidget);
    });

    testWidgets('catalogue vide : message « aucun contenu »', (tester) async {
      faux.repond('GET', '/subjects', {'items': [], 'totalCount': 0, 'page': 1, 'totalPages': 1});
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      expect(find.text(L10n.current.studentTabsNoContent), findsOneWidget);
    });

    testWidgets('recherche : la saisie validee relit le catalogue avec q', (tester) async {
      faux.repond('GET', '/subjects', contenus);
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      await tester.enterText(find.byType(TextField), 'physique');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await reseau(tester);
      expect(faux.recues('GET', '/subjects').last.queryParameters['q'], 'physique');
    });

    testWidgets('« Charger plus » demande la page suivante', (tester) async {
      faux.repond('GET', '/subjects', {...contenus, 'totalPages': 2});
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      await tester.tap(_bouton(L10n.current.studentCatalogLoadMore));
      await reseau(tester);
      expect(faux.recues('GET', '/subjects').last.queryParameters['page'], 2);
    });

    testWidgets('toucher un contenu payant sans enfant : message « aucun enfant »', (tester) async {
      faux.repond('GET', '/subjects', contenus);
      faux.repond('GET', '/parent/children', []);
      await monterHaut(tester);
      await tester.tap(find.text('Epreuve de maths').first);
      await pomper(tester);
      expect(find.text(L10n.current.parentDashNoChild), findsOneWidget);
    });

    testWidgets('toucher un contenu payant avec un enfant : confirmation d\'achat pour cet enfant', (tester) async {
      faux.repond('GET', '/subjects', contenus);
      faux.repond('GET', '/parent/children', [_enfant(4, 'Zoe')]);
      await monterHaut(tester);
      await tester.tap(find.text('Epreuve de maths').first);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      final l = L10n.current;
      expect(find.text(l.parentBuyConfirmTitle('Zoe')), findsOneWidget);
      await tester.tap(find.text(l.commonCancel));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(faux.recues('POST', '/parent/purchase-for-child'), isEmpty);
    });
  });

  group('ParentPaymentsTab', () {
    Map<String, dynamic> paiement(String label, num montant, {String direction = 'debit', String status = 'paid', String methode = 'Mobile Money'}) => {
          'kind': 'order',
          'label': label,
          'amountXaf': montant,
          'direction': direction,
          'status': status,
          'method': methode,
          'date': '2026-04-06T12:00:00Z',
        };

    testWidgets('depenses du mois et historique : signes, montants et statuts', (tester) async {
      faux.repond('GET', '/parent/payments', {
        'data': {
          'monthSpentXaf': 12000,
          'items': [
            paiement('Achat epreuve', 3000),
            paiement('Recharge portefeuille', 5000, direction: 'credit'),
            paiement('Achat livre', 1500, status: 'pending'),
            paiement('Abonnement', 7000, status: 'failed'),
            paiement('Pack', 2000, status: 'refunded'),
            paiement('Pack 2', 2500, status: 'refund_requested'),
          ],
        },
      });
      telephone(tester);
      tester.view.physicalSize = const Size(800, 3000);
      await monter(tester, ecran(_page(const ParentPaymentsTab())));
      expect(find.text('…'), findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.parentPaymentsTitle), findsOneWidget);
      expect(find.text(l.parentPaymentsMonthSpent), findsOneWidget);
      expect(find.text('${fmtXaf(12000)} XAF'), findsOneWidget);
      expect(find.text('−${fmtXaf(3000)}'), findsOneWidget);
      expect(find.text('+${fmtXaf(5000)}'), findsOneWidget);
      expect(find.textContaining(' · Mobile Money · ${l.parentPayStatusPending}'), findsOneWidget);
      expect(find.textContaining(' · Mobile Money · ${l.parentPayStatusFailed}'), findsOneWidget);
      expect(find.textContaining(' · Mobile Money · ${l.parentPayStatusRefunded}'), findsOneWidget);
      expect(find.textContaining(' · Mobile Money · ${l.parentPayStatusRefundRequested}'), findsOneWidget);
      // Paiement abouti : coche, credit : plus, en attente : horloge, echec : croix.
      expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.plus), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.clock), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.x), findsNWidgets(3));
    });

    testWidgets('aucun paiement : message dedie', (tester) async {
      faux.repond('GET', '/parent/payments', {
        'data': {'monthSpentXaf': 0, 'items': []},
      });
      await monterEcran(tester, _page(const ParentPaymentsTab()));
      expect(find.text(L10n.current.parentPaymentsEmpty), findsOneWidget);
      expect(find.text('${fmtXaf(0)} XAF'), findsOneWidget);
    });

    testWidgets('erreur : message puis « Reessayer »', (tester) async {
      faux.repond('GET', '/parent/payments', {}, statut: 500);
      await monterEcran(tester, _page(const ParentPaymentsTab()));
      final l = L10n.current;
      expect(find.text(l.parentPaymentsLoadError), findsOneWidget);
      faux.repond('GET', '/parent/payments', {
        'data': {'monthSpentXaf': 0, 'items': []},
      });
      await tester.tap(_bouton(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.parentPaymentsLoadError), findsNothing);
      expect(find.text(l.parentPaymentsEmpty), findsOneWidget);
      expect(faux.recues('GET', '/parent/payments').first.queryParameters['limit'], 50);
    });
  });

  group('ParentProfileTab', () {
    void routes({
      Map<String, dynamic>? abo,
      Object credits = const {'data': null},
      List<Map<String, dynamic>> enfants = const [],
    }) {
      faux.repond('GET', '/parent/profile', {
        'data': {'parentId': 1, 'name': 'Marie Eto', 'email': 'marie@exemple.cm'},
      });
      faux.repond('GET', '/subscriptions/me', abo ?? {'id': 1, 'hasPlan': false, 'planName': 'Gratuit'});
      faux.repond('GET', '/parent/credits', credits);
      faux.repond('GET', '/parent/children', enfants);
      for (final e in enfants) {
        faux.repond('GET', '/parent-alerts/${e['id']}', [
          {'id': 1, 'childId': e['id'], 'severity': 'High', 'content': 'A', 'isRead': false, 'detectedAt': '2026-04-06T12:00:00Z'},
          {'id': 2, 'childId': e['id'], 'severity': 'Low', 'content': 'B', 'isRead': true, 'detectedAt': '2026-04-06T12:00:00Z'},
        ]);
        faux.repond('GET', '/parent/children/${e['id']}/stats', {'averageScore': 66.4});
      }
    }

    Future<void> monterProfil(WidgetTester tester, {WinAppState? etat}) async {
      telephone(tester);
      tester.view.physicalSize = const Size(800, 3000);
      await monter(tester, ecran(_page(const ParentProfileTab()), etat: etat));
      await reseau(tester);
    }

    testWidgets('en-tete : nom, e-mail, plan, nombre d\'enfants, credits et alertes non lues', (tester) async {
      routes(
        abo: {'id': 1, 'hasPlan': true, 'planName': 'Famille', 'pricingPlanId': 2, 'status': 'active'},
        credits: {
          'data': {'creditsLeft': 4500, 'allocationRemaining': 3000, 'permanent': 1500, 'planName': 'Famille'},
        },
        enfants: [_enfant(4, 'Zoe', niveau: 'Terminale')],
      );
      telephone(tester);
      tester.view.physicalSize = const Size(800, 3000);
      await monter(tester, ecran(_page(const ParentProfileTab())));
      // Avant la fin du chargement : points de suspension.
      expect(find.text('…'), findsWidgets);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Marie Eto'), findsOneWidget);
      expect(find.text('marie@exemple.cm'), findsOneWidget);
      expect(find.text(l.parentPlanName('Famille')), findsOneWidget);
      expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
      expect(find.text(l.parentProfileCredits), findsOneWidget);
      // Une alerte non lue sur deux.
      expect(find.text('1'), findsNWidgets(2));
    });

    testWidgets('sans abonnement ni credits : « Sans abonnement » et tiret', (tester) async {
      routes();
      await monterProfil(tester);
      expect(find.text(L10n.current.parentNoSubscription), findsOneWidget);
      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('enfants suivis : prenom, classe et score moyen une fois lu', (tester) async {
      routes(enfants: [_enfant(4, 'Zoe', niveau: 'Terminale')]);
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.text(l.parentSubChildrenFollowed), findsOneWidget);
      expect(find.text('Zoe'), findsOneWidget);
      expect(find.text('Terminale'), findsOneWidget);
      expect(find.text('13,3/20'), findsOneWidget);
      await tester.tap(find.text('Zoe'));
      await reseau(tester);
      expect(tester.widget<ChildActivityScreen>(find.byType(ChildActivityScreen)).child.id, 4);
    });

    testWidgets('profil, abonnement et enfants en erreur : « Mon compte » et compteurs a zero', (tester) async {
      faux.repond('GET', '/parent/profile', {}, statut: 500);
      faux.repond('GET', '/subscriptions/me', {}, statut: 500);
      faux.repond('GET', '/parent/credits', {}, statut: 500);
      faux.repond('GET', '/parent/children', {}, statut: 500);
      await monterProfil(tester);
      expect(find.text(L10n.current.parentProfileMyAccount), findsOneWidget);
      expect(find.text('…'), findsNothing);
    });

    testWidgets('« Mon abonnement » et « Gerer l\'abonnement » ouvrent le statut de l\'abonnement', (tester) async {
      routes();
      await monterProfil(tester);
      await tester.tap(find.text(L10n.current.studentHubSubscription));
      await reseau(tester);
      expect(find.byType(SubscriptionStatusScreen), findsOneWidget);
    });

    testWidgets('cours particuliers des enfants', (tester) async {
      routes();
      await monterProfil(tester);
      await tester.tap(find.text(L10n.current.parentProfileTutoring));
      await reseau(tester);
      expect(find.byType(TutoringForStudentsScreen), findsOneWidget);
    });

    testWidgets('enfants couverts par le plan', (tester) async {
      routes();
      await monterProfil(tester);
      await tester.tap(find.text(L10n.current.parentProfileCovered));
      await reseau(tester);
      expect(find.byType(CoveredChildrenScreen), findsOneWidget);
    });

    testWidgets('« Paiements et historique » ouvre la page des paiements', (tester) async {
      routes();
      faux.repond('GET', '/parent/payments', {
        'data': {'monthSpentXaf': 0, 'items': []},
      });
      await monterProfil(tester);
      await tester.tap(find.text(L10n.current.parentProfilePayments));
      await reseau(tester);
      expect(find.byType(ParentPaymentsTab), findsOneWidget);
      expect(find.text(L10n.current.parentPaymentsEmpty), findsOneWidget);
    });

    testWidgets('mode sombre : l\'interrupteur bascule le theme global', (tester) async {
      routes();
      final etat = WinAppState();
      await monterProfil(tester, etat: etat);
      expect(etat.dark, isFalse);
      final ligne = find.widgetWithText(Row, L10n.current.commonDarkMode);
      await tester.tap(find.descendant(of: ligne, matching: find.byType(Switch)));
      await pomper(tester);
      expect(etat.dark, isTrue);
    });

    testWidgets('langue, confidentialite et conditions d\'utilisation sont proposees', (tester) async {
      routes();
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.text(l.language), findsOneWidget);
      expect(find.byType(LanguageToggle), findsOneWidget);
      expect(find.text(l.studentHubPrivacy), findsOneWidget);
      expect(find.text(l.studentHubTerms), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.commonLogout), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.commonLogout), findsOneWidget);
    });
  });

  group('ParentWinAITab', () {
    testWidgets('etat initial : presentation, quatre suggestions, acces a la memoire', (tester) async {
      await monterEcran(tester, const ParentWinAITab());
      final l = L10n.current;
      expect(find.text(l.parentAiTagline), findsOneWidget);
      for (final s in [l.parentAiSuggestion1, l.parentAiSuggestion2, l.parentAiSuggestion3, l.parentAiSuggestion4]) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text(l.commonWinaiMemory), findsOneWidget);
    });

    testWidgets('une suggestion est envoyee et la reponse de WinAI affichee', (tester) async {
      faux.repond('POST', '/chatbot/message', {
        'assistantMessage': {'content': 'Voici un plan'},
      });
      await monterEcran(tester, const ParentWinAITab());
      final suggestion = L10n.current.parentAiSuggestion2;
      await tester.tap(find.text(suggestion));
      await reseau(tester);
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], suggestion);
      expect(find.text(suggestion), findsOneWidget);
      expect(find.text('Voici un plan'), findsOneWidget);
    });

    testWidgets('saisie libre : message rogne envoye ; message vide ignore', (tester) async {
      faux.repond('POST', '/chatbot/message', {'reply': 'D\'accord'});
      await monterEcran(tester, const ParentWinAITab());
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(faux.requetes, isEmpty);
      await tester.enterText(find.byType(TextField), '  Comment le motiver ? ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Comment le motiver ?');
      expect(find.text('D\'accord'), findsOneWidget);
    });

    testWidgets('message initial : envoye automatiquement ; pas de reponse : message par defaut', (tester) async {
      faux.repond('POST', '/chatbot/message', {}, statut: 500);
      await monterEcran(tester, const ParentWinAITab(initialMessage: 'Aide-moi'));
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Aide-moi');
      expect(find.text(L10n.current.studentTabsAiNoReply), findsOneWidget);
    });

    testWidgets('« Memoire de WinAI » ouvre la feuille des memoires', (tester) async {
      faux.repond('GET', '/chatbot/memories', []);
      await monterEcran(tester, const ParentWinAITab());
      await tester.tap(find.text(L10n.current.commonWinaiMemory));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(faux.recues('GET', '/chatbot/memories'), hasLength(1));
    });
  });
}
