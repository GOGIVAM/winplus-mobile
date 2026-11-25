import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/speech_service.dart';
import 'package:winplus/services/winai_studio_service.dart';
import 'package:winplus/shared/winai/winai_creations.dart';
import 'package:winplus/shared/winai/winai_listen_bar.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// Voix simulée : la lecture dure jusqu'à l'arrêt.
class _FausseVoix implements SpeechEngine {
  final lus = <String>[];
  final vitesses = <double>[];
  int arrets = 0;
  Completer<void>? _enCours;

  @override
  set onProgress(void Function(int offset)? handler) {}
  @override
  set onError(void Function(String message)? handler) {}
  @override
  Future<void> setLanguage(String bcp47) async {}
  @override
  Future<void> setRate(double engineRate) async => vitesses.add(engineRate);
  @override
  Future<void> speak(String text) {
    lus.add(text);
    _enCours = Completer<void>();
    return _enCours!.future;
  }

  @override
  Future<void> stop() async {
    arrets++;
    final c = _enCours;
    _enCours = null;
    if (c != null && !c.isCompleted) c.complete();
  }
}

void main() {
  late _FausseVoix voix;

  setUp(() async {
    preparerEnvironnement();
    voix = _FausseVoix();
    SpeechService.withEngine(voix);
  });

  const fiche = StudioSheet(
      id: 12,
      title: 'Fiche : derivees',
      subject: 'Maths',
      topic: 'Derivees',
      content: '# Derivees\n\nLa derivee mesure une variation. Elle sert partout.',
      durationMinutes: 15,
      isAiGenerated: true,
      hidden: false);

  testWidgets('fiche : la barre d ecoute lit le texte, met en pause, change la vitesse, puis s arrete en quittant', (tester) async {
    await monterEcran(tester, const WinAISheetScreen(sheet: fiche));
    final l = L10n.current;
    expect(find.text('Fiche : derivees'), findsOneWidget);
    expect(find.byType(WinAIListenBar), findsOneWidget);
    expect(find.text(l.winaiListen), findsOneWidget);
    expect(voix.lus, isEmpty);

    await tester.tap(find.byIcon(PhosphorIconsFill.play));
    await pomper(tester);
    // Le texte est lu sans les marques de mise en forme.
    expect(voix.lus, hasLength(1));
    expect(voix.lus.single, contains('La derivee mesure une variation'));
    expect(voix.lus.single, isNot(contains('#')));
    expect(find.text(l.winaiListenPause), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.pause), findsOneWidget);

    await tester.tap(find.byIcon(PhosphorIconsFill.pause));
    await pomper(tester);
    expect(find.text(l.winaiListenResume), findsOneWidget);

    // Vitesse : 1 puis 1,25.
    expect(find.text('1×'), findsOneWidget);
    await tester.tap(find.text('1×'));
    await pomper(tester);
    expect(find.text('1.25×'), findsOneWidget);

    // Quitter l'écran arrête la lecture.
    final arretsAvant = voix.arrets;
    await monter(tester, const SizedBox());
    await pomper(tester);
    expect(voix.arrets, greaterThan(arretsAvant));
    expect(SpeechService.instance.state.value.status, SpeechStatus.idle);
  });

  testWidgets('fiche sans texte : etat vide, pas de barre d ecoute', (tester) async {
    await monterEcran(
        tester,
        const WinAISheetScreen(
            sheet: StudioSheet(
                id: 13,
                title: 'Vide',
                subject: 'Maths',
                topic: '',
                durationMinutes: 0,
                isAiGenerated: true,
                hidden: false)));
    expect(find.text(L10n.current.winaiSheetEmpty), findsOneWidget);
    expect(find.byType(WinAIListenBar), findsNothing);
  });
}
