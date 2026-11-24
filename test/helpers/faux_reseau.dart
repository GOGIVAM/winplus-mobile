import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/api_client.dart';
import 'package:winplus/services/biometric_service.dart';
import 'package:winplus/services/http_cache.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/services/tutor_booking_service.dart';

/// Corps brut, envoyé tel quel (flux d'évènements « data: … » par exemple).
class FauxTexte {
  final String texte;
  const FauxTexte(this.texte);
}

/// Réponse simulée du serveur.
class FauxReponse {
  final Object? corps;
  final int statut;
  const FauxReponse(this.corps, [this.statut = 200]);
}

/// Adaptateur HTTP de Dio qui ne sort jamais sur le réseau : chaque requête
/// est enregistrée puis servie par la route déclarée avec [sur] ou [repond].
/// Une route non déclarée répond 404 avec { error: 'route non simulee' }.
class FauxReseau implements HttpClientAdapter {
  final List<RequestOptions> requetes = [];
  final Map<String, FauxReponse Function(RequestOptions)> _routes = {};

  /// Déclare la réponse (calculée) d'une route « METHODE /chemin ».
  void sur(String methode, String chemin, FauxReponse Function(RequestOptions) h) {
    _routes['${methode.toUpperCase()} $chemin'] = h;
  }

  /// Déclare une réponse fixe : [corps] est encodé en JSON.
  void repond(String methode, String chemin, Object? corps, {int statut = 200}) {
    sur(methode, chemin, (_) => FauxReponse(corps, statut));
  }

  /// Simule l'absence de réseau (aucune réponse du serveur).
  void coupure(String methode, String chemin) {
    sur(methode, chemin, (o) => throw DioException.connectionError(requestOptions: o, reason: 'hors ligne simule'));
  }

  /// Requêtes reçues pour « METHODE /chemin ».
  List<RequestOptions> recues(String methode, String chemin) =>
      requetes.where((r) => r.method == methode.toUpperCase() && r.path == chemin).toList();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requetes.add(options);
    final h = _routes['${options.method} ${options.path}'];
    final r = h == null ? const FauxReponse({'error': 'route non simulee'}, 404) : h(options);
    final corps = r.corps;
    final texte = corps == null
        ? ''
        : corps is FauxTexte
            ? corps.texte
            : jsonEncode(corps);
    return ResponseBody.fromString(
      texte,
      r.statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

bool _estErreurDePolice(Object erreur) {
  final t = erreur.toString();
  return t.contains('allowRuntimeFetching') || t.contains('Failed to load font') || t.contains('google_fonts');
}

/// Exécute [corps] dans une zone fille de la zone courante (donc avec le même
/// temps simulé de flutter_test). Le paquet google_fonts charge ses polices en
/// tâche de fond et, sans réseau ni police embarquée (cas des tests), relance
/// son erreur sans que personne ne l'attende : flutter_test ferait alors
/// échouer le test. Cette zone ignore UNIQUEMENT ces erreurs de police ; toute
/// autre erreur est transmise telle quelle à flutter_test.
R sansErreurDePolice<R>(R Function() corps) {
  final zone = Zone.current.fork(
    specification: ZoneSpecification(
      handleUncaughtError: (self, parent, zone, erreur, pile) {
        if (_estErreurDePolice(erreur)) return;
        parent.handleUncaughtError(zone, erreur, pile);
      },
    ),
  );
  return zone.run(corps);
}

/// Monte [widget] (sous un MaterialApp déjà fourni par l'appelant) sans que
/// les erreurs de chargement de police ne fassent échouer le test.
Future<void> monter(WidgetTester tester, Widget widget) =>
    sansErreurDePolice(() => tester.pumpWidget(widget));

/// Équivalent de tester.pump, dans la zone qui ignore les erreurs de police.
Future<void> pomper(WidgetTester tester, [Duration? duree]) =>
    sansErreurDePolice(() => tester.pump(duree));

/// Prépare l'environnement commun : liaison de test, préférences vides (ou
/// [prefs]), langue française, aucune récupération de polices sur Internet,
/// et un faux réseau branché sur le client Dio unique de l'application.
/// Renvoie le faux réseau (aucune requête réelle).
FauxReseau preparerEnvironnement({Map<String, Object> prefs = const {}}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(prefs));
  // Jetons de session : trousseau simulé vide, et copie en mémoire oubliée.
  // Un jeton placé dans [prefs] est repris au premier accès, comme une
  // session ouverte par une version précédente de l'application.
  FlutterSecureStorage.setMockInitialValues({});
  SessionManager.resetForTest();
  ApiClient.instance.onSessionExpired = null;
  // Politique de tutorat gardée en mémoire par le service : une réponse
  // attendue par le test précédent ne viendra jamais.
  TutorBookingService.instance.resetPolicyForTest();
  // Lectures gardées pour le hors ligne : en mémoire et vides à chaque test
  // (une écriture Hive sur disque bloquerait le temps simulé).
  HttpCache.instance.useMemoryStore();
  // Empreinte : comportement réel (aucune sous Windows) sauf si le test le
  // simule.
  BiometricService.instance.debugAvailable = null;
  BiometricService.instance.debugAuthenticate = null;
  L10n.locale = const Locale('fr');
  final faux = FauxReseau();
  ApiClient.instance.dio.httpClientAdapter = faux;
  return faux;
}

/// Données de dates françaises et anglaises, nécessaires à WinFormat.
Future<void> initialiserDates() async {
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
}

/// Laisse s'exécuter les tâches asynchrones lancées sans attente (unawaited).
Future<void> laisserFinir() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Dossier temporaire Hive : à appeler dans setUpAll, avec [fermerHive] en tearDownAll.
Directory ouvrirDossierHive() {
  final dossier = Directory.systemTemp.createTempSync('winplus_hive_test_');
  Hive.init(dossier.path);
  return dossier;
}

Future<void> fermerHive(Directory dossier) async {
  await Hive.close();
  if (dossier.existsSync()) dossier.deleteSync(recursive: true);
}
