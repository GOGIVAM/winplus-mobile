import 'package:flutter/material.dart';
import '../services/exam_coach_service.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Mode veille d'examen : le parent active un suivi rapproché sur le plan
/// ExamCoachPlan actif de l'enfant (ou en crée un). N'ajoute pas de nouvelle
/// entité  juste ExamCoachPlan.ParentWatchModeActivatedAt côté backend.
class ExamWatchModeTab extends StatefulWidget {
  final ApiChild child;
  const ExamWatchModeTab({super.key, required this.child});
  @override
  State<ExamWatchModeTab> createState() => _ExamWatchModeTabState();
}

class _ExamWatchModeTabState extends State<ExamWatchModeTab> {
  ApiWatchModeState? _state;
  bool _busy = false;
  String? _error;
  final _examTypeCtrl = TextEditingController();
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _examTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state =
          await ExamCoachService.instance.getWatchMode(widget.child.id);
      if (mounted) setState(() => _state = state);
    } catch (_) {
      if (mounted) {
        setState(() => _state = const ApiWatchModeState(active: false));
      }
    }
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _activateExisting() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state =
          await ExamCoachService.instance.activateWatchMode(widget.child.id);
      if (mounted) setState(() => _state = state);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = "Impossible d'activer la veille pour le moment.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitForm() async {
    if (_examTypeCtrl.text.trim().isEmpty || _examDate == null) {
      setState(() => _error = "Choisissez un type d'examen et une date.");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state = await ExamCoachService.instance.activateWatchMode(
        widget.child.id,
        examType: _examTypeCtrl.text.trim(),
        examDate: _examDate,
      );
      if (mounted) setState(() => _state = state);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = "La veille n'a pas pu être activée. Réessayez.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ExamCoachService.instance.deactivateWatchMode(widget.child.id);
      _load();
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Impossible de désactiver la veille pour le moment.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = _state;
    if (state == null) return const Center(child: CircularProgressIndicator());

    final daysLeft = state.examDate != null
        ? state.examDate!.difference(DateTime.now()).inDays
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text("Veille d'examen  ${widget.child.firstName}",
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 6),
        Text(
          "Un suivi rapproché pendant la période d'examen : WinAI adapte ses conseils et vous propose des questions pertinentes dans l'assistant familial.",
          style: WinType.bodyS(s.onMuted),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, style: WinType.labelS(WinColors.error)),
          const SizedBox(height: 8),
        ],
        if (state.active)
          WinCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.examType ?? '',
                            style: WinType.titleM(s.onStrong)),
                        if (state.examDate != null)
                          Text('Examen le ${_fmtDate(state.examDate!)}',
                              style: WinType.labelS(s.onMuted)),
                      ]),
                ),
                if (daysLeft != null && daysLeft >= 0)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('J-$daysLeft',
                        style: WinType.archivo(
                            size: 22,
                            weight: FontWeight.w800,
                            color: WinColors.teal700)),
                    Text("avant l'examen",
                        style: WinType.labelS(WinColors.teal600)),
                  ]),
              ]),
              const SizedBox(height: 12),
              WinButton('Désactiver la veille',
                  variant: WinButtonVariant.outline,
                  loading: _busy,
                  onTap: _deactivate),
            ]),
          )
        else if (state.examType != null && state.examDate != null)
          WinCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.examType!, style: WinType.titleM(s.onStrong)),
              Text('Examen le ${_fmtDate(state.examDate!)}',
                  style: WinType.labelS(s.onMuted)),
              const SizedBox(height: 12),
              WinButton('Activer la veille',
                  block: true, loading: _busy, onTap: _activateExisting),
            ]),
          )
        else
          WinCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WinTextField(
                label: "Type d'examen",
                hint: 'Ex : BEPC, Baccalauréat série C…',
                icon: Icons.school_outlined,
                controller: _examTypeCtrl,
              ),
              const SizedBox(height: 14),
              Text("Date de l'examen",
                  style: WinType.labelM(s.onStrong)
                      .copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickExamDate,
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
                        _examDate != null
                            ? _fmtDate(_examDate!)
                            : 'Choisir une date',
                        style: WinType.bodyM(s.onStrong)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              WinButton('Activer la veille',
                  block: true, loading: _busy, onTap: _submitForm),
            ]),
          ),
      ],
    );
  }
}
