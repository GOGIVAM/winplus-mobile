import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/pending_goals_panel.dart';
import 'package:winplus/student/tutors/tutor_report_sheet.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  group('PendingGoalsPanel', () {
    void objectifs(List<Map<String, dynamic>> l) => faux.repond('GET', '/student/goals', {'data': l});

    final proposes = [
      {'id': 1, 'title': 'Reviser les maths', 'description': 'Chaque soir', 'status': 'Pending', 'targetDate': '2026-05-01T12:00:00Z', 'proposedByUserId': 9},
      {'id': 2, 'title': 'Deja actif', 'status': 'Active', 'targetDate': '2026-05-01T12:00:00Z'},
    ];

    testWidgets('sans proposition en attente : le panneau est invisible', (tester) async {
      objectifs([proposes[1]]);
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      expect(find.text(L10n.current.studentGoalsTitle), findsNothing);
    });

    testWidgets('propositions en attente : titre, compteur, description, echeance et mention du parent', (tester) async {
      objectifs(proposes);
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      final l = L10n.current;
      expect(find.text(l.studentGoalsTitle), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Reviser les maths'), findsOneWidget);
      expect(find.text('Chaque soir'), findsOneWidget);
      expect(find.text(l.studentGoalsProposedBy), findsOneWidget);
      expect(find.text('Deja actif'), findsNothing);
    });

    testWidgets('accepter : appel serveur puis disparition du panneau', (tester) async {
      objectifs(proposes);
      faux.repond('POST', '/goals/1/accept', {});
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      await tester.tap(_bouton(L10n.current.commonAccept));
      await reseau(tester);
      expect(faux.recues('POST', '/goals/1/accept'), hasLength(1));
      expect(find.text('Reviser les maths'), findsNothing);
    });

    testWidgets('accepter echoue : message d\'erreur, la proposition reste', (tester) async {
      objectifs(proposes);
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      await tester.tap(_bouton(L10n.current.commonAccept));
      await reseau(tester);
      expect(find.text(L10n.current.studentGoalsAcceptError), findsOneWidget);
      expect(find.text('Reviser les maths'), findsOneWidget);
    });

    testWidgets('refuser : confirmation d\'abord, puis appel ; annuler ne fait rien', (tester) async {
      objectifs(proposes);
      faux.repond('POST', '/goals/1/refuse', {});
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      final l = L10n.current;
      await tester.tap(_bouton(l.commonDecline));
      await pomper(tester);
      expect(find.text(l.studentGoalsRefuseConfirm), findsOneWidget);
      await tester.tap(_bouton(l.commonCancel));
      await pomper(tester);
      expect(faux.recues('POST', '/goals/1/refuse'), isEmpty);
      await tester.tap(_bouton(l.commonDecline));
      await pomper(tester);
      await tester.tap(_bouton(l.commonConfirm));
      await reseau(tester);
      expect(faux.recues('POST', '/goals/1/refuse'), hasLength(1));
      expect(find.text('Reviser les maths'), findsNothing);
    });

    testWidgets('modifier : formulaire prerempli ; titre vide refuse ; enregistrement envoie l\'echeance', (tester) async {
      objectifs(proposes);
      faux.repond('PUT', '/goals/1/modify', {});
      await monterEcran(tester, const Scaffold(body: PendingGoalsPanel()));
      final l = L10n.current;
      await tester.tap(_bouton(l.commonEdit));
      await pomper(tester);
      expect(find.widgetWithText(TextField, 'Reviser les maths'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(_bouton(l.studentGoalsSaveActivate));
      await reseau(tester);
      expect(find.text(l.studentGoalsRequired), findsOneWidget);
      expect(faux.recues('PUT', '/goals/1/modify'), isEmpty);
      await tester.enterText(find.byType(TextField).first, 'Reviser les sciences');
      await tester.tap(_bouton(l.studentGoalsSaveActivate));
      await reseau(tester);
      final d = faux.recues('PUT', '/goals/1/modify').single.data as Map;
      expect(d['title'], 'Reviser les sciences');
      expect(d['description'], 'Chaque soir');
      expect(d.containsKey('deadline'), isTrue);
      expect(find.text('Reviser les sciences'), findsNothing, reason: 'la proposition quitte la liste une fois activee');
    });
  });

  group('showTutorReportSheet', () {
    Widget ouvreur(void Function(bool?) surResultat) => Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () async => surResultat(await showTutorReportSheet(c, bookingId: 5, tutorName: 'Mme Ngo')),
              child: const Text('signaler'),
            ),
          ),
        );

    Future<void> ouvrirFeuille(WidgetTester tester) async {
      await tester.tap(find.text('signaler'));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
    }

    testWidgets('titre avec le nom du tuteur et motifs de secours si le serveur ne repond pas', (tester) async {
      await monterEcran(tester, ouvreur((_) {}));
      await ouvrirFeuille(tester);
      expect(find.text(L10n.current.tutoringReportName('Mme Ngo')), findsOneWidget);
      expect(find.text(L10n.current.tutoringReportIntro), findsOneWidget);
    });

    testWidgets('aucun motif choisi : message et aucun envoi', (tester) async {
      await monterEcran(tester, ouvreur((_) {}));
      await ouvrirFeuille(tester);
      await tester.tap(_bouton(L10n.current.tutoringReportSubmit));
      await reseau(tester);
      expect(find.text(L10n.current.tutoringReportChooseReason), findsOneWidget);
      expect(faux.recues('POST', '/tutor-reports'), isEmpty);
    });

    testWidgets('motif « autre » : description d\'au moins 10 caracteres exigee', (tester) async {
      faux.repond('GET', '/tutor-reports/reasons', [
        {'code': 'other', 'label': 'Autre motif'},
      ]);
      await monterEcran(tester, ouvreur((_) {}));
      await ouvrirFeuille(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text('Autre motif').last);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), 'court');
      await tester.tap(_bouton(L10n.current.tutoringReportSubmit));
      await reseau(tester);
      expect(find.text(L10n.current.tutoringReportDescribe), findsOneWidget);
      expect(faux.recues('POST', '/tutor-reports'), isEmpty);
    });

    testWidgets('signalement envoye : motif et description postes, message du serveur, resultat « vrai »', (tester) async {
      bool? resultat;
      faux.repond('GET', '/tutor-reports/reasons', [
        {'code': 'no_show', 'label': 'Absent'},
      ]);
      faux.repond('POST', '/tutor-reports', {'message': 'Signalement recu'});
      await monterEcran(tester, ouvreur((r) => resultat = r));
      await ouvrirFeuille(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text('Absent').last);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(_bouton(L10n.current.tutoringReportSubmit));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(faux.recues('POST', '/tutor-reports').single.data, {'tutorBookingId': 5, 'reason': 'no_show'});
      expect(find.text('Signalement recu'), findsOneWidget);
      expect(resultat, true);
    });

    testWidgets('echec du signalement : message d\'erreur dans la feuille', (tester) async {
      faux.repond('GET', '/tutor-reports/reasons', [
        {'code': 'no_show', 'label': 'Absent'},
      ]);
      faux.repond('POST', '/tutor-reports', {'error': 'Deja signale'}, statut: 409);
      await monterEcran(tester, ouvreur((_) {}));
      await ouvrirFeuille(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text('Absent').last);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(_bouton(L10n.current.tutoringReportSubmit));
      await reseau(tester);
      expect(find.text('Deja signale'), findsOneWidget);
    });
  });
}
