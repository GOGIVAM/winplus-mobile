import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'session_manager.dart';

/// Module 27 (lot 8) : téléchargement hors-ligne chiffré des LEÇONS DE
/// FORMATION (Course) uniquement.
///
/// Frontière produit stricte (rappelée dans PROMPTS_IMPLEMENTATION...md et
/// dans local_downloads_service.dart) : ce service ne concerne JAMAIS les
/// épreuves/corrigés/livres (Subject/CourseContent), qui ne sont plus
/// téléchargeables pour personne depuis le Module 44 et se consultent
/// uniquement dans la visionneuse intégrée. Nom de fichier volontairement
/// distinct de local_downloads_service.dart pour ne jamais confondre les
/// deux périmètres.
///
/// Chiffrement et liaison au compte :
///  - une clé AES-256 aléatoire est générée une fois par compte et stockée
///    dans le trousseau sécurisé de l'appareil (flutter_secure_storage), sous
///    une entrée nommée par l'id utilisateur ;
///  - chaque leçon téléchargée est chiffrée (AES-CBC, IV aléatoire par
///    fichier) avant d'être écrite sur le disque ; jamais en clair ;
///  - [wipeForLogout] supprime la clé ET les fichiers chiffrés à la
///    déconnexion : un fichier chiffré sans sa clé est définitivement
///    illisible, et il n'est de toute façon pas question qu'un autre compte
///    connecté sur le même appareil retrouve les téléchargements du
///    précédent.
class CourseOfflineService {
  CourseOfflineService._();
  static final CourseOfflineService instance = CourseOfflineService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _metaBoxName = 'CourseOfflineBox';

  Box? _metaBox;

  Future<Box> _box() async {
    if (_metaBox != null && _metaBox!.isOpen) return _metaBox!;
    _metaBox = await Hive.openBox(_metaBoxName);
    return _metaBox!;
  }

  Future<Directory> _offlineDir(int userId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/course_offline/$userId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<enc.Key> _keyFor(int userId) async {
    final storageKey = 'course_offline_key_$userId';
    final existing = await _secureStorage.read(key: storageKey);
    if (existing != null) {
      return enc.Key.fromBase64(existing);
    }
    final generated = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(key: storageKey, value: generated.base64);
    return generated;
  }

  String _entryId(int courseId, int lessonId) => '${courseId}_$lessonId';

  /// Télécharge, chiffre et enregistre une leçon de formation.
  /// [videoUrl] doit être l'URL présignée à durée limitée renvoyée par
  /// CoursePlayerController.GetLesson (jamais une URL S3 permanente).
  Future<void> downloadLesson({
    required int courseId,
    required int lessonId,
    required String title,
    required String videoUrl,
    void Function(double progress)? onProgress,
  }) async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      throw StateError('Téléchargement hors-ligne impossible : aucun compte connecté.');
    }

    final response = await Dio().get<List<int>>(
      videoUrl,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (onProgress != null && total > 0) {
          onProgress(received / total);
        }
      },
    );
    final bytes = Uint8List.fromList(response.data ?? const []);

    final key = await _keyFor(userId);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final dir = await _offlineDir(userId);
    final file = File('${dir.path}/${_entryId(courseId, lessonId)}.enc');
    // IV (16 octets) préfixé au fichier : nécessaire au déchiffrement, pas
    // secret en soi (seule la clé, elle, ne quitte jamais le trousseau).
    await file.writeAsBytes([...iv.bytes, ...encrypted.bytes]);

    final box = await _box();
    await box.put(_entryId(courseId, lessonId), {
      'courseId': courseId,
      'lessonId': lessonId,
      'title': title,
      'sizeBytes': bytes.length,
      'downloadedAt': DateTime.now().toIso8601String(),
      'path': file.path,
    });
  }

  Future<bool> isDownloaded(int courseId, int lessonId) async {
    final box = await _box();
    return box.containsKey(_entryId(courseId, lessonId));
  }

  /// Déchiffre la leçon dans un fichier temporaire (cache de l'app) et
  /// renvoie son chemin, prêt à être ouvert par un lecteur vidéo local.
  /// Le fichier temporaire est écrasé à chaque appel : jamais conservé en
  /// clair plus longtemps que la lecture en cours.
  Future<String> decryptForPlayback(int courseId, int lessonId) async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      throw StateError('Lecture hors-ligne impossible : aucun compte connecté.');
    }
    final box = await _box();
    final entry = box.get(_entryId(courseId, lessonId)) as Map?;
    if (entry == null) {
      throw StateError('Cette leçon n\'a pas été téléchargée.');
    }
    final file = File(entry['path'] as String);
    if (!await file.exists()) {
      await box.delete(_entryId(courseId, lessonId));
      throw StateError('Fichier hors-ligne introuvable (a-t-il été effacé par le système ?).');
    }

    final raw = await file.readAsBytes();
    final iv = enc.IV(raw.sublist(0, 16));
    final cipherBytes = raw.sublist(16);
    final key = await _keyFor(userId);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

    final cacheDir = await getTemporaryDirectory();
    final tmp = File('${cacheDir.path}/course_offline_playback.mp4');
    await tmp.writeAsBytes(plain, flush: true);
    return tmp.path;
  }

  Future<void> deleteLesson(int courseId, int lessonId) async {
    final box = await _box();
    final entry = box.get(_entryId(courseId, lessonId)) as Map?;
    if (entry != null) {
      final file = File(entry['path'] as String);
      if (await file.exists()) await file.delete();
      await box.delete(_entryId(courseId, lessonId));
    }
  }

  Future<List<Map<String, dynamic>>> listDownloads() async {
    final box = await _box();
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Appelé à la déconnexion (AuthService.signOut) : purge la clé de
  /// chiffrement ET les fichiers du compte courant. Un compte différent qui
  /// se connecte ensuite sur le même appareil ne doit jamais pouvoir
  /// retrouver ou déchiffrer les téléchargements du précédent.
  Future<void> wipeForLogout() async {
    try {
      final userId = await SessionManager.getUserId();
      if (userId != null) {
        await _secureStorage.delete(key: 'course_offline_key_$userId');
        final dir = await _offlineDir(userId);
        if (await dir.exists()) await dir.delete(recursive: true);
        final box = await _box();
        final keysToRemove = box.keys.where((k) {
          final entry = box.get(k) as Map?;
          return entry != null && entry['path'] is String &&
              (entry['path'] as String).contains('/course_offline/$userId/');
        }).toList();
        for (final k in keysToRemove) {
          await box.delete(k);
        }
      }
    } catch (_) {
      // Ne doit jamais empêcher la déconnexion elle-même.
    }
  }
}
