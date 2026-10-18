import 'dart:async';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'session_manager.dart';

/// Module 27 (lot 8) : push mobile via ntfy. Décision déjà prise :
/// "push via ntfy sans garantie quand l'application est fermée" — ce service
/// ne couvre donc que le premier plan (app ouverte), exactement comme le
/// fait le web (useNotifications.ts) : aucune notification système n'est
/// requise (pas de FCM/APNs), seulement un flux SSE écouté tant que l'app
/// est active, qui déclenche un rafraîchissement de la liste en mémoire.
///
/// Le flux est `GET /notifications/sse` (NotificationsController.cs),
/// qui proxifie ntfy avec ses propres identifiants côté serveur : le mobile
/// n'a besoin que de son JWT WinPlus, comme le web, et ne connaît jamais le
/// topic ntfy ni son jeton.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  StreamSubscription<List<int>>? _sub;
  Completer<void>? _done;
  CancelToken? _cancel;
  bool _active = false;
  /// Numéro de la boucle en cours : après stop() puis start() (changement de
  /// compte, retour sur la coquille), l'ancienne boucle encore en attente
  /// s'arrête au lieu d'ouvrir un second flux en parallèle.
  int _run = 0;
  Duration _delay = const Duration(seconds: 2);

  /// Appelle [onEvent] chaque fois qu'un évènement `data:` arrive sur le
  /// flux (nouvelle notification). Reconnecte avec un backoff exponentiel
  /// (plafonné à 60s) en cas de coupure, tant que [stop] n'a pas été appelé.
  /// Ne lève jamais : une panne de ce flux ne doit pas impacter le reste de
  /// l'app (même politique que le reste du projet pour les notifications).
  Future<void> start(void Function() onEvent) async {
    if (_active) return;
    _active = true;
    _delay = const Duration(seconds: 2);
    _loop(onEvent, ++_run);
  }

  void stop() {
    _active = false;
    _run++;
    _cancel?.cancel();
    _cancel = null;
    _sub?.cancel();
    _sub = null;
    // Débloque la boucle en attente de fin de flux (cancel() ne déclenche
    // pas onDone).
    if (_done != null && !_done!.isCompleted) _done!.complete();
  }

  Future<void> _loop(void Function() onEvent, int run) async {
    bool alive() => _active && run == _run;
    while (alive()) {
      final token = await SessionManager.getAccessToken();
      if (token == null || token.isEmpty) {
        await Future.delayed(_delay);
        continue;
      }

      try {
        final dio = ApiClient.instance.dio;
        final cancel = CancelToken();
        _cancel = cancel;
        final res = await dio.get<ResponseBody>(
          '/notifications/sse',
          cancelToken: cancel,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        );

        if (!alive()) return;
        _delay = const Duration(seconds: 2);
        // Une reconnexion peut avoir manqué des évènements : resynchronise.
        onEvent();

        final completer = Completer<void>();
        _done = completer;
        _sub = res.data?.stream.listen(
          (chunk) {
            final text = String.fromCharCodes(chunk);
            if (text.contains('data:')) onEvent();
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (_) {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );
        if (_sub == null && !completer.isCompleted) completer.complete();
        await completer.future;
      } catch (_) {
        // Coupure réseau ou 401 : on retente avec un délai croissant plutôt
        // que de marteler le serveur.
      }

      if (alive()) {
        await Future.delayed(_delay);
        final nextMs = _delay.inMilliseconds * 2;
        _delay = Duration(milliseconds: nextMs > 60000 ? 60000 : nextMs);
      }
    }
  }
}
