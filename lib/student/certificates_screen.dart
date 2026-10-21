import '../l10n/l10n.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/certificate_service.dart';
import '../services/course_service.dart';
import '../theme/win_motion.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});
  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<ApiCertificate>? _certs;
  String? _error;

  /// Lot 9.7b (F15) : certificats de FORMATION (GET /my-course-certificates),
  /// distincts des certificats de sujets lus jusqu'ici seuls.
  List<MyCourseCertificate> _courseCerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courseCerts = await CourseService.instance
          .myCourseCertificates()
          .catchError((_) => <MyCourseCertificate>[]);
      if (mounted) setState(() => _courseCerts = courseCerts);
    } catch (_) {}
    try {
      final data = await CertificateService.instance.getCertificates();
      if (mounted)
        setState(() {
          _certs = data;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _certs = [];
          _error = L10n.current.studentCertLoadError;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final certs = _certs;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.studentCertTitle, style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() => _certs = null);
              _load();
            },
          ),
        ],
      ),
      body: certs == null
          ? const Center(child: CircularProgressIndicator())
          : _courseCerts.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(context.l10n.studentCertCourses, style: WinType.titleM(s.onStrong)),
                    const SizedBox(height: 10),
                    ..._courseCerts.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CourseCertificateCard(cert: c),
                        )),
                    if (certs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(context.l10n.studentCertPapersAndPaths,
                          style: WinType.titleM(s.onStrong)),
                      const SizedBox(height: 10),
                      ...certs.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: WinCard(
                              child: Row(children: [
                                const Icon(Icons.workspace_premium,
                                    color: WinColors.gold),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(c.title,
                                        style: WinType.bodyM(s.onStrong))),
                                if ((c.score ?? 0) > 0)
                                  WinBadge('${c.score}%'),
                              ]),
                            ),
                          )),
                    ],
                  ],
                )
          : certs.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium_outlined,
                      size: 64, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? context.l10n.studentCertEmpty,
                    style: WinType.bodyM(s.onMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_error == null)
                    Text(
                      context.l10n.studentCertEmptyHint,
                      style: WinType.bodyS(s.onFaint),
                      textAlign: TextAlign.center,
                    ),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: certs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final cert = certs[i];
                    final score = cert.score ?? 0;
                    final isHigh = score >= 80;
                    return WinCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gold header band
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              color: WinColors.goldBg,
                              child: Row(children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: WinColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.workspace_premium,
                                      size: 30, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(cert.title,
                                          style: WinType.headlineS(
                                              WinColors.ink800),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(context.l10n.studentCertIssuedOn(cert.issuedAt),
                                          style:
                                              WinType.labelM(WinColors.ink500)),
                                    ])),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (score > 0) ...[
                                      Row(children: [
                                        WinBadge('$score%',
                                            color: isHigh
                                                ? BadgeColor.success
                                                : BadgeColor.warn),
                                        const SizedBox(width: 8),
                                        Text(
                                            isHigh
                                                ? context.l10n.studentCertMentionVeryGood
                                                : context.l10n.studentCertMentionGood,
                                            style: WinType.labelM(isHigh
                                                ? WinColors.success
                                                : WinColors.warn)),
                                      ]),
                                      const SizedBox(height: 14),
                                    ],
                                    Row(children: [
                                      Expanded(
                                        child: WinButton(context.l10n.studentCertDownloadPdf,
                                            variant: WinButtonVariant.outline,
                                            small: true,
                                            icon: Icons.download_outlined,
                                            onTap: cert.pdfUrl != null
                                                ? () {}
                                                : null),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: WinButton(context.l10n.studentCertShare,
                                            variant: WinButtonVariant.ghost,
                                            small: true,
                                            icon: Icons.share_outlined,
                                            onTap: () {}),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Icon(Icons.verified_outlined,
                                          size: 14, color: s.primary),
                                      const SizedBox(width: 6),
                                      Text(cert.subjectName,
                                          style: WinType.labelM(s.onMuted)),
                                    ]),
                                  ]),
                            ),
                          ]),
                    );
                  },
                ),
    );
  }
}

/// Lot 9.7b (F15) : certificat de formation. Le PDF du certificat reste
/// consultable et téléchargeable (18.21 : seules les épreuves et les livres
/// ne sortent jamais de l'application) ; il s'affiche ici depuis le lien
/// présigné renvoyé par le serveur. Le code de vérification publique est
/// affiché (page /verify-formation/{code}).
class _CourseCertificateCard extends StatelessWidget {
  final MyCourseCertificate cert;
  const _CourseCertificateCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final issued = cert.issuedAt;
    final date = issued == null
        ? ''
        : WinFormat.dateNumeric(issued);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium, color: WinColors.gold, size: 28),
          const SizedBox(width: 10),
          Expanded(
              child: Text(cert.courseTitle,
                  style: WinType.titleM(s.onStrong),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          if (cert.grade != null) WinBadge('${cert.grade!.round()} %'),
        ]),
        const SizedBox(height: 6),
        Text(
            [
              if (cert.instructorName != null) cert.instructorName!,
              if (date.isNotEmpty) context.l10n.studentCertIssuedOn(date),
            ].join(' · '),
            style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 4),
        SelectableText(context.l10n.studentCertVerificationCode(cert.verificationCode),
            style: WinType.labelS(s.onMuted)),
        const SizedBox(height: 10),
        WinButton(context.l10n.studentCertSeePdf,
            variant: WinButtonVariant.outline,
            small: true,
            icon: Icons.picture_as_pdf_outlined,
            onTap: cert.fileUrl == null
                ? null
                : () => Navigator.push(
                    context,
                    WinPageRoute(
                      builder: (_) => _CertificatePdfScreen(
                          title: cert.courseTitle, url: cert.fileUrl!),
                    ))),
      ]),
    );
  }
}

class _CertificatePdfScreen extends StatefulWidget {
  final String title;
  final String url;
  const _CertificatePdfScreen({required this.title, required this.url});
  @override
  State<_CertificatePdfScreen> createState() => _CertificatePdfScreenState();
}

class _CertificatePdfScreenState extends State<_CertificatePdfScreen> {
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Lien présigné S3 : requête sans en-tête d'authentification.
      final res = await Dio().get<List<int>>(widget.url,
          options: Options(responseType: ResponseType.bytes));
      if (!mounted) return;
      setState(() => _bytes = Uint8List.fromList(res.data ?? const []));
    } catch (_) {
      if (mounted) {
        setState(() => _error = L10n.current.studentCertPdfLoadError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        foregroundColor: s.onStrong,
        title: Text(widget.title, style: WinType.titleM(s.onStrong)),
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: WinType.bodyM(s.onMuted)))
          : _bytes == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewer.data(_bytes!,
                  sourceName:
                      'winplus-course-cert-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}',
                  params: PdfViewerParams(backgroundColor: s.bg)),
    );
  }
}