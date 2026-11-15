import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/action_plan_screen.dart';
import 'package:winplus/institution/at_risk_screen.dart';
import 'package:winplus/institution/group_create_screen.dart';
import 'package:winplus/institution/group_members_screen.dart';
import 'package:winplus/institution/reports_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await reseau(tester);
}

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('ReportsScreen', () {
    testWidgets('presente le rapport mensuel et le bouton « Recevoir maintenant »', (tester) async {
      await monterEcran(tester, const ReportsScreen());
      final l = L10n.current;
      expect(find.text(l.instReportsTitle), findsOneWidget);
      expect(find.text(l.instMonthlyReportTitle), findsOneWidget);
      expect(find.text(l.instMonthlyReportMeta), findsOneWidget);
      expect(_bouton(l.instMonthlyReportSendNow), findsOneWidget);
    });

    testWidgets('envoi reussi : message de confirmation', (tester) async {
      faux.repond('POST', '/institution/monthly-report/send', {});
      await monterEcran(tester, const ReportsScreen());
      await _toucher(tester, _bouton(L10n.current.instMonthlyReportSendNow));
      expect(faux.recues('POST', '/institution/monthly-report/send'), hasLength(1));
      expect(find.text(L10n.current.instMonthlyReportSent), findsOneWidget);
    });

    testWidgets('refus 400 : aucune adresse e-mail de direction', (tester) async {
      faux.repond('POST', '/institution/monthly-report/send', {'error': 'x'}, statut: 400);
      await monterEcran(tester, const ReportsScreen());
      await _toucher(tester, _bouton(L10n.current.instMonthlyReportSendNow));
      expect(find.text(L10n.current.instMonthlyReportNoEmail), findsOneWidget);
    });

    testWidgets('autre erreur serveur : message d\'erreur generique', (tester) async {
      faux.repond('POST', '/institution/monthly-report/send', {}, statut: 500);
      await monterEcran(tester, const ReportsScreen());
      await _toucher(tester, _bouton(L10n.current.instMonthlyReportSendNow));
      expect(find.text(L10n.current.instMonthlyReportError), findsOneWidget);
      expect(find.text(L10n.current.instMonthlyReportNoEmail), findsNothing);
    });
  });

  group('AtRiskScreen', () {
    final eleves = [
      {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'groupName': 'Groupe A', 'riskScore': 40, 'globalScore': 60, 'inactiveDays': 2, 'weakSubject': 'Maths', 'weakScore': 30, 'riskReason': 'Notes en baisse'},
      {'id': 2, 'firstName': 'Bob', 'lastName': 'Nku', 'groupName': 'Groupe B', 'riskScore': 90, 'globalScore': 30, 'inactiveDays': 10},
      {'id': 3, 'firstName': 'Cleo', 'lastName': 'Ban', 'groupName': 'Groupe C', 'riskScore': 70, 'globalScore': 35},
    ];

    testWidgets('liste vide : message « aucun eleve a risque »', (tester) async {
      faux.repond('GET', '/institution/at-risk', []);
      await monterEcran(tester, const AtRiskScreen());
      expect(find.text(L10n.current.instRiskEmpty), findsOneWidget);
    });

    testWidgets('erreur serveur : meme etat vide, sans plantage', (tester) async {
      faux.repond('GET', '/institution/at-risk', {}, statut: 500);
      await monterEcran(tester, const AtRiskScreen());
      expect(find.text(L10n.current.instRiskEmpty), findsOneWidget);
    });

    testWidgets('tri : critiques d\'abord (score de risque decroissant), puis moderes ; compteur de critiques', (tester) async {
      faux.repond('GET', '/institution/at-risk', eleves);
      await monterEcran(tester, const AtRiskScreen());
      double y(String nom) => tester.getTopLeft(find.text(nom)).dy;
      expect(y('Bob Nku'), lessThan(y('Cleo Ban')));
      expect(y('Cleo Ban'), lessThan(y('Ada Eto')));
      expect(find.text(L10n.current.instRiskCriticalCount(2)), findsOneWidget);
    });

    testWidgets('carte : matiere faible, score, inactivite, raison et groupe', (tester) async {
      faux.repond('GET', '/institution/at-risk', [eleves[0]]);
      await monterEcran(tester, const AtRiskScreen());
      final l = L10n.current;
      expect(find.text('Groupe A'), findsOneWidget);
      expect(find.textContaining('Maths'), findsOneWidget);
      expect(find.text(l.instRiskScore(60)), findsOneWidget);
      expect(find.text(l.instRiskInactiveFor(2)), findsOneWidget);
      expect(find.text('Notes en baisse'), findsOneWidget);
      expect(find.text(l.instRiskModerate), findsWidgets);
    });

    testWidgets('filtre « Critique » masque les moderes', (tester) async {
      faux.repond('GET', '/institution/at-risk', eleves);
      await monterEcran(tester, const AtRiskScreen());
      await tester.tap(find.widgetWithText(WinChip, L10n.current.instRiskCritical));
      await pomper(tester);
      expect(find.text('Ada Eto'), findsNothing);
      expect(find.text('Bob Nku'), findsOneWidget);
      await tester.tap(find.widgetWithText(WinChip, L10n.current.instRiskModerate));
      await pomper(tester);
      expect(find.text('Ada Eto'), findsOneWidget);
      expect(find.text('Bob Nku'), findsNothing);
    });

    testWidgets('« Plan d\'action » ouvre le plan d\'action', (tester) async {
      faux.repond('GET', '/institution/at-risk', [eleves[0]]);
      await monterEcran(tester, const AtRiskScreen());
      await _toucher(tester, _bouton(L10n.current.instRiskActionPlan));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(ActionPlanScreen), findsOneWidget);
    });

    testWidgets('actualiser relit la liste', (tester) async {
      faux.repond('GET', '/institution/at-risk', []);
      await monterEcran(tester, const AtRiskScreen());
      await tester.tap(find.byIcon(Icons.refresh_outlined));
      await reseau(tester);
      expect(faux.recues('GET', '/institution/at-risk'), hasLength(2));
    });
  });

  group('ActionPlanScreen', () {
    testWidgets('chargement : squelettes puis plan', (tester) async {
      faux.repond('GET', '/institution/action-plan', {'actions': []});
      telephone(tester);
      await monter(tester, ecran(const ActionPlanScreen()));
      expect(find.byType(WinSkeleton), findsWidgets);
      await reseau(tester);
      expect(find.byType(WinSkeleton), findsNothing);
    });

    testWidgets('actions et resume : priorite, effort, impact, compteur 0/2', (tester) async {
      faux.repond('GET', '/institution/action-plan', {
        'week_label': 'Semaine 12',
        'context': {'student_count': 120, 'at_risk_count': 8},
        'actions': [
          {'priority': 1, 'action': 'Appeler les familles', 'effort': 'Faible', 'estimated_impact': 'Fort'},
          {'priority': 2, 'action': 'Organiser un tutorat'},
        ],
      });
      await monterEcran(tester, const ActionPlanScreen());
      final l = L10n.current;
      expect(find.text('Semaine 12'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(find.text(l.instPlanPriority(1)), findsOneWidget);
      expect(find.text('Faible'), findsOneWidget);
      expect(find.text('Appeler les familles'), findsOneWidget);
      expect(find.text(l.instPlanImpact('Fort')), findsOneWidget);
      final resume = l.instPlanSummaryStudents(120) + l.instPlanSummaryAtRisk(8) + l.instPlanSummaryActions(2);
      expect(find.text(resume), findsOneWidget);
    });

    testWidgets('« Marquer comme fait » avance le compteur', (tester) async {
      faux.repond('GET', '/institution/action-plan', {
        'actions': [
          {'priority': 1, 'action': 'A'},
          {'priority': 2, 'action': 'B'},
        ],
      });
      await monterEcran(tester, const ActionPlanScreen());
      await tester.tap(_bouton(L10n.current.instPlanMarkDone).first);
      await pomper(tester);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text(L10n.current.instPlanDone), findsOneWidget);
    });

    testWidgets('aucune action : le message du serveur est affiche', (tester) async {
      faux.repond('GET', '/institution/action-plan', {'message': 'Aucun eleve rattache'});
      await monterEcran(tester, const ActionPlanScreen());
      expect(find.text('Aucun eleve rattache'), findsOneWidget);
    });

    testWidgets('aucune action ni message : texte vide par defaut', (tester) async {
      faux.repond('GET', '/institution/action-plan', {});
      await monterEcran(tester, const ActionPlanScreen());
      expect(find.text(L10n.current.instPlanEmpty), findsOneWidget);
    });

    testWidgets('403 : acces refuse ; autre erreur : plan indisponible ; « Reessayer » recharge', (tester) async {
      faux.repond('GET', '/institution/action-plan', {}, statut: 403);
      await monterEcran(tester, const ActionPlanScreen());
      expect(find.text(L10n.current.instPlanForbidden), findsOneWidget);
      faux.repond('GET', '/institution/action-plan', {}, statut: 500);
      await tester.tap(_bouton(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text(L10n.current.instPlanUnavailable), findsOneWidget);
      faux.repond('GET', '/institution/action-plan', {'actions': [
        {'priority': 1, 'action': 'Enfin'},
      ]});
      await tester.tap(_bouton(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text('Enfin'), findsOneWidget);
    });
  });

  group('GroupMembersScreen', () {
    testWidgets('membres : nom du groupe, effectif, moyennes', (tester) async {
      faux.repond('GET', '/institution/groups/3/members', [
        {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'email': 'ada@x.cm', 'averageScore': 82.4},
        {'id': 2, 'firstName': 'Bob', 'lastName': 'Nku', 'averageScore': 45},
      ]);
      await monterEcran(tester, const GroupMembersScreen(groupId: 3, groupName: '3eA'));
      expect(find.text('3eA'), findsOneWidget);
      expect(find.text(L10n.current.instStudentCount(2)), findsOneWidget);
      expect(find.text('Ada Eto'), findsOneWidget);
      expect(find.text('ada@x.cm'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('groupe sans membre : message dedie', (tester) async {
      faux.repond('GET', '/institution/groups/3/members', []);
      await monterEcran(tester, const GroupMembersScreen(groupId: 3, groupName: '3eA'));
      expect(find.text(L10n.current.instGroupNoMembers), findsOneWidget);
    });
  });

  group('GroupCreateScreen', () {
    Future<void> nommer(WidgetTester tester, String nom) async {
      await tester.enterText(find.byType(TextField).first, nom);
      await pomper(tester);
    }

    testWidgets('formulaire : champ nom, niveaux et 12 eleves a cocher', (tester) async {
      await monterEcran(tester, const GroupCreateScreen());
      expect(find.text(L10n.current.instGroupNameLabel), findsOneWidget);
      expect(find.text('BEPC'), findsOneWidget);
      expect(find.text(L10n.current.instGroupSelected(0)), findsOneWidget);
    });

    testWidgets('sans nom ou sans niveau : aucun envoi', (tester) async {
      await monterEcran(tester, const GroupCreateScreen());
      await _toucher(tester, _bouton(L10n.current.instGroupCreateSubmit));
      expect(faux.requetes, isEmpty);
      await nommer(tester, 'TLE C');
      await _toucher(tester, _bouton(L10n.current.instGroupCreateSubmit));
      expect(faux.requetes, isEmpty, reason: 'le niveau manque encore');
    });

    testWidgets('cocher des eleves met a jour le compteur', (tester) async {
      await monterEcran(tester, const GroupCreateScreen());
      await tester.ensureVisible(find.text('Ahmed Nkono'));
      await tester.tap(find.text('Ahmed Nkono'));
      await pomper(tester);
      expect(find.text(L10n.current.instGroupSelected(1)), findsOneWidget);
      await tester.tap(find.text('Ahmed Nkono'));
      await pomper(tester);
      expect(find.text(L10n.current.instGroupSelected(0)), findsOneWidget);
    });

    testWidgets('creation reussie : confirmation avec le nom du groupe', (tester) async {
      faux.repond('POST', '/institution/groups', {});
      await monterEcran(tester, const GroupCreateScreen());
      await nommer(tester, '  TLE C 2027 ');
      await tester.tap(find.text('BAC'));
      await pomper(tester);
      await _toucher(tester, _bouton(L10n.current.instGroupCreateSubmit));
      expect(faux.recues('POST', '/institution/groups').single.data, {'name': 'TLE C 2027', 'level': 'BAC'});
      expect(find.text(L10n.current.instGroupCreated), findsOneWidget);
      expect(find.text(L10n.current.instGroupCreatedSummary('TLE C 2027', 0)), findsOneWidget);
    });

    testWidgets('echec serveur : message d\'erreur et formulaire conserve', (tester) async {
      faux.repond('POST', '/institution/groups', {}, statut: 500);
      await monterEcran(tester, const GroupCreateScreen());
      await nommer(tester, 'TLE C');
      await tester.tap(find.text('BAC'));
      await pomper(tester);
      await _toucher(tester, _bouton(L10n.current.instGroupCreateSubmit));
      expect(find.text(L10n.current.instGroupCreateError), findsOneWidget);
      expect(find.text(L10n.current.instGroupCreated), findsNothing);
    });
  });
}
