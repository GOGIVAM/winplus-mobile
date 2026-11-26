import 'package:dio/dio.dart';

/// Message refusé par le filtre des messageries du serveur (numéros de
/// téléphone, e-mails, liens de réseaux sociaux ; gros mots et insultes) :
/// 400 { code, message } avant tout enregistrement. Le message du serveur
/// s'affiche tel quel, le texte reste dans le champ pour être corrigé, et
/// rien ne part en file d'envoi (le renvoyer ne changerait rien).
class ContentRefused implements Exception {
  /// « coordonnees_interdites » ou « langage_inapproprie ».
  final String code;
  final String message;
  const ContentRefused(this.code, this.message);

  static const codes = {'coordonnees_interdites', 'langage_inapproprie'};

  /// Refus du filtre porté par [e], ou null pour toute autre erreur.
  static ContentRefused? of(Object e) {
    if (e is ContentRefused) return e;
    if (e is! DioException || e.response?.statusCode != 400) return null;
    final d = e.response?.data;
    if (d is! Map) return null;
    final code = d['code']?.toString();
    if (code == null || !codes.contains(code)) return null;
    final msg = (d['message'] ?? d['error'])?.toString() ?? '';
    return ContentRefused(code, msg);
  }

  @override
  String toString() => message;
}
