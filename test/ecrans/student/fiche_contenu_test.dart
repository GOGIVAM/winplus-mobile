import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/shared/subscription/subscription_notifier.dart';
import 'package:winplus/shared/shop/account_required_purchase_screen.dart';
import 'package:winplus/student/content_detail_screen.dart';
import 'package:winplus/student/document_viewer_screen.dart';
import 'package:winplus/student/quiz_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Content _contenu({
  String id = '12',
  bool gratuit = false,
  int prix = 1500,
  ContentType type = ContentType.epreuve,
  bool corrige = false,
  List<ContentReview> avis = const [],
}) =>
    Content(
      id: id,
      title: 'Epreuve de maths BAC',
      subjectId: 'math',
      exam: 'BAC',
      level: 'Terminale',
      type: type,
      year: 2024,
      price: prix,
      rating100: 43,
      ratings: 8,
      downloads: 120,
      free: gratuit,
      hasCorrection: corrige,
      description: 'Une epreuve complete',
      teacher: 'Mme Ngo',
      reviews: avis,
    );

const _sessionPrefs = {'access_token': 'jeton'};

/// Ecran haut : la barre d'actions fixee en bas ne recouvre plus les
/// boutons et les notes du bas de la fiche.
Future<void> _monterHaut(WidgetTester tester, Widget fiche, {SubscriptionNotifier? abonnement}) async {
  telephone(tester);
  tester.view.physicalSize = const Size(800, 3200);
  await monter(tester, ecran(fiche, abonnement: abonnement));
  await reseau(tester);
}

void main() {
  late FauxReseau faux;
  late Directory dossier;

  // Le catalogue de quiz (ouvert par « Commencer le quiz ») lit son cache
  // local : boite en memoire, pour ne pas bloquer le temps simule.
  setUpAll(() async {
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.studentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() {
    faux = preparerEnvironnement();
    faux.repond('GET', '/subjects', {'items': []});
  });

  group('Contenu', () {
    testWidgets('titre, auteur, note, vues, annee, description et avis absents', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      final l = L10n.current;
      expect(find.text('Epreuve de maths BAC'), findsOneWidget);
      expect(find.text(l.studentDetailBy('Mme Ngo')), findsOneWidget);
      expect(find.text(l.studentDetailRatingCount('4.3', 8)), findsOneWidget);
      expect(find.text(l.studentDetailViews(120)), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('Une epreuve complete'), findsOneWidget);
      expect(find.text('${fmtXaf(1500)} XAF'), findsOneWidget);
    });

    testWidgets('avis existants affiches', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(avis: const [ContentReview('Ada', 'Tres utile', 40, '5 janv.')])));
      await tester.scrollUntilVisible(find.text('Tres utile'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Ada'), findsWidgets);
      expect(find.text('Tres utile'), findsOneWidget);
      expect(find.text(L10n.current.studentDetailNoReviews), findsNothing);
    });

    testWidgets('sans avis : message dedie', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.scrollUntilVisible(find.text(L10n.current.studentDetailNoReviews), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(L10n.current.studentDetailNoReviews), findsOneWidget);
    });

    testWidgets('contenus similaires : le contenu courant est exclu, trois au plus', (tester) async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 12, 'title': 'Lui-meme'},
          {'id': 13, 'title': 'Voisin 1'},
          {'id': 14, 'title': 'Voisin 2'},
        ],
      });
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.scrollUntilVisible(find.text('Voisin 1'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Voisin 2'), findsOneWidget);
      expect(find.text('Lui-meme'), findsNothing);
      expect(faux.recues('GET', '/subjects').single.queryParameters['category'], 'math');
      expect(faux.recues('GET', '/subjects').single.queryParameters['pageSize'], 5);
    });
  });

  group('Barre d\'actions', () {
    testWidgets('contenu gratuit : lecture dans l\'application ; avec corrige : bouton supplementaire', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(gratuit: true, corrige: true)));
      final l = L10n.current;
      expect(_bouton(l.studentDetailReadInApp), findsOneWidget);
      expect(_bouton(l.studentDetailViewAnswers), findsOneWidget);
      expect(_bouton(l.studentDetailAddToCartPrice(fmtXaf(1500))), findsNothing);
    });

    testWidgets('livre gratuit : libelle « lire le livre »', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(gratuit: true, type: ContentType.livre)));
      expect(_bouton(L10n.current.studentDetailReadBook), findsOneWidget);
    });

    testWidgets('lire ouvre la visionneuse sur l\'identifiant du contenu ; corrige = kind=correction', (tester) async {
      faux.repond('GET', '/subjects/12/view', {}, statut: 404);
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(gratuit: true, corrige: true)));
      await tester.tap(_bouton(L10n.current.studentDetailReadInApp));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(DocumentViewerScreen), findsOneWidget);
      expect(faux.recues('GET', '/subjects/12/view').single.queryParameters, isEmpty);
      // La visionneuse n'a pas de bouton retour standard : on ferme la page.
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(_bouton(L10n.current.studentDetailViewAnswers));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(faux.recues('GET', '/subjects/12/view').last.queryParameters, {'kind': 'correction'});
    });

    testWidgets('contenu de demonstration (identifiant non numerique) : message sans document', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(id: 'demo', gratuit: true)));
      await tester.tap(_bouton(L10n.current.studentDetailReadInApp));
      await pomper(tester);
      expect(find.text(L10n.current.studentDetailDemoNoDocument), findsOneWidget);
    });

    testWidgets('quiz : bouton « demarrer » vers le catalogue de quiz', (tester) async {
      faux.repond('GET', '/quizzes', []);
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(type: ContentType.quiz)));
      await tester.tap(_bouton(L10n.current.studentDetailStartQuiz));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(QuizHubScreen), findsOneWidget);
    });

    testWidgets('contenu payant : prix du panier et lien vers les abonnements', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      final l = L10n.current;
      expect(_bouton(l.studentDetailAddToCartPrice(fmtXaf(1500))), findsOneWidget);
      expect(find.text(l.studentDetailOrSubscriptions), findsOneWidget);
      expect(_bouton(l.studentDetailReadInApp), findsNothing);
    });

    testWidgets('droit « acces au catalogue » : lecture directe d\'un contenu payant', (tester) async {
      final abo = await abonnementAvecDroits(tester, faux, {'catalog.access': true});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()), abonnement: abo);
      expect(_bouton(L10n.current.studentDetailReadInApp), findsOneWidget);
      expect(_bouton(L10n.current.studentDetailAddToCartPrice(fmtXaf(1500))), findsNothing);
    });

    testWidgets('sans compte : « ajouter au panier » demande de creer un compte', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.tap(_bouton(L10n.current.studentDetailAddToCartPrice(fmtXaf(1500))));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(AccountRequiredPurchaseScreen), findsOneWidget);
      expect(faux.recues('POST', '/cart/items'), isEmpty);
    });

    testWidgets('connecte : ajout au panier serveur puis message avec lien « voir le panier »', (tester) async {
      faux = preparerEnvironnement(prefs: _sessionPrefs);
      faux.repond('GET', '/subjects', {'items': []});
      faux.repond('GET', '/subjects/12/view-access', {'document': 'locked', 'correction': 'locked'});
      faux.repond('POST', '/cart/items', {'items': [], 'itemsCount': 1});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.tap(_bouton(L10n.current.studentDetailAddToCartPrice(fmtXaf(1500))));
      await reseau(tester);
      expect(faux.recues('POST', '/cart/items').single.data, {'subjectId': 12});
      expect(find.text(L10n.current.studentDetailAddedToCart), findsOneWidget);
      expect(find.text(L10n.current.studentDetailViewCart), findsOneWidget);
    });

    testWidgets('ajout au panier refuse : message d\'erreur', (tester) async {
      faux = preparerEnvironnement(prefs: _sessionPrefs);
      faux.repond('GET', '/subjects', {'items': []});
      faux.repond('GET', '/subjects/12/view-access', {'document': 'locked'});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.tap(_bouton(L10n.current.studentDetailAddToCartPrice(fmtXaf(1500))));
      await reseau(tester);
      expect(find.text(L10n.current.studentDetailAddToCartError), findsOneWidget);
    });

    testWidgets('apercu du serveur : bouton « lire les N premieres pages »', (tester) async {
      faux = preparerEnvironnement(prefs: _sessionPrefs);
      faux.repond('GET', '/subjects', {'items': []});
      faux.repond('GET', '/subjects/12/view-access', {'document': 'preview', 'previewPages': 3});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      expect(_bouton(L10n.current.studentDetailReadPreview(3)), findsOneWidget);
    });

    testWidgets('acces complet reconnu par le serveur : lecture directe', (tester) async {
      faux = preparerEnvironnement(prefs: _sessionPrefs);
      faux.repond('GET', '/subjects', {'items': []});
      faux.repond('GET', '/subjects/12/view-access', {'document': 'full', 'correction': 'full'});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu(corrige: true)));
      expect(_bouton(L10n.current.studentDetailReadInApp), findsOneWidget);
      expect(_bouton(L10n.current.studentDetailViewAnswers), findsOneWidget);
    });
  });

  group('Notes et etiquettes personnelles', () {
    testWidgets('etiquettes rapides : cocher memorise le choix pour ce contenu', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      final tag = find.text(L10n.current.studentDetailTagToRevise);
      await tester.scrollUntilVisible(tag, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(tag);
      await pomper(tester);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(jsonDecode(prefs!.getString('tags_12')!), ['À réviser']);
    });

    testWidgets('ajouter une note : saisie, enregistrement, memorisation', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      final l = L10n.current;
      await tester.scrollUntilVisible(find.text(l.studentDetailAddNote), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l.studentDetailAddNote));
      await pomper(tester);
      await tester.enterText(find.byType(TextField), 'Revoir le chapitre 3');
      await tester.tap(_bouton(l.commonSave));
      await pomper(tester);
      expect(find.text('Revoir le chapitre 3'), findsOneWidget);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(jsonDecode(prefs!.getString('notes_12')!), ['Revoir le chapitre 3']);
    });

    testWidgets('note vide ou annulee : rien n\'est ajoute', (tester) async {
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      final l = L10n.current;
      await tester.scrollUntilVisible(find.text(l.studentDetailAddNote), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l.studentDetailAddNote));
      await pomper(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(_bouton(l.commonSave));
      await pomper(tester);
      expect(find.byIcon(PhosphorIconsRegular.note), findsNothing);
      await tester.tap(find.text(l.studentDetailAddNote));
      await pomper(tester);
      await tester.tap(_bouton(l.commonCancel));
      await pomper(tester);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('notes et etiquettes memorisees sont rechargees a l\'ouverture ; la croix supprime une note', (tester) async {
      faux = preparerEnvironnement(prefs: {
        'notes_12': jsonEncode(['Ancienne note']),
        'tags_12': jsonEncode(['Difficile']),
      });
      faux.repond('GET', '/subjects', {'items': []});
      await _monterHaut(tester, ContentDetailScreen(content: _contenu()));
      await tester.scrollUntilVisible(find.text('Ancienne note'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Ancienne note'), findsOneWidget);
      await tester.tap(find.byIcon(PhosphorIconsRegular.x).last);
      await pomper(tester);
      expect(find.text('Ancienne note'), findsNothing);
    });

    testWidgets('le coeur de la barre bascule le favori du contenu', (tester) async {
      final c = _contenu();
      await _monterHaut(tester, ContentDetailScreen(content: c));
      await tester.tap(find.byIcon(PhosphorIconsRegular.heart));
      await pomper(tester);
      expect(c.fav, isTrue);
      expect(find.byIcon(PhosphorIconsFill.heart), findsOneWidget);
    });
  });
}
