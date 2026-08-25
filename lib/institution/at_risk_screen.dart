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
      if (mounted) setState(() => _students = list);
    } catch (_) {
      if (mounted) setState(() => _students = []);
    }
  }

  bool _isCritical(ApiAtRiskStudent s) => s.riskScore >= 0.7;

  List<ApiAtRiskStudent> get _items {
    final all = _students ?? [];
    return switch (_filter) {
      'Critique' => all.where(_isCritical).toList(),
      'Modéré'   => all.where((s) => !_isCritical(s)).toList(),
      _          => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final high = (_students ?? []).where(_isCritical).length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Élèves à risque', style: WinType.headlineS(s.onStrong)),
        actions: [
          if (_students != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: WinBadge('$high critiques', color: BadgeColor.error)),
            ),
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() => _students = null); _load(); },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: _filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WinChip(f, active: _filter == f,
                onTap: () => setState(() => _filter = f)),
          )).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList(s)),
      ]),
    );
  }

  Widget _buildList(WinScheme s) {
    if (_students == null) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline, size: 64, color: WinColors.success),
        const SizedBox(height: 12),
        Text('Aucun élève à risque détecté.', style: WinType.bodyM(s.onMuted)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AtRiskCard(_items[i], _isCritical(_items[i])),
    );
  }
}

class _AtRiskCard extends StatelessWidget {
  final ApiAtRiskStudent student;
  final bool isCritical;
  const _AtRiskCard(this.student, this.isCritical);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final riskColor = isCritical ? WinColors.error : WinColors.warn;
    final riskPct = (student.riskScore * 100).round();

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
        Row(children: [
          WinAvatar(student.fullName, size: 40,
              color: isCritical ? WinColors.errorBg : WinColors.warnBg),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(student.fullName, style: WinType.titleM(s.onStrong)),
            Text(student.groupName ?? 'Groupe non assigné', style: WinType.labelM(s.onMuted)),
          ])),
          WinBadge(isCritical ? 'Critique' : 'Modéré',
              color: isCritical ? BadgeColor.error : BadgeColor.warn),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _Chip(Icons.bar_chart, 'Risque : $riskPct%', s.onMuted),
        ]),
        const SizedBox(height: 8),
        Text(student.riskReason, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 12),
        Row(children: [
          WinButton('Contacter', small: true, icon: Icons.message_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MessagingScreen()))),
          const SizedBox(width: 8),
          WinButton('Plan d\'action', small: true,
              variant: WinButtonVariant.outline,
              icon: Icons.checklist_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActionPlanScreen()))),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: WinType.labelM(color)),
    ]);
  }
}
