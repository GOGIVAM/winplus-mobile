import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/tutors/tutor_reviews_section.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 6 : avis des élèves sur le profil public d'un tuteur.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> avis(int id, {String? reponse}) => {
        'id': id, 'tutorBookingId': id, 'studentName': 'Eleve $id', 'rating': 4, 'comment': 'Tres clair $id',
        'tutorReply': reponse, 'createdAt': '2026-11-0${id}T10:00:00Z',
      };

  testWidgets('avis, reponse du tuteur, trois d\'abord puis tous', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'items': [avis(1, reponse: 'Merci !'), avis(2), avis(3), avis(4)]});
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: TutorReviewsSection(tutorUserId: 50))));
    final l = L10n.current;
    expect(find.text(l.reviewsTitle(4)), findsOneWidget);
    expect(find.text('Tres clair 1'), findsOneWidget);
    expect(find.text('Merci !'), findsOneWidget);
    expect(find.text('Tres clair 4'), findsNothing);
    await tester.tap(find.text(l.reviewsSeeAll(4)));
    await pomper(tester);
    expect(find.text('Tres clair 4'), findsOneWidget);
  });

  testWidgets('fiche publique : pas de bouton de reponse', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'items': [avis(1)]});
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: TutorReviewsSection(tutorUserId: 50))));
    expect(find.text(L10n.current.reviewsReply), findsNothing);
  });

  testWidgets('repetiteur : « Repondre » publie la reponse, qui s\'affiche sous l\'avis', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'items': [avis(1)]});
    faux.repond('POST', '/tutor-reviews/1/reply', avis(1, reponse: 'Merci pour ce retour'));
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: TutorReviewsSection(tutorUserId: 50, canReply: true))));
    final l = L10n.current;
    await tester.tap(find.text(l.reviewsReply));
    await reseau(tester);
    // Rien a publier tant que la reponse est vide.
    expect(tester.widget<WinButton>(find.widgetWithText(WinButton, l.reviewsReplySend)).onTap, isNull);
    await tester.enterText(find.byType(TextField), ' Merci pour ce retour ');
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.reviewsReplySend));
    await reseau(tester);
    expect(faux.recues('POST', '/tutor-reviews/1/reply').single.data, {'reply': 'Merci pour ce retour'});
    expect(find.text('Merci pour ce retour'), findsOneWidget);
    expect(find.text(l.reviewsReplySent), findsOneWidget);
    // Une reponse existe : le bouton propose de la modifier.
    expect(find.text(l.reviewsEditReply), findsOneWidget);
  });

  testWidgets('repetiteur : refus du serveur (coordonnees dans la reponse) affiche tel quel', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'items': [avis(1)]});
    faux.repond('POST', '/tutor-reviews/1/reply', {'success': false, 'code': 'coordonnees_interdites', 'message': 'Pas de numero de telephone ici.'}, statut: 400);
    await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: TutorReviewsSection(tutorUserId: 50, canReply: true))));
    final l = L10n.current;
    await tester.tap(find.text(l.reviewsReply));
    await reseau(tester);
    await tester.enterText(find.byType(TextField), 'Appelez le 699000000');
    await pomper(tester);
    await tester.tap(find.widgetWithText(WinButton, l.reviewsReplySend));
    await reseau(tester);
    expect(find.text('Pas de numero de telephone ici.'), findsOneWidget);
    expect(find.text(l.reviewsReply), findsOneWidget);
  });

  testWidgets('aucun avis ou panne : rien', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const Scaffold(body: TutorReviewsSection(tutorUserId: 50)));
    expect(find.byType(Text), findsNothing);
  });
}
