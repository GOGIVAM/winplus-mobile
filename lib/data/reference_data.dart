import 'package:flutter/material.dart';
import 'models.dart';
import '../theme/win_colors.dart';

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
        'math', 'Mathématiques', 'Maths', WinColors.blue500, Icons.functions),
    Subject('pc', 'Physique', 'Physique', WinColors.teal500,
        Icons.science_outlined),
    Subject(
        'chimie', 'Chimie', 'Chimie', WinColors.ink700, Icons.biotech_outlined),
    Subject(
        'fr', 'Français', 'Français', WinColors.gold, Icons.menu_book_outlined),
    Subject('angl', 'Anglais', 'Anglais', WinColors.blue700, Icons.language),
    Subject('svt', 'SVT', 'SVT', WinColors.success, Icons.eco_outlined),
    Subject('info', 'Informatique', 'Info', WinColors.ink600, Icons.memory),
    Subject('philo', 'Philosophie', 'Philo', WinColors.blue400,
        Icons.psychology_outlined),
    Subject('hg', 'Histoire-Géo', 'Hist-Géo', Color(0xFF8A6D3B), Icons.public),
  ];

  static Subject subjectById(String id) =>
      subjects.firstWhere((s) => s.id == id, orElse: () => subjects.first);

  static const roles = <RoleInfo>[
    RoleInfo(
        WinRole.student,
        'Étudiant / Apprenant',
        'Du BEPC aux concours des grandes écoles',
        Icons.school_outlined,
        WinColors.blue500),
    RoleInfo(
        WinRole.parent,
        'Parent / Tuteur',
        'Suivi et accompagnement de mes enfants',
        Icons.people_outline,
        WinColors.teal600),
    RoleInfo(
        WinRole.teacher,
        'Professeur / Formateur',
        'Publication de contenus et suivi des apprenants',
        Icons.menu_book_outlined,
        WinColors.ink700),
    RoleInfo(
        WinRole.institution,
        'Institution',
        'Lycée, université ou centre de formation',
        Icons.apartment_outlined,
        WinColors.gold),
  ];
}
