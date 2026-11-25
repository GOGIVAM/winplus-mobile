import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/study_groups_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

const _groupe = {'id': 1, 'name': 'Groupe maths', 'joinCode': 'ABC123', 'isOwner': true, 'memberCount': 3};

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('chargement puis etat vide avec indication', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': []});
    telephone(tester);
    await monter(tester, ecran(const StudyGroupsScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    expect(find.text(L10n.current.studentGroupsEmpty), findsOneWidget);
    expect(find.text(L10n.current.studentGroupsEmptyHint), findsOneWidget);
    expect(_bouton(L10n.current.studentGroupsCreatePlus), findsOneWidget);
    expect(_bouton(L10n.current.studentGroupsJoinByCode), findsOneWidget);
  });

  testWidgets('erreur serveur : avertissement et liste vide', (tester) async {
    faux.repond('GET', '/study-groups/me', {}, statut: 500);
    await monterEcran(tester, const StudyGroupsScreen());
    expect(find.text(L10n.current.studentGroupsLoadError), findsOneWidget);
  });

  testWidgets('carte de groupe : nom, badge « proprietaire » et effectif', (tester) async {
    faux.repond('GET', '/study-groups/me', {
      'data': [
        _groupe,
        {'id': 2, 'name': 'Physique', 'joinCode': 'XYZ', 'isOwner': false, 'memberCount': 1},
      ],
    });
    await monterEcran(tester, const StudyGroupsScreen());
    final l = L10n.current;
    expect(find.text('Groupe maths'), findsOneWidget);
    expect(find.text(l.studentGroupsOwner), findsOneWidget);
    expect(find.text(l.studentGroupsMemberCount(3)), findsOneWidget);
    expect(find.text(l.studentGroupsMemberCount(1)), findsOneWidget);
  });

  testWidgets('rejoindre : code trop court = message, aucun appel', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': []});
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.ensureVisible(_bouton(L10n.current.studentGroupsJoinByCode));
    await pomper(tester);
    await tester.tap(_bouton(L10n.current.studentGroupsJoinByCode));
    // Premiere image de la feuille : hors scene ; la suivante l'affiche.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(_bouton(L10n.current.studentGroupsJoin));
    await pomper(tester, const Duration(milliseconds: 200));
    expect(find.text(L10n.current.studentGroupsCodeIncomplete), findsOneWidget);
    expect(faux.recues('POST', '/study-groups/join'), isEmpty);
  });

  testWidgets('rejoindre avec un bon code : code en majuscules envoye, message et rechargement', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': []});
    faux.repond('POST', '/study-groups/join', {'data': {'id': 5, 'name': 'Chimie', 'alreadyMember': false}});
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.ensureVisible(_bouton(L10n.current.studentGroupsJoinByCode));
    await pomper(tester);
    await tester.tap(_bouton(L10n.current.studentGroupsJoinByCode));
    // Premiere image de la feuille : hors scene ; la suivante l'affiche.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), ' abc123 ');
    await tester.tap(_bouton(L10n.current.studentGroupsJoin));
    await reseau(tester);
    expect(faux.recues('POST', '/study-groups/join').single.data, {'code': 'ABC123'});
    expect(find.text(L10n.current.studentGroupsJoined('Chimie')), findsOneWidget);
    expect(faux.recues('GET', '/study-groups/me'), hasLength(2));
  });

  testWidgets('code inconnu : message « code introuvable »', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': []});
    faux.repond('POST', '/study-groups/join', {'error': 'x'}, statut: 404);
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.ensureVisible(_bouton(L10n.current.studentGroupsJoinByCode));
    await pomper(tester);
    await tester.tap(_bouton(L10n.current.studentGroupsJoinByCode));
    // Premiere image de la feuille : hors scene ; la suivante l'affiche.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'ZZZZ99');
    await tester.tap(_bouton(L10n.current.studentGroupsJoin));
    await reseau(tester);
    expect(find.text(L10n.current.studentGroupsCodeNotFound), findsOneWidget);
  });

  testWidgets('creer un groupe : nom trop court refuse, puis creation avec matiere', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': []});
    faux.repond('POST', '/study-groups', {'data': {'id': 9, 'name': 'Mon groupe'}});
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.ensureVisible(_bouton(L10n.current.studentGroupsCreatePlus));
    await pomper(tester);
    await tester.tap(_bouton(L10n.current.studentGroupsCreatePlus));
    // Premiere image de la feuille : hors scene ; la suivante l'affiche.
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(0), 'ab');
    await tester.tap(_bouton(L10n.current.studentGroupsCreateBtn));
    await reseau(tester);
    expect(find.text(L10n.current.studentGroupsNameTooShort), findsOneWidget);
    expect(faux.recues('POST', '/study-groups'), isEmpty);
    await tester.enterText(find.byType(TextField).at(0), 'Mon groupe');
    await tester.enterText(find.byType(TextField).at(1), 'Maths');
    await tester.tap(_bouton(L10n.current.studentGroupsCreateBtn));
    await reseau(tester);
    final d = faux.recues('POST', '/study-groups').single.data as Map;
    expect(d['name'], 'Mon groupe');
    expect(d['subject'], 'Maths');
    expect(faux.recues('GET', '/study-groups/me'), hasLength(2));
  });

  testWidgets('quitter un groupe : confirmation puis appel serveur et rechargement', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': [_groupe]});
    faux.repond('DELETE', '/study-groups/1/leave', {});
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.tap(_bouton(L10n.current.studentGroupsLeave));
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.studentGroupsLeaveOwner('Groupe maths')), findsOneWidget);
    await tester.tap(find.text(L10n.current.studentGroupsLeave).last);
    await reseau(tester);
    expect(faux.recues('DELETE', '/study-groups/1/leave'), hasLength(1));
  });

  testWidgets('quitter puis annuler : aucun appel', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': [_groupe]});
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.tap(_bouton(L10n.current.studentGroupsLeave));
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(L10n.current.commonCancel));
    await reseau(tester);
    expect(faux.recues('DELETE', '/study-groups/1/leave'), isEmpty);
  });

  testWidgets('detail : membres, code d\'invitation et classement de la semaine', (tester) async {
    faux.repond('GET', '/study-groups/me', {'data': [_groupe]});
    faux.repond('GET', '/study-groups/1', {
      'data': {
        'id': 1,
        'name': 'Groupe maths',
        'joinCode': 'ABC123',
        'members': [
          {'userId': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'role': 'owner'},
          {'userId': 2, 'firstName': 'Bob', 'lastName': 'Nku', 'role': 'member'},
        ],
      },
    });
    faux.repond('GET', '/study-groups/1/leaderboard', {
      'data': {
        'periodDays': 7,
        'ranking': [
          {'userId': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'quizzesPassed': 3, 'studyMinutes': 90, 'points': 40},
        ],
      },
    });
    await monterEcran(tester, const StudyGroupsScreen());
    await tester.tap(_bouton(L10n.current.studentHomeSee));
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.studentGroupsMembersCount(2)), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Bob Nku'), findsOneWidget);
    expect(find.text(l.studentGroupsRankLine(3, 90)), findsOneWidget);
  });
}
