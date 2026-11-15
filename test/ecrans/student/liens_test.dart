import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/my_links_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({Map<String, dynamic> liens = const {}, List<Map<String, dynamic>> attente = const [], List<Map<String, dynamic>> rattachements = const []}) {
    faux.repond('GET', '/student/links', liens);
    faux.repond('GET', '/teacher-links/pending', attente);
    faux.repond('GET', '/student/institution-attachments', {'data': rattachements});
  }

  testWidgets('chargement puis liens : parents, professeurs de classe et groupes', (tester) async {
    routes(liens: {
      'parents': [
        {'firstName': 'Marie', 'lastName': 'Eto'},
      ],
      'teachers': [
        {'firstName': 'Paul', 'lastName': 'Nkoa', 'source': 'class', 'className': '3eA'},
        {'firstName': 'Luc', 'lastName': 'Bela'},
      ],
      'groups': [
        {'name': 'Groupe maths'},
      ],
    });
    telephone(tester);
    await monter(tester, ecran(const MyLinksScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.studentLinksParents), findsOneWidget);
    expect(find.text('Marie Eto'), findsOneWidget);
    expect(find.text(l.studentLinksRoleParent), findsOneWidget);
    expect(find.text(l.studentLinksTeachers), findsOneWidget);
    expect(find.text(l.studentLinksTeacherClass('3eA')), findsOneWidget);
    expect(find.text(l.roleTeacher), findsOneWidget);
    expect(find.text(l.studentLinksStudyGroups), findsOneWidget);
    expect(find.text('Groupe maths'), findsOneWidget);
    expect(find.text(l.studentLinksInvitations), findsNothing);
  });

  testWidgets('erreur de chargement : message dedie', (tester) async {
    faux.repond('GET', '/student/links', {}, statut: 500);
    faux.repond('GET', '/teacher-links/pending', []);
    await monterEcran(tester, const MyLinksScreen());
    expect(find.text(L10n.current.studentLinksLoadError), findsOneWidget);
  });

  testWidgets('aucun lien : aucune rubrique n\'est affichee', (tester) async {
    routes();
    await monterEcran(tester, const MyLinksScreen());
    final l = L10n.current;
    expect(find.text(l.studentLinksParents), findsNothing);
    expect(find.text(l.studentLinksTeachers), findsNothing);
    expect(find.text(l.studentLinksSchools), findsNothing);
  });

  testWidgets('invitation en attente : compteur, nom et acceptation', (tester) async {
    routes(attente: [
      {'id': 5, 'firstName': 'Paul', 'lastName': 'Nkoa'},
    ]);
    faux.repond('PUT', '/teacher-links/5/accept', {});
    await monterEcran(tester, const MyLinksScreen());
    expect(find.text(L10n.current.studentLinksInvitations), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Paul Nkoa'), findsOneWidget);
    expect(find.text(L10n.current.studentLinksTeacherPending), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, L10n.current.commonAccept));
    await reseau(tester);
    expect(faux.recues('PUT', '/teacher-links/5/accept'), hasLength(1));
  });

  testWidgets('refuser une invitation la retire de la liste', (tester) async {
    routes(attente: [
      {'id': 5, 'firstName': 'Paul', 'lastName': 'Nkoa'},
    ]);
    faux.repond('PUT', '/teacher-links/5/reject', {});
    await monterEcran(tester, const MyLinksScreen());
    await tester.tap(find.widgetWithText(WinButton, L10n.current.commonDecline));
    await reseau(tester);
    expect(faux.recues('PUT', '/teacher-links/5/reject'), hasLength(1));
    expect(find.text('Paul Nkoa'), findsNothing);
    expect(find.text(L10n.current.studentLinksInvitations), findsNothing);
  });

  testWidgets('rattachement a un etablissement en attente : accepter ou refuser', (tester) async {
    routes(rattachements: [
      {'id': 9, 'institutionName': 'Lycee Leclerc', 'groupName': '3eA', 'status': 'pending'},
    ]);
    faux.repond('PUT', '/student/institution-attachments/9/accept', {});
    await monterEcran(tester, const MyLinksScreen());
    final l = L10n.current;
    expect(find.text('Lycee Leclerc'), findsOneWidget);
    expect(find.text('${l.studentLinksClass('3eA')} · ${l.studentLinksAttachPending}'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.commonAccept));
    await reseau(tester);
    expect(faux.recues('PUT', '/student/institution-attachments/9/accept'), hasLength(1));
  });

  testWidgets('rattachement accepte : bouton « retirer » qui envoie un refus', (tester) async {
    routes(rattachements: [
      {'id': 9, 'institutionName': 'Lycee Leclerc', 'status': 'accepted'},
    ]);
    faux.repond('PUT', '/student/institution-attachments/9/refuse', {});
    await monterEcran(tester, const MyLinksScreen());
    final b = find.widgetWithText(WinButton, L10n.current.studentLinksWithdraw);
    expect(b, findsOneWidget);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('PUT', '/student/institution-attachments/9/refuse'), hasLength(1));
  });

  testWidgets('echec de reponse a un rattachement : message de la barre d\'information', (tester) async {
    routes(rattachements: [
      {'id': 9, 'institutionName': 'Lycee', 'status': 'pending'},
    ]);
    await monterEcran(tester, const MyLinksScreen());
    await tester.tap(find.widgetWithText(WinButton, L10n.current.commonAccept));
    await reseau(tester);
    expect(find.text(L10n.current.studentLinksActionFailed), findsOneWidget);
  });

  testWidgets('la fleche retour est presente dans la barre', (tester) async {
    routes();
    await monterEcran(tester, const MyLinksScreen());
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
