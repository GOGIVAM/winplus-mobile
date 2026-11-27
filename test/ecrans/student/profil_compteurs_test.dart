import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/profile_hub_tab.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Profil de l'eleve : les sous-titres des tuiles Badges, Certificats et
/// Groupes donnent les vrais nombres (ils etaient ecrits en dur : 14, 2, 3).
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes() {
    faux.repond('GET', '/users/profile/statistics', {'currentStreak': 0});
    faux.repond('GET', '/badges', {
      'data': [
        {'code': 'a', 'title': 'A', 'unlocked': true},
        {'code': 'b', 'title': 'B', 'unlocked': false},
        {'code': 'c', 'title': 'C', 'unlocked': false},
      ],
    });
    faux.repond('GET', '/my-course-certificates', [
      {'id': 1, 'courseId': 3, 'courseTitle': 'Algebre', 'certificateNumber': 'C-1'},
    ]);
    faux.repond('GET', '/certificates/user/my-certificates', {'data': []});
    faux.repond('GET', '/study-groups/me', {
      'data': [
        {'id': 4, 'name': 'Maths Tle', 'subject': 'Maths', 'inviteCode': 'X1'},
      ],
    });
  }

  testWidgets('compteurs reels : 1 badge sur 3, 1 certificat (formation), 1 groupe', (tester) async {
    routes();
    await monterEcran(tester, const ProfileHubTab());
    final l = L10n.current;
    expect(find.text(l.studentHubBadgesCount(1, 3)), findsOneWidget);
    expect(find.text(l.studentHubCertificatesCount(1)), findsOneWidget);
    expect(find.text(l.studentHubGroupsCount(1)), findsOneWidget);
    expect(find.text('14 débloqués'), findsNothing);
  });

  testWidgets('routes en panne : sous-titres generaux, jamais de faux nombre', (tester) async {
    faux.repond('GET', '/badges', {}, statut: 500);
    faux.repond('GET', '/certificates/user/my-certificates', {}, statut: 500);
    faux.repond('GET', '/study-groups/me', {}, statut: 500);
    await monterEcran(tester, const ProfileHubTab());
    final l = L10n.current;
    expect(find.text(l.studentHubBadgesSub), findsOneWidget);
    expect(find.text(l.studentHubCertificatesSub), findsOneWidget);
    expect(find.text(l.studentHubGroupsSub), findsOneWidget);
  });

  testWidgets('aucun certificat ni groupe : le dit en clair', (tester) async {
    routes();
    faux.repond('GET', '/my-course-certificates', []);
    faux.repond('GET', '/study-groups/me', {'data': []});
    await monterEcran(tester, const ProfileHubTab());
    final l = L10n.current;
    expect(find.text(l.studentHubCertificatesCount(0)), findsOneWidget);
    expect(find.text(l.studentHubGroupsCount(0)), findsOneWidget);
  });
}
