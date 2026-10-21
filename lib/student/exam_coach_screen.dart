import '../l10n/l10n.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/exam_coach_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/subscription/upgrade_sheet.dart';
import '../shared/subscription/subscription_notifier.dart';

/// Module 24 (lot 8, rattrapage 16.3) : Exam Coach porté sur les vrais
/// endpoints déjà utilisés par le web (ExamCoach.tsx/examCoachService.ts) —
/// GET/POST/PUT/DELETE /exam-coach — remplace le plan 100% simulé
/// (WinData.examCoachPlan) affiché jusqu'ici.
class ExamCoachScreen extends StatefulWidget {
  const ExamCoachScreen({super.key});
  @override
  State<ExamCoachScreen> createState() => _ExamCoachScreenState();
}

const _examTypes = <String, String>{
  'BEPC': "BEPC — Brevet d'Études du Premier Cycle",
  'BAC_C': 'BAC C — Mathématiques & Sciences Physiques',
  'BAC_D': 'BAC D — Sciences & Vie de la Terre',
  'BAC_A': 'BAC A — Lettres & Sciences Humaines',
  'BAC_TI': 'BAC TI — Technique Industrielle',
  'BAC_G': 'BAC G — Sciences Économiques & Sociales',
  'ENSP': 'ENSP',
  'UY_L1': 'Université — Licence 1',
  'CONCOURS': "Concours d'entrée",
};

class _ExamCoachScreenState extends State<ExamCoachScreen> {
  bool _loading = true;
  bool _generating = false;
  String? _error;
  ApiExamCoachPlan? _plan;
  Map<String, dynamic>? _parsed;

  // Formulaire de configuration
  String _examType = 'BAC_C';
  DateTime? _examDate;
  double _hoursPerDay = 2;

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
      final plan = await ExamCoachService.instance.getActivePlan();
      Map<String, dynamic>? parsed;
      if (plan != null) {
        try {
          parsed = Map<String, dynamic>.from(jsonDecode(plan.planJson) as Map);
        } catch (_) {
          parsed = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _parsed = parsed;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = L10n.current.studentCoachLoadError;
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_examDate == null) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final plan = await ExamCoachService.instance.createPlan(
        examType: _examType,
        examDate: _examDate!,
        hoursPerDay: _hoursPerDay,
      );
      Map<String, dynamic>? parsed;
      try {
        parsed = Map<String, dynamic>.from(jsonDecode(plan.planJson) as Map);
      } catch (_) {
        parsed = null;
      }
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _parsed = parsed;
        _generating = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = L10n.current.studentCoachGenerateError;
        });
      }
    }
  }

  Future<void> _deletePlan() async {
    final plan = _plan;
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.studentCoachDeleteTitle),
        content: Text(context.l10n.studentCoachDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ExamCoachService.instance.deactivatePlan(plan.id);
      if (!mounted) return;
      setState(() {
        _plan = null;
        _parsed = null;
      });
    } catch (_) {}
  }

  int _todayDayNumber() {
    final created = _plan!.createdAt;
    final createdDate = DateTime(created.year, created.month, created.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return (todayDate.difference(createdDate).inDays + 1).clamp(1, 1 << 30);
  }

  Future<void> _completeToday() async {
    final plan = _plan;
    if (plan == null) return;
    final dayNumber = _todayDayNumber();
    try {
      await ExamCoachService.instance.completeDay(plan.id, dayNumber);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    // Lot 9.7b : verrou sur le droit ai.feature.exam_coach (et plus sur une
    // maquette d'abonnement) ; le serveur refuse aussi (403) sans ce droit.
    final sub = SubscriptionScope.of(context);

    if (!sub.has(EntitlementKeys.examCoach)) {
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(
          backgroundColor: s.bg,
          elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: s.onStrong),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                      color: WinColors.warnBg, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline,
                      size: 40, color: WinColors.warn)),
              const SizedBox(height: 20),
              Text('Exam Coach',
                  style: WinType.displayS(s.onStrong),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                  context.l10n.studentCoachLocked,
                  style: WinType.bodyM(s.onMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              WinButton(context.l10n.studentCoachSeePlans,
                  block: true,
                  onTap: () => UpgradeSheet.show(context,
                      featureName: 'Exam Coach', requiredPlan: 'Standard')),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: s.onStrong),
            onPressed: () => Navigator.pop(context)),
        title: Text('Exam Coach', style: WinType.headlineS(s.onStrong)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_plan == null ? _buildSetup(s) : _buildDashboard(s)),
    );
  }

  Widget _buildSetup(WinScheme s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinAlert(
          context.l10n.studentCoachIntro,
          type: BadgeColor.teal,
          icon: Icons.auto_awesome_outlined,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          WinAlert(_error!, type: BadgeColor.error),
        ],
        const SizedBox(height: 24),
        Text(context.l10n.studentCoachTargetExam, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examTypes.entries.map((e) {
            final selected = _examType == e.key;
            return GestureDetector(
              onTap: () => setState(() => _examType = e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? s.primaryContainer : s.surface2,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                  border: Border.all(color: selected ? s.primary : s.outline),
                ),
                child: Text(e.key,
                    style: WinType.labelM(selected ? s.primary : s.onMuted)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.studentCoachExamDate, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        WinButton(
          _examDate == null
              ? context.l10n.studentCoachPickDate
              : '${_examDate!.day}/${_examDate!.month}/${_examDate!.year}',
          variant: WinButtonVariant.outline,
          icon: Icons.calendar_today_outlined,
          block: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) setState(() => _examDate = picked);
          },
        ),
        const SizedBox(height: 28),
        Text(context.l10n.studentCoachHoursPerDay, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 4),
        Text('${_hoursPerDay.toStringAsFixed(1)}h',
            style: WinType.archivo(
                size: 32, weight: FontWeight.w800, color: s.primary)),
        Slider(
          value: _hoursPerDay,
          min: 0.5,
          max: 6,
          divisions: 11,
          activeColor: s.primary,
          inactiveColor: s.outline2,
          onChanged: (v) => setState(() => _hoursPerDay = v),
        ),
        const SizedBox(height: 28),
        WinButton(
          _generating ? context.l10n.studentCoachGenerating : context.l10n.studentCoachGenerate,
          block: true,
          icon: Icons.auto_awesome_outlined,
          onTap: (_examDate == null || _generating) ? null : _generate,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildDashboard(WinScheme s) {
    final plan = _plan!;
    final parsed = _parsed;
    final days = plan.examDate.difference(DateTime.now()).inDays.clamp(0, 1 << 30);
    final todayNum = _todayDayNumber();
    final isTodayDone = plan.completedDays.any((d) => d.dayNumber == todayNum);

    final allDays = <Map<String, dynamic>>[];
    if (parsed != null) {
      for (final w in (parsed['weeks'] as List? ?? [])) {
        for (final d in ((w as Map)['days'] as List? ?? [])) {
          allDays.add(Map<String, dynamic>.from(d as Map));
        }
      }
    }
    final weekStart = ((todayNum - 1) ~/ 7) * 7 + 1;
    final weekDays =
        allDays.where((d) => (d['day'] as int) >= weekStart && (d['day'] as int) < weekStart + 7).toList();
    final totalActive = allDays.where((d) => d['activity_type'] != 'rest').length;
    final completionPct = totalActive == 0
        ? 0
        : (plan.completedDays.length / totalActive * 100).round().clamp(0, 100);
    final completedSet = plan.completedDays.map((d) => d.dayNumber).toSet();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        WinCard(
          bg: WinColors.ink800,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.school_outlined, size: 20, color: WinColors.teal400),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(plan.examType,
                      style: WinType.headlineS(WinColors.cream50))),
              WinBadge(context.l10n.studentCoachDaysLeft(days), color: BadgeColor.warn),
            ]),
            const SizedBox(height: 4),
            Text('${plan.examDate.day}/${plan.examDate.month}/${plan.examDate.year}',
                style: WinType.bodyS(WinColors.ink300)),
            const SizedBox(height: 12),
            WinProgressBar(completionPct.toDouble(), color: WinColors.teal400),
            const SizedBox(height: 4),
            Text(context.l10n.studentCoachCompletion(completionPct),
                style: WinType.labelM(WinColors.ink300)),
            const SizedBox(height: 4),
            Text(context.l10n.studentCoachReliability((plan.confidenceScore * 100).round()),
                style: WinType.labelM(WinColors.ink300)),
          ]),
        ),
        const SizedBox(height: 16),
        WinCard(
          bg: isTodayDone ? WinColors.successBg : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WinBadge(context.l10n.studentCoachTodayDay(todayNum)),
            const SizedBox(height: 8),
            if (!isTodayDone)
              WinButton(context.l10n.studentCoachMarkToday,
                  icon: Icons.check, block: true, onTap: _completeToday)
            else
              Row(children: [
                const Icon(Icons.check_circle, color: WinColors.success, size: 18),
                const SizedBox(width: 8),
                Text(context.l10n.studentCoachTodayDone),
              ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.studentCoachThisWeek, style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        if (weekDays.isEmpty)
          Text(context.l10n.studentCoachNoWeek,
              style: WinType.bodyM(s.onMuted))
        else
          ...weekDays.map((d) {
            final dayNum = d['day'] as int;
            final isDone = completedSet.contains(dayNum);
            final isToday = dayNum == todayNum;
            final isRest = d['activity_type'] == 'rest';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WinCard(
                bg: isDone
                    ? WinColors.successBg
                    : isToday
                        ? s.primary.withValues(alpha: 0.06)
                        : null,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? WinColors.success : s.surface2,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text('$dayNum',
                              style: WinType.labelS(s.onMuted)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(isRest ? context.l10n.studentCoachRest : (d['focus_area'] as String? ?? ''),
                            style: WinType.titleM(s.onStrong)),
                        if (!isRest)
                          Text('${d['duration_minutes'] ?? 0} min',
                              style: WinType.labelS(s.onMuted)),
                      ])),
                ]),
              ),
            );
          }),
        const SizedBox(height: 16),
        WinButton(context.l10n.studentCoachDeletePlan,
            variant: WinButtonVariant.outline,
            block: true,
            icon: Icons.delete_outline,
            onTap: _deletePlan),
      ],
    );
  }
}
