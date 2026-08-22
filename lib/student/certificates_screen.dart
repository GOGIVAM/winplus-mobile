import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final certs = WinData.certificates;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Certificats', style: WinType.headlineS(s.onStrong)),
      ),
      body: certs.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 64, color: s.onFaint),
              const SizedBox(height: 12),
              Text('Aucun certificat pour l\'instant',
                  style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 8),
              Text('Complétez des quiz et des parcours pour\ndécrocher vos premiers certificats.',
                  style: WinType.bodyS(s.onFaint),
                  textAlign: TextAlign.center),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: certs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final cert = certs[i];
                final isHigh = cert.score >= 80;
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
                        Row(children: [
                          WinBadge('${cert.score}%',
                              color: isHigh
                                  ? BadgeColor.success
                                  : BadgeColor.warn),
                          const SizedBox(width: 8),
                          Text(isHigh ? 'Mention Très Bien' : 'Mention Bien',
                              style: WinType.labelM(
                                  isHigh ? WinColors.success : WinColors.warn)),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: WinButton('Télécharger PDF',
                                variant: WinButtonVariant.outline,
                                small: true,
                                icon: Icons.download_outlined,
                                onTap: () {}),
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
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(cert.verifyUrl))),
                          child: Row(children: [
                            Icon(Icons.verified_outlined,
                                size: 14, color: s.primary),
                            const SizedBox(width: 6),
                            Text('Vérifier en ligne',
                                style: WinType.labelM(s.primary)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
