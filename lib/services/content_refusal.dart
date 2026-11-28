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

/// Refus motivé du serveur (403, 409 ou 400 avec { code, message } en
/// français) : lien requis pour ajouter un élève (lien_requis), accès à une
/// épreuve payante (exam_access_required), répétiteur qui ne peut pas écrire
/// le premier, enfant non lié… Le message s'affiche tel quel à la place
/// d'une erreur générique. Couvre aussi [ContentRefused].
class ServerRefusal implements Exception {
  final String? code;
  final String message;
  const ServerRefusal(this.message, [this.code]);

  static ServerRefusal? of(Object e) {
    if (e is ServerRefusal) return e;
    if (e is ContentRefused) return ServerRefusal(e.message, e.code);
    if (e is! DioException) return null;
    final status = e.response?.statusCode;
    if (status != 403 && status != 409 && status != 400) return null;
    final d = e.response?.data;
    if (d is! Map) return null;
    final msg = d['message']?.toString().trim() ?? '';
    if (msg.isEmpty || d['code'] == null) return null;
    return ServerRefusal(msg, d['code']?.toString());
  }

  @override
  String toString() => message;
}
