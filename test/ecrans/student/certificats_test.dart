import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/certificates_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({Object formations = const [], Object sujets = const {'data': []}}) {
    faux.repond('GET', '/my-course-certificates', formations);
    faux.repond('GET', '/certificates/user/my-certificates', sujets);
  }

  testWidgets('chargement puis etat vide quand aucun certificat n\'existe', (tester) async {
    routes();
    telephone(tester);
    await monter(tester, ecran(const CertificatesScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    expect(find.text(L10n.current.studentCertEmpty), findsOneWidget);
    expect(find.text(L10n.current.studentCertEmptyHint), findsOneWidget);
  });

  testWidgets('erreur serveur : message de chargement a la place de l\'etat vide', (tester) async {
    faux.repond('GET', '/my-course-certificates', []);
    faux.repond('GET', '/certificates/user/my-certificates', {}, statut: 500);
    await monterEcran(tester, const CertificatesScreen());
    expect(find.text(L10n.current.studentCertLoadError), findsOneWidget);
    expect(find.text(L10n.current.studentCertEmpty), findsNothing);
  });

  testWidgets('certificats de sujets : titre, date, mention et lien PDF', (tester) async {
    routes(sujets: {
      'data': [
        {'id': 1, 'subjectTitle': 'Maths BAC', 'issuedAt': '2026-01-05', 'grade': 17, 'fileUrl': 'https://x/c.pdf'},
      ],
    });
    await monterEcran(tester, const CertificatesScreen());
    final l = L10n.current;
    expect(find.text('Maths BAC'), findsOneWidget);
    expect(find.text(l.studentCertIssuedOn('2026-01-05')), findsOneWidget);
  });

  testWidgets('certificats de formation : rubrique dediee puis rubrique des epreuves', (tester) async {
    routes(
      formations: {
        'data': [
          {'id': 1, 'courseTitle': 'Algebre complete', 'verificationCode': 'ABC123', 'grade': 15},
        ],
      },
      sujets: {
        'data': [
          {'id': 2, 'subjectTitle': 'Physique BEPC', 'grade': 80},
        ],
      },
    );
    await monterEcran(tester, const CertificatesScreen());
    final l = L10n.current;
    expect(find.text(l.studentCertCourses), findsOneWidget);
    expect(find.text('Algebre complete'), findsOneWidget);
    expect(find.text(l.studentCertPapersAndPaths), findsOneWidget);
    expect(find.text('Physique BEPC'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('erreur sur les formations seulement : les certificats de sujets restent affiches', (tester) async {
    faux.repond('GET', '/my-course-certificates', {}, statut: 500);
    faux.repond('GET', '/certificates/user/my-certificates', {
      'data': [
        {'id': 2, 'subjectTitle': 'Physique BEPC'},
      ],
    });
    await monterEcran(tester, const CertificatesScreen());
    expect(find.text('Physique BEPC'), findsOneWidget);
    expect(find.text(L10n.current.studentCertLoadError), findsNothing);
  });

  testWidgets('actualiser relit les deux listes', (tester) async {
    routes();
    await monterEcran(tester, const CertificatesScreen());
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await reseau(tester);
    expect(faux.recues('GET', '/certificates/user/my-certificates'), hasLength(2));
    expect(faux.recues('GET', '/my-course-certificates'), hasLength(2));
  });
}
