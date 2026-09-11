import 'package:flutter/material.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_booking_flow_screen.dart';

const _weekdayShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Fiche répétiteur publique (vue élève) — professeur_complete.md, section
/// "Fiche répétiteur (vue publique)".
class TutorPublicProfileScreen extends StatefulWidget {
  final int userId;
  const TutorPublicProfileScreen({super.key, required this.userId});

  @override
  State<TutorPublicProfileScreen> createState() => _TutorPublicProfileScreenState();
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
    setState(() { _loading = true; _error = false; });
    try {
      final profile = await TutorProfileService.instance.getPublicProfile(widget.userId);
      List<TutorAvailabilityOccurrence> occ = [];
      try {
        occ = await TutorBookingService.instance.getTwoWeekCalendar(widget.userId);
      } catch (_) {
        // La fiche reste consultable même si le calendrier échoue.
      }
      if (mounted) setState(() { _profile = profile; _occurrences = occ; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  void _openBooking({TutorAvailabilityOccurrence? preselected}) {
    final p = _profile;
    if (p == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TutorBookingFlowScreen(
        profile: p,
        occurrences: _occurrences,
        initialOccurrence: preselected,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final p = _profile;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profil du tuteur', style: WinType.headlineS(s.onStrong)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error || p == null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Impossible de charger ce profil.', style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  WinButton('Réessayer', onTap: _load),
                ]))
              : Column(children: [
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
                      child: WinButton('Réserver une séance', block: true,
                          icon: Icons.calendar_month_outlined,
                          onTap: () => _openBooking()),
                    ),
                  ),
                ]),
    );
  }

  Widget _buildBody(WinScheme s, TutorProfile p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WinAvatar(p.fullName ?? p.title ?? '?', size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.fullName ?? 'Tuteur WinPlus', style: WinType.archivo(size: 19, color: s.onStrong)),
              if ((p.title ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(p.title!, style: WinType.bodyM(s.onMuted)),
                ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (p.isDiplomaVerified) const WinBadge('Vérifié Diplôme', color: BadgeColor.success),
                const WinBadge('Avis bientôt disponibles', color: BadgeColor.neutral),
              ]),
            ]),
          ),
        ]),
        if ((p.tutorBio ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(p.tutorBio!, style: WinType.bodyM(s.onSurface)),
        ],
        if ((p.videoUrl ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionTitle('Vidéo de présentation'),
          const SizedBox(height: 8),
          WinCard(
            child: Row(children: [
              Icon(Icons.play_circle_outline, color: s.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.videoUrl!,
                    style: WinType.bodyS(s.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        const _SectionTitle('Tarifs & forfaits'),
        const SizedBox(height: 8),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p.hourlyRateXaf != null ? '${p.hourlyRateXaf} XAF' : 'Tarif non communiqué',
                  style: WinType.archivo(size: 20, color: s.onStrong)),
              if (p.hourlyRateXaf != null)
                Padding(padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text('/ heure', style: WinType.labelM(s.onMuted))),
            ]),
            if (p.trialSessionEnabled) ...[
              const SizedBox(height: 6),
              Text(
                (p.trialSessionPriceXaf ?? 0) == 0
                    ? 'Séance d\'essai gratuite'
                    : 'Séance d\'essai : ${p.trialSessionPriceXaf} XAF',
                style: WinType.labelM(WinColors.success),
              ),
            ],
            if (p.packages.isNotEmpty) ...[
              const SizedBox(height: 12),
              const WinDivider(),
              const SizedBox(height: 12),
              ...p.packages.where((pk) => pk.isActive).map((pk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: s.onFaint),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${pk.name} — ${pk.sessionsCount} séances', style: WinType.bodyS(s.onStrong))),
                      Text('${pk.totalPriceXaf} XAF', style: WinType.labelM(s.onStrong).copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  )),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Disponibilités (14 prochains jours)'),
        const SizedBox(height: 8),
        _AvailabilityCalendar(occurrences: _occurrences, onTapSlot: (occ) => _openBooking(preselected: occ)),
        const SizedBox(height: 16),
        const _SectionTitle('Matières & niveaux'),
        const SizedBox(height: 8),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Matières', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: p.subjects.isEmpty
                ? [Text('Non renseigné', style: WinType.bodyS(s.onFaint))]
                : p.subjects.map((sub) => WinBadge(sub, color: BadgeColor.teal)).toList()),
            const SizedBox(height: 12),
            Text('Niveaux', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: p.levels.isEmpty
                ? [Text('Non renseigné', style: WinType.bodyS(s.onFaint))]
                : p.levels.map((lvl) => WinBadge(lvl, color: BadgeColor.blue)).toList()),
          ]),
        ),
        const SizedBox(height: 100), // laisse la place au bouton sticky
      ],
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
  const _AvailabilityCalendar({required this.occurrences, required this.onTapSlot});

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
      o.date.year == day.year && o.date.month == day.month && o.date.day == day.day && o.isBookable);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (widget.occurrences.isEmpty) {
      return const WinAlert('Aucun créneau disponible pour le moment.', type: BadgeColor.neutral);
    }
    final daySlots = widget.occurrences.where((o) =>
        o.date.year == _selectedDay.year && o.date.month == _selectedDay.month && o.date.day == _selectedDay.day).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = _days[i];
            final active = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;
            final bookable = _dayHasBookable(day);
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? s.primary : (bookable ? WinColors.successBg : s.chipBg),
                  border: Border.all(color: active ? s.primary : s.outline),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_weekdayShort[day.weekday - 1],
                      style: WinType.labelS(active ? Colors.white : s.onMuted)),
                  const SizedBox(height: 2),
                  Text('${day.day}',
                      style: WinType.titleM(active ? Colors.white : (bookable ? WinColors.success : s.onStrong))),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      if (daySlots.isEmpty)
        Text('Aucun créneau ce jour-là.', style: WinType.bodyS(s.onFaint))
      else
        Wrap(spacing: 8, runSpacing: 8, children: daySlots.map((occ) {
          return GestureDetector(
            onTap: occ.isBookable ? () => widget.onTapSlot(occ) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: occ.isBookable ? WinColors.successBg : s.chipBg,
                border: Border.all(color: occ.isBookable ? WinColors.success : s.outline),
              ),
              child: Text('${occ.startTime} – ${occ.endTime}',
                  style: WinType.labelM(occ.isBookable ? WinColors.success : s.onFaint)),
            ),
          );
        }).toList()),
    ]);
  }
}
