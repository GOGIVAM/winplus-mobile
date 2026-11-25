import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/album_tab.dart';
import 'package:winplus/parent/goal_proposal_tab.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

const _enfant = ApiChild(id: 4, firstName: 'Zoe', lastName: 'Eto');

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boites en memoire : une ecriture sur disque lancee pendant un test ne
    // se termine jamais dans son temps simule et bloquerait le test suivant.
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await Hive.openBox(LocalCacheService.reportsBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
    await LocalCacheService.reports.clear();
  });

  group('AlbumTab', () {
    testWidgets('album non genere (404) : message dedie', (tester) async {
      faux.repond('GET', '/parent-reports/4/album', {}, statut: 404);
      telephone(tester);
      await monter(tester, ecran(const Scaffold(body: AlbumTab(child: _enfant))));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      expect(find.text(L10n.current.parentAlbumNotGenerated('Zoe')), findsOneWidget);
    });

    testWidgets('serveur en panne : erreur et Reessayer, pas « album non genere »', (tester) async {
      faux.repond('GET', '/parent-reports/4/album', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const Scaffold(body: AlbumTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text(l.commonLoadError), findsOneWidget);
      expect(find.text(l.parentAlbumNotGenerated('Zoe')), findsNothing);
      faux.repond('GET', '/parent-reports/4/album', {}, statut: 404);
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.parentAlbumNotGenerated('Zoe')), findsOneWidget);
    });

    testWidgets('album complet : titre, annee, rubriques et listes', (tester) async {
      faux.repond('GET', '/parent-reports/4/album', {
        'schoolYear': '2025-2026',
        'subjectsWorked': 'Maths et physique',
        'progression': 'Belle progression',
        'topContents': ['Algebre', 'Optique'],
        'goalsSummary': '2 objectifs atteints',
        'intensityWeeks': ['Semaine 3'],
        'bulletin': 'Bon trimestre',
        'updatedAt': '2026-06-01T10:00:00',
      });
      await monterEcran(tester, const Scaffold(body: AlbumTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text(l.parentAlbumTitle('Zoe')), findsOneWidget);
      expect(find.text(l.parentAlbumMeta('2025-2026', '01/06/2026')), findsOneWidget);
      expect(find.text('Maths et physique'), findsOneWidget);
      expect(find.text('Algebre'), findsOneWidget);
      expect(find.text('Optique'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Bon trimestre'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Bon trimestre'), findsOneWidget);
    });

    testWidgets('album partiel : seules les rubriques renseignees sont affichees', (tester) async {
      faux.repond('GET', '/parent-reports/4/album', {'progression': 'Stable', 'updatedAt': '2026-06-01T10:00:00'});
      await monterEcran(tester, const Scaffold(body: AlbumTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text('Stable'), findsOneWidget);
      expect(find.text(l.parentAlbumSubjects.toUpperCase()), findsNothing);
      expect(find.text(l.parentAlbumReportCard.toUpperCase()), findsNothing);
    });
  });

  group('GoalProposalTab', () {
    Map<String, dynamic> objectifs() => {
          'data': [
            {'goalId': 1, 'title': 'Reviser les maths', 'status': 'Pending', 'targetDate': '2026-05-01T00:00:00Z', 'description': 'Chaque soir'},
            {'goalId': 2, 'title': 'Lire un livre', 'status': 'Active', 'proposedByUserId': 9, 'targetDate': '2026-06-01T00:00:00Z'},
            {'goalId': 3, 'title': 'Objectif propre a l\'eleve', 'status': 'Active', 'targetDate': '2026-06-01T00:00:00Z'},
          ],
        };

    testWidgets('objectifs en attente et actifs proposes par le parent', (tester) async {
      faux.repond('GET', '/parent/children/4/goals', objectifs());
      await monterEcran(tester, const Scaffold(body: GoalProposalTab(child: _enfant)));
      final l = L10n.current;
      expect(find.text(l.parentGoalProposeTo('Zoe')), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lire un livre'), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text('Reviser les maths'), findsOneWidget);
      expect(find.text('Chaque soir'), findsOneWidget);
      expect(find.text('Lire un livre'), findsOneWidget);
      expect(find.text('Objectif propre a l\'eleve'), findsNothing, reason: 'non propose par un parent');
      expect(find.text(l.parentGoalNoPending), findsNothing);
    });

    testWidgets('aucun objectif : messages « aucun en attente » et « aucun actif »', (tester) async {
      faux.repond('GET', '/parent/children/4/goals', {'data': []});
      await monterEcran(tester, const Scaffold(body: GoalProposalTab(child: _enfant)));
      final l = L10n.current;
      await tester.scrollUntilVisible(find.text(l.parentGoalNoActive), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.parentGoalNoPending), findsOneWidget);
      expect(find.text(l.parentGoalNoActive), findsOneWidget);
    });

    testWidgets('proposition sans titre ni echeance : message et aucun envoi', (tester) async {
      faux.repond('GET', '/parent/children/4/goals', {'data': []});
      await monterEcran(tester, const Scaffold(body: GoalProposalTab(child: _enfant)));
      final b = find.widgetWithText(WinButton, L10n.current.parentGoalSubmit);
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      expect(find.text(L10n.current.studentGoalsRequired), findsOneWidget);
      expect(faux.requetes.where((r) => r.method == 'POST'), isEmpty);
    });
  });
}
