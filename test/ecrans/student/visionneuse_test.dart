import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/document_viewer_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _reessayer() => find.widgetWithText(WinButton, L10n.current.commonRetry);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('chargement : indicateur et titre du document', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 404);
    telephone(tester);
    await monter(tester, ecran(const DocumentViewerScreen(subjectId: 5, title: 'Maths BAC')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Maths BAC'), findsOneWidget);
    await reseau(tester);
  });

  testWidgets('corrige : le titre indique « corrige » et la requete porte kind=correction', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 404);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'Maths BAC', kind: ViewerDocumentKind.correction));
    expect(find.text(L10n.current.studentViewerCorrectionTitle('Maths BAC')), findsOneWidget);
    expect(faux.recues('GET', '/subjects/5/view').single.queryParameters, {'kind': 'correction'});
    expect(find.text(L10n.current.studentViewerNoCorrection), findsOneWidget);
  });

  testWidgets('formation : l\'identifiant de formation est envoye', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 404);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T', courseId: 9));
    expect(faux.recues('GET', '/subjects/5/view').single.queryParameters, {'courseId': 9});
  });

  testWidgets('404 sur un document : « document introuvable », sans bouton reessayer', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 404);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.text(L10n.current.studentViewerNoDocument), findsOneWidget);
    expect(_reessayer(), findsNothing);
  });

  testWidgets('403 : acces refuse, sans reessai', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 403);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.text(L10n.current.studentViewerNoAccess), findsOneWidget);
    expect(_reessayer(), findsNothing);
  });

  testWidgets('401 : session expiree, sans reessai', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 401);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.text(L10n.current.studentViewerSessionExpired), findsOneWidget);
    expect(_reessayer(), findsNothing);
  });

  testWidgets('erreur serveur 500 : message generique et reessai qui relance la requete', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 500);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.text(L10n.current.studentViewerLoadFailed), findsOneWidget);
    expect(_reessayer(), findsOneWidget);
    await tester.tap(_reessayer());
    await reseau(tester);
    expect(faux.recues('GET', '/subjects/5/view'), hasLength(2));
  });

  testWidgets('document vide : echec de chargement avec reessai', (tester) async {
    faux.repond('GET', '/subjects/5/view', null);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.text(L10n.current.studentViewerLoadFailed), findsOneWidget);
    expect(_reessayer(), findsOneWidget);
  });

  testWidgets('aucune action de telechargement ou de partage n\'est proposee', (tester) async {
    faux.repond('GET', '/subjects/5/view', {}, statut: 500);
    await monterEcran(tester, const DocumentViewerScreen(subjectId: 5, title: 'T'));
    expect(find.byIcon(Icons.download), findsNothing);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.byIcon(Icons.print), findsNothing);
  });

  testWidgets('openDocumentViewer pousse la visionneuse', (tester) async {
    faux.repond('GET', '/subjects/7/view', {}, statut: 404);
    await monterEcran(tester, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => openDocumentViewer(c, subjectId: 7, title: 'Livre'), child: const Text('ouvrir')))));
    await tester.tap(find.text('ouvrir'));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(DocumentViewerScreen), findsOneWidget);
    expect(faux.recues('GET', '/subjects/7/view'), hasLength(1));
  });
}
