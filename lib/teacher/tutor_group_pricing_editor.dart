import 'package:flutter/material.dart';

import '../services/tutor_profile_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Lot 9.3 (suivi 17.3) : séances de groupe. Le tuteur choisit sa méthode :
/// prix par élève dégressif selon la taille du groupe (paliers), ou prix fixe
/// pour le groupe (en % du prix individuel), avec une taille maximale. Le prix
/// réel est toujours calculé par le serveur (devis).
class GroupPricingValue {
  final String method; // none | per_student | flat
  final int maxGroupSize;
  final int flatPercent;
  final List<TutorGroupDiscount> discounts;
  const GroupPricingValue({
    this.method = 'none',
    this.maxGroupSize = 4,
    this.flatPercent = 150,
    this.discounts = const [],
  });

  factory GroupPricingValue.fromProfile(TutorProfile p) => GroupPricingValue(
        method: p.groupPricingMethod ?? 'none',
        maxGroupSize: p.groupPricingMethod != null && p.maxGroupSize >= 2 ? p.maxGroupSize : 4,
        flatPercent: p.groupFlatPricePercent ?? 150,
        discounts: p.groupDiscounts,
      );

  GroupPricingValue copyWith({String? method, int? maxGroupSize, int? flatPercent, List<TutorGroupDiscount>? discounts}) =>
      GroupPricingValue(
        method: method ?? this.method,
        maxGroupSize: maxGroupSize ?? this.maxGroupSize,
        flatPercent: flatPercent ?? this.flatPercent,
        discounts: discounts ?? this.discounts,
      );

  /// Champs envoyés au serveur, qui valide les bornes.
  Map<String, dynamic> toPayload() => {
        'updateGroupPricing': true,
        'groupPricingMethod': method,
        if (method != 'none') 'maxGroupSize': maxGroupSize,
        if (method == 'flat') 'groupFlatPricePercent': flatPercent,
        'groupDiscounts': method == 'per_student' ? discounts.map((d) => d.toJson()).toList() : [],
      };
}

class TutorGroupPricingEditor extends StatefulWidget {
  final GroupPricingValue value;
  final ValueChanged<GroupPricingValue> onChanged;

  /// Matière principale et niveau du tuteur, pour la suggestion WinAI (suivi 17.14).
  final String? subject;
  final String? level;
  const TutorGroupPricingEditor(
      {super.key, required this.value, required this.onChanged, this.subject, this.level});

  @override
  State<TutorGroupPricingEditor> createState() => _TutorGroupPricingEditorState();
}

class _TutorGroupPricingEditorState extends State<TutorGroupPricingEditor> {
  static const _methods = ['none', 'per_student', 'flat'];

  String _methodLabel(BuildContext context, String m) => switch (m) {
        'per_student' => context.l10n.teacherGroupMethodPerStudent,
        'flat' => context.l10n.teacherGroupMethodFlat,
        _ => context.l10n.teacherGroupMethodNone,
      };

  TutorGroupPricingSuggestion? _suggestion;
  bool _loading = false;

  GroupPricingValue get value => widget.value;
  ValueChanged<GroupPricingValue> get onChanged => widget.onChanged;

  // Suivi 17.14 : WinAI propose les réglages de groupe ; le tuteur les applique
  // puis les ajuste, le serveur revalide les bornes à l'enregistrement.
  Future<void> _suggest() async {
    final subject = widget.subject;
    if (subject == null || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.teacherGroupSubjectsFirst)));
      return;
    }
    setState(() => _loading = true);
    try {
      final sug = await TutorProfileService.instance.suggestGroupPricing(subject, level: widget.level);
      if (!mounted) return;
      setState(() => _suggestion = sug);
      if (sug == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherGroupSuggestError)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherGroupSuggestError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(String method) {
    final sug = _suggestion;
    if (sug == null) return;
    onChanged(GroupPricingValue(
      method: method,
      maxGroupSize: sug.maxGroupSize.clamp(2, 20),
      flatPercent: sug.flatPercent.clamp(100, 1000),
      discounts: sug.discounts,
    ));
    setState(() => _suggestion = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sizes = List.generate(19, (i) => i + 2);
    Widget stepper(String label, int v, int min, int max, ValueChanged<int> on, {int step = 1}) => Row(children: [
          Expanded(child: Text(label, style: WinType.bodyS(s.onSurface))),
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: v - step >= min ? () => on(v - step) : null),
          Text('$v', style: WinType.titleM(s.onStrong)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: v + step <= max ? () => on(v + step) : null),
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(context.l10n.teacherGroupTitle, style: WinType.labelM(s.onStrong))),
        TextButton.icon(
          onPressed: _loading ? null : _suggest,
          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
          label: Text(_loading ? context.l10n.commonWinaiThinking : context.l10n.teacherGroupSuggest),
        ),
      ]),
      const SizedBox(height: 4),
      Text(context.l10n.teacherGroupIntro,
          style: WinType.labelS(s.onFaint)),
      if (_suggestion != null) ...[
        const SizedBox(height: 8),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '${context.l10n.teacherGroupSuggested}'
                '${_suggestion!.marketData ? ' ${context.l10n.teacherGroupBasedOn(_suggestion!.sampleSize)}' : ' ${context.l10n.teacherGroupEstimate}'}',
                style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 6),
            Text(context.l10n.teacherGroupMaxSizeLine(_suggestion!.maxGroupSize), style: WinType.bodyS(s.onSurface)),
            ..._suggestion!.discounts.map((d) => Text(
                context.l10n.teacherGroupPerStudentLine(d.minGroupSize, d.percentDiscount),
                style: WinType.bodyS(s.onSurface))),
            Text(context.l10n.teacherGroupFlatLine(_suggestion!.flatPercent),
                style: WinType.bodyS(s.onSurface)),
            const SizedBox(height: 6),
            Text(_suggestion!.explanation, style: WinType.labelS(s.onFaint)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              WinButton(context.l10n.teacherGroupApplyPerStudent, small: true, onTap: () => _apply('per_student')),
              WinButton(context.l10n.teacherGroupApplyFlat, small: true, variant: WinButtonVariant.outline, onTap: () => _apply('flat')),
              WinButton(context.l10n.teacherPricingIgnore, small: true, variant: WinButtonVariant.outline,
                  onTap: () => setState(() => _suggestion = null)),
            ]),
          ]),
        ),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _methods
            .map((k) => WinChip(_methodLabel(context, k), active: value.method == k, onTap: () => onChanged(value.copyWith(method: k))))
            .toList(),
      ),
      if (value.method != 'none')
        stepper(context.l10n.teacherGroupMaxSizeLabel, value.maxGroupSize, 2, 20, (v) => onChanged(value.copyWith(maxGroupSize: v))),
      if (value.method == 'flat') ...[
        stepper(context.l10n.teacherGroupFlatLabel, value.flatPercent, 100, 1000,
            (v) => onChanged(value.copyWith(flatPercent: v)), step: 10),
        Text(context.l10n.teacherGroupFlatExample,
            style: WinType.labelS(s.onFaint)),
      ],
      if (value.method == 'per_student') ...[
        ...value.discounts.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          void update(TutorGroupDiscount nd) {
            final list = [...value.discounts];
            list[i] = nd;
            onChanged(value.copyWith(discounts: list));
          }

          return Row(children: [
            Text(context.l10n.teacherPricingFrom, style: WinType.bodyS(s.onSurface)),
            DropdownButton<int>(
              value: d.minGroupSize.clamp(2, value.maxGroupSize),
              items: sizes.where((n) => n <= value.maxGroupSize).map((n) => DropdownMenuItem(value: n, child: Text(context.l10n.teacherGroupStudents(n)))).toList(),
              onChanged: (n) => update(TutorGroupDiscount(minGroupSize: n ?? 2, percentDiscount: d.percentDiscount)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: stepper('−%', d.percentDiscount, 1, 70,
                  (v) => update(TutorGroupDiscount(minGroupSize: d.minGroupSize, percentDiscount: v)), step: 5),
            ),
            IconButton(
              tooltip: context.l10n.teacherPricingRemoveTier,
              icon: Icon(Icons.delete_outline, color: s.onMuted),
              onPressed: () => onChanged(value.copyWith(discounts: [...value.discounts]..removeAt(i))),
            ),
          ]);
        }),
        if (value.discounts.length < 5)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.l10n.teacherPricingAddTier),
            onPressed: () => onChanged(value.copyWith(discounts: [
              ...value.discounts,
              TutorGroupDiscount(
                  minGroupSize: (2 + value.discounts.length).clamp(2, value.maxGroupSize),
                  percentDiscount: 10 + value.discounts.length * 5),
            ])),
          ),
        Text(context.l10n.teacherGroupTierHint,
            style: WinType.labelS(s.onFaint)),
      ],
    ]);
  }
}
