import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/subscription/upgrade_sheet.dart';

class ExamCoachScreen extends StatefulWidget {
  const ExamCoachScreen({super.key});
  @override
  State<ExamCoachScreen> createState() => _ExamCoachScreenState();
}

class _ExamCoachScreenState extends State<ExamCoachScreen> {
  bool _planGenerated = false;
  final _examCtrl = TextEditingController(text: 'BAC C');
  final _dateCtrl = TextEditingController(text: '18 juin 2026');
  double _hoursPerDay = 3;

  // Matières sélectionnées dans l'ordre de priorité
  final List<String> _orderedSubjects = ['math', 'pc', 'chimie'];

  // Deadline par matière (optionnel)
  final Map<String, TextEditingController> _deadlineCtrls = {};

  @override
  void dispose() {
    _examCtrl.dispose();
    _dateCtrl.dispose();
    for (final c in _deadlineCtrls.values) { c.dispose(); }
    super.dispose();
  }

  TextEditingController _deadlineCtrl(String subjectId) =>
      _deadlineCtrls.putIfAbsent(subjectId, () => TextEditingController());

  void _toggleSubject(String id) {
    setState(() {
      if (_orderedSubjects.contains(id)) {
        _orderedSubjects.remove(id);
        _deadlineCtrls[id]?.dispose();
        _deadlineCtrls.remove(id);
      } else {
        _orderedSubjects.add(id);
      }
    });
  }

  void _moveUp(int i) {
    if (i == 0) return;
    setState(() {
      final tmp = _orderedSubjects[i - 1];
      _orderedSubjects[i - 1] = _orderedSubjects[i];
      _orderedSubjects[i] = tmp;
    });
  }

  void _moveDown(int i) {
    if (i == _orderedSubjects.length - 1) return;
    setState(() {
      final tmp = _orderedSubjects[i + 1];
      _orderedSubjects[i + 1] = _orderedSubjects[i];
      _orderedSubjects[i] = tmp;
    });
  }

  String _fmtHours(double h) {
    final mins = (h * 60).round();
    final hh = mins ~/ 60;
    final mm = mins % 60;
    return mm == 0 ? '${hh}h' : '${hh}h${mm.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    const sub = WinData.currentSubscription;

    if (sub.isFree) {
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
              Container(width: 80, height: 80,
                decoration: const BoxDecoration(color: WinColors.warnBg, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline, size: 40, color: WinColors.warn)),
              const SizedBox(height: 20),
              Text('Exam Coach', style: WinType.displayS(s.onStrong), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Disponible à partir du plan Standard.\nWinAI génère un planning adapté à tes lacunes.',
                  style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              WinButton('Voir les plans', block: true,
                  onTap: () => UpgradeSheet.show(context, featureName: 'Exam Coach', requiredPlan: 'Standard')),
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
      body: _planGenerated ? _PlanView() : _buildForm(s),
    );
  }

  Widget _buildForm(WinScheme s) {
    const allSubjects = WinData.subjects;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const WinAlert(
          'WinAI génère un planning semaine par semaine adapté à tes lacunes et tes délais.',
          type: BadgeColor.teal, icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 24),

        // ── Exam + date ───────────────────────────────────────────
        WinTextField(label: 'Examen cible', hint: 'BAC C, ENSP, BEPC…',
            icon: Icons.school_outlined, controller: _examCtrl),
        const SizedBox(height: 16),
        WinTextField(label: 'Date de l\'examen', hint: 'jj mois aaaa',
            icon: Icons.calendar_today_outlined, controller: _dateCtrl),
        const SizedBox(height: 28),

        // ── Sélection des matières ────────────────────────────────
        Text('Matières à réviser', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 4),
        Text('Sélectionne les matières à inclure dans ton planning.',
            style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: allSubjects.map((subj) {
            final selected = _orderedSubjects.contains(subj.id);
            return GestureDetector(
              onTap: () => _toggleSubject(subj.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? subj.color.withValues(alpha: 0.12) : s.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? subj.color : s.outline,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(subj.icon, size: 14, color: selected ? subj.color : s.onFaint),
                  const SizedBox(width: 6),
                  Text(subj.short,
                      style: WinType.labelM(selected ? subj.color : s.onMuted)
                          .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ]),
              ),
            );
          }).toList(),
        ),

        // ── Ordre de priorité ─────────────────────────────────────
        if (_orderedSubjects.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Ordre de priorité & délais', style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 4),
          Text('Réordonne par ordre d\'importance. Ajoute une deadline optionnelle.',
              style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 12),
          ..._orderedSubjects.asMap().entries.map((e) {
            final idx = e.key;
            final id = e.value;
            final subj = WinData.subjectById(id);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                color: subj.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: subj.color.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: subj.color, shape: BoxShape.circle),
                  child: Center(child: Text('${idx + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Icon(subj.icon, size: 16, color: subj.color),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(subj.name, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _deadlineCtrl(id),
                    style: WinType.labelM(s.onMuted),
                    decoration: InputDecoration(
                      hintText: 'Deadline optionnelle (ex: 10 mai)',
                      hintStyle: WinType.labelM(s.onFaint),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: subj.color, width: 1)),
                    ),
                  ),
                ])),
                Column(children: [
                  GestureDetector(
                    onTap: () => _moveUp(idx),
                    child: Icon(Icons.keyboard_arrow_up,
                        size: 20, color: idx == 0 ? s.onFaint : s.onMuted),
                  ),
                  GestureDetector(
                    onTap: () => _moveDown(idx),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: idx == _orderedSubjects.length - 1 ? s.onFaint : s.onMuted),
                  ),
                ]),
              ]),
            );
          }),
        ],

        // ── Heures par jour ───────────────────────────────────────
        const SizedBox(height: 28),
        Text("Heures d'étude par jour", style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 4),
        Text(_fmtHours(_hoursPerDay),
            style: WinType.archivo(size: 32, weight: FontWeight.w800, color: s.primary)),
        Slider(
          value: _hoursPerDay,
          min: 1, max: 12, divisions: 22,
          activeColor: s.primary,
          inactiveColor: s.outline2,
          onChanged: (v) => setState(() => _hoursPerDay = v),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1h', style: WinType.labelM(s.onFaint)),
          Text('6h', style: WinType.labelM(s.onFaint)),
          Text('12h', style: WinType.labelM(s.onFaint)),
        ]),
        const SizedBox(height: 8),
        Text(
          _hoursPerDay <= 4
              ? 'Rythme léger · Idéal pour maintenir la régularité.'
              : _hoursPerDay <= 7
                  ? 'Rythme modéré · Bon équilibre travail/repos.'
                  : 'Rythme intensif · Assure-toi de bien dormir !',
          style: WinType.bodyS(s.onMuted),
        ),
        const SizedBox(height: 36),
        WinButton(
          'Générer mon plan avec WinAI',
          block: true,
          icon: Icons.auto_awesome_outlined,
          onTap: _orderedSubjects.isEmpty
              ? null
              : () => setState(() => _planGenerated = true),
        ),
        if (_orderedSubjects.isEmpty) ...[
          const SizedBox(height: 8),
          Center(child: Text('Sélectionne au moins une matière.',
              style: WinType.labelM(WinColors.warn))),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _PlanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    const plan = WinData.examCoachPlan;
    final done = plan.weeks.where((w) => w.done).length;
    final total = plan.weeks.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        WinCard(
          bg: WinColors.ink800,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.school_outlined, size: 20, color: WinColors.teal400),
              const SizedBox(width: 8),
              Text(plan.examName, style: WinType.headlineS(WinColors.cream50)),
              const Spacer(),
              WinBadge('${WinData.upcomingExams.first.daysLeft}j restants', color: BadgeColor.warn),
            ]),
            const SizedBox(height: 4),
            Text(plan.examDate, style: WinType.bodyS(WinColors.ink300)),
            const SizedBox(height: 12),
            WinProgressBar(done / total * 100, color: WinColors.teal400),
            const SizedBox(height: 4),
            Text('$done/$total semaines complétées', style: WinType.labelM(WinColors.ink300)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Planning semaine par semaine', style: WinType.headlineS(s.onStrong)),
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
                  child: Icon(week.done ? Icons.check : Icons.lock_open_outlined,
                      size: 16, color: week.done ? Colors.white : s.onFaint),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(week.label, style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6,
                      children: week.topics.map((t) => WinChip(t)).toList()),
                ])),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
        WinButton('Partager mon plan', variant: WinButtonVariant.outline, block: true,
            icon: Icons.share_outlined, onTap: () {}),
      ],
    );
  }
}
