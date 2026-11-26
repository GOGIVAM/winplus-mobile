import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../theme/win_motion.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_public_profile_screen.dart';
import 'tutor_pricing_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/win_screen.dart';
import '../../shared/tutor_ref_picker.dart';

List<(String, String)> get _tutorModes => [
  ('online', L10n.current.commonOnline),
  // Lot 9.5 (17.11) : tout mode présentiel ne renvoie que des tuteurs vérifiés.
  ('in_person', L10n.current.tutoringFilterInPerson),
  ('student_home', L10n.current.tutoringFilterStudentHome),
  ('tutor_home', L10n.current.tutoringModeTutorHome),
  ('neutral_place', L10n.current.tutoringFilterNeutralPlace),
];
const _tutorCities = ['Douala', 'Yaoundé'];

/// Recherche de répétiteurs (Module 1  côté élève, professeur_complete.md).
class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({super.key});
  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> {
  String? _subject;
  String? _level;
  bool _verifiedOnly = false;
  String? _mode;
  String? _city;
  bool _availableSoon = false;
  // Réglages de la feuille « Trier et filtrer ».
  num? _maxRate;
  double? _minRating;
  String? _sort;
  // Sujets de séance (lot 9.1, 17.5) : classent les tuteurs côté serveur et
  // sont repris dans la réservation.
  List<String> _topics = [];
  bool _loading = true;
  bool _error = false;
  List<TutorSearchResult> _results = [];
  // Suivi 17.14 (parité web) : répétiteurs attribués à l'élève, ou par ce
  // parent / cette institution, proposés en tête de la recherche.
  List<TutorAssignment> _assigned = [];

  @override
  void initState() {
    super.initState();
    _loadAssigned();
    _search();
  }

  Future<void> _loadAssigned() async {
    try {
      final ctx = await TutorBookingService.instance.getBookingContext();
      if (mounted) setState(() => _assigned = ctx.activeAssignments.where((a) => a.isActive).toList());
    } catch (_) {
      // Sans contexte (hors ligne, invité) : recherche simple.
    }
  }

  TutorAssignment? _assignmentFor(int tutorUserId) =>
      _assigned.where((a) => a.tutorUserId == tutorUserId).firstOrNull;

  /// Résultats avec les tuteurs attribués en premier (ordre serveur conservé sinon).
  List<TutorSearchResult> get _ordered {
    if (_assigned.isEmpty) return _results;
    final ids = _assigned.map((a) => a.tutorUserId).toSet();
    return [..._results.where((r) => ids.contains(r.userId)), ..._results.where((r) => !ids.contains(r.userId))];
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await TutorProfileService.instance.search(
        subject: _subject,
        level: _level,
        verifiedOnly: _verifiedOnly ? true : null,
        mode: _mode,
        city: _city,
        availableSoon: _availableSoon ? true : null,
        maxHourlyRateXaf: _maxRate,
        minRating: _minRating,
        sort: _sort,
        topics: _topics,
        pageSize: 30,
      );
      if (mounted)
        setState(() {
          _results = results;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = true;
        });
    }
  }

  /// Matière choisie dans la liste commune du tutorat.
  Future<void> _pickSubject() async {
    final ref = await TutorProfileService.instance.referential();
    if (!mounted) return;
    final l = context.l10n;
    final r = await showTutorRefPicker(context,
        title: l.tutoringPickSubjectTitle,
        sections: [
          (l.instCycleSecondary, ref.secondarySubjects),
          (l.instCycleHigher, ref.superiorSubjects),
        ],
        selected: {if (_subject != null) _subject!},
        labelOf: tutorSubjectLabel,
        noneLabel: l.tutoringAllSubjects);
    if (r == null || !mounted) return;
    setState(() => _subject = r.firstOrNull);
    _search();
  }

  Future<void> _pickLevel() async {
    final ref = await TutorProfileService.instance.referential();
    if (!mounted) return;
    final l = context.l10n;
    final r = await showTutorRefPicker(context,
        title: l.tutoringPickLevelTitle,
        sections: [
          (l.instCycleSecondary, ref.secondaryLevels),
          (l.instCycleHigher, ref.superiorLevels),
        ],
        selected: {if (_level != null) _level!},
        labelOf: tutorLevelLabel,
        noneLabel: l.tutoringAllLevels);
    if (r == null || !mounted) return;
    setState(() => _level = r.firstOrNull);
    _search();
  }

  /// Nombre de réglages actifs dans « Trier et filtrer ».
  int get _extraCount =>
      (_maxRate != null ? 1 : 0) +
      (_minRating != null ? 1 : 0) +
      (_sort != null ? 1 : 0);

  /// Tri, tarif maximum et note minimale ; la recherche repart à la fermeture.
  Future<void> _openSortFilter() async {
    final l = context.l10n;
    await showWinBottomSheet<void>(
      context: context,
      title: l.tutoringSortFilter,
      child: StatefulBuilder(builder: (c, setSheet) {
        final s = WinTheme.of(c);
        void set(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        Widget title(String t) => Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Text(t, style: WinType.labelM(s.onMuted)));
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.tutoringSortBy, style: WinType.labelM(s.onMuted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (value, label) in <(String?, String)>[
                  (null, l.tutoringSortRelevance),
                  ('price-asc', l.tutoringSortPriceAsc),
                  ('price-desc', l.tutoringSortPriceDesc),
                  ('next-slot', l.tutoringSortNextSlot),
                ])
                  WinChip(label,
                      active: _sort == value,
                      onTap: () => set(() => _sort = value)),
              ]),
              title(l.tutoringMaxRate),
              Wrap(spacing: 8, runSpacing: 8, children: [
                WinChip(l.tutoringAnyRate,
                    active: _maxRate == null,
                    onTap: () => set(() => _maxRate = null)),
                for (final v in const [2000, 3000, 5000, 10000])
                  WinChip(l.tutoringMaxRateValue(fmtXaf(v)),
                      active: _maxRate == v,
                      onTap: () => set(() => _maxRate = v)),
              ]),
              title(l.tutoringMinRating),
              Wrap(spacing: 8, runSpacing: 8, children: [
                WinChip(l.tutoringAnyRating,
                    active: _minRating == null,
                    onTap: () => set(() => _minRating = null)),
                for (final v in const [3.0, 4.0, 4.5])
                  WinChip(l.tutoringMinRatingValue(WinFormat.decimal(v)),
                      active: _minRating == v,
                      icon: PhosphorIconsRegular.star,
                      onTap: () => set(() => _minRating = v)),
              ]),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: WinButton(l.tutoringShowResults,
                    block: true, onTap: () => Navigator.pop(c)),
              ),
            ]);
      }),
    );
    if (mounted) _search();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.studentTabsFindTutor),
        actions: [
          IconButton(
            tooltip: l.tutoringSortFilter,
            onPressed: _openSortFilter,
            icon: Badge(
              isLabelVisible: _extraCount > 0,
              label: Text('$_extraCount'),
              child: Icon(PhosphorIconsRegular.slidersHorizontal,
                  color: s.onStrong),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TopicsField(
            topics: _topics,
            hint: context.l10n.tutoringSearchTopicsHint,
            onChanged: (t) {
              setState(() => _topics = t);
              _search();
            },
          ),
        ),
        // Matière et niveau se choisissent dans la liste commune du tutorat.
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              WinChip(
                  _subject == null
                      ? l.tutoringAllSubjects
                      : tutorSubjectLabel(_subject!),
                  active: _subject != null,
                  icon: PhosphorIconsRegular.bookOpen,
                  onTap: _pickSubject),
              const SizedBox(width: 8),
              WinChip(
                  _level == null ? l.tutoringAllLevels : tutorLevelLabel(_level!),
                  active: _level != null,
                  icon: PhosphorIconsRegular.graduationCap,
                  onTap: _pickLevel),
              const SizedBox(width: 8),
              WinChip(l.tutoringDiplomaVerified,
                  active: _verifiedOnly,
                  icon: PhosphorIconsRegular.sealCheck, onTap: () {
                setState(() => _verifiedOnly = !_verifiedOnly);
                _search();
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tutorModes.length + _tutorCities.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return WinChip(context.l10n.tutoringAvailableSoon,
                    active: _availableSoon,
                    icon: PhosphorIconsRegular.lightning, onTap: () {
                  setState(() => _availableSoon = !_availableSoon);
                  _search();
                });
              }
              if (i - 1 < _tutorModes.length) {
                final (value, label) = _tutorModes[i - 1];
                return WinChip(label, active: _mode == value, onTap: () {
                  setState(() => _mode = _mode == value ? null : value);
                  _search();
                });
              }
              final city = _tutorCities[i - 1 - _tutorModes.length];
              return WinChip(city,
                  active: _city == city, icon: PhosphorIconsRegular.mapPin, onTap: () {
                setState(() => _city = _city == city ? null : city);
                _search();
              });
            },
          ),
        ),
        if (_assigned.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _assigned.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Center(child: Text(context.l10n.tutoringAssignedLabel, style: WinType.labelS(s.onMuted)));
                }
                final a = _assigned[i - 1];
                return WinChip(a.tutorName ?? context.l10n.roleTutor,
                    active: false,
                    icon: PhosphorIconsRegular.star,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TutorPublicProfileScreen(userId: a.tutorUserId, assignment: a))));
              },
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const WinLoading()
              : _error
                  ? WinErrorState(
                      message: context.l10n.tutoringSearchLoadError,
                      onRetry: _search)
                  : _results.isEmpty
                      ? WinEmptyState(
                          title: context.l10n.tutoringSearchEmpty,
                          icon: PhosphorIconsRegular.userFocus)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _ordered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _TutorResultCard(_ordered[i],
                                  topics: _topics, assignment: _assignmentFor(_ordered[i].userId)),
                        ),
        ),
      ]),
    );
  }
}

class _TutorResultCard extends StatelessWidget {
  final TutorSearchResult tutor;
  final List<String> topics;
  /// Attribution active vers ce tuteur : mise en avant et réservation depuis l'attribution.
  final TutorAssignment? assignment;
  const _TutorResultCard(this.tutor, {this.topics = const [], this.assignment});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final rate = tutor.fromHourlyRateXaf ?? tutor.hourlyRateXaf;
    final from = tutor.fromHourlyRateXaf != null &&
        tutor.hourlyRateXaf != null &&
        tutor.fromHourlyRateXaf != tutor.hourlyRateXaf;
    return WinCard(
      onTap: () => Navigator.push(
          context,
          WinPageRoute(
              builder: (_) => TutorPublicProfileScreen(
                  userId: tutor.userId, initialTopics: topics, assignment: assignment))),
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar + badge de vérification superposé (même langage que le
        // cœur favori des cartes catalogue : indicateur incrusté sur
        // l'image plutôt qu'une ligne de texte séparée).
        Stack(clipBehavior: Clip.none, children: [
          WinAvatar(tutor.fullName.isEmpty ? '?' : tutor.fullName,
              size: 56, imageUrl: tutor.avatarUrl),
          // Lot 9.5 : la coche signale la vérification pour le présentiel.
          if (tutor.isInPersonVerified)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: WinColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: s.surface, width: 2),
                ),
                child: const Icon(PhosphorIconsBold.check,
                    size: 12, color: Colors.white),
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(tutor.fullName,
                      style: WinType.titleM(s.onStrong),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.primaryContainer,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                ),
                child: Text(
                  rate != null
                      ? (from ? context.l10n.tutoringRateFrom(fmtXaf(rate)) : '${fmtXaf(rate)} XAF/h')
                      : context.l10n.tutoringRateNa,
                  style: WinType.labelS(s.primary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            // Note et nombre d'avis ; « Nouveau » tant qu'il n'y a pas d'avis.
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(children: [
                Icon(PhosphorIconsFill.star,
                    size: 14,
                    color: tutor.reviewCount > 0 && tutor.averageRating != null
                        ? WinColors.gold
                        : s.onFaint),
                const SizedBox(width: 4),
                Text(
                    tutor.reviewCount > 0 && tutor.averageRating != null
                        ? context.l10n.tutoringRatingShort(
                            WinFormat.decimal(tutor.averageRating!),
                            tutor.reviewCount)
                        : context.l10n.tutoringNewTutor,
                    style: WinType.labelS(s.onMuted)),
              ]),
            ),
            if (assignment != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(context.l10n.tutoringAssignedTutor, style: WinType.labelS(s.primary).copyWith(fontWeight: FontWeight.w700)),
              ),
            if ((tutor.title ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(tutor.title!, style: WinType.labelM(s.onMuted)),
              ),
            if (tutor.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tutor.subjects
                    .take(3)
                    .map((sub) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.chipBg,
                            borderRadius: BorderRadius.circular(WinRadii.full),
                          ),
                          child: Text(sub, style: WinType.labelS(s.onMuted)),
                        ))
                    .toList(),
              ),
            ],
            if (tutor.matchedTopics.isNotEmpty) ...[
              const SizedBox(height: 8),
              TopicChipsRow(tutor.matchedTopics, highlight: true),
            ],
            // Lot 9.5 : modes réels (présentiel = tuteur vérifié) et caution.
            if (tutor.offersInPerson != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '${tutor.offersInPerson! ? context.l10n.tutoringInPersonPossible : context.l10n.tutoringOnlineOnly}'
                    '${tutor.isDiplomaVerified ? ' · ${context.l10n.tutoringDiplomaVerified}' : ''}'
                    '${tutor.endorsedByInstitutions.isNotEmpty ? ' · ${context.l10n.tutoringEndorsedBy(tutor.endorsedByInstitutions.first)}' : ''}',
                    style: WinType.labelS(s.onFaint)),
              ),
            if (tutor.nextAvailableSlot != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(PhosphorIconsRegular.calendarCheck,
                      size: 14, color: s.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        context.l10n.tutoringNextSlot(WinFormat.dayMonthTime(
                            tutor.nextAvailableSlot!)),
                        style: WinType.labelS(s.primary)),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

