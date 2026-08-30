import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});
  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  String _period = '7 jours';
  static const _periods = ['7 jours', '30 jours', '90 jours', '1 an'];

  static const _subjectScores = {
    'Maths': 84,
    'Physique': 71,
    'Chimie': 52,
    'Français': 79,
    'SVT': 66,
  };

  static const _weeklyScores = [65, 70, 72, 69, 74, 76, 78];
  static const _quizTotal = 47;
  static const _quizSuccessRate = 74;

  Color _barColor(int score) {
    if (score >= 70) return WinColors.success;
    if (score >= 50) return WinColors.warn;
    return WinColors.error;
  }

  int get _avgScore {
    final vals = _subjectScores.values;
    return vals.fold(0, (a, b) => a + b) ~/ vals.length;
  }

  List<MapEntry<String, int>> get _sortedScores {
    final entries = _subjectScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final maxWeekly = _weeklyScores.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes rapports', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. Chips période
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _periods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WinChip(
                  p,
                  active: _period == p,
                  onTap: () => setState(() => _period = p),
                ),
              )).toList(),
            ),
          ),
          if (_period != '7 jours') ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.lock_outline, size: 14, color: WinColors.warn),
              const SizedBox(width: 6),
              Text('Plan Standard requis pour cette période',
                  style: WinType.labelM(WinColors.warn)),
            ]),
          ],
          const SizedBox(height: 20),

          // 2. Card score moyen
          WinCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(
                '$_avgScore%',
                style: WinType.archivo(size: 48, color: _barColor(_avgScore)),
              ),
              const SizedBox(height: 4),
              Text('Score moyen', style: WinType.labelM(s.onMuted)),
            ]),
          ),
          const SizedBox(height: 24),

          // 3. Score par matière
          WinSectionHeader('Score par matière'),
          ..._sortedScores.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                width: 72,
                child: Text(e.key,
                    style: WinType.bodyM(s.onStrong)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: WinProgressBar(
                  e.value.toDouble(),
                  color: _barColor(e.value),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text('${e.value}%',
                    textAlign: TextAlign.right,
                    style: WinType.labelM(s.onMuted)),
              ),
            ]),
          )),
          const SizedBox(height: 24),

          // 4. Progression hebdomadaire
          WinSectionHeader('Progression hebdomadaire'),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyScores.length, (i) {
                final score = _weeklyScores[i];
                final barH = (score / maxWeekly) * 80;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$score', style: WinType.labelS(s.onFaint)),
                        const SizedBox(height: 2),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            color: _barColor(score),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('S${i + 1}',
                            style: WinType.labelS(s.onMuted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Quiz
          WinSectionHeader('Quiz'),
          Row(children: [
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_quizTotal',
                      style: WinType.archivo(size: 28, color: s.onStrong)),
                  const SizedBox(height: 4),
                  Text('Quiz réalisés', style: WinType.labelM(s.onMuted)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WinCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_quizSuccessRate%',
                      style: WinType.archivo(size: 28, color: WinColors.success)),
                  const SizedBox(height: 4),
                  Text('Taux de réussite', style: WinType.labelM(s.onMuted)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          WinCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.emoji_events, size: 16, color: WinColors.gold),
                const SizedBox(width: 6),
                Text('Meilleure matière : Maths',
                    style: WinType.bodyM(s.onStrong)
                        .copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: WinColors.warn),
                const SizedBox(width: 6),
                Text('À améliorer : Chimie', style: WinType.bodyM(s.onMuted)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // 6. Export
          WinButton(
            'Exporter PDF',
            icon: Icons.download_outlined,
            block: true,
            variant: WinButtonVariant.outline,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disponible avec le Plan Standard'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
