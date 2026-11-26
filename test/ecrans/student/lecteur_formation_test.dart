import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/course_player_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Lecon du sommaire (GET /courses/{id}/play).
Map<String, dynamic> _lecon(int id, String titre, {String type = 'article', bool faite = false, int duree = 0}) => {
      'id': id,
      'title': titre,
      'lessonType': type,
      'videoDurationSec': duree,
      'position': id,
      'isPreview': false,
      'isCompleted': faite,
      'lastPositionSec': 0,
    };

Map<String, dynamic> _sommaire({
  List<Map<String, dynamic>>? lecons,
  num progression = 0,
  Map<String, dynamic>? examenFinal,
  String? terminee,
}) =>
    {
      'courseId': 7,
      'title': 'Algebre',
      'progressPercent': progression,
      'completedAt': terminee,
      if (examenFinal != null) 'finalExam': examenFinal,
      'sections': [
        {
          'id': 1,
          'title': 'Module 1',
          'position': 1,
          'lessons': lecons ?? [_lecon(1, 'Les ensembles'), _lecon(2, 'Les fonctions')],
        },
      ],
    };

/// Contenu d'une lecon (GET /courses/{id}/play/{lecon}).
Map<String, dynamic> _contenu(int id, String titre, {Map<String, dynamic> en = const {}}) => {
      'id': id,
      'title': titre,
      'lessonType': 'article',
      'articleContent': 'Texte de la lecon $id',
      'videoDurationSec': 0,
      'isPreview': false,
      'progress': {'isCompleted': false, 'lastPositionSec': 0},
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  /// Monte le lecteur au-dessus d'une page d'accueil (il se ferme tout seul
  /// si le sommaire ne charge pas) et laisse finir les deux chargements.
  Future<void> ouvrirLecteur(WidgetTester tester, {int? leconInitiale}) async {
    await monterEcran(tester, lanceur(CoursePlayerScreen(courseId: 7, courseTitle: 'Algebre', initialLessonId: leconInitiale)));
    await ouvrir(tester);
  }

  void routesBase({Map<String, dynamic>? sommaire}) {
    faux.repond('GET', '/courses/7/play', sommaire ?? _sommaire());
    faux.repond('GET', '/courses/7/play/1', _contenu(1, 'Les ensembles'));
    faux.repond('GET', '/courses/7/play/2', _contenu(2, 'Les fonctions'));
  }

  testWidgets('chargement puis premiere lecon a faire : titres, texte, progression et bouton « Marquer termine »', (tester) async {
    routesBase(sommaire: _sommaire(progression: 40));
    telephone(tester);
    await monter(tester, ecran(lanceur(const CoursePlayerScreen(courseId: 7, courseTitle: 'Algebre'))));
    await tester.tap(find.text('ouvrir'));
    await pomper(tester);
    // Premiere image de la page poussee : construite hors scene.
    expect(find.byType(CircularProgressIndicator, skipOffstage: false), findsWidgets);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('Algebre'), findsOneWidget);
    expect(find.text('Les ensembles'), findsWidgets);
    expect(find.text('Texte de la lecon 1'), findsOneWidget);
    expect(find.text(WinFormat.percent(40)), findsOneWidget);
    expect(find.text(l.studentPlayerMarkDone), findsOneWidget);
    expect(faux.recues('GET', '/courses/7/play/1'), hasLength(1));
  });

  testWidgets('la premiere lecon non terminee est ouverte, pas la premiere de la liste', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [_lecon(1, 'Les ensembles', faite: true), _lecon(2, 'Les fonctions')]));
    await ouvrirLecteur(tester);
    expect(faux.recues('GET', '/courses/7/play/1'), isEmpty);
    expect(faux.recues('GET', '/courses/7/play/2'), hasLength(1));
    expect(find.text('Texte de la lecon 2'), findsOneWidget);
  });

  testWidgets('lecon initiale demandee : elle est ouverte en priorite', (tester) async {
    routesBase();
    await ouvrirLecteur(tester, leconInitiale: 2);
    expect(faux.recues('GET', '/courses/7/play/2'), hasLength(1));
    expect(find.text('Texte de la lecon 2'), findsOneWidget);
  });

  testWidgets('sommaire impossible a charger : le lecteur se ferme', (tester) async {
    faux.repond('GET', '/courses/7/play', {'error': 'x'}, statut: 500);
    await ouvrirLecteur(tester);
    expect(find.byType(CoursePlayerScreen), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('lecon qui ne charge pas : invite a selectionner une lecon', (tester) async {
    faux.repond('GET', '/courses/7/play', _sommaire());
    faux.repond('GET', '/courses/7/play/1', {'error': 'x'}, statut: 500);
    await ouvrirLecteur(tester);
    expect(find.text(L10n.current.studentPlayerSelectLesson), findsOneWidget);
  });

  testWidgets('description de la lecon et mention « Termine » si deja faite ; plus de bouton', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [_lecon(1, 'Les ensembles', faite: true), _lecon(2, 'Les fonctions', faite: true)]));
    faux.repond('GET', '/courses/7/play/1', _contenu(1, 'Les ensembles', en: {'description': 'Notions de base', 'progress': {'isCompleted': true}}));
    await ouvrirLecteur(tester, leconInitiale: 1);
    final l = L10n.current;
    expect(find.text('Notions de base'), findsOneWidget);
    expect(find.text(l.studentPlayerDone), findsOneWidget);
    expect(find.text(l.studentPlayerLessonDone), findsOneWidget);
    expect(find.text(l.studentPlayerMarkDone), findsNothing);
  });

  testWidgets('marquer termine : appel serveur, progression mise a jour et lecon cochee', (tester) async {
    routesBase();
    faux.repond('POST', '/courses/7/play/1/progress', {'progressPercent': 50, 'courseCompleted': false});
    await ouvrirLecteur(tester);
    final l = L10n.current;
    await tester.tap(find.text(l.studentPlayerMarkDone));
    await reseau(tester);
    final envoi = faux.recues('POST', '/courses/7/play/1/progress').single;
    expect(envoi.data, {'watchTimeSec': 0, 'lastPositionSec': 0, 'isCompleted': true});
    expect(find.text(WinFormat.percent(50)), findsOneWidget);
    expect(find.text(l.studentPlayerLessonDone), findsOneWidget);
    expect(find.text(l.studentPlayerMarkDone), findsNothing);
    expect(find.text(l.studentPlayerCourseDone), findsNothing);
  });

  testWidgets('derniere lecon terminee : fenetre de felicitations puis bandeau de certificat', (tester) async {
    routesBase();
    faux.repond('POST', '/courses/7/play/1/progress', {'progressPercent': 100, 'courseCompleted': true});
    await ouvrirLecteur(tester);
    final l = L10n.current;
    await tester.tap(find.text(l.studentPlayerMarkDone));
    await reseau(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l.studentPlayerCertGenerating), findsOneWidget);
    await tester.tap(find.text(l.commonClose));
    await reseau(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l.studentPlayerCertAvailable), findsOneWidget);
    expect(find.text(WinFormat.percent(100)), findsOneWidget);
  });

  testWidgets('completion refusee par le serveur (409) : message du serveur, lecon toujours a faire', (tester) async {
    routesBase();
    faux.repond('POST', '/courses/7/play/1/progress', {'error': 'Lis la lecon plus longtemps', 'code': 'too_fast'}, statut: 409);
    await ouvrirLecteur(tester);
    final l = L10n.current;
    await tester.tap(find.text(l.studentPlayerMarkDone));
    await reseau(tester);
    expect(find.text('Lis la lecon plus longtemps'), findsOneWidget);
    expect(find.text(l.studentPlayerMarkDone), findsOneWidget);
    expect(find.text(WinFormat.percent(0)), findsOneWidget);
  });

  testWidgets('panne serveur pendant la completion : aucun message, lecon toujours a faire', (tester) async {
    routesBase();
    faux.repond('POST', '/courses/7/play/1/progress', {}, statut: 500);
    await ouvrirLecteur(tester);
    await tester.tap(find.text(L10n.current.studentPlayerMarkDone));
    await reseau(tester);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(L10n.current.studentPlayerMarkDone), findsOneWidget);
  });

  testWidgets('barre du bas : « Suivant » ouvre la lecon suivante, « Precedent » revient', (tester) async {
    routesBase();
    await ouvrirLecteur(tester);
    final precedent = find.byIcon(PhosphorIconsFill.skipBack);
    final suivant = find.byIcon(PhosphorIconsFill.skipForward);
    // Premiere lecon : pas de precedent.
    expect(tester.widget<IconButton>(find.ancestor(of: precedent, matching: find.byType(IconButton))).onPressed, isNull);
    await tester.tap(suivant);
    await reseau(tester);
    expect(find.text('Texte de la lecon 2'), findsOneWidget);
    // Derniere lecon : pas de suivant.
    expect(tester.widget<IconButton>(find.ancestor(of: suivant, matching: find.byType(IconButton))).onPressed, isNull);
    await tester.tap(precedent);
    await reseau(tester);
    expect(find.text('Texte de la lecon 1'), findsOneWidget);
  });

  testWidgets('curriculum : sections, lecons cochees, duree des videos ; choisir une lecon la charge', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [
      _lecon(1, 'Les ensembles', faite: true),
      _lecon(2, 'Les fonctions', type: 'video', duree: 125),
    ]));
    await ouvrirLecteur(tester);
    await tester.tap(find.byTooltip(L10n.current.studentPlayerCurriculum));
    await pomper(tester);
    expect(find.text('Module 1'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.checkCircle), findsOneWidget);
    expect(find.text('2:05'), findsOneWidget);
    await tester.tap(find.text('Les ensembles'));
    await reseau(tester);
    expect(find.text('Module 1'), findsNothing);
    expect(faux.recues('GET', '/courses/7/play/1'), hasLength(1));
  });

  testWidgets('curriculum : examen final verrouille tant que les lecons ne sont pas terminees', (tester) async {
    routesBase(sommaire: _sommaire(examenFinal: {'quizId': 9, 'passScore': 60, 'available': false, 'passed': false}));
    await ouvrirLecteur(tester);
    await tester.tap(find.byTooltip(L10n.current.studentPlayerCurriculum));
    await pomper(tester);
    final l = L10n.current;
    expect(find.text(l.studentExamFinalTitle), findsOneWidget);
    expect(find.text(l.studentExamFinalLocked), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.lock), findsOneWidget);
    await tester.tap(find.text(l.studentExamFinalTitle));
    await pomper(tester);
    // Toujours dans le curriculum : l'examen n'est pas ouvert.
    expect(find.text('Module 1'), findsOneWidget);
  });

  testWidgets('piece jointe qui n\'est pas un PDF : indication « s\'ouvre depuis le site »', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [_lecon(1, 'Annexe', type: 'file')]));
    faux.repond('GET', '/courses/7/play/1', _contenu(1, 'Annexe', en: {
      'lessonType': 'file',
      'articleContent': null,
      'fileUrl': 'https://exemple.test/f/tableau.xlsx?sig=1',
      'fileName': 'tableau.xlsx',
    }));
    await ouvrirLecteur(tester);
    expect(find.text('tableau.xlsx'), findsOneWidget);
    expect(find.text(L10n.current.studentPlayerOpenWithApp), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.filePdf), findsNothing);
  });

  testWidgets('piece jointe PDF (reconnue par le chemin du lien) : invite a ouvrir le document', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [_lecon(1, 'Annexe', type: 'file')]));
    faux.repond('GET', '/courses/7/play/1', _contenu(1, 'Annexe', en: {
      'lessonType': 'file',
      'articleContent': null,
      'fileUrl': 'https://exemple.test/f/support.PDF?sig=1',
    }));
    await ouvrirLecteur(tester);
    expect(find.text(L10n.current.studentPlayerAttachedFile), findsOneWidget);
    expect(find.text(L10n.current.studentPlayerTapToOpen), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.filePdf), findsOneWidget);
  });

  testWidgets('fichier du catalogue (sourceSubjectId) : carte « Ouvrir dans la visionneuse »', (tester) async {
    routesBase(sommaire: _sommaire(lecons: [_lecon(1, 'Epreuve 2024', type: 'file')]));
    faux.repond('GET', '/courses/7/play/1', _contenu(1, 'Epreuve 2024', en: {'lessonType': 'file', 'articleContent': null, 'sourceSubjectId': 55, 'viewerOnly': true}));
    await ouvrirLecteur(tester);
    expect(find.text(L10n.current.studentPlayerOpenViewer), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.eye), findsOneWidget);
    // Jamais proposee comme piece jointe a telecharger.
    expect(find.byIcon(PhosphorIconsRegular.paperclip), findsNothing);
  });
}
