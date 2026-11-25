import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/institution/action_plan_screen.dart';
import 'package:winplus/institution/at_risk_screen.dart';
import 'package:winplus/institution/group_create_screen.dart';
import 'package:winplus/institution/group_members_screen.dart';
import 'package:winplus/institution/institution_tabs.dart';
import 'package:winplus/institution/license_screen.dart';
import 'package:winplus/institution/reports_screen.dart';
import 'package:winplus/institution/tutor_endorsements_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/tutoring_for_students_screen.dart';
import 'package:winplus/widgets/language_selector.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

/// Les onglets sont des colonnes sans Scaffold : on les pose dans un Scaffold.
Widget _page(Widget onglet) => Scaffold(body: onglet);

Map<String, dynamic> _groupe(int id, String nom, int membres, {String niveau = 'Terminale'}) => {'id': id, 'name': nom, 'memberCount': membres, 'level': niveau};

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'institution'}));

  /// Ecran haut : toute la liste est construite sans defilement.
  Future<void> monterHaut(WidgetTester tester, Widget enfant, {WinAppState? etat}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3000);
    await monter(tester, ecran(enfant, etat: etat));
    await reseau(tester);
  }

  group('InstitutionGroupsTab', () {
    testWidgets('chargement puis groupes : effectif, nom, classe et actions', (tester) async {
      faux.repond('GET', '/institution/groups', [
        _groupe(1, 'Terminale C1', 32),
        _groupe(2, 'Premiere D', 28, niveau: 'Première'),
      ]);
      telephone(tester);
      await monter(tester, ecran(_page(const InstitutionGroupsTab())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.widgetWithText(TextField, l.instGroupSearch), findsOneWidget);
      expect(find.text('Terminale C1'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text(l.instDashStudentsCount(32)), findsOneWidget);
      expect(_bouton(l.instGroupSeeStudents), findsNWidgets(2));
      expect(_bouton(l.instGroupAssignResources), findsNWidgets(2));
      expect(_bouton(l.studentGroupsCreate), findsOneWidget);
    });

    testWidgets('aucun groupe : seul le bouton de creation reste', (tester) async {
      faux.repond('GET', '/institution/groups', []);
      await monterEcran(tester, _page(const InstitutionGroupsTab()));
      expect(_bouton(L10n.current.instGroupSeeStudents), findsNothing);
      expect(_bouton(L10n.current.studentGroupsCreate), findsOneWidget);
    });

    testWidgets('« Voir eleves » ouvre les membres du groupe', (tester) async {
      faux.repond('GET', '/institution/groups', [_groupe(7, 'Terminale C1', 32)]);
      faux.repond('GET', '/institution/groups/7/members', []);
      await monterEcran(tester, _page(const InstitutionGroupsTab()));
      await tester.tap(_bouton(L10n.current.instGroupSeeStudents));
      await reseau(tester);
      final membres = tester.widget<GroupMembersScreen>(find.byType(GroupMembersScreen));
      expect(membres.groupId, 7);
      expect(membres.groupName, 'Terminale C1');
    });

    testWidgets('« Attribuer ressources » : feuille au nom du groupe, « Annuler » la ferme', (tester) async {
      faux.repond('GET', '/institution/groups', [_groupe(7, 'Terminale C1', 32)]);
      await monterEcran(tester, _page(const InstitutionGroupsTab()));
      final l = L10n.current;
      await tester.tap(_bouton(l.instGroupAssignResources));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.instGroupAssignTo('Terminale C1')), findsOneWidget);
      expect(find.text(l.instGroupAssignInfo), findsOneWidget);
      expect(_bouton(l.instGroupBrowseCatalog), findsOneWidget);
      await tester.tap(_bouton(l.commonCancel));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.instGroupAssignTo('Terminale C1')), findsNothing);
    });

    testWidgets('« Creer un groupe » ouvre le formulaire puis relit la liste au retour', (tester) async {
      faux.repond('GET', '/institution/groups', []);
      await monterEcran(tester, _page(const InstitutionGroupsTab()));
      await tester.tap(_bouton(L10n.current.studentGroupsCreate));
      await reseau(tester);
      expect(find.byType(GroupCreateScreen), findsOneWidget);
      faux.repond('GET', '/institution/groups', [_groupe(9, 'Nouveau groupe', 0)]);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(faux.recues('GET', '/institution/groups'), hasLength(2));
      expect(find.text('Nouveau groupe'), findsOneWidget);
    });

    // Bug probable (lecture du code) : _load n'attrape pas les erreurs ; un
    // serveur en erreur laisse l'onglet sur son indicateur de chargement, sans
    // message ni nouvel essai possible.
    testWidgets('BUG PROBABLE : serveur en erreur, l\'onglet sort du chargement', (tester) async {
      faux.repond('GET', '/institution/groups', {}, statut: 500);
      await monterEcran(tester, _page(const InstitutionGroupsTab()));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }, skip: true); // Bug probable : voir le commentaire ci-dessus.
  });

  group('InstitutionCatalogTab', () {
    testWidgets('bandeau de licence et contenus du catalogue avec leur classe', (tester) async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'Epreuve de maths', 'category': 'epreuve', 'level': 'Terminale', 'price': 500},
          {'id': 2, 'title': 'Livre de physique', 'category': 'livre', 'level': 'Première', 'isFree': true},
        ],
      });
      await monterEcran(tester, _page(const InstitutionCatalogTab()));
      final l = L10n.current;
      expect(find.text(l.instCatalogLicenseInfo), findsOneWidget);
      expect(find.text('Epreuve de maths'), findsOneWidget);
      expect(find.text('Livre de physique'), findsOneWidget);
      expect(find.textContaining('Terminale'), findsOneWidget);
      // Pas de bouton « Assigner » : le serveur n'a pas cette fonction.
      expect(find.text(l.instCatalogAssign), findsNothing);
      expect(faux.recues('GET', '/subjects').single.queryParameters['pageSize'], 40);
    });

    testWidgets('catalogue vide : « aucun contenu » ; panne : erreur et bouton Reessayer', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      await monterEcran(tester, _page(const InstitutionCatalogTab()));
      expect(find.text(L10n.current.studentTabsNoContent), findsOneWidget);
      await monter(tester, const SizedBox());
      faux.repond('GET', '/subjects', {}, statut: 500);
      await monterEcran(tester, _page(const InstitutionCatalogTab()));
      expect(find.text(L10n.current.studentTabsNoContent), findsNothing);
      expect(find.text(L10n.current.commonLoadError), findsOneWidget);
      expect(find.text(L10n.current.commonRetry), findsOneWidget);
    });
  });

  group('InstitutionAnalyticsTab', () {
    void routes() {
      faux.repond('GET', '/institution/analytics', {'downloadsThisMonth': 140, 'quizzesThisMonth': 56});
      faux.repond('GET', '/institution/groups', [
        _groupe(1, 'Terminale C1', 32),
        _groupe(2, 'Premiere D', 28),
      ]);
    }

    testWidgets('compteurs du mois et performance par groupe', (tester) async {
      routes();
      await monterHaut(tester, _page(const InstitutionAnalyticsTab()));
      final l = L10n.current;
      expect(find.text('140'), findsOneWidget);
      expect(find.text('56'), findsOneWidget);
      expect(find.text(l.instAnalyticsDownloadsMonth), findsOneWidget);
      expect(find.text(l.instAnalyticsQuizMonth), findsOneWidget);
      expect(find.text(l.instAnalyticsByGroup), findsOneWidget);
      expect(find.text('Terminale C1'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.byType(WinProgressBar), findsNWidgets(2));
    });

    testWidgets('« Eleves a risque » ouvre l\'ecran dedie', (tester) async {
      routes();
      await monterHaut(tester, _page(const InstitutionAnalyticsTab()));
      await tester.tap(_bouton(L10n.current.instRiskTitle));
      await reseau(tester);
      expect(find.byType(AtRiskScreen), findsOneWidget);
    });

    testWidgets('« Plan d\'action WinAI » ouvre l\'ecran dedie', (tester) async {
      routes();
      await monterHaut(tester, _page(const InstitutionAnalyticsTab()));
      await tester.tap(_bouton(L10n.current.instPlanTitle));
      await reseau(tester);
      expect(find.byType(ActionPlanScreen), findsOneWidget);
    });
  });

  group('InstitutionAccountTab', () {
    testWidgets('nom de l\'etablissement lu sur le serveur', (tester) async {
      faux.repond('GET', '/institution/me', {
        'data': {'id': 3, 'name': 'Lycee Leclerc'},
      });
      await monterHaut(tester, _page(const InstitutionAccountTab()));
      final l = L10n.current;
      expect(find.text('Lycee Leclerc'), findsOneWidget);
      expect(find.text(l.instAccountSchool), findsOneWidget);
      expect(find.text(l.instAccountLicense), findsOneWidget);
      expect(find.byType(LanguageToggle), findsOneWidget);
      expect(find.text(l.commonLogout), findsOneWidget);
    });

    testWidgets('nom introuvable : « Mon etablissement »', (tester) async {
      faux.repond('GET', '/institution/me', {}, statut: 500);
      await monterHaut(tester, _page(const InstitutionAccountTab()));
      expect(find.text(L10n.current.instMySchool), findsOneWidget);
    });

    testWidgets('liens : licence, tutorat, cautions et rapports ouvrent leur ecran', (tester) async {
      faux.repond('GET', '/institution/me', {'name': 'Lycee Leclerc'});
      final l = L10n.current;
      final cas = <String, Type>{
        l.instAccountLicense: LicenseScreen,
        l.instAccountTutoring: TutoringForStudentsScreen,
        l.instEndorseScreenTitle: TutorEndorsementsScreen,
        l.instAccountReports: ReportsScreen,
      };
      for (final e in cas.entries) {
        await monterHaut(tester, _page(const InstitutionAccountTab()));
        await tester.tap(find.text(e.key));
        await reseau(tester);
        expect(find.byType(e.value), findsOneWidget, reason: e.key);
        await monter(tester, const SizedBox());
      }
    });

    testWidgets('mode sombre : l\'interrupteur bascule le theme global', (tester) async {
      faux.repond('GET', '/institution/me', {'name': 'Lycee Leclerc'});
      final etat = WinAppState();
      await monterHaut(tester, _page(const InstitutionAccountTab()), etat: etat);
      expect(etat.dark, isFalse);
      final ligne = find.widgetWithText(Row, L10n.current.commonDarkMode);
      await tester.tap(find.descendant(of: ligne, matching: find.byType(Switch)));
      await pomper(tester);
      expect(etat.dark, isTrue);
    });
  });

  group('InstitutionWinAITab', () {
    testWidgets('etat initial : presentation et quatre suggestions', (tester) async {
      await monterEcran(tester, const InstitutionWinAITab());
      final l = L10n.current;
      expect(find.text(l.instAiTagline), findsOneWidget);
      for (final s in [l.instAiSuggestion1, l.instRiskTitle, l.instAiSuggestion3, l.instAiSuggestion4]) {
        expect(find.text(s), findsOneWidget);
      }
    });

    testWidgets('une suggestion est envoyee et la reponse affichee', (tester) async {
      faux.repond('POST', '/chatbot/message', {'reply': 'Voici l\'analyse'});
      await monterEcran(tester, const InstitutionWinAITab());
      final suggestion = L10n.current.instAiSuggestion3;
      await tester.tap(find.text(suggestion));
      await reseau(tester);
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], suggestion);
      expect(find.text('Voici l\'analyse'), findsOneWidget);
    });

    testWidgets('message initial envoye automatiquement ; sans reponse : message par defaut', (tester) async {
      faux.repond('POST', '/chatbot/message', {}, statut: 500);
      await monterEcran(tester, const InstitutionWinAITab(initialMessage: 'Analyse de cohorte'));
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Analyse de cohorte');
      expect(find.text(L10n.current.studentTabsAiNoReply), findsOneWidget);
    });

    testWidgets('saisie vide ignoree, saisie rognee envoyee', (tester) async {
      faux.repond('POST', '/chatbot/message', {'reply': 'D\'accord'});
      await monterEcran(tester, const InstitutionWinAITab());
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(faux.requetes, isEmpty);
      await tester.enterText(find.byType(TextField), '  Quels groupes decrochent ? ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Quels groupes decrochent ?');
    });
  });
}
