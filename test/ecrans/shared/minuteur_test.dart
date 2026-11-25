import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/study_timer_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  setUp(() => preparerEnvironnement());

  testWidgets('etat initial : 25:00, mode Pomodoro et compteur a zero', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    final l = L10n.current;
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text(l.timerTitle), findsOneWidget);
    // Puce de mode et libelle sous le chronometre.
    expect(find.text(l.timerModePomodoro), findsNWidgets(2));
    expect(find.text(l.timerTodayCount(0)), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.play), findsOneWidget);
  });

  testWidgets('demarrer : le temps s\'ecoule seconde par seconde, pause l\'arrete', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    await tester.tap(find.byIcon(PhosphorIconsFill.play));
    await pomper(tester, const Duration(seconds: 3));
    expect(find.text('24:57'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.pause), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsFill.pause));
    await pomper(tester);
    await pomper(tester, const Duration(seconds: 5));
    expect(find.text('24:57'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.play), findsOneWidget);
    await monter(tester, const SizedBox());
  });

  testWidgets('reinitialiser remet la duree du mode et arrete le minuteur', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    await tester.tap(find.byIcon(PhosphorIconsFill.play));
    await pomper(tester, const Duration(seconds: 2));
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
    await pomper(tester);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.play), findsOneWidget);
    await monter(tester, const SizedBox());
  });

  testWidgets('changer de mode : pause courte 05:00, pause longue 15:00', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    await tester.tap(find.text(L10n.current.timerModeShortBreak));
    await pomper(tester);
    expect(find.text('05:00'), findsOneWidget);
    await tester.tap(find.text(L10n.current.timerModeLongBreak));
    await pomper(tester);
    expect(find.text('15:00'), findsOneWidget);
    await tester.tap(find.text(L10n.current.timerModePomodoro));
    await pomper(tester);
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('changer de mode en cours de minuteur l\'arrete', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    await tester.tap(find.byIcon(PhosphorIconsFill.play));
    await pomper(tester, const Duration(seconds: 2));
    await tester.tap(find.text(L10n.current.timerModeShortBreak));
    await pomper(tester);
    expect(find.byIcon(PhosphorIconsFill.play), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('fin d\'une pause courte : boite de dialogue « retour au travail » puis nouveau pomodoro', (tester) async {
    await monterEcran(tester, const StudyTimerScreen());
    await tester.tap(find.text(L10n.current.timerModeShortBreak));
    await pomper(tester);
    await tester.tap(find.byIcon(PhosphorIconsFill.play));
    await pomper(tester, const Duration(seconds: 301));
    final l = L10n.current;
    expect(find.text(l.timerBreakDone), findsOneWidget);
    expect(find.text(l.timerBackToWork), findsOneWidget);
    await tester.tap(find.text(l.timerNewPomodoro));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text(l.timerTodayCount(0)), findsOneWidget, reason: 'une pause ne compte pas comme un pomodoro');
  });
}
