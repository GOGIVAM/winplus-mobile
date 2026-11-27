import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/course_editor_service.dart';
import 'package:winplus/teacher/course_editor_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : éditeur de formation du professeur (chapitres, leçons, ordre,
/// programme WinAI, soumission).
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> formation({String status = 'draft', List sections = const []}) => {
        'id': 12, 'title': 'Algebre', 'status': status, 'level': 'debutant', 'category': 'Informatique',
        'price': 5000, 'isFree': false, 'sections': sections,
      };

  List deuxChapitres() => [
        {
          'id': 1, 'title': 'Chapitre 1', 'position': 0, 'unlockRule': 'immediate',
          'lessons': [
            {'id': 10, 'title': 'Introduction', 'lessonType': 'video', 'videoUrl': 'https://v.cm/1', 'isPublished': true, 'position': 0},
            {'id': 11, 'title': 'Exercices', 'lessonType': 'article', 'articleContent': 'x', 'isPublished': false, 'position': 1},
          ],
        },
        {'id': 2, 'title': 'Chapitre 2', 'position': 1, 'unlockRule': 'delay_days', 'delayDays': 7, 'lessons': []},
      ];

  Future<void> monterEditeur(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, const CourseEditorScreen(courseId: 12));
    tester.view.physicalSize = const Size(800, 3000);
    await pomper(tester);
  }

  Future<void> ouvrir(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
  }

  testWidgets('programme : chapitres, regle d\'ouverture, types et brouillons', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    await monterEditeur(tester);
    final l = L10n.current;
    expect(find.text('Chapitre 1'), findsOneWidget);
    expect(find.text(l.tcourseUnlockAfter(7)), findsOneWidget);
    expect(find.text('${l.tcourseTypeArticle} · ${l.tcourseDraftLesson}'), findsOneWidget);
    expect(find.text(l.tcourseCounts(2, 2)), findsOneWidget);
  });

  testWidgets('ajouter un chapitre avec ouverture apres un score', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('POST', '/teacher/courses/12/sections', {'id': 3, 'title': 'Revisions', 'position': 2});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.text(l.tcourseAddSection).first);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseSectionTitle), 'Revisions');
    await tester.tap(find.widgetWithText(WinChip, l.tcourseUnlockMinScore));
    await pomper(tester);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseMinScore), '60');
    await tester.tap(find.widgetWithText(WinButton, l.tcourseSave));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/courses/12/sections').single.data,
        {'title': 'Revisions', 'description': null, 'position': 0, 'unlockRule': 'min_score', 'delayDays': null, 'minScore': 60});
  });

  testWidgets('descendre un chapitre : nouvel ordre envoye', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('PUT', '/teacher/courses/12/sections/reorder', {'message': 'ok'});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.byTooltip(l.tcourseSectionActions).first);
    await ouvrir(tester, find.text(l.tcourseMoveDown));
    await reseau(tester);
    expect(faux.recues('PUT', '/teacher/courses/12/sections/reorder').single.data, [
      {'id': 2, 'position': 0},
      {'id': 1, 'position': 1},
    ]);
  });

  testWidgets('ajouter une lecon article : texte obligatoire puis envoi', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('POST', '/teacher/courses/12/sections/2/lessons', {'id': 20, 'title': 'Fiche', 'position': 0});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.text(l.tcourseAddLesson).last);
    await ouvrir(tester, find.text(l.tcourseTypeArticle).last);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseLessonTitle), 'Fiche');
    await tester.tap(find.widgetWithText(WinButton, l.tcourseSave));
    await pomper(tester);
    expect(find.text(l.tcourseNeedArticle), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseArticle), 'Les identites remarquables.');
    await tester.tap(find.widgetWithText(WinButton, l.tcourseSave));
    await reseau(tester);
    final envoi = faux.recues('POST', '/teacher/courses/12/sections/2/lessons').single.data as Map;
    expect(envoi['lessonType'], 'article');
    expect(envoi['articleContent'], 'Les identites remarquables.');
    expect(envoi.containsKey('videoUrl'), isFalse);
  });

  testWidgets('lecon video : adresse complete exigee', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('POST', '/teacher/courses/12/sections/1/lessons', {'id': 21, 'title': 'Cours', 'position': 2});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.text(l.tcourseAddLesson).first);
    await ouvrir(tester, find.text(l.tcourseTypeVideo).last);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseLessonTitle), 'Cours');
    await tester.enterText(find.widgetWithText(TextField, l.tcourseVideoUrl), 'youtube');
    await tester.tap(find.widgetWithText(WinButton, l.tcourseSave));
    await pomper(tester);
    expect(find.text(l.tcourseNeedUrl), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, l.tcourseVideoUrl), 'https://youtu.be/abc');
    await tester.enterText(find.widgetWithText(TextField, l.tcourseVideoMinutes), '12');
    await tester.tap(find.widgetWithText(WinButton, l.tcourseSave));
    await reseau(tester);
    final envoi = faux.recues('POST', '/teacher/courses/12/sections/1/lessons').single.data as Map;
    expect(envoi['videoUrl'], 'https://youtu.be/abc');
    expect(envoi['videoDurationSec'], 720);
  });

  testWidgets('supprimer une lecon apres confirmation', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('DELETE', '/teacher/courses/12/sections/1/lessons/11', {'message': 'ok'});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.text('Exercices'));
    await ouvrir(tester, find.text(l.tcourseDeleteLesson));
    await tester.tap(find.widgetWithText(TextButton, l.commonDelete));
    await reseau(tester);
    expect(faux.recues('DELETE', '/teacher/courses/12/sections/1/lessons/11'), hasLength(1));
  });

  testWidgets('programme WinAI : generation, apercu, import en chapitres', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation());
    faux.repond('POST', '/teacher/courses/generate-syllabus', {
      'weeks': [
        {'week': 1, 'title': 'Polynomes', 'concepts': ['degre'], 'activities': ['exercices'], 'duration_minutes': 90, 'suggested_resources': ['annales']},
        {'week': 2, 'title': 'Equations', 'concepts': [], 'activities': [], 'duration_minutes': 60, 'suggested_resources': []},
      ],
    });
    faux.repond('POST', '/teacher/courses/12/import-syllabus', {'sectionsCreated': 2});
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.widgetWithText(WinButton, l.tcourseSyllabus));
    tester.view.physicalSize = const Size(800, 3000);
    await tester.tap(find.widgetWithText(WinButton, l.tcourseGenerate));
    await reseau(tester);
    final demande = faux.recues('POST', '/teacher/courses/generate-syllabus').single.data as Map;
    expect(demande['subject'], 'Informatique');
    expect(demande['duration_weeks'], 6);
    expect(find.text(l.tcourseWeekTitle(1, 'Polynomes')), findsOneWidget);
    await tester.tap(find.widgetWithText(WinButton, l.tcourseImport(2)));
    await reseau(tester);
    final envoi = faux.recues('POST', '/teacher/courses/12/import-syllabus').single.data as Map;
    expect((envoi['weeks'] as List).first, {
      'week': 1, 'title': 'Polynomes', 'concepts': ['degre'], 'activities': ['exercices'], 'durationMinutes': 90,
      'suggestedResources': ['annales'],
    });
  });

  testWidgets('programme WinAI hors du plan : message du serveur', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation());
    faux.repond('POST', '/teacher/courses/generate-syllabus',
        {'error': '« Création assistée » n\'est pas incluse dans votre plan.', 'code': 'feature_not_in_plan'}, statut: 403);
    await monterEditeur(tester);
    final l = L10n.current;
    await ouvrir(tester, find.widgetWithText(WinButton, l.tcourseSyllabus));
    await tester.tap(find.widgetWithText(WinButton, l.tcourseGenerate));
    await reseau(tester);
    expect(find.textContaining('pas incluse dans votre plan'), findsOneWidget);
  });

  testWidgets('soumettre : confirmation puis appel ; en validation, rien n\'est modifiable', (tester) async {
    faux.repond('GET', '/teacher/courses/12', formation(sections: deuxChapitres()));
    faux.repond('POST', '/teacher/courses/12/submit', {'message': 'ok'});
    await monterEditeur(tester);
    final l = L10n.current;
    await tester.ensureVisible(find.widgetWithText(WinButton, l.tcourseSubmit));
    await ouvrir(tester, find.widgetWithText(WinButton, l.tcourseSubmit));
    faux.repond('GET', '/teacher/courses/12', formation(status: 'pending_review', sections: deuxChapitres()));
    await tester.tap(find.widgetWithText(TextButton, l.tcourseSubmit));
    await reseau(tester);
    expect(faux.recues('POST', '/teacher/courses/12/submit'), hasLength(1));
    expect(find.text(l.tcoursePending), findsOneWidget);
    expect(find.text(l.tcourseAddLesson), findsNothing);
  });

  testWidgets('programme WinAI : matiere choisie dans le selecteur (pre-remplie, jamais tapee)', (tester) async {
    faux.repond('POST', '/teacher/courses/generate-syllabus', {'weeks': []});
    final course = EditorCourse.fromJson(formation());
    tester.view.physicalSize = const Size(800, 3000);
    await monterEcran(tester, SyllabusScreen(course: course));
    final l = L10n.current;
    expect(find.byType(TextField), findsNWidgets(2), reason: 'objectifs et examens vises seulement, plus de champ Matiere');
    await tester.tap(find.text('Maths'));
    await pomper(tester);
    await tester.tap(find.text(l.tcourseGenerate));
    await reseau(tester);
    expect((faux.recues('POST', '/teacher/courses/generate-syllabus').single.data as Map)['subject'], 'Mathématiques');
  });
}
