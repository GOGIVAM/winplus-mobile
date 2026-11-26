import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/services/secure_hive.dart';

import '../helpers/faux_reseau.dart';

/// Lot 8 (relecture de sécurité) : copies locales chiffrées sur le
/// téléphone ; une boîte en clair d'une version précédente est reprise sans
/// perte, puis son fichier en clair disparaît.
void main() {
  late Directory dossier;
  setUp(() {
    preparerEnvironnement();
    SecureHive.resetForTest();
    dossier = ouvrirDossierHive();
  });
  tearDown(() => fermerHive(dossier));

  bool fichierContient(String boite, String texte) {
    final f = File('${dossier.path}/${boite.toLowerCase()}.hive');
    return f.existsSync() && latin1.decode(f.readAsBytesSync()).contains(texte);
  }

  test('ecrite chiffree : le texte n\'apparait pas dans le fichier', () async {
    final box = await SecureHive.open('outbox');
    await box.put('a', {'note': 'moyenne-secrete-17'});
    await box.close();
    expect(fichierContient('outbox', 'moyenne-secrete-17'), isFalse);
    final relue = await SecureHive.open('outbox');
    expect(relue.get('a'), {'note': 'moyenne-secrete-17'});
  });

  test('boite en clair d\'une version precedente : reprise sans perte, puis chiffree', () async {
    final ancienne = await Hive.openBox('outbox');
    await ancienne.put('envoi-1', {'path': '/cart', 'body': 'panier-en-attente'});
    await ancienne.close();
    expect(fichierContient('outbox', 'panier-en-attente'), isTrue);

    final box = await SecureHive.open('outbox');
    expect(box.get('envoi-1'), {'path': '/cart', 'body': 'panier-en-attente'});
    await box.close();
    expect(fichierContient('outbox', 'panier-en-attente'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SecureHive.migratedPrefKey), contains('outbox'));
  });

  test('ouvertures simultanees : chaque boite est inscrite comme migree', () async {
    await Future.wait([for (final n in ['b1', 'b2', 'b3', 'b4']) SecureHive.open(n)]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SecureHive.migratedPrefKey), containsAll(['b1', 'b2', 'b3', 'b4']));
  });

  test('la cle reste la meme d\'un lancement a l\'autre', () async {
    final box = await SecureHive.open('outbox');
    await box.put('k', 'v');
    await box.close();
    SecureHive.resetForTest();
    expect((await SecureHive.open('outbox')).get('k'), 'v');
    expect(await const FlutterSecureStorage().read(key: 'winplus_hive_key'), isNotNull);
  });
}
