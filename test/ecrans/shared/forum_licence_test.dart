import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/institution/license_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/forum/forum_screen.dart';
import 'package:winplus/shared/forum/new_thread_screen.dart';
import 'package:winplus/shared/forum/thread_detail_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('forumCategoryLabel', () {
    testWidgets('traduit les quatre categories et laisse les autres telles quelles', (tester) async {
      await monterEcran(tester, const SizedBox());
      final l = L10n.current;
      expect(forumCategoryLabel(l, 'Questions'), l.forumCatQuestions);
      expect(forumCategoryLabel(l, 'Discussions'), l.forumCatDiscussions);
      expect(forumCategoryLabel(l, 'Ressources'), l.forumCatResources);
      expect(forumCategoryLabel(l, 'Aide'), l.forumCatHelp);
      expect(forumCategoryLabel(l, 'Autre'), 'Autre');
    });
  });

  group('ForumScreen', () {
    testWidgets('sujets : titre, auteur, reponses, votes, badge « resolu » et role', (tester) async {
      faux.repond('GET', '/forums/threads', {
        'threads': [
          {'id': 1, 'title': 'Comment factoriser ?', 'authorName': 'Ada', 'authorRole': 'student', 'repliesCount': 3, 'upvotes': 5, 'isSolved': true},
          {'id': 2, 'title': 'Ressources BAC', 'authorName': 'Lycee', 'authorRole': 'institution', 'isVerifiedInstitution': true},
        ],
        'total': 2,
      });
      await monterEcran(tester, const ForumScreen());
      final l = L10n.current;
      expect(find.text('Comment factoriser ?'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text(l.forumSolved), findsOneWidget);
      expect(find.text(l.roleStudent), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 20});
    });

    testWidgets('categorie sans sujet : message dedie', (tester) async {
      faux.repond('GET', '/forums/threads', {'threads': [], 'total': 0});
      await monterEcran(tester, const ForumScreen());
      expect(find.text(L10n.current.forumEmptyCategory), findsOneWidget);
    });

    testWidgets('erreur serveur : le message d\'erreur remplace la liste', (tester) async {
      faux.repond('GET', '/forums/threads', {}, statut: 500);
      await monterEcran(tester, const ForumScreen());
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(L10n.current.forumEmptyCategory), findsNothing);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('choisir une categorie recharge avec le filtre ; « Toutes » l\'enleve', (tester) async {
      faux.repond('GET', '/forums/threads', {'threads': [], 'total': 0});
      await monterEcran(tester, const ForumScreen());
      // Les categories defilent a l'horizontale : on amene chacune a l'ecran.
      final bande = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right).first;
      Future<void> categorie(String libelle, double pas) async {
        await tester.scrollUntilVisible(find.text(libelle), pas, scrollable: bande);
        await tester.ensureVisible(find.text(libelle));
        await pomper(tester);
      }

      await categorie(L10n.current.forumCatHelp, 80);
      await tester.tap(find.text(L10n.current.forumCatHelp));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters['category'], 'Aide');
      await categorie(L10n.current.forumAll, -80);
      await tester.tap(find.text(L10n.current.forumAll));
      await reseau(tester);
      expect(faux.requetes.last.queryParameters.containsKey('category'), isFalse);
    });

    testWidgets('le bouton « + » ouvre la creation de sujet', (tester) async {
      faux.repond('GET', '/forums/threads', {'threads': [], 'total': 0});
      await monterEcran(tester, const ForumScreen());
      await tester.tap(find.byIcon(Icons.add));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.byType(NewThreadScreen), findsOneWidget);
    });

    testWidgets('toucher un sujet ouvre son detail', (tester) async {
      faux.repond('GET', '/forums/threads', {
        'threads': [
          {'id': 7, 'title': 'Sujet sept', 'authorName': 'Ada'},
        ],
        'total': 1,
      });
      faux.repond('GET', '/forums/threads/7/posts', []);
      await monterEcran(tester, const ForumScreen());
      await tester.tap(find.text('Sujet sept'));
      await reseau(tester);
      expect(find.byType(ThreadDetailScreen), findsOneWidget);
    });
  });

  group('NewThreadScreen', () {
    testWidgets('titre ou contenu vide : rien n\'est publie', (tester) async {
      await monterEcran(tester, const NewThreadScreen());
      await tester.ensureVisible(_bouton(L10n.current.forumPublish));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.forumPublish));
      await reseau(tester);
      expect(faux.requetes, isEmpty);
      await tester.enterText(find.byType(TextField).at(0), 'Mon sujet');
      await tester.tap(_bouton(L10n.current.forumPublish));
      await reseau(tester);
      expect(faux.requetes, isEmpty, reason: 'le contenu manque encore');
    });

    testWidgets('publication : categorie par defaut « Questions » et textes rognes', (tester) async {
      faux.repond('POST', '/forums/threads', {});
      await monterEcran(tester, const NewThreadScreen());
      await tester.enterText(find.byType(TextField).at(0), '  Mon sujet ');
      await tester.enterText(find.byType(TextField).at(1), ' Le contenu ');
      await tester.tap(find.text(L10n.current.forumCatHelp));
      await pomper(tester);
      await tester.ensureVisible(_bouton(L10n.current.forumPublish));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.forumPublish));
      await reseau(tester);
      expect(faux.recues('POST', '/forums/threads').single.data, {'title': 'Mon sujet', 'content': 'Le contenu', 'category': 'Aide'});
    });

    testWidgets('echec serveur : message dans la barre d\'information, l\'ecran reste', (tester) async {
      await monterEcran(tester, const NewThreadScreen());
      await tester.enterText(find.byType(TextField).at(0), 'Sujet');
      await tester.enterText(find.byType(TextField).at(1), 'Contenu');
      await tester.ensureVisible(_bouton(L10n.current.forumPublish));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.forumPublish));
      await reseau(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(NewThreadScreen), findsOneWidget);
    });
  });

  group('LicenseScreen', () {
    testWidgets('serveur en erreur : message du serveur ou message par defaut', (tester) async {
      faux.repond('GET', '/institution/license', {'error': 'Acces refuse'}, statut: 403);
      await monterEcran(tester, const LicenseScreen());
      expect(find.text('Acces refuse'), findsOneWidget);
    });

    testWidgets('erreur sans message : texte par defaut', (tester) async {
      faux.repond('GET', '/institution/license', {}, statut: 500);
      await monterEcran(tester, const LicenseScreen());
      expect(find.text(L10n.current.instLicenseUnavailable), findsOneWidget);
    });

    testWidgets('licence en cours : sieges utilises et liberation d\'un siege', (tester) async {
      faux.repond('GET', '/institution/license', {
        'license': {'status': 'active', 'studentSeats': 100, 'studentSeatsUsed': 40, 'teacherSeats': 5, 'teacherSeatsUsed': 2, 'aiBudgetUsedPercent': 12, 'autoRenew': true, 'startDate': '2026-01-05T00:00:00Z', 'endDate': '2027-01-05T00:00:00Z'},
        'seats': [
          {'id': 11, 'kind': 'student', 'name': 'Ada Eto'},
          {'id': 12, 'kind': 'teacher', 'userId': 9},
        ],
      });
      faux.repond('DELETE', '/institution/license/seats/11', {'message': 'Siege libere'});
      await monterEcran(tester, const LicenseScreen());
      final l = L10n.current;
      expect(find.text(l.instLicenseStudentSeatsUsed('40', '100')), findsOneWidget);
      expect(find.text(l.instLicenseTeacherSeatsUsed('2', '5')), findsOneWidget);
      expect(find.text(l.instLicensePeriod('05/01/2026', '05/01/2027')), findsOneWidget);
      expect(find.text('Ada Eto'), findsOneWidget);
      expect(find.text(l.instLicenseAccount('9')), findsOneWidget);
      await tester.tap(find.text(l.instLicenseRelease).first);
      await reseau(tester);
      expect(faux.recues('DELETE', '/institution/license/seats/11'), hasLength(1));
      expect(find.text('Siege libere'), findsOneWidget);
    });

    testWidgets('licence d\'essai : pas d\'interrupteur de renouvellement', (tester) async {
      faux.repond('GET', '/institution/license', {
        'license': {'status': 'trialing', 'studentSeats': 10, 'studentSeatsUsed': 1, 'teacherSeats': 1, 'teacherSeatsUsed': 0, 'aiBudgetUsedPercent': 0},
        'seats': [],
      });
      await monterEcran(tester, const LicenseScreen());
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('sans licence : grille tarifaire, devis et achat', (tester) async {
      faux.repond('GET', '/institution/license', {
        'license': null,
        'grid': {
          'tiers': [
            {'yearlyPerSeatTtc': 1500, 'fromSeats': 20},
          ],
          'minSeats': 20,
          'studentsPerTeacherSeat': 25,
        },
      });
      faux.repond('GET', '/institution/license/quote', {'pricePerSeatTtc': 1500, 'teacherSeats': 1, 'endsAt': '2027-01-05T00:00:00Z', 'amountDueTtc': 30000});
      faux.repond('POST', '/institution/license/purchase', {'message': 'Licence activee'});
      await monterEcran(tester, const LicenseScreen());
      final l = L10n.current;
      expect(find.text(l.instLicenseSubscribeTitle), findsOneWidget);
      expect(faux.recues('GET', '/institution/license/quote').single.queryParameters, {'students': 20, 'term': 'year'});
      expect(find.textContaining(l.instLicenseQuoteTotal(fmtXaf(30000)), findRichText: true), findsOneWidget);
      final achat = _bouton(l.instLicensePurchase);
      await tester.ensureVisible(achat);
      await pomper(tester);
      await tester.tap(achat);
      await reseau(tester);
      expect(faux.recues('POST', '/institution/license/purchase').single.data, {'studentSeats': 20, 'term': 'year', 'autoRenew': true});
    });

    testWidgets('devis refuse : alerte d\'erreur et achat inactif', (tester) async {
      faux.repond('GET', '/institution/license', {
        'license': null,
        'grid': {'tiers': [], 'minSeats': 20, 'studentsPerTeacherSeat': 25},
      });
      faux.repond('GET', '/institution/license/quote', {'error': 'Minimum 20 eleves'}, statut: 400);
      await monterEcran(tester, const LicenseScreen());
      expect(find.text('Minimum 20 eleves'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.instLicensePurchase)).onTap, isNull);
    });
  });
}
