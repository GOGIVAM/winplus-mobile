import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_profile_service.dart';
import 'package:winplus/student/tutors/tutor_booking_flow_screen.dart';
import 'package:winplus/student/tutors/tutor_engagement_flow_screen.dart';
import 'package:winplus/student/tutors/tutor_policy_widgets.dart';
import 'package:winplus/student/tutors/tutor_pricing_widgets.dart';
import 'package:winplus/student/tutors/tutor_public_profile_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import '../../helpers/appli.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

/// Politique publique servie par GET /tutor-policy. Le service la garde en
/// memoire apres le premier succes : toutes les routes de ce fichier servent
/// donc la meme.
const _politique = {
  'version': '2026-03-01',
  'disputeWindowHours': 24,
  'notchPayFeePercent': 3,
  'sections': [
    {
      'id': 'annulation',
      'title': 'Annulation',
      'paragraphs': ['Premier paragraphe', 'Second paragraphe'],
    },
  ],
};

Map<String, dynamic> _profil([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'userId': 21,
      'fullName': 'Mme Ngo',
      'title': 'Professeure agregee',
      'hourlyRateXaf': 800,
      'subjects': ['Mathematiques', 'Physique'],
      'levels': ['Terminale'],
      'fullRefundHours': 24,
      'partialRefundPercent': 50,
      'noRefundHours': 2,
      ...en,
    };

String _jour(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  void routes(Map<String, dynamic> profil, {List<Map<String, dynamic>> creneaux = const []}) {
    faux.repond('GET', '/tutor-profile/21', profil);
    // Le calendrier est lu pour deux semaines : les creneaux ne sont servis
    // qu'a la premiere (celle d'aujourd'hui) pour ne pas etre dupliques.
    faux.sur('GET', '/tutor-bookings/tutor/21/calendar', (o) {
      final debut = o.queryParameters['weekStart'];
      return FauxReponse(debut == _jour(DateTime.now()) ? creneaux : []);
    });
    faux.repond('GET', '/tutor-policy', _politique);
  }

  // Ce groupe passe en premier : le service garde la politique en memoire des
  // son premier succes, et le premier test a besoin qu'elle soit en erreur.
  group('TutorCancellationPolicyCard et politique publique', () {
    testWidgets('serveur de politique en erreur : les lignes de base restent affichees, sans frais ni contestation', (tester) async {
      faux.repond('GET', '/tutor-policy', {}, statut: 500);
      await monterEcran(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TutorCancellationPolicyCard(fullRefundHours: 48, partialRefundPercent: 30, noRefundHours: 0))),
      );
      final l = L10n.current;
      expect(find.text(l.tutoringPolicyFull(48)), findsOneWidget);
      // Aucun delai sans remboursement : le remboursement reste possible jusqu'au debut.
      expect(find.text(l.tutoringPolicyUntilStart), findsOneWidget);
      expect(find.text(l.tutoringPolicyWallet), findsOneWidget);
      expect(find.textContaining('Après la séance'), findsNothing);
    });

    testWidgets('delai total egal au delai partiel : pas de ligne de remboursement partiel ; mode compact : pas de ligne « tuteur annule »', (tester) async {
      faux.repond('GET', '/tutor-policy', _politique);
      await monterEcran(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TutorCancellationPolicyCard(fullRefundHours: 6, partialRefundPercent: 50, noRefundHours: 6, compact: true))),
      );
      final l = L10n.current;
      expect(find.text(l.tutoringPolicyPartial(50, 6, 6)), findsNothing);
      expect(find.text(l.tutoringPolicyTutorCancels), findsNothing);
      expect(find.text(l.tutoringPolicyNone(6)), findsOneWidget);
    });

    testWidgets('« Lire la politique » ouvre la page publique : delais, frais, sections et version', (tester) async {
      faux.repond('GET', '/tutor-policy', _politique);
      await monterEcran(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TutorCancellationPolicyCard(fullRefundHours: 24, partialRefundPercent: 50, noRefundHours: 2))),
      );
      await tester.tap(find.text(L10n.current.tutoringPolicyRead));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      final l = L10n.current;
      expect(find.byType(TutorPolicyScreen), findsOneWidget);
      expect(find.text(l.studentHubTutorPolicy), findsOneWidget);
      expect(find.text('24 h'), findsOneWidget);
      expect(find.text(l.tutoringPercent('3')), findsOneWidget);
      expect(find.text('Annulation'), findsOneWidget);
      expect(find.text('Premier paragraphe'), findsOneWidget);
      expect(find.text('Second paragraphe'), findsOneWidget);
      expect(find.textContaining('Version du'), findsOneWidget);
    });
  });

  group('TutorPublicProfileScreen', () {
    testWidgets('chargement puis en-tete : nom, titre, avis et boutons', (tester) async {
      routes(_profil({'averageRating': 4.5, 'reviewCount': 12}));
      telephone(tester);
      await monter(tester, ecran(const TutorPublicProfileScreen(userId: 21)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text('Professeure agregee'), findsOneWidget);
      expect(find.text(l.tutoringRatingReviews('4.5', 12)), findsOneWidget);
      expect(_bouton(l.tutoringBookSession), findsOneWidget);
    });

    testWidgets('sans avis : « Pas encore d\'avis » ; sans nom : nom par defaut', (tester) async {
      routes(_profil({'fullName': null, 'title': null}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text(l.tutoringNoReviewsYet), findsOneWidget);
      expect(find.text(l.tutoringDefaultName), findsOneWidget);
    });

    testWidgets('badges : diplome verifie, presentiel verifie, caution ; presentiel bloque = en ligne uniquement', (tester) async {
      routes(_profil({
        'isDiplomaVerified': true,
        'isInPersonVerified': true,
        'endorsedByInstitutions': ['Lycee Leclerc'],
      }));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text(l.tutoringDiplomaVerified), findsOneWidget);
      expect(find.text(l.tutoringInPersonVerified), findsOneWidget);
      expect(find.text(l.tutoringEndorsedBy('Lycee Leclerc')), findsOneWidget);
      expect(find.text(l.tutoringOnlineOnly), findsNothing);
    });

    testWidgets('presentiel suspendu : pas de badge « Verifie pour le presentiel »', (tester) async {
      routes(_profil({'isInPersonVerified': true, 'inPersonSuspended': true, 'inPersonAllowed': false}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text(l.tutoringInPersonVerified), findsNothing);
      expect(find.text(l.tutoringOnlineOnly), findsOneWidget);
    });

    testWidgets('erreur : message puis « Reessayer »', (tester) async {
      faux.repond('GET', '/tutor-profile/21', {'error': 'x'}, statut: 404);
      faux.repond('GET', '/tutor-policy', _politique);
      faux.repond('GET', '/tutor-bookings/tutor/21/calendar', []);
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text(l.tutoringProfileLoadError), findsOneWidget);
      expect(_bouton(l.tutoringBookSession), findsNothing);
      routes(_profil());
      await tester.tap(_bouton(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.tutoringProfileLoadError), findsNothing);
      expect(find.text('Mme Ngo'), findsOneWidget);
    });

    testWidgets('biographie, video, matieres et niveaux (« Non renseigne » si vides)', (tester) async {
      routes(_profil({'tutorBio': 'Dix ans d\'experience', 'videoUrl': 'https://exemple.test/v'}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text('Dix ans d\'experience'), findsOneWidget);
      expect(find.text(l.tutoringIntroVideo), findsOneWidget);
      expect(find.text('https://exemple.test/v'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Physique'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Mathematiques'), findsOneWidget);
      expect(find.text('Terminale'), findsOneWidget);
    });

    testWidgets('matieres et niveaux vides : « Non renseigne » deux fois', (tester) async {
      routes(_profil({'subjects': [], 'levels': []}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      await tester.scrollUntilVisible(find.text(L10n.current.tutoringLevels), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(L10n.current.tutoringNotSpecified), findsNWidgets(2));
    });

    testWidgets('tarif : simple, a partir de (grille) et non communique', (tester) async {
      routes(_profil());
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(find.text('800 XAF'), findsOneWidget);
      expect(find.text(L10n.current.tutoringPerHour), findsOneWidget);
      expect(find.text(L10n.current.tutoringFrom), findsNothing);

      await monter(tester, const SizedBox());
      routes(_profil({
        'fromHourlyRateXaf': 500,
        'rates': [
          {'subject': 'Mathematiques', 'mode': 'online', 'hourlyRateXaf': 500},
        ],
      }));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text('500 XAF'), findsOneWidget);
      expect(find.text(l.tutoringFrom), findsOneWidget);
      expect(find.text('• ${l.tutoringRateLine('Mathematiques', l.tutoringModeOnlineLower, '500')}'), findsOneWidget);
      expect(find.text(l.tutoringProrata), findsOneWidget);

      await monter(tester, const SizedBox());
      routes(_profil({'hourlyRateXaf': null}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(find.text(l.tutoringRateNotGiven), findsOneWidget);
    });

    testWidgets('seance d\'essai : gratuite ou payante', (tester) async {
      routes(_profil({'trialSessionEnabled': true, 'trialSessionPriceXaf': 0}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(find.text(L10n.current.tutoringTrialFree), findsOneWidget);

      await monter(tester, const SizedBox());
      routes(_profil({'trialSessionEnabled': true, 'trialSessionPriceXaf': 300}));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(find.text(L10n.current.tutoringTrialPrice('300')), findsOneWidget);
    });

    testWidgets('politique d\'annulation du tuteur : lignes de remboursement et frais du serveur', (tester) async {
      routes(_profil());
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      await tester.scrollUntilVisible(find.text(l.tutoringPolicyCardTitle), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.tutoringPolicyFull(24)), findsOneWidget);
      expect(find.text(l.tutoringPolicyPartial(50, 2, 24)), findsOneWidget);
      expect(find.text(l.tutoringPolicyNone(2)), findsOneWidget);
      expect(find.text(l.tutoringPolicyWalletFee('3')), findsOneWidget);
      expect(find.text(l.tutoringPolicyDispute(24)), findsOneWidget);
    });

    testWidgets('calendrier vide : alerte « aucun creneau »', (tester) async {
      routes(_profil());
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      await tester.scrollUntilVisible(find.text(L10n.current.tutoringNoSlotAvailable), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(L10n.current.tutoringNoSlotAvailable), findsOneWidget);
    });

    testWidgets('calendrier en panne : la fiche reste consultable', (tester) async {
      routes(_profil());
      faux.repond('GET', '/tutor-bookings/tutor/21/calendar', {}, statut: 500);
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text(L10n.current.tutoringProfileLoadError), findsNothing);
    });

    testWidgets('creneaux du jour : reservable en vert, complet non cliquable ; toucher ouvre la reservation', (tester) async {
      final auj = DateTime.now();
      routes(_profil(), creneaux: [
        {'date': _jour(auj), 'startTime': '15:00', 'availableDurationsMinutes': [60], 'isBookable': true},
        {'date': _jour(auj), 'startTime': '17:30', 'isBookable': false},
      ]);
      faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'student'});
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      await tester.scrollUntilVisible(find.text('15:00'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('17:30'), findsOneWidget);
      // Creneau complet : rien ne se passe.
      await tester.tap(find.text('17:30'));
      await reseau(tester);
      expect(find.byType(TutorBookingFlowScreen), findsNothing);
      await tester.tap(find.text('15:00'));
      await reseau(tester);
      final flux = tester.widget<TutorBookingFlowScreen>(find.byType(TutorBookingFlowScreen));
      expect(flux.profile.userId, 21);
      expect(flux.initialOccurrence?.startTime, '15:00');
    });

    testWidgets('« Reserver une seance » ouvre la reservation avec les sujets de la recherche', (tester) async {
      routes(_profil());
      faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'student'});
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21, initialTopics: ['derivees']));
      await tester.tap(_bouton(L10n.current.tutoringBookSession));
      await reseau(tester);
      final flux = tester.widget<TutorBookingFlowScreen>(find.byType(TutorBookingFlowScreen));
      expect(flux.initialTopics, ['derivees']);
      expect(flux.initialOccurrence, isNull);
    });

    testWidgets('offre mensuelle : remise affichee et bouton « Reserver au mois »', (tester) async {
      routes(_profil({'monthlyEnabled': true, 'monthlyDiscountPercent': 10}));
      faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'student'});
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text('${l.tutoringEngStagePlan} · ${l.tutoringPercent('-10')}'), findsOneWidget);
      expect(find.text(l.tutoringMonthlyText), findsOneWidget);
      await tester.tap(_bouton(l.tutoringBookMonthly));
      await reseau(tester);
      expect(find.byType(TutorEngagementFlowScreen), findsOneWidget);
    });

    testWidgets('sans offre mensuelle : pas de bouton mensuel', (tester) async {
      routes(_profil());
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      expect(_bouton(L10n.current.tutoringBookMonthly), findsNothing);
    });

    testWidgets('prix de groupe : resume sur la fiche', (tester) async {
      routes(_profil({
        'groupPricingMethod': 'per_student',
        'maxGroupSize': 4,
        'groupDiscounts': [
          {'minGroupSize': 3, 'percentDiscount': 20},
        ],
      }));
      await monterEcran(tester, const TutorPublicProfileScreen(userId: 21));
      final l = L10n.current;
      expect(find.text('• ${l.tutoringGroupUpTo('4')}'), findsOneWidget);
      expect(find.text('• ${l.tutoringGroupFromSize(3, 20)}'), findsOneWidget);
    });
  });

  group('Briques de tarifs', () {
    testWidgets('TopicChipsRow : vide = rien ; sinon une pastille par sujet', (tester) async {
      await monterEcran(tester, const TopicChipsRow([]));
      expect(find.byType(WinBadge), findsNothing);
      await monter(tester, const SizedBox());
      await monterEcran(tester, const TopicChipsRow(['derivees', 'limites']));
      expect(find.byType(WinBadge), findsNWidgets(2));
    });

    testWidgets('TopicsField : maximum de sujets atteint, la saisie disparait', (tester) async {
      var sujets = <String>['a', 'b', 'c', 'd'];
      await tester.pumpWidget(appli(StatefulBuilder(
        builder: (c, set) => TopicsField(topics: sujets, onChanged: (t) => set(() => sujets = t)),
      )));
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'e, f');
      await tester.tap(find.byTooltip(L10n.current.tutoringAddTopic));
      await tester.pump();
      // Plafond de 5 sujets : « f » est ignore, la saisie disparait.
      expect(sujets, ['a', 'b', 'c', 'd', 'e']);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('TutorGroupPricingSummary : prix fixe, chacun paie sa part, individuel seulement', (tester) async {
      final l = L10n.current;
      await tester.pumpWidget(appli(TutorGroupPricingSummary(
        profile: TutorProfile.fromJson({'id': 1, 'userId': 1, 'groupPricingMethod': 'flat', 'maxGroupSize': 3, 'groupFlatPricePercent': 150}),
      )));
      expect(find.text('• ${l.tutoringGroupFlatSummary(150)}'), findsOneWidget);
      await tester.pumpWidget(appli(TutorGroupPricingSummary(
        profile: TutorProfile.fromJson({'id': 1, 'userId': 1, 'groupPricingMethod': 'per_student', 'maxGroupSize': 3}),
      )));
      expect(find.text('• ${l.tutoringGroupEachPays}'), findsOneWidget);
      await tester.pumpWidget(appli(TutorGroupPricingSummary(
        profile: TutorProfile.fromJson({'id': 1, 'userId': 1}),
      )));
      expect(find.byType(Text), findsNothing);
    });
  });
}
