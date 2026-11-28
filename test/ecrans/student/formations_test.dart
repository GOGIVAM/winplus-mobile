import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/course_catalog_screen.dart';
import 'package:winplus/student/course_detail_screen.dart';
import 'package:winplus/student/my_courses_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winplus/data/models.dart' show fmtXaf;

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _cours({int id = 1, String titre = 'Algebre', num prix = 0, bool gratuit = true, int duree = 90}) => {
      'id': id,
      'title': titre,
      'slug': 's$id',
      'price': prix,
      'isFree': gratuit,
      'totalDurationMin': duree,
      'lessonsCount': 3,
      'category': 'Mathématiques',
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  group('MyCoursesScreen', () {
    testWidgets('chargement puis liste : titre, progression, bouton selon l\'avancement', (tester) async {
      faux.repond('GET', '/my-courses', [
        {'enrollmentId': 1, 'progressPercent': 0, 'course': {'id': 1, 'title': 'Algebre', 'lessonsCount': 4, 'totalDurationMin': 90, 'instructorName': 'Mme Ngo'}},
        {'enrollmentId': 2, 'progressPercent': 40, 'course': {'id': 2, 'title': 'Optique', 'lessonsCount': 2, 'totalDurationMin': 60}},
        {'enrollmentId': 3, 'progressPercent': 100, 'course': {'id': 3, 'title': 'Chimie', 'lessonsCount': 5, 'totalDurationMin': 120}},
      ]);
      telephone(tester);
      await monter(tester, ecran(const MyCoursesScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Algebre'), findsOneWidget);
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text(WinFormat.percent(0)), findsOneWidget);
      expect(find.text(WinFormat.percent(40)), findsOneWidget);
      expect(_bouton(l.studentMyCoursesStart), findsOneWidget);
      expect(_bouton(l.commonContinue), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Chimie'), 300, scrollable: find.byType(Scrollable).first);
      expect(_bouton(l.studentMyCoursesReplay), findsOneWidget);
      expect(find.byIcon(PhosphorIconsFill.medal), findsOneWidget);
    });

    testWidgets('toucher la carte (pas seulement le bouton) ouvre le lecteur de la formation', (tester) async {
      faux.repond('GET', '/my-courses', [
        {'enrollmentId': 1, 'progressPercent': 40, 'course': {'id': 7, 'title': 'Algebre', 'lessonsCount': 4, 'totalDurationMin': 90}},
      ]);
      await monterEcran(tester, const MyCoursesScreen());
      await tester.tap(find.text('Algebre'));
      await reseau(tester);
      // Le lecteur s'est ouvert sur cette formation (il demande son programme ;
      // sans reponse simulee, il se referme aussitot).
      expect(faux.recues('GET', '/courses/7/play'), isNotEmpty);
    });

    testWidgets('aucune formation : etat vide avec bouton d\'exploration', (tester) async {
      faux.repond('GET', '/my-courses', []);
      await monterEcran(tester, const MyCoursesScreen());
      expect(find.text(L10n.current.studentMyCoursesEmpty), findsOneWidget);
      expect(_bouton(L10n.current.studentMyCoursesExplore), findsOneWidget);
    });

    testWidgets('erreur : message puis « Reessayer »', (tester) async {
      faux.repond('GET', '/my-courses', {}, statut: 500);
      await monterEcran(tester, const MyCoursesScreen());
      expect(find.text(L10n.current.studentMyCoursesLoadError), findsOneWidget);
      faux.repond('GET', '/my-courses', []);
      await tester.tap(_bouton(L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text(L10n.current.studentMyCoursesLoadError), findsNothing);
      expect(find.text(L10n.current.studentMyCoursesEmpty), findsOneWidget);
    });

    testWidgets('« Catalogue » dans la barre ouvre le catalogue des formations', (tester) async {
      faux.repond('GET', '/my-courses', []);
      faux.repond('GET', '/courses', {'data': [], 'total': 0});
      await monterEcran(tester, const MyCoursesScreen());
      await tester.tap(find.text(L10n.current.shellTabCatalog));
      await reseau(tester);
      expect(find.byType(CourseCatalogScreen), findsOneWidget);
    });
  });

  group('CourseCatalogScreen', () {
    testWidgets('grille : titre, duree, prix TTC ou gratuit', (tester) async {
      faux.repond('GET', '/courses', {
        'data': [
          _cours(id: 1, titre: 'Algebre'),
          _cours(id: 2, titre: 'Trigo', prix: 5000, gratuit: false),
        ],
        'total': 2,
        'totalPages': 1,
      });
      await monterEcran(tester, const CourseCatalogScreen());
      expect(find.text('Algebre'), findsOneWidget);
      expect(find.text('Trigo'), findsOneWidget);
      expect(find.text(L10n.current.commonFree), findsOneWidget);
      expect(find.text(L10n.current.studentCatalogPriceTtc('5 000')), findsOneWidget);
      expect(find.text('1 h 30'), findsNWidgets(2));
      expect(find.text(L10n.current.studentCatalogLoadMore), findsNothing);
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 12});
    });

    testWidgets('liste vide : message dedie', (tester) async {
      faux.repond('GET', '/courses', {'data': []});
      await monterEcran(tester, const CourseCatalogScreen());
      expect(find.text(L10n.current.studentCatalogEmpty), findsOneWidget);
    });

    testWidgets('erreur serveur : traitee comme un catalogue vide, sans plantage', (tester) async {
      faux.repond('GET', '/courses', {}, statut: 500);
      await monterEcran(tester, const CourseCatalogScreen());
      expect(find.text(L10n.current.studentCatalogEmpty), findsOneWidget);
    });

    testWidgets('plusieurs pages : « Charger plus » demande la page suivante', (tester) async {
      faux.repond('GET', '/courses', {'data': [_cours()], 'total': 20, 'totalPages': 2});
      await monterEcran(tester, const CourseCatalogScreen());
      await tester.tap(find.text(L10n.current.studentCatalogLoadMore));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters['page'], 2);
    });

    testWidgets('une puce de categorie filtre la liste, un second toucher l\'enleve', (tester) async {
      faux.repond('GET', '/courses', {'data': [_cours()]});
      await monterEcran(tester, const CourseCatalogScreen());
      await tester.tap(find.text(L10n.current.dataSubjectPhysics));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters['category'], 'Physique');
      await tester.tap(find.text(L10n.current.dataSubjectPhysics));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters.containsKey('category'), isFalse);
    });

    testWidgets('filtres : « Gratuit » puis « Appliquer » envoie free=true', (tester) async {
      faux.repond('GET', '/courses', {'data': [_cours()]});
      await monterEcran(tester, const CourseCatalogScreen());
      await tester.tap(find.byIcon(PhosphorIconsRegular.slidersHorizontal));
      await reseau(tester);
      expect(find.text(L10n.current.studentCatalogFilters), findsOneWidget);
      await tester.tap(find.widgetWithText(WinChip, L10n.current.commonFree));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.studentCatalogApply));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters['free'], true);
    });

    testWidgets('la recherche attend 400 ms puis interroge /courses/search', (tester) async {
      faux.repond('GET', '/courses', {'data': [_cours()]});
      faux.repond('GET', '/courses/search', [_cours(id: 9, titre: 'Resultat')]);
      await monterEcran(tester, const CourseCatalogScreen());
      await tester.enterText(find.byType(TextField), 'resu');
      await pomper(tester, const Duration(milliseconds: 100));
      expect(faux.recues('GET', '/courses/search'), isEmpty);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(faux.recues('GET', '/courses/search').single.queryParameters, {'q': 'resu', 'page': 1});
      expect(find.text('Resultat'), findsOneWidget);
    });
  });

  group('CourseDetailScreen', () {
    Map<String, dynamic> detail(Map<String, dynamic> en) => {
          ..._cours(),
          'description': 'Un cours complet',
          'instructor': {'name': 'Mme Ngo'},
          'objectives': ['Resoudre des equations'],
          'requirements': ['Calculatrice'],
          'certificateEnabled': true,
          'enrolledCount': 12,
          'sections': [
            {
              'id': 1,
              'title': 'Debuts',
              'lessons': [
                {'id': 1, 'title': 'Intro'},
                {'id': 2, 'title': 'Suite'},
              ],
            },
          ],
          ...en,
        };

    void routes(Map<String, dynamic> d, {List<Map<String, dynamic>> avis = const []}) {
      faux.repond('GET', '/courses/1', d);
      faux.repond('GET', '/courses/1/reviews', avis);
    }

    testWidgets('formation introuvable : message d\'erreur', (tester) async {
      faux.repond('GET', '/courses/1', {}, statut: 404);
      faux.repond('GET', '/courses/1/reviews', []);
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      expect(find.text(L10n.current.studentCourseNotFound), findsOneWidget);
    });

    testWidgets('formation gratuite : titre, instructeur, inscrits, « Commencer » et certificat', (tester) async {
      routes(detail({}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      final l = L10n.current;
      expect(find.text('Algebre'), findsWidgets);
      expect(find.text('Mme Ngo'), findsWidgets);
      expect(find.text(l.studentCourseEnrolled(12)), findsOneWidget);
      expect(find.text(l.commonFree), findsWidgets);
      expect(_bouton(l.studentCourseStartFree), findsOneWidget);
      expect(_bouton(l.studentCourseBuy), findsNothing);
      expect(find.text(l.studentCourseCertIncluded), findsOneWidget);
    });

    testWidgets('inscription gratuite : appel serveur puis ouverture du lecteur', (tester) async {
      routes(detail({}));
      faux.repond('POST', '/courses/1/enroll', {});
      faux.repond('GET', '/courses/1/play', {'courseId': 1, 'title': 'Algebre'});
      // Ouverte au-dessus d'une page, comme dans l'application : elle se
      // remplace par le lecteur (remplacer la seule page est interdit).
      await monterEcran(tester, lanceur(const CourseDetailScreen(courseId: 1)));
      await ouvrir(tester);
      final b = _bouton(L10n.current.studentCourseStartFree);
      await tester.ensureVisible(b);
      await pomper(tester);
      await tester.tap(b);
      await reseau(tester);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(faux.recues('POST', '/courses/1/enroll'), hasLength(1));
      expect(find.byType(CourseDetailScreen), findsNothing, reason: 'remplace par le lecteur');
    });

    testWidgets('inscription refusee (409) : le message du serveur est affiche', (tester) async {
      routes(detail({}));
      faux.repond('POST', '/courses/1/enroll', {'error': 'Deja inscrit', 'code': 'already_enrolled'}, statut: 409);
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      final b = _bouton(L10n.current.studentCourseStartFree);
      await tester.ensureVisible(b);
      await tester.tap(b);
      await reseau(tester);
      expect(find.text('Deja inscrit'), findsOneWidget);
      expect(find.byType(CourseDetailScreen), findsOneWidget);
    });

    testWidgets('formation payante : prix, note de TVA et bouton d\'achat', (tester) async {
      routes(detail({'price': 5000, 'isFree': false}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      final l = L10n.current;
      // Separateur de milliers, comme sur le reste de l'application.
      expect(find.text('${fmtXaf(5000)} XAF'), findsOneWidget);
      expect(find.text(l.studentCourseVatNote), findsOneWidget);
      expect(_bouton(l.studentCourseBuy), findsOneWidget);
      expect(_bouton(l.studentCourseStartFree), findsNothing);
    });

    testWidgets('deja inscrit : « Continuer »', (tester) async {
      routes(detail({'isEnrolled': true}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      expect(_bouton(L10n.current.studentCourseContinue), findsOneWidget);
      expect(_bouton(L10n.current.studentCourseStartFree), findsNothing);
    });

    testWidgets('auteur de la formation : bouton « la votre » sans action d\'inscription', (tester) async {
      routes(detail({'isOwner': true}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      expect(_bouton(L10n.current.studentCourseYours), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.studentCourseYours)).onTap, isNull);
    });

    testWidgets('achetee mais pas encore ouverte : « Commencer » (rattrapage)', (tester) async {
      routes(detail({'price': 5000, 'isFree': false, 'isPurchased': true}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      expect(_bouton(L10n.current.studentCoursePurchasedStart), findsOneWidget);
      expect(_bouton(L10n.current.studentCourseBuy), findsNothing);
    });

    testWidgets('compte parent : « Offrir a mon enfant » remplace l\'achat', (tester) async {
      faux = preparerEnvironnement(prefs: {'user_role': 'parent'});
      routes(detail({'price': 5000, 'isFree': false}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      expect(_bouton(L10n.current.studentCourseOfferChild), findsOneWidget);
      expect(_bouton(L10n.current.studentCourseBuy), findsNothing);
    });

    testWidgets('sans avis : message dedie en bas de page', (tester) async {
      routes(detail({}));
      await monterEcran(tester, const CourseDetailScreen(courseId: 1));
      await tester.scrollUntilVisible(find.text(L10n.current.studentCourseNoReviews), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text(L10n.current.studentCourseNoReviews), findsOneWidget);
    });
  });
}
