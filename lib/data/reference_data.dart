import 'models.dart';
import '../theme/win_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Listes de référence de l'application (matières et profils).
///
/// Les valeurs (identifiants, noms français enregistrés côté serveur) sont
/// fixes ; les libellés affichés passent par les fichiers de langue
/// ([Subject.name], [Subject.short], libellés des profils dans role_screen).
/// Remplace l'ancien mock_data.dart, dont toutes les données de
/// démonstration ont été retirées (lot 5).
class WinData {
  WinData._();

  static const subjects = <Subject>[
    Subject(
        'math', 'Mathématiques', 'Maths', WinColors.blue500, PhosphorIconsRegular.function),
    Subject('pc', 'Physique', 'Physique', WinColors.teal500,
        PhosphorIconsRegular.flask),
    Subject(
        'chimie', 'Chimie', 'Chimie', WinColors.ink700, PhosphorIconsRegular.dna),
    Subject(
        'fr', 'Français', 'Français', WinColors.gold, PhosphorIconsRegular.bookOpen),
    Subject('angl', 'Anglais', 'Anglais', WinColors.blue700, PhosphorIconsRegular.globe),
    Subject('svt', 'SVT', 'SVT', WinColors.success, PhosphorIconsRegular.leaf),
    Subject('info', 'Informatique', 'Info', WinColors.ink600, PhosphorIconsRegular.cpu),
    Subject('philo', 'Philosophie', 'Philo', WinColors.blue400,
        PhosphorIconsRegular.brain),
    Subject('hg', 'Histoire-Géo', 'Hist-Géo', WinColors.gold, PhosphorIconsRegular.globe),
    // Matière non reconnue (culture générale, spécialités…) : visuel neutre.
    Subject('autre', 'Autre', 'Autre', WinColors.teal600,
        PhosphorIconsRegular.fileText),
  ];

  static Subject subjectById(String id) =>
      subjects.firstWhere((s) => s.id == id, orElse: () => subjectByName(id));

  /// Matière d'après son nom tel que l'envoie le serveur (« Mathématiques »,
  /// « mathematiques », « Maths », « Physique-Chimie »…), sans tenir compte
  /// des accents ni de la casse ; « Autre » si rien ne correspond.
  static Subject subjectByName(String name) {
    String norm(String v) => v
        .toLowerCase()
        .replaceAll(RegExp('[\u00e0\u00e2\u00e4]'), 'a')
        .replaceAll(RegExp('[\u00e9\u00e8\u00ea\u00eb]'), 'e')
        .replaceAll(RegExp('[\u00ee\u00ef]'), 'i')
        .replaceAll(RegExp('[\u00f4\u00f6]'), 'o')
        .replaceAll(RegExp('[\u00f9\u00fb\u00fc]'), 'u')
        .replaceAll('\u00e7', 'c')
        .trim();
    final n = norm(name);
    if (n.isEmpty) return subjects.last;
    for (final s in subjects) {
      if (n == s.id || n == norm(s.nameFr) || n == norm(s.shortFr)) return s;
    }
    for (final s in subjects.take(subjects.length - 1)) {
      if (n.startsWith(norm(s.shortFr)) || n.contains(norm(s.nameFr))) return s;
    }
    return subjects.last;
  }

  static const roles = <RoleInfo>[
    RoleInfo(
        WinRole.student,
        'Étudiant / Apprenant',
        'Du BEPC aux concours des grandes écoles',
        PhosphorIconsRegular.graduationCap,
        WinColors.blue500),
    RoleInfo(
        WinRole.parent,
        'Parent / Tuteur',
        'Suivi et accompagnement de mes enfants',
        PhosphorIconsRegular.users,
        WinColors.teal600),
    RoleInfo(
        WinRole.teacher,
        'Professeur / Formateur',
        'Publication de contenus et suivi des apprenants',
        PhosphorIconsRegular.bookOpen,
        WinColors.ink700),
    RoleInfo(
        WinRole.institution,
        'Institution',
        'Lycée, université ou centre de formation',
        PhosphorIconsRegular.buildings,
        WinColors.gold),
  ];
}
