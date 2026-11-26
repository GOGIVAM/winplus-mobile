import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/course_stats_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : suivi des leçons et ludification d'une formation.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes({bool actif = true}) {
    faux.repond('GET', '/teacher/courses/12/gamification', {
      'gamificationEnabled': actif, 'pointsPerLesson': 10, 'pointsPerQuiz': 20, 'pointsBonusPerfectScore': 10, 'leaderboardVisible': true,
    });
    faux.repond('GET', '/teacher/courses/12/leaderboard', [
      {'rank': 1, 'userId': 30, 'name': 'Paul Eto', 'points': 120},
    ]);
    faux.repond('GET', '/teacher/courses/12/analytics/lessons', [
      {'lessonId': 1, 'title': 'Introduction', 'lessonType': 'video', 'completionRate': 80.0, 'completedCount': 8, 'averageWatchTimeSec': 600, 'lowCompletionAlert': false},
      {'lessonId': 2, 'title': 'Exercices', 'lessonType': 'article', 'completionRate': 25.0, 'completedCount': 2, 'averageWatchTimeSec': 0, 'averageQuizScore': 60.0, 'lowCompletionAlert': true},
    ]);
  }

  testWidgets('lecons : completion, visionnage, score sur 20 ; classement', (tester) async {
    routes();
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const CourseStatsScreen(courseId: 12, title: 'Algebre'));
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    expect(find.text('80 %'), findsOneWidget);
    expect(find.text('${l.cstatCompleted(8)} · ${l.cstatWatch(10)}'), findsOneWidget);
    expect(find.text('${l.cstatCompleted(2)} · ${l.cstatQuiz('12.0 / 20')}'), findsOneWidget);
    expect(find.text('Paul Eto'), findsOneWidget);
    expect(find.text(l.cstatPoints(120)), findsOneWidget);
  });

  testWidgets('reglages : augmenter les points envoie le nouveau reglage', (tester) async {
    routes();
    faux.repond('PUT', '/teacher/courses/12/gamification', {
      'gamificationEnabled': true, 'pointsPerLesson': 15, 'pointsPerQuiz': 20, 'pointsBonusPerfectScore': 10, 'leaderboardVisible': true,
    });
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const CourseStatsScreen(courseId: 12, title: 'Algebre'));
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
    final l = L10n.current;
    await tester.tap(find.byTooltip('${l.cstatPerLesson} +'));
    await reseau(tester);
    expect((faux.recues('PUT', '/teacher/courses/12/gamification').single.data as Map)['pointsPerLesson'], 15);
    expect(find.text(l.cstatSaved), findsOneWidget);
  });

  testWidgets('ludification coupee : pas de classement', (tester) async {
    routes(actif: false);
    await monterEcran(tester, const CourseStatsScreen(courseId: 12, title: 'Algebre'));
    expect(find.text(L10n.current.cstatBoard), findsNothing);
  });
}
