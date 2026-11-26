import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/winai/winai_exam.dart';
import 'package:winplus/shared/winai/winai_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Atelier WinAI du professeur : composer une epreuve complete (sujet,
/// bareme, corrige) et la retrouver dans « Mes epreuves ».
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  const epreuve = {
    'id': 5,
    'kind': 'epreuve',
    'title': 'Devoir : Pythagore',
    'subject': 'Maths',
    'level': '3e',
    'examType': 'devoir',
    'durationMinutes': 60,
    'totalPoints': 20,
    'exercises': [
      {
        'title': 'Calcul direct',
        'context': 'Un triangle rectangle.',
        'points': 4.5,
        'questions': [
          {'number': 1, 'statement': 'Calcule l hypotenuse.', 'points': 4.5, 'answer': 'Cinq centimetres.', 'scoringGuide': 'Formule puis calcul.'},
        ],
      },
    ],
  };

  Future<void> ouvrirAtelier(WidgetTester tester) async {
    await monterEcran(tester, const WinAIScreen(role: WinRole.teacher));
    await tester.tap(find.text(L10n.current.winaiTabStudio));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
  }

  // La feuille de reglages depasse l'ecran de test : on declenche le bouton
  // par le composant plutot que par un appui a l'ecran.
  Future<void> generer(WidgetTester tester) async {
    tester.widget<WinButton>(find.widgetWithText(WinButton, L10n.current.winaiSettingsGenerate, skipOffstage: false)).onTap!();
    await pomper(tester);
  }

  Future<void> voir(WidgetTester tester, String texte) async {
    await tester.scrollUntilVisible(find.text(texte), 200, scrollable: find.byType(Scrollable).last);
    await pomper(tester);
  }

  testWidgets('epreuve complete : matiere obligatoire, reglages envoyes, sujet affiche, corrige a la demande', (tester) async {
    faux.repond('POST', '/teacher/epreuves', {'success': true, 'data': epreuve}, statut: 201);
    await ouvrirAtelier(tester);
    final l = L10n.current;
    await voir(tester, l.winaiToolExam);
    await tester.tap(find.text(l.winaiToolExam));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));

    // Sans matiere : rien ne part.
    await generer(tester);
    await pomper(tester);
    expect(find.text(l.winaiExamSubjectRequired, skipOffstage: false), findsOneWidget);
    expect(faux.recues('POST', '/teacher/epreuves'), isEmpty);

    await tester.enterText(find.byType(TextField).first, 'Maths');
    tester.widget<WinChip>(find.widgetWithText(WinChip, l.winaiExamTypeMock, skipOffstage: false)).onTap!();
    await pomper(tester);
    await generer(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));

    final envoi = faux.recues('POST', '/teacher/epreuves').single.data as Map;
    expect(envoi['subject'], 'Maths');
    expect(envoi['examType'], 'examen-blanc');
    expect(envoi['durationMinutes'], 120);
    expect(envoi['totalPoints'], 20);
    expect(envoi['exercises'], 3);

    expect(find.byType(WinAIExamScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('Devoir : Pythagore'), findsOneWidget);
    expect(find.text('Calcul direct'), findsOneWidget);
    expect(find.text(l.winaiExamPointsShort('4,5')), findsNWidgets(2));
    // Le corrige reste cache tant que le professeur ne le demande pas.
    expect(find.text(l.winaiExamAnswer), findsNothing);
    await tester.tap(find.text(l.winaiExamShowAnswers));
    await pomper(tester);
    expect(find.text(l.winaiExamAnswer, skipOffstage: false), findsOneWidget);
    expect(find.text(l.winaiExamScoring, skipOffstage: false), findsOneWidget);
  });

  testWidgets('epreuve hors de l offre : message du serveur et acces aux offres', (tester) async {
    faux.repond('POST', '/teacher/epreuves',
        {'success': false, 'error': 'La generation d epreuves demande l offre Fondateur.', 'code': 'feature_not_in_plan'}, statut: 403);
    await ouvrirAtelier(tester);
    final l = L10n.current;
    await voir(tester, l.winaiToolExam);
    await tester.tap(find.text(l.winaiToolExam));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).first, 'Maths');
    await generer(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.byType(WinAIExamScreen, skipOffstage: false), findsNothing);
    expect(find.text('La generation d epreuves demande l offre Fondateur.'), findsOneWidget);
    expect(find.text(l.winaiStudioSeePlans), findsOneWidget);
  });

  testWidgets('« Mes epreuves » : liste, ouverture d une epreuve, suppression confirmee', (tester) async {
    faux.repond('GET', '/teacher/epreuves', {'data': [{'id': 5, 'title': 'Devoir : Pythagore', 'examType': 'devoir'}]});
    faux.repond('GET', '/teacher/epreuves/5', {'data': epreuve});
    faux.repond('DELETE', '/teacher/epreuves/5', {'success': true});
    await monterEcran(tester, const WinAIExamsScreen());
    await reseau(tester);
    await pomper(tester);
    final l = L10n.current;
    expect(find.text('Devoir : Pythagore'), findsOneWidget);
    await tester.tap(find.text('Devoir : Pythagore'));
    await pomper(tester);
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text('Calcul direct'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip(l.commonDelete));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(l.commonDelete));
    await pomper(tester);
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(faux.recues('DELETE', '/teacher/epreuves/5'), hasLength(1));
    expect(find.text(l.winaiExamsEmpty), findsOneWidget);
  });
}
