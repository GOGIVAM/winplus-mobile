import '../../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../theme/win_motion.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_policy_widgets.dart';
import 'tutor_booking_flow_screen.dart';
import 'tutor_engagement_flow_screen.dart';
import 'tutor_pricing_widgets.dart';

/// Fiche répétiteur publique (vue élève)  professeur_complete.md, section
/// "Fiche répétiteur (vue publique)".
class TutorPublicProfileScreen extends StatefulWidget {
  final int userId;

  /// Sujets saisis dans la recherche (lot 9.1), repris dans la réservation.
  final List<String> initialTopics;

  /// Lot 9.3 : attribution active d'où l'on vient (bénéficiaires présélectionnés).
  final TutorAssignment? assignment;

  /// Lot 9.4 : ouvre directement l'engagement mensuel (depuis une attribution).
  final bool openMonthly;
  const TutorPublicProfileScreen(
      {super.key, required this.userId, this.initialTopics = const [], this.assignment, this.openMonthly = false});

  @override
  State<TutorPublicProfileScreen> createState() =>
      _TutorPublicProfileScreenState();
}

class _TutorPublicProfileScreenState extends State<TutorPublicProfileScreen> {
  TutorProfile? _profile;
  List<TutorAvailabilityOccurrence> _occurrences = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final profile =
          await TutorProfileService.instance.getPublicProfile(widget.userId);
      List<TutorAvailabilityOccurrence> occ = [];
      try {
        occ = await TutorBookingService.instance
            .getTwoWeekCalendar(widget.userId);
      } catch (_) {
        // La fiche reste consultable même si le calendrier échoue.
      }
      if (mounted)
        setState(() {
          _profile = profile;
          _occurrences = occ;
          _loading = false;
        });
      if (mounted && widget.openMonthly && profile.monthlyEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openEngagement());
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = true;
        });
    }
  }

  void _openBooking({TutorAvailabilityOccurrence? preselected}) {
    final p = _profile;
    if (p == null) return;
    Navigator.push(
        context,
        WinPageRoute(
          builder: (_) => TutorBookingFlowScreen(
            profile: p,
            occurrences: _occurrences,
            initialOccurrence: preselected,
            initialTopics: widget.initialTopics,
            assignment: widget.assignment,
          ),
        ));
  }

  /// Lot 9.4 : engagement mensuel (mêmes créneaux 4 semaines, payé d'avance).
  void _openEngagement() {
    final p = _profile;
    if (p == null) return;
    Navigator.push(
        context,
        WinPageRoute(
          builder: (_) => TutorEngagementFlowScreen(
            profile: p,
            initialTopics: widget.initialTopics,
            assignment: widget.assignment,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final p = _profile;

    return Scaffold(
      backgroundColor: s.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error || p == null
              ? SafeArea(
                  child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(children: [
                      WinCircleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context)),
                    ]),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.wifi_off_outlined,
                            size: 48, color: s.onFaint),
                        const SizedBox(height: 12),
                        Text(context.l10n.tutoringProfileLoadError,
                            style: WinType.bodyM(s.onMuted)),
                        const SizedBox(height: 12),
                        WinButton(context.l10n.commonRetry, onTap: _load),
                      ]),
                    ),
                  ),
                ]))
              : Column(children: [
                  _HeroHeader(profile: p, onBack: () => Navigator.pop(context)),
                  Expanded(child: _buildBody(s, p)),
                  // Bouton "Réserver" sticky en bas (professeur_complete.md).
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: s.bg,
                      border: Border(top: BorderSide(color: s.outline)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: WinButton(context.l10n.tutoringBookSession,
                          block: true,
                          icon: Icons.calendar_month_outlined,
                          onTap: () => _openBooking()),
                    ),
                  ),
                ]),
    );
  }

  Widget _buildBody(WinScheme s, TutorProfile p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        if ((p.tutorBio ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(p.tutorBio!, style: WinType.bodyM(s.onSurface)),
        ],
        if ((p.videoUrl ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle(context.l10n.tutoringIntroVideo),
          const SizedBox(height: 8),
          WinCard(
            child: Row(children: [
              Icon(Icons.play_circle_outline, color: s.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.videoUrl!,
                    style: WinType.bodyS(s.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        _SectionTitle(context.l10n.tutoringRatesPackages),
        const SizedBox(height: 8),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (p.rates.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 4, top: 6),
                    child:
                        Text(context.l10n.tutoringFrom, style: WinType.labelM(s.onMuted))),
              Text(
                  (p.fromHourlyRateXaf ?? p.hourlyRateXaf) != null
                      ? '${fmtXaf((p.fromHourlyRateXaf ?? p.hourlyRateXaf)!)} XAF'
                      : context.l10n.tutoringRateNotGiven,
                  style: WinType.archivo(size: 20, color: s.onStrong)),
              if ((p.fromHourlyRateXaf ?? p.hourlyRateXaf) != null)
                Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(context.l10n.tutoringPerHour, style: WinType.labelM(s.onMuted))),
            ]),
            if (p.rates.isNotEmpty ||
                p.rateModifiers.isNotEmpty ||
                p.durationDiscounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              TutorRateGridSummary(
                  rates: p.rates,
                  modifiers: p.rateModifiers,
                  discounts: p.durationDiscounts),
            ],
            TutorGroupPricingSummary(profile: p),
            if (p.trialSessionEnabled) ...[
              const SizedBox(height: 6),
              Text(
                (p.trialSessionPriceXaf ?? 0) == 0
                    ? context.l10n.tutoringTrialFree
                    : context.l10n.tutoringTrialPrice('${p.trialSessionPriceXaf}'),
                style: WinType.labelM(WinColors.success),
              ),
            ],
            // Lot 9.4 : l'offre mensuelle remplace les anciens forfaits (inertes).
            if (p.monthlyEnabled) ...[
              const SizedBox(height: 12),
              const WinDivider(),
              const SizedBox(height: 12),
              Text(context.l10n.tutoringEngStagePlan +
                  (p.monthlyDiscountPercent > 0 ? ' · ${context.l10n.tutoringPercent('-${p.monthlyDiscountPercent}')}' : ''),
                  style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 4),
              Text(context.l10n.tutoringMonthlyText,
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 8),
              WinButton(context.l10n.tutoringBookMonthly,
                  small: true,
                  variant: WinButtonVariant.outline,
                  icon: Icons.event_repeat_outlined,
                  onTap: _openEngagement),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        // Lot 9.2 (17.10) : réglages d'annulation effectifs, lien vers la
        // politique publique.
        _SectionTitle(context.l10n.tutoringCancellationPolicy),
        const SizedBox(height: 8),
        TutorCancellationPolicyCard(
          fullRefundHours: p.fullRefundHours,
          partialRefundPercent: p.partialRefundPercent,
          noRefundHours: p.noRefundHours,
        ),
        const SizedBox(height: 16),
        _SectionTitle(context.l10n.tutoringAvailability14),
        const SizedBox(height: 8),
        _AvailabilityCalendar(
            occurrences: _occurrences,
            onTapSlot: (occ) => _openBooking(preselected: occ)),
        const SizedBox(height: 16),
        _SectionTitle(context.l10n.tutoringSubjectsLevels),
        const SizedBox(height: 8),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.tutoringSubjects, style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 6),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.subjects.isEmpty
                    ? [Text(context.l10n.tutoringNotSpecified, style: WinType.bodyS(s.onFaint))]
                    : p.subjects
                        .map((sub) => WinBadge(sub, color: BadgeColor.teal))
                        .toList()),
            const SizedBox(height: 12),
            Text(context.l10n.tutoringLevels, style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 6),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.levels.isEmpty
                    ? [Text(context.l10n.tutoringNotSpecified, style: WinType.bodyS(s.onFaint))]
                    : p.levels
                        .map((lvl) => WinBadge(ClassLevels.label(lvl), color: BadgeColor.blue))
                        .toList()),
          ]),
        ),
        const SizedBox(height: 100), // laisse la place au bouton sticky
      ],
    );
  }
}

/// En-tête héros dégradé (identité du tuteur), même langage que les
/// bandeaux d'accueil des tableaux de bord et le panneau de connexion
/// remplace l'ancienne simple ligne avatar+texte en haut de liste.
class _HeroHeader extends StatelessWidget {
  final TutorProfile profile;
  final VoidCallback onBack;
  const _HeroHeader({required this.profile, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final p = profile;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.heroFrom, s.heroTo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WinCircleIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              WinAvatar(p.fullName ?? p.title ?? '?',
                  size: 72, color: WinColors.teal400),
              if (p.isInPersonVerified && !p.inPersonSuspended)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: WinColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: s.heroTo, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName ?? context.l10n.tutoringDefaultName,
                        style: WinType.archivo(
                            size: 19, color: WinColors.cream50)),
                    if ((p.title ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(p.title!,
                            style: WinType.bodyM(WinColors.ink200)),
                      ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      // Lot 9.5 (17.11) : présentiel, diplôme et caution en badges distincts.
                      if (p.isInPersonVerified && !p.inPersonSuspended)
                        WinBadge(context.l10n.tutoringInPersonVerified,
                            color: BadgeColor.success),
                      if (p.isDiplomaVerified)
                        WinBadge(context.l10n.tutoringDiplomaVerified,
                            color: BadgeColor.teal),
                      for (final n in p.endorsedByInstitutions)
                        WinBadge(context.l10n.tutoringEndorsedBy(n), color: BadgeColor.blue),
                      if (!p.inPersonAllowed)
                        WinBadge(context.l10n.tutoringOnlineOnly,
                            color: BadgeColor.neutral),
                      WinBadge(
                          p.averageRating != null && p.reviewCount > 0
                              ? context.l10n.tutoringRatingReviews(p.averageRating!.toStringAsFixed(1), p.reviewCount)
                              : context.l10n.tutoringNoReviewsYet,
                          color: BadgeColor.neutral),
                    ]),
                  ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Text(title, style: WinType.headlineS(s.onStrong));
  }
}

/// Calendrier horizontal 14 jours avec créneaux verts pour les jours ayant
/// au moins un créneau réservable (tap direct -> flow de réservation).
class _AvailabilityCalendar extends StatefulWidget {
  final List<TutorAvailabilityOccurrence> occurrences;
  final ValueChanged<TutorAvailabilityOccurrence> onTapSlot;
  const _AvailabilityCalendar(
      {required this.occurrences, required this.onTapSlot});

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = DateTime(today.year, today.month, today.day);
  }

  List<DateTime> get _days {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(14, (i) => start.add(Duration(days: i)));
  }

  bool _dayHasBookable(DateTime day) => widget.occurrences.any((o) =>
      o.date.year == day.year &&
      o.date.month == day.month &&
      o.date.day == day.day &&
      o.isBookable);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (widget.occurrences.isEmpty) {
      return WinAlert(context.l10n.tutoringNoSlotAvailable,
          type: BadgeColor.neutral);
    }
    final daySlots = widget.occurrences
        .where((o) =>
            o.date.year == _selectedDay.year &&
            o.date.month == _selectedDay.month &&
            o.date.day == _selectedDay.day)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = _days[i];
            final active = day.year == _selectedDay.year &&
                day.month == _selectedDay.month &&
                day.day == _selectedDay.day;
            final bookable = _dayHasBookable(day);
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? s.primary
                      : (bookable ? WinColors.successBg : s.chipBg),
                  borderRadius: BorderRadius.circular(WinRadii.sm),
                  border: Border.all(color: active ? s.primary : s.outline),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(WinFormat.weekdayShortCap(day.weekday),
                          style: WinType.labelS(
                              active ? Colors.white : s.onMuted)),
                      const SizedBox(height: 2),
                      Text('${day.day}',
                          style: WinType.titleM(active
                              ? Colors.white
                              : (bookable ? WinColors.success : s.onStrong))),
                    ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      if (daySlots.isEmpty)
        Text(context.l10n.tutoringNoSlotThatDay, style: WinType.bodyS(s.onFaint))
      else
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daySlots.map((occ) {
              return GestureDetector(
                onTap: occ.isBookable ? () => widget.onTapSlot(occ) : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: occ.isBookable ? WinColors.successBg : s.chipBg,
                    borderRadius: BorderRadius.circular(WinRadii.full),
                    border: Border.all(
                        color: occ.isBookable ? WinColors.success : s.outline),
                  ),
                  child: Text(occ.startTime,
                      style: WinType.labelM(
                          occ.isBookable ? WinColors.success : s.onFaint)),
                ),
              );
            }).toList()),
    ]);
  }
}
