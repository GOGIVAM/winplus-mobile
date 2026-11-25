import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// Refus d'un message de contact.
class SupportContactException implements Exception {
  /// Erreurs par champ (name, email, subject, message…), si le serveur les
  /// donne (400).
  final Map<String, String> fieldErrors;

  /// Trop d'envois depuis cette connexion (429).
  final bool tooMany;

  /// La route n'existe pas encore sur ce serveur (404) : proposer l'e-mail.
  final bool unavailable;

  const SupportContactException({
    this.fieldErrors = const {},
    this.tooMany = false,
    this.unavailable = false,
  });
}

/// Message au support (POST /support/contact), gardé par le serveur et
/// envoyé par e-mail à l'équipe ; rattaché au compte si on est connecté.
class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();
  final _api = ApiClient.instance;

  Future<void> contact({
    required String name,
    required String email,
    String? phone,
    required String subject,
    required String message,
  }) async {
    try {
      await _api.dio.post('/support/contact', data: {
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'subject': subject,
        'message': message,
        'source': 'mobile',
        'locale': L10n.code,
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) throw const SupportContactException(tooMany: true);
      if (status == 404) throw const SupportContactException(unavailable: true);
      if (status == 400) {
        final data = e.response?.data;
        final errors = <String, String>{};
        final raw = data is Map ? data['errors'] : null;
        if (raw is Map) {
          raw.forEach((k, v) {
            final msg = v is List && v.isNotEmpty ? '${v.first}' : '$v';
            // Clés .NET en PascalCase (Name, Email…) : ramenées au nom du champ.
            final key = '$k'.isEmpty ? '$k' : '$k'[0].toLowerCase() + '$k'.substring(1);
            errors[key] = msg;
          });
        }
        throw SupportContactException(fieldErrors: errors);
      }
      rethrow;
    }
  }
}
