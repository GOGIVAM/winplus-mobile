import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/verify_certificate_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : vérification d'un certificat par son code, comme /verify du site
/// (certificats d'épreuve, puis de formation).
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Future<void> verifier(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text(L10n.current.certVerifyButton));
    await reseau(tester);
  }

  testWidgets('certificat d\'epreuve authentique : titulaire, intitule, date, note, numero', (tester) async {
    faux.repond('GET', '/certificates/verify/ABC123', {
      'success': true,
      'data': {
        'isValid': true, 'certificateNumber': 'WP-2026-0042', 'studentName': 'Zoe Eto',
        'courseName': 'Mathematiques Terminale', 'issuedAt': '2026-11-20T10:00:00Z',
        'completionDate': '2026-11-20T10:00:00Z', 'grade': 16.5,
      },
    });
    await monterEcran(tester, const VerifyCertificateScreen());
    final l = L10n.current;
    await verifier(tester, 'ABC123');
    expect(find.text(l.certVerifyAuthentic), findsOneWidget);
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(find.text('Mathematiques Terminale'), findsOneWidget);
    expect(find.textContaining('WP-2026-0042'), findsOneWidget);
    expect(find.textContaining(l.certVerifyGrade('16.5')), findsOneWidget);
    expect(faux.recues('GET', '/certificats/ABC123'), isEmpty, reason: 'trouve du premier coup');
  });

  testWidgets('code de formation : second essai sur /certificats', (tester) async {
    faux.repond('GET', '/certificates/verify/F-77', {'success': false, 'data': {'isValid': false}});
    faux.repond('GET', '/certificats/F-77', {'isValid': true, 'studentName': 'Leo Mba', 'courseTitle': 'Python debutant'});
    await monterEcran(tester, const VerifyCertificateScreen());
    await verifier(tester, 'F-77');
    expect(find.text(L10n.current.certVerifyAuthentic), findsOneWidget);
    expect(find.text('Leo Mba'), findsOneWidget);
    expect(find.text('Python debutant'), findsOneWidget);
  });

  testWidgets('code inconnu : message « aucun certificat » ; code trop court : rien n\'est demande', (tester) async {
    faux.repond('GET', '/certificates/verify/ZZZZ', {'success': false, 'data': {'isValid': false}});
    faux.repond('GET', '/certificats/ZZZZ', {'error': 'x'}, statut: 404);
    await monterEcran(tester, const VerifyCertificateScreen());
    final l = L10n.current;
    await verifier(tester, 'ab');
    expect(find.text(l.certVerifyCodeRequired), findsOneWidget);
    expect(faux.recues('GET', '/certificates/verify/ab'), isEmpty);
    await verifier(tester, 'ZZZZ');
    expect(find.text(l.certVerifyInvalid), findsOneWidget);
    expect(find.text(l.certVerifyAuthentic), findsNothing);
  });

  testWidgets('serveur en panne : erreur, pas « aucun certificat »', (tester) async {
    faux.repond('GET', '/certificates/verify/ABC123', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const VerifyCertificateScreen());
    final l = L10n.current;
    await verifier(tester, 'ABC123');
    expect(find.text(l.commonLoadError), findsOneWidget);
    expect(find.text(l.certVerifyInvalid), findsNothing);
  });

  testWidgets('code fourni a l\'ouverture : verifie tout de suite', (tester) async {
    faux.repond('GET', '/certificates/verify/ABC123', {'data': {'isValid': true, 'studentName': 'Zoe Eto', 'courseName': 'Maths'}});
    await monterEcran(tester, const VerifyCertificateScreen(initialCode: 'ABC123'));
    expect(find.text('Zoe Eto'), findsOneWidget);
  });
}
