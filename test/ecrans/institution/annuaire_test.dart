import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/student_directory_screen.dart';
import 'package:winplus/l10n/l10n.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({List<Map<String, dynamic>> eleves = const [], Map<String, dynamic> kpis = const {}}) {
    faux.repond('GET', '/institution/me', {'data': {'id': 4, 'name': 'Lycee'}});
    faux.repond('GET', '/institution/4/students', {'items': eleves});
    faux.repond('GET', '/institution/4/kpis', kpis);
  }

  testWidgets('compte sans etablissement : message dedie', (tester) async {
    faux.repond('GET', '/institution/me', {}, statut: 404);
    await monterEcran(tester, const StudentDirectoryScreen());
    expect(find.text(L10n.current.instDirNoInstitution), findsOneWidget);
  });

  testWidgets('chargement puis indicateurs et eleves (nom, e-mail de secours, matricule)', (tester) async {
    routes(
      kpis: {'totalStudents': 120, 'activeStudents': 90, 'groupCount': 6, 'averageScore': 12},
      eleves: [
        {'id': 1, 'firstName': 'Ada', 'lastName': 'Eto', 'email': 'ada@x.cm', 'matricule': 'M-001', 'isActive': true},
        {'id': 2, 'email': 'sans-nom@x.cm', 'isActive': false},
      ],
    );
    telephone(tester);
    await monter(tester, ecran(const StudentDirectoryScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('120'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Ada Eto'), findsOneWidget);
    expect(find.text('M-001'), findsOneWidget);
    expect(find.text('sans-nom@x.cm'), findsWidgets);
    expect(find.text(l.instDirCount(2)), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.circle), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.circle), findsOneWidget);
  });

  testWidgets('annuaire vide : message « aucun eleve »', (tester) async {
    routes();
    await monterEcran(tester, const StudentDirectoryScreen());
    expect(find.text(L10n.current.instDirNoStudent), findsOneWidget);
  });

  testWidgets('recherche : le terme est envoye a l\'annuaire', (tester) async {
    routes();
    await monterEcran(tester, const StudentDirectoryScreen());
    await tester.enterText(find.byType(TextField).last, 'ada');
    await reseau(tester);
    expect(faux.recues('GET', '/institution/4/students').last.queryParameters['q'], 'ada');
  });

  testWidgets('ajout sans e-mail : message et aucun envoi', (tester) async {
    routes();
    await monterEcran(tester, const StudentDirectoryScreen());
    await tester.tap(find.byIcon(PhosphorIconsRegular.plus));
    await reseau(tester);
    expect(find.text(L10n.current.instDirEmailRequired), findsOneWidget);
    expect(faux.recues('POST', '/institution/4/students/import'), isEmpty);
  });

  testWidgets('ajout reussi : ligne d\'import envoyee, champs vides, annuaire relu', (tester) async {
    routes();
    faux.repond('POST', '/institution/4/students/import', {});
    await monterEcran(tester, const StudentDirectoryScreen());
    await tester.enterText(find.byType(TextField).at(0), ' ada@x.cm ');
    await tester.enterText(find.byType(TextField).at(1), '3eme');
    await tester.tap(find.byIcon(PhosphorIconsRegular.plus));
    await reseau(tester);
    expect(faux.recues('POST', '/institution/4/students/import').single.data, {
      'rows': [
        {'email': 'ada@x.cm', 'level': '3eme'},
      ],
    });
    expect(find.text(L10n.current.instDirAddSuccess), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, isEmpty);
    expect(faux.recues('GET', '/institution/4/students'), hasLength(2));
  });

  testWidgets('ajout refuse par le serveur : message d\'erreur', (tester) async {
    routes();
    faux.repond('POST', '/institution/4/students/import', {}, statut: 400);
    await monterEcran(tester, const StudentDirectoryScreen());
    await tester.enterText(find.byType(TextField).at(0), 'ada@x.cm');
    await tester.tap(find.byIcon(PhosphorIconsRegular.plus));
    await reseau(tester);
    expect(find.text(L10n.current.instDirAddError), findsOneWidget);
  });
}
