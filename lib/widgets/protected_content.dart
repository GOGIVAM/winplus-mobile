import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Protection des contenus payants contre la capture d'écran (Android,
/// FLAG_SECURE posé par MainActivity). Plusieurs écrans protégés peuvent être
/// ouverts l'un sur l'autre (lecteur puis PDF d'une leçon) : un compteur ne
/// retire la protection qu'à la fermeture du dernier.
///
/// Sans effet hors d'Android (iOS ne permet pas d'interdire la capture) et
/// dans les tests (aucun canal natif).
class ScreenProtection {
  ScreenProtection._();

  static const _canal = MethodChannel('cm.winplus/ecran');
  static int _ouverts = 0;

  static bool get _actif => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> acquerir() async {
    _ouverts++;
    if (_ouverts == 1) await _appeler('proteger');
  }

  static Future<void> liberer() async {
    if (_ouverts == 0) return;
    _ouverts--;
    if (_ouverts == 0) await _appeler('liberer');
  }

  static Future<void> _appeler(String methode) async {
    if (!_actif) return;
    try {
      await _canal.invokeMethod<void>(methode);
    } on MissingPluginException {
      // Tests ou moteur sans MainActivity : rien a proteger.
    } on PlatformException {
      // La protection est un plus : son echec ne doit pas bloquer la lecture.
    }
  }
}
