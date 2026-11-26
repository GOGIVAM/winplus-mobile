import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/student_home.dart';
import 'package:winplus/widgets/mobile_home.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

String _ilYa(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

/// Accueil de l'eleve (MobileHomeView, comme la version telephone du site) :
/// recherche, « Pour toi », acces rapide, bande de chiffres (moyenne, etude,
/// quiz, serie, badges, offre), autres contenus commences et echeances.
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>> encours = const [],
    List<Map<String, dynamic>> echeances = const [],
    int serie = 0,
    List<Map<String, dynamic>> badges = const [],
  }) {
    faux.repond('GET', '/users/me', {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto'});
    faux.repond('GET', '/student/stats', {'data': stats ?? {}});
    faux.repond('GET', '/student/learning/continue', {'data': encours});
    faux.repond('GET', '/student/events/upcoming', {'data': echeances});
    faux.repond('GET', '/users/profile/statistics', {'currentStreak': serie});
    faux.repond('GET', '/badges', {'data': badges});
  }

  /// Ecran haut : les blocs du bas sont construits sans defilement.
  Future<void> monterHaut(WidgetTester tester, {Widget ecranEleve = const StudentHomeTab()}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(ecranEleve));
    await reseau(tester);
  }

  /// Fait defiler la bande des chiffres jusqu'a [cible].
  Future<void> chiffre(WidgetTester tester, Finder cible) async {
    final bande = find.descendant(
      of: find.byType(MobileStatsStrip),
      matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right),
    );
    await tester.scrollUntilVisible(cible, 120, scrollable: bande.first);
  }

  testWidgets('avant la reponse du serveur : valeurs « — » et aucune section de donnees', (tester) async {
    telephone(tester);
    await monter(tester, ecran(const StudentHomeTab()));
    expect(find.text('—'), findsWidgets);
    expect(find.text(L10n.current.studentHomeContinue), findsNothing);
    expect(find.text(L10n.current.studentHomeUpcomingExams), findsNothing);
    await reseau(tester);
  });

  testWidgets('chiffres reels : moyenne, heures de la semaine, quiz, serie et badges debloques', (tester) async {
    routes(
      stats: {
        'averageScore': 74.4,
        'weeklyQuizCompleted': 5,
        'weeklyStudyHours': [1.0, 2.0, 0.5],
      },
      serie: 4,
      badges: [
        {'code': 'a', 'title': 'A', 'unlocked': true},
        {'code': 'b', 'title': 'B', 'unlocked': true},
        {'code': 'c', 'title': 'C', 'unlocked': false},
      ],
    );
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('14,9/20'), findsOneWidget);
    // 3,5 h d'etude : format commun des durees (lot 1).
    await chiffre(tester, find.text('3 h 30'));
    expect(find.text('3 h 30'), findsOneWidget);
    await chiffre(tester, find.text('5'));
    expect(find.text('5'), findsOneWidget);
    await chiffre(tester, find.text(l.mobileHomeDays(4)));
    expect(find.text(l.mobileHomeDays(4)), findsOneWidget);
    await chiffre(tester, find.text('2'));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('contenu commence : repris dans « Pour toi », les suivants dans « continuer »', (tester) async {
    routes(encours: [
      {'subjectId': 4, 'title': 'Algebre BAC', 'category': 'math', 'progress': 35},
      {'subjectId': 6, 'title': 'Optique', 'category': 'physics', 'progress': 60},
    ]);
    await monterHaut(tester);
    // Le plus recent est le sous-titre de la carte « Reprends la ou tu en etais ».
    expect(find.text('Algebre BAC', skipOffstage: false), findsOneWidget);
    expect(find.text(L10n.current.studentHomeContinue), findsOneWidget);
    expect(find.text('Optique'), findsOneWidget);
    expect(find.text(WinFormat.percent(60)), findsOneWidget);
  });

  testWidgets('un seul contenu commence : pas de section « continuer » en double', (tester) async {
    routes(encours: [
      {'subjectId': 4, 'title': 'Algebre BAC', 'progress': 35},
    ]);
    await monterHaut(tester);
    expect(find.text(L10n.current.studentHomeContinue), findsNothing);
  });

  testWidgets('ouvrir un contenu commence lit la fiche reelle ; echec = message', (tester) async {
    routes(encours: [
      {'subjectId': 4, 'title': 'Algebre BAC', 'progress': 35},
      {'subjectId': 6, 'title': 'Optique', 'progress': 60},
    ]);
    faux.repond('GET', '/subjects/6', {}, statut: 500);
    // Dans l'application l'onglet est dans la coquille, qui porte le Scaffold
    // ou s'affiche le message.
    await monterHaut(tester, ecranEleve: const Scaffold(body: StudentHomeTab()));
    await tester.tap(find.text('Optique'));
    await reseau(tester);
    expect(faux.recues('GET', '/subjects/6'), hasLength(1));
    expect(find.text(L10n.current.studentHomeOpenFailed), findsOneWidget);
  });

  testWidgets('echeances : au plus deux, avec le nombre de jours restants', (tester) async {
    routes(echeances: [
      {'title': 'BAC blanc', 'startDate': _ilYa(const Duration(days: 12, hours: 6))},
      {'title': 'Examen de physique', 'startDate': _ilYa(const Duration(days: 3, hours: 6))},
      {'title': 'Troisieme', 'startDate': _ilYa(const Duration(days: 20))},
    ]);
    await monterHaut(tester);
    expect(find.text(L10n.current.studentHomeUpcomingExams), findsOneWidget);
    expect(find.text('BAC blanc'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Troisieme'), findsNothing);
    expect(faux.recues('GET', '/student/events/upcoming').single.queryParameters, {'limit': 3});
  });

  testWidgets('sans abonnement : la carte offre invite a passer a une offre', (tester) async {
    routes();
    await monterHaut(tester);
    await chiffre(tester, find.text(L10n.current.studentHomeUpgrade));
    expect(find.text(L10n.current.studentHomeUpgrade), findsOneWidget);
  });

  testWidgets('avec un abonnement : nom du plan dans la carte offre, plus d\'invitation', (tester) async {
    routes();
    final abo = await abonnementAvecDroits(tester, faux, {'ai.feature.exam_coach': true}, plan: 'Premium');
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const StudentHomeTab(), abonnement: abo));
    await reseau(tester);
    await chiffre(tester, find.text('Premium'));
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text(L10n.current.studentHomeUpgrade), findsNothing);
  });

  testWidgets('serveur entierement en erreur : l\'accueil reste affiche avec des « — »', (tester) async {
    await monterHaut(tester);
    expect(find.text('—'), findsWidgets);
    expect(find.text(L10n.current.mobileHomeQuick), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('acces rapide : quiz, epreuves, revisions et groupes', (tester) async {
    routes();
    await monterHaut(tester);
    final l = L10n.current;
    for (final t in [l.mobileHomeQuiz, l.mobileHomePapers, l.mobileHomeRevisions, l.mobileHomeGroups]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });
}
