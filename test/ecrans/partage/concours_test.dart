import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/concours_service.dart';
import 'package:winplus/shared/concours_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : hub des concours et page d'un concours.
void main() {
  late FauxReseau faux;
  final ouvrirOrigine = ConcoursDetailScreen.openSubject;
  late List<int> ouverts;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    ouverts = [];
    ConcoursDetailScreen.openSubject = (_, id) async => ouverts.add(id);
  });
  tearDown(() => ConcoursDetailScreen.openSubject = ouvrirOrigine);

  final annee = DateTime.now().year + 1;

  Map<String, dynamic> session() => {
        'id': 1, 'slug': 'ens', 'name': 'Concours ENS Yaoundé', 'nameEn': 'ENS Yaounde entrance exam', 'year': annee,
        'registrationStartDate': '$annee-01-10T00:00:00Z', 'registrationEndDate': '$annee-02-20T00:00:00Z',
        'examDate': '$annee-07-15T00:00:00Z', 'resultsDate': null, 'location': 'Yaoundé', 'enrollmentFeeXaf': 20000,
        'officialRegistrationUrl': 'https://ens.cm', 'registrationStatus': 'upcoming',
        'tips': 'Reviser les annales\nGerer son temps',
        'faqJson': jsonEncode([{'question': 'Quel age ?', 'answer': 'Moins de 25 ans.'}]),
        'admissionConditions': 'Etre titulaire du **BAC**.',
      };

  Map<String, dynamic> stats() => {
        'success': true,
        'data': {
          'examType': 'ens', 'totalExams': 3, 'withCorrection': 2, 'freeExams': 1,
          'categories': [{'name': 'Maths', 'count': 2}, {'name': 'Physique', 'count': 1}],
          'years': [2025, 2024],
          'exams': [
            {'id': 1, 'subjectId': 11, 'title': 'Maths 2025', 'category': 'Maths', 'year': 2025, 'isFree': true, 'price': 0, 'hasCorrection': true},
            {'id': 2, 'subjectId': 12, 'title': 'Maths 2024', 'category': 'Maths', 'year': 2024, 'isFree': false, 'price': 1500, 'hasCorrection': true},
            {'id': 3, 'subjectId': 13, 'title': 'Physique 2025', 'category': 'Physique', 'year': 2025, 'isFree': false, 'price': 1500, 'hasCorrection': false},
          ],
        },
      };

  testWidgets('hub : quatorze concours, nombre d\'epreuves, statut et prochaine date', (tester) async {
    faux.repond('GET', '/concours-events', [session()]);
    for (final c in concoursSchools) {
      faux.repond('GET', '/exams/stats/${c.slug}', c.slug == 'ens' ? stats() : {'success': true, 'data': {'totalExams': 0}});
    }
    await monterEcran(tester, const ConcoursHubScreen());
    final l = L10n.current;
    expect(find.text('ENS Yaoundé'), findsOneWidget);
    expect(find.textContaining(l.concExams(3)), findsOneWidget);
    expect(find.widgetWithText(WinBadge, l.concRegUpcoming), findsOneWidget);
    expect(find.textContaining(l.concNextDate('').trim()), findsOneWidget);
    await tester.scrollUntilVisible(find.text('GCE A Level'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('GCE A Level'), findsOneWidget);
  });

  testWidgets('hub : calendrier en panne, les concours restent affiches', (tester) async {
    faux.repond('GET', '/concours-events', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const ConcoursHubScreen());
    expect(find.text('ENS Yaoundé'), findsOneWidget);
  });

  testWidgets('page : calendrier, filtres matiere et annee, ouverture d\'une epreuve', (tester) async {
    faux.repond('GET', '/concours-events/ens', session());
    faux.repond('GET', '/exams/stats/ens', stats());
    tester.view.physicalSize = const Size(800, 4000);
    await monterEcran(tester, const ConcoursDetailScreen(school: ConcoursSchool('ens', 'ENS Yaoundé')));
    tester.view.physicalSize = const Size(800, 4000);
    await pomper(tester);
    final l = L10n.current;
    expect(find.text('Concours ENS Yaoundé'), findsOneWidget);
    expect(find.text(l.concCalendar(annee)), findsOneWidget);
    expect(find.text('Yaoundé'), findsOneWidget);
    expect(find.text(l.concStats(3, 2, 1)), findsOneWidget);
    expect(find.text('Maths 2024'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinChip, 'Physique (1)'));
    await pomper(tester);
    expect(find.text('Maths 2024'), findsNothing);
    expect(find.text('Physique 2025'), findsOneWidget);
    await tester.tap(find.widgetWithText(WinChip, l.concAllSubjects));
    await tester.tap(find.widgetWithText(WinChip, '2024'));
    await pomper(tester);
    expect(find.text('Maths 2025'), findsNothing);
    await tester.tap(find.text('Maths 2024'));
    await pomper(tester);
    expect(ouverts, [12]);
  });

  testWidgets('page : conseils, conditions sans markdown, FAQ depliable', (tester) async {
    faux.repond('GET', '/concours-events/ens', session());
    faux.repond('GET', '/exams/stats/ens', stats());
    await monterEcran(tester, const ConcoursDetailScreen(school: ConcoursSchool('ens', 'ENS Yaoundé')));
    final l = L10n.current;
    final liste = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Gerer son temps'), 300, scrollable: liste);
    expect(find.text('Reviser les annales'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Etre titulaire du BAC.'), 300, scrollable: liste);
    await tester.scrollUntilVisible(find.text('Quel age ?'), 300, scrollable: liste);
    expect(find.text(l.concFaq), findsOneWidget);
    await tester.tap(find.text('Quel age ?'));
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text('Moins de 25 ans.'), findsOneWidget);
  });

  testWidgets('page en anglais : nom anglais ; sans calendrier ni epreuve', (tester) async {
    L10n.locale = const Locale('en');
    addTearDown(() => L10n.locale = const Locale('fr'));
    faux.repond('GET', '/concours-events/ens', session());
    faux.repond('GET', '/exams/stats/ens', {'success': true, 'data': {'totalExams': 0}});
    await monterEcran(tester, const ConcoursDetailScreen(school: ConcoursSchool('ens', 'ENS Yaoundé')));
    expect(find.text('ENS Yaounde entrance exam'), findsOneWidget);
    // Libellés de l'interface dans la langue réelle de l'écran.
    final l = tester.element(find.byType(ConcoursDetailScreen)).l10n;
    expect(find.text(l.concNoExam), findsOneWidget);
  });

  testWidgets('page sans session publiee : message', (tester) async {
    faux.repond('GET', '/concours-events/bac', null, statut: 404);
    faux.repond('GET', '/exams/stats/bac', stats());
    await monterEcran(tester, const ConcoursDetailScreen(school: ConcoursSchool('bac', 'BAC')));
    expect(find.text(L10n.current.concNoCalendar), findsOneWidget);
    expect(find.text('BAC'), findsOneWidget);
  });
}
