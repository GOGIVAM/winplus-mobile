import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/teacher_links_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({List<Map<String, dynamic>> attente = const [], List<Map<String, dynamic>> liens = const []}) {
    faux.repond('GET', '/teacher-links/pending', attente);
    faux.repond('GET', '/teacher-links/mine', liens);
  }

  testWidgets('chargement puis onglets « en attente » (avec compteur) et « lies »', (tester) async {
    routes(attente: [
      {'id': 1, 'initiator': {'firstName': 'Ada', 'lastName': 'Eto'}},
    ]);
    telephone(tester);
    await monter(tester, ecran(const TeacherLinksScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('${l.commonPending} (1)'), findsOneWidget);
    expect(find.text(l.teacherLinksLinkedTab), findsOneWidget);
    expect(find.text('Ada Eto'), findsOneWidget);
  });

  testWidgets('aucune invitation : message dedie', (tester) async {
    routes();
    await monterEcran(tester, const TeacherLinksScreen());
    expect(find.text(L10n.current.teacherLinksNoPending), findsOneWidget);
  });

  testWidgets('accepter ou refuser une invitation appelle la bonne route puis recharge', (tester) async {
    routes(attente: [
      {'id': 1, 'initiator': {'firstName': 'Ada', 'lastName': 'Eto'}},
    ]);
    faux.repond('PUT', '/teacher-links/1/accept', {});
    faux.repond('PUT', '/teacher-links/1/reject', {});
    await monterEcran(tester, const TeacherLinksScreen());
    await tester.tap(find.byIcon(PhosphorIconsBold.check));
    await reseau(tester);
    expect(faux.recues('PUT', '/teacher-links/1/accept'), hasLength(1));
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await reseau(tester);
    expect(faux.recues('PUT', '/teacher-links/1/reject'), hasLength(1));
    expect(faux.recues('GET', '/teacher-links/pending'), hasLength(3));
  });

  testWidgets('onglet « lies » : liens existants et suppression', (tester) async {
    routes(liens: [
      {'id': 7, 'other': {'firstName': 'Paul', 'lastName': 'Nkoa'}},
    ]);
    faux.repond('DELETE', '/teacher-links/7', {});
    await monterEcran(tester, const TeacherLinksScreen());
    await tester.tap(find.text(L10n.current.teacherLinksLinkedTab));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text('Paul Nkoa'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.linkBreak));
    await reseau(tester);
    expect(faux.recues('DELETE', '/teacher-links/7'), hasLength(1));
  });

  testWidgets('onglet « lies » vide : message dedie', (tester) async {
    routes();
    await monterEcran(tester, const TeacherLinksScreen());
    await tester.tap(find.text(L10n.current.teacherLinksLinkedTab));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.teacherLinksNoLinked), findsOneWidget);
  });

  testWidgets('recherche : moins de 3 caracteres = aucun appel ; sinon resultats (sans e-mail, retire par le serveur) avec invitation', (tester) async {
    routes();
    faux.repond('GET', '/teacher-links/search', [
      {'id': 9, 'firstName': 'Zoe', 'lastName': 'Mba'},
    ]);
    faux.repond('POST', '/teacher-links/invite', {});
    await monterEcran(tester, const TeacherLinksScreen());
    await tester.enterText(find.byType(TextField), 'zo');
    await reseau(tester);
    expect(faux.recues('GET', '/teacher-links/search'), isEmpty);
    await tester.enterText(find.byType(TextField), 'zoe');
    await reseau(tester);
    expect(faux.recues('GET', '/teacher-links/search').single.queryParameters, {'q': 'zoe'});
    expect(find.text('Zoe Mba'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsFill.userPlus));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher-links/invite').single.data, {'targetUserId': 9});
    expect(find.text(L10n.current.teacherLinksInviteSent), findsOneWidget);
    expect(find.text('Zoe Mba'), findsNothing);
  });
}
