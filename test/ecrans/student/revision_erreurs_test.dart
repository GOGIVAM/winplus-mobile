import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/quiz_revision_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

String _ilYa(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({List<Map<String, dynamic>> erreurs = const [], List<Map<String, dynamic>> matieres = const []}) {
    faux.repond('GET', '/quiz/mistakes', {'data': erreurs});
    faux.repond('GET', '/quiz/mistakes/subjects', {'data': matieres});
  }

  testWidgets('chargement puis questions ratees avec reponse donnee et bonne reponse', (tester) async {
    routes(erreurs: [
      {'id': 1, 'question': 'Capitale du Cameroun ?', 'givenAnswer': 'Douala', 'correctAnswer': 'Yaounde', 'subject': 'Geographie', 'createdAt': _ilYa(const Duration(minutes: 20))},
    ]);
    telephone(tester);
    await monter(tester, ecran(const QuizRevisionScreen()));
    expect(chargement, findsOneWidget);
    await reseau(tester);
    expect(find.text('Capitale du Cameroun ?'), findsOneWidget);
    expect(find.text('Douala'), findsOneWidget);
    expect(find.text('Yaounde'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.x), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
    expect(find.text(L10n.current.studentRevisionMinutesAgo(20)), findsOneWidget);
  });

  testWidgets('aucune erreur : message dedie', (tester) async {
    routes();
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.text(L10n.current.studentRevisionEmpty), findsOneWidget);
  });

  testWidgets('erreur serveur : message d\'erreur', (tester) async {
    faux.repond('GET', '/quiz/mistakes', {}, statut: 500);
    faux.repond('GET', '/quiz/mistakes/subjects', {'data': []});
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.text(L10n.current.studentRevisionLoadError), findsOneWidget);
  });

  testWidgets('filtres par matiere : « Toutes » plus une puce par matiere, envoi du filtre choisi', (tester) async {
    routes(matieres: [
      {'subject': 'Maths', 'count': 2},
      {'subject': 'Physique', 'count': 1},
    ]);
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.widgetWithText(WinChip, L10n.current.studentRevisionAll), findsOneWidget);
    expect(faux.recues('GET', '/quiz/mistakes').single.queryParameters, isEmpty);
    await tester.tap(find.widgetWithText(WinChip, 'Maths'));
    await reseau(tester);
    expect(faux.recues('GET', '/quiz/mistakes').last.queryParameters, {'subject': 'Maths'});
    await tester.tap(find.widgetWithText(WinChip, L10n.current.studentRevisionAll));
    await reseau(tester);
    expect(faux.recues('GET', '/quiz/mistakes').last.queryParameters, isEmpty);
  });

  testWidgets('sans matiere : aucune rangee de filtres', (tester) async {
    routes();
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.byType(WinChip), findsNothing);
  });

  testWidgets('« Maitrise » marque l\'erreur resolue puis recharge', (tester) async {
    routes(erreurs: [
      {'id': 5, 'question': 'Q ?', 'createdAt': _ilYa(const Duration(hours: 3))},
    ]);
    faux.repond('POST', '/quiz/mistakes/5/resolve', {});
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.text(L10n.current.studentRevisionHoursAgo(3)), findsOneWidget);
    routes();
    await tester.tap(find.widgetWithText(WinButton, L10n.current.studentDetailTagMastered));
    await reseau(tester);
    expect(faux.recues('POST', '/quiz/mistakes/5/resolve'), hasLength(1));
    expect(find.text('Q ?'), findsNothing);
    expect(find.text(L10n.current.studentRevisionEmpty), findsOneWidget);
  });

  testWidgets('bouton de retour au catalogue present quand des erreurs existent', (tester) async {
    routes(erreurs: [
      {'id': 5, 'question': 'Q ?', 'createdAt': _ilYa(const Duration(days: 3))},
    ]);
    await monterEcran(tester, const QuizRevisionScreen());
    expect(find.text(L10n.current.studentRevisionDaysAgo(3)), findsOneWidget);
    expect(find.widgetWithText(WinButton, L10n.current.studentRevisionBackToCatalog), findsOneWidget);
  });
}
