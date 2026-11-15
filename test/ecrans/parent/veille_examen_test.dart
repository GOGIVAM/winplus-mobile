import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/exam_watch_mode_tab.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

const _enfant = ApiChild(id: 4, firstName: 'Zoe', lastName: 'Eto');

Widget _onglet() => const Scaffold(body: ExamWatchModeTab(child: _enfant));

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('chargement puis formulaire quand aucune veille n\'existe', (tester) async {
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': false});
    telephone(tester);
    await monter(tester, ecran(_onglet()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('${l.parentWatchTitle}  Zoe'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l.studentCoachPickDate), findsOneWidget);
  });

  testWidgets('erreur de lecture : traitee comme « pas de veille »', (tester) async {
    faux.repond('GET', '/exam-coach/4/watch-mode', {}, statut: 500);
    await monterEcran(tester, _onglet());
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('formulaire incomplet : message et aucun envoi', (tester) async {
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': false});
    await monterEcran(tester, _onglet());
    await tester.tap(find.widgetWithText(WinButton, L10n.current.parentWatchActivate));
    await reseau(tester);
    expect(find.text(L10n.current.parentWatchFormRequired), findsOneWidget);
    expect(faux.recues('POST', '/exam-coach/4/watch-mode'), isEmpty);
  });

  testWidgets('veille active : examen, compte a rebours et desactivation', (tester) async {
    final date = DateTime.now().add(const Duration(days: 10, hours: 12)).toUtc().toIso8601String();
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': true, 'examType': 'BAC', 'examDate': date});
    faux.repond('DELETE', '/exam-coach/4/watch-mode', {});
    await monterEcran(tester, _onglet());
    final l = L10n.current;
    expect(find.text('BAC'), findsOneWidget);
    expect(find.text(l.parentWatchCountdown(10)), findsOneWidget);
    expect(find.text(l.parentWatchBeforeExam), findsOneWidget);
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': false});
    await tester.tap(find.widgetWithText(WinButton, l.parentWatchDeactivate));
    await reseau(tester);
    expect(faux.recues('DELETE', '/exam-coach/4/watch-mode'), hasLength(1));
    expect(find.text('BAC'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('plan existant non surveille : un bouton active la veille sans formulaire', (tester) async {
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': false, 'examType': 'BEPC', 'examDate': '2026-06-15T00:00:00Z'});
    faux.repond('POST', '/exam-coach/4/watch-mode', {'active': true, 'examType': 'BEPC', 'examDate': '2026-06-15T00:00:00Z'});
    await monterEcran(tester, _onglet());
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.widgetWithText(WinButton, L10n.current.parentWatchActivate));
    await reseau(tester);
    expect(faux.recues('POST', '/exam-coach/4/watch-mode').single.data, {'hoursPerDay': 2.0});
    expect(find.widgetWithText(WinButton, L10n.current.parentWatchDeactivate), findsOneWidget);
  });

  testWidgets('echec d\'activation : message d\'erreur', (tester) async {
    faux.repond('GET', '/exam-coach/4/watch-mode', {'active': false, 'examType': 'BEPC', 'examDate': '2026-06-15T00:00:00Z'});
    await monterEcran(tester, _onglet());
    await tester.tap(find.widgetWithText(WinButton, L10n.current.parentWatchActivate));
    await reseau(tester);
    expect(find.text(L10n.current.parentWatchActivateError), findsOneWidget);
  });
}
