import 'api_client.dart';

class ApiCertificate {
  final int id;
  final String title;
  final String subjectName;
  final String issuedAt;
  final String? pdfUrl;
  final int? score;
  const ApiCertificate({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.issuedAt,
    this.pdfUrl,
    this.score,
  });

  /// Module 25 : lit les champs réellement renvoyés par CertificateDto
  /// (subjectTitle, fileUrl, grade), en gardant les anciens noms en repli.
  factory ApiCertificate.fromJson(Map<String, dynamic> j) => ApiCertificate(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['subjectTitle'] ?? j['title'])?.toString() ?? '',
        subjectName: (j['subjectTitle'] ?? j['subjectName'])?.toString() ?? '',
        issuedAt: j['issuedAt']?.toString() ?? '',
        pdfUrl: (j['fileUrl'] ?? j['pdfUrl']) as String?,
        score: ((j['grade'] ?? j['score']) as num?)?.round(),
      );
}

class CertificateService {
  CertificateService._();
  static final CertificateService instance = CertificateService._();

  final _api = ApiClient.instance;

  /// Module 25 : `GET /certificates` n'existe pas (la racine n'accepte que
  /// POST, émission). Les certificats de l'utilisateur connecté sont servis
  /// par GET /certificates/user/my-certificates, enveloppés dans { success, data }.
  Future<List<ApiCertificate>> getCertificates() async {
    final res = await _api.dio.get('/certificates/user/my-certificates');
    final raw = res.data;
    final map = raw is Map<String, dynamic> ? raw : null;
    final list = raw is List
        ? raw
        : (map?['data'] ?? map?['items']) as List? ?? [];
    return list
        .map((e) => ApiCertificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
