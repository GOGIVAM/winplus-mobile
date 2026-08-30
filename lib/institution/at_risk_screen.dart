import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../shared/messaging/messaging_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'action_plan_screen.dart';

class AtRiskScreen extends StatefulWidget {
  const AtRiskScreen({super.key});
  @override
  State<AtRiskScreen> createState() => _AtRiskScreenState();
}

class _AtRiskScreenState extends State<AtRiskScreen> {
  List<ApiAtRiskStudent>? _students;
  String _filter = 'Tout';
  static const _filters = ['Tout', 'Critique', 'Modéré'];

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
      if (mounted) setState(() => _students = []);
    }
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
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Élèves à risque', style: WinType.headlineS(s.onStrong)),
        actions: [
          if (_students != null && critCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                  child: WinBadge('$critCount critiques',
                      color: BadgeColor.error)),
            ),
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() => _students = null);
              _load();
            },
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
                        child: WinChip(f,
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
    if (_students == null)
      return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline,
            size: 64, color: WinColors.success),
        const SizedBox(height: 12),
        Text('Aucun élève dans cette catégorie.',
            style: WinType.bodyM(s.onMuted)),
      ]));
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

    return Container(
      decoration: BoxDecoration(
        color: s.cardBg,
        borderRadius: BorderRadius.zero,
        border: Border(
          left: BorderSide(color: riskColor, width: 4),
          top: BorderSide(color: s.cardBorder),
          right: BorderSide(color: s.cardBorder),
          bottom: BorderSide(color: s.cardBorder),
        ),
        boxShadow: WinShadows.sm,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          WinAvatar(student.fullName,
              size: 40, color: critical ? WinColors.errorBg : WinColors.warnBg),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(student.fullName, style: WinType.titleM(s.onStrong)),
                Text(
                    student.level.isNotEmpty
                        ? student.level
                        : (student.groupName ?? ''),
                    style: WinType.labelM(s.onMuted)),
              ])),
          WinBadge(critical ? 'Critique' : 'Modéré',
              color: critical ? BadgeColor.error : BadgeColor.warn),
        ]),
        const SizedBox(height: 12),

        // Stats row
        Row(children: [
          _InfoChip(
              Icons.subject_outlined,
              student.weakSubject.isNotEmpty
                  ? '${student.weakSubject}  ${student.weakScore}%'
                  : 'Matière faible ',
              WinColors.error),
          const SizedBox(width: 10),
          _InfoChip(Icons.bar_chart_outlined, 'Score : ${student.globalScore}%',
              scoreColor),
          const SizedBox(width: 10),
          _InfoChip(
              Icons.schedule_outlined,
              student.inactiveDays > 0
                  ? 'Inactif depuis ${student.inactiveDays}j'
                  : 'Actif',
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

        // Action buttons
        Row(children: [
          WinButton('Contacter',
              small: true,
              icon: Icons.message_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MessagingScreen()))),
          const SizedBox(width: 8),
          WinButton("Plan d'action",
              small: true,
              variant: WinButtonVariant.outline,
              icon: Icons.checklist_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActionPlanScreen()))),
        ]),
      ]),
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
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Flexible(
          child: Text(label,
              style:
                  WinType.labelM(color).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
    ]);
  }
}
