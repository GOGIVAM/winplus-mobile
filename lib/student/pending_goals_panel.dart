import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/goals_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Objectifs proposés par un parent, en attente de réponse de l'élève
/// (Status Pending). Se cache tout seul quand la liste est vide : c'est son
/// propre "badge", pas besoin de compteur global séparé.
class PendingGoalsPanel extends StatefulWidget {
  const PendingGoalsPanel({super.key});
  @override
  State<PendingGoalsPanel> createState() => _PendingGoalsPanelState();
}

class _PendingGoalsPanelState extends State<PendingGoalsPanel> {
  List<ApiGoalDetail>? _pending;
  int? _busyId;
  int? _editingId;
  int? _confirmRefuseId;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _editDeadline;
  String? _error;

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
      final all = await GoalsService.instance.getMyGoals();
      if (mounted)
        setState(
            () => _pending = all.where((g) => g.status == 'Pending').toList());
    } catch (_) {
      if (mounted) setState(() => _pending = []);
    }
  }

  void _startEdit(ApiGoalDetail g) {
    setState(() {
      _error = null;
      _confirmRefuseId = null;
      _editingId = g.id;
      _titleCtrl.text = g.title ?? '';
      _descCtrl.text = g.description ?? '';
      _editDeadline = g.targetDate;
    });
  }

  Future<void> _accept(int id) async {
    setState(() {
      _busyId = id;
      _error = null;
    });
    try {
      await GoalsService.instance.accept(id);
      if (mounted)
        setState(() {
          _pending = _pending?.where((g) => g.id != id).toList();
        });
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = L10n.current.studentGoalsAcceptError);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _refuse(int id) async {
    setState(() {
      _busyId = id;
      _error = null;
    });
    try {
      await GoalsService.instance.refuse(id);
      if (mounted)
        setState(() {
          _pending = _pending?.where((g) => g.id != id).toList();
        });
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = L10n.current.studentGoalsRefuseError);
    } finally {
      if (mounted)
        setState(() {
          _busyId = null;
          _confirmRefuseId = null;
        });
    }
  }

  Future<void> _saveEdit(int id) async {
    if (_titleCtrl.text.trim().isEmpty || _editDeadline == null) {
      setState(() => _error = L10n.current.studentGoalsRequired);
      return;
    }
    setState(() {
      _busyId = id;
      _error = null;
    });
    try {
      await GoalsService.instance.modify(
        id,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        deadline: _editDeadline!,
      );
      if (mounted)
        setState(() {
          _pending = _pending?.where((g) => g.id != id).toList();
          _editingId = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            L10n.current.studentGoalsSaveError);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _editDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _editDeadline = picked);
  }

  String _fmtDate(DateTime d) =>
      WinFormat.dateNumeric(d);

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    if (pending == null || pending.isEmpty) return const SizedBox.shrink();
    final s = WinTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinColors.teal500.withValues(alpha: 0.06),
        border: Border.all(color: WinColors.teal500.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(WinRadii.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_outlined, size: 16, color: WinColors.teal600),
          const SizedBox(width: 8),
          Expanded(
              child: Text(context.l10n.studentGoalsTitle,
                  style: WinType.titleM(s.onStrong))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: WinColors.teal600,
                borderRadius: BorderRadius.circular(WinRadii.full)),
            child:
                Text('${pending.length}', style: WinType.labelS(Colors.white)),
          ),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: WinType.labelS(WinColors.error)),
        ],
        const SizedBox(height: 10),
        ...pending.map((g) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  _editingId == g.id ? _buildEditForm(s, g) : _buildItem(s, g),
            )),
      ]),
    );
  }

  Widget _buildItem(WinScheme s, ApiGoalDetail g) {
    final busy = _busyId == g.id;
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(g.title ?? '', style: WinType.titleM(s.onStrong))),
          Text(context.l10n.studentGoalsDeadlineOn(_fmtDate(g.targetDate)),
              style: WinType.labelS(s.onFaint)),
        ]),
        const SizedBox(height: 2),
        Text(context.l10n.studentGoalsProposedBy,
            style: WinType.labelS(WinColors.teal600)
                .copyWith(fontStyle: FontStyle.italic)),
        if (g.description != null && g.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(g.description!, style: WinType.bodyS(s.onMuted)),
        ],
        const SizedBox(height: 10),
        if (_confirmRefuseId == g.id)
          Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.l10n.studentGoalsRefuseConfirm,
                    style: WinType.labelS(s.onMuted)),
                WinButton(context.l10n.commonConfirm,
                    small: true,
                    variant: WinButtonVariant.outline,
                    loading: busy,
                    onTap: () => _refuse(g.id)),
                WinButton(context.l10n.commonCancel,
                    small: true,
                    variant: WinButtonVariant.ghost,
                    onTap: busy
                        ? null
                        : () => setState(() => _confirmRefuseId = null)),
              ])
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            WinButton(context.l10n.commonAccept,
                small: true,
                icon: Icons.check,
                loading: busy,
                onTap: () => _accept(g.id)),
            WinButton(context.l10n.commonEdit,
                small: true,
                variant: WinButtonVariant.outline,
                icon: Icons.edit_outlined,
                onTap: busy ? null : () => _startEdit(g)),
            WinButton(context.l10n.commonDecline,
                small: true,
                variant: WinButtonVariant.ghost,
                icon: Icons.close,
                onTap: busy
                    ? null
                    : () => setState(() {
                          _confirmRefuseId = g.id;
                          _error = null;
                        })),
          ]),
      ]),
    );
  }

  Widget _buildEditForm(WinScheme s, ApiGoalDetail g) {
    final busy = _busyId == g.id;
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinTextField(label: context.l10n.studentGoalsFieldTitle, controller: _titleCtrl),
        const SizedBox(height: 10),
        Text(context.l10n.commonDescription, style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          style: WinType.bodyM(s.onStrong),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: s.surface2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.outline)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WinRadii.md),
                borderSide: BorderSide(color: s.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 10),
        Text(context.l10n.studentGoalsFieldDeadline, style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickDeadline,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                border: Border.all(color: s.outline),
                borderRadius: BorderRadius.circular(WinRadii.md)),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: s.onFaint),
              const SizedBox(width: 8),
              Text(
                  _editDeadline != null
                      ? _fmtDate(_editDeadline!)
                      : context.l10n.studentCoachPickDate,
                  style: WinType.bodyM(s.onStrong)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: WinButton(context.l10n.studentGoalsSaveActivate,
                  small: true, loading: busy, onTap: () => _saveEdit(g.id))),
          const SizedBox(width: 8),
          WinButton(context.l10n.commonCancel,
              small: true,
              variant: WinButtonVariant.ghost,
              onTap: busy ? null : () => setState(() => _editingId = null)),
        ]),
      ]),
    );
  }
}
