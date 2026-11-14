import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Plan d'action hebdomadaire WinAI de l'établissement.
///
/// Module 23 : l'écran affichait une liste de cinq actions codées en dur
/// (élèves fictifs) ; seul le texte d'en-tête dépendait du réseau, et il lisait
/// un champ que le serveur ne renvoie pas. Les actions viennent désormais de
/// GET /api/institution/action-plan (plan calculé par WinAI sur les élèves de
/// l'établissement), avec des états chargement, échec et liste vide explicites.
class ActionPlanScreen extends StatefulWidget {
  const ActionPlanScreen({super.key});
  @override
  State<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends State<ActionPlanScreen> {
  // Suivi « réalisé » local à la session d'écran (comportement inchangé :
  // aucune persistance serveur n'existe pour ce marquage).
  final _done = <int>{};
  ApiActionPlan? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await InstitutionService.instance.getActionPlan();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _done.clear();
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      setState(() {
        _loading = false;
        _error = code == 403
            ? L10n.current.instPlanForbidden
            : L10n.current.instPlanUnavailable;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = L10n.current.instPlanUnavailable;
      });
    }
  }

  static (IconData, Color) _styleFor(int priority) {
    switch (priority) {
      case 1:
        return (Icons.priority_high, WinColors.error);
      case 2:
        return (Icons.trending_up, WinColors.warn);
      default:
        return (Icons.insights_outlined, WinColors.blue500);
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text(context.l10n.instPlanTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: _buildContent(s),
        ),
      ),
    );
  }

  List<Widget> _buildContent(WinScheme s) {
    if (_loading) {
      return const [
        WinSkeleton(height: 56),
        SizedBox(height: 16),
        WinSkeleton(height: 110),
        SizedBox(height: 12),
        WinSkeleton(height: 110),
        SizedBox(height: 12),
        WinSkeleton(height: 110),
      ];
    }

    if (_error != null) {
      return [
        WinAlert(_error!, type: BadgeColor.error, icon: Icons.error_outline),
        const SizedBox(height: 16),
        WinButton(context.l10n.commonRetry,
            icon: Icons.refresh,
            variant: WinButtonVariant.outline,
            onTap: _load),
      ];
    }

    final plan = _plan ?? const ApiActionPlan();
    final actions = plan.actions;
    if (actions.isEmpty) {
      return [
        WinAlert(
          plan.message ??
              context.l10n.instPlanEmpty,
          type: BadgeColor.neutral,
          icon: Icons.info_outline,
        ),
      ];
    }

    final total = actions.length;
    final doneCount = _done.length;
    final summary = StringBuffer(
        context.l10n.instPlanSummaryStudents(plan.studentCount));
    if (plan.atRiskCount > 0) {
      summary.write(context.l10n.instPlanSummaryAtRisk(plan.atRiskCount));
    }
    summary.write(
        context.l10n.instPlanSummaryActions(total));

    return [
      if (plan.weekLabel != null) ...[
        Text(plan.weekLabel!, style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 8),
      ],
      WinAlert(
        summary.toString(),
        type: BadgeColor.teal,
        icon: winAIIconData,
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: WinProgressBar(doneCount / total * 100)),
        const SizedBox(width: 12),
        Text('$doneCount/$total', style: WinType.titleM(s.onStrong)),
      ]),
      const SizedBox(height: 4),
      Text(context.l10n.instPlanActionsDone, style: WinType.labelM(s.onMuted)),
      const SizedBox(height: 20),
      ...actions.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value;
        final (icon, color) = _styleFor(a.priority);
        final isDone = _done.contains(i);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDone ? WinColors.successBg : s.cardBg,
              borderRadius: BorderRadius.circular(WinRadii.lg),
              border: Border.all(
                color: isDone ? WinColors.success : s.cardBorder,
              ),
              boxShadow: WinShadows.sm,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 20, color: isDone ? WinColors.success : color),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(context.l10n.instPlanPriority(a.priority > 0 ? a.priority : i + 1),
                        style: WinType.titleM(s.onStrong)),
                    if (a.effort.isNotEmpty)
                      Text(a.effort,
                          style: WinType.labelM(s.primary)
                              .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(a.action, style: WinType.bodyS(s.onMuted)),
                    if (a.estimatedImpact.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(context.l10n.instPlanImpact(a.estimatedImpact),
                          style: WinType.bodyS(s.onMuted)),
                    ],
                    const SizedBox(height: 10),
                    if (!isDone)
                      WinButton(context.l10n.instPlanMarkDone,
                          small: true,
                          variant: WinButtonVariant.outline,
                          icon: Icons.check,
                          onTap: () => setState(() => _done.add(i)))
                    else
                      Row(children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: WinColors.success),
                        const SizedBox(width: 6),
                        Text(context.l10n.instPlanDone,
                            style: WinType.labelM(WinColors.success)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                  ])),
            ]),
          ),
        );
      }),
    ];
  }
}
