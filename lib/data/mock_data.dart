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
        difficulty: 4,
        teacher: 'Prof. Mbarga',
        description:
            'Épreuve officielle de Mathématiques du BAC C session 2023. Inclut les 4 exercices et le problème complet avec barème officiel.',
        reviews: [
          const ContentReview(
              'Sonia K.',
              'Très bien structuré, le barème est clair.',
              48,
              'il y a 3 jours'),
          const ContentReview(
              'Armand T.',
              'Exactement l\'épreuve originale, impeccable.',
              47,
              'il y a 1 sem.'),
        ]),
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
        teacher: 'Prof. Nkoulou',
        description:
            'Correction détaillée et commentée de l\'épreuve de Physique BAC C 2022. Chaque étape est expliquée avec les formules clés à retenir.',
        aiReco:
            'Tu as raté les questions sur les circuits  voici les corrections détaillées.',
        reviews: [
          const ContentReview(
              'Fadel M.',
              'La meilleure correction que j\'ai trouvée en ligne.',
              50,
              'il y a 5 jours'),
          const ContentReview('Carole B.', 'Très pédagogique, bravo au prof.',
              49, 'il y a 2 sem.'),
        ]),
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
        difficulty: 3,
        teacher: 'Prof. Ateba',
        description:
            '30 questions sur la chimie organique niveau Terminale D. Timer 20 min. Résultats et explications instantanés.'),
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
        difficulty: 5,
        teacher: 'WinPlus Editorial',
        description:
            '4 années d\'annales ENSP avec corrections complètes. Mathématiques, Physique, Chimie. Idéal pour une préparation intensive au concours.',
        reviews: [
          const ContentReview(
              'Rodrigue N.',
              'Pack indispensable pour l\'ENSP. Admis cette année !',
              50,
              'il y a 1 mois'),
          const ContentReview('Hortense E.', 'Très complet, vaut chaque franc.',
              48, 'il y a 2 mois'),
        ]),
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
        difficulty: 3,
        teacher: 'Prof. Mbarga',
        description:
            'Guide méthodologique complet sur les dérivées et les limites. 45 exercices corrigés progressifs. Du niveau Première au BAC C.'),
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
        difficulty: 2,
        teacher: 'WinPlus Editorial',
        description:
            'Épreuve officielle BEPC Mathématiques 2024 en accès libre.'),
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
        difficulty: 2,
        teacher: 'WinPlus Editorial',
        description: 'Épreuve officielle BEPC SVT 2024 en accès libre.'),
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
        difficulty: 5,
        teacher: 'WinPlus Editorial',
        description:
            'Annales complètes du concours d\'entrée à la FMSB (Faculté de Médecine et des Sciences Biomédicales). SVT, Chimie, Physique.',
        reviews: [
          const ContentReview(
              'Blanche O.',
              'J\'ai réussi le concours FMSB grâce à ce pack !',
              50,
              'il y a 3 mois'),
        ]),
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
        difficulty: 3,
        teacher: 'Prof. Essono',
        description:
            'Correction intégrale de l\'épreuve de Maths Probatoire D 2023.'),
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
        difficulty: 4,
        teacher: 'Prof. Mbarga',
        description:
            '20 questions de niveau BAC C sur les dérivées et limites. Accès libre.'),
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
        difficulty: 5,
        teacher: 'Prof. Nkoulou',
        description:
            'Épreuve de Physique du concours Polytechnique Yaoundé 2022.'),
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
        difficulty: 2,
        teacher: 'Prof. Ngo Mbe',
        description:
            'Méthodes et exemples corrigés pour la dissertation et le commentaire composé au BAC littéraire.'),
  ];

  static Content contentById(String id) =>
      catalog.firstWhere((c) => c.id == id, orElse: () => catalog.first);

  static const quizDerivees = Quiz(
    id: 'c10',
    title: 'Quiz Dérivées & Limites',
    subjectId: 'math',
    durationMinutes: 20,
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
    AppNotification(
        'n5',
        'warn',
        'Vérification périodique requise',
        'Confirme ton adresse email pour continuer à utiliser WinPlus.',
        'il y a 2j',
        'Cette semaine',
        true),
    AppNotification(
        'n6',
        'ai',
        'Plan de révision prêt',
        'WinAI a généré ton planning BAC C  3 semaines, 2h/jour.',
        'il y a 5j',
        'Ce mois',
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

  // ---- ABONNEMENT ----

  static const pricingPlans = <PricingPlan>[
    PricingPlan(
      tier: PlanTier.libre,
      name: 'Boutique Libre',
      tagline: 'Accès limité, achat à l\'unité',
      priceMonthly: 0,
      priceYearly: 0,
      downloadLimit: 5,
      quizDailyLimit: 3,
      aiMessages: 10,
      features: [
        PricingFeature('5 téléchargements/mois', included: true),
        PricingFeature('3 quiz par jour', included: true),
        PricingFeature('10 messages WinAI', included: true),
        PricingFeature('Accès catalogue complet',
            included: false, detail: 'Achat à l\'unité seulement'),
        PricingFeature('Exam Coach IA', included: false),
        PricingFeature('Téléchargement hors-ligne', included: false),
        PricingFeature('Corrections prioritaires', included: false),
      ],
    ),
    PricingPlan(
      tier: PlanTier.standard,
      name: 'Standard',
      tagline: 'L\'essentiel pour réviser',
      priceMonthly: 2500,
      priceYearly: 25000,
      downloadLimit: 30,
      quizDailyLimit: 20,
      aiMessages: 100,
      features: [
        PricingFeature('30 téléchargements/mois', included: true),
        PricingFeature('20 quiz par jour', included: true),
        PricingFeature('100 messages WinAI', included: true),
        PricingFeature('Catalogue complet inclus', included: true),
        PricingFeature('Exam Coach IA', included: false),
        PricingFeature('Téléchargement hors-ligne', included: true),
        PricingFeature('Support prioritaire', included: false),
      ],
    ),
    PricingPlan(
      tier: PlanTier.premium,
      name: 'Premium',
      tagline: 'Tout, sans limite',
      priceMonthly: 5000,
      priceYearly: 50000,
      popular: true,
      downloadLimit: null,
      quizDailyLimit: null,
      aiMessages: null,
      features: [
        PricingFeature('Téléchargements illimités', included: true),
        PricingFeature('Quiz illimités', included: true),
        PricingFeature('WinAI illimité', included: true),
        PricingFeature('Exam Coach IA', included: true),
        PricingFeature('Téléchargement hors-ligne', included: true),
        PricingFeature('Certificats & badges', included: true),
        PricingFeature('Support prioritaire 24h', included: true),
      ],
    ),
    PricingPlan(
      tier: PlanTier.famille,
      name: 'Famille',
      tagline: 'Premium pour toute la famille',
      priceMonthly: 8000,
      priceYearly: 80000,
      downloadLimit: null,
      quizDailyLimit: null,
      aiMessages: null,
      features: [
        PricingFeature('Jusqu\'à 4 enfants', included: true),
        PricingFeature('Dashboard parent avancé', included: true),
        PricingFeature('WinAI Alerts par enfant', included: true),
        PricingFeature('Tout Premium inclus', included: true),
        PricingFeature('Rapport hebdo par email', included: true),
        PricingFeature('Support prioritaire 24h', included: true),
        PricingFeature('Encouragements personnalisés', included: true),
      ],
    ),
  ];

  static const currentSubscription = ActiveSubscription(
    tier: PlanTier.standard,
    planName: 'Standard',
    expiresAt: '15 sept. 2026',
    autoRenew: true,
    downloadsUsed: 18,
    downloadsLimit: 30,
    quizUsedToday: 2,
    quizDailyLimit: 20,
    aiMessagesUsed: 34,
    aiMessagesLimit: 100,
  );

  // ---- CONTINUE LEARNING ----

  static const inProgress = <InProgressContent>[
    InProgressContent(
        'c2', 'Correction BAC C Physique 2022', 'pc', 62, 'il y a 2h'),
    InProgressContent('c4', 'Pack ENSP 2020–2023', 'math', 38, 'hier'),
    InProgressContent('c5', 'Méthodes & Dérivées', 'math', 85, 'il y a 3j'),
  ];

  // ---- RECOMMANDATIONS IA ----

  static const aiRecommendations = <AiRecommendation>[
    AiRecommendation(RecoType.weakSubject, 'Renforce ta Physique',
        'Ton score moyen en Physique est de 48%  bien en dessous de la moyenne. WinAI a sélectionné 3 ressources ciblées.',
        contentId: 'c2'),
    AiRecommendation(RecoType.suggestedQuiz, 'Quiz du jour : Dérivées',
        'Tu n\'as pas pratiqué les dérivées depuis 4 jours. 5 min suffisent pour consolider.',
        contentId: 'c10'),
    AiRecommendation(RecoType.examPlan, 'Plan BAC C : 3 semaines',
        'Le BAC C est dans 21 jours. WinAI a préparé un planning jour par jour basé sur tes lacunes.'),
  ];

  // ---- ACTIVITÉ RÉCENTE ----

  static const activityFeed = <ActivityEvent>[
    ActivityEvent(ActivityType.quiz, 'Quiz Dérivées & Limites', '4/5  80%',
        'Aujourd\'hui 09:14'),
    ActivityEvent(ActivityType.download, 'Correction BAC C Physique 2022',
        'Téléchargé', 'Hier 18:40'),
    ActivityEvent(ActivityType.badge, 'Badge débloqué : 7 jours de feu',
        '+50 XP', 'Hier 08:00'),
    ActivityEvent(
        ActivityType.purchase, 'Méthodes & Dérivées', '2 500 XAF', 'il y a 3j'),
    ActivityEvent(
        ActivityType.quiz, 'Quiz Chimie organique', '6/10  60%', 'il y a 4j'),
    ActivityEvent(ActivityType.session, 'Session d\'étude', '1h 30  Physique',
        'il y a 5j'),
  ];

  // ---- PLANNING HEBDOMADAIRE ----

  static const studyWeekData = StudyWeek([
    StudyDay('Lun', 90, 120),
    StudyDay('Mar', 120, 120),
    StudyDay('Mer', 45, 120),
    StudyDay('Jeu', 130, 120),
    StudyDay('Ven', 110, 120),
    StudyDay('Sam', 60, 120),
    StudyDay('Dim', 0, 120),
  ]);

  static const examCoachPlan = StudyPlan(
    'BAC C',
    '18 juin 2026',
    2,
    [
      StudyWeekPlan(
          'Semaine 1', ['Dérivées', 'Intégrales', 'Quiz de positionnement'],
          done: true),
      StudyWeekPlan('Semaine 2', [
        'Physique : circuits électriques',
        'Mécanique du point',
        'Quiz mi-parcours'
      ]),
      StudyWeekPlan('Semaine 3',
          ['Révision générale', 'Annales 2021–2023', 'Simulation BAC C']),
    ],
  );

  // ---- EXAMENS À VENIR ----

  static const upcomingExams = <ExamCountdown>[
    ExamCountdown('BAC C  Mathématiques', '18 juin 2026', 21, 'math'),
    ExamCountdown('BAC C  Physique-Chimie', '19 juin 2026', 22, 'pc'),
    ExamCountdown('Concours ENSP', '5 juil. 2026', 38, 'math'),
  ];

  // ---- BADGES / GAMIFICATION ----

  static const badges = <AchievementBadge>[
    AchievementBadge('b1', '7 jours de feu', 'Étudié 7 jours consécutifs',
        Icons.local_fire_department, WinColors.warn,
        unlocked: true, unlockedAt: 'Hier'),
    AchievementBadge('b2', 'Premier quiz', 'Complété ton 1er quiz',
        Icons.quiz_outlined, WinColors.teal500,
        unlocked: true, unlockedAt: 'il y a 2 sem.'),
    AchievementBadge('b3', 'Téléchargeur', '10 contenus téléchargés',
        Icons.download_done, WinColors.blue500,
        unlocked: true, unlockedAt: 'il y a 1 mois'),
    AchievementBadge('b4', 'Expert Maths', '90%+ à 5 quiz de Maths',
        Icons.functions, WinColors.gold,
        unlocked: false),
    AchievementBadge('b5', '30 jours de feu', 'Étudié 30 jours consécutifs',
        Icons.local_fire_department, WinColors.error,
        unlocked: false),
    AchievementBadge('b6', 'Pack complet', 'Terminé un pack annales',
        Icons.inventory_2_outlined, WinColors.ink700,
        unlocked: false),
  ];

  // ---- PROFIL UTILISATEUR ----

  static const userProfile = UserProfile(
    id: 'u1',
    name: 'Koumba Martial',
    email: 'koumba.martial@gmail.com',
    phone: '+237 699 123 456',
    role: WinRole.student,
    level: 'Terminale C',
    filiere: 'Scientifique',
    examObjectif: 'BAC C',
    avatarInitials: 'KM',
  );

  // ---- PROFESSEUR : contenus publiés ----
  static const profContent = <ProfContent>[
    ProfContent('BAC C  Maths 2023', 'Épreuve', 'Publié', 1840, 4.7, 184000),
    ProfContent('Correction BAC C Physique 2022', 'Correction', 'Publié', 2410,
        4.9, 723000),
    ProfContent('Quiz Vecteurs  Terminale', 'Quiz', 'En révision', 0, 0, 0),
    ProfContent('Méthodes & Dérivées', 'Livre', 'Brouillon', 0, 0, 0),
  ];

  // ---- PROFESSEUR : corrections en attente ----
  static const submissions = <Submission>[
    Submission('s1', 'Sonia Kombe', 'Devoir Intégrales  Terminale C',
        'il y a 30 min', false),
    Submission(
        's2', 'Armand Talla', 'Devoir Vecteurs  1ère C', 'il y a 2h', false),
    Submission('s3', 'Fadel Moussa', 'Devoir Chimie organique', 'hier', true,
        score: 14),
    Submission('s4', 'Carole Biya', 'Exercice Mécanique', 'il y a 3j', true,
        score: 16),
  ];

  // ---- INSTITUTION : groupes ----
  static const groups = <Group>[
    Group('g1', 'TLE C 2026', 45, 78, 71, 'BAC'),
    Group('g2', 'TLE D 2026', 38, 52, 58, 'BAC'),
    Group('g3', 'BTS Info 1', 26, 34, 49, 'BTS'),
    Group('g4', '3ème A', 52, 81, 74, 'BEPC'),
  ];

  // ---- INSTITUTION : élèves à risque ----
  static const atRiskStudents = <AtRiskStudent>[
    AtRiskStudent('r1', 'Jean-Paul Ekwalla', 'TLE C', 32, 8, 'high',
        'Score < 35% depuis 3 semaines, 8 absences'),
    AtRiskStudent('r2', 'Martine Abanda', 'TLE D', 41, 5, 'high',
        'Série d\'étude rompue depuis 12 jours'),
    AtRiskStudent('r3', 'Boris Nguyen', 'BTS Info 1', 48, 3, 'medium',
        'Score en baisse de 15 pts ce mois'),
    AtRiskStudent('r4', 'Sylvie Meka', 'TLE C', 50, 4, 'medium',
        'Physique faible : 28%, aucun quiz cette semaine'),
  ];

  // ---- PARENT : évènements enfants ----
  static const childEvents = <ChildEvent>[
    ChildEvent('Ahmed', 'BAC C  Mathématiques', '18 juin 2026', 'exam'),
    ChildEvent(
        'Ahmed', 'Renouvellement abonnement', '15 sept. 2026', 'renewal'),
    ChildEvent('Léa', 'BEPC  Mathématiques', '14 mai 2026', 'exam'),
  ];

  // ---- PARENT : scores d\'engagement ----
  static const engagementScores = <EngagementScore>[
    EngagementScore('k1', 72, 65, 'up'),
    EngagementScore('k2', 88, 90, 'down'),
  ];

  // ---- 4.8 GET /api/student/stats ----

  static const studentStats = StudentStats(
    streakDays: 14,
    avgScore: 78,
    hoursThisWeek: 32,
    totalBadges: 14,
    totalCertificates: 2,
    totalFavorites: 28,
  );

  // ---- 4.9 GET /api/parent/account ----

  static const parentAccount = ParentAccount(
    name: 'Solange Nkono',
    plan: 'Famille',
    creditsAvailable: 40000,
    creditsTotal: 40000,
    creditsUsed: 12500,
    childrenLimit: 5,
  );

  // ---- 4.10 GET /api/parent/children ----

  static final trackedChildren = <TrackedChild>[
    TrackedChild(
        id: 'k-001',
        name: 'Ahmed Nkono',
        level: 'Tle C',
        avgScore: 78,
        trend: Trend.up,
        lastActiveAt: DateTime.now()),
    TrackedChild(
        id: 'k-002',
        name: 'Brenda Nkono',
        level: '2nde',
        avgScore: 62,
        trend: Trend.down,
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1))),
    TrackedChild(
        id: 'k-003',
        name: 'Kevin Nkono',
        level: 'BEPC',
        avgScore: 85,
        trend: Trend.up,
        lastActiveAt: DateTime.now()),
  ];

  // ---- 4.11 GET /api/parent/child/{id}/activity ----

  static const childEngagement = ChildEngagement(
    score: 73,
    scoreDelta: 8,
    sessionsThisWeek: 5,
    avgSessionMinutes: 42,
  );

  // ---- 4.12 GET /api/parent/upcoming-events ----

  static final upcomingEvents = <UpcomingEvent>[
    UpcomingEvent(
        type: 'renewal',
        label: 'Renouvellement abonnement',
        date: DateTime.now().add(const Duration(days: 7))),
    UpcomingEvent(
        type: 'exam', label: 'BAC C · Ahmed', date: DateTime(2026, 10, 8)),
  ];

  // ---- 4.14 GET /api/teacher/stats ----

  static const teacherStats = TeacherStats(
    totalRevenue: 907000,
    avgRating: 4.8,
    totalStudents: 412,
    commissionRate: 0.80,
    publishedCount: 18,
    totalDownloads: 2140,
  );

  // ---- 4.15 GET /api/teacher/insights ----

  static const teacherInsights = <TeacherInsight>[
    TeacherInsight(
        icon: Icons.local_fire_department,
        text: 'Pack ENSP 2019-2023  meilleur vendeur ce mois'),
    TeacherInsight(
        icon: Icons.people,
        text: 'Terminale C représente 68% de votre audience'),
    TeacherInsight(
        icon: Icons.trending_up, text: '+12% de téléchargements cette semaine'),
  ];

  // ---- 4.16 GET /api/institution/stats ----

  static const institutionStats = InstitutionStats(
    name: 'Lycée Bilingue de Yaoundé',
    plan: 'Enterprise',
    licensesTotal: 2450,
    licensesUsed: 1823,
    avgSuccessRate: 74,
    activeStudentsToday: 642,
    quizThisWeek: 1847,
  );

  // ---- 4.17 GET /api/institution/subject-stats ----

  static const subjectStats = <SubjectStat>[
    SubjectStat(subject: 'Mathématiques', sessions: 1240),
    SubjectStat(subject: 'Physique-Chimie', sessions: 890),
    SubjectStat(subject: 'Français', sessions: 654),
    SubjectStat(subject: 'SVT', sessions: 420),
  ];

  // ---- 4.18 GET /api/institution/students ----

  static const mockStudents = <MockStudent>[
    MockStudent(
        id: 's-001',
        name: 'Ahmed Nkono',
        level: 'Tle C',
        group: 'Classe A',
        score: 78,
        active: true),
    MockStudent(
        id: 's-002',
        name: 'Brenda Mballa',
        level: 'Tle C',
        group: 'Classe A',
        score: 86,
        active: true),
    MockStudent(
        id: 's-003',
        name: 'Yann Talla',
        level: '1ère D',
        group: 'Classe B',
        score: 54,
        active: false),
    MockStudent(
        id: 's-004',
        name: 'Aïcha Bello',
        level: 'Concours',
        group: 'Classe C',
        score: 91,
        active: true),
    MockStudent(
        id: 's-005',
        name: 'Steve Ngono',
        level: 'Tle A',
        group: 'Classe B',
        score: 63,
        active: true),
    MockStudent(
        id: 's-006',
        name: 'Marie Essono',
        level: 'Tle C',
        group: 'Classe A',
        score: 74,
        active: true),
    MockStudent(
        id: 's-007',
        name: 'Paul Nkoulou',
        level: 'Tle D',
        group: 'Classe B',
        score: 45,
        active: false),
    MockStudent(
        id: 's-008',
        name: 'Fatima Moussa',
        level: '1ère C',
        group: 'Classe C',
        score: 82,
        active: true),
    MockStudent(
        id: 's-009',
        name: 'Rodrigue Ateba',
        level: 'Concours',
        group: 'Classe C',
        score: 88,
        active: true),
    MockStudent(
        id: 's-010',
        name: 'Carole Biya',
        level: 'Tle A',
        group: 'Classe A',
        score: 67,
        active: true),
    MockStudent(
        id: 's-011',
        name: 'Hortense Ekwalla',
        level: 'Tle C',
        group: 'Classe B',
        score: 71,
        active: true),
    MockStudent(
        id: 's-012',
        name: 'Jean-Pierre Meka',
        level: 'Tle D',
        group: 'Classe C',
        score: 38,
        active: false),
    MockStudent(
        id: 's-013',
        name: 'Sylvie Ngo Mbe',
        level: '1ère C',
        group: 'Classe A',
        score: 79,
        active: true),
    MockStudent(
        id: 's-014',
        name: 'Boris Tchami',
        level: 'Tle C',
        group: 'Classe B',
        score: 55,
        active: true),
    MockStudent(
        id: 's-015',
        name: 'Blanche Abanda',
        level: 'Concours',
        group: 'Classe C',
        score: 93,
        active: true),
    MockStudent(
        id: 's-016',
        name: 'Kevin Nguyen',
        level: '3ème',
        group: 'BEPC',
        score: 60,
        active: true),
    MockStudent(
        id: 's-017',
        name: 'Solange Kombe',
        level: 'Tle D',
        group: 'Classe B',
        score: 47,
        active: false),
    MockStudent(
        id: 's-018',
        name: 'Armand Mbarga',
        level: 'Tle C',
        group: 'Classe A',
        score: 85,
        active: true),
    MockStudent(
        id: 's-019',
        name: 'Martine Fopa',
        level: '1ère D',
        group: 'Classe B',
        score: 72,
        active: true),
    MockStudent(
        id: 's-020',
        name: 'Thierry Bessala',
        level: 'Concours',
        group: 'Classe C',
        score: 76,
        active: true),
  ];

  // ---- CERTIFICATS ----
  static const certificates = <Certificate>[
    Certificate('cert1', 'Maîtrise des Dérivées  Niveau BAC C', '14 jan. 2026',
        'https://winplus.cm/verify/cert1', 92),
    Certificate('cert2', 'Quiz Physique  Expert', '2 mars 2026',
        'https://winplus.cm/verify/cert2', 88),
  ];
}
