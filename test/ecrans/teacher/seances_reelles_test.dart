import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/teacher_tabs.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Onglet « Séances » du professeur : ses vraies séances (GET /sessions/mine)
/// et plus les deux séances inventées.
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  String dans(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

  Future<void> monterOnglet(WidgetTester tester) =>
      monterEcran(tester, const Scaffold(body: TeacherSessionsTab()));

  testWidgets('seances du serveur : titre, horaire, inscrits ; plus aucune seance inventee', (tester) async {
    faux.repond('GET', '/sessions/mine', {
      'data': [
        {'id': 1, 'title': 'Revision derivees', 'startDate': dans(const Duration(minutes: 30)), 'endDate': dans(const Duration(minutes: 90)), 'durationMinutes': 60, 'status': 'scheduled', 'enrolledCount': 3, 'externalLink': 'https://meet.example/abc'},
        {'id': 2, 'title': 'Correction physique', 'startDate': dans(const Duration(days: 2)), 'durationMinutes': 45, 'status': 'scheduled', 'enrolledCount': 0},
      ],
      'success': true,
    });
    await monterOnglet(tester);
    final l = L10n.current;
    expect(find.text('Revision derivees'), findsOneWidget);
    expect(find.text('Correction physique'), findsOneWidget);
    expect(find.textContaining(l.teacherSessionsEnrolled(3)), findsOneWidget);
    expect(find.text(l.teacherSessionsSoon), findsOneWidget, reason: 'commence dans 30 min');
    expect(find.text(l.teacherSessionsJoin), findsOneWidget, reason: 'seule la seance avec un lien');
    expect(find.text(l.teacherSessionsDemo1), findsNothing);
    final q = faux.recues('GET', '/sessions/mine').single.queryParameters;
    expect(q.containsKey('from') && q.containsKey('to'), isTrue);
  });

  testWidgets('seance annulee : marquee, sans bouton « Rejoindre »', (tester) async {
    faux.repond('GET', '/sessions/mine', {
      'data': [
        {'id': 3, 'title': 'Seance annulee', 'startDate': dans(const Duration(hours: 3)), 'durationMinutes': 60, 'status': 'Cancelled', 'externalLink': 'https://meet.example/x'},
      ],
    });
    await monterOnglet(tester);
    expect(find.text(L10n.current.teacherSessionsCancelled), findsOneWidget);
    expect(find.text(L10n.current.teacherSessionsJoin), findsNothing);
  });

  testWidgets('aucune seance : message, et le bouton pour en planifier une', (tester) async {
    faux.repond('GET', '/sessions/mine', {'data': [], 'success': true});
    await monterOnglet(tester);
    expect(find.text(L10n.current.teacherSessionsEmpty), findsOneWidget);
    expect(find.text(L10n.current.teacherSessionsPlan), findsOneWidget);
  });

  testWidgets('serveur en erreur : message et « Reessayer » qui relit', (tester) async {
    faux.repond('GET', '/sessions/mine', {'error': 'panne'}, statut: 500);
    await monterOnglet(tester);
    expect(find.text(L10n.current.teacherSessionsLoadError), findsOneWidget);
    faux.repond('GET', '/sessions/mine', {'data': []});
    await tester.tap(find.text(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text(L10n.current.teacherSessionsEmpty), findsOneWidget);
  });
}
