import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'session_manager.dart';

/// Déverrouillage de l'application par empreinte ou visage (local_auth).
///
/// Activé, il est demandé à chaque lancement avec une session ouverte, et
/// chaque déverrouillage réussi compte comme une preuve d'identité : plus
/// de code de reconfirmation par e-mail tant qu'il sert. Proposé une fois
/// après la connexion, réglable ensuite depuis l'avatar.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const enabledKey = 'biometric_enabled';
  static const offeredKey = 'biometric_offered';

  final LocalAuthentication _auth = LocalAuthentication();

  /// Tests : remplace la vérification du téléphone.
  @visibleForTesting
  Future<bool> Function()? debugAvailable;
  @visibleForTesting
  Future<bool> Function()? debugAuthenticate;

  /// Le téléphone a-t-il une empreinte ou un visage enregistré ?
  Future<bool> isAvailable() async {
    final fake = debugAvailable;
    if (fake != null) return fake();
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(enabledKey, enabled);
    await p.setBool(offeredKey, true);
  }

  /// Faut-il proposer l'empreinte (disponible, jamais proposée ni activée) ?
  Future<bool> shouldOffer() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(offeredKey) ?? false) return false;
    if (p.getBool(enabledKey) ?? false) return false;
    return isAvailable();
  }

  Future<void> markOffered() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(offeredKey, true);
  }

  /// Demande l'empreinte ; une réussite compte comme preuve d'identité.
  /// Faux si la personne annule, échoue, ou si le téléphone refuse.
  Future<bool> authenticate() async {
    bool ok;
    final fake = debugAuthenticate;
    if (fake != null) {
      ok = await fake();
    } else {
      try {
        ok = await _auth.authenticate(
          localizedReason: L10n.current.biometricReason,
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
      } catch (e) {
        debugPrint('biometric: $e');
        ok = false;
      }
    }
    if (ok) await SessionManager.markIdentityChecked();
    return ok;
  }
}
