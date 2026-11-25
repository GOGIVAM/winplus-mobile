import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/http_cache.dart';
import 'package:winplus/shared/downloads/my_downloads_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 3 : « Mes téléchargements » : leçons enregistrées du compte, pages
/// gardées pour le mode hors ligne, place occupée et suppression.
void main() {
  late Directory dossier;
  late Box box;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boîte en mémoire : une écriture disque ne finit jamais dans le temps
    // simulé d'un test d'écran.
    box = await Hive.openBox('CourseOfflineBox', bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    preparerEnvironnement(prefs: {'user_id': 7});
    await box.clear();
  });

  Future<void> lecon(int courseId, int lessonId, String titre, int taille, {int compte = 7}) =>
      box.put('${courseId}_$lessonId', {
        'courseId': courseId,
        'lessonId': lessonId,
        'title': titre,
        'sizeBytes': taille,
        'downloadedAt': DateTime(2026, 11, lessonId).toIso8601String(),
        'path': '${dossier.path}/course_offline/$compte/${courseId}_$lessonId.enc',
      });

  /// Laisse finir les accès réels au disque (suppression de fichier).
  Future<void> disque(WidgetTester tester) async {
    // Une suppression par tour : plusieurs tours pour « Tout supprimer ».
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await reseau(tester);
    }
  }

  Future<void> garderPage(String path) => HttpCache.instance.save(Response(
        requestOptions: RequestOptions(path: path),
        data: {'items': List.generate(50, (i) => 'element $i')},
        statusCode: 200,
      ));

  testWidgets('lecons du compte seulement, les plus recentes d\'abord, avec la place totale', (tester) async {
    await lecon(1, 2, 'Derivees', 5 * 1024 * 1024);
    await lecon(1, 3, 'Integrales', 3 * 1024 * 1024);
    await lecon(9, 9, 'Autre compte', 1024, compte: 8);
    await monterEcran(tester, const MyDownloadsScreen());
    final l = L10n.current;
    expect(find.text('Derivees'), findsOneWidget);
    expect(find.text('Integrales'), findsOneWidget);
    expect(find.text('Autre compte'), findsNothing);
    expect(find.text('5.0 Mo'), findsOneWidget);
    expect(find.text(l.dlTotal('8.0 Mo')), findsOneWidget);
    final y1 = tester.getTopLeft(find.text('Integrales')).dy;
    final y2 = tester.getTopLeft(find.text('Derivees')).dy;
    expect(y1, lessThan(y2), reason: 'la plus recente (3 novembre) en premier');
  });

  testWidgets('supprimer une lecon apres confirmation libere sa place', (tester) async {
    await lecon(1, 2, 'Derivees', 1024 * 1024);
    await lecon(1, 3, 'Integrales', 1024 * 1024);
    await monterEcran(tester, const MyDownloadsScreen());
    final l = L10n.current;
    await tester.tap(find.byIcon(PhosphorIconsRegular.trash).first);
    await reseau(tester);
    expect(find.text(l.dlDeleteLessonTitle), findsOneWidget);
    await tester.tap(find.text(l.commonDelete).last);
    await disque(tester);
    expect(find.text('Integrales'), findsNothing);
    expect(find.text('Derivees'), findsOneWidget);
    expect(box.length, 1);
    expect(find.text(l.dlFreed), findsOneWidget);
  });

  testWidgets('annuler ne supprime rien ; tout supprimer vide la liste', (tester) async {
    await lecon(1, 2, 'Derivees', 1024);
    await lecon(1, 3, 'Integrales', 1024);
    await monterEcran(tester, const MyDownloadsScreen());
    final l = L10n.current;
    await tester.tap(find.byIcon(PhosphorIconsRegular.trash).first);
    await reseau(tester);
    await tester.tap(find.text(l.commonCancel));
    await reseau(tester);
    expect(box.length, 2);
    await tester.tap(find.text(l.dlDeleteAll));
    await reseau(tester);
    expect(find.text(l.dlDeleteAllTitle), findsOneWidget);
    await tester.tap(find.text(l.dlDeleteAll).last);
    await disque(tester);
    expect(box.length, 0);
    expect(find.text(l.dlLessonsEmpty), findsOneWidget);
  });

  testWidgets('pages gardees pour le mode hors ligne : nombre, place, et Vider', (tester) async {
    await garderPage('/student/dashboard');
    await garderPage('/subjects');
    await monterEcran(tester, const MyDownloadsScreen());
    final l = L10n.current;
    expect(find.textContaining(l.dlCacheBody(2, '').split('(').first), findsOneWidget);
    await tester.tap(find.text(l.dlCacheClear));
    await reseau(tester);
    await tester.tap(find.text(l.dlCacheClear).last);
    await reseau(tester);
    expect(find.text(l.dlCacheEmpty), findsOneWidget);
    expect((await HttpCache.instance.statsForUser(7)).entries, 0);
  });

  test('statsForUser ne compte que le compte demande', () async {
    preparerEnvironnement(prefs: {'user_id': 7});
    await garderPage('/a');
    expect((await HttpCache.instance.statsForUser(7)).entries, 1);
    expect((await HttpCache.instance.statsForUser(8)).entries, 0);
    expect((await HttpCache.instance.statsForUser(7)).bytes, greaterThan(100));
  });

  test('taille lisible', () {
    expect(formatSize(512), '1 Ko');
    expect(formatSize(5 * 1024 * 1024), '5.0 Mo');
  });
}