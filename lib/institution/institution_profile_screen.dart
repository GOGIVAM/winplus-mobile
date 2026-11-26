import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_profile_service.dart';
import '../services/user_service.dart';
import '../shared/net_image.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

String institutionTypeLabel(BuildContext context, String v) {
  final l = context.l10n;
  return switch (v) {
    'ecole_primaire' => l.instTypePrimary,
    'college' => l.instTypeCollege,
    'lycee' => l.instTypeLycee,
    'lycee_technique' => l.instTypeTechnical,
    'universite' => l.instTypeUniversity,
    'grande_ecole' => l.instTypeGrandeEcole,
    'centre_formation' => l.instTypeTraining,
    'centre_concours' => l.instTypeExamPrep,
    _ => v,
  };
}

/// Fiche de l'établissement, modifiable par son compte : logo, coordonnées,
/// type, cycles, sous-système, effectif et objectifs. Le nom passe par une
/// demande à l'équipe WinPlus.
class InstitutionProfileScreen extends StatefulWidget {
  const InstitutionProfileScreen({super.key});
  @override
  State<InstitutionProfileScreen> createState() =>
      _InstitutionProfileScreenState();
}

class _InstitutionProfileScreenState extends State<InstitutionProfileScreen> {
  final _svc = InstitutionProfileService.instance;
  InstitutionProfile? _p;
  InstitutionProfileException? _error;
  bool _saving = false, _logoBusy = false;

  final _name = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _students = TextEditingController();
  String _type = '', _subsystem = '', _teaching = '';
  Set<String> _cycles = {}, _goals = {};
  String? _logoUrl;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _city, _region, _address, _phone, _email, _students]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(InstitutionProfile p) {
    _p = p;
    _name.text = p.name;
    _city.text = p.city;
    _region.text = p.region;
    _address.text = p.address;
    _phone.text = p.phone;
    _email.text = p.email;
    _students.text = p.studentsEstimate > 0 ? '${p.studentsEstimate}' : '';
    _type = p.type;
    _subsystem = p.subsystem;
    _teaching = p.teaching;
    _cycles = p.cycles.toSet();
    _goals = p.goals.toSet();
    _logoUrl = p.logoUrl;
  }

  Future<void> _load() async {
    setState(() {
      _p = null;
      _error = null;
    });
    try {
      final p = await _svc.load();
      if (mounted) setState(() => _fill(p));
    } on InstitutionProfileException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickLogo() async {
    final shot = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 88);
    if (shot == null) return;
    setState(() => _logoBusy = true);
    try {
      final url = await UserService.instance
          .uploadAvatar(await shot.readAsBytes(), shot.name);
      if (url == null) {
        _toast(L10n.current.tutorUploadFailed);
      } else if (mounted) {
        setState(() => _logoUrl = url);
      }
    } catch (_) {
      _toast(L10n.current.tutorUploadFailed);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final p = _p!;
    if (_city.text.trim().isEmpty) {
      setState(() => _fieldError = l.instProfileCityRequired);
      return;
    }
    if (_cycles.isEmpty) {
      setState(() => _fieldError = l.instProfileCycleRequired);
      return;
    }
    // Seuls les champs modifiés partent : le nom ne déclenche une demande à
    // l'équipe que s'il a vraiment changé.
    final changes = <String, dynamic>{};
    void put(String key, String now, String before) {
      if (now.trim() != before) changes[key] = now.trim();
    }

    put('name', _name.text, p.name);
    put('city', _city.text, p.city);
    put('region', _region.text, p.region);
    put('address', _address.text, p.address);
    put('phone', _phone.text, p.phone);
    put('email', _email.text, p.email);
    put('type', _type, p.type);
    put('subsystem', _subsystem, p.subsystem);
    put('teaching', _teaching, p.teaching);
    final students = int.tryParse(_students.text.trim()) ?? 0;
    if (students != p.studentsEstimate) changes['studentsEstimate'] = students;
    if (!_sameSet(_cycles, p.cycles)) changes['cycles'] = _ordered(InstitutionChoices.cycles, _cycles);
    if (!_sameSet(_goals, p.goals)) changes['goals'] = _ordered(InstitutionChoices.goals, _goals);
    if (changes.isEmpty) {
      _toast(l.instProfileNoChange);
      return;
    }
    setState(() {
      _saving = true;
      _fieldError = null;
    });
    try {
      final r = await _svc.save(changes);
      if (!mounted) return;
      setState(() => _fill(r.profile));
      _toast(r.nameChangeRequested ? l.instProfileNameRequested : l.instProfileSaved);
    } on InstitutionProfileException catch (e) {
      if (mounted) setState(() => _fieldError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static bool _sameSet(Set<String> a, List<String> b) =>
      a.length == b.toSet().length && a.containsAll(b);
  static List<String> _ordered(List<String> order, Set<String> picked) =>
      [for (final v in order) if (picked.contains(v)) v];

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final Widget body;
    final error = _error;
    if (error != null) {
      body = error.routeMissing
          ? WinEmptyState(
              title: l.instProfileUnavailable,
              message: l.instProfileUnavailableHint,
              icon: PhosphorIconsRegular.buildings)
          : error.notLinked
              ? WinEmptyState(
                  title: l.instProfileNotLinked,
                  message: error.message,
                  icon: PhosphorIconsRegular.buildings)
              : WinErrorState(message: error.message, onRetry: _load);
    } else if (_p == null) {
      body = const WinLoading();
    } else {
      body = _form(s);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.instProfileTitle)),
      body: body,
    );
  }

  Widget _form(WinScheme s) {
    final l = context.l10n;
    Widget section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(t, style: WinType.titleL(s.onStrong)));
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t, style: WinType.titleM(s.onStrong)));
    Widget single(List<String> values, String current,
            String Function(String) text, ValueChanged<String> pick) =>
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            WinChip(text(v),
                active: v == current, onTap: () => setState(() => pick(v))),
        ]);
    Widget multi(List<String> values, Set<String> picked,
            String Function(String) text) =>
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            WinChip(text(v),
                active: picked.contains(v),
                onTap: () => setState(
                    () => picked.contains(v) ? picked.remove(v) : picked.add(v))),
        ]);

    String cycle(String v) => switch (v) {
          'primaire' => l.instCyclePrimary,
          'secondaire' => l.instCycleSecondary,
          'superieur' => l.instCycleHigher,
          'concours' => l.instCycleExams,
          _ => v,
        };
    String subsystem(String v) => switch (v) {
          'fr' => l.instSubsystemFr,
          'en' => l.instSubsystemEn,
          'bilingue' => l.instSubsystemBilingual,
          _ => v,
        };
    String teaching(String v) => switch (v) {
          'general' => l.instTeachingGeneral,
          'technique' => l.instTeachingTechnical,
          'both' => l.instTeachingBoth,
          _ => v,
        };
    String goal(String v) => switch (v) {
          'suivi' => l.instGoalTracking,
          'examens' => l.instGoalExams,
          'devoirs' => l.instGoalHomework,
          'parents' => l.instGoalParents,
          'enseignants' => l.instGoalTeachers,
          'orientation' => l.instGoalGuidance,
          _ => v,
        };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Logo et code de l'établissement.
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(WinRadii.lg),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _logoUrl == null
                  ? Container(
                      color: winTone(s, BadgeColor.gold).bg,
                      child: Icon(PhosphorIconsRegular.buildings,
                          size: 34, color: winTone(s, BadgeColor.gold).fg))
                  : NetImage(_logoUrl!,
                      error: (_) => Container(
                          color: winTone(s, BadgeColor.gold).bg,
                          child: Icon(PhosphorIconsRegular.buildings,
                              size: 34,
                              color: winTone(s, BadgeColor.gold).fg))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_p!.code.isNotEmpty)
                    Text(l.instProfileCode(_p!.code),
                        style: WinType.bodyS(s.onMuted)),
                  const SizedBox(height: 8),
                  WinButton(
                      _logoUrl == null
                          ? l.instProfileLogoPick
                          : l.instProfileLogoChange,
                      small: true,
                      variant: WinButtonVariant.outline,
                      icon: PhosphorIconsRegular.image,
                      loading: _logoBusy,
                      onTap: _logoBusy ? null : _pickLogo),
                ]),
          ),
        ]),

        section(l.instProfileIdentity),
        WinTextField(label: l.instProfileName, controller: _name),
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l.instProfileNameHint, style: WinType.bodyS(s.onMuted))),
        label(l.instProfileType),
        single(InstitutionChoices.types, _type,
            (v) => institutionTypeLabel(context, v), (v) => _type = v),

        section(l.instProfileContact),
        WinTextField(label: l.instProfileCity, controller: _city),
        const SizedBox(height: 12),
        WinTextField(label: l.instProfileRegion, controller: _region),
        const SizedBox(height: 12),
        WinTextField(label: l.instProfileAddress, controller: _address),
        const SizedBox(height: 12),
        WinTextField(
            label: l.instProfilePhone,
            controller: _phone,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        WinTextField(
            label: l.instProfileEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress),

        section(l.instProfileTeaching),
        label(l.instProfileCycles),
        multi(InstitutionChoices.cycles, _cycles, cycle),
        label(l.instProfileSubsystem),
        single(InstitutionChoices.subsystems, _subsystem, subsystem,
            (v) => _subsystem = v),
        label(l.instProfileTeachingKind),
        single(InstitutionChoices.teachings, _teaching, teaching,
            (v) => _teaching = v),
        const SizedBox(height: 14),
        WinTextField(
            label: l.instProfileStudents,
            controller: _students,
            keyboardType: TextInputType.number),

        section(l.instProfileGoals),
        multi(InstitutionChoices.goals, _goals, goal),

        if (_fieldError != null) ...[
          const SizedBox(height: 18),
          WinAlert(_fieldError!, type: BadgeColor.error),
        ],
        const SizedBox(height: 22),
        WinButton(l.commonSave,
            block: true, loading: _saving, onTap: _saving ? null : _save),
      ],
    );
  }
}
