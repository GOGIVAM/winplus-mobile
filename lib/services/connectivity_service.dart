import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Levée par [requireOnline] pour les actions qui ne doivent jamais être
/// mises en file hors ligne (paiements, crédits, liaison/déliaison
/// parent-enfant, génération IA, demandes d'accès enseignant) : elles
/// doivent échouer explicitement, jamais silencieusement ni en attente.
class OfflineActionException implements Exception {
  final String message;
  const OfflineActionException(
      [this.message = 'Cette action nécessite une connexion internet.']);
  @override
  String toString() => message;
}

/// À appeler en tout début des méthodes de service listées ci-dessus.
void requireOnline() {
  if (!ConnectivityService.instance.isOnline) {
    throw const OfflineActionException();
  }
}

/// État réseau global de l'app, exposé en flux pour que les écrans affichent
/// une bannière discrète plutôt qu'un écran vide + bouton Réessayer, et pour
/// déclencher la synchronisation de l'OutboxService au retour du réseau.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Émet à chaque changement d'état (true = en ligne, false = hors ligne).
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> start() async {
    final initial = await Connectivity().checkConnectivity();
    _isOnline = _resultsToOnline(initial);

    _sub ??= Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _resultsToOnline(results);
      if (_isOnline != wasOnline) _controller.add(_isOnline);
    });
  }

  bool _resultsToOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
