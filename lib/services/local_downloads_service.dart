import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';

/// Vrai téléchargement de fichier (Brique 2). Le fichier binaire est écrit
/// dans le répertoire privé de l'app (getApplicationDocumentsDirectory,
/// jamais accessible aux autres apps ni exposé via un intent "ouvrir avec"
/// ou un partage), et son chemin local est indexé par content_id dans une
/// box Hive dédiée aux téléchargements réels  distincte des 4 box de cache
/// de réponses API, puisqu'elle indexe des fichiers, pas des réponses JSON.
class LocalDownloadsService {
  LocalDownloadsService._();
  static final LocalDownloadsService instance = LocalDownloadsService._();

  static const _boxName = 'DownloadedFilesBox';
  Box? _box;

  Future<Box> _openBox() async => _box ??= await Hive.openBox(_boxName);

  /// Chemin local déjà téléchargé pour ce contenu, ou null.
  Future<String?> localPathFor(String contentId) async {
    final box = await _openBox();
    final path = box.get(contentId) as String?;
    if (path == null) return null;
    // Le fichier a pu être supprimé par l'OS (pression mémoire) sans que
    // l'entrée Hive soit nettoyée  vérifier son existence réelle plutôt
    // que de faire confiance à l'index seul.
    if (!await File(path).exists()) {
      await box.delete(contentId);
      return null;
    }
    return path;
  }

  /// Télécharge réellement [url] et l'enregistre sous content_id=[contentId].
  /// [suggestedFileName] sert à déduire une extension lisible (sinon dérivée
  /// de l'URL). Retourne le chemin local écrit.
  Future<String> download({
    required String contentId,
    required String url,
    String? suggestedFileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    // L'URL est la source fiable de la vraie extension du fichier (nom de
    // titre libre côté catalogue, presque jamais suffixé) ; le nom suggéré
    // n'est qu'un repli si l'URL ne donne rien d'exploitable.
    final ext = _extensionFrom(url) ??
        _extensionFrom(suggestedFileName ?? '') ??
        '.pdf';
    final localPath = '${downloadsDir.path}/$contentId$ext';

    await ApiClient.instance.dio.download(url, localPath);

    final box = await _openBox();
    await box.put(contentId, localPath);
    return localPath;
  }

  String? _extensionFrom(String source) {
    final clean = source.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot == -1 || dot == clean.length - 1) return null;
    final ext = clean.substring(dot);
    // Extension trop longue = probablement pas une vraie extension (URL sans point final utile).
    return ext.length <= 6 ? ext : null;
  }
}
