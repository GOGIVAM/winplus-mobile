import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/session_manager.dart';
import '../services/user_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'onboarding_success_screen.dart';

/// Complétion de profil après vérification d'email. Le contenu s'adapte au
/// rôle du compte (student/teacher/parent/institution)  un professeur n'a
/// pas de "niveau scolaire actuel", il déclare plutôt ce qu'il enseigne
/// (US-PRO-02, professeur_complete.md). Persisté via PUT /users/profile
/// (UserService.updateProfile) au lieu de rester purement local.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  WinRole? _role;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final roleStr = await SessionManager.getUserRole();
    final role = WinRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => WinRole.student,
    );
    if (mounted)
      setState(() {
        _role = role;
        _loadingRole = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      final s = WinTheme.of(context);
      return Scaffold(
        backgroundColor: s.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Institution : pas de données d'onboarding dédiées  on va directement
    // à l'écran de succès (déjà adapté au rôle).
    if (_role == WinRole.institution) {
      return OnboardingSuccessScreen(role: _role!);
    }

    // Module 15 (lot 6) : le parent a désormais son propre onboarding
    // (objectif pour l'enfant + préférence de suivi), parité avec le web
    // (CompleteProfile.tsx, ParentOnboarding). Avant ce module, il sautait
    // directement à l'écran de succès, par choix produit non documenté
    // ailleurs qu'en commentaire de code.
    if (_role == WinRole.parent) {
      return const _ParentProfileWizard();
    }

    return _role == WinRole.teacher
        ? const _TeacherProfileWizard()
        : const _StudentProfileWizard();
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   Étudiant  niveau / filière / objectif (comportement historique).
   ═══════════════════════════════════════════════════════════════════════ */

class _StudentProfileWizard extends StatefulWidget {
  const _StudentProfileWizard();
  @override
  State<_StudentProfileWizard> createState() => _StudentProfileWizardState();
}

class _StudentProfileWizardState extends State<_StudentProfileWizard> {
  int _step = 0;
  String? _level, _filiere, _objectif;
  bool _saving = false;
  // Décision 15.3 (arbitrages lot 7, 2026-10-08) : facultative, jamais
  // bloquante (_canContinue n'en dépend pas)  demandée ici plutôt que
  // d'ajouter une étape dédiée, parité avec le web (CompleteProfile.tsx).
  DateTime? _dateOfBirth;

  static const _levels = [
    'BEPC',
    'Probatoire',
    'BAC',
    'BTS',
    'Licence',
    'Concours'
  ];
  static const _filieres = [
    'Scientifique',
    'Littéraire',
    'Technique',
    'Économique'
  ];
  static const _objectifs = [
    'BAC A',
    'BAC C',
    'BAC D',
    'BEPC',
    'ENSP',
    'FMSB',
    'Polytechnique',
    'Autre'
  ];

  bool get _canContinue => switch (_step) {
        0 => _level != null,
        1 => _filiere != null,
        _ => _objectif != null,
      };

  Future<void> _next() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await UserService.instance.updateProfile(
      level: _level,
      specialization: _filiere,
      targetExam: _objectif,
      dateOfBirth: _dateOfBirth == null
          ? null
          : '${_dateOfBirth!.year.toString().padLeft(4, '0')}-'
              '${_dateOfBirth!.month.toString().padLeft(2, '0')}-'
              '${_dateOfBirth!.day.toString().padLeft(2, '0')}',
    );
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        WinPageRoute(
            builder: (_) =>
                const OnboardingSuccessScreen(role: WinRole.student)));
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: context.l10n.authDobOptional,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    final steps = [l10n.commonLevel, l10n.authStepStream, l10n.authStepGoal];
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            Row(children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WinProgressBar(i <= _step ? 100 : 0,
                            height: 3,
                            color: i < _step
                                ? s.primary
                                : (i == _step ? s.primary : s.outline)),
                        const SizedBox(height: 4),
                        Text(steps[i],
                            style: WinType.labelS(
                                    i == _step ? s.primary : s.onFaint)
                                .copyWith(
                                    fontWeight: i == _step
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                      ]),
                ),
              ],
            ]),
            const SizedBox(height: 40),
            Text(_stepTitle, style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(_stepSubtitle, style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChips(s)),
                  if (_step == 0) _buildDateOfBirthField(s),
                ],
              ),
            ),
            WinButton(
              _step < 2 ? l10n.commonContinue : l10n.authFinish,
              block: true,
              loading: _saving,
              onTap: _canContinue && !_saving ? _next : null,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField(WinScheme s) {
    final label = _dateOfBirth == null
        ? context.l10n.authDobOptional
        : context.l10n.authBornOn(WinFormat.dateNumeric(_dateOfBirth!));
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: _pickDateOfBirth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(WinRadii.md),
            border: Border.all(color: s.outline, width: 1.5),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: s.onMuted),
            const SizedBox(width: 10),
            Text(label, style: WinType.bodyM(s.onMuted)),
          ]),
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => context.l10n.authStudentLevelTitle,
        1 => context.l10n.authStudentStreamTitle,
        _ => context.l10n.authStudentGoalTitle,
      };

  String get _stepSubtitle => switch (_step) {
        0 => context.l10n.authStudentLevelHint,
        1 => context.l10n.authStudentStreamHint,
        _ => context.l10n.authStudentGoalHint,
      };

  /// Libellé affiché d'une option ; la valeur envoyée à l'API reste le
  /// texte français de la liste.
  String _optionLabel(String v) {
    final l10n = context.l10n;
    return switch (v) {
      'Concours' => l10n.authOptConcours,
      'Scientifique' => l10n.authOptScience,
      'Littéraire' => l10n.authOptLiterary,
      'Technique' => l10n.authOptTechnical,
      'Économique' => l10n.authOptEconomics,
      'Polytechnique' => l10n.authOptPolytechnique,
      'Autre' => l10n.authOptOther,
      _ => v,
    };
  }

  Widget _buildChips(WinScheme s) {
    final (items, selected, onSelect) = switch (_step) {
      0 => (_levels, _level, (String v) => setState(() => _level = v)),
      1 => (_filieres, _filiere, (String v) => setState(() => _filiere = v)),
      _ => (_objectifs, _objectif, (String v) => setState(() => _objectif = v)),
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final active = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: active ? WinColors.ink800 : s.surface,
              borderRadius: BorderRadius.circular(WinRadii.full),
              border: Border.all(
                  color: active ? WinColors.ink800 : s.outline, width: 1.5),
            ),
            child: Text(_optionLabel(item),
                style: WinType.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: active ? WinColors.cream50 : s.onSurface)),
          ),
        );
      }).toList(),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   Professeur  matières / niveaux enseignés (US-PRO-02). Multiselect,
   persisté sur User.TeachingSubjects/TeachingLevels (PUT /users/profile),
   réutilisable plus tard pour préremplir l'onboarding Mode Répétiteur.
   ═══════════════════════════════════════════════════════════════════════ */

class _TeacherProfileWizard extends StatefulWidget {
  const _TeacherProfileWizard();
  @override
  State<_TeacherProfileWizard> createState() => _TeacherProfileWizardState();
}

class _TeacherProfileWizardState extends State<_TeacherProfileWizard> {
  int _step = 0;
  final Set<String> _subjects = {};
  final Set<String> _levels = {};
  bool _saving = false;

  static const _teacherLevels = [
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
    'BTS',
    'Prépa',
    'ENSP Polytechnique',
    'FMSB Médecine',
    'ESSEC Commerce',
    'ENAM Administration',
    'ENS École Normale',
    'ENSET',
  ];

  bool get _canContinue =>
      _step == 0 ? _subjects.isNotEmpty : _levels.isNotEmpty;

  Future<void> _next() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() => _saving = true);
    await UserService.instance.updateProfile(
      teachingSubjects: _subjects.toList(),
      teachingLevels: _levels.toList(),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        WinPageRoute(
            builder: (_) =>
                const OnboardingSuccessScreen(role: WinRole.teacher)));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    final steps = [l10n.authStepSubjects, l10n.authStepLevels];
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            Row(children: [
              for (int i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WinProgressBar(i <= _step ? 100 : 0,
                            height: 3,
                            color: i < _step
                                ? s.primary
                                : (i == _step ? s.primary : s.outline)),
                        const SizedBox(height: 4),
                        Text(steps[i],
                            style: WinType.labelS(
                                    i == _step ? s.primary : s.onFaint)
                                .copyWith(
                                    fontWeight: i == _step
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                      ]),
                ),
              ],
            ]),
            const SizedBox(height: 40),
            Text(
                _step == 0
                    ? l10n.authTeacherSubjectsTitle
                    : l10n.authTeacherLevelsTitle,
                style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? l10n.authTeacherSubjectsHint
                  : l10n.authTeacherLevelsHint,
              style: WinType.bodyM(s.onMuted),
            ),
            const SizedBox(height: 28),
            Expanded(child: _buildChips(s)),
            WinButton(
              _step == 0 ? l10n.commonContinue : l10n.authFinish,
              block: true,
              loading: _saving,
              onTap: _canContinue && !_saving ? _next : null,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildChips(WinScheme s) {
    final items = _step == 0
        ? WinData.subjects.map((sub) => sub.nameFr).toList()
        : _teacherLevels;
    final selectedSet = _step == 0 ? _subjects : _levels;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final active = selectedSet.contains(item);
        return GestureDetector(
          onTap: () => setState(
              () => active ? selectedSet.remove(item) : selectedSet.add(item)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: active ? WinColors.ink800 : s.surface,
              borderRadius: BorderRadius.circular(WinRadii.full),
              border: Border.all(
                  color: active ? WinColors.ink800 : s.outline, width: 1.5),
            ),
            child: Text(_itemLabel(item),
                style: WinType.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: active ? WinColors.cream50 : s.onSurface)),
          ),
        );
      }).toList(),
    );
  }

  /// Libellé affiché ; la valeur enregistrée reste le texte français
  /// (nom de matière ou niveau) envoyé à l'API.
  String _itemLabel(String v) {
    final l10n = context.l10n;
    for (final sub in WinData.subjects) {
      if (sub.nameFr == v) return sub.name;
    }
    return switch (v) {
      'Prépa' => l10n.authLvlPrepa,
      'FMSB Médecine' => l10n.authLvlFmsb,
      'ESSEC Commerce' => l10n.authLvlEssec,
      'ENS École Normale' => l10n.authLvlEns,
      _ => ClassLevels.label(v),
    };
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   Parent  Module 15 (lot 6). Collecte strictement les deux informations
   citées par la décision produit (SUIVI_VERSEMENTS_ET_CORRECTIONS.md
   §2.7) : objectif libre pour l'enfant/les enfants, et préférence de suivi.
   Non bloquant (bouton "Passer" disponible à chaque étape), persisté sur
   User.ParentChildObjective / User.ParentFollowUpPreference (PUT
   /users/profile), parité avec ParentOnboarding côté web.
   ═══════════════════════════════════════════════════════════════════════ */

class _ParentProfileWizard extends StatefulWidget {
  const _ParentProfileWizard();
  @override
  State<_ParentProfileWizard> createState() => _ParentProfileWizardState();
}

class _ParentProfileWizardState extends State<_ParentProfileWizard> {
  int _step = 0;
  final _objectiveCtrl = TextEditingController();
  String? _followUp;
  bool _saving = false;

  static List<(String, String, String)> _followUpOptions(
          AppLocalizations l10n) =>
      [
        ('close', l10n.authFollowCloseLabel, l10n.authFollowCloseHint),
        ('weekly', l10n.authFollowWeeklyLabel, l10n.authFollowWeeklyHint),
        ('minimal', l10n.authFollowMinimalLabel, l10n.authFollowMinimalHint),
      ];

  bool get _canContinue =>
      _step == 0 ? _objectiveCtrl.text.trim().isNotEmpty : _followUp != null;

  Future<void> _skip() async {
    if (!mounted) return;
    Navigator.pushReplacement(context,
        WinPageRoute(builder: (_) => const OnboardingSuccessScreen(role: WinRole.parent)));
  }

  Future<void> _next() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() => _saving = true);
    await UserService.instance.updateProfile(
      parentChildObjective: _objectiveCtrl.text.trim(),
      parentFollowUpPreference: _followUp,
    );
    if (!mounted) return;
    Navigator.pushReplacement(context,
        WinPageRoute(builder: (_) => const OnboardingSuccessScreen(role: WinRole.parent)));
  }

  @override
  void dispose() {
    _objectiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    final steps = [l10n.authStepGoal, l10n.authStepFollowUp];
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            Row(children: [
              for (int i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WinProgressBar(i <= _step ? 100 : 0,
                            height: 3,
                            color: i < _step
                                ? s.primary
                                : (i == _step ? s.primary : s.outline)),
                        const SizedBox(height: 4),
                        Text(steps[i],
                            style: WinType.labelS(
                                    i == _step ? s.primary : s.onFaint)
                                .copyWith(
                                    fontWeight: i == _step
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                      ]),
                ),
              ],
            ]),
            const SizedBox(height: 40),
            Text(
                _step == 0
                    ? l10n.authParentGoalTitle
                    : l10n.authParentFollowTitle,
                style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? l10n.authParentGoalHint
                  : l10n.authParentFollowHint,
              style: WinType.bodyM(s.onMuted),
            ),
            const SizedBox(height: 28),
            Expanded(child: _step == 0 ? _buildObjectiveField(s) : _buildFollowUpChoices(s)),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: Text(l10n.authSkipStep),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WinButton(
                  _step == 0 ? l10n.commonContinue : l10n.authFinish,
                  block: true,
                  loading: _saving,
                  onTap: _canContinue && !_saving ? _next : null,
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildObjectiveField(WinScheme s) {
    return TextField(
      controller: _objectiveCtrl,
      maxLength: 300,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: context.l10n.authParentGoalPlaceholder,
        filled: true,
        fillColor: s.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WinRadii.md),
          borderSide: BorderSide(color: s.outline),
        ),
      ),
      style: WinType.bodyM(s.onSurface),
    );
  }

  Widget _buildFollowUpChoices(WinScheme s) {
    return Column(
      children: _followUpOptions(context.l10n).map((opt) {
        final (value, label, hint) = opt;
        final active = _followUp == value;
        return GestureDetector(
          onTap: () => setState(() => _followUp = value),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: active ? WinColors.ink800 : s.surface,
              borderRadius: BorderRadius.circular(WinRadii.md),
              border: Border.all(
                  color: active ? WinColors.ink800 : s.outline, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: WinType.manrope(
                        size: 14,
                        weight: FontWeight.w700,
                        color: active ? WinColors.cream50 : s.onSurface)),
                const SizedBox(height: 4),
                Text(hint,
                    style: WinType.manrope(
                        size: 12,
                        weight: FontWeight.w500,
                        color: active
                            ? WinColors.cream50.withValues(alpha: 0.85)
                            : s.onMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
