import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../services/tutor_booking_service.dart';
import '../services/tutor_profile_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import 'tutor_group_pricing_editor.dart';
import 'tutor_pricing_grid_editor.dart';
import 'tutor_verification_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../shared/net_image.dart';
import '../shared/tutor_ref_picker.dart';
import '../student/tutors/tutor_reviews_section.dart';

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
/// Nombre d'étapes du profil (matières, intervention, tarifs, disponibilités,
/// présentation) ; leurs titres affichés viennent des fichiers de langue.
const _stepCount = 5;
/// Jour abrégé (0 = dimanche … 6 = samedi) : « Dim », « Lun »… / « Sun », « Mon »…
String _dayShort(int d) =>
    WinFormat.weekdayShortCap(d == 0 ? DateTime.sunday : d);

// Libellés affichés ; les valeurs enregistrées (matières, niveaux,
// spécialités, styles, ville « Autre ville ») restent celles ci-dessus.
String _subjectLabel(BuildContext context, String m) => switch (m) {
      'Mathématiques' => context.l10n.dataSubjectMath,
      'Physique' => context.l10n.dataSubjectPhysics,
      'Chimie' => context.l10n.dataSubjectChemistry,
      'Français' => context.l10n.dataSubjectFrench,
      'Philosophie' => context.l10n.dataSubjectPhilosophy,
      'Anglais' => context.l10n.dataSubjectEnglish,
      'Histoire-Géo' => context.l10n.dataSubjectHistGeo,
      'Informatique' => context.l10n.dataSubjectComputing,
      'Économie' => context.l10n.tutoringSubjectEconomics,
      _ => m,
    };

String _levelLabel(BuildContext context, String l) => switch (l) {
      'Prépa' => context.l10n.authLvlPrepa,
      'FMSB Médecine' => context.l10n.authLvlFmsb,
      'ESSEC Commerce' => context.l10n.authLvlEssec,
      'ENAM Administration' => context.l10n.teacherProfileLevelEnam,
      'ENS École Normale' => context.l10n.authLvlEns,
      _ => ClassLevels.label(l),
    };

String _specialtyLabel(BuildContext context, String sp) => switch (sp) {
      'Préparation concours' => context.l10n.teacherProfileSpecContestPrep,
      'Soutien scolaire' => context.l10n.teacherProfileSpecSchoolSupport,
      'Rattrapage express' => context.l10n.teacherProfileSpecCatchUp,
      'Cours de vacances' => context.l10n.teacherProfileSpecHoliday,
      _ => sp,
    };

String _styleLabel(BuildContext context, String st) => switch (st) {
      'Structuré' => context.l10n.teacherProfileStyleStructured,
      'Interactif' => context.l10n.teacherProfileStyleInteractive,
      'Mixte' => context.l10n.teacherProfileStyleMixed,
      _ => st,
    };

String _cityLabel(BuildContext context, String c) =>
    c == 'Autre ville' ? context.l10n.teacherProfileOtherCity : c;

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
  // Liste commune des matières et des niveaux (celle du site) ; la liste
  // de secours tant que le serveur ne l'a pas donnée.
  TutorReferential _ref = TutorReferential.fallback;
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
  /// Envoi de fichier en cours : 'photo', 'video' ou 'diploma'.
  String? _uploading;

  /// Photo du compte (obligatoire pour publier le profil).
  String? _avatarUrl;
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
    _service.referential().then((r) {
      if (!mounted) return;
      setState(() {
        _ref = r;
        // Un ancien libellé enregistré rejoint celui de la liste.
        _subjectsSel = _subjectsSel.map(r.canonical).toSet();
        _levelsSel = _levelsSel.map(r.canonical).toSet();
      });
    });
  }

  /// Choix proposés d'emblée : la liste courte, puis ce qui a été coché
  /// ailleurs dans la liste complète.
  List<String> _shown(List<String> core, Set<String> sel) {
    final base = core.map(_ref.canonical).toList();
    return [...base, ...sel.where((v) => !base.contains(v))];
  }

  /// Liste complète (secondaire et supérieur), à cocher.
  Future<void> _pickMore({required bool subjects}) async {
    final l = context.l10n;
    final r = await showTutorRefPicker(context,
        title: subjects
            ? l.teacherProfileSubjectsTaught
            : l.teacherProfileLevelsCovered,
        sections: [
          (
            l.instCycleSecondary,
            subjects ? _ref.secondarySubjects : _ref.secondaryLevels
          ),
          (
            l.instCycleHigher,
            subjects ? _ref.superiorSubjects : _ref.superiorLevels
          ),
        ],
        selected: subjects ? _subjectsSel : _levelsSel,
        labelOf: subjects ? tutorSubjectLabel : tutorLevelLabel,
        multiple: true);
    if (r == null || !mounted) return;
    setState(() => subjects ? _subjectsSel = r : _levelsSel = r);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherProfileLoadError)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hydrate(TutorProfile p) {
    _subjectsSel = p.subjects.map(_ref.canonical).toSet();
    _levelsSel = p.levels.map(_ref.canonical).toSet();
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
    if ((p.avatarUrl ?? '').isNotEmpty) _avatarUrl = p.avatarUrl;
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
        ? context.l10n.teacherProfileActiveAfterSuspension
        : context.l10n.teacherProfileActiveAfterVerification;
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
            .showSnackBar(SnackBar(content: Text(L10n.current.teacherProfileStepSaved)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.current.teacherProfileSaveError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Choisit un fichier d'au plus [maxMb] Mo ; null si rien n'est choisi ou
  /// si le fichier est trop lourd (l'utilisateur est prévenu).
  Future<PlatformFile?> _pickFile(
      {required FileType type, List<String>? extensions, required int maxMb}) async {
    final res = await FilePicker.platform.pickFiles(
        type: type, allowedExtensions: extensions, withData: true);
    final f = res?.files.firstOrNull;
    if (f == null || f.bytes == null) return null;
    if (f.size > maxMb * 1024 * 1024) {
      _toast(L10n.current.tutorFileTooBig(maxMb));
      return null;
    }
    return f;
  }

  Future<void> _send(String kind, Future<void> Function() work) async {
    setState(() => _uploading = kind);
    try {
      await work();
    } catch (e) {
      _toast(TutorProfileService.serverMessage(e) ??
          L10n.current.tutorUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _pickPhoto() async {
    final shot = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85);
    if (shot == null) return;
    await _send('photo', () async {
      final url = await UserService.instance
          .uploadAvatar(await shot.readAsBytes(), shot.name);
      if (url == null) throw StateError('avatar: envoi refuse');
      if (mounted) setState(() => _avatarUrl = url);
      // La photo compte dans la complétude : on relit le profil.
      _hydrate(await _service.getMine());
    });
  }

  Future<void> _pickVideo() async {
    final f = await _pickFile(type: FileType.video, maxMb: 25);
    if (f == null) return;
    await _send('video', () async {
      final url = await _service.uploadVideo(f.bytes!, f.name);
      if (mounted) setState(() => _videoCtrl.text = url);
      _toast(L10n.current.tutorVideoSent);
    });
  }

  Future<void> _pickDiploma() async {
    final f = await _pickFile(
        type: FileType.custom,
        extensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        maxMb: 10);
    if (f == null) return;
    await _send('diploma', () async {
      final url = await _service.uploadDocument(f.bytes!, f.name);
      await _service.submitVerificationDocument(url);
      _hydrate(await _service.getMine());
    });
  }

  Future<void> _activate() async {
    setState(() => _saving = true);
    try {
      final p = await _service.activate();
      _hydrate(p);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(L10n.current.teacherProfileActivated)));
    } catch (e) {
      // Le serveur dit ce qui manque (photo, matière, tarif…).
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(TutorProfileService.serverMessage(e) ??
                L10n.current.teacherProfileActivateError)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherProfileAiUnavailable)));
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
        title: Text(context.l10n.teacherProfileTitle,
            style: WinType.archivo(size: 18, color: s.onStrong)),
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              icon: Icon(
                  _showPreview
                      ? PhosphorIconsRegular.pencilSimple
                      : PhosphorIconsRegular.eye,
                  color: s.onMuted),
              tooltip: _showPreview
                  ? context.l10n.teacherProfileBackToEdit
                  : context.l10n.teacherProfilePreview,
              onPressed: () => setState(() => _showPreview = !_showPreview),
            ),
          if (_profile?.isActive == true)
            IconButton(
              icon: Icon(
                  // Icône pleine quand les vacances sont actives.
                  _profile!.isOnVacation
                      ? PhosphorIconsFill.airplaneTakeoff
                      : PhosphorIconsRegular.airplaneTakeoff,
                  color: _profile!.isOnVacation ? WinColors.warn : s.onMuted),
              tooltip: context.l10n.teacherProfileOnHoliday,
              onPressed: () async {
                final p = await _service.setVacation(!_profile!.isOnVacation);
                _hydrate(p);
              },
            ),
          if (_profile?.isActive == true)
            PopupMenuButton<String>(
              icon: Icon(PhosphorIconsBold.dotsThreeVertical, color: s.onMuted),
              onSelected: (_) => _deactivate(),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'off', child: Text(context.l10n.tutorDeactivate)),
              ],
            ),
        ],
      ),
      body: _loading
          ? const WinLoading()
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
            Text(p.title ?? context.l10n.tutoringDefaultName,
                style: WinType.archivo(size: 17, color: s.onStrong)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (p.isInPersonVerified && !p.inPersonSuspended)
                WinBadge(context.l10n.tutoringInPersonVerified, color: BadgeColor.success),
              if (p.isDiplomaVerified)
                WinBadge(context.l10n.tutoringDiplomaVerified, color: BadgeColor.teal),
              for (final n in p.endorsedByInstitutions)
                WinBadge(context.l10n.tutoringEndorsedBy(n), color: BadgeColor.blue),
              // Avis réels des élèves (note moyenne et nombre d'avis).
              if (p.reviewCount > 0 && p.averageRating != null)
                WinBadge(
                    context.l10n.teacherProfileRating(
                        WinFormat.decimal(p.averageRating!), p.reviewCount),
                    color: BadgeColor.gold)
              else
                WinBadge(context.l10n.teacherProfileNoReviews,
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
        Text(context.l10n.teacherProfileRate, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        Text(
            p.hourlyRateXaf != null
                ? '${WinFormat.number(p.hourlyRateXaf!)} XAF/h'
                : context.l10n.tutoringNotSpecified,
            style: WinType.bodyM(s.onMuted)),
        if (p.trialSessionEnabled) Text(context.l10n.teacherProfileTrialOffered),
      ])),
      const SizedBox(height: 12),
      WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.tutoringSubjectsLevels, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        Text(p.subjects.join(', ').isEmpty ? context.l10n.teacherProfileNoneF : p.subjects.map((m) => _subjectLabel(context, m)).join(', ')),
        Text(p.levels.join(', ').isEmpty ? context.l10n.teacherProfileNoneM : p.levels.map((l) => _levelLabel(context, l)).join(', ')),
      ])),
      // Les avis reçus, auxquels le répétiteur répond d'ici.
      TutorReviewsSection(tutorUserId: p.userId, canReply: true),
      const SizedBox(height: 20),
      WinButton(context.l10n.teacherProfileBookPreview, block: true, onTap: null),
    ]);
  }

  /// Libellé d'un élément manquant, traduit d'après son code ; le libellé du
  /// serveur (en français) sert de repli.
  String _missingLabel(Map<String, String> m) {
    final l = context.l10n;
    return switch (m['field']) {
      'photo' => l.tutorPhotoTitle,
      'subjects' => l.tutorMissingSubjects,
      'levels' => l.tutorMissingLevels,
      'interventionMode' => l.tutorMissingMode,
      'hourlyRate' => l.tutorMissingRate,
      'availability' => l.tutorMissingAvailability,
      'bio' => l.teacherProfileBio,
      'title' => l.teacherProfileProTitle,
      'video' => l.teacherProfileVideo,
      _ => m['label'] ?? '',
    };
  }

  int? _missingStep(String? field) => switch (field) {
        'subjects' || 'levels' => 0,
        'interventionMode' => 1,
        'hourlyRate' => 2,
        'availability' => 3,
        'photo' || 'bio' || 'title' || 'video' => 4,
        _ => null,
      };

  /// Retirer le profil de la recherche, après confirmation.
  Future<void> _deactivate() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(l.tutorDeactivateTitle),
              content: Text(l.tutorDeactivateBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l.commonCancel)),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l.tutorDeactivateConfirm)),
              ],
            ));
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      _hydrate(await _service.deactivate());
      _toast(L10n.current.tutorDeactivated);
    } catch (e) {
      _toast(TutorProfileService.serverMessage(e) ??
          L10n.current.teacherProfileSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildCompletion(WinScheme s) {
    final c = _completion!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // État du profil : brouillon, en ligne ou en vacances.
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _profile?.isActive != true
              ? WinBadge(context.l10n.tutorStateDraft, color: BadgeColor.neutral)
              : _profile?.isOnVacation == true
                  ? WinBadge(context.l10n.tutorStateVacation,
                      color: BadgeColor.warn)
                  : WinBadge(context.l10n.tutorStateOnline,
                      color: BadgeColor.success),
        ),
      ),
      // Profil actif qui ne remplit plus le minimum : il n'est plus proposé
      // aux élèves tant qu'il n'est pas complété.
      if (_profile?.isActive == true && _profile?.isListedInSearch == false)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WinAlert(context.l10n.tutorNotListed, type: BadgeColor.warn),
        ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(context.l10n.teacherProfileCompletion, style: WinType.bodyM(s.onMuted)),
        Text(WinFormat.percent(c.score),
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
            children: [
              for (final m in c.missingItems)
                ActionChip(
                  label: Text(_missingLabel(m),
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: winTone(s, BadgeColor.warn).bg,
                  side: BorderSide.none,
                  // Mène à l'étape où l'élément se renseigne.
                  onPressed: _missingStep(m['field']) == null
                      ? null
                      : () => setState(() {
                            _showPreview = false;
                            _step = _missingStep(m['field'])!;
                          }),
                ),
            ]),
      ],
    ]);
  }

  Widget _buildStepper(WinScheme s) {
    return Row(
        children: List.generate(_stepCount * 2 - 1, (i) {
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
            ? const Icon(PhosphorIconsBold.check, size: 14, color: WinColors.teal700)
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
          Text(context.l10n.teacherProfileSubjectsTaught, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _shown(_subjects, _subjectsSel))
                  WinChip(
                    _subjectLabel(context, m),
                    active: _subjectsSel.contains(m),
                    onTap: () => setState(() => _subjectsSel.contains(m)
                        ? _subjectsSel.remove(m)
                        : _subjectsSel.add(m)),
                  ),
                if (_ref.fromServer)
                  WinChip(context.l10n.tutoringMoreSubjects,
                      icon: PhosphorIconsRegular.plus,
                      onTap: () => _pickMore(subjects: true)),
              ]),
          const SizedBox(height: 20),
          Text(context.l10n.teacherProfileLevelsCovered, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in _shown(_levels, _levelsSel))
                  WinChip(
                    _levelLabel(context, l),
                    active: _levelsSel.contains(l),
                    onTap: () => setState(() => _levelsSel.contains(l)
                        ? _levelsSel.remove(l)
                        : _levelsSel.add(l)),
                  ),
                if (_ref.fromServer)
                  WinChip(context.l10n.tutoringMoreLevels,
                      icon: PhosphorIconsRegular.plus,
                      onTap: () => _pickMore(subjects: false)),
              ]),
          const SizedBox(height: 20),
          Text(context.l10n.teacherProfileSpecialties, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialties
                  .map((sp) => WinChip(
                        _specialtyLabel(context, sp),
                        active: _specialtiesSel.contains(sp),
                        onTap: () => setState(() => _specialtiesSel.contains(sp)
                            ? _specialtiesSel.remove(sp)
                            : _specialtiesSel.add(sp)),
                      ))
                  .toList()),
        ]);

      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.teacherProfileModes, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          CheckboxListTile(
              value: _online,
              onChanged: (v) => setState(() => _online = v ?? false),
              title: Text(context.l10n.teacherProfileOnlineViaWinplus),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading),
          // Lot 9.5 (17.11) : présentiel réservé aux tuteurs vérifiés (refusé aussi par le serveur).
          if (!_inPersonAllowed) ...[
            WinAlert(
                '${_profile?.inPersonBlockedReason ?? context.l10n.teacherProfileBlockedDefault} '
                '${_profile?.inPersonSuspended == true ? context.l10n.teacherProfileKeptSuspended : context.l10n.teacherProfileKeptUnverified}',
                type: BadgeColor.warn),
            const SizedBox(height: 6),
            WinButton(context.l10n.teacherProfileGetVerified,
                small: true,
                variant: WinButtonVariant.outline,
                icon: PhosphorIconsRegular.shieldCheck,
                onTap: _openVerification),
            const SizedBox(height: 6),
          ],
          // Lot 9.5 (17.17) : choix présentiels conservés, cochés mais grisés
          // « actif après vérification » tant que le présentiel n'est pas possible.
          _inPersonTile(s, context.l10n.teacherProfileAtStudentHome, _atStudent, (v) => setState(() => _atStudent = v)),
          _inPersonTile(s, context.l10n.teacherProfileAtMyHome, _atTutor, (v) => setState(() => _atTutor = v)),
          _inPersonTile(s, context.l10n.teacherProfileNeutralPlace, _neutral, (v) => setState(() => _neutral = v)),
          if (_atStudent || _atTutor) ...[
            const SizedBox(height: 12),
            Text(context.l10n.teacherProfileZones,
                style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              isExpanded: true,
              hint: Text(context.l10n.teacherProfileChooseCity),
              items: _tutorCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(_cityLabel(context, c))))
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
                isExpanded: true,
                hint: Text(context.l10n.teacherProfileDistrictHint),
                items: (_tutorQuartiers[_selectedCity] ?? [])
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedQuartier = v),
              )
            else if (_selectedCity == 'Autre ville')
              WinTextField(
                  controller: _customCityCtrl,
                  hint: context.l10n.teacherProfileCityOrDistrictHint),
            const SizedBox(height: 8),
            WinButton(context.l10n.teacherProfileAddZone,
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
          Text(context.l10n.teacherProfileHourlyRate, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _rateCtrl,
              hint: context.l10n.teacherProfileHourlyRateHint,
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          WinButton(_rateLoading ? context.l10n.commonWinaiThinking : context.l10n.teacherProfileAiSuggestion,
              variant: WinButtonVariant.outline,
              small: true,
              icon: winAIIconData,
              onTap: _rateLoading ? null : _suggestRate),
          if (_rateSuggestion != null) ...[
            const SizedBox(height: 10),
            WinAlert(
              context.l10n.teacherProfileRateSuggested(WinFormat.number(_rateSuggestion!.suggestedRateXaf), WinFormat.number(_rateSuggestion!.rangeLowXaf), WinFormat.number(_rateSuggestion!.rangeHighXaf), _rateSuggestion!.explanation),
              type: BadgeColor.blue,
            ),
            TextButton(
                onPressed: () => setState(() => _rateCtrl.text =
                    _rateSuggestion!.suggestedRateXaf.toString()),
                child: Text(context.l10n.teacherProfileUseRate)),
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
              title: Text(context.l10n.teacherProfileTrialToggle),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading),
          if (_trialEnabled)
            WinTextField(
                controller: _trialPriceCtrl,
                hint: context.l10n.teacherProfileTrialPriceHint,
                keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          // Lot 9.4 (17.7) : engagement mensuel, remise facultative bornée par le serveur.
          SwitchListTile(
              value: _monthlyEnabled,
              onChanged: (v) => setState(() => _monthlyEnabled = v),
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.teacherProfileMonthlyToggle),
              subtitle: Text(context.l10n.teacherProfileMonthlyDesc)),
          if (_monthlyEnabled) ...[
            WinTextField(
                controller: _monthlyDiscountCtrl,
                hint: context.l10n.teacherProfileMonthlyDiscountHint(_monthlyMaxDiscount),
                keyboardType: TextInputType.number),
            const SizedBox(height: 4),
            Text(context.l10n.teacherProfileMonthlyHint,
                style: WinType.labelS(s.onFaint)),
          ],
        ]);

      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.teacherProfileWeeklySlots,
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
                    child: Text(pi == 0 ? _dayShort(day) : '',
                        style: TextStyle(
                            fontSize: 10,
                            color: active ? Colors.white : s.onMuted)),
                  ),
                ),
              );
            }));
          })),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileNotice, style: WinType.labelM(s.onStrong)),
          Wrap(
              spacing: 8,
              children: [12, 24, 48]
                  .map((h) => WinChip(context.l10n.teacherProfileHours(h),
                      active: _notice == h,
                      onTap: () => setState(() => _notice = h)))
                  .toList()),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileMaxPerWeek, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _maxPerWeekCtrl,
              hint: context.l10n.teacherProfileUnlimited,
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          Text(context.l10n.tutoringCancellationPolicy, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 4),
          Text(
              context.l10n.teacherProfilePolicyIntro,
              style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 10),
          _policyStepper(s,
              label: context.l10n.teacherProfileFullRefund,
              suffix: context.l10n.teacherProfileHoursBefore,
              value: _fullRefundHours,
              min: _bound('fullRefundHoursMin', 12),
              max: _bound('fullRefundHoursMax', 48),
              step: 1,
              onChanged: (v) => setState(() {
                    _fullRefundHours = v;
                    if (_noRefundHours > v) _noRefundHours = v;
                  })),
          _policyStepper(s,
              label: context.l10n.teacherProfilePartialRefund,
              suffix: '%',
              value: _partialRefundPercent,
              min: _bound('partialRefundPercentMin', 0),
              max: _bound('partialRefundPercentMax', 100),
              step: 10,
              onChanged: (v) => setState(() => _partialRefundPercent = v)),
          _policyStepper(s,
              label: context.l10n.teacherProfileNoRefund,
              suffix: context.l10n.teacherProfileHoursBefore,
              value: _noRefundHours,
              min: _bound('noRefundHoursMin', 0),
              max: [_bound('noRefundHoursMax', 12), _fullRefundHours]
                  .reduce((a, b) => a < b ? a : b),
              step: 1,
              onChanged: (v) => setState(() => _noRefundHours = v)),
          const SizedBox(height: 6),
          Text(
              context.l10n.teacherProfilePolicyBounds(
                  _bound('fullRefundHoursMin', 12),
                  _bound('fullRefundHoursMax', 48),
                  _bound('partialRefundPercentMin', 0),
                  _bound('partialRefundPercentMax', 100),
                  _bound('noRefundHoursMin', 0),
                  _bound('noRefundHoursMax', 12)),
              style: WinType.labelS(s.onFaint)),
        ]);

      case 4:
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Photo : obligatoire pour publier le profil.
          Text(context.l10n.tutorPhotoTitle, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Row(children: [
            ClipOval(
              child: SizedBox(
                width: 64,
                height: 64,
                child: (_avatarUrl ?? '').isEmpty
                    ? WinAvatar(_profile?.fullName ?? '', size: 64)
                    : NetImage(_avatarUrl!,
                        error: (_) =>
                            WinAvatar(_profile?.fullName ?? '', size: 64)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.tutorPhotoHint,
                        style: WinType.bodyS(s.onMuted)),
                    const SizedBox(height: 8),
                    WinButton(
                        (_avatarUrl ?? '').isEmpty
                            ? context.l10n.tutorPhotoPick
                            : context.l10n.tutorPhotoChange,
                        small: true,
                        variant: WinButtonVariant.outline,
                        icon: PhosphorIconsRegular.camera,
                        loading: _uploading == 'photo',
                        onTap: _uploading == null ? _pickPhoto : null),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileProTitle, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
              controller: _titleCtrl, hint: context.l10n.teacherProfileProTitleHint),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileBio,
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          TextField(controller: _bioCtrl, maxLength: 300, maxLines: 4),
          const SizedBox(height: 8),
          Text(context.l10n.teacherProfileStyle, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: _styles
                  .map((st) => WinChip(_styleLabel(context, st),
                      active: _teachingStyle == st,
                      onTap: () => setState(() => _teachingStyle = st)))
                  .toList()),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileVideo,
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Text(context.l10n.tutorVideoHint, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 8),
          WinButton(context.l10n.tutorVideoUpload,
              small: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.videoCamera,
              loading: _uploading == 'video',
              onTap: _uploading == null ? _pickVideo : null),
          const SizedBox(height: 8),
          WinTextField(
              controller: _videoCtrl, hint: context.l10n.tutorVideoLinkHint),
          const SizedBox(height: 16),
          // Lot 9.5 : vérification pour le présentiel (identité, entretien, caution).
          WinCard(
            onTap: _openVerification,
            child: Row(children: [
              Icon(PhosphorIconsRegular.shieldCheck, color: s.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.l10n.teacherProfileVerification, style: WinType.titleM(s.onStrong)),
                  Text(
                      _profile?.inPersonSuspended == true
                          ? context.l10n.teacherProfileVerifSuspended
                          : _profile?.isInPersonVerified == true
                              ? context.l10n.teacherProfileVerifOpen
                              : context.l10n.teacherProfileVerifRoutes,
                      style: WinType.labelS(s.onMuted)),
                ]),
              ),
              Icon(PhosphorIconsRegular.caretRight, color: s.onFaint),
            ]),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.teacherProfileDiploma,
              style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          if (_profile?.pendingOrLatestDocument != null)
            WinAlert(context.l10n.teacherProfileDocStatus(_profile!.pendingOrLatestDocument!.status),
                type: BadgeColor.neutral)
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.tutorDiplomaHint,
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 8),
              WinButton(context.l10n.tutorDiplomaAttach,
                  small: true,
                  variant: WinButtonVariant.outline,
                  icon: PhosphorIconsRegular.paperclip,
                  loading: _uploading == 'diploma',
                  onTap: _uploading == null ? _pickDiploma : null),
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
          icon: const Icon(PhosphorIconsRegular.minusCircle),
          onPressed: v > min ? () => onChanged((v - step).clamp(min, max)) : null,
        ),
        SizedBox(
          width: 64,
          child: Text('$v $suffix',
              textAlign: TextAlign.center, style: WinType.labelM(s.onStrong)),
        ),
        IconButton(
          icon: const Icon(PhosphorIconsRegular.plusCircle),
          onPressed: v < max ? () => onChanged((v + step).clamp(min, max)) : null,
        ),
      ]),
    );
  }

  Widget _buildActions(WinScheme s) {
    // Wrap : sur un ecran etroit, les boutons passent a la ligne au lieu de
    // deborder (derniere etape : Precedent, Enregistrer et Activer).
    return Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 8,
        children: [
      WinButton(context.l10n.teacherProfilePrevious,
          variant: WinButtonVariant.ghost,
          onTap:
              _step == 0 || _saving ? null : () => setState(() => _step -= 1)),
      if (_step < 4)
        WinButton(_saving ? context.l10n.teacherProfileSaving : context.l10n.commonContinue,
            loading: _saving,
            onTap: _saving ? null : () => _saveStep(next: _step + 1))
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          WinButton(context.l10n.commonSave,
              variant: WinButtonVariant.outline,
              loading: _saving,
              onTap: _saving ? null : () => _saveStep()),
          if (_profile?.isActive != true)
            WinButton(context.l10n.teacherProfileActivate,
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
