import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Ancien stockage des fichiers du catalogue téléchargés sur l'appareil
/// (épreuves, corrigés, livres), écrits en clair dans le répertoire privé de
/// l'app et indexés par content_id dans une box Hive dédiée.
///
/// Module 44 (décisions §11.1 à §11.4) : ces contenus ne sont plus jamais
/// téléchargeables, pour personne  ils se consultent uniquement dans la
/// visionneuse intégrée (DocumentViewerScreen), en mémoire, avec un
/// filigrane nominatif. Ce service ne sert donc plus qu'à effacer les copies
/// laissées par les versions précédentes de l'app.
///
/// Il ne concerne pas le futur téléchargement hors-ligne chiffré des leçons
/// de formation (Module 27), qui aura son propre stockage.
class LocalDownloadsService {
  LocalDownloadsService._();
  static final LocalDownloadsService instance = LocalDownloadsService._();

  static const _boxName = 'DownloadedFilesBox';

  /// Supprime les fichiers du catalogue encore présents sur l'appareil et
  /// vide leur index. Sans effet s'il n'y a rien à effacer ; ne lève jamais
  /// (appelé au démarrage, ne doit pas bloquer l'app).
  Future<void> purgeLegacyCatalogFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
      }
    } catch (_) {
      // Répertoire inaccessible : nouvelle tentative au prochain démarrage.
    }

    try {
      if (await Hive.boxExists(_boxName)) {
        final box = await Hive.openBox(_boxName);
        await box.clear();
        await box.close();
      }
    } catch (_) {
      // Index illisible : sans fichier derrière, il n'ouvre plus rien.
    }
  }
}
