import 'package:flutter/material.dart';
import '../services/tutor_booking_service.dart';
import '../services/tutor_profile_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'tutor_group_pricing_editor.dart';
import 'tutor_pricing_grid_editor.dart';
import 'tutor_verification_screen.dart';

/// Module 1  Onboarding et profil répétiteur (professeur_complete.md).
/// Écran unique en 5 étapes (Workflow 1) : matières/niveaux, intervention,
/// tarifs, disponibilités, bio/vérification.
class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

const _levels = [
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
  'ENSP Polytechnique',
  'FMSB Médecine',
  'ESSEC Commerce',
  'ENAM Administration',
  'ENS École Normale',
  'ENSET',
];
const _subjects = [
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
const _specialties = [
  'Préparation concours',
  'Soutien scolaire',
  'Rattrapage express',
  'Cours de vacances'
];
const _styles = ['Structuré', 'Interactif', 'Mixte'];
const _stepLabels = [
  'Matières & niveaux',
  'Intervention & zones',
  'Tarifs & forfaits',
  'Disponibilités',
  'Bio & vérification'
];
const _days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

// Zones d'intervention (US-PRO-07) : quartiers usuels pour les deux plus
// grandes villes, saisie libre pour les autres.
const _tutorCities = ['Douala', 'Yaoundé', 'Autre ville'];
const _tutorQuartiers = <String, List<String>>{
  'Douala': [
    'Akwa',
    'Bonanjo',
    'Bonapriso',
    'Bali',
    'Deido',
    'Makepe',
    'Ndokoti',
    'Bepanda',
    'Logbaba',
    'Kotto',
    'PK8',
    'PK10',
    'PK12',
    'Village',
    'Bonamoussadi'
  ],
  'Yaoundé': [
    'Bastos',
    'Centre-ville',
    'Mvog-Mbi',
    'Mokolo',
    'Essos',
    'Nlongkak',
    'Nsam',
    'Melen',
    'Ngoa-Ekelle',
    'Biyem-Assi',
    'Emombo',
    'Etoudi',
    'Mvan'
  ],
};

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final _service = TutorProfileService.instance;
  bool _loading = true;
  bool _showPreview = false;
  bool _saving = false;
  TutorProfile? _profile;
  TutorProfileCompletion? _completion;
  int _step = 0;

  Set<String> _subjectsSel = {};
  Set<String> _levelsSel = {};
  Set<String> _specialtiesSel = {};
  bool _online = false, _atStudent = false, _atTutor = false, _neutral = false;
  final List<TutorZone> _zones = [];
  String? _selectedCity;
  String? _selectedQuartier;
  final _customCityCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  bool _trialEnabled = false;
  final _trialPriceCtrl = TextEditingController();
  // Lot 9.4 : offre d'engagement mensuel (remplace les anciens forfaits, inertes).
  bool _monthlyEnabled = false;
  final _monthlyDiscountCtrl = TextEditingController();
  int _monthlyMaxDiscount = 30;
  int _notice = 24;
  final _maxPerWeekCtrl = TextEditingController();
  // Lot 9.2 : politique d'annulation du tuteur, dans les bornes fixées par
  // WinPlus (GET /tutor-policy, même source que le web).
  int _fullRefundHours = 24;
  int _partialRefundPercent = 50;
  int _noRefundHours = 2;
  Map<String, int> _policyBounds = const {};
  final Set<String> _slotKeys = {}; // "day-period"
  final _titleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  String? _teachingStyle;
  final _diplomaCtrl = TextEditingController();
  TutorRateSuggestion? _rateSuggestion;
  bool _rateLoading = false;
  // Lot 9.1 : grille tarifaire (matière/mode, créneaux, dégressivité).
  TutorPricingGrid _grid = const TutorPricingGrid();
  // Lot 9.3 : séances de groupe.
  GroupPricingValue _group = const GroupPricingValue();

  static const _periods = [
    {'label': 'Matin', 'start': '08:00', 'end': '12:00'},
    {'label': 'Aprem', 'start': '13:00', 'end': '17:00'},
    {'label': 'Soir', 'start': '18:00', 'end': '21:00'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getMine();
      final c = await _service.getCompletion();
      _hydrate(p);
      setState(() => _completion = c);
      TutorBookingService.instance.getPolicy().then((policy) {
        if (mounted) setState(() => _policyBounds = policy.bounds);
      }).catchError((_) {});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de charger ton profil tuteur.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hydrate(TutorProfile p) {
    _subjectsSel = p.subjects.toSet();
    _levelsSel = p.levels.toSet();
    _specialtiesSel = p.specialties.toSet();
    _online = p.offersOnline;
    // Lot 9.5 (17.17) : choix ENREGISTRÉS (conservés sans vérification), pas
    // les modes effectifs, pour ne jamais les effacer en réenregistrant.
    _atStudent = p.savedOffersAtStudentHome ?? p.offersAtStudentHome;
    _atTutor = p.savedOffersAtTutorHome ?? p.offersAtTutorHome;
    _neutral = p.savedOffersNeutralPlace ?? p.offersNeutralPlace;
    _zones
      ..clear()
      ..addAll(p.interventionZones);
    _rateCtrl.text = p.hourlyRateXaf?.toString() ?? '';
    _trialEnabled = p.trialSessionEnabled;
    _trialPriceCtrl.text = p.trialSessionPriceXaf?.toString() ?? '';
    _monthlyEnabled = p.monthlyEnabled;
    _monthlyDiscountCtrl.text = p.monthlyDiscountPercent.toString();
    _monthlyMaxDiscount = p.monthlyMaxDiscountPercent;
    _grid = TutorPricingGrid(
        rates: p.rates,
        modifiers: p.rateModifiers,
        discounts: p.durationDiscounts);
    _group = GroupPricingValue.fromProfile(p);
    _notice = p.noticeHours;
    _maxPerWeekCtrl.text = p.maxSessionsPerWeek?.toString() ?? '';
    _fullRefundHours = p.fullRefundHours;
    _partialRefundPercent = p.partialRefundPercent;
    _noRefundHours = p.noRefundHours;
    _slotKeys.clear();
    for (final s in p.availabilitySlots) {
      _slotKeys.add('${s.dayOfWeek}-${s.startTime}');
    }
    _titleCtrl.text = p.title ?? '';
    _bioCtrl.text = p.tutorBio ?? '';
    _videoCtrl.text = p.videoUrl ?? '';
    _teachingStyle = p.teachingStyle;
    setState(() {
      _profile = p;
      _step = (p.onboardingStep > 0 ? p.onboardingStep - 1 : 0).clamp(0, 4);
    });
  }

  /// Lot 9.5 : présentiel possible (vérifié et non suspendu).
  bool get _inPersonAllowed => _profile?.inPersonAllowed ?? true;

  /// Lot 9.5 (17.17) : mode présentiel. Sans vérification (ou pendant une
  /// suspension), le choix reste modifiable et enregistré, mais coché en gris
  /// avec « Actif après vérification » : ni proposé ni réservable d'ici là.
  Widget _inPersonTile(WinScheme s, String label, bool value, ValueChanged<bool> onChanged) {
    final pending = value && !_inPersonAllowed;
    final note = _profile?.inPersonSuspended == true
        ? 'Actif après examen de la suspension'
        : 'Actif après vérification';
    return CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: pending ? s.onMuted : null,
        title: Text(label, style: pending ? WinType.bodyM(s.onMuted) : null),
        subtitle: pending ? Text(note, style: WinType.bodyS(s.onMuted)) : null,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading);
  }

  /// Lot 9.5 : parcours de vérification ; au retour, relit le profil (modes
  /// présentiels effectifs) sans changer l'étape en cours.
  Future<void> _openVerification() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorVerificationScreen()));
    try {
      final p = await _service.getMine();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _atStudent = p.savedOffersAtStudentHome ?? p.offersAtStudentHome;
        _atTutor = p.savedOffersAtTutorHome ?? p.offersAtTutorHome;
        _neutral = p.savedOffersNeutralPlace ?? p.offersNeutralPlace;
      });
    } catch (_) {}
  }

  Map<String, dynamic> _stepPayload() {
    switch (_step) {
      case 0:
        return {
          'subjects': _subjectsSel.toList(),
          'levels': _levelsSel.toList(),
          'specialties': _specialtiesSel.toList()
        };
      case 1:
        return {
          'offersOnline': _online,
          'offersAtStudentHome': _atStudent,
          'offersAtTutorHome': _atTutor,
          'offersNeutralPlace': _neutral,
          'interventionZones': _zones.map((z) => z.toJson()).toList(),
        };
      case 2:
        return {
          'hourlyRateXaf': num.tryParse(_rateCtrl.text),
          'trialSessionEnabled': _trialEnabled,
          'trialSessionPriceXaf': num.tryParse(_trialPriceCtrl.text),
          'monthlyEnabled': _monthlyEnabled,
          'monthlyDiscountPercent': (int.tryParse(_monthlyDiscountCtrl.text.trim()) ?? 0).clamp(0, _monthlyMaxDiscount),
          ..._grid.toPayload(),
          ..._group.toPayload(),
        };
      case 3:
        final slots = _slotKeys.map((k) {
          final parts = k.split('-');
          final day = int.parse(parts[0]);
          final start = parts[1];
          final period = _periods.firstWhere((p) => p['start'] == start);
          return TutorAvailabilitySlot(
                  dayOfWeek: day, startTime: start, endTime: period['end']!)
              .toJson();
        }).toList();
        return {
          'noticeHours': _notice,
          'maxSessionsPerWeek': int.tryParse(_maxPerWeekCtrl.text),
          'availabilitySlots': slots,
          'fullRefundHours': _fullRefundHours,
          'partialRefundPercent': _partialRefundPercent,
          'noRefundHours': _noRefundHours,
        };
      case 4:
        return {
          'title': _titleCtrl.text,
          'tutorBio': _bioCtrl.text,
          'videoUrl': _videoCtrl.text,
          'teachingStyle': _teachingStyle
        };
      default:
        return {};
    }
  }

  Future<void> _saveStep({int? next}) async {
    setState(() => _saving = true);
    try {
      final payload = {
        ..._stepPayload(),
        'onboardingStep': (_step + 1).clamp(0, 5)
      };
      final p = await _service.update(payload);
      final c = await _service.getCompletion();
      _hydrate(p);
      setState(() => _completion = c);
      if (next != null) setState(() => _step = next);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Étape enregistrée.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'enregistrement.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _saving = true);
    try {
      final p = await _service.activate();
      _hydrate(p);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Ton profil tuteur est visible dans la recherche !')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Complète les champs essentiels avant d\'activer ton profil.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _suggestRate() async {
    if (_subjectsSel.isEmpty) return;
    setState(() => _rateLoading = true);
    try {
      final s = await _service.suggestRate(_subjectsSel.first,
          level: _levelsSel.isNotEmpty ? _levelsSel.first : null);
      setState(() => _rateSuggestion = s);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('WinAI indisponible pour l\'instant.')));
    } finally {
      if (mounted) setState(() => _rateLoading = false);
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
        title: Text('Mode Tuteur',
            style: WinType.archivo(size: 18, color: s.onStrong)),
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              icon: Icon(
                  _showPreview
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  color: s.onMuted),
              tooltip: _showPreview
                  ? 'Retour à l\'édition'
                  : 'Voir mon profil comme un élève',
              onPressed: () => setState(() => _showPreview = !_showPreview),
            ),
          if (_profile?.isActive == true)
            IconButton(
              icon: Icon(
                  _profile!.isOnVacation
                      ? Icons.flight_takeoff
                      : Icons.flight_takeoff_outlined,
                  color: _profile!.isOnVacation ? WinColors.warn : s.onMuted),
              tooltip: 'En vacances',
              onPressed: () async {
                final p = await _service.setVacation(!_profile!.isOnVacation);
                _hydrate(p);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _showPreview
                  ? _buildPreview(s)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_completion != null) _buildCompletion(s),
                        const SizedBox(height: 16),
                        _buildStepper(s),
                        const SizedBox(height: 16),
                        WinCard(child: _buildStepBody(s)),
                        const SizedBox(height: 20),
                        _buildActions(s),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
    );
  }

  /// "Voir mon profil comme un élève" (US-10) : rendu public en lecture
  /// seule, à partir des données déjà chargées  aucune donnée d'avis/note
  /// n'existe encore (dépend du Module 6), affichée comme telle plutôt que
  /// fabriquée.
  Widget _buildPreview(WinScheme s) {
    final p = _profile!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        WinAvatar(p.title ?? '?', size: 64),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title ?? 'Tuteur WinPlus',
                style: WinType.archivo(size: 17, color: s.onStrong)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (p.isInPersonVerified && !p.inPersonSuspended)
                const WinBadge('Vérifié pour le présentiel', color: BadgeColor.success),
              if (p.isDiplomaVerified)
                const WinBadge('Diplôme vérifié', color: BadgeColor.teal),
              for (final n in p.endorsedByInstitutions)
                WinBadge('Caution : $n', color: BadgeColor.blue),
              const WinBadge('Avis bientôt disponibles',
                  color: BadgeColor.neutral),
            ]),
          ]),
        ),
      ]),
      if ((p.tutorBio ?? '').isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(p.tutorBio!, style: WinType.bodyM(s.onStrong)),
      ],
      if ((p.videoUrl ?? '').isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('🎥 ${p.videoUrl}', style: WinType.bodyM(s.onMuted)),
      ],
      const SizedBox(height: 16),
      WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tarif', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        Text(
            p.hourlyRateXaf != null
                ? '${p.hourlyRateXaf} XAF/h'
                : 'Non renseigné',
            style: WinType.bodyM(s.onMuted)),
        if (p.trialSessionEnabled) const Text('Séance d\'essai proposée'),
      ])),
      const SizedBox(height: 12),
      WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Matières & niveaux', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        Text(p.subjects.join(', ').isEmpty ? 'Aucune' : p.subjects.join(', ')),
        Text(p.levels.join(', ').isEmpty ? 'Aucun' : p.levels.join(', ')),
      ])),
      const SizedBox(height: 20),
      WinButton('Réserver (aperçu  désactivé)', block: true, onTap: null),
    ]);
  }

  Widget _buildCompletion(WinScheme s) {
    final c = _completion!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Complétude du profil', style: WinType.bodyM(s.onMuted)),
        Text('${c.score}/100',
            style: WinType.labelM(s.onStrong)
                .copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(WinRadii.full),
        child: LinearProgressIndicator(
            value: c.score / 100,
            backgroundColor: s.chipBg,
            color: WinColors.teal400,
            minHeight: 6),
      ),
      if (c.missingItems.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: c.missingItems
                .map((m) => Chip(
                      label: Text(m['label'] ?? '',
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor: WinColors.warnBg,
                      side: BorderSide.none,
                    ))
                .toList()),
      ],
    ]);
  }

  Widget _buildStepper(WinScheme s) {
    return Row(
        children: List.generate(_stepLabels.length * 2 - 1, (i) {
      if (i.isOdd) {
        final done = (i ~/ 2) < _step;
        return Expanded(
            child: Container(
                height: 2, color: done ? WinColors.teal400 : s.outline));
      }
      final idx = i ~/ 2;
      final active = idx == _step;
      final done = idx < _step;
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              active ? WinColors.teal400 : (done ? WinColors.teal50 : s.chipBg),
          border:
              Border.all(color: active || done ? WinColors.teal400 : s.outline),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: WinColors.teal700)
            : Text('${idx + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : s.onMuted)),
      );
    }));
  }

  Widget _buildStepBody(WinScheme s) {
    switch (_step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Matières enseignées', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects
                  .map((m) => WinChip(
                        m,
                        active: _subjectsSel.contains(m),
                        onTap: () => setState(() => _subjectsSel.contains(m)
                            ? _subjectsSel.remove(m)
                            : _subjectsSel.add(m)),
                      ))
                  .toList()),
          const SizedBox(height: 20),
          Text('Niveaux couverts', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _levels
                  .map((l) => WinChip(
                        l,
                        active: _levelsSel.contains(l),
                        onTap: () => setState(() => _levelsSel.contains(l)
                            ? _levelsSel.remove(l)
                            : _levelsSel.add(l)),
                      ))
                  .toList()),
          const SizedBox(height: 20),
          Text('Spécialités', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialties
                  .map((sp) => WinChip(
                        sp,
                        active: _specialtiesSel.contains(sp),
                        onTap: () => setState(() => _specialtiesSel.contains(sp)
                            ? _specialtiesSel.remove(sp)
                            : _specialtiesSel.add(sp)),
                      ))
                  .toList()),
        ]);

      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Modes d\'intervention', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          CheckboxListTile(
              value: _online,
              onChanged: (v) => setState(() => _online = v ?? false),
              title: const Text('En ligne via WinPlus'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading),
          // Lot 9.5 (17.11) : présentiel réservé aux tuteurs vérifiés (refusé aussi par le serveur).
          if (!_inPersonAllowed) ...[
            WinAlert(
                '${_profile?.inPersonBlockedReason ?? 'Le présentiel est réservé aux tuteurs vérifiés.'} '
                '${_profile?.inPersonSuspended == true ? 'Tes choix présentiels restent enregistrés et redeviendront actifs à la levée de la suspension.' : 'Tes choix présentiels sont enregistrés et deviendront actifs dès ta vérification.'}',
                type: BadgeColor.warn),
            const SizedBox(height: 6),
            WinButton('Me faire vérifier',
                small: true,
                variant: WinButtonVariant.outline,
                icon: Icons.verified_user_outlined,
                onTap: _openVerification),
            const SizedBox(height: 6),
          ],
          // Lot 9.5 (17.17) : choix présentiels conservés, cochés mais grisés
          // « actif après vérification » tant que le présentiel n'est pas possible.
          _inPersonTile(s, 'À domicile chez l\'élève', _atStudent, (v) => setState(() => _atStudent = v)),
          _inPersonTile(s, 'À domicile chez moi', _atTutor, (v) => setState(() => _atTutor = v)),
          _inPersonTile(s, 'Présentiel en espace neutre', _neutral, (v) => setState(() => _neutral = v)),
          if (_atStudent || _atTutor) ...[
            const SizedBox(height: 12),
            Text('Zones géographiques couvertes',
                style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              hint: const Text('Choisir une ville…'),
              items: _tutorCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCity = v;
                _selectedQuartier = null;
              }),
            ),
            const SizedBox(height: 8),
            if (_selectedCity != null && _selectedCity != 'Autre ville')
              DropdownButtonFormField<String>(
                value: _selectedQuartier,
                hint: const Text('Quartier (optionnel)…'),
                items: (_tutorQuartiers[_selectedCity] ?? [])
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedQuartier = v),
              )
            else if (_selectedCity == 'Autre ville')
              WinTextField(
                  controller: _customCityCtrl,
                  hint: 'Nom de la ville / quartier'),
            const SizedBox(height: 8),
            WinButton('Ajouter cette zone',
                small: true, variant: WinButtonVariant.outline, onTap: () {
              final city = _selectedCity == 'Autre ville'
                  ? _customCityCtrl.text.trim()
                  : _selectedCity;
              if (city == null || city.isEmpty) return;
              final quartier =
                  _selectedCity == 'Autre ville' ? null : _selectedQuartier;
              setState(() {
                _zones.add(TutorZone(city: city, quartier: quartier));
                _selectedCity = null;
                _selectedQuartier = null;
                _customCityCtrl.clear();
              });
            }),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _zones
                    .map((z) => Chip(
                          label: Text(z.quartier != null
                              ? '${z.city}  ${z.quartier}'
                              : z.city),
                          onDeleted: () => setState(() => _zones.remove(z)),
                        ))
                    .toList()),
          ],
        ]);

      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tarif horaire (XAF)', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _rateCtrl,
              hint: 'ex: 3000',
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          WinButton(_rateLoading ? 'WinAI réfléchit…' : 'Suggestion WinAI',
              variant: WinButtonVariant.outline,
              small: true,
              icon: Icons.auto_awesome,
              onTap: _rateLoading ? null : _suggestRate),
          if (_rateSuggestion != null) ...[
            const SizedBox(height: 10),
            WinAlert(
              '${_rateSuggestion!.suggestedRateXaf} XAF/h suggéré (${_rateSuggestion!.rangeLowXaf}-${_rateSuggestion!.rangeHighXaf}). ${_rateSuggestion!.explanation}',
              type: BadgeColor.blue,
            ),
            TextButton(
                onPressed: () => setState(() => _rateCtrl.text =
                    _rateSuggestion!.suggestedRateXaf.toString()),
                child: const Text('Utiliser ce tarif')),
          ],
          const SizedBox(height: 16),
          TutorPricingGridEditor(
            value: _grid,
            onChanged: (g) => setState(() => _grid = g),
            subjects: _subjectsSel.toList(),
            offersOnline: _online,
            offersInPerson: _atStudent || _atTutor || _neutral,
            level: _levelsSel.isNotEmpty ? _levelsSel.first : null,
          ),
          const SizedBox(height: 16),
          TutorGroupPricingEditor(
              value: _group,
              onChanged: (g) => setState(() => _group = g),
              subject: _subjectsSel.isNotEmpty ? _subjectsSel.first : null,
              level: _levelsSel.isNotEmpty ? _levelsSel.first : null),
          const SizedBox(height: 16),
          CheckboxListTile(
              value: _trialEnabled,
              onChanged: (v) => setState(() => _trialEnabled = v ?? false),
              title: const Text('Proposer une séance d\'essai'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading),
          if (_trialEnabled)
            WinTextField(
                controller: _trialPriceCtrl,
                hint: 'Prix (0 = gratuite)',
                keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          // Lot 9.4 (17.7) : engagement mensuel, remise facultative bornée par le serveur.
          SwitchListTile(
              value: _monthlyEnabled,
              onChanged: (v) => setState(() => _monthlyEnabled = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Proposer l\'engagement mensuel'),
              subtitle: const Text('Mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance ; tu es payé séance par séance.')),
          if (_monthlyEnabled) ...[
            WinTextField(
                controller: _monthlyDiscountCtrl,
                hint: 'Remise mensuelle en % (0 à $_monthlyMaxDiscount)',
                keyboardType: TextInputType.number),
            const SizedBox(height: 4),
            Text('Appliquée au prix de chaque séance du mois, calculé par ta grille.',
                style: WinType.labelS(s.onFaint)),
          ],
        ]);

      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créneaux hebdomadaires (tap pour activer)',
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 10),
          Table(
              children: List.generate(_periods.length, (pi) {
            final period = _periods[pi];
            return TableRow(
                children: List.generate(7, (day) {
              final key = '$day-${period['start']}';
              final active = _slotKeys.contains(key);
              return Padding(
                padding: const EdgeInsets.all(3),
                child: GestureDetector(
                  onTap: () => setState(() =>
                      active ? _slotKeys.remove(key) : _slotKeys.add(key)),
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(WinRadii.sm),
                        color: active ? WinColors.teal400 : s.chipBg,
                        border: Border.all(color: s.outline)),
                    child: Text(pi == 0 ? _days[day] : '',
                        style: TextStyle(
                            fontSize: 10,
                            color: active ? Colors.white : s.onMuted)),
                  ),
                ),
              );
            }));
          })),
          const SizedBox(height: 16),
          Text('Délai de préavis minimum', style: WinType.labelM(s.onStrong)),
          Wrap(
              spacing: 8,
              children: [12, 24, 48]
                  .map((h) => WinChip('$h h',
                      active: _notice == h,
                      onTap: () => setState(() => _notice = h)))
                  .toList()),
          const SizedBox(height: 16),
          Text('Séances max par semaine', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _maxPerWeekCtrl,
              hint: 'Illimité',
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          Text("Politique d'annulation", style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 4),
          Text(
              "Ce que l'élève récupère s'il annule lui-même (les frais Mobile Money restent à sa charge).",
              style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 10),
          _policyStepper(s,
              label: 'Remboursement total si annulé au moins',
              suffix: 'h avant',
              value: _fullRefundHours,
              min: _bound('fullRefundHoursMin', 12),
              max: _bound('fullRefundHoursMax', 48),
              step: 1,
              onChanged: (v) => setState(() {
                    _fullRefundHours = v;
                    if (_noRefundHours > v) _noRefundHours = v;
                  })),
          _policyStepper(s,
              label: 'Ensuite, part remboursée',
              suffix: '%',
              value: _partialRefundPercent,
              min: _bound('partialRefundPercentMin', 0),
              max: _bound('partialRefundPercentMax', 100),
              step: 10,
              onChanged: (v) => setState(() => _partialRefundPercent = v)),
          _policyStepper(s,
              label: 'Aucun remboursement à moins de',
              suffix: 'h avant',
              value: _noRefundHours,
              min: _bound('noRefundHoursMin', 0),
              max: [_bound('noRefundHoursMax', 12), _fullRefundHours]
                  .reduce((a, b) => a < b ? a : b),
              step: 1,
              onChanged: (v) => setState(() => _noRefundHours = v)),
          const SizedBox(height: 6),
          Text(
              'Limites fixées par WinPlus : remboursement total entre '
              '${_bound('fullRefundHoursMin', 12)} h et ${_bound('fullRefundHoursMax', 48)} h avant, '
              'part remboursée de ${_bound('partialRefundPercentMin', 0)} à ${_bound('partialRefundPercentMax', 100)} %, '
              'aucun remboursement en dessous de ${_bound('noRefundHoursMin', 0)} à ${_bound('noRefundHoursMax', 12)} h.',
              style: WinType.labelS(s.onFaint)),
        ]);

      case 4:
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Titre professionnel', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _titleCtrl, hint: 'ex: Prof de Maths  Terminale C/D'),
          const SizedBox(height: 16),
          Text('Bio courte (300 caractères max)',
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          TextField(controller: _bioCtrl, maxLength: 300, maxLines: 4),
          const SizedBox(height: 8),
          Text('Style pédagogique', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: _styles
                  .map((st) => WinChip(st,
                      active: _teachingStyle == st,
                      onTap: () => setState(() => _teachingStyle = st)))
                  .toList()),
          const SizedBox(height: 16),
          Text('Vidéo de présentation (optionnel)',
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(controller: _videoCtrl, hint: 'https://youtube.com/...'),
          const SizedBox(height: 16),
          // Lot 9.5 : vérification pour le présentiel (identité, entretien, caution).
          WinCard(
            onTap: _openVerification,
            child: Row(children: [
              Icon(Icons.verified_user_outlined, color: s.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vérification pour le présentiel', style: WinType.titleM(s.onStrong)),
                  Text(
                      _profile?.inPersonSuspended == true
                          ? 'Présentiel suspendu en attendant un examen'
                          : _profile?.isInPersonVerified == true
                              ? 'Vérifié : présentiel ouvert'
                              : "Pièce d'identité, entretien ou caution d'institution",
                      style: WinType.labelS(s.onMuted)),
                ]),
              ),
              Icon(Icons.chevron_right, color: s.onFaint),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Diplôme (facultatif, badge « Diplôme vérifié », sans effet sur le présentiel)',
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          if (_profile?.pendingOrLatestDocument != null)
            WinAlert('Statut : ${_profile!.pendingOrLatestDocument!.status}',
                type: BadgeColor.neutral)
          else
            Row(children: [
              Expanded(
                  child: WinTextField(
                      controller: _diplomaCtrl,
                      hint: 'URL du document uploadé')),
              const SizedBox(width: 8),
              WinButton('Envoyer',
                  small: true,
                  variant: WinButtonVariant.outline, onTap: () async {
                if (_diplomaCtrl.text.trim().isEmpty) return;
                await _service
                    .submitVerificationDocument(_diplomaCtrl.text.trim());
                final p = await _service.getMine();
                _hydrate(p);
                _diplomaCtrl.clear();
              }),
            ]),
        ]);
    }
  }

  int _bound(String key, int fallback) => _policyBounds[key] ?? fallback;

  Widget _policyStepper(WinScheme s,
      {required String label,
      required String suffix,
      required int value,
      required int min,
      required int max,
      required int step,
      required ValueChanged<int> onChanged}) {
    final v = value.clamp(min, max < min ? min : max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: WinType.bodyS(s.onStrong))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: v > min ? () => onChanged((v - step).clamp(min, max)) : null,
        ),
        SizedBox(
          width: 64,
          child: Text('$v $suffix',
              textAlign: TextAlign.center, style: WinType.labelM(s.onStrong)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: v < max ? () => onChanged((v + step).clamp(min, max)) : null,
        ),
      ]),
    );
  }

  Widget _buildActions(WinScheme s) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      WinButton('Précédent',
          variant: WinButtonVariant.ghost,
          onTap:
              _step == 0 || _saving ? null : () => setState(() => _step -= 1)),
      if (_step < 4)
        WinButton(_saving ? 'Enregistrement…' : 'Continuer',
            loading: _saving,
            onTap: _saving ? null : () => _saveStep(next: _step + 1))
      else
        Row(children: [
          WinButton('Enregistrer',
              variant: WinButtonVariant.outline,
              loading: _saving,
              onTap: _saving ? null : () => _saveStep()),
          const SizedBox(width: 8),
          if (_profile?.isActive != true)
            WinButton('Activer',
                variant: WinButtonVariant.accent,
                loading: _saving,
                onTap: _saving
                    ? null
                    : () async {
                        await _saveStep();
                        await _activate();
                      }),
        ]),
    ]);
  }
}
