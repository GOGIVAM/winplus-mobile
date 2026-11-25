import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/tutor_coaching_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : coaching WinAI du répétiteur (rapport mensuel, fiches par élève).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> rapport() => {
        'id': 3, 'tutorUserId': 50, 'monthLabel': 'Novembre 2026', 'generatedAt': '2026-11-20T08:00:00Z',
        'content': jsonEncode({
          'strengths': ['Explications claires'],
          'subjects_improving': ['Maths'],
          'stagnation_patterns': ['Retards en debut de seance'],
          'recommendations': ['Preparer un plan de seance'],
          'report_text': 'Bon mois dans l ensemble.',
        }),
      };

  void eleves() => faux.repond('GET', '/tutor-insights/students', [
        {'studentUserId': 30, 'studentName': 'Paul Eto', 'sessionsCount': 3, 'lastSubject': 'Maths'},
      ]);

  testWidgets('rapport : texte et quatre blocs ; eleves suivis', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', rapport());
    eleves();
    await monterEcran(tester, const TutorCoachingScreen());
    final l = L10n.current;
    expect(find.text('Novembre 2026'), findsOneWidget);
    expect(find.text('Bon mois dans l ensemble.'), findsOneWidget);
    expect(find.text(l.coachStrengths), findsOneWidget);
    expect(find.text('Explications claires'), findsOneWidget);
    expect(find.text('Preparer un plan de seance'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Paul Eto'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('${l.coachSessions(3)} · Maths'), findsOneWidget);
  });

  testWidgets('pas de rapport (404) : generer maintenant ; refus du serveur affiche', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', null, statut: 404);
    faux.repond('GET', '/tutor-insights/students', []);
    faux.repond('POST', '/tutor-insights/coaching-report/generate-now',
        {'message': 'Pas encore assez de seances.'}, statut: 400);
    await monterEcran(tester, const TutorCoachingScreen());
    final l = L10n.current;
    expect(find.text(l.coachEmptyTitle), findsOneWidget);
    expect(find.text(l.coachNoStudents), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.coachGenerateNow));
    await reseau(tester);
    expect(find.text('Pas encore assez de seances.'), findsOneWidget);
    faux.repond('POST', '/tutor-insights/coaching-report/generate-now', rapport());
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.widgetWithText(WinButton, l.coachGenerateNow));
    await reseau(tester);
    expect(find.text('Explications claires'), findsOneWidget);
    expect(find.text(l.coachGenerated), findsOneWidget);
  });

  testWidgets('limite WinAI (402) : message du serveur', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', null, statut: 404);
    faux.repond('GET', '/tutor-insights/students', []);
    faux.repond('POST', '/tutor-insights/coaching-report/generate-now',
        {'error': 'Limite WinAI atteinte.', 'code': 'ai_quota_exceeded'}, statut: 402);
    await monterEcran(tester, const TutorCoachingScreen());
    await tester.tap(find.widgetWithText(WinButton, L10n.current.coachGenerateNow));
    await reseau(tester);
    expect(find.text('Limite WinAI atteinte.'), findsOneWidget);
  });

  testWidgets('fiche : generer, modifier, enregistrer, envoyer et copier', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', rapport());
    eleves();
    faux.repond('GET', '/tutor-insights/revision-sheet/30', null, statut: 404);
    faux.repond('POST', '/tutor-insights/revision-sheet/30/generate',
        {'priority_topics': ['Derivees'], 'sheet_text': 'Revoir les derivees.'});
    faux.repond('PUT', '/tutor-insights/revision-sheet/30', {'id': 1, 'content': 'x'});
    faux.repond('POST', '/messages/conversations', {'conversationId': 30, 'messageId': 9});
    await monterEcran(tester, const TutorCoachingScreen());
    final l = L10n.current;
    await tester.scrollUntilVisible(find.text('Paul Eto'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Paul Eto'));
    await reseau(tester);
    await tester.tap(find.widgetWithText(WinButton, l.coachSheetGenerate));
    await reseau(tester);
    expect(find.text('Revoir les derivees.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Revoir les derivees et les limites.');
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.coachSheetSave));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-insights/revision-sheet/30').single.data,
        {'subject': 'Maths', 'content': 'Revoir les derivees et les limites.'});
    expect(find.text(l.coachSheetSaved), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.widgetWithText(WinButton, l.coachSheetSend));
    await reseau(tester);
    final envoi = faux.recues('POST', '/messages/conversations').single.data as Map;
    expect(envoi['participantId'], 30);
    expect(envoi['firstMessage'], contains('Revoir les derivees et les limites.'));
    expect(find.text(l.coachSheetSent('Paul Eto')), findsOneWidget);

    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copie = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.widgetWithText(WinButton, l.coachSheetCopy));
    await reseau(tester);
    expect(copie, 'Revoir les derivees et les limites.');
  });

  testWidgets('fiche deja enregistree : affichee directement', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', rapport());
    eleves();
    faux.repond('GET', '/tutor-insights/revision-sheet/30', {'id': 1, 'content': 'Fiche enregistree.'});
    await monterEcran(tester, const TutorCoachingScreen());
    await tester.scrollUntilVisible(find.text('Paul Eto'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Paul Eto'));
    await reseau(tester);
    expect(find.text('Fiche enregistree.'), findsOneWidget);
    expect(find.widgetWithText(WinButton, L10n.current.coachSheetGenerate), findsNothing);
  });

  testWidgets('panne : erreur', (tester) async {
    faux.repond('GET', '/tutor-insights/coaching-report/latest', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const TutorCoachingScreen());
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
  });
}
