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
  bool _active = false;
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
    _loop(onEvent);
  }

  void stop() {
    _active = false;
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _loop(void Function() onEvent) async {
    while (_active) {
      final token = await SessionManager.getAccessToken();
      if (token == null || token.isEmpty) {
        await Future.delayed(_delay);
        continue;
      }

      try {
        final dio = ApiClient.instance.dio;
        final res = await dio.get<ResponseBody>(
          '/notifications/sse',
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        );

        if (!_active) return;
        _delay = const Duration(seconds: 2);

        final completer = Completer<void>();
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
        await completer.future;
      } catch (_) {
        // Coupure réseau ou 401 : on retente avec un délai croissant plutôt
        // que de marteler le serveur.
      }

      if (_active) {
        await Future.delayed(_delay);
        final nextMs = _delay.inMilliseconds * 2;
        _delay = Duration(milliseconds: nextMs > 60000 ? 60000 : nextMs);
      }
    }
  }
}
