import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/correction_queue_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

final _copies = [
  {'id': 1, 'studentName': 'Ada Eto', 'contentTitle': 'Devoir de maths', 'submittedAt': '5 janvier', 'corrected': false},
  {'id': 2, 'studentName': 'Bob Nku', 'contentTitle': 'Devoir de physique', 'submittedAt': '6 janvier', 'corrected': true, 'score': 15},
  {'id': 3, 'studentName': 'Cleo Ban', 'contentTitle': 'Devoir de chimie', 'submittedAt': '7 janvier', 'corrected': false},
];

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('chargement puis copies : eleve, titre, note ou « en attente », compteur', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    telephone(tester);
    await monter(tester, ecran(const CorrectionQueueScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('Ada Eto'), findsOneWidget);
    expect(find.text('Devoir de physique'), findsOneWidget);
    expect(find.text('15/20'), findsOneWidget);
    expect(find.text(l.teacherCorrectionPendingCount(2)), findsOneWidget);
    expect(_bouton(l.teacherCorrectionCorrect), findsNWidgets(2));
    expect(_bouton(l.commonEdit), findsOneWidget);
  });

  testWidgets('liste enveloppee dans { items } acceptee', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'items': _copies});
    await monterEcran(tester, const CorrectionQueueScreen());
    expect(find.text('Ada Eto'), findsOneWidget);
  });

  testWidgets('aucune copie : « rien a corriger » ; panne : erreur et bouton Reessayer', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', []);
    await monterEcran(tester, const CorrectionQueueScreen());
    expect(find.text(L10n.current.teacherCorrectionEmpty), findsOneWidget);
    faux.repond('GET', '/teacher/corrections/pending', {}, statut: 500);
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
    await reseau(tester);
    expect(find.text(L10n.current.teacherCorrectionEmpty), findsNothing);
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    await tester.tap(find.text(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text('Ada Eto'), findsOneWidget);
  });

  testWidgets('filtres : « En attente » et « Corrige »', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    await monterEcran(tester, const CorrectionQueueScreen());
    await tester.tap(find.widgetWithText(WinChip, L10n.current.teacherCorrectionFilterMarked));
    await pomper(tester);
    expect(find.text('Bob Nku'), findsOneWidget);
    expect(find.text('Ada Eto'), findsNothing);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.commonPending));
    await pomper(tester);
    expect(find.text('Ada Eto'), findsOneWidget);
    expect(find.text('Bob Nku'), findsNothing);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.commonAll));
    await pomper(tester);
    expect(find.text('Cleo Ban'), findsOneWidget);
  });

  testWidgets('feuille de correction : note par defaut 12/20, envoi avec note et commentaire', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    faux.repond('POST', '/corrections/1', {});
    await monterEcran(tester, const CorrectionQueueScreen());
    await tester.tap(_bouton(L10n.current.teacherCorrectionCorrect).first);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    final l = L10n.current;
    expect(find.text(l.teacherCorrectionSheetTitle('Ada Eto')), findsOneWidget);
    expect(find.text('12/20'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(16);
    await pomper(tester);
    expect(find.text('16/20'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Bon travail ');
    await tester.tap(_bouton(l.teacherCorrectionSend));
    await reseau(tester);
    expect(faux.recues('POST', '/corrections/1').single.data, {'note': 16, 'comment': 'Bon travail', 'status': 'submitted'});
    expect(find.text(l.teacherCorrectionSent('Ada Eto')), findsOneWidget);
  });

  testWidgets('envoi de la correction refuse : message d\'erreur, formulaire conserve', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    await monterEcran(tester, const CorrectionQueueScreen());
    await tester.tap(_bouton(L10n.current.teacherCorrectionCorrect).first);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(L10n.current.teacherCorrectionSend));
    await reseau(tester);
    expect(find.text(L10n.current.teacherCorrectionSendError), findsOneWidget);
    expect(_bouton(L10n.current.teacherCorrectionSend), findsOneWidget);
  });

  testWidgets('fermer la feuille recharge la liste', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', _copies);
    faux.repond('POST', '/corrections/1', {});
    await monterEcran(tester, const CorrectionQueueScreen());
    await tester.tap(_bouton(L10n.current.teacherCorrectionCorrect).first);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(_bouton(L10n.current.teacherCorrectionSend));
    await reseau(tester);
    await tester.tapAt(const Offset(200, 20));
    await pomper(tester, const Duration(milliseconds: 500));
    await reseau(tester);
    expect(faux.recues('GET', '/teacher/corrections/pending'), hasLength(2));
  });
}
