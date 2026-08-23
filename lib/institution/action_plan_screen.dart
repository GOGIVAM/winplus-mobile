import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ActionPlanScreen extends StatefulWidget {
  const ActionPlanScreen({super.key});
  @override
  State<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends State<ActionPlanScreen> {
  final _done = <int>{};
  String? _aiPlan;

  @override
  void initState() {
    super.initState();
    InstitutionService.instance.getActionPlan().then((plan) {
      if (mounted && plan != null) setState(() => _aiPlan = plan);
    });
  }

  static const _actions = [
    (
      Icons.person_outline,
      WinColors.error,
      'Intervention urgente',
      'Jean-Paul Ekwalla',
      'Score < 35% depuis 3 semaines. Planifier un entretien avec l\'élève et ses parents avant vendredi.',
    ),
    (
      Icons.group_outlined,
      WinColors.warn,
      'Session de rattrapage',
      'Groupe TLE D 2026',
      'Organiser une session de révision en Physique pour les 8 élèves sous la moyenne.',
    ),
    (
      Icons.message_outlined,
      WinColors.blue500,
      'Notification aux parents',
      'Martine Abanda & Boris Nguyen',
      'Envoyer un rapport de progression aux parents de ces 2 élèves à risque modéré.',
    ),
    (
      Icons.library_books_outlined,
      WinColors.teal500,
      'Ressources ciblées',
      'Sylvie Meka',
      'Attribuer le pack de révision Physique BAC C 2022–2024 (score Physique : 28%).',
    ),
    (
      Icons.calendar_today_outlined,
      WinColors.ink500,
      'Suivi hebdomadaire',
      'Tous les élèves à risque',
      'Activer les alertes WinAI hebdomadaires pour les 4 élèves identifiés ce mois.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final doneCount = _done.length;
    final total = _actions.length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Plan d\'action WinAI', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          WinAlert(
            _aiPlan ?? 'WinAI a analysé les données de votre institution et recommande $total actions prioritaires.',
            type: BadgeColor.teal, icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: WinProgressBar(doneCount / total * 100)),
            const SizedBox(width: 12),
            Text('$doneCount/$total', style: WinType.titleM(s.onStrong)),
          ]),
          const SizedBox(height: 4),
          Text('actions réalisées', style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 20),
          ..._actions.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            final isDone = _done.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDone ? WinColors.successBg : s.cardBg,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isDone ? WinColors.success : s.cardBorder,
                  ),
                  boxShadow: WinShadows.sm,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: a.$2.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.$1, size: 20, color: isDone ? WinColors.success : a.$2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.$3, style: WinType.titleM(s.onStrong)),
                    Text(a.$4, style: WinType.labelM(s.primary)
                        .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(a.$5, style: WinType.bodyS(s.onMuted)),
                    const SizedBox(height: 10),
                    if (!isDone)
                      WinButton('Marquer comme fait', small: true,
                          variant: WinButtonVariant.outline,
                          icon: Icons.check,
                          onTap: () => setState(() => _done.add(i)))
                    else
                      Row(children: [
                        const Icon(Icons.check_circle, size: 16, color: WinColors.success),
                        const SizedBox(width: 6),
                        Text('Réalisé', style: WinType.labelM(WinColors.success)
                            .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                  ])),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
