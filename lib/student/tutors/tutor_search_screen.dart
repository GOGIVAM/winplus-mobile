import 'package:flutter/material.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_public_profile_screen.dart';

const _tutorSubjects = [
  'Mathématiques', 'Physique', 'Chimie', 'SVT', 'Français', 'Philosophie',
  'Anglais', 'Histoire-Géo', 'Informatique', 'Économie',
];
const _tutorLevels = [
  '6ème', '5ème', '4ème', '3ème', 'Seconde', 'Première', 'Terminale',
  'BEPC', 'Probatoire', 'BAC', 'Prépa',
];
const _tutorModes = [
  ('online', 'En ligne'),
  ('student_home', 'À mon domicile'),
  ('tutor_home', 'Chez le tuteur'),
  ('neutral_place', 'Espace neutre'),
];
const _tutorCities = ['Douala', 'Yaoundé'];

/// Recherche de répétiteurs (Module 1 — côté élève, professeur_complete.md).
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
  bool _loading = true;
  bool _error = false;
  List<TutorSearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() { _loading = true; _error = false; });
    try {
      final results = await TutorProfileService.instance.search(
        subject: _subject,
        level: _level,
        verifiedOnly: _verifiedOnly ? true : null,
        mode: _mode,
        city: _city,
        availableSoon: _availableSoon ? true : null,
        pageSize: 30,
      );
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
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
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tutorSubjects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return WinChip('Toutes matières',
                    active: _subject == null,
                    onTap: () { setState(() => _subject = null); _search(); });
              }
              final subj = _tutorSubjects[i - 1];
              return WinChip(subj,
                  active: _subject == subj,
                  onTap: () { setState(() => _subject = _subject == subj ? null : subj); _search(); });
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
                return WinChip('Tous niveaux',
                    active: _level == null,
                    onTap: () { setState(() => _level = null); _search(); });
              }
              if (i == 1) {
                return WinChip('Diplôme vérifié',
                    active: _verifiedOnly,
                    icon: Icons.verified_outlined,
                    onTap: () { setState(() => _verifiedOnly = !_verifiedOnly); _search(); });
              }
              final lvl = _tutorLevels[i - 2];
              return WinChip(lvl,
                  active: _level == lvl,
                  onTap: () { setState(() => _level = _level == lvl ? null : lvl); _search(); });
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
                    icon: Icons.bolt_outlined,
                    onTap: () { setState(() => _availableSoon = !_availableSoon); _search(); });
              }
              if (i - 1 < _tutorModes.length) {
                final (value, label) = _tutorModes[i - 1];
                return WinChip(label,
                    active: _mode == value,
                    onTap: () { setState(() => _mode = _mode == value ? null : value); _search(); });
              }
              final city = _tutorCities[i - 1 - _tutorModes.length];
              return WinChip(city,
                  active: _city == city,
                  icon: Icons.place_outlined,
                  onTap: () { setState(() => _city = _city == city ? null : city); _search(); });
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                      const SizedBox(height: 12),
                      Text('Impossible de charger les tuteurs.', style: WinType.bodyM(s.onMuted)),
                      const SizedBox(height: 12),
                      WinButton('Réessayer', onTap: _search),
                    ]))
                  : _results.isEmpty
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.person_search_outlined, size: 64, color: s.onFaint),
                            const SizedBox(height: 12),
                            Text('Aucun tuteur trouvé pour ces critères.',
                                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                          ]),
                        ))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _TutorResultCard(_results[i]),
                        ),
        ),
      ]),
    );
  }
}

class _TutorResultCard extends StatelessWidget {
  final TutorSearchResult tutor;
  const _TutorResultCard(this.tutor);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TutorPublicProfileScreen(userId: tutor.userId))),
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WinAvatar(tutor.fullName.isEmpty ? '?' : tutor.fullName, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tutor.fullName, style: WinType.titleM(s.onStrong)),
            if ((tutor.title ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(tutor.title!, style: WinType.labelM(s.onMuted)),
              ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (tutor.isDiplomaVerified) const WinBadge('Vérifié Diplôme', color: BadgeColor.success),
              const WinBadge('Avis bientôt disponibles', color: BadgeColor.neutral),
            ]),
            if (tutor.subjects.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(tutor.subjects.join(', '), style: WinType.labelS(s.onFaint), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          tutor.hourlyRateXaf != null ? '${tutor.hourlyRateXaf!.toStringAsFixed(0)} XAF/h' : 'Tarif ND',
          style: WinType.labelM(s.primary).copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
