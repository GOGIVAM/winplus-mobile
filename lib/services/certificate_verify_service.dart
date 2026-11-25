import 'package:dio/dio.dart';

import 'api_client.dart';

/// Résultat de la vérification d'un certificat par son code.
class CertificateCheck {
  final bool valid;
  final String? studentName;

  /// Matière, épreuve ou formation certifiée.
  final String? title;
  final num? grade;
  final DateTime? issuedAt;
  final String? number;

  const CertificateCheck({
    required this.valid,
    this.studentName,
    this.title,
    this.grade,
    this.issuedAt,
    this.number,
  });

  static const invalid = CertificateCheck(valid: false);
}

/// Vérification publique d'un certificat (lot 7), comme les pages
/// /verify/{code} et /verify-formation/{code} du site : un seul champ pour
/// les deux familles de certificats.
class CertificateVerifyService {
  CertificateVerifyService._();
  static final CertificateVerifyService instance = CertificateVerifyService._();
  final _api = ApiClient.instance;

  static Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      return d is Map<String, dynamic> ? d : body;
    }
    return const {};
  }

  /// Certificats d'épreuve (GET /certificates/verify/{code}), puis, si le
  /// code n'y est pas, certificats de formation (GET /certificats/{code}).
  /// Lève une erreur seulement si le serveur ne répond pas.
  Future<CertificateCheck> verify(String code) async {
    final c = Uri.encodeComponent(code.trim());
    try {
      final d = _data((await _api.dio.get('/certificates/verify/$c')).data);
      if (d['isValid'] == true) {
        return CertificateCheck(
          valid: true,
          studentName: d['studentName']?.toString(),
          title: d['courseName']?.toString(),
          grade: d['grade'] as num?,
          issuedAt: DateTime.tryParse(d['issuedAt']?.toString() ?? '')?.toLocal(),
          number: d['certificateNumber']?.toString(),
        );
      }
    } on DioException catch (e) {
      if (!_unknownCode(e)) rethrow;
    }
    try {
      final d = _data((await _api.dio.get('/certificats/$c')).data);
      if (d['isValid'] == true) {
        return CertificateCheck(
          valid: true,
          studentName: d['studentName']?.toString(),
          title: d['courseTitle']?.toString(),
          grade: d['grade'] as num?,
          issuedAt: DateTime.tryParse(d['issuedAt']?.toString() ?? '')?.toLocal(),
        );
      }
    } on DioException catch (e) {
      if (!_unknownCode(e)) rethrow;
    }
    return CertificateCheck.invalid;
  }

  /// Code inconnu ou refusé (404, 400) : « non trouvé », pas une panne.
  static bool _unknownCode(DioException e) {
    final code = e.response?.statusCode;
    return code == 404 || code == 400;
  }
}
