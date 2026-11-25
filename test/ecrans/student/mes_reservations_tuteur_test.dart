import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/tutors/my_tutor_bookings_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _seance([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'tutorUserId': 2,
      'tutorName': 'Mme Ngo',
      'studentUserId': 3,
      'sessionDate': '2026-04-06',
      'startTime': '10:00',
      'endTime': '11:00',
      'mode': 'online',
      'priceXaf': 4500,
      'status': 'confirmed',
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void routes(List<Map<String, dynamic>> seances, {List<Map<String, dynamic>> attributions = const [], List<Map<String, dynamic>> engagements = const []}) {
    faux.repond('GET', '/tutor-bookings/mine', seances);
    faux.repond('GET', '/tutor-assignments/for-me', attributions);
    faux.repond('GET', '/tutor-engagements/mine', engagements);
  }

  testWidgets('chargement puis seance : tuteur, horaire, mode, prix et statut traduit', (tester) async {
    routes([_seance()]);
    telephone(tester);
    await monter(tester, ecran(const MyTutorBookingsScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('Mme Ngo'), findsOneWidget);
    expect(find.text('06/04/2026 · 10:00 – 11:00'), findsOneWidget);
    expect(find.text(l.commonOnline), findsOneWidget);
    expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
    expect(find.text(l.tutoringStatusConfirmed), findsOneWidget);
  });

  testWidgets('aucune reservation ni engagement : message dedie', (tester) async {
    routes([]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.tutoringBookingsEmpty), findsOneWidget);
  });

  testWidgets('erreur : message puis « Reessayer »', (tester) async {
    faux.repond('GET', '/tutor-bookings/mine', {}, statut: 500);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.tutoringBookingsLoadError), findsOneWidget);
    routes([]);
    await tester.tap(_bouton(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text(L10n.current.tutoringBookingsEmpty), findsOneWidget);
  });

  testWidgets('tri : seances les plus recentes d\'abord', (tester) async {
    routes([
      _seance({'id': 1, 'tutorName': 'Ancienne', 'sessionDate': '2026-01-05'}),
      _seance({'id': 2, 'tutorName': 'Recente', 'sessionDate': '2026-05-05'}),
    ]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(tester.getTopLeft(find.text('Recente')).dy, lessThan(tester.getTopLeft(find.text('Ancienne')).dy));
  });

  testWidgets('statuts : en attente du tuteur, refusee, expiree, inconnu affiche tel quel', (tester) async {
    routes([
      _seance({'id': 1, 'status': 'pending_tutor_approval', 'tutorName': 'A'}),
      _seance({'id': 2, 'status': 'rejected', 'tutorName': 'B'}),
      _seance({'id': 3, 'status': 'bizarre', 'tutorName': 'C'}),
    ]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    final l = L10n.current;
    expect(find.text(l.tutoringStatusPendingTutor), findsOneWidget);
    expect(find.text(l.tutoringStatusRejected), findsOneWidget);
    expect(find.text('bizarre'), findsOneWidget);
  });

  testWidgets('repetiteurs attribues : carte avec « Reserver » et « Mensuel »', (tester) async {
    routes([], attributions: [
      {'id': 1, 'tutorUserId': 9, 'tutorName': 'Paul', 'subject': 'Maths', 'assignedByName': 'Mme Eto', 'assignerType': 'parent', 'status': 'active'},
    ], engagements: []);
    faux.repond('GET', '/tutor-profile/9', {'id': 1, 'userId': 9, 'fullName': 'Paul'});
    await monterEcran(tester, const MyTutorBookingsScreen());
    final l = L10n.current;
    expect(find.text(l.tutoringAssignedTitle), findsOneWidget);
    expect(find.text('Maths · ${l.tutoringAssignedBy('Mme Eto')}'), findsOneWidget);
    expect(_bouton(l.tutoringBook), findsOneWidget);
    expect(_bouton(l.tutoringMonthly), findsOneWidget);
  });

  testWidgets('seance terminee : avis (note obligatoire), envoi avec commentaire', (tester) async {
    routes([_seance({'status': 'completed', 'viewerIsParticipant': true})]);
    faux.repond('POST', '/tutor-reviews', {'id': 1, 'rating': 4});
    await monterEcran(tester, const MyTutorBookingsScreen());
    final l = L10n.current;
    final envoyer = _bouton(l.tutoringReviewSubmit);
    await tester.ensureVisible(envoyer);
    await tester.tap(envoyer);
    await reseau(tester);
    expect(find.text(l.tutoringReviewChooseRating), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.star).at(3));
    await pomper(tester);
    await tester.enterText(find.byType(TextField), 'Tres claire');
    await tester.tap(envoyer);
    await reseau(tester);
    expect(faux.recues('POST', '/tutor-reviews').single.data, {'tutorBookingId': 1, 'rating': 4, 'comment': 'Tres claire'});
    expect(find.text(l.tutoringReviewThanks), findsWidgets);
    expect(envoyer, findsNothing);
  });

  testWidgets('avis refuse par le serveur : message d\'erreur dans la carte', (tester) async {
    routes([_seance({'status': 'completed', 'canReview': true})]);
    faux.repond('POST', '/tutor-reviews', {'error': 'Deja note'}, statut: 400);
    await monterEcran(tester, const MyTutorBookingsScreen());
    await tester.ensureVisible(find.byIcon(PhosphorIconsRegular.star).first);
    await tester.tap(find.byIcon(PhosphorIconsRegular.star).first);
    await pomper(tester);
    final envoyer = _bouton(L10n.current.tutoringReviewSubmit);
    await tester.tap(envoyer);
    await reseau(tester);
    expect(find.text('Deja note'), findsOneWidget);
  });

  testWidgets('canReview = faux : aucun formulaire d\'avis ; ma note affichee', (tester) async {
    routes([_seance({'status': 'completed', 'canReview': false, 'myReviewRating': 5})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.tutoringLeaveReview), findsNothing);
    expect(find.text(L10n.current.tutoringMyRating('5')), findsOneWidget);
  });

  testWidgets('contestation : fenetre, saisie du motif et appel serveur', (tester) async {
    routes([_seance({'status': 'completed', 'canReview': false, 'canDispute': true, 'disputeDeadline': '2026-04-07T10:00:00Z'})]);
    faux.repond('PUT', '/tutor-bookings/1/dispute', _seance({'status': 'disputed'}));
    await monterEcran(tester, const MyTutorBookingsScreen());
    final l = L10n.current;
    final b = _bouton(l.tutoringDisputeSession);
    await tester.ensureVisible(b);
    await pomper(tester);
    await tester.tap(b);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(l.tutoringReportProblem), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Le tuteur etait absent');
    await tester.tap(_bouton(l.commonSend));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/dispute').single.data, {'reason': 'Le tuteur etait absent'});
    expect(find.text(l.tutoringBookingsDisputeSent), findsOneWidget);
  });

  testWidgets('contestation avec motif vide : aucun appel', (tester) async {
    routes([_seance({'status': 'completed', 'canReview': false, 'canDispute': true})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    final b = _bouton(L10n.current.tutoringDisputeSession);
    await tester.ensureVisible(b);
    await pomper(tester);
    await tester.tap(b);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(L10n.current.commonSend));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/dispute'), isEmpty);
  });

  testWidgets('seance contestee : motif affiche', (tester) async {
    routes([_seance({'status': 'disputed', 'disputeReason': 'Absent'})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.tutoringDisputeSentReason('Absent')), findsOneWidget);
  });

  testWidgets('remboursement credite : phrase du serveur en alerte', (tester) async {
    routes([_seance({'status': 'cancelled', 'refundedAt': '2026-04-05T08:00:00Z', 'refundAmountXaf': 0, 'refundPercent': 0})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.svcRefundTooLate), findsOneWidget);
  });

  testWidgets('signaler le tuteur : bouton, feuille, puis mention « signalement transmis »', (tester) async {
    routes([_seance({'canReport': true})]);
    faux.repond('GET', '/tutor-reports/reasons', [
      {'code': 'no_show', 'label': 'Absent'},
    ]);
    faux.repond('POST', '/tutor-reports', {'message': 'Recu'});
    await monterEcran(tester, const MyTutorBookingsScreen());
    final l = L10n.current;
    final b = _bouton(l.tutoringReportTutor);
    await tester.ensureVisible(b);
    await pomper(tester);
    await tester.tap(b);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text('Absent').last);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(l.tutoringReportSubmit));
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 500));
    expect(find.text(l.tutoringReportSentTeam), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing, reason: 'la feuille est fermee');
  });

  testWidgets('deja signale : mention sans bouton', (tester) async {
    routes([_seance({'hasReported': true, 'canReport': true})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(find.text(L10n.current.tutoringReportSentTeam), findsOneWidget);
    expect(_bouton(L10n.current.tutoringReportTutor), findsNothing);
  });

  testWidgets('support de seance partage : bouton « support » ; mention de reservation pour autrui', (tester) async {
    routes([_seance({'sessionMaterialStatus': 'shared', 'payerType': 'parent', 'payerName': 'Mme Eto', 'participants': [{'userId': 3, 'name': 'Zoe'}]})]);
    await monterEcran(tester, const MyTutorBookingsScreen());
    expect(_bouton(L10n.current.tutoringMaterial), findsOneWidget);
    expect(find.text(L10n.current.svcBookedForOthers('Zoe', 'Mme Eto')), findsOneWidget);
  });
}
