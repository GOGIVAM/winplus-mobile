import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/speech_service.dart';

/// Moteur simulé : chaque lecture reste en cours jusqu'à [finir] ou stop().
class _FauxMoteur implements SpeechEngine {
  final langues = <String>[];
  final vitesses = <double>[];
  final lus = <String>[];
  int arrets = 0;
  Completer<void>? _enCours;
  void Function(int)? progression;
  void Function(String)? erreur;

  @override
  Future<void> setLanguage(String bcp47) async => langues.add(bcp47);
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
    _terminer();
  }

  void _terminer() {
    final c = _enCours;
    _enCours = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Fin naturelle de la lecture en cours.
  Future<void> finir() async {
    _terminer();
    await pump();
  }

  @override
  set onProgress(void Function(int offset)? handler) => progression = handler;
  @override
  set onError(void Function(String message)? handler) => erreur = handler;
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _FauxMoteur moteur;
  late SpeechService svc;

  setUp(() {
    L10n.locale = const Locale('fr');
    moteur = _FauxMoteur();
    svc = SpeechService.withEngine(moteur);
  });
  tearDown(() => L10n.locale = const Locale('fr'));

  test('lire : langue de l\'application, vitesse normale, etat en lecture puis termine', () async {
    await svc.speak('Bonjour. Deuxieme phrase.', key: 'fiche:1');
    await pump();
    expect(moteur.langues, ['fr-FR']);
    expect(moteur.vitesses.last, 0.5);
    expect(moteur.lus, ['Bonjour. Deuxieme phrase.']);
    expect(svc.state.value.isPlaying, isTrue);
    expect(svc.state.value.key, 'fiche:1');
    expect(svc.state.value.sentenceCount, 2);
    moteur.progression!(9);
    expect(svc.state.value.sentence, 1);
    expect(svc.state.value.progress, closeTo(9 / 25, 0.001));
    await moteur.finir();
    expect(svc.state.value.status, SpeechStatus.idle);
    expect(svc.state.value.progress, 1);
  });

  test('anglais : en-US', () async {
    L10n.locale = const Locale('en');
    await svc.speak('Hello.');
    expect(moteur.langues, ['en-US']);
  });

  test('pause puis reprise : relit a partir du mot en cours', () async {
    await svc.speak('Un deux trois quatre.', key: 'k');
    await pump();
    moteur.progression!(8);
    await svc.pause();
    await pump();
    expect(svc.state.value.isPaused, isTrue);
    expect(moteur.arrets, 1);
    await svc.resume();
    await pump();
    expect(svc.state.value.isPlaying, isTrue);
    expect(moteur.lus.last, 'trois quatre.');
    // Les positions du moteur se rapportent au texte relu.
    moteur.progression!(6);
    expect(svc.state.value.progress, closeTo(14 / 21, 0.001));
    await moteur.finir();
    expect(svc.state.value.status, SpeechStatus.idle);
    expect(moteur.lus, hasLength(2), reason: 'la lecture arretee par la pause ne repart pas');
  });

  test('toggle : meme cle = pause puis reprise ; autre cle = nouvelle lecture', () async {
    await svc.toggle('Texte A.', key: 'a');
    await pump();
    await svc.toggle('Texte A.', key: 'a');
    expect(svc.state.value.isPaused, isTrue);
    await svc.toggle('Texte A.', key: 'a');
    await pump();
    expect(svc.state.value.isPlaying, isTrue);
    await svc.toggle('Texte B.', key: 'b');
    await pump();
    expect(svc.state.value.key, 'b');
    expect(moteur.lus.last, 'Texte B.');
  });

  test('vitesse bornee 0.5 a 2 ; en lecture, reprise au mot en cours', () async {
    await svc.setRate(5);
    expect(svc.state.value.rate, 2.0);
    expect(moteur.vitesses.last, 1.0);
    await svc.speak('Alpha beta gamma.');
    await pump();
    moteur.progression!(6);
    await svc.setRate(0.1);
    await pump();
    expect(svc.state.value.rate, 0.5);
    expect(moteur.vitesses.last, 0.25);
    expect(moteur.lus.last, 'beta gamma.');
    expect(svc.state.value.isPlaying, isTrue);
  });

  test('arreter : etat repos, plus de cle ; erreur du moteur exposee', () async {
    await svc.speak('Texte.', key: 'k');
    await pump();
    await svc.stop();
    expect(svc.state.value.status, SpeechStatus.idle);
    expect(svc.state.value.key, isNull);
    await svc.speak('Texte.');
    moteur.erreur!('no engine');
    expect(svc.state.value.status, SpeechStatus.idle);
    expect(svc.state.value.error, 'no engine');
  });

  test('texte vide ou seulement du markdown : rien n\'est lu', () async {
    await svc.speak('  # \n```code```  ');
    expect(moteur.lus, isEmpty);
    expect(svc.state.value.status, SpeechStatus.idle);
  });

  test('markdown nettoye et texte long lu par morceaux, phrases comptees sur tout le texte', () async {
    expect(SpeechService.splitText('# Titre\n\n- **gras** et [lien](https://x.y)\n- `code`'), ['Titre\ngras et lien\ncode']);
    const phrase = 'Phrase numero un assez longue pour remplir. ';
    final long = List.filled(200, phrase).join();
    final morceaux = SpeechService.splitText(long);
    expect(morceaux.length, greaterThan(1));
    expect(morceaux.every((m) => m.length <= SpeechService.maxChunk), isTrue);
    expect(morceaux.every((m) => m.endsWith('.')), isTrue, reason: 'coupe en fin de phrase');
    await svc.speak(long);
    await pump();
    expect(svc.state.value.sentenceCount, 200);
    for (var i = 0; i < morceaux.length; i++) {
      expect(moteur.lus.last, morceaux[i]);
      await moteur.finir();
    }
    expect(svc.state.value.status, SpeechStatus.idle);
    expect(svc.state.value.sentence, 199);
  });
}
