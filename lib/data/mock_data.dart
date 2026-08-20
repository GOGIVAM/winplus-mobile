import 'package:flutter/material.dart';
import 'models.dart';
import '../theme/win_colors.dart';

/// WINPLUS  Données de démonstration (contenu camerounais réaliste).
/// Prix XAF conformes à la grille tarifaire du cahier des charges.
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

  static const levels = [
    'BEPC',
    'Probatoire',
    'BAC',
    'BTS',
    'Licence',
    'Concours'
  ];

  static final catalog = <Content>[
    Content(
        id: 'c1',
        title: 'BAC C  Mathématiques 2023',
        subjectId: 'math',
        exam: 'BAC C',
        level: 'BAC',
        type: ContentType.epreuve,
        year: 2023,
        price: 1000,
        rating100: 47,
        ratings: 214,
        downloads: 1840,
        free: false,
        difficulty: 4),
    Content(
        id: 'c2',
        title: 'Correction BAC C Physique 2022',
        subjectId: 'pc',
        exam: 'BAC C',
        level: 'BAC',
        type: ContentType.correction,
        year: 2022,
        price: 3000,
        rating100: 49,
        ratings: 320,
        downloads: 2410,
        free: false,
        fav: true,
        difficulty: 4,
        aiReco:
            'Tu as raté les questions sur les circuits  voici les corrections détaillées.'),
    Content(
        id: 'c3',
        title: 'Quiz Chimie organique  Terminale',
        subjectId: 'chimie',
        exam: 'BAC D',
        level: 'BAC',
        type: ContentType.quiz,
        year: 2024,
        price: 1000,
        rating100: 45,
        ratings: 98,
        downloads: 760,
        free: false,
        difficulty: 3),
    Content(
        id: 'c4',
        title: 'Pack ENSP 2020–2023 (épreuves + corrigés)',
        subjectId: 'math',
        exam: 'ENSP',
        level: 'Concours',
        type: ContentType.pack,
        year: 2023,
        price: 8000,
        rating100: 48,
        ratings: 156,
        downloads: 980,
        free: false,
        difficulty: 5),
    Content(
        id: 'c5',
        title: 'Méthodes & Dérivées  Préparation BAC C',
        subjectId: 'math',
        exam: 'BAC C',
        level: 'BAC',
        type: ContentType.livre,
        year: 2024,
        price: 2500,
        rating100: 46,
        ratings: 72,
        downloads: 540,
        free: false,
        fav: true,
        difficulty: 3),
    Content(
        id: 'c6',
        title: 'BEPC  Mathématiques 2024',
        subjectId: 'math',
        exam: 'BEPC',
        level: 'BEPC',
        type: ContentType.epreuve,
        year: 2024,
        price: 0,
        rating100: 44,
        ratings: 410,
        downloads: 5200,
        free: true,
        difficulty: 2),
    Content(
        id: 'c7',
        title: 'BEPC  SVT 2024',
        subjectId: 'svt',
        exam: 'BEPC',
        level: 'BEPC',
        type: ContentType.epreuve,
        year: 2024,
        price: 0,
        rating100: 43,
        ratings: 286,
        downloads: 3900,
        free: true,
        difficulty: 2),
    Content(
        id: 'c8',
        title: 'Pack FMSB Médecine  Annales concours',
        subjectId: 'svt',
        exam: 'FMSB',
        level: 'Concours',
        type: ContentType.pack,
        year: 2023,
        price: 10000,
        rating100: 49,
        ratings: 188,
        downloads: 1120,
        free: false,
        difficulty: 5),
    Content(
        id: 'c9',
        title: 'Correction Probatoire D Maths 2023',
        subjectId: 'math',
        exam: 'Probatoire',
        level: 'Probatoire',
        type: ContentType.correction,
        year: 2023,
        price: 2000,
        rating100: 46,
        ratings: 142,
        downloads: 1640,
        free: false,
        difficulty: 3),
    Content(
        id: 'c10',
        title: 'Quiz Dérivées & Limites  Terminale C',
        subjectId: 'math',
        exam: 'BAC C',
        level: 'BAC',
        type: ContentType.quiz,
        year: 2024,
        price: 0,
        rating100: 47,
        ratings: 230,
        downloads: 2100,
        free: true,
        difficulty: 4),
    Content(
        id: 'c11',
        title: 'Polytechnique  Physique 2022',
        subjectId: 'pc',
        exam: 'Polytechnique',
        level: 'Concours',
        type: ContentType.epreuve,
        year: 2022,
        price: 1500,
        rating100: 48,
        ratings: 96,
        downloads: 720,
        free: false,
        difficulty: 5),
    Content(
        id: 'c12',
        title: 'Le Français au BAC  Dissertation & Commentaire',
        subjectId: 'fr',
        exam: 'BAC A',
        level: 'BAC',
        type: ContentType.livre,
        year: 2024,
        price: 2000,
        rating100: 45,
        ratings: 64,
        downloads: 480,
        free: false,
        difficulty: 2),
  ];

  static Content contentById(String id) =>
      catalog.firstWhere((c) => c.id == id, orElse: () => catalog.first);

  static const quizDerivees = Quiz(
    id: 'c10',
    title: 'Quiz Dérivées & Limites',
    subjectId: 'math',
    questions: [
      QuizQuestion(
          "Quelle est la dérivée de f(x) = x³ ?",
          ['3x²', 'x²', '3x', '2x³'],
          0,
          "La dérivée de xⁿ est n·xⁿ⁻¹, donc (x³)' = 3x²."),
      QuizQuestion("lim(x→0) sin(x)/x = ?", ['0', '1', '∞', "n'existe pas"], 1,
          "C'est une limite classique : sin(x)/x → 1 quand x → 0."),
      QuizQuestion("La dérivée de ln(x) est :", ['1/x', 'ln(x)/x', 'x', "eˣ"],
          0, "(ln x)' = 1/x pour x > 0."),
      QuizQuestion("Si f(x) = eˣ, alors f'(x) = ?", ['x·eˣ', 'eˣ', '1', "eˣ⁻¹"],
          1, "La fonction exponentielle est sa propre dérivée."),
      QuizQuestion("La dérivée d'une constante k est :", ['k', '1', '0', 'x'],
          2, "La dérivée de toute constante est nulle."),
    ],
  );

  static const children = <Child>[
    Child(
        id: 'k1',
        name: 'Ahmed',
        level: 'Terminale C',
        lastActive: 'il y a 2h',
        studyWeek: '8h 20',
        streak: 7,
        weekScore: 72,
        quizDone: 3,
        progress: 64,
        trend: 'up',
        alertType: 'warn',
        alertMsg:
            'Faiblesse détectée en Physique (48%). 3 ressources recommandées.'),
    Child(
        id: 'k2',
        name: 'Léa',
        level: '3ème',
        lastActive: 'hier',
        studyWeek: '5h 10',
        streak: 0,
        weekScore: 88,
        quizDone: 5,
        progress: 80,
        trend: 'up',
        alertType: 'success',
        alertMsg: 'Léa a obtenu 90% à son dernier quiz Maths  excellent !'),
  ];

  static const subjectScores = <String, int>{
    'math': 78,
    'pc': 48,
    'chimie': 64,
    'fr': 81,
    'svt': 70
  };

  static const notifications = <AppNotification>[
    AppNotification(
        'n1',
        'ai',
        'WinAI a analysé tes résultats',
        '3 ressources ciblées en Physique t\'attendent.',
        '09:12',
        "Aujourd'hui",
        true),
    AppNotification(
        'n2',
        'gold',
        'Badge débloqué : 7 jours de feu',
        'Tu as étudié 7 jours d\'affilée. Continue !',
        '08:00',
        "Aujourd'hui",
        true),
    AppNotification(
        'n3',
        'success',
        'Paiement réussi',
        'Correction BAC C Physique 2022  3 000 XAF.',
        'Hier',
        'Cette semaine',
        false),
    AppNotification(
        'n4',
        'info',
        'Nouveau pack ENSP disponible',
        'Annales 2020–2023 ajoutées au catalogue.',
        'Lun.',
        'Cette semaine',
        false),
  ];

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

  // Données étudiant
  static const streak = 7;
  static const dayGoal = 65;
  static const avgScore = 72;
  static const studyToday = '1h 45';
  static const quizWeek = 4;
  static const downloadsTotal = 23;

  // ---- PROFESSEUR : contenus publiés ----
  static const profContent = <ProfContent>[
    ProfContent('BAC C  Maths 2023', 'Épreuve', 'Publié', 1840, 4.7, 184000),
    ProfContent('Correction BAC C Physique 2022', 'Correction', 'Publié', 2410,
        4.9, 723000),
    ProfContent('Quiz Vecteurs  Terminale', 'Quiz', 'En révision', 0, 0, 0),
    ProfContent('Méthodes & Dérivées', 'Livre', 'Brouillon', 0, 0, 0),
  ];

  // ---- INSTITUTION : groupes ----
  static const groups = <Group>[
    Group('g1', 'TLE C 2026', 45, 78, 71, 'BAC'),
    Group('g2', 'TLE D 2026', 38, 52, 58, 'BAC'),
    Group('g3', 'BTS Info 1', 26, 34, 49, 'BTS'),
    Group('g4', '3ème A', 52, 81, 74, 'BEPC'),
  ];
}
