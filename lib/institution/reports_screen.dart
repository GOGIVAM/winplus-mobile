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
  static const _periods = ['7 jours', '30 jours', 'Trimestre', 'Année'];
  String _period = '30 jours';

  static const _reportTypes = [
    _ReportType(
      Icons.bar_chart_outlined,
      'Rapport de performance global',
      'Vue d\'ensemble de tous les élèves',
      WinColors.blue500,
    ),
    _ReportType(
      Icons.school_outlined,
      'Rapport par classe',
      'Comparaison des classes, taux de réussite',
      WinColors.teal500,
    ),
    _ReportType(
      Icons.person_search_outlined,
      'Rapport individuel élève',
      'Progression détaillée d\'un élève',
      WinColors.gold,
    ),
    _ReportType(
      Icons.trending_down_outlined,
      'Rapport élèves à risque',
      'Élèves nécessitant une intervention',
      WinColors.error,
    ),
  ];

  Future<void> _generateReport(BuildContext context, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Génération en cours...'),
        content: const Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Patientez...'),
        ]),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!context.mounted) return;
    Navigator.pop(context); // ferme le dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 22),
          SizedBox(width: 8),
          Text('Rapport généré !'),
        ]),
        content: Text('Votre rapport "$title" est prêt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Partager')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
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
        // Sélecteur de période
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
        const SizedBox(height: 16),
        // 4 cards de types de rapports
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _reportTypes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = _reportTypes[i];
              return _ReportTypeCard(
                report: r,
                period: _period,
                onGenerate: () => _generateReport(context, r.title),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final _ReportType report;
  final String period;
  final VoidCallback onGenerate;

  const _ReportTypeCard({
    required this.report,
    required this.period,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: report.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(report.icon, size: 22, color: report.color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.title, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 2),
            Text(report.description, style: WinType.labelM(s.onMuted)),
          ])),
        ]),
        const SizedBox(height: 14),
        WinButton(
          'Générer PDF',
          block: true,
          variant: WinButtonVariant.outline,
          icon: Icons.picture_as_pdf_outlined,
          onTap: onGenerate,
        ),
      ]),
    );
  }
}

class _ReportType {
  final IconData icon;
  final String title, description;
  final Color color;
  const _ReportType(this.icon, this.title, this.description, this.color);
}
