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

  factory ApiCertificate.fromJson(Map<String, dynamic> j) => ApiCertificate(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        subjectName: j['subjectName'] as String? ?? '',
        issuedAt: j['issuedAt'] as String? ?? '',
        pdfUrl: j['pdfUrl'] as String?,
        score: j['score'] as int?,
      );
}

class CertificateService {
  CertificateService._();
  static final CertificateService instance = CertificateService._();

  final _api = ApiClient.instance;

  Future<List<ApiCertificate>> getCertificates() async {
    final res = await _api.dio.get('/certificates');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw as Map<String, dynamic>?)?['items'] as List? ?? [];
    return list
        .map((e) => ApiCertificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
