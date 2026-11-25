import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/barometer_tab.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/shared/messaging/messaging_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : baromètre de bien-être d'un enfant (GET /parent-alerts/{id}/barometre),
/// comme celui du site : état descriptif, signaux récents, sans score chiffré.
void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    await initialiserDates();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));
  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
  });

  Map<String, dynamic> signal(int id, String type, String severite, String message) => {
        'id': id, 'type': type, 'severity': severite, 'message': message,
        'isRead': false, 'detectedAt': '2026-11-20T08:00:00Z',
      };

  Future<void> monterVue(WidgetTester tester) => monterEcran(
      tester, const Scaffold(body: BarometerView(childId: 4, childName: 'Zoe')));

  testWidgets('signal prioritaire : etat, conseil, signaux avec type et gravite ; calcul demande d\'abord', (tester) async {
    faux.repond('GET', '/parent/ai-alerts/4', {'alerts': []});
    faux.repond('GET', '/parent-alerts/4/barometre', {
      'signals': [
        signal(1, 'Inactivite', 'High', 'Aucune activite depuis 8 jours'),
        signal(2, 'Surmenage', 'Low', 'Sessions tardives'),
      ],
    });
    await monterVue(tester);
    final l = L10n.current;
    expect(faux.recues('GET', '/parent/ai-alerts/4'), hasLength(1));
    expect(find.text(l.barometerStateHigh), findsOneWidget);
    expect(find.text(l.barometerHintSignals), findsOneWidget);
    expect(find.text('Aucune activite depuis 8 jours'), findsOneWidget);
    expect(find.text(l.barometerSeverityHigh), findsOneWidget);
    expect(find.text(l.barometerSeverityLow), findsOneWidget);
    expect(find.textContaining(l.barometerTypeInactive), findsOneWidget);
    await tester.tap(find.text(l.barometerWriteTo('Zoe')));
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('rien a signaler : etat calme, pas de bouton Ecrire ; le calcul en panne n\'empeche rien', (tester) async {
    faux.repond('GET', '/parent/ai-alerts/4', {'error': 'x'}, statut: 500);
    faux.repond('GET', '/parent-alerts/4/barometre', {'signals': []});
    await monterVue(tester);
    final l = L10n.current;
    expect(find.text(l.barometerStateNone), findsOneWidget);
    expect(find.text(l.barometerHintNone('Zoe')), findsOneWidget);
    expect(find.text(l.barometerEmpty), findsOneWidget);
    expect(find.text(l.barometerWriteTo('Zoe')), findsNothing);
  });

  testWidgets('barometre en panne : erreur et Reessayer', (tester) async {
    faux.repond('GET', '/parent-alerts/4/barometre', {'error': 'x'}, statut: 500);
    await monterVue(tester);
    final l = L10n.current;
    expect(find.text(l.commonLoadError), findsOneWidget);
    faux.repond('GET', '/parent-alerts/4/barometre', {'signals': []});
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.barometerStateNone), findsOneWidget);
  });

  testWidgets('page depuis « Plus » : choix de l\'enfant en haut, barometre de l\'enfant choisi', (tester) async {
    faux.repond('GET', '/parent/children', [
      {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
      {'id': 5, 'firstName': 'Leo', 'lastName': 'Eto'},
    ]);
    faux.repond('GET', '/parent-alerts/4/barometre', {'signals': []});
    faux.repond('GET', '/parent-alerts/5/barometre', {
      'signals': [signal(3, 'BaissePerformance', 'Medium', 'Notes en baisse en maths')],
    });
    await monterEcran(tester, const BarometerScreen());
    final l = L10n.current;
    expect(find.text(l.barometerStateNone), findsOneWidget);
    await tester.tap(find.text('Leo'));
    await reseau(tester);
    expect(find.text('Notes en baisse en maths'), findsOneWidget);
    expect(find.text(l.barometerStateMedium), findsOneWidget);
  });
}
