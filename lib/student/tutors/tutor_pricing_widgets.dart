import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Briques du lot 9.1 (tarifs modulables, sujets de séance) partagées entre
/// la réservation côté élève, les demandes côté tuteur et la fiche publique.
/// Aucun calcul de prix ici : seuls des devis renvoyés par le serveur sont
/// affichés.

const int kMaxTopics = 5;
// Jour abrégé à partir d'un index 0 = dimanche … 6 = samedi.
String _dowShort(int x) => WinFormat.weekdayShort(x == 0 ? DateTime.sunday : x);

/// Montant groupé par milliers : « 8 000 » / « 8,000 ».
String fmtXaf(num n) => WinFormat.number(n);

String _signed(int p) => L10n.current.tutoringPercent(p > 0 ? '+$p' : '$p');

/// Détail d'un devis serveur : tranches au même tarif, dégressivité, total.
class TutorPriceBreakdownView extends StatelessWidget {
  final TutorPriceQuote quote;
  const TutorPriceBreakdownView({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    Widget line(String left, String right, {Color? color, String? hint}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(left, style: WinType.bodyS(color ?? s.onSurface)),
                    if (hint != null)
                      Text(hint, style: WinType.labelS(s.onFaint)),
                  ]),
            ),
            Text(right, style: WinType.bodyS(color ?? s.onSurface)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          '${context.l10n.tutoringBaseRate(fmtXaf(quote.baseHourlyRateXaf))}'
          '${quote.subject != null ? ' · ${quote.subject}' : ''}'
          ' · ${quote.modeCategory == 'online' ? context.l10n.tutoringModeOnlineLower : context.l10n.tutoringModeInPerson}',
          style: WinType.labelS(s.onMuted)),
      const SizedBox(height: 6),
      ...quote.segments.map((seg) => line(
            '${seg.startTime} – ${seg.endTime} (${formatDurationMinutes(seg.minutes)})',
            '${fmtXaf(seg.amountXaf)} XAF',
            hint: seg.modifierPercent != 0
                ? '${seg.modifierLabels.join(' + ')} ${_signed(seg.modifierPercent)} · ${fmtXaf(seg.effectiveHourlyRateXaf)} XAF / h'
                : null,
          )),
      if (quote.durationDiscountPercent > 0) ...[
        line(context.l10n.tutoringSubtotal, '${fmtXaf(quote.subtotalXaf)} XAF',
            color: s.onMuted),
        line(context.l10n.tutoringLongSession(quote.durationDiscountPercent),
            '−${fmtXaf(quote.durationDiscountXaf)} XAF',
            color: WinColors.success),
      ],
      // Lot 9.3 : prix de groupe, appliqué au prix individuel.
      if (quote.isGroup) ...[
        line(context.l10n.tutoringSoloPrice, '${fmtXaf(quote.soloTotalXaf)} XAF', color: s.onMuted),
        if (quote.groupPricingMethod == 'flat')
          line(context.l10n.tutoringGroupFlat(quote.participantCount), '${fmtXaf(quote.totalXaf)} XAF',
              hint: context.l10n.tutoringGroupFlatHint(quote.groupFlatPercent ?? 100, fmtXaf(quote.perStudentXaf)))
        else
          line(context.l10n.tutoringPerStudentLine(quote.participantCount, fmtXaf(quote.perStudentXaf)), '${fmtXaf(quote.totalXaf)} XAF',
              color: quote.groupDiscountPercent > 0 ? WinColors.success : null,
              hint: quote.groupDiscountPercent > 0 ? context.l10n.tutoringGroupDiscount(quote.groupDiscountPercent) : null),
      ],
      const SizedBox(height: 4),
      const WinDivider(),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: Text(quote.isGroup ? context.l10n.tutoringTotalGroup : context.l10n.tutoringTotal, style: WinType.titleM(s.onStrong))),
        Text('${fmtXaf(quote.totalXaf)} XAF',
            style: WinType.titleM(s.onStrong)),
      ]),
    ]);
  }
}

/// Saisie des sujets à travailler (5 au plus, 100 caractères chacun).
class TopicsField extends StatefulWidget {
  final List<String> topics;
  final ValueChanged<List<String>> onChanged;
  final String? hint;
  const TopicsField({
    super.key,
    required this.topics,
    required this.onChanged,
    this.hint,
  });

  @override
  State<TopicsField> createState() => _TopicsFieldState();
}

class _TopicsFieldState extends State<TopicsField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final parts = _ctrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.length > 100 ? t.substring(0, 100) : t);
    final next = [...widget.topics];
    for (final p in parts) {
      if (next.length >= kMaxTopics) break;
      if (!next.any((t) => t.toLowerCase() == p.toLowerCase())) next.add(p);
    }
    _ctrl.clear();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.topics.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.topics
              .map((t) => InputChip(
                    label: Text(t, style: WinType.labelM(s.onSurface)),
                    onDeleted: () => widget.onChanged(
                        widget.topics.where((x) => x != t).toList()),
                  ))
              .toList(),
        ),
      if (widget.topics.length < kMaxTopics) ...[
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
              decoration: InputDecoration(
                hintText: widget.topics.isEmpty ? (widget.hint ?? context.l10n.tutoringTopicsPlaceholder) : context.l10n.tutoringAnotherTopic,
                counterText: '',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WinRadii.sm)),
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.tutoringAddTopic,
            icon: Icon(Icons.add_circle_outline, color: s.primary),
            onPressed: _commit,
          ),
        ]),
      ],
    ]);
  }
}

/// Liste de sujets en lecture seule ; [highlight] pour une correspondance.
class TopicChipsRow extends StatelessWidget {
  final List<String> topics;
  final bool highlight;
  const TopicChipsRow(this.topics, {super.key, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: topics
          .map((t) => WinBadge(t,
              color: highlight ? BadgeColor.success : BadgeColor.neutral))
          .toList(),
    );
  }
}

/// Méthode de prix de groupe du tuteur (lot 9.3), sur la fiche publique.
class TutorGroupPricingSummary extends StatelessWidget {
  final TutorProfile profile;
  const TutorGroupPricingSummary({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (profile.effectiveMaxGroupSize < 2) return const SizedBox.shrink();
    final lines = <String>[
      context.l10n.tutoringGroupUpTo('${profile.maxGroupSize}'),
      if (profile.groupPricingMethod == 'flat')
        context.l10n.tutoringGroupFlatSummary(profile.groupFlatPricePercent ?? 100)
      else if (profile.groupDiscounts.isEmpty)
        context.l10n.tutoringGroupEachPays
      else
        ...profile.groupDiscounts.map((d) => context.l10n.tutoringGroupFromSize(d.minGroupSize, d.percentDiscount)),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $l', style: WinType.bodyS(s.onSurface)),
                ))
            .toList(),
      ),
    );
  }
}

/// Lecture de la grille d'un tuteur (fiche publique, aperçu tuteur).
class TutorRateGridSummary extends StatelessWidget {
  final List<TutorRate> rates;
  final List<TutorRateModifier> modifiers;
  final List<TutorDurationDiscount> discounts;
  const TutorRateGridSummary(
      {super.key,
      this.rates = const [],
      this.modifiers = const [],
      this.discounts = const []});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (rates.isEmpty && modifiers.isEmpty && discounts.isEmpty) {
      return const SizedBox.shrink();
    }
    String modeLabel(String? m) => m == 'online'
        ? context.l10n.tutoringModeOnlineLower
        : m == 'in_person'
            ? context.l10n.tutoringModeInPerson
            : context.l10n.tutoringModeAll;
    String days(List<int> d) => d.isEmpty || d.length == 7
        ? context.l10n.tutoringEveryDay
        : d.map(_dowShort).join(' ');
    final lines = <String>[
      ...rates.map((r) =>
          context.l10n.tutoringRateLine(r.subject ?? context.l10n.tutoringAllSubjects, modeLabel(r.mode), fmtXaf(r.hourlyRateXaf))),
      ...modifiers.map((m) =>
          context.l10n.tutoringModifierLine(m.label, '${days(m.daysOfWeek)}${m.startTime != null ? ', ${m.startTime}–${m.endTime}' : ''}', _signed(m.percentAdjustment))),
      ...discounts.map((d) =>
          context.l10n.tutoringFromDuration(formatDurationMinutes(d.minDurationMinutes), d.percentDiscount)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $l', style: WinType.bodyS(s.onSurface)),
          )),
      Text(context.l10n.tutoringProrata,
          style: WinType.labelS(s.onFaint)),
    ]);
  }
}
