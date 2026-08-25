import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _periods = ['Ce mois', 'Ce trimestre', 'Cette année'];
  String _period = 'Ce mois';
  bool _exporting = false;

  static const _reports = [
    _Report(
      Icons.bar_chart_outlined,
      'Activité globale',
      'Connexions, quiz et téléchargements par période',
      WinColors.blue500,
      [
        _Stat('1 823', 'Élèves actifs'),
        _Stat('4 210', 'Quiz complétés'),
        _Stat('9 640', 'Téléchargements'),
      ],
    ),
    _Report(
      Icons.groups_outlined,
      'Performances par groupe',
      'Score moyen et progression par classe',
      WinColors.teal500,
      [
        _Stat('78%', 'TLE C 2026'),
        _Stat('52%', 'TLE D 2026'),
        _Stat('74%', '3ème A'),
      ],
    ),
    _Report(
      Icons.warning_amber_outlined,
      'Élèves à risque',
      'Identification des élèves nécessitant un suivi',
      WinColors.warn,
      [
        _Stat('4', 'Élèves à risque'),
        _Stat('2', 'Alertes critiques'),
        _Stat('12j', 'Délai moyen'),
      ],
    ),
    _Report(
      Icons.receipt_long_outlined,
      'Suivi des licences',
      'Utilisation et renouvellement des abonnements',
      WinColors.gold,
      [
        _Stat('1 823', 'Licences actives'),
        _Stat('627', 'Disponibles'),
        _Stat('74%', 'Taux d\'usage'),
      ],
    ),
  ];

  void _exportPdf(String title) async {
    setState(() => _exporting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _exporting = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapport prêt'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 52, color: WinColors.error),
          const SizedBox(height: 12),
          Text('$title — $_period', textAlign: TextAlign.center,
              style: WinType.bodyM(WinTheme.of(ctx).onStrong).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Le rapport PDF a été généré et sera envoyé par email sous 2 minutes.',
              textAlign: TextAlign.center,
              style: WinType.bodyS(WinTheme.of(ctx).onMuted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Rapports', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _periods.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WinChip(p, active: _period == p,
                  onTap: () => setState(() => _period = p)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ReportCard(
              report: _reports[i],
              period: _period,
              exporting: _exporting,
              onExport: () => _exportPdf(_reports[i].title),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _Report report;
  final String period;
  final bool exporting;
  final VoidCallback onExport;

  const _ReportCard({
    required this.report,
    required this.period,
    required this.exporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: report.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(report.icon, size: 20, color: report.color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.title, style: WinType.titleM(s.onStrong)),
            Text(report.description, style: WinType.labelM(s.onMuted)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: report.stats.map((st) => Expanded(
          child: Column(children: [
            Text(st.value,
                style: WinType.archivo(size: 17, weight: FontWeight.w700, color: s.onStrong)),
            Text(st.label, style: WinType.labelS(s.onMuted), textAlign: TextAlign.center),
          ]),
        )).toList()),
        const SizedBox(height: 14),
        WinButton(
          'Exporter PDF',
          block: true,
          variant: WinButtonVariant.outline,
          icon: Icons.picture_as_pdf_outlined,
          loading: exporting,
          onTap: onExport,
        ),
      ]),
    );
  }
}

class _Report {
  final IconData icon;
  final String title, description;
  final Color color;
  final List<_Stat> stats;
  const _Report(this.icon, this.title, this.description, this.color, this.stats);
}

class _Stat {
  final String value, label;
  const _Stat(this.value, this.label);
}
