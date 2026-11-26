import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../services/institution_service.dart';
import '../shared/messaging/messaging_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'action_plan_screen.dart';
import '../l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';

class AtRiskScreen extends StatefulWidget {
  const AtRiskScreen({super.key});
  @override
  State<AtRiskScreen> createState() => _AtRiskScreenState();
}

class _AtRiskScreenState extends State<AtRiskScreen> {
  List<ApiAtRiskStudent>? _students;
  String _filter = 'Tout';
  static const _filters = ['Tout', 'Critique', 'Modéré'];

  String _filterLabel(String f) => switch (f) {
        'Critique' => context.l10n.instRiskCritical,
        'Modéré' => context.l10n.instRiskModerate,
        _ => context.l10n.commonAll,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await InstitutionService.instance.getAtRiskStudents();
      // Critique first, then Modéré
      list.sort((a, b) {
        if (a.isCritical == b.isCritical)
          return b.riskScore.compareTo(a.riskScore);
        return a.isCritical ? -1 : 1;
      });
      if (mounted) setState(() => _students = list);
    } catch (_) {
      // Panne : erreur et Réessayer, pas « aucun élève à risque ».
      if (mounted) setState(() => _error = true);
    }
  }

  bool _error = false;

  void _retry() {
    setState(() {
      _error = false;
      _students = null;
    });
    _load();
  }

  List<ApiAtRiskStudent> get _items {
    final all = _students ?? [];
    return switch (_filter) {
      'Critique' => all.where((s) => s.isCritical).toList(),
      'Modéré' => all.where((s) => !s.isCritical).toList(),
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final critCount = (_students ?? []).where((s) => s.isCritical).length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.instRiskTitle),
        actions: [
          if (_students != null && critCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                  child: WinBadge(context.l10n.instRiskCriticalCount(critCount),
                      color: BadgeColor.error)),
            ),
          IconButton(
            icon: Icon(PhosphorIconsRegular.arrowClockwise, color: s.onStrong),
            onPressed: _retry,
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: WinChip(_filterLabel(f),
                            active: _filter == f,
                            onTap: () => setState(() => _filter = f)),
                      ))
                  .toList()),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList(s)),
      ]),
    );
  }

  Widget _buildList(WinScheme s) {
    if (_error) {
      return WinErrorState(message: context.l10n.commonLoadError, onRetry: _retry);
    }
    if (_students == null)
      return const WinLoading();
    if (_items.isEmpty) {
      return WinEmptyState(
          icon: PhosphorIconsRegular.checkCircle, title: context.l10n.instRiskEmpty);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AtRiskCard(_items[i]),
    );
  }
}

class _AtRiskCard extends StatelessWidget {
  final ApiAtRiskStudent student;
  const _AtRiskCard(this.student);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final critical = student.isCritical;
    final riskColor = critical ? WinColors.error : WinColors.warn;
    final scoreColor = student.globalScore < 40
        ? WinColors.error
        : student.globalScore < 55
            ? WinColors.warn
            : WinColors.success;

    // Un bord arrondi exige une bordure de couleur uniforme : la bande de
    // couleur du risque est donc dessinee a l'interieur, sous le decoupage.
    return Container(
      decoration: BoxDecoration(
        color: s.cardBg,
        borderRadius: BorderRadius.circular(WinRadii.md),
        border: Border.all(color: s.cardBorder),
        boxShadow: WinShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WinRadii.md - 1),
        child: Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: riskColor, width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: riskColor, width: 2)),
            child: WinAvatar(student.fullName,
                size: 36,
                color: critical ? winTone(s, BadgeColor.error).bg : winTone(s, BadgeColor.warn).bg),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(student.fullName, style: WinType.titleM(s.onStrong)),
                Text(
                    student.level.isNotEmpty
                        ? ClassLevels.label(student.level)
                        : (student.groupName ?? ''),
                    style: WinType.labelM(s.onMuted)),
              ])),
          WinBadge(critical ? context.l10n.instRiskCritical : context.l10n.instRiskModerate,
              color: critical ? BadgeColor.error : BadgeColor.warn),
        ]),
        const SizedBox(height: 12),

        // Stats row
        Wrap(spacing: 8, runSpacing: 8, children: [
          _InfoChip(
              PhosphorIconsRegular.textAlignLeft,
              student.weakSubject.isNotEmpty
                  ? '${student.weakSubject}  ${student.weakScore}%'
                  : context.l10n.instRiskWeakSubject,
              WinColors.error),
          _InfoChip(PhosphorIconsRegular.chartBar, context.l10n.instRiskScore(student.globalScore),
              scoreColor),
          _InfoChip(
              PhosphorIconsRegular.clock,
              student.inactiveDays > 0
                  ? context.l10n.instRiskInactiveFor(student.inactiveDays)
                  : context.l10n.commonActive,
              student.inactiveDays > 7 ? WinColors.error : s.onMuted),
        ]),

        // Reason text
        if (student.riskReason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(student.riskReason,
              style: WinType.bodyS(s.onMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],

        const SizedBox(height: 12),

        // Action buttons (a la ligne sur un ecran etroit)
        Wrap(spacing: 8, runSpacing: 8, children: [
          WinButton(context.l10n.instRiskContact,
              small: true,
              icon: PhosphorIconsRegular.chatText,
              onTap: () => Navigator.push(context,
                  WinPageRoute(builder: (_) => const MessagingScreen()))),
          WinButton(context.l10n.instRiskActionPlan,
              small: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.listChecks,
              onTap: () => Navigator.push(context,
                  WinPageRoute(builder: (_) => const ActionPlanScreen()))),
        ]),
      ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WinRadii.full),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Flexible(
            child: Text(label,
                style:
                    WinType.labelS(color).copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
