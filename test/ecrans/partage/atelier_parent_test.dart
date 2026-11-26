import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/shared/winai/winai_screen.dart';
import 'package:winplus/shared/winai/winai_tools.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Atelier WinAI du parent : le bilan de la semaine part des resultats reels
/// de l'enfant choisi (redige par le serveur).
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement(prefs: {'user_role': 'parent'});
    await LocalCacheService.parentDashboard.clear();
  });

  testWidgets('atelier du parent : « Bilan de la semaine » choisit l enfant puis ouvre le bilan redige par le serveur', (tester) async {
    faux.repond('GET', '/parent/children', [
      {'id': 30, 'firstName': 'Awa', 'lastName': 'Ngo'},
      {'id': 31, 'firstName': 'Paul', 'lastName': 'Ngo'},
    ]);
    faux.repond('POST', '/parent/children/30/bilan-semaine', {
      'data': {'id': 4, 'title': 'Bilan de la semaine de Awa', 'text': 'Awa a travaille quatre jours cette semaine.'}
    }, statut: 201);
    await monterEcran(tester, const WinAIScreen(role: WinRole.parent));
    final l = L10n.current;
    await tester.tap(find.text(l.winaiTabStudio));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(l.winaiToolWeekReport));
    await pomper(tester);
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(l.winaiPickChild), findsOneWidget);
    await tester.tap(find.text('Awa Ngo'));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(faux.recues('POST', '/parent/children/30/bilan-semaine'), hasLength(1));
    expect(find.byType(WinAITextScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('Bilan de la semaine de Awa'), findsOneWidget);
  });

  testWidgets('bilan de la semaine : limite WinAI du parent, message du serveur et acces aux offres', (tester) async {
    faux.repond('GET', '/parent/children', [
      {'id': 30, 'firstName': 'Awa', 'lastName': 'Ngo'},
    ]);
    faux.repond('POST', '/parent/children/30/bilan-semaine',
        {'success': false, 'error': 'Limite de la semaine atteinte.', 'code': 'ai_quota_exceeded'}, statut: 402);
    await monterEcran(tester, const WinAIScreen(role: WinRole.parent));
    final l = L10n.current;
    await tester.tap(find.text(l.winaiTabStudio));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(l.winaiToolWeekReport));
    await pomper(tester);
    await reseau(tester);
    await reseau(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    // Un seul enfant : pas de choix a faire.
    expect(find.text(l.winaiPickChild), findsNothing);
    expect(find.byType(WinAITextScreen, skipOffstage: false), findsNothing);
    expect(find.text('Limite de la semaine atteinte.'), findsOneWidget);
    expect(find.text(l.winaiStudioSeePlans), findsOneWidget);
  });
}
