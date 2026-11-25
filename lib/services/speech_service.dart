import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/l10n.dart';

/// Où en est la lecture à voix haute.
enum SpeechStatus { idle, playing, paused }

/// État exposé aux écrans (ValueListenableBuilder sur [SpeechService.state]).
@immutable
class SpeechState {
  final SpeechStatus status;

  /// Clé du texte lu (fourni par l'écran, par exemple « sheet:12 ») : permet
  /// à un écran de savoir si c'est SON texte qui est lu.
  final String? key;

  /// Vitesse choisie, 1.0 = normale (de [SpeechService.minRate] à [SpeechService.maxRate]).
  final double rate;

  /// Avancement dans le texte, de 0 à 1.
  final double progress;

  /// Phrase en cours (à partir de 0) et nombre de phrases du texte, pour
  /// une barre ou un surlignage.
  final int sentence;
  final int sentenceCount;

  /// Dernière erreur du moteur (aucun moteur de synthèse, langue absente…).
  final String? error;

  const SpeechState({
    this.status = SpeechStatus.idle,
    this.key,
    this.rate = 1.0,
    this.progress = 0,
    this.sentence = 0,
    this.sentenceCount = 0,
    this.error,
  });

  bool get isPlaying => status == SpeechStatus.playing;
  bool get isPaused => status == SpeechStatus.paused;

  SpeechState copyWith({SpeechStatus? status, String? key, bool clearKey = false, double? rate, double? progress, int? sentence, int? sentenceCount, String? error, bool clearError = false}) =>
      SpeechState(
        status: status ?? this.status,
        key: clearKey ? null : (key ?? this.key),
        rate: rate ?? this.rate,
        progress: progress ?? this.progress,
        sentence: sentence ?? this.sentence,
        sentenceCount: sentenceCount ?? this.sentenceCount,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Moteur de synthèse : flutter_tts en vrai, un faux dans les tests.
abstract class SpeechEngine {
  Future<void> setLanguage(String bcp47);

  /// Vitesse du moteur (0.5 = normale sur Android et iOS).
  Future<void> setRate(double engineRate);

  /// Lit [text] et se termine quand la lecture est finie ou arrêtée.
  Future<void> speak(String text);
  Future<void> stop();

  /// Position (en caractères) du mot en cours dans le texte passé à [speak].
  set onProgress(void Function(int offset)? handler);
  set onError(void Function(String message)? handler);
}

class FlutterTtsEngine implements SpeechEngine {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    // speak() attend la fin de la lecture : la file des morceaux en dépend.
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> setLanguage(String bcp47) async {
    await _init();
    await _tts.setLanguage(bcp47);
  }

  @override
  Future<void> setRate(double engineRate) async {
    await _init();
    await _tts.setSpeechRate(engineRate);
  }

  @override
  Future<void> speak(String text) async {
    await _init();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  set onProgress(void Function(int offset)? handler) =>
      _tts.setProgressHandler((text, start, end, word) => handler?.call(start));

  @override
  set onError(void Function(String message)? handler) =>
      _tts.setErrorHandler((msg) => handler?.call('$msg'));
}

/// Lecture à voix haute (atelier WinAI, étape 4), sans interface : lire,
/// pause, reprendre, arrêter, vitesse ; langue fr/en selon l'application.
///
/// La pause arrête le moteur en gardant la position, la reprise relit à
/// partir du mot en cours : même comportement sur Android et iOS (la pause
/// native d'Android n'existe pas sur toutes les versions). Les textes longs
/// sont lus par morceaux (Android refuse les textes de plus de 4 000
/// caractères environ).
class SpeechService {
  SpeechService._(this._engine) {
    _engine.onProgress = (offset) {
      _offsetInChunk = offset;
      _publishProgress();
    };
    _engine.onError = (message) {
      _run++;
      state.value = state.value.copyWith(status: SpeechStatus.idle, error: message);
    };
  }

  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._(FlutterTtsEngine());

  /// Tests : service sur un moteur simulé.
  @visibleForTesting
  static SpeechService withEngine(SpeechEngine engine) => _instance = SpeechService._(engine);

  static const minRate = 0.5;
  static const maxRate = 2.0;
  static const maxChunk = 3500;

  final SpeechEngine _engine;
  final ValueNotifier<SpeechState> state = ValueNotifier(const SpeechState());

  List<String> _chunks = const [];

  /// Début de chaque phrase : (morceau, position dans le morceau).
  List<(int, int)> _sentences = const [];
  int _chunk = 0;
  int _offsetInChunk = 0;

  /// Numéro de la lecture en cours : une boucle de lecture plus ancienne
  /// (arrêtée, mise en pause, remplacée) s'arrête d'elle-même.
  int _run = 0;

  /// Langue du moteur selon la langue de l'application.
  static String languageFor(String languageCode) => languageCode == 'en' ? 'en-US' : 'fr-FR';

  /// Lit [text] depuis le début (remplace toute lecture en cours).
  Future<void> speak(String text, {String? key}) async {
    final chunks = splitText(text);
    await _halt();
    if (chunks.isEmpty) {
      state.value = state.value.copyWith(status: SpeechStatus.idle, clearKey: true, progress: 0, clearError: true);
      return;
    }
    _chunks = chunks;
    _sentences = sentenceStarts(chunks);
    _chunk = 0;
    _offsetInChunk = 0;
    state.value = state.value.copyWith(
        status: SpeechStatus.playing,
        key: key,
        clearKey: key == null,
        progress: 0,
        sentence: 0,
        sentenceCount: _sentences.length,
        clearError: true);
    await _engine.setLanguage(languageFor(L10n.locale.languageCode));
    await _engine.setRate(_engineRate(state.value.rate));
    unawaited(_play(++_run));
  }

  Future<void> pause() async {
    if (!state.value.isPlaying) return;
    _run++;
    state.value = state.value.copyWith(status: SpeechStatus.paused);
    await _engine.stop();
  }

  Future<void> resume() async {
    if (!state.value.isPaused) return;
    state.value = state.value.copyWith(status: SpeechStatus.playing);
    unawaited(_play(++_run));
  }

  Future<void> stop() async {
    await _halt();
    _chunks = const [];
    _sentences = const [];
    state.value = state.value.copyWith(status: SpeechStatus.idle, clearKey: true, progress: 0, sentence: 0, sentenceCount: 0);
  }

  /// Change la vitesse (1.0 = normale). En cours de lecture, elle s'applique
  /// tout de suite en reprenant au mot en cours.
  Future<void> setRate(double rate) async {
    final r = rate.clamp(minRate, maxRate).toDouble();
    state.value = state.value.copyWith(rate: r);
    await _engine.setRate(_engineRate(r));
    if (state.value.isPlaying) {
      _run++;
      await _engine.stop();
      unawaited(_play(++_run));
    }
  }

  /// Bouton unique lire/pause/reprendre pour un texte donné.
  Future<void> toggle(String text, {required String key}) {
    final s = state.value;
    if (s.key == key && s.isPlaying) return pause();
    if (s.key == key && s.isPaused) return resume();
    return speak(text, key: key);
  }

  Future<void> _halt() async {
    _run++;
    if (state.value.status != SpeechStatus.idle) await _engine.stop();
  }

  static double _engineRate(double rate) => (rate * 0.5).clamp(0.0, 1.0).toDouble();

  Future<void> _play(int run) async {
    while (run == _run && _chunk < _chunks.length) {
      final chunk = _chunks[_chunk];
      final from = _offsetInChunk.clamp(0, chunk.length);
      final rest = chunk.substring(from);
      final base = from;
      // Les positions du moteur sont relatives au texte relu : on les
      // ramène au morceau entier.
      _engine.onProgress = (offset) {
        if (run != _run) return;
        _offsetInChunk = base + offset;
        _publishProgress();
      };
      if (rest.trim().isNotEmpty) await _engine.speak(rest);
      if (run != _run) return;
      _chunk++;
      _offsetInChunk = 0;
      _publishProgress();
    }
    if (run == _run) {
      state.value = state.value.copyWith(
          status: SpeechStatus.idle, progress: 1, sentence: _sentences.isEmpty ? 0 : _sentences.length - 1);
    }
  }

  void _publishProgress() {
    final total = _chunks.fold<int>(0, (n, c) => n + c.length);
    if (total == 0) return;
    final done = _chunks.take(_chunk).fold<int>(0, (n, c) => n + c.length) + _offsetInChunk;
    var sentence = 0;
    for (var i = 0; i < _sentences.length; i++) {
      final (c, o) = _sentences[i];
      if (c < _chunk || (c == _chunk && o <= _offsetInChunk)) sentence = i;
    }
    state.value = state.value.copyWith(progress: (done / total).clamp(0.0, 1.0).toDouble(), sentence: sentence);
  }

  /// Début de chaque phrase (après . ! ? … ou un retour à la ligne).
  @visibleForTesting
  static List<(int, int)> sentenceStarts(List<String> chunks) {
    final starts = <(int, int)>[];
    final end = RegExp(r'[.!?…]+\s+|\n+');
    for (var c = 0; c < chunks.length; c++) {
      final text = chunks[c];
      if (text.trim().isEmpty) continue;
      starts.add((c, 0));
      for (final m in end.allMatches(text)) {
        if (m.end < text.length) starts.add((c, m.end));
      }
    }
    return starts;
  }

  /// Texte lisible : sans balises markdown, découpé en morceaux de moins de
  /// [maxChunk] caractères, aux fins de phrase si possible.
  @visibleForTesting
  static List<String> splitText(String text) {
    final clean = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'[*_`>|]'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    if (clean.isEmpty) return const [];
    final chunks = <String>[];
    var rest = clean;
    while (rest.length > maxChunk) {
      var cut = -1;
      for (final sep in ['\n', '. ', '! ', '? ', '; ', ', ', ' ']) {
        final i = rest.lastIndexOf(sep, maxChunk - 1);
        if (i > maxChunk ~/ 2) {
          cut = i + sep.length;
          break;
        }
      }
      if (cut <= 0) cut = maxChunk;
      chunks.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    if (rest.isNotEmpty) chunks.add(rest);
    return chunks;
  }
}
