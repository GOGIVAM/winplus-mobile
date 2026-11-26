import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/course_stats_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Suivi d'une formation publiée (lot 7, refait au lot 8 : Georges le
/// jugeait trop sommaire) : leçons, élèves inactifs et relance WinAI,
/// points et classement.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes({bool actif = true, List<Map<String, Object>>? inactifs}) {
    faux.repond('GET', '/teacher/courses/12/gamification', {
      'gamificationEnabled': actif, 'pointsPerLesson': 10, 'pointsPerQuiz': 20, 'pointsBonusPerfectScore': 10, 'leaderboardVisible': true,
    });
    faux.repond('GET', '/teacher/courses/12/leaderboard', [
      {'rank': 1, 'userId': 30, 'name': 'Paul Eto', 'points': 120},
    ]);
    faux.repond('GET', '/teacher/courses/12/analytics/lessons', [
      {'lessonId': 1, 'title': 'Introduction', 'lessonType': 'video', 'completionRate': 80.0, 'completedCount': 8, 'enrolledCount': 10, 'averageWatchTimeSec': 600, 'lowCompletionAlert': false},
      {'lessonId': 2, 'title': 'Exercices', 'lessonType': 'article', 'completionRate': 25.0, 'completedCount': 2, 'enrolledCount': 10, 'averageWatchTimeSec': 0, 'averageQuizScore': 60.0, 'lowCompletionAlert': true},
    ]);
    faux.repond('GET', '/teacher/courses/12/inactive-students', inactifs ??
        [
          {'userId': 40, 'name': 'Zoe Ndi', 'lastActivity': '2026-11-10T08:00:00Z', 'daysInactive': 16},
          {'userId': 41, 'name': 'Leo Mba', 'daysInactive': 9},
        ]);
    faux.repond('GET', '/teacher/courses/12/relaunch-stats', {'totalSent': 4, 'reactivatedCount': 1, 'reactivationRate': 25.0});
    faux.repond('GET', '/teacher/courses/12', {'id': 12, 'inactivityThresholdDays': 7});
  }

  Future<void> monterGrand(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const CourseStatsScreen(courseId: 12, title: 'Algebre'));
    tester.view.physicalSize = const Size(800, 3000);
    await reseau(tester);
  }

  testWidgets('lecons : chiffres cles, decrochage, parcours lecon par lecon', (tester) async {
    routes();
    await monterGrand(tester);
    final l = L10n.current;
    expect(find.text('10'), findsOneWidget, reason: 'inscrits');
    expect(find.text(WinFormat.percent(53)), findsOneWidget, reason: 'completion moyenne (80 + 25) / 2');
    expect(find.text('12/20'), findsOneWidget, reason: 'score moyen des quiz');
    expect(find.text('${l.cstatDropTitle} : ${l.cstatDropText(6, 'Introduction', 'Exercices')}'), findsOneWidget);
    expect(find.text(l.cstatLessonOf(8, 10)), findsOneWidget);
    expect(find.text(l.cstatWatch('10 min')), findsOneWidget);
    expect(find.text(l.cstatQuiz('12/20')), findsOneWidget);
    expect(find.text(l.cstatReviewBadge), findsOneWidget);
  });

  testWidgets('eleves : inactifs, seuil, relance WinAI des eleves choisis', (tester) async {
    routes();
    faux.repond('POST', '/teacher/courses/12/relaunch-students', {'sent': 1, 'message': 'On continue ?'});
    await monterGrand(tester);
    final l = L10n.current;
    await tester.tap(find.text('${l.cstatTabStudents} (2)'));
    await pomper(tester);
    expect(find.text('Zoe Ndi'), findsOneWidget);
    expect(find.text(l.cstatRelaunchStats(4, '25')), findsOneWidget);
    await tester.tap(find.text('Zoe Ndi'));
    await pomper(tester);
    await tester.tap(find.text(l.cstatRelaunch(1)));
    await pomper(tester);
    await tester.tap(find.text(l.commonConfirm));
    await reseau(tester);
    expect((faux.recues('POST', '/teacher/courses/12/relaunch-students').single.data as Map)['userIds'], [40]);
    expect(find.text('On continue ?'), findsOneWidget, reason: 'message envoye montre au professeur');
  });

  testWidgets('eleves : changer le seuil l\'enregistre et relit les inactifs', (tester) async {
    routes();
    faux.repond('PUT', '/teacher/courses/12/inactivity-threshold', {'inactivityThresholdDays': 14});
    await monterGrand(tester);
    final l = L10n.current;
    await tester.tap(find.text('${l.cstatTabStudents} (2)'));
    await pomper(tester);
    await tester.tap(find.text(l.cstatDays(14)));
    await reseau(tester);
    expect((faux.recues('PUT', '/teacher/courses/12/inactivity-threshold').single.data as Map)['days'], 14);
    expect(faux.recues('GET', '/teacher/courses/12/inactive-students'), hasLength(2));
  });

  testWidgets('points : augmenter les points envoie le nouveau reglage ; classement', (tester) async {
    routes();
    faux.repond('PUT', '/teacher/courses/12/gamification', {
      'gamificationEnabled': true, 'pointsPerLesson': 15, 'pointsPerQuiz': 20, 'pointsBonusPerfectScore': 10, 'leaderboardVisible': true,
    });
    await monterGrand(tester);
    final l = L10n.current;
    await tester.tap(find.text(l.cstatTabPoints));
    await pomper(tester);
    expect(find.text('Paul Eto'), findsOneWidget);
    expect(find.text(l.cstatPoints(120)), findsOneWidget);
    await tester.tap(find.byTooltip('${l.cstatPerLesson} +'));
    await reseau(tester);
    expect((faux.recues('PUT', '/teacher/courses/12/gamification').single.data as Map)['pointsPerLesson'], 15);
  });

  testWidgets('ludification coupee : pas de classement', (tester) async {
    routes(actif: false);
    await monterGrand(tester);
    await tester.tap(find.text(L10n.current.cstatTabPoints));
    await pomper(tester);
    expect(find.text(L10n.current.cstatBoard), findsNothing);
  });
}
