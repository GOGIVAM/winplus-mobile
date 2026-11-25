import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_verification_service.dart';
import 'package:winplus/teacher/tutor_verification_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _defiler(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

/// Ecran haut : les cartes identite, entretien et caution sont toutes
/// construites (la liste ne construit que ce qui approche de l'ecran).
Future<void> _monterHaut(WidgetTester tester) async {
  telephone(tester);
  tester.view.physicalSize = const Size(800, 4000);
  await monter(tester, ecran(const TutorVerificationScreen()));
  await reseau(tester);
}

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  void statut(Map<String, dynamic> corps) => faux.repond('GET', '/tutor-verification/me', corps);

  testWidgets('chargement puis erreur : message du serveur et « Reessayer »', (tester) async {
    faux.repond('GET', '/tutor-verification/me', {'message': 'Non autorise'}, statut: 403);
    telephone(tester);
    await monter(tester, ecran(const TutorVerificationScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    expect(find.text('Non autorise'), findsOneWidget);
    statut({});
    await tester.tap(_bouton(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text('Non autorise'), findsNothing);
    expect(find.text(L10n.current.teacherVerifTitle), findsOneWidget);
  });

  testWidgets('non verifie : badge « en ligne uniquement », trois cartes (identite, entretien, caution)', (tester) async {
    statut({});
    await _monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.tutoringOnlineOnly), findsOneWidget);
    expect(find.text(l.teacherVerifIntro), findsOneWidget);
    expect(find.text(l.teacherVerifIdentityTitle), findsOneWidget);
    expect(find.text(l.teacherVerifInterviewTitle), findsOneWidget);
    await _defiler(tester, find.text(l.teacherVerifInstitutionTitle));
    expect(find.text(l.teacherVerifNoEndorsement), findsOneWidget);
  });

  testWidgets('verifie : badge et voies validees', (tester) async {
    statut({'isVerified': true, 'routes': ['identity', 'institution'], 'hasApprovedIdentity': true});
    await _monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.tutoringInPersonVerified), findsOneWidget);
    expect(find.text(l.teacherVerifRoutesValidated('${kVerificationRouteLabels['identity']}, ${kVerificationRouteLabels['institution']}')), findsOneWidget);
    expect(find.text(l.teacherVerifValidated), findsOneWidget);
    expect(find.text(l.teacherVerifIdentityOk), findsOneWidget);
  });

  testWidgets('suspendu : badge et bandeau d\'alerte', (tester) async {
    statut({'isSuspended': true, 'isVerified': true});
    await _monterHaut(tester);
    expect(find.text(L10n.current.teacherVerifSuspended), findsOneWidget);
    expect(find.text(L10n.current.teacherVerifSuspendedBanner), findsOneWidget);
  });

  testWidgets('identite en attente : message, formulaire masque', (tester) async {
    statut({'latestIdentity': {'id': 1, 'status': 'pending', 'submittedAt': '2026-03-01T10:00:00Z'}});
    await _monterHaut(tester);
    expect(find.textContaining(L10n.current.teacherVerifPendingSince('@@').split('@@').first, findRichText: true), findsOneWidget);
    expect(_bouton(L10n.current.teacherVerifSubmit), findsNothing);
  });

  testWidgets('identite refusee : motif affiche et nouveau formulaire propose, envoi inactif sans fichiers', (tester) async {
    statut({'latestIdentity': {'id': 1, 'status': 'rejected', 'rejectionReason': 'Photo floue'}});
    await _monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.teacherVerifRejected('Photo floue')), findsOneWidget);
    final envoi = _bouton(l.teacherVerifSubmit);
    expect(envoi, findsOneWidget);
    expect(tester.widget<WinButton>(envoi).onTap, isNull);
    expect(find.text(l.teacherVerifFront), findsOneWidget);
    expect(find.text(l.teacherVerifSelfie), findsOneWidget);
    expect(find.text(l.teacherVerifRetention(30, 7)), findsOneWidget);
  });

  testWidgets('entretien : demande en visio avec disponibilites et message ; ville seulement en rencontre', (tester) async {
    statut({});
    faux.repond('POST', '/tutor-verification/me/interview', {'latestInterview': {'id': 3, 'status': 'requested'}});
    await _monterHaut(tester);
    final l = L10n.current;
    final demander = _bouton(l.teacherVerifRequestInterview);
    await _defiler(tester, demander);
    expect(find.text(l.teacherVerifMeetingCity), findsNothing);
    await tester.tap(_bouton(l.teacherVerifMeeting));
    await pomper(tester);
    expect(find.text(l.teacherVerifMeetingCity), findsOneWidget);
    await tester.tap(_bouton(l.teacherVerifVideo));
    await pomper(tester);
    expect(find.text(l.teacherVerifMeetingCity), findsNothing);
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(champs.evaluate().length - 2), 'Soirs apres 18 h');
    await tester.enterText(champs.at(champs.evaluate().length - 1), 'Bonjour');
    await tester.tap(demander);
    await reseau(tester);
    expect(faux.recues('POST', '/tutor-verification/me/interview').single.data, {'format': 'video', 'availability': 'Soirs apres 18 h', 'message': 'Bonjour'});
    expect(find.text(l.teacherVerifRequested), findsOneWidget);
  });

  testWidgets('entretien demande : badge « demande », annulation', (tester) async {
    statut({'latestInterview': {'id': 3, 'status': 'requested', 'requestedAt': '2026-03-01T10:00:00Z', 'hasIdentityAttached': true}});
    faux.repond('POST', '/tutor-verification/me/interview/3/cancel', {});
    await _monterHaut(tester);
    final l = L10n.current;
    expect(find.text(kInterviewStatusLabels['requested']!), findsOneWidget);
    final annuler = _bouton(l.teacherVerifCancelRequest);
    await _defiler(tester, annuler);
    await tester.tap(annuler);
    await reseau(tester);
    expect(faux.recues('POST', '/tutor-verification/me/interview/3/cancel'), hasLength(1));
    expect(find.text(l.teacherVerifCancelled), findsOneWidget);
  });

  testWidgets('entretien planifie : lien et lieu affiches', (tester) async {
    statut({'latestInterview': {'id': 3, 'status': 'scheduled', 'scheduledAt': '2026-03-05T10:00:00Z', 'meetingUrl': 'https://meet.x/abc', 'location': 'Bureau 2', 'hasIdentityAttached': true}});
    await _monterHaut(tester);
    final l = L10n.current;
    await tester.scrollUntilVisible(find.textContaining('https://meet.x/abc'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining(l.teacherVerifLink('https://meet.x/abc')), findsOneWidget);
    expect(find.textContaining(l.teacherVerifPlace('Bureau 2')), findsOneWidget);
  });

  testWidgets('entretien reussi : mention de reussite', (tester) async {
    statut({'hasPassedInterview': true, 'latestInterview': {'id': 3, 'status': 'passed'}});
    await _monterHaut(tester);
    expect(find.textContaining(L10n.current.teacherVerifPassed), findsOneWidget);
  });

  testWidgets('caution d\'institution : etablissements actifs et revoques', (tester) async {
    statut({
      'endorsements': [
        {'id': 1, 'institutionName': 'Lycee Leclerc', 'verifierName': 'M. Nkoa', 'status': 'active', 'isValid': true},
        {'id': 2, 'institutionName': 'Ecole X', 'status': 'revoked', 'revokedAt': '2026-02-01T10:00:00Z', 'revocationReason': 'Depart'},
      ],
    });
    await _monterHaut(tester);
    final l = L10n.current;
    await _defiler(tester, find.text(l.teacherVerifInstitutionTitle));
    expect(find.text('Lycee Leclerc · ${l.teacherVerifVerifiedBy('M. Nkoa')}'), findsOneWidget);
    expect(find.text(l.teacherVerifActive), findsOneWidget);
    expect(find.textContaining(l.teacherVerifReasonSuffix('Depart')), findsOneWidget);
  });

  testWidgets('historique des evenements de verification', (tester) async {
    statut({
      'history': [
        {'id': 1, 'category': 'identity', 'action': 'submitted', 'createdAt': '2026-03-01T10:00:00Z'},
        {'id': 2, 'category': 'identity', 'action': 'rejected', 'reason': 'Photo floue', 'createdAt': '2026-03-02T10:00:00Z'},
      ],
    });
    await _monterHaut(tester);
    final l = L10n.current;
    await _defiler(tester, find.text(l.teacherVerifHistory));
    expect(find.textContaining(kVerificationEventLabels['identity:submitted']!), findsOneWidget);
    expect(find.textContaining('Photo floue'), findsOneWidget);
  });

  testWidgets('echec d\'une demande d\'entretien : message du serveur dans la barre d\'information', (tester) async {
    statut({});
    faux.repond('POST', '/tutor-verification/me/interview', {'message': 'Deja une demande ouverte'}, statut: 409);
    await _monterHaut(tester);
    final demander = _bouton(L10n.current.teacherVerifRequestInterview);
    await _defiler(tester, demander);
    await tester.tap(demander);
    await reseau(tester);
    expect(find.text('Deja une demande ouverte'), findsOneWidget);
  });
}
