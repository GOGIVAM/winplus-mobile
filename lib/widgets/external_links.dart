import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouverture d'une page du site dans le navigateur du téléphone, et partage
/// d'un lien par les applications installées (WhatsApp, e-mail, copie...).
class ExternalLinks {
  ExternalLinks._();

  /// Ouvre [url] dans le navigateur. `false` si aucune application ne peut
  /// l'ouvrir : l'appelant affiche alors un message ou propose de copier.
  static Future<bool> open(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Partage [url] par la feuille de partage du système. [subject] sert de
  /// titre (e-mail, par exemple).
  static Future<void> share(String url, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(uri: Uri.parse(url), subject: subject));
    } catch (_) {
      // Rien à faire : la feuille de partage est un plus.
    }
  }
}
