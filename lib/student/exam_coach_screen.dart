import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/subscription/upgrade_sheet.dart';
import '../app_config.dart';

class ExamCoachScreen extends StatefulWidget {
  const ExamCoachScreen({super.key});
  @override
  State<ExamCoachScreen> createState() => _ExamCoachScreenState();
}

class _ExamCoachScreenState extends State<ExamCoachScreen> {
  bool _planGenerated = false;
  final _examCtrl = TextEditingController(text: 'BAC C');
  final _dateCtrl = TextEditingController(text: '18 juin 2026');
  double _hoursPerDay = 2;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = WinData.currentSubscription;

    if (sub.isFree && !AppConfig.devMode) {
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(
          backgroundColor: s.bg, elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: s.onStrong),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                    color: WinColors.warnBg, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline, size: 40, color: WinColors.warn),
              ),
              const SizedBox(height: 20),
              Text('Exam Coach', style: WinType.displayS(s.onStrong),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Disponible à partir du plan Standard.\nWinAI génère un planning semaine par semaine adapté à tes lacunes.',
                  style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              WinButton('Voir les plans', block: true,
                  onTap: () => UpgradeSheet.show(context,
                      featureName: 'Exam Coach', requiredPlan: 'Standard')),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: s.onStrong),
            onPressed: () => Navigator.pop(context)),
        title: Text('Exam Coach', style: WinType.headlineS(s.onStrong)),
        actions: [
          if (_planGenerated)
            TextButton(
              onPressed: () => setState(() => _planGenerated = false),
              child: Text('Modifier', style: WinType.labelM(s.primary)),
            ),
        ],
      ),
      body: _planGenerated ? _PlanView() : _FormView(
        examCtrl: _examCtrl,
        dateCtrl: _dateCtrl,
        hoursPerDay: _hoursPerDay,
        onHoursChanged: (v) => setState(() => _hoursPerDay = v),
        onGenerate: () => setState(() => _planGenerated = true),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController examCtrl, dateCtrl;
  final double hoursPerDay;
  final ValueChanged<double> onHoursChanged;
  final VoidCallback onGenerate;
  const _FormView({
    required this.examCtrl, required this.dateCtrl,
    required this.hoursPerDay, required this.onHoursChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinAlert(
          'WinAI va créer un plan de révision personnalisé basé sur tes résultats.',
          type: BadgeColor.teal, icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 24),
        WinTextField(label: 'Examen cible', hint: 'BAC C, ENSP…',
            icon: Icons.school_outlined, controller: examCtrl),
        const SizedBox(height: 16),
        WinTextField(label: 'Date de l\'examen', hint: 'jj mois aaaa',
            icon: Icons.calendar_today_outlined, controller: dateCtrl),
        const SizedBox(height: 24),
        Text('Heures d\'étude par jour', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 4),
        Text('${hoursPerDay.round()}h/jour', style: WinType.archivo(
            size: 28, weight: FontWeight.w700, color: s.primary)),
        Slider(
          value: hoursPerDay,
          min: 1, max: 6, divisions: 5,
          activeColor: s.primary,
          inactiveColor: s.outline2,
          onChanged: onHoursChanged,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1h', style: WinType.labelM(s.onFaint)),
          Text('6h', style: WinType.labelM(s.onFaint)),
        ]),
        const SizedBox(height: 32),
        WinButton('Générer mon plan avec WinAI',
            block: true, icon: Icons.auto_awesome_outlined,
            onTap: onGenerate),
      ]),
    );
  }
}

class _PlanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final plan = WinData.examCoachPlan;
    final done = plan.weeks.where((w) => w.done).length;
    final total = plan.weeks.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Header
        WinCard(
          bg: WinColors.ink800,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.school_outlined, size: 20, color: WinColors.teal400),
              const SizedBox(width: 8),
              Text(plan.examName,
                  style: WinType.headlineS(WinColors.cream50)),
              const Spacer(),
              WinBadge('${WinData.upcomingExams.first.daysLeft}j restants',
                  color: BadgeColor.warn),
            ]),
            const SizedBox(height: 4),
            Text(plan.examDate, style: WinType.bodyS(WinColors.ink300)),
            const SizedBox(height: 12),
            WinProgressBar(done / total * 100, color: WinColors.teal400),
            const SizedBox(height: 4),
            Text('$done/$total semaines complétées',
                style: WinType.labelM(WinColors.ink300)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Planning semaine par semaine',
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        ...plan.weeks.asMap().entries.map((e) {
          final week = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WinCard(
              bg: week.done ? WinColors.successBg : null,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: week.done ? WinColors.success : s.surface2,
                  ),
                  child: Icon(
                    week.done ? Icons.check : Icons.lock_open_outlined,
                    size: 16,
                    color: week.done ? Colors.white : s.onFaint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(week.label, style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: week.topics.map((t) => WinChip(t)).toList(),
                  ),
                ])),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
        WinButton('Partager mon plan',
            variant: WinButtonVariant.outline, block: true,
            icon: Icons.share_outlined, onTap: () {}),
      ],
    );
  }
}
