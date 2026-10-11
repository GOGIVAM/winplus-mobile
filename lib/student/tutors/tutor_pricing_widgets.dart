import 'package:flutter/material.dart';

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
const _dowShort = ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.'];

String fmtXaf(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _signed(int p) => p > 0 ? '+$p %' : '$p %';

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
          'Tarif de base : ${fmtXaf(quote.baseHourlyRateXaf)} XAF / h'
          '${quote.subject != null ? ' · ${quote.subject}' : ''}'
          ' · ${quote.modeCategory == 'online' ? 'en ligne' : 'présentiel'}',
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
        line('Sous-total', '${fmtXaf(quote.subtotalXaf)} XAF',
            color: s.onMuted),
        line('Séance longue (−${quote.durationDiscountPercent} %)',
            '−${fmtXaf(quote.durationDiscountXaf)} XAF',
            color: WinColors.success),
      ],
      const SizedBox(height: 4),
      const WinDivider(),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: Text('Total', style: WinType.titleM(s.onStrong))),
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
  final String hint;
  const TopicsField({
    super.key,
    required this.topics,
    required this.onChanged,
    this.hint = 'Ex. équations du second degré',
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
                hintText: widget.topics.isEmpty ? widget.hint : 'Autre sujet…',
                counterText: '',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WinRadii.sm)),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Ajouter ce sujet',
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
        ? 'en ligne'
        : m == 'in_person'
            ? 'présentiel'
            : 'tous modes';
    String days(List<int> d) => d.isEmpty || d.length == 7
        ? 'tous les jours'
        : d.map((x) => _dowShort[x]).join(' ');
    final lines = <String>[
      ...rates.map((r) =>
          '${r.subject ?? 'Toutes matières'} · ${modeLabel(r.mode)} : ${fmtXaf(r.hourlyRateXaf)} XAF / h'),
      ...modifiers.map((m) =>
          '${m.label} (${days(m.daysOfWeek)}${m.startTime != null ? ', ${m.startTime}–${m.endTime}' : ''}) : ${_signed(m.percentAdjustment)}'),
      ...discounts.map((d) =>
          'À partir de ${formatDurationMinutes(d.minDurationMinutes)} : −${d.percentDiscount} %'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $l', style: WinType.bodyS(s.onSurface)),
          )),
      Text('Facturation au prorata des tranches de 30 min.',
          style: WinType.labelS(s.onFaint)),
    ]);
  }
}
