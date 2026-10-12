import 'package:flutter/material.dart';

import '../services/tutor_profile_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

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
  static const _methods = {
    'none': 'Individuel seulement',
    'per_student': 'Prix par élève dégressif',
    'flat': 'Prix fixe pour le groupe',
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
          const SnackBar(content: Text('Choisis d\'abord tes matières.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final sug = await TutorProfileService.instance.suggestGroupPricing(subject, level: widget.level);
      if (!mounted) return;
      setState(() => _suggestion = sug);
      if (sug == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('WinAI n\'a pas pu proposer de réglages de groupe pour l\'instant.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('WinAI n\'a pas pu proposer de réglages de groupe pour l\'instant.')));
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
        Expanded(child: Text('Séances de groupe', style: WinType.labelM(s.onStrong))),
        TextButton.icon(
          onPressed: _loading ? null : _suggest,
          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
          label: Text(_loading ? 'WinAI réfléchit…' : 'Proposer (WinAI)'),
        ),
      ]),
      const SizedBox(height: 4),
      Text('Un parent, une institution ou un groupe d\'étude peut réserver pour plusieurs élèves. Une séance de groupe occupe ton créneau une seule fois.',
          style: WinType.labelS(s.onFaint)),
      if (_suggestion != null) ...[
        const SizedBox(height: 8),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                'Réglages proposés par WinAI'
                '${_suggestion!.marketData ? ' (d\'après ${_suggestion!.sampleSize} tuteurs)' : ' (estimation)'}',
                style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 6),
            Text('Taille maximale : ${_suggestion!.maxGroupSize} élèves', style: WinType.bodyS(s.onSurface)),
            ..._suggestion!.discounts.map((d) => Text(
                'Prix par élève, dès ${d.minGroupSize} élèves : −${d.percentDiscount} %',
                style: WinType.bodyS(s.onSurface))),
            Text('Ou prix fixe pour le groupe : ${_suggestion!.flatPercent} % du prix individuel',
                style: WinType.bodyS(s.onSurface)),
            const SizedBox(height: 6),
            Text(_suggestion!.explanation, style: WinType.labelS(s.onFaint)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              WinButton('Prix par élève', small: true, onTap: () => _apply('per_student')),
              WinButton('Prix fixe', small: true, variant: WinButtonVariant.outline, onTap: () => _apply('flat')),
              WinButton('Ignorer', small: true, variant: WinButtonVariant.outline,
                  onTap: () => setState(() => _suggestion = null)),
            ]),
          ]),
        ),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _methods.entries
            .map((e) => WinChip(e.value, active: value.method == e.key, onTap: () => onChanged(value.copyWith(method: e.key))))
            .toList(),
      ),
      if (value.method != 'none')
        stepper('Taille maximale du groupe (élèves)', value.maxGroupSize, 2, 20, (v) => onChanged(value.copyWith(maxGroupSize: v))),
      if (value.method == 'flat') ...[
        stepper('Prix du groupe (% du prix individuel)', value.flatPercent, 100, 1000,
            (v) => onChanged(value.copyWith(flatPercent: v)), step: 10),
        Text('Ex. 150 % : une séance individuelle à 6 000 XAF coûte 9 000 XAF pour le groupe, quel que soit le nombre d\'élèves.',
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
            Text('Dès ', style: WinType.bodyS(s.onSurface)),
            DropdownButton<int>(
              value: d.minGroupSize.clamp(2, value.maxGroupSize),
              items: sizes.where((n) => n <= value.maxGroupSize).map((n) => DropdownMenuItem(value: n, child: Text('$n élèves'))).toList(),
              onChanged: (n) => update(TutorGroupDiscount(minGroupSize: n ?? 2, percentDiscount: d.percentDiscount)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: stepper('−%', d.percentDiscount, 1, 70,
                  (v) => update(TutorGroupDiscount(minGroupSize: d.minGroupSize, percentDiscount: v)), step: 5),
            ),
            IconButton(
              tooltip: 'Supprimer ce palier',
              icon: Icon(Icons.delete_outline, color: s.onMuted),
              onPressed: () => onChanged(value.copyWith(discounts: [...value.discounts]..removeAt(i))),
            ),
          ]);
        }),
        if (value.discounts.length < 5)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un palier'),
            onPressed: () => onChanged(value.copyWith(discounts: [
              ...value.discounts,
              TutorGroupDiscount(
                  minGroupSize: (2 + value.discounts.length).clamp(2, value.maxGroupSize),
                  percentDiscount: 10 + value.discounts.length * 5),
            ])),
          ),
        Text('Seul le palier le plus haut atteint s\'applique. Sans palier, chaque élève paie le prix individuel.',
            style: WinType.labelS(s.onFaint)),
      ],
    ]);
  }
}
