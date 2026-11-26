import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/tutors/tutor_reviews_section.dart';

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

  testWidgets('aucun avis ou panne : rien', (tester) async {
    faux.repond('GET', '/tutor-reviews/tutor/50', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const Scaffold(body: TutorReviewsSection(tutorUserId: 50)));
    expect(find.byType(Text), findsNothing);
  });
}
