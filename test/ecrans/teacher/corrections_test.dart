import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/correction_queue_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

// Forme reelle de GET /teacher/corrections/pending?filter=all
// (PendingCorrectionDto) : assignment, subject (niveau de la classe),
// submittedDate sans fuseau, daysWaiting, priority, status, score sur maxScore.
final _copies = [
  {
    'id': 1, 'assignmentId': 10, 'assignment': 'Devoir de maths', 'studentName': 'Ada Eto',
    'subject': 'Terminale C', 'submittedDate': '2026-01-05T09:00:00.0000000', 'daysWaiting': 3,
    'priority': 'high', 'status': 'pending', 'maxScore': 20, 'textContent': 'Ma reponse au probleme',
  },
  {
    'id': 2, 'assignmentId': 11, 'assignment': 'Devoir de physique', 'studentName': 'Bob Nku',
    'submittedDate': '2026-01-06T09:00:00.0000000', 'daysWaiting': 2, 'priority': 'normal',
    'status': 'corrected', 'score': 15, 'maxScore': 20, 'comment': 'Bien',
  },
  {
    'id': 3, 'assignmentId': 12, 'assignment': 'Quiz de chimie', 'studentName': 'Cleo Ban',
    'submittedDate': '2026-01-07T09:00:00.0000000', 'daysWaiting': 0, 'priority': 'normal',
    'status': 'draft', 'score': 60, 'maxScore': 100, 'fileUrl': 'https://exemple.cm/copie.pdf',
  },
];

Future<void> _ouvrirFeuille(WidgetTester tester, Finder bouton) async {
  await tester.tap(bouton);
  await pomper(tester);
  await pomper(tester, const Duration(milliseconds: 400));
}

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('cartes : devoir, eleve et classe, date de remise, attente, note sur 20, urgent et brouillon', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    telephone(tester);
    await monter(tester, ecran(const CorrectionQueueScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(faux.recues('GET', '/teacher/corrections/pending').single.queryParameters['filter'], 'all');
    expect(find.text('Devoir de maths'), findsOneWidget);
    expect(find.text('Ada Eto · Terminale C'), findsOneWidget);
    expect(find.text('Bob Nku'), findsOneWidget);
    final remise = l.teacherCorrectionSubmittedOn(WinFormat.dayMonth(DateTime.utc(2026, 1, 5, 9)));
    expect(find.text('$remise · ${l.teacherCorrectionWaitingDays(3)}'), findsOneWidget);
    expect(find.text(WinFormat.grade20(75)), findsOneWidget);
    expect(find.text(l.teacherCorrectionUrgent), findsOneWidget);
    expect(find.text(l.commonDraft), findsOneWidget);
    expect(find.text(l.teacherCorrectionPendingCount(2)), findsOneWidget);
    expect(_bouton(l.teacherCorrectionCorrect), findsNWidgets(2));
    expect(_bouton(l.commonEdit), findsOneWidget);
  });

  testWidgets('liste brute ou enveloppee dans { items } acceptee', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'items': _copies});
    await monterEcran(tester, const CorrectionQueueScreen());
    expect(find.text('Devoir de maths'), findsOneWidget);
  });

  testWidgets('aucune copie : etat vide ; panne : erreur et bouton Reessayer', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': []});
    await monterEcran(tester, const CorrectionQueueScreen());
    expect(find.text(L10n.current.teacherCorrectionEmpty), findsOneWidget);
    faux.repond('GET', '/teacher/corrections/pending', {}, statut: 500);
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
    await reseau(tester);
    expect(find.text(L10n.current.teacherCorrectionEmpty), findsNothing);
    expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    await tester.tap(find.text(L10n.current.commonRetry));
    await reseau(tester);
    expect(find.text('Devoir de maths'), findsOneWidget);
  });

  testWidgets('filtres : En attente (brouillon compris) et Corrige', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    await monterEcran(tester, const CorrectionQueueScreen());
    await tester.tap(find.widgetWithText(WinChip, L10n.current.teacherCorrectionFilterMarked));
    await pomper(tester);
    expect(find.text('Devoir de physique'), findsOneWidget);
    expect(find.text('Devoir de maths'), findsNothing);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.commonPending));
    await pomper(tester);
    expect(find.text('Devoir de maths'), findsOneWidget);
    expect(find.text('Quiz de chimie'), findsOneWidget);
    expect(find.text('Devoir de physique'), findsNothing);
    await tester.tap(find.widgetWithText(WinChip, L10n.current.commonAll));
    await pomper(tester);
    expect(find.text('Devoir de physique'), findsOneWidget);
  });

  testWidgets('feuille d une nouvelle copie : texte de l eleve, 12/20 par defaut, envoi de la note et du commentaire', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    faux.repond('POST', '/corrections/1', {});
    await monterEcran(tester, const CorrectionQueueScreen());
    await _ouvrirFeuille(tester, _bouton(L10n.current.teacherCorrectionCorrect).first);
    final l = L10n.current;
    expect(find.text(l.teacherCorrectionSheetTitle('Ada Eto')), findsOneWidget);
    expect(find.text('Ma reponse au probleme'), findsOneWidget);
    expect(find.text(l.teacherCorrectionScale('20')), findsOneWidget);
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

  testWidgets('copie corrigee : la feuille reprend la note et le commentaire donnes', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    await monterEcran(tester, const CorrectionQueueScreen());
    await _ouvrirFeuille(tester, _bouton(L10n.current.commonEdit));
    expect(find.text('15/20'), findsNWidgets(2));
    expect(find.text('Bien'), findsOneWidget);
    expect(find.text(L10n.current.teacherCorrectionNoWork), findsOneWidget);
  });

  testWidgets('quiz note sur 100 : bareme du devoir, demi-point, fichier rendu a ouvrir', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    faux.repond('POST', '/corrections/3', {});
    await monterEcran(tester, const CorrectionQueueScreen());
    await _ouvrirFeuille(tester, _bouton(L10n.current.teacherCorrectionCorrect).last);
    final l = L10n.current;
    expect(find.text(l.teacherCorrectionScale('100')), findsOneWidget);
    expect(find.text('60/100'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).max, 100);
    expect(_bouton(l.teacherCorrectionOpenFile), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(72.5);
    await pomper(tester);
    await tester.tap(_bouton(l.teacherCorrectionSend));
    await reseau(tester);
    expect(faux.recues('POST', '/corrections/3').single.data['note'], 72.5);
  });

  testWidgets('envoi de la correction refuse : message d erreur, formulaire conserve', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    await monterEcran(tester, const CorrectionQueueScreen());
    await _ouvrirFeuille(tester, _bouton(L10n.current.teacherCorrectionCorrect).first);
    await tester.tap(_bouton(L10n.current.teacherCorrectionSend));
    await reseau(tester);
    expect(find.text(L10n.current.teacherCorrectionSendError), findsOneWidget);
    expect(_bouton(L10n.current.teacherCorrectionSend), findsOneWidget);
  });

  testWidgets('fermer la feuille recharge la liste', (tester) async {
    faux.repond('GET', '/teacher/corrections/pending', {'data': _copies});
    faux.repond('POST', '/corrections/1', {});
    await monterEcran(tester, const CorrectionQueueScreen());
    await _ouvrirFeuille(tester, _bouton(L10n.current.teacherCorrectionCorrect).first);
    await tester.tap(_bouton(L10n.current.teacherCorrectionSend));
    await reseau(tester);
    await tester.tapAt(const Offset(200, 20));
    await pomper(tester, const Duration(milliseconds: 500));
    await reseau(tester);
    expect(faux.recues('GET', '/teacher/corrections/pending'), hasLength(2));
  });
}
