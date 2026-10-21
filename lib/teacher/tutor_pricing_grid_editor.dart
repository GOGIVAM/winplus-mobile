import 'package:flutter/material.dart';

import '../services/tutor_booking_service.dart';
import '../services/tutor_profile_service.dart';
import '../student/tutors/tutor_pricing_widgets.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Grille tarifaire du tuteur (lot 9.1, suivi 17.3), parité avec le web :
/// tarif de base par matière et par mode, modulation par créneau,
/// dégressivité selon la durée, suggestion WinAI. Composant contrôlé : la
/// grille part avec l'étape « Tarifs » de TutorProfileScreen et le serveur
/// la valide. Aucun prix n'est calculé ici.
class TutorPricingGrid {
  final List<TutorRate> rates;
  final List<TutorRateModifier> modifiers;
  final List<TutorDurationDiscount> discounts;
  const TutorPricingGrid(
      {this.rates = const [],
      this.modifiers = const [],
      this.discounts = const []});

  Map<String, dynamic> toPayload() => {
        'rates': rates.map((r) => r.toJson()).toList(),
        'rateModifiers': modifiers.map((m) => m.toJson()).toList(),
        'durationDiscounts': discounts.map((d) => d.toJson()).toList(),
      };
}

class TutorPricingGridEditor extends StatefulWidget {
  final TutorPricingGrid value;
  final ValueChanged<TutorPricingGrid> onChanged;
  final List<String> subjects;
  final bool offersOnline;
  final bool offersInPerson;
  final String? level;
  const TutorPricingGridEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.subjects,
    required this.offersOnline,
    required this.offersInPerson,
    this.level,
  });

  @override
  State<TutorPricingGridEditor> createState() => _TutorPricingGridEditorState();
}

/// Initiale du jour (0 = dimanche … 6 = samedi) : « D », « L »… / « S », « M »…
String _dayShort(int d) =>
    WinFormat.weekdayCap(d == 0 ? DateTime.sunday : d).substring(0, 1);
final _timeOptions = [
  for (var i = 0; i < 48; i++)
    '${(i ~/ 2).toString().padLeft(2, '0')}:${i.isOdd ? '30' : '00'}',
  '24:00',
];
const _durationOptions = [60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360];

class _TutorPricingGridEditorState extends State<TutorPricingGridEditor> {
  bool _loading = false;
  TutorRateGridSuggestion? _suggestion;
  // Change quand la grille est remplacée d'un bloc (suggestion WinAI) pour
  // reconstruire les champs texte avec leurs nouvelles valeurs.
  int _gen = 0;

  TutorPricingGrid get _g => widget.value;
  void _emit(
          {List<TutorRate>? rates,
          List<TutorRateModifier>? modifiers,
          List<TutorDurationDiscount>? discounts}) =>
      widget.onChanged(TutorPricingGrid(
          rates: rates ?? _g.rates,
          modifiers: modifiers ?? _g.modifiers,
          discounts: discounts ?? _g.discounts));

  List<String> get _modes => [
        if (widget.offersOnline) 'online',
        if (widget.offersInPerson) 'in_person',
      ];

  Future<void> _suggest() async {
    if (widget.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.teacherPricingSubjectsFirst)));
      return;
    }
    setState(() => _loading = true);
    try {
      final g = await TutorProfileService.instance.suggestRateGrid(
          widget.subjects, _modes.isEmpty ? ['online'] : _modes,
          level: widget.level);
      if (mounted) setState(() => _suggestion = g);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherPricingSuggestError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply() {
    final g = _suggestion;
    if (g == null) return;
    setState(() {
      _suggestion = null;
      _gen++;
    });
    widget.onChanged(TutorPricingGrid(
        rates: g.rates, modifiers: g.modifiers, discounts: g.discounts));
  }

  String _modeLabel(String? m) => m == 'online'
      ? context.l10n.commonOnline
      : m == 'in_person'
          ? context.l10n.teacherPricingInPerson
          : context.l10n.teacherPricingAllModes;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    InputDecoration deco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm)));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.teacherPricingGridTitle, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 4),
      Text(
          context.l10n.teacherPricingGridIntro,
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 8),
      WinButton(_loading ? context.l10n.commonWinaiThinking : context.l10n.teacherPricingSuggest,
          variant: WinButtonVariant.outline,
          small: true,
          icon: Icons.auto_awesome,
          onTap: _loading ? null : _suggest),
      if (_suggestion != null) ...[
        const SizedBox(height: 10),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.teacherPricingSuggested,
                style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 6),
            TutorRateGridSummary(
                rates: _suggestion!.rates,
                modifiers: _suggestion!.modifiers,
                discounts: _suggestion!.discounts),
            const SizedBox(height: 6),
            Text(_suggestion!.explanation, style: WinType.labelS(s.onMuted)),
            const SizedBox(height: 8),
            Row(children: [
              WinButton(context.l10n.studentCatalogApply, small: true, onTap: _apply),
              const SizedBox(width: 8),
              WinButton(context.l10n.teacherPricingIgnore,
                  small: true,
                  variant: WinButtonVariant.ghost,
                  onTap: () => setState(() => _suggestion = null)),
            ]),
          ]),
        ),
      ],

      // ── Tarifs de base ────────────────────────────────────────────────
      const SizedBox(height: 16),
      Text(context.l10n.teacherPricingBaseTitle,
          style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 6),
      ..._g.rates.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        void update(TutorRate nr) {
          final list = [..._g.rates];
          list[i] = nr;
          _emit(rates: list);
        }

        final subjectOptions = {...widget.subjects, if (r.subject != null) r.subject!};
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('rs-$_gen-$i'),
                initialValue: r.subject,
                isExpanded: true,
                decoration: deco(context.l10n.commonSubject),
                items: [
                  DropdownMenuItem<String?>(
                      value: null, child: Text(context.l10n.tutoringAllSubjects)),
                  ...subjectOptions.map((sub) => DropdownMenuItem<String?>(
                      value: sub,
                      child: Text(sub, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => update(v == null
                    ? r.copyWith(clearSubject: true)
                    : r.copyWith(subject: v)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('rm-$_gen-$i'),
                initialValue: r.mode,
                isExpanded: true,
                decoration: deco(context.l10n.tutoringMode),
                items: [null, 'online', 'in_person']
                    .map((m) => DropdownMenuItem<String?>(
                        value: m, child: Text(_modeLabel(m))))
                    .toList(),
                onChanged: (v) => update(
                    v == null ? r.copyWith(clearMode: true) : r.copyWith(mode: v)),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 86,
              child: TextFormField(
                key: ValueKey('rate-$_gen-$i'),
                initialValue:
                    r.hourlyRateXaf > 0 ? r.hourlyRateXaf.toString() : '',
                keyboardType: TextInputType.number,
                decoration: deco('XAF/h'),
                onChanged: (v) =>
                    update(r.copyWith(hourlyRateXaf: num.tryParse(v) ?? 0)),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.teacherPricingRemoveRate,
                onPressed: () {
                  setState(() => _gen++);
                  _emit(rates: [..._g.rates]..removeAt(i));
                }),
          ]),
        );
      }),
      WinButton(context.l10n.teacherPricingAddRate,
          variant: WinButtonVariant.outline,
          small: true,
          onTap: () => _emit(rates: [
                ..._g.rates,
                TutorRate(
                    subject: widget.subjects.isNotEmpty
                        ? widget.subjects.first
                        : null,
                    mode: _modes.isNotEmpty ? _modes.first : null,
                    hourlyRateXaf: 0),
              ])),

      // ── Modulations ───────────────────────────────────────────────────
      const SizedBox(height: 16),
      Text(context.l10n.teacherPricingModTitle, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 4),
      Text(context.l10n.teacherPricingModExample,
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 6),
      ..._g.modifiers.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        void update(TutorRateModifier nm) {
          final list = [..._g.modifiers];
          list[i] = nm;
          _emit(modifiers: list);
        }

        TutorRateModifier copy(
                {String? label,
                List<int>? days,
                String? start,
                String? end,
                bool allDay = false,
                int? percent}) =>
            TutorRateModifier(
              label: label ?? m.label,
              daysOfWeek: days ?? m.daysOfWeek,
              startTime: allDay ? null : (start ?? m.startTime),
              endTime: allDay ? null : (end ?? m.endTime),
              percentAdjustment: percent ?? m.percentAdjustment,
            );

        return WinCard(
          padding: const EdgeInsets.all(10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('mod-label-$_gen-$i'),
                  initialValue: m.label,
                  maxLength: 60,
                  decoration: deco(context.l10n.teacherPricingModName).copyWith(counterText: ''),
                  onChanged: (v) => update(copy(label: v)),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextFormField(
                  key: ValueKey('mod-pct-$_gen-$i'),
                  initialValue: m.percentAdjustment.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: deco('%'),
                  onChanged: (v) =>
                      update(copy(percent: int.tryParse(v) ?? 0)),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.teacherPricingRemoveMod,
                  onPressed: () {
                    setState(() => _gen++);
                    _emit(modifiers: [..._g.modifiers]..removeAt(i));
                  }),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: List.generate(7, (d) {
                final on = m.daysOfWeek.contains(d);
                return FilterChip(
                  label: Text(_dayShort(d)),
                  selected: on,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => update(copy(
                      days: on
                          ? m.daysOfWeek.where((x) => x != d).toList()
                          : ([...m.daysOfWeek, d]..sort()))),
                );
              }),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('ms-$_gen-$i'),
                  initialValue: m.startTime,
                  isExpanded: true,
                  decoration: deco(context.l10n.tutoringEngStart),
                  items: [
                    DropdownMenuItem<String?>(
                        value: null, child: Text(context.l10n.teacherPricingAllDay)),
                    ..._timeOptions.take(48).map((t) =>
                        DropdownMenuItem<String?>(value: t, child: Text(t))),
                  ],
                  onChanged: (v) => update(v == null
                      ? copy(allDay: true)
                      : copy(
                          start: v,
                          end: (m.endTime != null && m.endTime!.compareTo(v) > 0)
                              ? m.endTime
                              : '24:00')),
                ),
              ),
              if (m.startTime != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('me-$_gen-$i-${m.startTime}'),
                    initialValue: m.endTime,
                    isExpanded: true,
                    decoration: deco(context.l10n.teacherPricingEnd),
                    items: _timeOptions
                        .where((t) => t.compareTo(m.startTime!) > 0)
                        .map((t) =>
                            DropdownMenuItem<String>(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => update(copy(end: v)),
                  ),
                ),
              ],
            ]),
          ]),
        );
      }),
      if (_g.modifiers.length < 10) ...[
        const SizedBox(height: 6),
        WinButton(context.l10n.teacherPricingAddMod,
            variant: WinButtonVariant.outline,
            small: true,
            onTap: () => _emit(modifiers: [
                  ..._g.modifiers,
                  const TutorRateModifier(
                      label: 'Soir',
                      daysOfWeek: [1, 2, 3, 4, 5],
                      startTime: '18:00',
                      endTime: '21:00',
                      percentAdjustment: 10),
                ])),
      ],

      // ── Dégressivité ──────────────────────────────────────────────────
      const SizedBox(height: 16),
      Text(context.l10n.teacherPricingDurTitle, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 4),
      Text(context.l10n.teacherPricingDurHint,
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 6),
      ..._g.discounts.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        void update(TutorDurationDiscount nd) {
          final list = [..._g.discounts];
          list[i] = nd;
          _emit(discounts: list);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text(context.l10n.teacherPricingFrom, style: WinType.bodyS(s.onMuted)),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('dd-$_gen-$i'),
                initialValue: _durationOptions.contains(d.minDurationMinutes)
                    ? d.minDurationMinutes
                    : null,
                isExpanded: true,
                decoration: deco(context.l10n.commonDuration),
                items: _durationOptions
                    .map((m) => DropdownMenuItem<int>(
                        value: m, child: Text(formatDurationMinutes(m))))
                    .toList(),
                onChanged: (v) => update(TutorDurationDiscount(
                    minDurationMinutes: v ?? d.minDurationMinutes,
                    percentDiscount: d.percentDiscount)),
              ),
            ),
            const SizedBox(width: 6),
            Text('−', style: WinType.bodyS(s.onMuted)),
            SizedBox(
              width: 60,
              child: TextFormField(
                key: ValueKey('disc-$_gen-$i'),
                initialValue: d.percentDiscount.toString(),
                keyboardType: TextInputType.number,
                decoration: deco('%'),
                onChanged: (v) => update(TutorDurationDiscount(
                    minDurationMinutes: d.minDurationMinutes,
                    percentDiscount: int.tryParse(v) ?? 0)),
              ),
            ),
            Text(' %', style: WinType.bodyS(s.onMuted)),
            IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.teacherPricingRemoveTier,
                onPressed: () {
                  setState(() => _gen++);
                  _emit(discounts: [..._g.discounts]..removeAt(i));
                }),
          ]),
        );
      }),
      if (_g.discounts.length < 5)
        WinButton(context.l10n.teacherPricingAddTierPlus,
            variant: WinButtonVariant.outline,
            small: true,
            onTap: () => _emit(discounts: [
                  ..._g.discounts,
                  TutorDurationDiscount(
                      minDurationMinutes:
                          (120 + _g.discounts.length * 60).clamp(60, 360),
                      percentDiscount: 5),
                ])),
    ]);
  }
}
