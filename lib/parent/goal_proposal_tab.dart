import 'package:flutter/material.dart';
import '../services/goals_service.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

const _goalTypes = [
  ('academic', 'Scolaire'),
  ('personal', 'Personnel'),
  ('skill', 'Compétence'),
];

/// Proposition d'objectifs co-construits parent → enfant (GoalsController).
/// L'élève doit accepter, modifier ou refuser : jamais actif tant qu'il n'a
/// pas répondu. Distinct de WeeklyGoal (cibles hebdomadaires automatiques).
class GoalProposalTab extends StatefulWidget {
  final ApiChild child;
  const GoalProposalTab({super.key, required this.child});
  @override
  State<GoalProposalTab> createState() => _GoalProposalTabState();
}

class _GoalProposalTabState extends State<GoalProposalTab> {
  List<ApiGoal>? _goals;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'academic';
  DateTime? _deadline;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final goals = await ParentService.instance.getGoals(widget.child.id);
      if (mounted) setState(() => _goals = goals);
    } catch (_) {
      if (mounted) setState(() => _goals = []);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _deadline == null) {
      setState(() => _error = "Le titre et l'échéance sont requis.");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _success = false;
    });
    try {
      await GoalsService.instance.propose(
        childId: widget.child.id,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        type: _type,
        deadline: _deadline!,
      );
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _deadline = null;
        _success = true;
      });
      _load();
    } catch (_) {
      setState(
          () => _error = "La proposition n'a pas pu être envoyée. Réessayez.");
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final goals = _goals;
    if (goals == null) return const Center(child: CircularProgressIndicator());

    final pending = goals.where((g) => g.status == 'Pending').toList();
    final active = goals
        .where((g) => g.status == 'Active' && g.proposedByUserId != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Proposer un objectif à ${widget.child.firstName}',
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 6),
        Text(
          "Votre proposition attend l'accord de votre enfant : il peut l'accepter telle quelle, l'ajuster, ou la refuser.",
          style: WinType.bodyS(s.onMuted),
        ),
        const SizedBox(height: 16),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WinTextField(
                label: 'Titre',
                controller: _titleCtrl,
                icon: Icons.flag_outlined),
            const SizedBox(height: 12),
            WinTextField(
                label: 'Description (optionnel)', controller: _descCtrl),
            const SizedBox(height: 12),
            Text('Type',
                style: WinType.labelM(s.onStrong)
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _goalTypes
                  .map((t) => WinChip(t.$2,
                      active: _type == t.$1,
                      onTap: () => setState(() => _type = t.$1)))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text('Échéance',
                style: WinType.labelM(s.onStrong)
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: s.surface,
                  borderRadius: BorderRadius.circular(WinRadii.md),
                  border: Border.all(color: s.outline, width: 1.5),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: s.onFaint),
                  const SizedBox(width: 10),
                  Text(
                      _deadline != null
                          ? _fmtDate(_deadline!)
                          : 'Choisir une date',
                      style: WinType.bodyM(s.onStrong)),
                ]),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: WinType.labelS(WinColors.error)),
            ],
            if (_success) ...[
              const SizedBox(height: 8),
              Text('Proposition envoyée.',
                  style: WinType.labelS(WinColors.teal700)),
            ],
            const SizedBox(height: 12),
            WinButton("Proposer l'objectif",
                block: true, loading: _submitting, onTap: _submit),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Propositions en attente', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Text('Aucune proposition en attente de réponse.',
              style: WinType.bodyS(s.onMuted))
        else
          ...pending.map((g) =>
              _GoalRow(goal: g, label: 'En attente', color: WinColors.warn)),
        const SizedBox(height: 20),
        Text('Objectifs actifs co-construits',
            style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Text('Aucun objectif co-construit actif pour le moment.',
              style: WinType.bodyS(s.onMuted))
        else
          ...active.map((g) =>
              _GoalRow(goal: g, label: 'Actif', color: WinColors.teal600)),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  final ApiGoal goal;
  final String label;
  final Color color;
  const _GoalRow(
      {required this.goal, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(goal.title ?? '', style: WinType.titleM(s.onStrong)),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(goal.description!, style: WinType.bodyS(s.onMuted)),
              ],
              const SizedBox(height: 4),
              Text(
                'Échéance : ${goal.targetDate.day.toString().padLeft(2, '0')}/${goal.targetDate.month.toString().padLeft(2, '0')}/${goal.targetDate.year}',
                style: WinType.labelS(s.onFaint),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WinRadii.full),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(label,
                style: WinType.labelS(color)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
