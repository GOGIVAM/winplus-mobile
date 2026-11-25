import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/widgets/win_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/course_catalog_screen.dart';
import 'package:winplus/student/my_courses_screen.dart';
import 'package:winplus/student/search_screen.dart';
import 'package:winplus/student/student_reports_screen.dart';
import 'package:winplus/student/student_tabs.dart';
import 'package:winplus/student/tutors/tutor_search_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';
import 'package:winplus/student/quiz_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Les onglets sont des colonnes sans Scaffold : on les pose dans un Scaffold.
Widget _page(Widget onglet) => Scaffold(body: onglet);

/// Pastilles de type du catalogue : rangee qui defile a l'horizontale.
/// (Le champ de recherche contient aussi un Scrollable horizontal : on vise la liste.)
final _rangee = find.descendant(
  of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal),
  matching: find.byType(Scrollable),
).first;
Finder _puce(String libelle) => find.descendant(of: _rangee, matching: find.text(libelle));

Future<void> _toucherPuce(WidgetTester tester, String libelle, [double pas = 60]) async {
  await tester.scrollUntilVisible(_puce(libelle), pas, scrollable: _rangee);
  await tester.ensureVisible(_puce(libelle));
  await pomper(tester);
  await tester.tap(_puce(libelle));
  await pomper(tester);
  // Les cartes reapparaissent en fondu decale : on laisse finir l'animation.
  await pomper(tester, const Duration(seconds: 1));
}

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  group('StudentCatalogTab', () {
    testWidgets('chargement puis grille : titres des contenus et filtres de type', (tester) async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'Epreuve de maths', 'category': 'epreuve', 'price': 500},
          {'id': 2, 'title': 'Quiz de physique', 'category': 'quiz', 'isFree': true},
        ],
      });
      telephone(tester);
      await monter(tester, ecran(_page(const StudentCatalogTab())));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      // Pas de titre « Catalogue » dans la page : la barre du haut le porte.
      expect(find.text(l.mobileHomeSearchPaper), findsOneWidget);
      expect(find.text('Epreuve de maths'), findsOneWidget);
      expect(find.text('Quiz de physique'), findsOneWidget);
      expect(find.text(l.mobileCatalogCount(2)), findsOneWidget);
      expect(_puce(l.commonAll), findsOneWidget);
      expect(_puce(l.studentTabsTypePapers), findsOneWidget);
      expect(faux.recues('GET', '/subjects').single.queryParameters['pageSize'], 50);
    });

    testWidgets('filtre « Quiz » : seuls les quiz restent ; « Tout » les ramene', (tester) async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'Epreuve de maths', 'category': 'epreuve'},
          {'id': 2, 'title': 'Quiz de physique', 'category': 'quiz'},
        ],
      });
      await monterEcran(tester, _page(const StudentCatalogTab()));
      await _toucherPuce(tester, 'Quiz');
      expect(find.text('Quiz de physique'), findsOneWidget);
      expect(find.text('Epreuve de maths'), findsNothing);
      await _toucherPuce(tester, L10n.current.commonAll, -60);
      expect(find.text('Epreuve de maths'), findsOneWidget);
      // Le filtre est local : aucun nouvel appel serveur.
      expect(faux.recues('GET', '/subjects'), hasLength(1));
    });

    testWidgets('filtre sans resultat : message « aucun contenu »', (tester) async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'Epreuve de maths', 'category': 'epreuve'},
        ],
      });
      await monterEcran(tester, _page(const StudentCatalogTab()));
      await _toucherPuce(tester, L10n.current.studentTabsTypePacks);
      expect(find.text(L10n.current.studentTabsNoContent), findsOneWidget);
    });

    testWidgets('catalogue vide : message « aucun contenu »', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      await monterEcran(tester, _page(const StudentCatalogTab()));
      expect(find.text(L10n.current.studentTabsNoContent), findsOneWidget);
    });

    testWidgets('erreur serveur : message puis « Reessayer »', (tester) async {
      faux.repond('GET', '/subjects', {}, statut: 500);
      await monterEcran(tester, _page(const StudentCatalogTab()));
      final l = L10n.current;
      expect(find.text(l.studentTabsCatalogLoadError), findsOneWidget);
      expect(find.byType(WinErrorState), findsOneWidget);
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'Epreuve de maths', 'category': 'epreuve'},
        ],
      });
      await tester.tap(find.widgetWithText(WinButton, l.commonRetry));
      await reseau(tester);
      expect(find.text(l.studentTabsCatalogLoadError), findsNothing);
      expect(find.text('Epreuve de maths'), findsOneWidget);
    });

    testWidgets('bouton d\'actualisation : relit le catalogue (page tiree vers le bas)', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      await monterEcran(tester, _page(const StudentCatalogTab()));
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
      await pomper(tester);
      await pomper(tester, const Duration(seconds: 1));
      await reseau(tester);
      expect(faux.recues('GET', '/subjects'), hasLength(2));
    });

    testWidgets('banniere des formations : ouvre le catalogue des formations', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      faux.repond('GET', '/courses', {'data': [], 'total': 0});
      await monterEcran(tester, _page(const StudentCatalogTab()));
      await tester.tap(find.text(L10n.current.studentTabsStructuredCourses));
      await reseau(tester);
      expect(find.byType(CourseCatalogScreen), findsOneWidget);
    });

    testWidgets('banniere des repetiteurs : ouvre la recherche de repetiteurs', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      await monterEcran(tester, _page(const StudentCatalogTab()));
      await tester.tap(find.text(L10n.current.studentTabsFindTutor));
      await reseau(tester);
      expect(find.byType(TutorSearchScreen), findsOneWidget);
    });

    testWidgets('champ de recherche : ouvre l\'ecran de recherche', (tester) async {
      faux.repond('GET', '/subjects', {'items': []});
      await monterEcran(tester, _page(const StudentCatalogTab()));
      // La barre ouvre la recherche a la validation de la saisie.
      await tester.enterText(find.byType(TextField), 'BAC maths');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pomper(tester);
      await reseau(tester);
      expect(tester.widget<SearchScreen>(find.byType(SearchScreen)).initialQuery, 'BAC maths');
    });
  });

  group('StudentSpaceTab', () {
    testWidgets('statistiques reelles : moyenne arrondie et heures de la semaine cumulees', (tester) async {
      faux.repond('GET', '/student/stats', {
        'data': {'averageScore': 71.6, 'weeklyStudyHours': [2.0, 3.4, 4]},
      });
      telephone(tester);
      await monter(tester, ecran(_page(const StudentSpaceTab())));
      // Avant la reponse : tirets, jamais de chiffres de demonstration.
      expect(find.text('—'), findsNWidgets(2));
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('9h'), findsOneWidget);
      expect(find.text(l.studentReportsAvgScore), findsOneWidget);
      expect(find.text(l.studentTabsStudyThisWeek), findsOneWidget);
    });

    testWidgets('statistiques indisponibles : les tirets restent affiches', (tester) async {
      faux.repond('GET', '/student/stats', {}, statut: 500);
      await monterEcran(tester, _page(const StudentSpaceTab()));
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('tous les raccourcis de l\'espace sont proposes', (tester) async {
      faux.repond('GET', '/student/stats', {'data': {}});
      await monterEcran(tester, _page(const StudentSpaceTab()));
      final l = L10n.current;
      final liste = find.byType(Scrollable).first;
      // Dans l'ordre de l'ecran : cinq groupes d'usage, chacun avec son titre.
      for (final libelle in [
        l.spaceGroupLearn,
        l.studentMyCoursesTitle,
        l.studentTabsCourseCatalog,
        l.liveTitle,
        l.studentTabsFavorites,
        l.studentHubHistory,
        l.spaceGroupPractice,
        l.hwTitle,
        l.studentHubRevisionQuiz,
        l.studentTabsGuidedSession,
        l.studentTabsExamCoach,
        l.spaceGroupSupport,
        l.studentTabsFindTutor,
        l.studentTabsMyBookings,
        l.studentLinksStudyGroups,
        l.spaceGroupProgress,
        l.studentReportsTitle,
        l.studentHomeBadges,
        l.studentTabsCertificates,
        l.spaceGroupPurchases,
        l.studentTabsMyCart,
        l.studentTabsMyOrders,
      ]) {
        await tester.scrollUntilVisible(find.text(libelle), 300, scrollable: liste);
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
    });

    testWidgets('« Mes formations » ouvre la liste de mes formations', (tester) async {
      faux.repond('GET', '/student/stats', {'data': {}});
      faux.repond('GET', '/my-courses', []);
      await monterEcran(tester, _page(const StudentSpaceTab()));
      await tester.tap(find.text(L10n.current.studentMyCoursesTitle).first);
      await reseau(tester);
      expect(find.byType(MyCoursesScreen), findsOneWidget);
    });

    testWidgets('« Mes rapports » ouvre l\'ecran des rapports', (tester) async {
      faux.repond('GET', '/student/stats', {'data': {}});
      await monterEcran(tester, _page(const StudentSpaceTab()));
      final cible = find.text(L10n.current.studentReportsTitle);
      await tester.scrollUntilVisible(cible, 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(cible);
      await pomper(tester);
      await tester.tap(cible);
      await pomper(tester);
      await reseau(tester);
      expect(find.byType(StudentReportsScreen), findsOneWidget);
    });
  });

  group('StudentWinAITab', () {
    Finder champ() => find.byType(TextField);

    testWidgets('etat initial : presentation, quatre suggestions et acces a la memoire de WinAI', (tester) async {
      await monterEcran(tester, const StudentWinAITab());
      final l = L10n.current;
      expect(find.text('WinAI'), findsWidgets);
      expect(find.text(l.studentTabsAiTagline), findsOneWidget);
      for (final s in [l.studentTabsAiSuggest1, l.studentTabsAiSuggest2, l.studentTabsAiSuggest3, l.studentTabsAiSuggest4]) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text(l.commonWinaiMemory), findsOneWidget);
    });

    testWidgets('saisie puis envoi : message de l\'eleve, appel serveur et reponse de WinAI', (tester) async {
      faux.repond('POST', '/chatbot/message', {
        'assistantMessage': {'content': 'Voici la methode'},
      });
      await monterEcran(tester, const StudentWinAITab());
      await tester.enterText(champ(), '  Explique les limites ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(find.text('Explique les limites'), findsOneWidget);
      expect(find.text('Voici la methode'), findsOneWidget);
      final envoi = faux.recues('POST', '/chatbot/message').single.data as Map;
      expect(envoi['content'], 'Explique les limites');
      expect(envoi['clientMessageId'], isA<String>());
      // La zone de saisie est videe et les suggestions disparaissent.
      expect(tester.widget<TextField>(champ()).controller!.text, isEmpty);
      expect(find.text(L10n.current.studentTabsAiSuggest1), findsNothing);
    });

    testWidgets('message vide : rien n\'est envoye', (tester) async {
      await monterEcran(tester, const StudentWinAITab());
      await tester.enterText(champ(), '   ');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(faux.requetes, isEmpty);
      expect(find.text(L10n.current.studentTabsAiSuggest1), findsOneWidget);
    });

    testWidgets('une suggestion est envoyee telle quelle', (tester) async {
      faux.repond('POST', '/chatbot/message', {'reply': 'Bien sur'});
      await monterEcran(tester, const StudentWinAITab());
      final suggestion = L10n.current.studentTabsAiSuggest2;
      await tester.tap(find.text(suggestion));
      await reseau(tester);
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], suggestion);
      expect(find.text('Bien sur'), findsOneWidget);
    });

    testWidgets('message initial : envoye automatiquement a l\'ouverture', (tester) async {
      faux.repond('POST', '/chatbot/message', {'reply': 'Reponse automatique'});
      await monterEcran(tester, const StudentWinAITab(initialMessage: 'Aide-moi sur les suites'));
      expect((faux.recues('POST', '/chatbot/message').single.data as Map)['content'], 'Aide-moi sur les suites');
      expect(find.text('Aide-moi sur les suites'), findsOneWidget);
      expect(find.text('Reponse automatique'), findsOneWidget);
    });

    testWidgets('serveur en erreur : message « pas de reponse »', (tester) async {
      faux.repond('POST', '/chatbot/message', {}, statut: 500);
      await monterEcran(tester, const StudentWinAITab());
      await tester.enterText(champ(), 'Bonjour');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(find.text(L10n.current.studentTabsAiNoReply), findsOneWidget);
    });

    testWidgets('quota depasse (402) : message du serveur affiche comme reponse', (tester) async {
      faux.repond('POST', '/chatbot/message', {'message': 'Limite atteinte pour aujourd\'hui'}, statut: 402);
      await monterEcran(tester, const StudentWinAITab());
      await tester.enterText(champ(), 'Bonjour');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      expect(find.text('Limite atteinte pour aujourd\'hui'), findsOneWidget);
    });

    testWidgets('bouton de dictee : ouvre la dictee (indisponible sans reconnaissance vocale) ; pas de piece jointe factice', (tester) async {
      // Telephone sans reconnaissance vocale : le service refuse de demarrer.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugin.csdcorp.com/speech_to_text'), (call) async => false);
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugin.csdcorp.com/speech_to_text'), null));
      await monterEcran(tester, const StudentWinAITab());
      // L'ancien trombone n'envoyait que le nom du fichier : il a disparu en
      // attendant le vrai televersement de sources.
      expect(find.byIcon(PhosphorIconsRegular.paperclip), findsNothing);
      await tester.tap(find.byIcon(PhosphorIconsRegular.microphone));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      // Pas de service de reconnaissance dans les tests : message explicite.
      expect(find.text(L10n.current.voiceUnavailable), findsOneWidget);
    });

    testWidgets('onglet « Sources » : fichiers, plafond et contenus ; une source cochee est envoyee avec le message et citee', (tester) async {
      faux.repond('GET', '/winai/sources', {
        'data': {
          'usage': {'files': 1, 'bytes': 2048, 'maxFiles': 30, 'maxBytes': 104857600, 'maxFileBytes': 5242880, 'maxSourcesPerMessage': 10},
          'sources': [
            {'id': 12, 'type': 'document', 'title': 'Ma fiche Pythagore', 'fileName': 'fiche.txt', 'sizeBytes': 2048, 'status': 'ready'},
          ],
        },
      });
      faux.repond('GET', '/winai/sources/disponibles', {
        'data': {
          'documents': [],
          'epreuves': [
            {'type': 'epreuve', 'id': 34, 'title': 'Bac C 2024 Maths', 'detail': 'Epreuve'},
          ],
          'formations': [],
          'erreursQuiz': {'type': 'erreurs-quiz', 'id': 0, 'title': 'Mes erreurs de quiz', 'detail': '3 question(s) a revoir'},
        },
      });
      faux.repond('POST', '/chatbot/message', {
        'assistantMessage': {'content': 'Voici le corrige'},
        'sources': [
          {'type': 'epreuve', 'id': 34, 'title': 'Bac C 2024 Maths', 'page': 2},
        ],
      });
      await monterEcran(tester, const StudentWinAITab());
      final l = L10n.current;
      // Rien n est demande tant que l onglet n est pas ouvert.
      expect(faux.requetes, isEmpty);
      await tester.tap(find.text(l.winaiTabSources));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.text(l.winaiSourcesUsage(1, 30)), findsOneWidget);
      expect(find.text('Ma fiche Pythagore'), findsOneWidget);
      expect(find.text('Mes erreurs de quiz'), findsOneWidget);
      await tester.ensureVisible(find.text('Bac C 2024 Maths'));
      await pomper(tester);
      await tester.tap(find.text('Bac C 2024 Maths'));
      await pomper(tester);
      await tester.tap(find.text(l.winaiTabChat));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.winaiSourcesSelected(1)), findsOneWidget);
      await tester.enterText(champ(), 'Corrige l exercice 2');
      await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
      await reseau(tester);
      final envoi = faux.recues('POST', '/chatbot/message').single.data as Map;
      expect(envoi['sources'], [
        {'type': 'epreuve', 'id': 34},
      ]);
      expect(find.text('Voici le corrige'), findsOneWidget);
      expect(find.text(l.winaiCitationPage('Bac C 2024 Maths', 2)), findsOneWidget);
    });

    testWidgets('onglet « Atelier » : outils de cet espace ; le quiz ouvre ses reglages, est genere par le serveur puis s ouvre dans le lecteur', (tester) async {
      faux.repond('POST', '/quizzes/me/generate', {
        'id': 91, 'title': 'Quiz : les suites', 'subject': 'Maths', 'difficulty': 'medium',
        'questionsCount': 1, 'durationMinutes': 5,
        'questions': [
          {'id': 'q1', 'question': '2 + 2 ?', 'options': ['3', '4']},
        ],
      });
      await monterEcran(tester, const StudentWinAITab());
      final l = L10n.current;
      await tester.tap(find.text(l.winaiTabStudio));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      for (final t in [l.winaiToolQuiz, l.winaiToolSheet, l.winaiCreationsTitle, l.studentTabsExamCoach]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(faux.requetes, isEmpty);
      await tester.tap(find.text(l.winaiToolQuiz));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.winaiSettingsTopic), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'les suites');
      await tester.ensureVisible(find.text(l.winaiSettingsGenerate));
      await pomper(tester);
      await tester.tap(find.text(l.winaiSettingsGenerate));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      final envoi = faux.recues('POST', '/quizzes/me/generate').single.data as Map;
      expect(envoi['topic'], 'les suites');
      expect(envoi['difficulty'], 'medium');
      // Rien ne passe plus par la discussion : le quiz est enregistre et joue.
      expect(faux.recues('POST', '/chatbot/message'), isEmpty);
      expect(find.byType(QuizActiveScreen, skipOffstage: false), findsOneWidget);
    });

    testWidgets('atelier : limite de l abonnement atteinte, message du serveur et acces aux offres', (tester) async {
      faux.repond('POST', '/revisions/me/generate', {'error': 'Limite de la semaine atteinte.', 'code': 'ai_quota_exceeded'}, statut: 402);
      await monterEcran(tester, const StudentWinAITab());
      final l = L10n.current;
      await tester.tap(find.text(l.winaiTabStudio));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text(l.winaiToolSheet));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text(l.winaiSettingsGenerate));
      await pomper(tester);
      await tester.tap(find.text(l.winaiSettingsGenerate));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text('Limite de la semaine atteinte.'), findsOneWidget);
      expect(find.text(l.winaiStudioSeePlans), findsOneWidget);
    });

    testWidgets('« Memoire de WinAI » ouvre la feuille des memoires', (tester) async {
      faux.repond('GET', '/chatbot/memories', []);
      await monterEcran(tester, const StudentWinAITab());
      await tester.tap(find.text(L10n.current.commonWinaiMemory));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(faux.recues('GET', '/chatbot/memories'), hasLength(1));
      expect(find.text(L10n.current.widgetMemSubtitle), findsOneWidget);
    });
  });
}
