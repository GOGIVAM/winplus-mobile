import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copies locales chiffrées (lot 8, relecture de sécurité) : lectures
/// gardées pour le hors ligne, tableaux de bord, file des envois en attente
/// et index des formations téléchargées sont écrits chiffrés (AES-256) sur
/// le téléphone. La clé est tirée au hasard au premier lancement et rangée
/// dans le trousseau du téléphone, comme les jetons de session ; elle n'est
/// jamais sauvegardée (règles de sauvegarde Android).
///
/// Une boîte écrite en clair par une version précédente est recopiée une
/// fois dans sa version chiffrée, puis le fichier en clair est supprimé :
/// rien n'est perdu (la file des envois en attente notamment).
class SecureHive {
  SecureHive._();

  static const _keyName = 'winplus_hive_key';

  /// Boîtes déjà passées au chiffrement (préférence).
  static const migratedPrefKey = 'hive_encrypted_boxes';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<HiveAesCipher?>? _cipher;

  /// Tests : oublie la clé gardée en mémoire.
  @visibleForTesting
  static void resetForTest() => _cipher = null;

  static Future<HiveAesCipher?> _loadCipher() => _cipher ??= () async {
        try {
          var stored = await _secure.read(key: _keyName);
          if (stored == null || base64Decode(stored).length != 32) {
            stored = base64Encode(Hive.generateSecureKey());
            await _secure.write(key: _keyName, value: stored);
          }
          return HiveAesCipher(base64Decode(stored));
        } catch (e) {
          // Trousseau indisponible : la boîte s'ouvre sans chiffrement
          // plutôt que de priver l'application de ses copies locales.
          debugPrint('SecureHive : trousseau indisponible ($e)');
          return null;
        }
      }();

  /// Ouvre la boîte [name], chiffrée. Une boîte déjà ouverte (tests, en
  /// mémoire) est rendue telle quelle.
  static Future<Box> open(String name) {
    // Une ouverture à la fois : la liste des boîtes migrées est relue puis
    // réécrite, deux ouvertures simultanées perdraient une inscription.
    final next = _queue.then((_) => _open(name));
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  static Future<void> _queue = Future.value();

  static Future<Box> _open(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    final cipher = await _loadCipher();
    if (cipher == null) return Hive.openBox(name);
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getStringList(migratedPrefKey) ?? const <String>[];
    if (!migrated.contains(name)) {
      Map<dynamic, dynamic>? old;
      if (await Hive.boxExists(name)) {
        try {
          final plain = await Hive.openBox(name);
          old = plain.toMap();
          await plain.deleteFromDisk();
        } catch (e) {
          // Boîte en clair illisible : elle repart vide.
          debugPrint('SecureHive : $name illisible, recreee ($e)');
          await Hive.deleteBoxFromDisk(name);
        }
      }
      final box = await Hive.openBox(name, encryptionCipher: cipher);
      if (old != null && old.isNotEmpty) await box.putAll(old);
      await prefs.setStringList(migratedPrefKey, [...migrated, name]);
      return box;
    }
    return Hive.openBox(name, encryptionCipher: cipher);
  }
}
