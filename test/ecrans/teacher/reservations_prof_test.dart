import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/tutor_bookings_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _seance([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'tutorUserId': 2,
      'studentUserId': 3,
      'studentName': 'Paul Eto',
      'sessionDate': '2026-04-06',
      'startTime': '10:00',
      'endTime': '11:00',
      'mode': 'online',
      'priceXaf': 4500,
      'status': 'pending_tutor_approval',
      ...en,
    };

Map<String, dynamic> _engagement([Map<String, dynamic> en = const {}]) => {
      'id': 40,
      'tutorUserId': 2,
      'status': 'pending_tutor_approval',
      'startDate': '2026-05-04',
      'endDate': '2026-06-01',
      'slots': [
        {'dayOfWeek': 2, 'startTime': '17:00', 'durationMinutes': 60},
      ],
      'participants': [
        {'userId': 3, 'name': 'Paul Eto'},
      ],
      'totalXaf': 18000,
      'discountPercent': 10,
      'sessionsCount': 4,
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  void routes({
    List<Map<String, dynamic>> attente = const [],
    List<Map<String, dynamic>> miennes = const [],
    List<Map<String, dynamic>> attributions = const [],
    List<Map<String, dynamic>> engagementsEnAttente = const [],
    List<Map<String, dynamic>> engagements = const [],
    bool? supportAuto,
  }) {
    faux.repond('GET', '/tutor-bookings/tutor/pending', attente);
    faux.repond('GET', '/tutor-bookings/tutor/mine', miennes);
    faux.repond('GET', '/tutor-assignments/tutor', attributions);
    faux.repond('GET', '/tutor-engagements/tutor/pending', engagementsEnAttente);
    faux.repond('GET', '/tutor-engagements/tutor/mine', engagements);
    faux.repond('GET', '/tutor-bookings/session-material/settings', {'autoGenerateOnAccept': supportAuto ?? false});
  }

  Map<String, dynamic> demande(Map<String, dynamic> seance, {int minutes = 90}) => {'booking': seance, 'minutesRemaining': minutes};

  /// Ecran tres haut : toute la liste est construite, sans defilement.
  Future<void> monterHaut(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 5000);
    await monter(tester, ecran(const TutorBookingsScreen()));
    await reseau(tester);
  }

  Future<void> faireDefiler(WidgetTester tester, Finder cible) => tester.scrollUntilVisible(cible, 300, scrollable: find.byType(Scrollable).first);

  testWidgets('chargement puis etats vides : aucune demande, aucune seance confirmee', (tester) async {
    routes();
    telephone(tester);
    await monter(tester, ecran(const TutorBookingsScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.tutoringPrivateLessons), findsOneWidget);
    expect(find.text(l.teacherBookingPendingTitle), findsOneWidget);
    expect(find.text(l.teacherBookingPendingEmpty), findsOneWidget);
    await faireDefiler(tester, find.text(l.teacherBookingConfirmedEmpty));
    expect(find.text(l.teacherBookingConfirmedEmpty), findsOneWidget);
  });

  testWidgets('erreur : message puis « Reessayer »', (tester) async {
    routes();
    faux.repond('GET', '/tutor-bookings/tutor/pending', {}, statut: 500);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    expect(find.text(l.tutoringBookingsLoadError), findsOneWidget);
    routes();
    await tester.tap(_bouton(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.tutoringBookingsLoadError), findsNothing);
    expect(find.text(l.teacherBookingPendingEmpty), findsOneWidget);
  });

  testWidgets('demande en attente : eleve, horaire, delai restant, mode et prix', (tester) async {
    routes(attente: [demande(_seance(), minutes: 45)]);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    expect(find.text('Paul Eto'), findsOneWidget);
    expect(find.text('06/04/2026 · 10:00 – 11:00'), findsOneWidget);
    expect(find.text(l.teacherBookingMinutes(45)), findsOneWidget);
    expect(find.text(l.commonOnline), findsOneWidget);
    expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
    expect(_bouton(l.commonAccept), findsOneWidget);
    expect(_bouton(l.commonDecline), findsOneWidget);
  });

  testWidgets('detail d\'une demande : matiere, duree, sujets et bouton de support WinAI', (tester) async {
    routes(attente: [
      demande(_seance({'subject': 'Maths', 'durationMinutes': 60, 'topics': ['derivees']})),
    ]);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    expect(find.textContaining('Maths · '), findsOneWidget);
    expect(find.text(l.teacherBookingTopics), findsOneWidget);
    expect(find.text('derivees'), findsOneWidget);
    expect(_bouton(l.teacherBookingPrepareMaterial), findsOneWidget);
  });

  testWidgets('accepter : appel serveur puis rechargement des listes', (tester) async {
    routes(attente: [demande(_seance())]);
    faux.repond('PUT', '/tutor-bookings/1/confirm', _seance({'status': 'confirmed'}));
    await monterEcran(tester, const TutorBookingsScreen());
    // Apres l'acceptation, la demande a quitte la liste d'attente.
    faux.repond('GET', '/tutor-bookings/tutor/pending', []);
    faux.repond('GET', '/tutor-bookings/tutor/mine', [_seance({'status': 'confirmed'})]);
    await tester.tap(_bouton(L10n.current.commonAccept));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/confirm'), hasLength(1));
    expect(faux.recues('GET', '/tutor-bookings/tutor/pending'), hasLength(2));
    expect(find.text(L10n.current.teacherBookingPendingEmpty), findsOneWidget);
    await faireDefiler(tester, find.text(L10n.current.tutoringStatusConfirmed));
    expect(find.text(L10n.current.tutoringStatusConfirmed), findsOneWidget);
  });

  testWidgets('acceptation refusee par le serveur : message et demande conservee', (tester) async {
    routes(attente: [demande(_seance())]);
    faux.repond('PUT', '/tutor-bookings/1/confirm', {'error': 'x'}, statut: 409);
    await monterEcran(tester, const TutorBookingsScreen());
    await tester.tap(_bouton(L10n.current.commonAccept));
    await reseau(tester);
    expect(find.text(L10n.current.teacherBookingAcceptError), findsOneWidget);
    expect(find.text('Paul Eto'), findsOneWidget);
  });

  testWidgets('refuser : fenetre du motif, envoi du motif et message de remboursement', (tester) async {
    routes(attente: [demande(_seance())]);
    faux.repond('PUT', '/tutor-bookings/1/decline', _seance({'status': 'rejected'}));
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await tester.tap(_bouton(l.commonDecline));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(l.teacherBookingDeclineTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Indisponible ce jour ');
    await tester.tap(_bouton(l.commonConfirm));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/decline').single.data, {'reason': 'Indisponible ce jour'});
    expect(find.text(l.teacherBookingDeclined), findsOneWidget);
  });

  testWidgets('refuser sans motif : motif nul envoye ; frais retenus affiches dans le message', (tester) async {
    routes(attente: [demande(_seance())]);
    faux.repond('PUT', '/tutor-bookings/1/decline', _seance({'status': 'rejected', 'tutorFeeChargedXaf': 300}));
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await tester.tap(_bouton(l.commonDecline));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(l.commonConfirm));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/decline').single.data, {'reason': null});
    expect(find.text(l.teacherBookingDeclinedFee('300')), findsOneWidget);
  });

  testWidgets('refuser puis « Annuler » dans la fenetre : aucun appel', (tester) async {
    routes(attente: [demande(_seance())]);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await tester.tap(_bouton(l.commonDecline));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(l.commonCancel));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(faux.recues('PUT', '/tutor-bookings/1/decline'), isEmpty);
    expect(find.text('Paul Eto'), findsOneWidget);
  });

  testWidgets('refus en erreur : message d\'erreur', (tester) async {
    routes(attente: [demande(_seance())]);
    faux.repond('PUT', '/tutor-bookings/1/decline', {}, statut: 500);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await tester.tap(_bouton(l.commonDecline));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(l.commonConfirm));
    await reseau(tester);
    expect(find.text(l.teacherBookingDeclineError), findsOneWidget);
  });

  testWidgets('seances a venir : triees par date, statut traduit ; seules les terminables ont le bouton', (tester) async {
    routes(miennes: [
      _seance({'id': 2, 'studentName': 'Tardive', 'sessionDate': '2026-06-01', 'status': 'confirmed'}),
      _seance({'id': 3, 'studentName': 'Precoce', 'sessionDate': '2026-04-01', 'status': 'confirmed', 'canMarkCompleted': true}),
      _seance({'id': 4, 'studentName': 'Terminee', 'sessionDate': '2026-05-01', 'status': 'completed'}),
      _seance({'id': 5, 'studentName': 'Annulee', 'sessionDate': '2026-05-02', 'status': 'cancelled'}),
    ]);
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('Annulee'), findsNothing);
    expect(tester.getTopLeft(find.text('Precoce')).dy, lessThan(tester.getTopLeft(find.text('Terminee')).dy));
    expect(tester.getTopLeft(find.text('Terminee')).dy, lessThan(tester.getTopLeft(find.text('Tardive')).dy));
    expect(find.text(l.tutoringStatusCompleted), findsOneWidget);
    expect(_bouton(l.teacherBookingMarkCompleted), findsOneWidget);
  });

  testWidgets('marquer effectuee : appel serveur, puis rechargement', (tester) async {
    routes(miennes: [_seance({'status': 'confirmed', 'canMarkCompleted': true})]);
    faux.repond('PUT', '/tutor-bookings/1/complete', _seance({'status': 'completed'}));
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    final b = _bouton(l.teacherBookingMarkCompleted);
    await faireDefiler(tester, b);
    faux.repond('GET', '/tutor-bookings/tutor/mine', [_seance({'status': 'completed'})]);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/1/complete'), hasLength(1));
    expect(find.text(l.tutoringStatusCompleted), findsOneWidget);
    expect(b, findsNothing);
  });

  testWidgets('cloture en erreur : message d\'erreur', (tester) async {
    routes(miennes: [_seance({'status': 'confirmed', 'canMarkCompleted': true})]);
    faux.repond('PUT', '/tutor-bookings/1/complete', {}, statut: 400);
    await monterEcran(tester, const TutorBookingsScreen());
    final b = _bouton(L10n.current.teacherBookingMarkCompleted);
    await faireDefiler(tester, b);
    await tester.tap(b);
    await reseau(tester);
    expect(find.text(L10n.current.teacherBookingCompleteError), findsOneWidget);
  });

  testWidgets('seance contestee : motif de l\'eleve en alerte', (tester) async {
    routes(miennes: [_seance({'status': 'disputed', 'disputeReason': 'Le tuteur est absent'})]);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await faireDefiler(tester, find.text(l.tutoringStatusDisputed));
    expect(find.text(l.teacherBookingDisputeReason('Le tuteur est absent')), findsOneWidget);
  });

  testWidgets('support de seance : l\'interrupteur d\'acceptation envoie le reglage', (tester) async {
    routes(supportAuto: false);
    faux.repond('PUT', '/tutor-bookings/session-material/settings', {'autoGenerateOnAccept': true});
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await faireDefiler(tester, find.text(l.teacherBookingAutoMaterial));
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    await tester.tap(find.byType(SwitchListTile));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-bookings/session-material/settings').single.data, {'autoGenerateOnAccept': true});
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
  });

  testWidgets('reglage du support refuse par le serveur : message du serveur', (tester) async {
    routes(supportAuto: false);
    faux.repond('PUT', '/tutor-bookings/session-material/settings', {'message': 'Plan insuffisant'}, statut: 403);
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    await faireDefiler(tester, find.text(l.teacherBookingAutoMaterial));
    await tester.tap(find.byType(SwitchListTile));
    await reseau(tester);
    expect(find.text('Plan insuffisant'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
  });

  testWidgets('attributions : en attente (Accepter / Refuser) et active (Mettre fin)', (tester) async {
    routes(attributions: [
      {'id': 5, 'tutorUserId': 2, 'assignerType': 'parent', 'assignedByName': 'Mme Eto', 'status': 'pending', 'subject': 'Maths', 'note': 'Urgent', 'beneficiaries': [{'userId': 3, 'name': 'Paul'}]},
      {'id': 6, 'tutorUserId': 2, 'assignerType': 'institution', 'institutionName': 'Lycee Leclerc', 'groupName': 'Terminale C', 'status': 'active'},
      {'id': 7, 'tutorUserId': 2, 'assignerType': 'parent', 'status': 'ended'},
    ]);
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('Mme Eto'), findsOneWidget);
    expect(find.text('Lycee Leclerc · Terminale C'), findsOneWidget);
    expect(find.text(l.teacherBookingQuote('Urgent')), findsOneWidget);
    expect(_bouton(l.tutoringEndAssignment), findsOneWidget);
    // L'attribution terminee n'a aucun bouton : un seul « Mettre fin », un seul couple Accepter / Refuser.
    expect(_bouton(l.commonAccept), findsOneWidget);
  });

  testWidgets('attribution en attente : « Accepter » envoie l\'action et met la carte a jour', (tester) async {
    routes(attributions: [
      {'id': 5, 'tutorUserId': 2, 'assignerType': 'parent', 'assignedByName': 'Mme Eto', 'status': 'pending'},
    ]);
    faux.repond('PUT', '/tutor-assignments/5/accept', {'id': 5, 'tutorUserId': 2, 'assignerType': 'parent', 'assignedByName': 'Mme Eto', 'status': 'active'});
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    final accepter = _bouton(l.commonAccept);
    await faireDefiler(tester, accepter);
    await tester.tap(accepter);
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-assignments/5/accept'), hasLength(1));
    expect(_bouton(l.tutoringEndAssignment), findsOneWidget);
    expect(accepter, findsNothing);
  });

  testWidgets('attribution : echec de la reponse, message d\'action impossible', (tester) async {
    routes(attributions: [
      {'id': 5, 'tutorUserId': 2, 'assignerType': 'parent', 'status': 'active'},
    ]);
    faux.repond('PUT', '/tutor-assignments/5/end', {}, statut: 500);
    await monterEcran(tester, const TutorBookingsScreen());
    final fin = _bouton(L10n.current.tutoringEndAssignment);
    await faireDefiler(tester, fin);
    await tester.tap(fin);
    await reseau(tester);
    expect(find.text(L10n.current.tutoringActionFailed), findsOneWidget);
  });

  testWidgets('demande d\'engagement mensuel : resume, delai et acceptation', (tester) async {
    routes(engagementsEnAttente: [
      {'engagement': _engagement(), 'minutesRemaining': 120},
    ]);
    faux.repond('PUT', '/tutor-engagements/40/accept', _engagement({'status': 'active'}));
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    expect(find.text(l.teacherBookingEngagementRequests), findsOneWidget);
    expect(find.text(l.teacherBookingMinutesToAnswer(120)), findsOneWidget);
    expect(find.textContaining(l.teacherBookingSessionsCount(4)), findsOneWidget);
    expect(find.textContaining(l.teacherBookingPaidInAdvance(fmtXaf(18000))), findsOneWidget);
    routes();
    await tester.tap(_bouton(l.teacherBookingAcceptMonth));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-engagements/40/accept'), hasLength(1));
    expect(find.text(l.teacherBookingEngagementAccepted), findsOneWidget);
    expect(find.text(l.teacherBookingEngagementRequests), findsNothing);
  });

  testWidgets('engagement : refus avec motif dans la fenetre', (tester) async {
    routes(engagementsEnAttente: [
      {'engagement': _engagement(), 'minutesRemaining': 0},
    ]);
    faux.repond('PUT', '/tutor-engagements/40/decline', _engagement({'status': 'declined'}));
    await monterEcran(tester, const TutorBookingsScreen());
    final l = L10n.current;
    // Delai ecoule : mention « expire bientot ».
    expect(find.text(l.teacherBookingExpiresSoon), findsOneWidget);
    // Les boutons « Refuser » du mois : le seul bouton « Refuser » (aucune demande de seance).
    await tester.tap(_bouton(l.commonDecline));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Complet');
    await tester.tap(_bouton(l.commonConfirm));
    await reseau(tester);
    expect(faux.recues('PUT', '/tutor-engagements/40/decline').single.data, {'reason': 'Complet'});
    expect(find.text(l.tutoringEngDeclined), findsOneWidget);
  });

  testWidgets('engagement : erreur du serveur, son message est affiche', (tester) async {
    routes(engagementsEnAttente: [
      {'engagement': _engagement(), 'minutesRemaining': 30},
    ]);
    faux.repond('PUT', '/tutor-engagements/40/accept', {'message': 'Creneau deja pris'}, statut: 409);
    await monterEcran(tester, const TutorBookingsScreen());
    await tester.tap(_bouton(L10n.current.teacherBookingAcceptMonth));
    await reseau(tester);
    expect(find.text('Creneau deja pris'), findsOneWidget);
  });

  testWidgets('bouton d\'actualisation : relit toutes les listes', (tester) async {
    routes();
    await monterEcran(tester, const TutorBookingsScreen());
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await reseau(tester);
    expect(faux.recues('GET', '/tutor-bookings/tutor/pending'), hasLength(2));
    expect(faux.recues('GET', '/tutor-bookings/tutor/mine'), hasLength(2));
  });
}
