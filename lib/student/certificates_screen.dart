import 'package:flutter/material.dart';
import '../services/certificate_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await CertificateService.instance.getCertificates();
      if (mounted) setState(() { _certs = data; _error = null; });
    } catch (_) {
      if (mounted) setState(() { _certs = []; _error = 'Impossible de charger les certificats.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final certs = _certs;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Certificats', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() => _certs = null); _load(); },
          ),
        ],
      ),
      body: certs == null
          ? const Center(child: CircularProgressIndicator())
          : certs.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium_outlined, size: 64, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Aucun certificat pour l\'instant',
                    style: WinType.bodyM(s.onMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_error == null)
                    Text(
                      'Complétez des quiz et des parcours pour\ndécrocher vos premiers certificats.',
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Gold header band
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          color: WinColors.goldBg,
                          child: Row(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: const BoxDecoration(
                                color: WinColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.workspace_premium,
                                  size: 30, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cert.title,
                                  style: WinType.headlineS(WinColors.ink800),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Délivré le ${cert.issuedAt}',
                                  style: WinType.labelM(WinColors.ink500)),
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
                                Text(isHigh ? 'Mention Très Bien' : 'Mention Bien',
                                    style: WinType.labelM(
                                        isHigh ? WinColors.success : WinColors.warn)),
                              ]),
                              const SizedBox(height: 14),
                            ],
                            Row(children: [
                              Expanded(
                                child: WinButton('Télécharger PDF',
                                    variant: WinButtonVariant.outline,
                                    small: true,
                                    icon: Icons.download_outlined,
                                    onTap: cert.pdfUrl != null ? () {} : null),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: WinButton('Partager',
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
