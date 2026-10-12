import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_public_profile_screen.dart';
import 'tutor_pricing_widgets.dart';

const _tutorSubjects = [
  'Mathématiques',
  'Physique',
  'Chimie',
  'SVT',
  'Français',
  'Philosophie',
  'Anglais',
  'Histoire-Géo',
  'Informatique',
  'Économie',
];
const _tutorLevels = [
  '6ème',
  '5ème',
  '4ème',
  '3ème',
  'Seconde',
  'Première',
  'Terminale',
  'BEPC',
  'Probatoire',
  'BAC',
  'Prépa',
];
const _tutorModes = [
  ('online', 'En ligne'),
  ('student_home', 'À mon domicile'),
  ('tutor_home', 'Chez le tuteur'),
  ('neutral_place', 'Espace neutre'),
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

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Trouver un tuteur', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TopicsField(
            topics: _topics,
            hint: 'Sujets à travailler (ex. dérivées, dissertation)',
            onChanged: (t) {
              setState(() => _topics = t);
              _search();
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tutorSubjects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return WinChip('Toutes matières', active: _subject == null,
                    onTap: () {
                  setState(() => _subject = null);
                  _search();
                });
              }
              final subj = _tutorSubjects[i - 1];
              return WinChip(subj, active: _subject == subj, onTap: () {
                setState(() => _subject = _subject == subj ? null : subj);
                _search();
              });
            },
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tutorLevels.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return WinChip('Tous niveaux', active: _level == null,
                    onTap: () {
                  setState(() => _level = null);
                  _search();
                });
              }
              if (i == 1) {
                return WinChip('Diplôme vérifié',
                    active: _verifiedOnly,
                    icon: Icons.verified_outlined, onTap: () {
                  setState(() => _verifiedOnly = !_verifiedOnly);
                  _search();
                });
              }
              final lvl = _tutorLevels[i - 2];
              return WinChip(lvl, active: _level == lvl, onTap: () {
                setState(() => _level = _level == lvl ? null : lvl);
                _search();
              });
            },
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
                return WinChip('Disponible sous 48h',
                    active: _availableSoon,
                    icon: Icons.bolt_outlined, onTap: () {
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
                  active: _city == city, icon: Icons.place_outlined, onTap: () {
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
                  return Center(child: Text('Attribués :', style: WinType.labelS(s.onMuted)));
                }
                final a = _assigned[i - 1];
                return WinChip(a.tutorName ?? 'Répétiteur',
                    active: false,
                    icon: Icons.star_outline,
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
              ? const Center(child: CircularProgressIndicator())
              : _error
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                      const SizedBox(height: 12),
                      Text('Impossible de charger les tuteurs.',
                          style: WinType.bodyM(s.onMuted)),
                      const SizedBox(height: 12),
                      WinButton('Réessayer', onTap: _search),
                    ]))
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(32),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.person_search_outlined,
                                size: 64, color: s.onFaint),
                            const SizedBox(height: 12),
                            Text('Aucun tuteur trouvé pour ces critères.',
                                style: WinType.bodyM(s.onMuted),
                                textAlign: TextAlign.center),
                          ]),
                        ))
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
          WinAvatar(tutor.fullName.isEmpty ? '?' : tutor.fullName, size: 56),
          if (tutor.isDiplomaVerified)
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
                child: const Icon(Icons.check_rounded,
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
                      ? '${from ? 'dès ' : ''}${fmtXaf(rate)} XAF/h'
                      : 'Tarif ND',
                  style: WinType.labelS(s.primary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            if (assignment != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Répétiteur attribué', style: WinType.labelS(s.primary).copyWith(fontWeight: FontWeight.w700)),
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
          ]),
        ),
      ]),
    );
  }
}
