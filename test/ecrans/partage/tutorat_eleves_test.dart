import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/tutoring_for_students_screen.dart';
import 'package:winplus/student/tutors/my_tutor_bookings_screen.dart';
import 'package:winplus/student/tutors/tutor_public_profile_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

const _contexteParent = {
  'role': 'parent',
  'allowedPayerTypes': ['student', 'parent'],
  'children': [
    {'userId': 3, 'name': 'Paul Eto'},
    {'userId': 4, 'name': 'Zoe Eto'},
  ],
};

const _contexteEtablissement = {
  'role': 'institution',
  'allowedPayerTypes': ['institution'],
  'institutionName': 'Lycee Leclerc',
  'institutionPendingConfirmationCount': 2,
  'institutionStudents': [
    {'userId': 10, 'name': 'Ali', 'groupName': 'Terminale C'},
    {'userId': 11, 'name': 'Bea', 'groupName': 'Terminale C'},
    {'userId': 12, 'name': 'Cyr', 'groupName': 'Premiere D'},
  ],
};

Map<String, dynamic> _attribution(int id, String statut, {Map<String, dynamic> en = const {}}) => {
      'id': id,
      'tutorUserId': 21,
      'tutorName': 'Mme Ngo',
      'assignerType': 'parent',
      'status': statut,
      'subject': 'Maths',
      'beneficiaries': [
        {'userId': 3, 'name': 'Paul Eto'},
      ],
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'parent'}));

  void routes({Map<String, dynamic> contexte = _contexteParent, List<Map<String, dynamic>> attributions = const []}) {
    faux.repond('GET', '/tutor-assignments/booking-context', contexte);
    faux.repond('GET', '/tutor-assignments/mine', attributions);
  }

  void portefeuille({num solde = 25000, List<Map<String, dynamic>> operations = const []}) {
    faux.repond('GET', '/wallet/me', {'data': {'availableXaf': solde, 'minRechargeXaf': 500}});
    faux.repond('GET', '/wallet/me/entries', {'data': {'items': operations, 'total': operations.length}});
  }

  Future<void> monterHaut(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3000);
    await monter(tester, ecran(const TutoringForStudentsScreen()));
    await reseau(tester);
  }

  group('TutoringForStudentsScreen', () {
    testWidgets('parent : chargement, titre « Cours particuliers », bouton d\'attribution et liste vide', (tester) async {
      routes();
      telephone(tester);
      await monter(tester, ecran(const TutoringForStudentsScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringPrivateLessons), findsOneWidget);
      expect(find.text(l.tutoringAssignTutor), findsOneWidget);
      expect(find.text(l.tutoringNoAssignment), findsOneWidget);
      expect(find.text(l.tutoringWalletInstitution), findsNothing);
      expect(faux.recues('GET', '/wallet/me'), isEmpty);
    });

    testWidgets('eleve seul : pas de bouton d\'attribution', (tester) async {
      routes(contexte: const {'role': 'student', 'allowedPayerTypes': ['student']});
      await monterHaut(tester);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('erreur : bouton « Reessayer » qui relit', (tester) async {
      faux.repond('GET', '/tutor-assignments/booking-context', {}, statut: 500);
      await monterHaut(tester);
      final l = L10n.current;
      expect(_bouton(l.commonRetry), findsOneWidget);
      routes();
      await tester.tap(_bouton(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.tutoringNoAssignment), findsOneWidget);
    });

    testWidgets('« Seances reservees » ouvre la liste des reservations', (tester) async {
      routes();
      faux.repond('GET', '/tutor-bookings/mine', []);
      await monterHaut(tester);
      await tester.tap(_bouton(L10n.current.tutoringBookedSessions));
      await reseau(tester);
      expect(find.byType(MyTutorBookingsScreen), findsOneWidget);
    });

    testWidgets('attributions : active (Reserver, Au mois, Mettre fin), en attente (Mettre fin), terminee (rien)', (tester) async {
      routes(attributions: [
        _attribution(1, 'active', en: {'responseNote': 'Avec plaisir'}),
        _attribution(2, 'pending', en: {'tutorName': 'M. Biya', 'groupName': 'Terminale C'}),
        _attribution(3, 'ended', en: {'tutorName': 'Mme Kom'}),
      ]);
      await monterHaut(tester);
      final l = L10n.current;
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text(l.tutoringAssignResponse('Avec plaisir')), findsOneWidget);
      expect(find.textContaining(l.tutoringClassName('Terminale C')), findsOneWidget);
      expect(find.textContaining('${l.tutoringStudentsCountPrefix(1)}Paul Eto · Maths'), findsNWidgets(3));
      expect(_bouton(l.tutoringBook), findsOneWidget);
      expect(_bouton(l.tutoringMonthly), findsOneWidget);
      expect(_bouton(l.tutoringEndAssignment), findsNWidgets(2));
    });

    testWidgets('« Reserver » et « Au mois » ouvrent la fiche du tuteur avec l\'attribution', (tester) async {
      routes(attributions: [_attribution(1, 'active')]);
      await monterHaut(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringMonthly));
      await reseau(tester);
      final fiche = tester.widget<TutorPublicProfileScreen>(find.byType(TutorPublicProfileScreen));
      expect(fiche.userId, 21);
      expect(fiche.assignment?.id, 1);
      expect(fiche.openMonthly, isTrue);
    });

    testWidgets('« Mettre fin » : la carte est mise a jour avec la reponse du serveur', (tester) async {
      routes(attributions: [_attribution(1, 'active')]);
      faux.repond('PUT', '/tutor-assignments/1/end', _attribution(1, 'ended'));
      await monterHaut(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringEndAssignment));
      await reseau(tester);
      expect(faux.recues('PUT', '/tutor-assignments/1/end'), hasLength(1));
      expect(_bouton(l.tutoringEndAssignment), findsNothing);
    });

    testWidgets('« Mettre fin » en erreur : message d\'action impossible', (tester) async {
      routes(attributions: [_attribution(1, 'active')]);
      faux.repond('PUT', '/tutor-assignments/1/end', {}, statut: 500);
      await monterHaut(tester);
      await tester.tap(_bouton(L10n.current.tutoringEndAssignment));
      await reseau(tester);
      expect(find.text(L10n.current.tutoringActionFailed), findsOneWidget);
    });

    group('Etablissement', () {
      testWidgets('titre, solde du portefeuille et dernieres operations', (tester) async {
        faux.repond('GET', '/tutor-assignments/booking-context', _contexteEtablissement);
        faux.repond('GET', '/tutor-assignments/mine', []);
        portefeuille(operations: [
          {'label': 'Recharge', 'amountXaf': 10000},
          {'label': 'Seance Maths', 'amountXaf': -4500},
        ]);
        await monterHaut(tester);
        final l = L10n.current;
        expect(find.text(l.tutoringForStudentsTitle), findsOneWidget);
        expect(find.text(l.tutoringWalletInstitution), findsOneWidget);
        expect(find.text('${fmtXaf(25000)} XAF'), findsOneWidget);
        expect(find.text('+${fmtXaf(10000)} XAF'), findsOneWidget);
        expect(find.text('${fmtXaf(-4500)} XAF'), findsOneWidget);
        expect(faux.recues('GET', '/wallet/me/entries').single.queryParameters, {'source': 'all', 'page': 1, 'pageSize': 10});
      });

      testWidgets('portefeuille en erreur : « Solde indisponible »', (tester) async {
        faux.repond('GET', '/tutor-assignments/booking-context', _contexteEtablissement);
        faux.repond('GET', '/tutor-assignments/mine', []);
        faux.repond('GET', '/wallet/me', {}, statut: 500);
        await monterHaut(tester);
        expect(find.text(L10n.current.tutoringWalletUnavailable), findsOneWidget);
      });

      testWidgets('recharge : fenetre, envoi (operateur, numero, montant), attente puis confirmation', (tester) async {
        faux.repond('GET', '/tutor-assignments/booking-context', _contexteEtablissement);
        faux.repond('GET', '/tutor-assignments/mine', []);
        portefeuille();
        faux.repond('POST', '/wallet/recharge', {'data': {'paymentId': 77}});
        faux.repond('GET', '/payments/77/status', {'status': 'pending'});
        await monterHaut(tester);
        final l = L10n.current;
        await tester.tap(_bouton(l.tutoringTopUp));
        await pomper(tester, const Duration(milliseconds: 400));
        expect(find.text(l.tutoringRechargeTitle), findsOneWidget);
        expect(find.widgetWithText(TextField, l.tutoringRechargeAmount(fmtXaf(500))), findsOneWidget);
        await tester.tap(find.text('Orange Money'));
        await pomper(tester);
        await tester.enterText(find.widgetWithText(TextField, l.tutoringRechargePhone), ' 612345678 ');
        await tester.enterText(find.widgetWithText(TextField, l.tutoringRechargeAmount(fmtXaf(500))), '5000');
        await tester.tap(find.widgetWithText(FilledButton, l.tutoringTopUp));
        await reseau(tester);
        final envoi = faux.recues('POST', '/wallet/recharge').single.data as Map;
        expect(envoi['amount'], 5000);
        expect(envoi['operator'], 'orange');
        expect(envoi['phone'], '612345678');
        expect(envoi['clientRequestId'], isA<String>());
        expect(find.text(l.tutoringRechargeConfirmOnPhone), findsOneWidget);
        expect(find.text(l.tutoringRechargePending), findsOneWidget);
        expect(tester.widget<WinButton>(_bouton(l.tutoringTopUp)).onTap, isNull);
        // Suivi toutes les 5 secondes : toujours en attente, puis confirme.
        await pomper(tester, const Duration(seconds: 5));
        await reseau(tester);
        expect(find.text(l.tutoringRechargePending), findsOneWidget);
        faux.repond('GET', '/payments/77/status', {'status': 'completed'});
        portefeuille(solde: 30000);
        await pomper(tester, const Duration(seconds: 5));
        await reseau(tester);
        expect(find.text(l.tutoringRechargePending), findsNothing);
        expect(find.text('${fmtXaf(30000)} XAF'), findsOneWidget);
        await attendreTexte(tester, l.tutoringRechargeConfirmed);
        expect(find.text(l.tutoringRechargeConfirmed), findsOneWidget);
      });

      testWidgets('recharge refusee par l\'operateur : message d\'echec', (tester) async {
        faux.repond('GET', '/tutor-assignments/booking-context', _contexteEtablissement);
        faux.repond('GET', '/tutor-assignments/mine', []);
        portefeuille();
        faux.repond('POST', '/wallet/recharge', {'data': {'paymentId': 77}});
        faux.repond('GET', '/payments/77/status', {'status': 'failed'});
        await monterHaut(tester);
        final l = L10n.current;
        await tester.tap(_bouton(l.tutoringTopUp));
        await pomper(tester, const Duration(milliseconds: 400));
        await tester.tap(find.widgetWithText(FilledButton, l.tutoringTopUp));
        await reseau(tester);
        await pomper(tester, const Duration(seconds: 5));
        await reseau(tester);
        await attendreTexte(tester, l.tutoringRechargeFailed);
        expect(find.text(l.tutoringRechargeFailed), findsOneWidget);
      });

      testWidgets('recharge : « Annuler » n\'envoie rien ; refus au lancement = message du serveur', (tester) async {
        faux.repond('GET', '/tutor-assignments/booking-context', _contexteEtablissement);
        faux.repond('GET', '/tutor-assignments/mine', []);
        portefeuille();
        faux.repond('POST', '/wallet/recharge', {'error': 'Montant trop faible'}, statut: 400);
        await monterHaut(tester);
        final l = L10n.current;
        await tester.tap(_bouton(l.tutoringTopUp));
        await pomper(tester, const Duration(milliseconds: 400));
        await tester.tap(find.text(l.commonCancel));
        await pomper(tester, const Duration(milliseconds: 400));
        expect(faux.recues('POST', '/wallet/recharge'), isEmpty);
        await tester.tap(_bouton(l.tutoringTopUp));
        await pomper(tester, const Duration(milliseconds: 400));
        await tester.tap(find.widgetWithText(FilledButton, l.tutoringTopUp));
        await reseau(tester);
        expect(find.text('Montant trop faible'), findsOneWidget);
      });
    });
  });

  group('Attribution d\'un tuteur', () {
    Future<void> ouvrirFormulaire(WidgetTester tester, {Map<String, dynamic> contexte = _contexteParent}) async {
      routes(contexte: contexte);
      faux.repond('GET', '/tutor-profile/search', [
        {'userId': 21, 'fullName': 'Mme Ngo', 'subjects': ['Maths', 'Physique']},
        {'userId': 22, 'fullName': 'M. Biya', 'subjects': ['Chimie']},
      ]);
      await monterHaut(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
    }

    testWidgets('parent : intro, recherche initiale (10 tuteurs) et enfants proposes', (tester) async {
      await ouvrirFormulaire(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringAssignIntro), findsOneWidget);
      expect(faux.recues('GET', '/tutor-profile/search').single.queryParameters['pageSize'], 10);
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text('Maths, Physique'), findsOneWidget);
      expect(find.text(l.tutoringAssignChildrenLabel), findsOneWidget);
      expect(find.widgetWithText(WinChip, 'Paul Eto'), findsOneWidget);
    });

    testWidgets('recherche par matiere : la matiere est envoyee ; aucun resultat = message', (tester) async {
      await ouvrirFormulaire(tester);
      final l = L10n.current;
      faux.repond('GET', '/tutor-profile/search', []);
      // La matiere se choisit dans le selecteur.
      await tester.ensureVisible(find.widgetWithText(WinChip, 'SVT'));
      await pomper(tester);
      await tester.tap(find.widgetWithText(WinChip, 'SVT'));
      await pomper(tester);
      await tester.ensureVisible(find.byIcon(PhosphorIconsRegular.magnifyingGlass));
      await pomper(tester);
      await tester.tap(find.byIcon(PhosphorIconsRegular.magnifyingGlass));
      await reseau(tester);
      expect(faux.recues('GET', '/tutor-profile/search').last.queryParameters['subject'], 'SVT');
      expect(find.text(l.tutoringAssignNoTutor), findsOneWidget);
    });

    testWidgets('validations : tuteur obligatoire, puis au moins un enfant', (tester) async {
      await ouvrirFormulaire(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await pomper(tester);
      expect(find.text(l.tutoringAssignChooseTutor), findsOneWidget);
      await tester.tap(find.text('Mme Ngo'));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await pomper(tester);
      expect(find.text(l.tutoringAssignChooseChild), findsOneWidget);
      expect(faux.recues('POST', '/tutor-assignments'), isEmpty);
    });

    testWidgets('envoi : tuteur, enfant, matiere et mot ; la nouvelle attribution apparait en tete', (tester) async {
      await ouvrirFormulaire(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-assignments', _attribution(9, 'pending', en: {'tutorName': 'M. Biya'}));
      await tester.tap(find.text('M. Biya'));
      await pomper(tester);
      expect(find.byIcon(PhosphorIconsFill.radioButton), findsOneWidget);
      await tester.tap(find.widgetWithText(WinChip, 'Zoe Eto'));
      await pomper(tester);
      await tester.ensureVisible(find.widgetWithText(WinChip, 'Chimie'));
      await pomper(tester);
      await tester.tap(find.widgetWithText(WinChip, 'Chimie'));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, l.tutoringAssignNoteHint), ' Deux fois par semaine ');
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-assignments').single.data, {
        'tutorUserId': 22,
        'studentUserIds': [4],
        'subject': 'Chimie',
        'note': 'Deux fois par semaine',
      });
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.tutoringAssignIntro), findsNothing);
      expect(find.text('M. Biya'), findsOneWidget);
    });

    testWidgets('refus du serveur : son message en alerte', (tester) async {
      await ouvrirFormulaire(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-assignments', {'message': 'Deja attribue'}, statut: 409);
      await tester.tap(find.text('Mme Ngo'));
      await tester.tap(find.widgetWithText(WinChip, 'Paul Eto'));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await reseau(tester);
      expect(find.text('Deja attribue'), findsOneWidget);
    });

    testWidgets('etablissement : classes entieres, eleves en attente de confirmation, classe envoyee', (tester) async {
      await ouvrirFormulaire(tester, contexte: _contexteEtablissement);
      final l = L10n.current;
      faux.repond('POST', '/tutor-assignments', _attribution(9, 'pending'));
      expect(find.text(l.tutoringAssignStudentsLabel), findsOneWidget);
      expect(find.text(l.tutoringAssignPending(2)), findsOneWidget);
      expect(find.widgetWithText(WinChip, l.tutoringAssignAllClass('Terminale C')), findsOneWidget);
      await tester.tap(find.widgetWithText(WinChip, l.tutoringAssignAllClass('Terminale C')));
      await pomper(tester);
      // Les eleves de la classe choisie ne sont plus proposes un par un.
      expect(find.widgetWithText(WinChip, 'Ali'), findsNothing);
      expect(find.widgetWithText(WinChip, 'Cyr'), findsOneWidget);
      await tester.tap(find.text('Mme Ngo'));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-assignments').single.data, {
        'tutorUserId': 21,
        'studentUserIds': <int>[],
        'groupName': 'Terminale C',
      });
    });

    testWidgets('etablissement sans eleve : message dedie ; validation « eleves ou classe »', (tester) async {
      await ouvrirFormulaire(tester, contexte: const {'role': 'institution', 'allowedPayerTypes': ['institution']});
      final l = L10n.current;
      expect(find.text(l.tutoringAssignNoStudent), findsOneWidget);
      await tester.tap(find.text('Mme Ngo'));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringAssignSubmit));
      await pomper(tester);
      expect(find.text(l.tutoringAssignChooseStudents), findsOneWidget);
    });
  });
}

/// Les messages s'affichent l'un apres l'autre : attend (8 s au plus) que
/// [texte] apparaisse.
Future<void> attendreTexte(WidgetTester tester, String texte) async {
  for (var i = 0; i < 16 && find.text(texte).evaluate().isEmpty; i++) {
    await pomper(tester, const Duration(milliseconds: 500));
  }
}
