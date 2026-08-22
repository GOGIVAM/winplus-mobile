# WinPlus Mobile — Plan d'implémentation v4

> **Sources :** `FEATURE_GAP_MOBILE.md` × `Plan_Abonnement.md` × audit code 2026-08-22  
> **Dernière mise à jour :** 2026-08-22 — Sprint 1 item 1 ✅

---

## Table des matières

1. [Principes fondamentaux](#1-principes-fondamentaux)
2. [UX par rôle — comportement attendu (tier max)](#2-ux-par-rôle--comportement-attendu-tier-max)
3. [État réel d'implémentation](#3-état-réel-dimplémentation)
4. [Mock data groupées par endpoint API](#4-mock-data-groupées-par-endpoint-api)
5. [Backlog ÉTUDIANT — Plan Ultime](#5-backlog-étudiant--plan-ultime)
6. [Backlog PARENT — Plan Famille](#6-backlog-parent--plan-famille)
7. [Backlog PROFESSEUR — Plan Expert](#7-backlog-professeur--plan-expert)
8. [Backlog INSTITUTION — Plan Enterprise](#8-backlog-institution--plan-enterprise)
9. [Backlog AUTH & SHARED](#9-backlog-auth--shared)
10. [Ordre d'implémentation — Sprints](#10-ordre-dimplémentation--sprints)
11. [Checklist gates — Phase 2](#11-checklist-gates--phase-2)
12. [Cahier des charges par écran](#12-cahier-des-charges-par-écran)
7. [Backlog PROFESSEUR — Plan Expert](#7-backlog-professeur--plan-expert)
8. [Backlog INSTITUTION — Plan Enterprise](#8-backlog-institution--plan-enterprise)
9. [Backlog AUTH & SHARED](#9-backlog-auth--shared)
10. [Ordre d'implémentation — Sprints](#10-ordre-dimplémentation--sprints)
11. [Checklist gates — Phase 2](#11-checklist-gates--phase-2)

---

## 1. Principes fondamentaux

### 1.1 Stratégie : tier max en premier, gates après

L'UI est développée avec **toutes les fonctionnalités visibles et actives**, comme si chaque utilisateur était sur le plan le plus élevé. Les restrictions (`SubscriptionScope`, paywalls) sont ajoutées en **Phase 2** après validation UX.

- `AppConfig.devMode = true` pendant tout le développement UI
- Les données mock reflètent un utilisateur au tier maximum
- Pas de `if (isPremium)` qui cache des sections entières pour l'instant

### 1.2 Tiers cumulatifs (RÈGLE ABSOLUE)

> **Un utilisateur de tier N peut faire TOUT ce qu'un utilisateur de tier N-1 fait, plus des fonctionnalités additionnelles.**

Les plans sont additifs, jamais des îlots séparés. Exemples concrets :
- Standard télécharge 5 épreuves/mois → Premium télécharge **illimité** (pas une UI différente, juste plus de quota)
- Fondateur crée 5 contenus → Pro crée **20** → Expert crée **illimité**
- Basique suit 1 enfant → Complet **2-3** → Famille **4-5**

Cela signifie que l'UI doit afficher les quotas/limites en fonction du plan, mais jamais masquer la fonctionnalité elle-même.

### 1.3 Tier maximum par rôle

| Rôle | Plan max | Prix | Fonctionnalité clé |
|---|---|---|---|
| Étudiant | **Ultime** | 7 500 XAF/mois | Tout illimité, coaching, certificats signés |
| Parent | **Famille** | 12 000 XAF/mois | 4-5 enfants, crédits 40k XAF, alertes temps réel |
| Professeur | **Expert** | 15 000 XAF/mois | Classes illimitées, 80% revenus, IA premium |
| Institution | **Enterprise** | Personnalisé | Licences en masse, analytics, rapports temps réel |

---

## 2. UX par rôle — comportement attendu (tier max)

### 2.1 Étudiant — Plan Ultime

```
[Splash] → [Welcome] → [Login → RoleShell]

HOME TAB
├── Hero : "Bonjour [Prénom] · BAC C · Terminale · 🔥14 jours"
│         Score moyen 78% | 32h cette semaine
├── Continue Learning (reprendre où on s'est arrêté)
│   └── [Card] BAC C Maths 2023 — 65% · Reprendre →
│   └── [Card] Pack ENSP — 30% · Reprendre →
├── Recommandations IA (avec raison affichée)
│   └── [Card] Quiz Chimie — "Pas révisé depuis 5 jours" →
│   └── [Card] Correction Physique — "Populaire Tle C" →
├── Compte à rebours
│   └── 🎯 BAC C — dans 47 jours
└── Activité récente (timeline)
    ├── Quiz Maths · 13/15 · il y a 1h
    ├── Téléchargement BAC D Physique · il y a 3h
    └── Quiz Chimie · 8/15 · hier

CATALOGUE TAB
├── Filtres avancés : Examen · Matière · Année · Type · Difficulté · [Tri ↕]
├── Grid de ContentCards (téléchargements illimités Ultime)
└── Tap → ContentDetailScreen
       ├── Aperçu 2-3 pages
       ├── Description + avis + Q&A
       ├── Tags de révision · notes perso
       ├── Contenus associés
       └── [Télécharger] · [Acheter] (invité)

QUIZ TAB
├── Liste quiz (illimités Ultime)
├── → QuizActiveScreen (timer, navigation Q)
│   → QuizResultScreen (score, stats)
│   → QuizReviewScreen (corrections détaillées)
└── [Révision] — refaire les quiz échoués

MOI TAB (ProfileHubTab) ✅
├── Header avatar · Nom · Plan Ultime 🏆
├── Apprentissage → Badges, Certificats, Favoris, Téléchargements
├── Communauté → Forum, WinAI
├── Compte → Notifications [badge], Abonnement, Paramètres
├── Mode sombre [switch]
└── Déconnexion
```

### 2.2 Parent — Plan Famille

```
[Shell 5 tabs : Accueil · Enfants · Ressources · Messages · Profil]

ACCUEIL TAB
├── Hero : "Bonjour [Prénom] · Plan Famille"
│         Crédits disponibles : 40 000 XAF 💰
├── Enfants (cards horizontales scrollables)
│   └── ChildSummaryCard : avatar · score · tendance ↗ · statut actif/hier
├── [⚠️ Alerte WinAI] si alertes → WinAIAlertsScreen
├── Évènements à venir
│   ├── 📅 Renouvellement dans 7 jours → RenewalSheet
│   └── 🎯 BAC C Ahmed · dans 47 jours
└── [Acheter du contenu pour un enfant →]

ENFANTS TAB
├── [+ Ajouter un enfant] (jusqu'à 5, Plan Famille)
└── ChildCard × N → ChildActivityScreen
    ├── Tab "Activité" : timeline + score engagement 73/100
    ├── Tab "Résultats" : score par matière, dernier quiz
    ├── Tab "Alertes WinAI" : difficultés, streak rompu
    ├── [Voir ressources pour cet enfant]
    ├── [Générer un quiz]
    └── [💌 Encouragement] → EncouragementSheet

RESSOURCES TAB
└── Catalogue + [Acheter pour...] choisir enfant

MESSAGES TAB
└── MessagingScreen → ConversationScreen

PROFIL TAB
├── Infos compte · Abonnement Famille · crédits 40k XAF
├── Historique paiements
├── [Gérer l'abonnement] → RenewalSheet
├── Mode sombre
└── Déconnexion
```

### 2.3 Professeur — Plan Expert

```
[Shell 5 tabs : Dashboard · Contenus · Étudiants · Sessions · Revenus]

DASHBOARD TAB
├── Hero : "[Nom] · Plan Expert · 80% de vos revenus"
├── Stats (depuis données réelles chargées)
│   ├── X contenus publiés · Y téléchargements · Note moy. 4,8 ⭐
│   └── N étudiants actifs · M classes
├── Insights IA
│   ├── 🔥 "Pack ENSP — meilleur vendeur ce mois"
│   └── 📈 "+12% téléchargements cette semaine"
└── [Correction queue] [+ Publier contenu]

CONTENUS TAB
├── Filtres : Publiés · En révision · Brouillons
├── ContentRow × N · long-press → ContentActionsSheet
│   ├── 📊 Voir stats inline
│   ├── ✏️ Modifier
│   ├── 🔄 Changer statut
│   └── 🗑️ Supprimer
└── [+ Publier] → ContentPublishScreen
    ├── Titre, Type, Matière, Niveau, Prix
    ├── [📎 Choisir fichier] — file_picker
    └── [Publier pour révision]

ÉTUDIANTS TAB
├── Mes classes (illimitées Expert)
│   └── ClassCard → liste étudiants
├── Tous les étudiants (recherche)
└── Row : avatar · nom · score · [💬 Contacter]

SESSIONS TAB
├── Sessions planifiées + passées
└── [+ Créer une session]

REVENUS TAB
├── Solde · [Retirer mes gains]
├── Commission : 80% (Plan Expert) · 20% WinPlus
├── Graphique mensuel
├── Revenus par contenu (top 10)
└── Transactions
```

### 2.4 Institution — Plan Enterprise

```
[Shell 5 tabs : Dashboard · Catalogue · Groupes · Étudiants · Profil]

DASHBOARD TAB
├── Hero : "[Institution] · Enterprise · [N] élèves"
├── KPIs (depuis mock/API)
│   ├── Élèves actifs : X / 2450
│   ├── Taux réussite : 74%
│   ├── Quiz/semaine : Y
│   └── Licences : Z / 2450
├── Matières les plus étudiées
├── [⚠️ 3 élèves à risque] → AtRiskScreen
│   └── AtRiskRow : nom · matière faible · score
│                   · [Contacter → MessagingScreen]
│                   · [Plan d'action → ActionPlanScreen]
└── [Plan d'action IA → ActionPlanScreen]

GROUPES TAB
├── [+ Créer un groupe]
└── GroupCard : nom · niveau · N élèves
    · [Voir élèves] · [Attribuer ressources]

ÉTUDIANTS TAB (Annuaire)
├── Recherche + filtres (niveau, groupe, statut)
├── Row : nom · niveau · groupe · score · [Contacter]
└── [📥 Importer CSV]

PROFIL TAB
├── Plan Enterprise · licences · quotas
├── [📊 Exporter rapport]
├── Mode sombre
└── Déconnexion
```

---

## 3. État réel d'implémentation

### 3.1 AUTH

| Écran | Fichier | Statut |
|---|---|---|
| Splash | `auth/splash_screen.dart` | ✅ |
| Welcome | `auth/welcome_screen.dart` | ✅ |
| Login (email/mdp) | `auth/login_screen.dart` | ✅ |
| Role selection | `auth/role_screen.dart` | ✅ |
| Forgot password | `auth/forgot_password_screen.dart` | ✅ |
| Reset password | `auth/reset_password_screen.dart` | ✅ |
| Verify code | `auth/verify_code_screen.dart` | ✅ |
| Complete profile | `auth/complete_profile_screen.dart` | ✅ |
| Email verified (succès) | `auth/email_verified_screen.dart` | ❌ à créer |
| Reconfirmation périodique | `auth/periodic_confirm_screen.dart` | ❌ à créer |
| Onboarding success | `auth/onboarding_success_screen.dart` | ❌ à créer |
| Google OAuth | — | ❌ stub SnackBar seulement |

### 3.2 ÉTUDIANT

| Écran / Feature | Fichier | Statut |
|---|---|---|
| Home basique | `student/student_home.dart` | ⚠️ 3 stats hardcodées, sans Continue Learning ni timeline |
| Catalogue | `student/student_tabs.dart` | ✅ |
| Recherche | `student/search_screen.dart` | ✅ |
| Détail contenu + achat invité | `student/content_detail_screen.dart` | ✅ |
| Quiz engine complet | `student/quiz_screen.dart` | ✅ |
| Exam Coach | `student/exam_coach_screen.dart` | ✅ |
| ProfileHubTab (5e tab "Moi") | `student/profile_hub_tab.dart` | ✅ câble 5 orphelins |
| Badges | `student/achievements_screen.dart` | ✅ câblé depuis hub |
| Certificats | `student/certificates_screen.dart` | ✅ câblé, sans affichage niveau plan |
| Favoris | `student/favorites_screen.dart` | ✅ câblé, limite non affichée |
| Historique téléchargements | `student/download_history_screen.dart` | ✅ câblé, sans filtre période |
| Notifications | `student/notifications_screen.dart` | ✅ câblé avec badge compteur |
| Profil (5 tabs : infos, sécurité, notifs, confidentialité, compte) | `student/profile_screen.dart` | ✅ avec 2FA wired |
| Continue Learning | — | ❌ absent |
| Recommandations IA (avec reason) | — | ❌ absent |
| Compte à rebours examens | — | ❌ absent |
| Activité récente (timeline) | — | ❌ absent |
| Notes et tags de révision | — | ❌ absent |
| Groupes d'étude | `student/study_groups_screen.dart` | ❌ à créer |
| Rapports de progression | `student/student_reports_screen.dart` | ❌ à créer |
| Quiz adaptatif / révision | `student/quiz_revision_screen.dart` | ❌ à créer |
| Différenciation visuelle par plan (Basic/Avancé/Premium UI) | — | ❌ même UI pour tous |
| Codes promo (-10/-15/-20%) | — | ❌ non implémenté |

### 3.3 PARENT

| Écran / Feature | Fichier | Statut |
|---|---|---|
| Dashboard | `parent/parent_tabs.dart` — `ParentDashTab` | ⚠️ données hardcodées, sans crédits ni cards enfants scrollables |
| Enfants (liste + gate plan gratuit) | `parent/parent_tabs.dart` — `ParentChildrenTab` | ⚠️ gate "1 enfant max" mais sans vrais plans |
| Ressources (catalogue parent) | `parent/parent_tabs.dart` — `ParentResourcesTab` | ✅ |
| Paiements | `parent/parent_tabs.dart` — `ParentPaymentsTab` | ✅ |
| Profil (avec messagerie) | `parent/parent_tabs.dart` — `ParentProfileTab` | ✅ |
| Ajout enfant | `parent/add_child_screen.dart` | ✅ |
| Activité enfant | `parent/child_activity_screen.dart` | ⚠️ pas de tabs, sans score engagement, boutons câblés vides |
| Alertes WinAI | `parent/winai_alerts_screen.dart` | ✅ |
| Statut abonnement | `parent/subscription_status_screen.dart` | ✅ |
| Messagerie | `shared/messaging/messaging_screen.dart` | ✅ câblé dans profil |
| Tab Messages dédié (4e tab shell) | `shell/role_shell.dart` | ❌ actuellement tab "Paiements" à la 4e place |
| Crédits mensuels affichés (10k/20k/40k XAF) | — | ❌ absent |
| Flow achat pour un enfant | `parent/buy_for_child_flow.dart` | ❌ à créer |
| Objectifs pour enfants (3 / illimité) | — | ❌ non implémenté |
| Score d'engagement enfant (0-100) | — | ❌ absent |
| Évènements à venir (examens, renouvellement) | — | ❌ absent |
| Modal renouvellement abonnement | `parent/renewal_sheet.dart` | ❌ bouton "Gérer" → `onTap: (){}` vide |
| Encouragement Sheet | `parent/encouragement_sheet.dart` | ❌ à créer |
| Chat IA (5/50/illimité selon plan) | — | ❌ non implémenté |
| Partage contenu entre enfants | — | ❌ non implémenté |
| Rapports de synthèse (email / PDF) | — | ❌ non implémenté |
| Alertes différenciées par plan (hebdo/quotidien/temps réel) | — | ⚠️ cards fixes, non différenciées |

### 3.4 PROFESSEUR

| Écran / Feature | Fichier | Statut |
|---|---|---|
| Dashboard | `teacher/teacher_tabs.dart` — `TeacherDashTab` | ⚠️ stats "907k / 4,8 / 412" hardcodées |
| Contenus (liste) | `teacher/teacher_tabs.dart` — `TeacherContentTab` | ✅ |
| Étudiants + messagerie | `teacher/teacher_tabs.dart` — `TeacherStudentsTab` | ✅ icône chat par étudiant |
| Sessions | `teacher/teacher_tabs.dart` — `TeacherSessionsTab` | ✅ |
| Revenus + revenus par contenu | `teacher/teacher_tabs.dart` — `TeacherRevenueTab` | ✅ section ajoutée |
| Publication contenu | `teacher/content_publish_screen.dart` | ⚠️ formulaire sans upload fichier (zone cliquable vide) |
| File de corrections | `teacher/correction_queue_screen.dart` | ✅ |
| Création de session | `teacher/session_create_screen.dart` | ✅ |
| Upload fichier (file_picker) | — | ❌ zone `onTap: (){}` sans action |
| ContentActionsSheet (éditer / stats / statut / supprimer) | `teacher/content_actions_sheet.dart` | ❌ à créer |
| Commission affichée (70% / 75% / 80%) | — | ❌ non affiché dans Revenue tab |
| Stats depuis données chargées (pas hardcodées) | — | ❌ valeurs en dur |
| Insights IA (section dashboard) | — | ❌ absent |
| Dashboard analytique par classe | — | ⚠️ très basique |
| Limites publications par plan (0/5/20/illimité) | — | ⚠️ gate "2 max gratuit" uniquement |
| Classes gérées selon plan (0/1/3/illimité) | — | ❌ non gated |
| Quiz générés par IA (2/10/illimité) | — | ❌ non implémenté |
| Éditeur riche document | — | ❌ non implémenté (v2) |
| Auto-publish calendrier | — | ❌ non implémenté (v2) |

### 3.5 INSTITUTION

| Écran / Feature | Fichier | Statut |
|---|---|---|
| Dashboard | `institution/institution_tabs.dart` — `InstitutionDashTab` | ⚠️ UI partielle, données hardcodées |
| Catalogue | `institution/institution_tabs.dart` — `InstitutionCatalogTab` | ✅ |
| Groupes | `institution/institution_tabs.dart` — `InstitutionGroupsTab` | ✅ |
| Analytics | `institution/institution_tabs.dart` — `InstitutionAnalyticsTab` | ✅ |
| Compte | `institution/institution_tabs.dart` — `InstitutionAccountTab` | ✅ |
| Élèves à risque | `institution/at_risk_screen.dart` | ⚠️ UI complète, boutons `onTap: (){}` vides |
| Plan d'action IA | `institution/action_plan_screen.dart` | ✅ |
| Création de groupe | `institution/group_create_screen.dart` | ✅ |
| Bouton "Contacter" câblé → MessagingScreen | — | ❌ vide |
| Bouton "Plan d'action" câblé → ActionPlanScreen | — | ❌ vide |
| Annuaire étudiants filtrable | `institution/student_directory_screen.dart` | ❌ à créer |
| Rapports exportables (mock PDF) | `institution/reports_screen.dart` | ❌ à créer |
| Dashboard enrichi (licences % / matières / KPIs) | — | ⚠️ données hardcodées |
| Gestion élèves en masse (CSV import mock) | — | ❌ non implémenté |

### 3.6 SHARED

| Écran / Feature | Fichier | Statut |
|---|---|---|
| Messagerie + chat | `shared/messaging/messaging_screen.dart` | ✅ |
| Commande invitée | `shared/shop/guest_order_screen.dart` | ✅ |
| Pricing screen (API wired) | `shared/subscription/pricing_screen.dart` | ✅ |
| SubscriptionNotifier + gates de base | `shared/subscription/subscription_notifier.dart` | ✅ |
| UpgradeSheet | `shared/subscription/upgrade_sheet.dart` | ⚠️ bouton "Voir les plans" → `onTap: (){}` vide |
| Cloche 🔔 dans AppBar (tous rôles) | `shell/role_shell.dart` | ❌ absent |
| Pomodoro / Timer d'études | `shared/study_timer_screen.dart` | ❌ à créer (v2) |
| Liens légaux (CGU, Confidentialité) | `shared/legal_screen.dart` | ❌ à créer |

---

## 4. Mock data groupées par endpoint API

> **Convention :** chaque bloc indique le endpoint API qui remplacera ces données le moment venu.  
> Les classes mock sont à définir dans `lib/data/mock_data.dart`.

---

### 4.1 `GET /api/auth/me` — Profil utilisateur

```dart
// Remplace : UserService.instance.getProfile()
// Actuellement : appel API réel (✅ connecté)
// Mock de secours si l'API échoue :
static const ApiUserProfile mockUserProfile = ApiUserProfile(
  id: 'u-001',
  fullName: 'Miguel Fopa',
  email: 'miguel.fopa@example.com',
  phone: '+237 699 000 001',
  level: 'Terminale C',
  role: 'student',
  avatarUrl: null,
);
```

### 4.2 `GET /api/subscriptions/me` — Abonnement actuel

```dart
// Remplace : SubscriptionService.instance.getCurrent()
// Actuellement : appel API réel (✅ connecté via loadFromApi())
// Valeur initiale dans SubscriptionNotifier avant chargement :
static const ActiveSubscription mockCurrentSubscription = ActiveSubscription(
  tier: PlanTier.premium, // → PlanTier.libre | standard | premium | famille
  planName: 'Ultime',
  expiresAt: '2027-08-21',
  autoRenew: true,
  downloadsLimit: 0,    // 0 = illimité
  quizDailyLimit: 0,
  aiMessagesLimit: 0,
);
```

### 4.3 `GET /api/subjects` — Catalogue

```dart
// Remplace : SubjectService.instance.getAll()
// Actuellement : appel API réel (✅ connecté)
// Pas de mock statique — données chargées dynamiquement
```

### 4.4 `GET /api/progress` — Contenus en cours (Continue Learning)

```dart
// Remplace : ProgressService.instance.getInProgress()
// Actuellement : ❌ endpoint non connecté, widget absent
static final List<InProgressContent> mockInProgress = [
  InProgressContent(
    contentId: 'c-001',
    title: 'BAC C Maths 2023',
    subjectId: 'math',
    progressPercent: 0.65,
    lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  InProgressContent(
    contentId: 'c-003',
    title: 'Pack ENSP 2019-2023',
    subjectId: 'pc',
    progressPercent: 0.30,
    lastAccessedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
```

### 4.5 `GET /api/recommendations` — Recommandations IA

```dart
// Remplace : RecommendationService.instance.get()
// Actuellement : ❌ endpoint non connecté
static final List<AiRecommendation> mockRecommendations = [
  AiRecommendation(
    contentId: 'c-005',
    title: 'Quiz Chimie — Oxydoréduction',
    reason: 'Tu n\'as pas révisé la Chimie depuis 5 jours',
    subjectId: 'chimie',
  ),
  AiRecommendation(
    contentId: 'c-002',
    title: 'Correction Physique BAC D 2022',
    reason: 'Populaire chez les élèves de Terminale C',
    subjectId: 'pc',
  ),
];
```

### 4.6 `GET /api/activity` — Activité récente étudiant

```dart
// Remplace : ActivityService.instance.getRecent()
// Actuellement : ❌ endpoint non connecté
static final List<ActivityEvent> mockActivities = [
  ActivityEvent(type: 'quiz', title: 'Quiz Maths — Suites',
    score: '13/15', at: DateTime.now().subtract(const Duration(hours: 1))),
  ActivityEvent(type: 'download', title: 'BAC D Physique 2023',
    at: DateTime.now().subtract(const Duration(hours: 3))),
  ActivityEvent(type: 'quiz', title: 'Quiz Chimie — Oxydoréduction',
    score: '8/15', at: DateTime.now().subtract(const Duration(days: 1))),
];
```

### 4.7 `GET /api/exams/upcoming` — Examens à venir

```dart
// Remplace : ExamService.instance.getUpcoming()
// Actuellement : ❌ endpoint non connecté
static final List<UpcomingExam> mockUpcomingExams = [
  UpcomingExam(name: 'BAC C', targetDate: DateTime(2026, 10, 8),
    subject: 'Mathématiques'),
  UpcomingExam(name: 'Probatoire', targetDate: DateTime(2026, 9, 15),
    subject: 'Physique'),
];
```

### 4.8 `GET /api/student/stats` — Stats étudiant

```dart
// Remplace : StudentService.instance.getStats()
// Actuellement : ❌ valeurs hardcodées dans WinData (avgScore, studyToday)
static const StudentStats mockStudentStats = StudentStats(
  streakDays: 14,
  avgScore: 78,
  hoursThisWeek: 32,
  totalBadges: 14,
  totalCertificates: 2,
  totalFavorites: 28,
);
```

### 4.9 `GET /api/parent/account` — Compte parent (crédits)

```dart
// Remplace : ParentService.instance.getAccount()
// Actuellement : ❌ non connecté, crédits absents de l'UI
static const ParentAccount mockParentAccount = ParentAccount(
  name: 'Solange Nkono',
  plan: 'Famille',
  creditsAvailable: 40000, // XAF — Plan Famille
  creditsTotal: 40000,
  creditsUsed: 12500,
  childrenLimit: 5,        // Plan Famille
);
```

### 4.10 `GET /api/parent/children` — Enfants suivis

```dart
// Remplace : ParentService.instance.getChildren()
// Actuellement : ✅ connecté mais dashboard sans cards scrollables
// Mock de secours :
static final List<TrackedChild> mockChildren = [
  TrackedChild(id: 'k-001', name: 'Ahmed Nkono', level: 'Tle C',
    avgScore: 78, trend: Trend.up, lastActiveAt: DateTime.now()),
  TrackedChild(id: 'k-002', name: 'Brenda Nkono', level: '2nde',
    avgScore: 62, trend: Trend.down,
    lastActiveAt: DateTime.now().subtract(const Duration(days: 1))),
  TrackedChild(id: 'k-003', name: 'Kevin Nkono', level: 'BEPC',
    avgScore: 85, trend: Trend.up, lastActiveAt: DateTime.now()),
];
```

### 4.11 `GET /api/parent/child/{id}/activity` — Activité d'un enfant

```dart
// Remplace : ParentService.instance.getChildActivity(childId)
// Actuellement : ⚠️ connecté mais tabs et score engagement absents
static const ChildEngagement mockChildEngagement = ChildEngagement(
  score: 73,          // 0-100
  scoreDelta: +8,     // vs semaine précédente
  sessionsThisWeek: 5,
  avgSessionMinutes: 42,
);
```

### 4.12 `GET /api/parent/upcoming-events` — Évènements à venir (parent)

```dart
// Remplace : ParentService.instance.getUpcomingEvents()
// Actuellement : ❌ absent de l'UI
static final List<UpcomingEvent> mockUpcomingEvents = [
  UpcomingEvent(type: 'renewal', label: 'Renouvellement abonnement',
    date: DateTime.now().add(const Duration(days: 7))),
  UpcomingEvent(type: 'exam', label: 'BAC C · Ahmed',
    date: DateTime(2026, 10, 8)),
];
```

### 4.13 `GET /api/teacher/content` — Contenus du professeur

```dart
// Remplace : TeacherService.instance.getContent()
// Actuellement : ✅ connecté
// Stats réelles à calculer depuis la liste :
// totalRevenue = content.fold(0, (a, c) => a + c.revenue)
// avgRating = content.fold(0.0, ...) / content.length
```

### 4.14 `GET /api/teacher/stats` — Stats globales professeur

```dart
// Remplace : TeacherService.instance.getStats() (endpoint à créer)
// Actuellement : ❌ valeurs "907k / 4,8 / 412" hardcodées
static const TeacherStats mockTeacherStats = TeacherStats(
  totalRevenue: 907000,   // XAF
  avgRating: 4.8,
  totalStudents: 412,
  commissionRate: 0.80,   // Plan Expert
  publishedCount: 18,
  totalDownloads: 2140,
);
```

### 4.15 `GET /api/teacher/insights` — Insights IA professeur

```dart
// Remplace : TeacherService.instance.getInsights()
// Actuellement : ❌ section absente du dashboard
static final List<TeacherInsight> mockInsights = [
  TeacherInsight(icon: Icons.local_fire_department,
    text: 'Pack ENSP 2019-2023 — meilleur vendeur ce mois'),
  TeacherInsight(icon: Icons.people,
    text: 'Terminale C représente 68% de votre audience'),
  TeacherInsight(icon: Icons.trending_up,
    text: '+12% de téléchargements cette semaine'),
];
```

### 4.16 `GET /api/institution/stats` — KPIs institution

```dart
// Remplace : InstitutionService.instance.getStats()
// Actuellement : ❌ valeurs hardcodées dans institution_tabs.dart
static const InstitutionStats mockInstitutionStats = InstitutionStats(
  name: 'Lycée Bilingue de Yaoundé',
  plan: 'Enterprise',
  licensesTotal: 2450,
  licensesUsed: 1823,
  avgSuccessRate: 74,       // %
  activeStudentsToday: 642,
  quizThisWeek: 1847,
);
```

### 4.17 `GET /api/institution/subject-stats` — Matières les plus étudiées

```dart
// Remplace : InstitutionService.instance.getSubjectStats()
// Actuellement : ❌ hardcodé
static final List<SubjectStat> mockSubjectStats = [
  SubjectStat(subject: 'Mathématiques', sessions: 1240),
  SubjectStat(subject: 'Physique-Chimie', sessions: 890),
  SubjectStat(subject: 'Français', sessions: 654),
  SubjectStat(subject: 'SVT', sessions: 420),
];
```

### 4.18 `GET /api/institution/students` — Annuaire étudiants

```dart
// Remplace : InstitutionService.instance.getStudents()
// Actuellement : ❌ StudentDirectoryScreen à créer
static final List<MockStudent> mockStudents = [
  MockStudent(id: 's-001', name: 'Ahmed Nkono', level: 'Tle C',
    group: 'Classe A', score: 78, active: true),
  MockStudent(id: 's-002', name: 'Brenda Mballa', level: 'Tle C',
    group: 'Classe A', score: 86, active: true),
  MockStudent(id: 's-003', name: 'Yann Talla', level: '1ère D',
    group: 'Classe B', score: 54, active: false),
  // ... 20+ étudiants pour tester la recherche / filtres
];
```

### 4.19 `GET /api/notifications` — Notifications

```dart
// Remplace : UserService.instance.getNotifications()
// Actuellement : ✅ connecté (NotificationsScreen + badge dans ProfileHubTab)
```

### 4.20 `GET /api/messaging/conversations` — Messagerie

```dart
// Remplace : MessagingService.instance.getConversations()
// Actuellement : ✅ connecté (MessagingScreen + ConversationScreen)
```

---

## 5. Backlog ÉTUDIANT — Plan Ultime

### 5.1 Home enrichie — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/student/student_home.dart`

| Widget à ajouter | Endpoint mock (§4) | Statut |
|---|---|---|
| Nom + date dynamiques depuis SessionManager | `§4.1` | ❌ |
| Stats : streak 🔥, score moyen, heures/semaine | `§4.8` | ❌ hardcodé |
| **Continue Learning** (2-3 cards avec %) | `§4.4` | ❌ |
| **Recommandations IA** (avec `reason` affiché) | `§4.5` | ❌ |
| **Compte à rebours** (prochain examen) | `§4.7` | ❌ |
| **Activité récente** (timeline 5 événements) | `§4.6` | ❌ |

### 5.2 Différenciation visuelle par plan — 🔴 PRIORITÉ HAUTE

Le dashboard doit visuellement changer selon le plan (Basic/Avancé/Premium UI per `Plan_Abonnement.md §5`) :

```
Plan Gratuit  → stats réduites, bandeau "Passez Standard →"
Plan Standard → dashboard Avancé, graphique progression visible
Plan Premium  → dashboard Premium, recommandations IA actives
Plan Ultime   → tout visible, badge 🏆, coaching personnalisé
```

### 5.3 Notes et tags de révision — 🟡 PRIORITÉ MOYENNE

**Fichier :** widget dans `lib/student/content_detail_screen.dart`

```
Section "Mes notes" (inline)
├── Tags rapides : [À réviser] [Difficile] [Maîtrisé]
├── [+ Ajouter une note] → TextField inline
└── Liste notes existantes (max 5 visibles, scroll)
```

### 5.4 Groupes d'étude — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/student/study_groups_screen.dart`

```
StudyGroupsScreen
├── Mes groupes (Créer 1 Gratuit / 5 Premium / 5+ Ultime)
│   └── Card : nom · N membres · matière · dernière activité
├── [+ Créer un groupe] → form
└── [Rejoindre par code]
```

### 5.5 Rapports de progression — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/student/student_reports_screen.dart`

```
StudentReportsScreen
├── Sélecteur période (7j / 30j / 90j / 1an / Illimité selon plan)
├── Score moyen par matière (barres horizontales)
├── Progression hebdomadaire (courbe)
├── Quiz : taux de réussite, matières fortes/faibles
├── [Exporter PDF] — Standard+
└── [Exporter Excel] — Premium+
```

### 5.6 Quiz adaptatif / révision — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/student/quiz_revision_screen.dart`

```
QuizRevisionScreen
├── "Questions ratées récemment" (depuis historique)
├── Filtre par matière
└── Lance QuizActiveScreen avec les questions échouées
```

### 5.7 Historique avec filtre période — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/student/download_history_screen.dart` (enrichir)

Ajouter sélecteur période : 30j (Gratuit) / 90j (Standard) / 1an (Premium) / Illimité (Ultime).

---

## 6. Backlog PARENT — Plan Famille

### 6.1 Tab Messages dédié — 🔴 PRIORITÉ HAUTE

Dans `lib/shell/role_shell.dart` : remplacer le 4e tab Paiements par un tab **Messages** qui pointe directement sur `MessagingScreen`. Paiements reste accessible depuis le Profil.

### 6.2 Dashboard enrichi (ParentDashTab) — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/parent/parent_tabs.dart` — `ParentDashTab`

```
ParentDashTab — Plan Famille
├── Hero : "Bonjour [Prénom depuis §4.1]"
│         💰 Crédits disponibles : 40 000 XAF (depuis §4.9)
├── Enfants (cards horizontales scrollables, depuis §4.10)
│   └── ChildSummaryCard : avatar · nom · score · tendance ↗ · statut
├── [⚠️ Alerte WinAI] si alertes non lues
├── Évènements à venir (depuis §4.12)
│   ├── 📅 Renouvellement dans N jours → RenewalSheet
│   └── 🎯 BAC C [enfant] dans N jours
└── [Acheter du contenu pour un enfant →] → BuyForChildScreen
```

### 6.3 ChildActivityScreen enrichie — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/parent/child_activity_screen.dart`

```
ChildActivityScreen (3 tabs)
├── Tab "Activité"
│   ├── Score d'engagement : 73/100 📈 (+8 cette semaine) (depuis §4.11)
│   ├── Sessions en barres (sem.)
│   └── Timeline (quiz, DL, sessions)
├── Tab "Résultats"
│   ├── Score moyen par matière
│   └── Dernier quiz + trend
├── Tab "Alertes WinAI"
│   └── Liste alertes (difficulté, streak rompu, matière faible)
├── [Voir ressources pour cet enfant] — câbler catalogue filtré
├── [Générer un quiz] — câbler QuizHubScreen
└── [💌 Envoyer un encouragement] → EncouragementSheet
```

### 6.4 RenewalSheet — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/parent/renewal_sheet.dart`

```
RenewalSheet (bottom sheet)
├── Plan actuel : Famille · 12 000 XAF/mois
├── Toggle [Mensuel | Annuel -15%]
├── Résumé : 12 000 XAF/mois · ou 122 400 XAF/an
├── [MTN Mobile Money] · [Orange Money]
└── [Confirmer le renouvellement]
```

### 6.5 Flow "Acheter pour un enfant" — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/parent/buy_for_child_screen.dart`

```
BuyForChildScreen
├── "Pour quel enfant ?" (chips sélecteur depuis §4.10)
├── Catalogue filtré (niveau de l'enfant)
└── Tap → GuestOrderScreen pré-rempli (email parent)
```

### 6.6 EncouragementSheet — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/parent/encouragement_sheet.dart`

```
EncouragementSheet (bottom sheet)
├── Templates prédéfinis
│   ├── 💪 "Continue comme ça, je suis fier(e) de toi !"
│   ├── 📚 "N'oublie pas de réviser la Chimie ce soir !"
│   └── 🎯 "Plus que N jours avant le BAC, tu peux le faire !"
├── [Écrire un message personnalisé]
└── [Envoyer] → MessagingService.sendMessage()
```

---

## 7. Backlog PROFESSEUR — Plan Expert

### 7.1 Upload fichier dans ContentPublishScreen — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/teacher/content_publish_screen.dart`

```dart
// Ajouter file_picker dans pubspec.yaml si absent, puis :
onTap: () async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'epub', 'zip'],
  );
  if (result != null) setState(() => _pickedFile = result.files.first);
},
// Afficher nom du fichier sélectionné + taille
```

### 7.2 ContentActionsSheet — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/teacher/content_actions_sheet.dart`

Câbler depuis `TeacherContentTab` : bouton `⋯` ou long-press sur chaque row.

```
ContentActionsSheet (bottom sheet)
├── [📊 Statistiques] → stats inline (téléchargements, note moy., revenus)
├── [✏️  Modifier] → form pré-rempli
├── [🔄 Changer statut] → chips (Publié / Brouillon / Archivé)
└── [🗑️  Supprimer] → dialog confirmation → TeacherService.deleteContent()
```

### 7.3 Commission affichée + stats réelles — 🟡 PRIORITÉ MOYENNE

**Fichier :** `TeacherRevenueTab` dans `lib/teacher/teacher_tabs.dart`

```dart
// Ajouter dans Revenue tab :
Text('Commission Plan Expert : 80% pour vous · 20% WinPlus')

// Calculer depuis données chargées (au lieu de hardcoder) :
final totalRevenue = _content?.fold(0, (a, c) => a + c.revenue) ?? 0;
final avgRating = _content == null || _content!.isEmpty ? 0.0
    : _content!.fold(0.0, (a, c) => a + c.rating) / _content!.length;
```

### 7.4 Insights IA dans le dashboard — 🟡 PRIORITÉ MOYENNE

**Fichier :** `TeacherDashTab` dans `lib/teacher/teacher_tabs.dart`

Ajouter section "Insights" en bas du dashboard depuis `§4.15`.

### 7.5 Classes gérées dans TeacherStudentsTab — 🟡 PRIORITÉ MOYENNE

```
TeacherStudentsTab enrichi
├── Section "Mes classes" (illimitées Plan Expert)
│   └── ClassCard : nom · N élèves · score moyen · [Voir →]
├── Section "Tous les étudiants" (recherche + filtre)
└── [+ Créer une classe] → CreateClassSheet
```

---

## 8. Backlog INSTITUTION — Plan Enterprise

### 8.1 Boutons AtRiskScreen câblés — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/institution/at_risk_screen.dart`

```dart
// Bouton "Contacter" :
onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const MessagingScreen())),

// Bouton "Plan d'action" :
onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => ActionPlanScreen(student: student))),
```

### 8.2 Dashboard Institution enrichi — 🔴 PRIORITÉ HAUTE

**Fichier :** `lib/institution/institution_tabs.dart` — `InstitutionDashTab`

Remplacer les valeurs hardcodées par les données mock `§4.16` et `§4.17` :

```dart
// Au lieu de "2 450", "74%", etc. en dur :
final stats = WinData.mockInstitutionStats;
final subjects = WinData.mockSubjectStats;
```

### 8.3 Annuaire étudiants — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/institution/student_directory_screen.dart`

```
StudentDirectoryScreen
├── Barre de recherche (nom, matricule)
├── Filtres : Niveau · Groupe · Statut
├── Liste étudiants (depuis §4.18)
│   └── Row : avatar · nom · niveau · groupe · score · [Contacter]
└── [📥 Importer CSV] → dialog mock "Import en cours..."
```

### 8.4 RapportsScreen — 🟡 PRIORITÉ MOYENNE

**Fichier :** `lib/institution/reports_screen.dart`

```
ReportsScreen
├── Sélecteur période
├── Types : Rapport global · Par classe · Individuel
└── [Générer PDF] → dialog "Rapport en cours de génération..."
```

---

## 9. Backlog AUTH & SHARED

### AUTH manquants

| Écran | Fichier | Priorité | Description |
|---|---|---|---|
| Email Verified | `lib/auth/email_verified_screen.dart` | 🔴 | Confetti + [Continuer] |
| Reconfirmation périodique | `lib/auth/periodic_confirm_screen.dart` | 🔴 | Code 6 chiffres, toutes les 30-45 jours |
| Onboarding success | `lib/auth/onboarding_success_screen.dart` | 🟡 | Post-complete_profile |

### SHARED manquants

| Feature | Fichier | Priorité | Description |
|---|---|---|---|
| Cloche 🔔 AppBar tous rôles | `shell/role_shell.dart` | 🔴 | Badge unread → NotificationsScreen |
| UpgradeSheet → PricingScreen | `shared/subscription/upgrade_sheet.dart` | 🔴 | Bouton "Voir les plans" actuellement vide |
| Liens légaux (CGU, Politique) | `shared/legal_screen.dart` | 🟡 | Obligatoire légalement |
| Pomodoro / Timer d'études | `shared/study_timer_screen.dart` | 🟡 | 100% client-side (v2) |

---

## 10. Ordre d'implémentation — Sprints

### Sprint 1 — Navigation & Câblage

```
1.  ProfileHubTab (student)               ✅ FAIT — 5 orphelins câblés
2.  Tab Messages dédié (parent shell)     ❌ remplacer 4e tab
3.  Cloche 🔔 AppBar tous rôles           ❌ badge + NotificationsScreen
4.  Boutons AtRisk câblés (institution)   ❌ Contacter + Plan d'action
5.  UpgradeSheet → PricingScreen          ❌ routage manquant
```

### Sprint 2 — Home enrichie (rétention)

```
6.  Mock data : §4.4 à §4.8 (InProgressContent, ActivityEvent, etc.)
7.  Student home : nom + date dynamiques
8.  Student home : Continue Learning widget
9.  Student home : Recommandations IA avec reason
10. Student home : Compte à rebours examen
11. Student home : Activité récente timeline
12. Student home : Stats enrichies (streak, score, heures)
```

### Sprint 3 — Parent Famille complet

```
13. Mock data : §4.9 à §4.12
14. ParentDashTab enrichi (crédits, cards enfants, évènements)
15. ChildActivityScreen : 3 tabs + score engagement + boutons câblés
16. RenewalSheet (modal renouvellement)
17. EncouragementSheet
18. BuyForChildScreen
```

### Sprint 4 — Teacher Expert complet

```
19. file_picker dans ContentPublishScreen
20. ContentActionsSheet (stats / modifier / statut / supprimer)
21. Mock data : §4.13 à §4.15
22. Dashboard : stats calculées depuis données (pas hardcodées)
23. Dashboard : section insights IA
24. Revenue tab : commission 80% affichée
25. TeacherStudentsTab : classes + ClassCard
```

### Sprint 5 — Institution Enterprise complet

```
26. Mock data : §4.16 à §4.18
27. InstitutionDashTab enrichi (KPIs depuis mock)
28. StudentDirectoryScreen (annuaire + recherche + CSV mock)
29. ReportsScreen (génération mock PDF)
```

### Sprint 6 — AUTH manquants

```
30. email_verified_screen
31. periodic_confirm_screen
32. onboarding_success_screen
```

### Sprint 7 — Features enrichissement student

```
33. Notes et tags de révision (ContentDetailScreen)
34. StudyGroupsScreen
35. StudentReportsScreen
36. QuizRevisionScreen (quiz adaptatif)
37. Différenciation visuelle par plan (dashboard Basic/Avancé/Premium)
38. Historique avec filtre période
39. Liens légaux
```

---

## 11. Checklist gates — Phase 2

> Après validation UX, ajouter les restrictions par plan en utilisant `SubscriptionScope.of(context)`.  
> Règle : un gate bloque la limite du plan inférieur, jamais la fonctionnalité elle-même.

| Gate | Gratuit | Standard | Premium | Ultime |
|---|---|---|---|---|
| Téléchargements | 5/mois | Illimité | Illimité | Illimité |
| Corrections | 5/mois | 30/mois | Illimité | Illimité |
| Quiz par jour | 3 | 10 | Illimité | Illimité |
| Messages IA/jour | 5 | 50 | 200 | Illimité |
| Favoris | 5 | 50 | 200 | Illimité |
| Groupes d'étude | ❌ | Créer 1 | Créer 5 | Créer 5+ |
| Historique | 30j | 90j | 1 an | Illimité |
| Rapports | ❌ | PDF | PDF+Excel | Tous formats |
| Certificats | ❌ | PDF | PDF+Email | Signé |

| Gate Parent | Gratuit | Basique | Complet | Famille |
|---|---|---|---|---|
| Enfants suivis | 0 | 1 | 2-3 | 4-5 |
| Crédits mensuels | 0 | 10 000 XAF | 20 000 XAF | 40 000 XAF |
| Alertes | ❌ | Hebdo | Quotidien | Temps réel |
| Messagerie enseignants | ❌ | ❌ | ✅ | ✅ |
| Chat IA | ❌ | 5/j | 50/j | Illimité |

| Gate Teacher | Gratuit | Fondateur | Pro | Expert |
|---|---|---|---|---|
| Publications/mois | 0 | 5 | 20 | Illimité |
| Classes | 0 | 1 (30 élèves) | 3 (100 élèves) | Illimité |
| Commission | ❌ | 70% | 75% | 80% |
| Quiz IA | ❌ | 2/mois | 10/mois | Illimité |

---

*Stratégie : UI tier max d'abord — tiers cumulatifs — gates en Phase 2*

---

## 12. Cahier des charges par écran

> **Convention :**
> - **Local** = donnée calculée ou stockée sur l'appareil, à implémenter maintenant
> - **API (mocké)** = endpoint réel à mocker, référence vers §4.X
> - **Navigation** = chemin UX complet pour atteindre l'écran

---

### SPRINT 1 — Navigation & Câblage

---

#### 📱 S1-1 — Cloche 🔔 notifications dans l'AppBar (tous rôles)

**Fichier :** `lib/shell/role_shell.dart`  
**Navigation :** Visible dès l'ouverture de l'app pour tout utilisateur connecté, en haut à droite de chaque tab.

**Contenu affiché :**
- Icône cloche `Icons.notifications_outlined` en haut à droite de l'AppBar
- Badge rouge avec le nombre de notifications non lues (ex. "3") affiché sur la cloche si `unreadCount > 0`
- Badge absent si toutes les notifications sont lues

**Données locales (à implémenter maintenant) :**
- Compteur `_unreadCount` chargé au démarrage du shell via `UserService.instance.getNotifications()`
- Filtrer les notifications `where((n) => !n.isRead)` pour obtenir le count
- Rafraîchir le compteur quand l'utilisateur revient de `NotificationsScreen`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/notifications` | Liste des notifications avec `isRead` | `§4.19` ✅ connecté |

**Action :** Tap sur la cloche → `Navigator.push` vers `NotificationsScreen`

---

#### 📱 S1-2 — Tab Messages dédié (shell Parent)

**Fichier :** `lib/shell/role_shell.dart`  
**Navigation :** Barre de navigation inférieure du rôle Parent → 4e onglet "Messages"

**Contenu affiché :**
- Icône `Icons.chat_bubble_outlined` dans la barre de navigation
- Label "Messages"
- Badge non-lu (même logique que la cloche, mais pour les messages)
- Le contenu de ce tab est directement `MessagingScreen` (liste des conversations)

**Données locales (à implémenter maintenant) :**
- Changer `NavItem('Paiements', Icons.account_balance_wallet_outlined)` en `NavItem('Messages', Icons.chat_bubble_outlined)`
- Changer `ParentPaymentsTab()` en `MessagingScreen()` dans `_pagesFor`
- Paiements reste accessible depuis `ParentProfileTab` via un bouton "Historique paiements"

**Appels API (mockés) :** aucun nouveau — `MessagingScreen` est déjà connecté `§4.20`

---

#### 📱 S1-3 — AtRiskScreen — boutons câblés

**Fichier :** `lib/institution/at_risk_screen.dart`  
**Navigation :** Shell Institution → Tab Accueil (Dashboard) → Carte "⚠️ N élèves à risque" → `AtRiskScreen`

**Contenu affiché :**
- AppBar : "Élèves à risque" + filtre chips [Tous · Critique · Modéré]
- Pour chaque élève à risque :
  - Avatar + nom complet de l'élève
  - Niveau (ex. "Terminale C")
  - Matière faible principale (ex. "Chimie — 34%")
  - Score global actuel (ex. "Score : 41%")
  - Dernière activité (ex. "Inactif depuis 8 jours")
  - Indicateur de sévérité : 🔴 Critique / 🟡 Modéré
  - Bouton [💬 Contacter] → ouvre `MessagingScreen` avec ce student pré-sélectionné
  - Bouton [📋 Plan d'action] → ouvre `ActionPlanScreen(studentId: id)`

**Données locales (à implémenter maintenant) :**
- Logique filtre chips : `_filter` enum (Tous / Critique / Modéré)
- Critique = score < 40% ou inactif > 7 jours
- Modéré = score 40-55% ou inactif 3-7 jours
- Tri : Critique en premier, puis Modéré

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/institution/at-risk` | Liste étudiants à risque avec score, matière faible, dernière activité | Créer `mockAtRiskStudents` dans `mock_data.dart` |

```dart
// À ajouter dans mock_data.dart
static final List<AtRiskStudent> mockAtRiskStudents = [
  AtRiskStudent(id: 's-007', name: 'Pierre Manga', level: 'Tle C',
    weakSubject: 'Chimie', weakScore: 34, globalScore: 41,
    inactiveDays: 8, severity: RiskLevel.critical),
  AtRiskStudent(id: 's-012', name: 'Chloé Biya', level: '1ère D',
    weakSubject: 'Mathématiques', weakScore: 42, globalScore: 51,
    inactiveDays: 4, severity: RiskLevel.moderate),
  AtRiskStudent(id: 's-019', name: 'Serge Ateba', level: 'Tle C',
    weakSubject: 'Physique', weakScore: 38, globalScore: 44,
    inactiveDays: 10, severity: RiskLevel.critical),
];
```

---

#### 📱 S1-4 — UpgradeSheet → PricingScreen

**Fichier :** `lib/shared/subscription/upgrade_sheet.dart`  
**Navigation :** Déclenché depuis n'importe quel endroit où un contenu est verrouillé (gate). Ex : étudiant gratuit tente de télécharger le 6e fichier.

**Contenu affiché :**
- Bottom sheet avec une illustration ou icône plan supérieur
- Titre : "Passez au plan [X] pour débloquer cette fonctionnalité"
- Description courte de ce que le plan supérieur apporte
- Bouton principal [Voir les plans] → `PricingScreen`
- Bouton secondaire [Plus tard] → ferme le sheet

**Données locales (à implémenter maintenant) :**
- Remplacer `onTap: () {}` du bouton "Voir les plans" par :
  ```dart
  onTap: () {
    Navigator.pop(context); // ferme le sheet
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
  }
  ```

**Appels API (mockés) :** aucun

---

### SPRINT 2 — Home Étudiant enrichie

---

#### 📱 S2-1 — StudentHomeTab (version enrichie)

**Fichier :** `lib/student/student_home.dart`  
**Navigation :** Shell Étudiant → Tab 1 "Accueil" (tab par défaut à l'ouverture)

**Contenu affiché (de haut en bas) :**

1. **Header dynamique**
   - "Bonjour [Prénom] 👋" — prénom chargé depuis `SessionManager`
   - Date du jour en français (ex. "Vendredi 22 août 2026")
   - Icône cloche à droite → NotificationsScreen (avec badge)

2. **Bandeau streak + stats (3 cartes horizontales)**
   - 🔥 Streak : "14 jours de suite"
   - 📊 Score moyen : "78%"
   - ⏱ Cette semaine : "32h d'étude"

3. **Continue Learning** (section "Reprendre où tu t'es arrêté")
   - Titre de section "Continuer →"
   - 2-3 cards horizontales scrollables, chacune affiche :
     - Miniature/icône du contenu
     - Titre du contenu (tronqué à 2 lignes)
     - Matière (ex. "Mathématiques")
     - Barre de progression en % (ex. "65%")
     - Label "Reprendre →"
   - Si vide : "Commence un contenu pour le voir ici"

4. **Recommandations WinAI** (section "Pour toi")
   - 2 cards verticales, chacune :
     - Titre du contenu
     - Reason en italique (ex. "Tu n'as pas révisé la Chimie depuis 5 jours")
     - Badge matière (ex. "Chimie")
     - [Voir →]

5. **Compte à rebours**
   - Titre "Prochain examen"
   - 🎯 Nom de l'examen (ex. "BAC C")
   - Nombre de jours restants en grand (ex. "47 jours")
   - Sous-texte : "Maths · 8 octobre 2026"

6. **Activité récente** (section "Cette semaine")
   - Timeline de 5 événements max :
     - Icône type (quiz 🧠, téléchargement ⬇, session 📅)
     - Titre de l'activité
     - Score si quiz (ex. "13/15")
     - Temps relatif (ex. "il y a 1h")

**Données locales (à implémenter maintenant) :**
- `String _greet()` → "Bonjour" / "Bon après-midi" / "Bonsoir" selon l'heure locale
- `String _formattedDate()` → `DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now())`
- `String _relativeTime(DateTime dt)` → "il y a Xmin / Xh / hier / il y a Xj"
- Chargement en parallèle via `Future.wait([...])` des 5 sources de données
- État de chargement : shimmer ou `CircularProgressIndicator` centré par section

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/auth/me` | Prénom de l'utilisateur | `§4.1` |
| `GET /api/student/stats` | streak, avgScore, hoursThisWeek | `§4.8` |
| `GET /api/progress` | Contenus en cours + % | `§4.4` |
| `GET /api/recommendations` | Recommandations IA + reason | `§4.5` |
| `GET /api/exams/upcoming` | Prochain examen + date | `§4.7` |
| `GET /api/activity` | Activité récente (5 événements) | `§4.6` |

---

### SPRINT 3 — Parent Famille complet

---

#### 📱 S3-1 — ParentDashTab (version enrichie)

**Fichier :** `lib/parent/parent_tabs.dart` — `ParentDashTab`  
**Navigation :** Shell Parent → Tab 1 "Accueil" (tab par défaut)

**Contenu affiché (de haut en bas) :**

1. **Header**
   - "Bonjour [Prénom] 👋" depuis `SessionManager`
   - Date du jour en français
   - Cloche 🔔 avec badge non lus

2. **Crédits mensuels** (card pleine largeur)
   - Icône 💰
   - "Crédits disponibles : 27 500 XAF"
   - Barre de progression : crédits utilisés / total (ex. 12 500 / 40 000 XAF)
   - Sous-texte : "Plan Famille · Renouvellement dans 7 jours"
   - [Voir l'abonnement] → `SubscriptionStatusScreen`

3. **Mes enfants** (cards horizontales scrollables)
   - Pour chaque enfant :
     - Avatar (initiales)
     - Prénom
     - Niveau (ex. "Tle C")
     - Score moyen (ex. "78%")
     - Flèche tendance ↗ (vert) ou ↘ (rouge)
     - Point statut : 🟢 "Actif aujourd'hui" · 🟡 "Hier" · 🔴 "Inactif"
   - Tap sur une card → `ChildActivityScreen(child: child)`

4. **Alerte WinAI** (affichée si alertes non lues)
   - Card jaune avec icône ⚠️
   - "Ahmed n'a pas révisé la Chimie depuis 5 jours"
   - [Voir toutes les alertes →] → `WinAIAlertsScreen`

5. **Évènements à venir**
   - Liste verticale :
     - 📅 "Renouvellement abonnement · dans 7 jours" → [Renouveler] → `RenewalSheet`
     - 🎯 "BAC C · Ahmed · dans 47 jours"
     - 🎯 "BEPC · Kevin · dans 62 jours"

6. **Action rapide**
   - Bouton pleine largeur [🛒 Acheter du contenu pour un enfant] → `BuyForChildScreen`

**Données locales (à implémenter maintenant) :**
- `_greet()` + `_formattedDate()` (même logique que student home)
- Calcul crédits restants : `account.creditsTotal - account.creditsUsed`
- Calcul jours avant renouvellement : `subscription.expiresAt.difference(DateTime.now()).inDays`
- Calcul statut enfant : actif = `lastActiveAt` < 1j, hier = < 2j, inactif sinon
- Tendance : `avgScore > previousWeekScore` → ↗, sinon ↘

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/auth/me` | Prénom | `§4.1` |
| `GET /api/parent/account` | Crédits disponibles / total | `§4.9` |
| `GET /api/parent/children` | Liste enfants + scores + statut | `§4.10` |
| `GET /api/subscriptions/me` | Date renouvellement, plan | `§4.2` |
| `GET /api/parent/upcoming-events` | Examens, renouvellements | `§4.12` |
| `GET /api/winai/alerts?unread=true` | Alertes non lues (count + preview) | Créer `mockWinAIAlerts` |

```dart
static final List<WinAIAlert> mockWinAIAlerts = [
  WinAIAlert(childId: 'k-001', childName: 'Ahmed',
    message: 'N\'a pas révisé la Chimie depuis 5 jours',
    severity: AlertSeverity.warning, createdAt: DateTime.now().subtract(const Duration(hours: 3))),
  WinAIAlert(childId: 'k-002', childName: 'Brenda',
    message: 'Score en baisse de 12% cette semaine en Maths',
    severity: AlertSeverity.critical, createdAt: DateTime.now().subtract(const Duration(hours: 8))),
];
```

---

#### 📱 S3-2 — ChildActivityScreen (version enrichie avec tabs)

**Fichier :** `lib/parent/child_activity_screen.dart`  
**Navigation :** Shell Parent → Tab "Enfants" → Tap sur `ChildCard` → `ChildActivityScreen`  
OU : Shell Parent → Tab "Accueil" → Tap card enfant → `ChildActivityScreen`

**Contenu affiché :**

**AppBar :** "[Prénom de l'enfant]" + niveau (ex. "Ahmed · Tle C")

**3 tabs :**

**Tab 1 "Activité"**
- Score d'engagement : chiffre 0-100 en grand (ex. "73 / 100")
  - Sous-texte : "+8 pts cette semaine 📈" ou "-3 pts ↘"
  - Barre circulaire ou linéaire colorée (vert > 70, orange 40-70, rouge < 40)
- Graphique barres horizontales : sessions par jour cette semaine (Lu/Ma/Me/Je/Ve/Sa/Di)
- Timeline activité (5 événements) :
  - Quiz Maths — 13/15 · il y a 2h
  - Téléchargement Pack ENSP · hier
  - Exam Coach activé · il y a 2 jours
  - Quiz Chimie — 8/15 · il y a 3 jours
- [Voir ressources pour Ahmed →] → `ParentResourcesTab` filtré par niveau enfant
- [Générer un quiz Maths pour Ahmed →] → `QuizHubScreen`
- [💌 Envoyer un encouragement] → `EncouragementSheet(childId: id)`

**Tab 2 "Résultats"**
- Score moyen global (ex. "78%")
- Tableau score par matière :
  - Maths : 84% ↗ (barre verte)
  - Physique : 71% → (barre orange)
  - Chimie : 52% ↘ (barre rouge)
  - Français : 79% ↗
- Dernier quiz : "Quiz Maths — Suites · 13/15 · il y a 2h"
- Meilleure matière : "Mathématiques 🏆"
- Matière à travailler : "Chimie ⚠️"

**Tab 3 "Alertes WinAI"**
- Liste alertes pour cet enfant :
  - Icône sévérité (rouge/jaune)
  - Texte de l'alerte (ex. "N'a pas révisé la Chimie depuis 5 jours")
  - Date (ex. "il y a 3h")
- Si aucune alerte : "Tout va bien ! Ahmed est régulier dans ses révisions. ✅"

**Données locales (à implémenter maintenant) :**
- `TabController` avec 3 onglets
- Couleur du score d'engagement : `score >= 70 → vert, >= 40 → orange, < 40 → rouge`
- `_relativeTime(DateTime dt)` pour la timeline
- Tri matières : de la plus faible à la plus forte
- Barres de progression des matières : `(score / 100)` en `WinProgressBar`
- `scoreDelta > 0` → afficher "+X pts cette semaine 📈", sinon "-X pts ↘"

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/parent/child/{id}/activity` | Timeline activité | `§4.11` |
| `GET /api/parent/child/{id}/stats` | Scores par matière, score global | Créer `mockChildStats` |
| `GET /api/parent/child/{id}/engagement` | Score engagement + delta | `§4.11` |
| `GET /api/winai/alerts?childId={id}` | Alertes pour cet enfant | `mockWinAIAlerts` filtré |

```dart
static final Map<String, ChildStats> mockChildStats = {
  'k-001': ChildStats(avgScore: 78, subjectScores: {
    'math': 84, 'pc': 71, 'chimie': 52, 'fr': 79,
  }, lastQuizTitle: 'Quiz Maths — Suites', lastQuizScore: '13/15'),
  'k-002': ChildStats(avgScore: 62, subjectScores: {
    'math': 55, 'pc': 68, 'chimie': 60, 'fr': 65,
  }, lastQuizTitle: 'Quiz Chimie — Oxydoréduction', lastQuizScore: '9/15'),
};
```

---

#### 📱 S3-3 — RenewalSheet

**Fichier :** `lib/parent/renewal_sheet.dart`  
**Navigation :**  
- Shell Parent → Tab "Accueil" → Carte évènements → [Renouveler]  
- Shell Parent → Tab "Profil" → "Mon abonnement" → [Renouveler]

**Contenu affiché :**

- **Handle** de bottom sheet en haut
- Titre : "Renouveler mon abonnement"
- Plan actuel : "Plan Famille · 12 000 XAF/mois"
- Toggle [Mensuel | Annuel]
  - Mensuel : "12 000 XAF / mois"
  - Annuel : "10 200 XAF / mois · -15% · Payé en une fois (122 400 XAF)"
- Section mode de paiement :
  - Radio [MTN Mobile Money] avec icône MTN jaune
  - Radio [Orange Money] avec icône Orange orange
- Champ numéro Mobile Money (si MTN ou Orange sélectionné) :
  - Placeholder "6XX XXX XXX"
  - Validation : commence par 6, 9 chiffres
- Résumé : "Total : 12 000 XAF" ou "122 400 XAF/an"
- Bouton [Confirmer le renouvellement] (accent, full width)
  - En chargement → spinner
  - Succès → SnackBar "Renouvellement confirmé !" + fermeture sheet
  - Erreur → `WinAlert` rouge inline

**Données locales (à implémenter maintenant) :**
- `bool _yearly = false` — toggle mensuel/annuel
- `PaymentMethod _method = PaymentMethod.mtn` — radio sélectionné
- `TextEditingController _phoneCtrl` — numéro Mobile Money
- Calcul prix annuel : `monthlyPrice * 12 * 0.85`
- Validation téléphone : `RegExp(r'^6[0-9]{8}$').hasMatch(phone)`
- `bool _loading = false` — état du bouton

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `POST /api/subscriptions/{id}/renew` | Confirmation renouvellement | Retourner `{'success': true}` après 1.5s délai |

---

#### 📱 S3-4 — EncouragementSheet

**Fichier :** `lib/parent/encouragement_sheet.dart`  
**Navigation :** `ChildActivityScreen` → Tab "Activité" → [💌 Envoyer un encouragement]

**Contenu affiché :**

- Handle bottom sheet
- Titre : "Encourager [Prénom de l'enfant]"
- Sous-titre : "Choisissez un message ou écrivez le vôtre"
- Liste de 4 templates prédéfinis (tap pour sélectionner) :
  - 💪 "Continue comme ça [Prénom], je suis fier(e) de toi !"
  - 📚 "N'oublie pas de réviser la Chimie ce soir !"
  - 🎯 "Plus que X jours avant le BAC, tu peux le faire !"
  - ⭐ "Ton score de X% cette semaine est excellent !"
- Champ texte "Ou écrivez votre propre message..." (multiline, max 200 caractères)
  - Compteur de caractères en bas à droite
- Bouton [Envoyer 💌] (accent, full width)
  - Succès → SnackBar "Message envoyé à [Prénom] !" + fermeture

**Données locales (à implémenter maintenant) :**
- `String? _selectedTemplate` — template sélectionné
- `TextEditingController _customCtrl` — message personnalisé
- `String get _finalMessage` → `_customCtrl.text.isNotEmpty ? _customCtrl.text : _selectedTemplate ?? ''`
- Templates avec interpolation : remplacer `[Prénom]` par le prénom de l'enfant, `X jours` par le compte à rebours réel, `X%` par le score de l'enfant
- Validation : message non vide avant envoi

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `POST /api/messaging/send` | Envoyer message à l'enfant | Retourner `{'sent': true}` après 800ms |

---

#### 📱 S3-5 — BuyForChildScreen

**Fichier :** `lib/parent/buy_for_child_screen.dart`  
**Navigation :** Shell Parent → Tab "Accueil" → [🛒 Acheter du contenu pour un enfant]

**Contenu affiché :**

- AppBar : "Acheter pour..."
- Section "Pour quel enfant ?" :
  - Chips horizontaux scrollables avec prénom + niveau de chaque enfant
  - Ahmed (Tle C) · Brenda (2nde) · Kevin (BEPC)
  - Chip sélectionné en accent, non sélectionné en outline
- Section "Contenu recommandé pour [Prénom] — [Niveau]" :
  - Grid 2 colonnes de `ContentCard` filtrées par niveau de l'enfant sélectionné
  - (ex. si Ahmed est en Tle C → afficher contenus Tle C en priorité)
- En bas de chaque `ContentCard` : bouton [Acheter pour Ahmed] au lieu de [Acheter]
- Tap → `GuestOrderScreen(content: content, forChildId: selectedChildId, prefilledEmail: parentEmail)`

**Données locales (à implémenter maintenant) :**
- `String? _selectedChildId` — enfant sélectionné (null = tous)
- Filtrer les contenus par `content.level == selectedChild.level` si enfant sélectionné
- Récupérer email parent depuis `SessionManager` pour pré-remplir `GuestOrderScreen`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/parent/children` | Liste enfants + niveaux | `§4.10` |
| `GET /api/subjects?level={level}` | Contenus filtrés par niveau | `§4.3` (SubjectService déjà connecté) |

---

### SPRINT 4 — Professeur Expert complet

---

#### 📱 S4-1 — ContentPublishScreen (avec upload fichier)

**Fichier :** `lib/teacher/content_publish_screen.dart`  
**Navigation :** Shell Professeur → Tab "Contenus" → [+ Publier un contenu]  
OU : Shell Professeur → Tab "Dashboard" → bouton [+ Publier] dans le hero

**Contenu affiché :**

- AppBar : "Publier un contenu"
- Champ **Titre** (texte, obligatoire, max 100 chars)
- Sélecteur **Type** (dropdown ou chips) : Épreuve · Correction · Quiz · Livre · Pack · Fiche
- Sélecteur **Matière** (dropdown) : Maths · Physique · Chimie · Français · SVT · Anglais · Histoire-Géo
- Sélecteur **Niveau** (chips) : BEPC · Probatoire · BAC A · BAC C · BAC D · Concours
- Sélecteur **Examen** (dropdown) : BAC · BEPC · ENSP · Polytechnique · ESSEC · FMSB · ENAM · ENS
- Champ **Année** (numérique, ex. 2023)
- Champ **Description** (multiline, max 500 chars)
- Sélecteur **Prix** :
  - Radio [Abonnement uniquement] — gratuit pour les abonnés
  - Radio [Prix libre] → champ montant en XAF
- Zone **Upload fichier** :
  - Bouton [📎 Choisir un fichier] → `FilePicker.platform.pickFiles()`
  - Formats acceptés : PDF, EPUB, ZIP
  - Affiche après sélection : nom du fichier + taille (ex. "BAC_Maths_2023.pdf · 2.3 Mo")
  - Bouton [✕] pour retirer le fichier
- Bouton [Publier pour révision] (accent, full width, loading)
- Note : "Votre contenu sera examiné avant d'être publié (24-48h)"

**Données locales (à implémenter maintenant) :**
- `PlatformFile? _pickedFile` — fichier sélectionné
- `String _formatFileSize(int bytes)` → ex. "2.3 Mo"
- Validation avant envoi : titre non vide + fichier sélectionné + matière + niveau
- `bool _loading = false`
- Succès → SnackBar "Contenu soumis pour révision !" + pop de l'écran

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `POST /api/teacher/content` | Soumettre le formulaire + fichier | Retourner `{'id': 'new-id', 'status': 'review'}` après 1.5s |

**Dépendance à ajouter dans `pubspec.yaml` :**
```yaml
file_picker: ^8.0.0
```

---

#### 📱 S4-2 — ContentActionsSheet

**Fichier :** `lib/teacher/content_actions_sheet.dart`  
**Navigation :** Shell Professeur → Tab "Contenus" → Bouton `⋯` ou long-press sur un contenu → bottom sheet

**Contenu affiché :**

- Handle bottom sheet
- En-tête : titre du contenu (tronqué si nécessaire) + badge statut (Publié / Brouillon / En révision)
- **Mini-stats inline** (3 cartes horizontales) :
  - ⬇ N téléchargements
  - ⭐ Note X.X/5 (Nk avis)
  - 💰 Revenus : X XAF
- Séparateur
- Actions (boutons liste) :
  - [📊 Statistiques détaillées] → navigate vers stats page ou expand inline
  - [✏️ Modifier les infos] → form pré-rempli (même UI que ContentPublishScreen mais en édition)
  - [🔄 Changer le statut] → 3 chips [Publié · Brouillon · Archivé] inline, tap → confirme
  - [🗑️ Supprimer] → dialog "Supprimer [titre] ? Cette action est irréversible." → [Annuler] [Supprimer]

**Données locales (à implémenter maintenant) :**
- Recevoir `TeacherContent content` en paramètre
- `_changeStatus(String newStatus)` → appel API mock + rafraîchir la liste parente
- Fermeture du sheet après chaque action

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `PATCH /api/teacher/content/{id}` | Modifier infos ou statut | Retourner contenu modifié |
| `DELETE /api/teacher/content/{id}` | Supprimer | Retourner `204 No Content` |

---

#### 📱 S4-3 — TeacherDashTab (version enrichie)

**Fichier :** `lib/teacher/teacher_tabs.dart` — `TeacherDashTab`  
**Navigation :** Shell Professeur → Tab 1 "Dashboard" (tab par défaut)

**Contenu affiché (de haut en bas) :**

1. **Hero** (card pleine largeur)
   - "Bonjour [Prénom] 👋"
   - "Plan Expert · 80% de vos revenus"
   - 2 boutons côte à côte : [+ Publier] → `ContentPublishScreen` · [Corrections (N)] → `CorrectionQueueScreen`

2. **Statistiques** (calculées depuis les données chargées, PAS hardcodées)
   - Ligne 1 : Contenus publiés · Total téléchargements
   - Ligne 2 : Note moyenne (⭐ X.X) · Étudiants actifs
   - Calculées via `Future.wait([TeacherService.getContent(), TeacherService.getStats()])`

3. **Revenus du mois**
   - Montant en grand : "X XAF ce mois"
   - Mini graphique barres 4 dernières semaines

4. **Insights WinAI** (section "Vos insights")
   - 3 cards (depuis `§4.15`) :
     - 🔥 "Pack ENSP 2019-2023 — meilleur vendeur ce mois"
     - 💡 "Terminale C représente 68% de votre audience"
     - 📈 "+12% de téléchargements cette semaine"

5. **Contenus récents** (3 derniers publiés)
   - Row : titre · téléchargements · note · [⋯]

**Données locales (à implémenter maintenant) :**
- `Future.wait([TeacherService.instance.getContent(), TeacherService.instance.getStats()])` dans `initState`
- Calcul depuis la liste de contenus : `totalDownloads = content.fold(0, (a, c) => a + c.downloads)`
- `avgRating = content.fold(0.0, (a, c) => a + c.rating) / content.length`
- Remplacer les 4 valeurs hardcodées "907k", "4,8", "412", "18" par les valeurs calculées

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/teacher/content` | Liste contenus avec stats | `§4.13` ✅ connecté |
| `GET /api/teacher/stats` | Stats globales + revenus mois | `§4.14` |
| `GET /api/teacher/insights` | Insights IA | `§4.15` |

---

#### 📱 S4-4 — TeacherStudentsTab (version enrichie)

**Fichier :** `lib/teacher/teacher_tabs.dart` — `TeacherStudentsTab`  
**Navigation :** Shell Professeur → Tab 3 "Étudiants"

**Contenu affiché :**

1. **Mes classes** (section collapsible)
   - Cards horizontales scrollables :
     - Nom de la classe (ex. "Tle C · Groupe A")
     - Nombre d'élèves (ex. "28 élèves")
     - Score moyen de la classe (ex. "74%")
     - [Voir les élèves →]
   - [+ Créer une classe] → `CreateClassSheet`

2. **Tous mes étudiants** (section avec recherche)
   - Barre de recherche en haut
   - Liste avec filtre chips : [Tous · Actifs · En difficulté]
   - Pour chaque étudiant :
     - Avatar (initiales)
     - Nom complet · Niveau
     - Score moyen · Tendance ↗ ou ↘
     - [💬] → `MessagingScreen` avec cet étudiant pré-sélectionné

**Données locales (à implémenter maintenant) :**
- `String _search = ''` — filtre texte
- `String _statusFilter = 'Tous'` — chips filtre
- `List<TeacherStudent> get _filtered` → applique search + status filter
- En difficulté : `student.avgScore < 50`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/teacher/students` | Liste étudiants avec scores | `§4` — créer `mockTeacherStudents` |
| `GET /api/teacher/classes` | Classes gérées | Créer `mockTeacherClasses` |

```dart
static final List<TeacherClass> mockTeacherClasses = [
  TeacherClass(id: 'c-001', name: 'Tle C · Groupe A',
    studentCount: 28, avgScore: 74),
  TeacherClass(id: 'c-002', name: 'Tle C · Groupe B',
    studentCount: 31, avgScore: 68),
  TeacherClass(id: 'c-003', name: '1ère D',
    studentCount: 24, avgScore: 71),
];

static final List<TeacherStudent> mockTeacherStudents = [
  TeacherStudent(id: 's-001', name: 'Ahmed Nkono', level: 'Tle C',
    avgScore: 78, trend: Trend.up),
  TeacherStudent(id: 's-002', name: 'Brenda Mballa', level: 'Tle C',
    avgScore: 86, trend: Trend.up),
  TeacherStudent(id: 's-003', name: 'Yann Talla', level: 'Tle C',
    avgScore: 44, trend: Trend.down),
  // ... 15+ étudiants pour tester les filtres
];
```

---

### SPRINT 5 — Institution Enterprise complet

---

#### 📱 S5-1 — InstitutionDashTab (version enrichie)

**Fichier :** `lib/institution/institution_tabs.dart` — `InstitutionDashTab`  
**Navigation :** Shell Institution → Tab 1 "Accueil" (tab par défaut)

**Contenu affiché (de haut en bas) :**

1. **Header**
   - Nom de l'institution (ex. "Lycée Bilingue de Yaoundé")
   - Plan : "Plan Enterprise"
   - Cloche 🔔 avec badge

2. **KPIs** (grille 2×2)
   - 👥 Élèves actifs : "642 / 2 450" (avec % : "26%")
   - 📈 Taux de réussite : "74%"
   - 🧠 Quiz cette semaine : "1 847"
   - 🔑 Licences : "1 823 / 2 450 (74%)"

3. **Matières les plus étudiées** (top 4)
   - 🥇 Mathématiques · 1 240 sessions
   - 🥈 Physique-Chimie · 890 sessions
   - 🥉 Français · 654 sessions
   - 4. SVT · 420 sessions

4. **Alerte élèves à risque**
   - Card rouge si `atRiskCount > 0` : "⚠️ 3 élèves nécessitent une attention urgente"
   - [Voir les élèves à risque →] → `AtRiskScreen`

5. **Action rapide**
   - [📋 Plan d'action IA →] → `ActionPlanScreen`

**Données locales (à implémenter maintenant) :**
- Charger `mockInstitutionStats` et `mockSubjectStats` au lieu des valeurs en dur
- `_pctLicenses = (stats.licensesUsed / stats.licensesTotal * 100).round()`
- `_pctActive = (stats.activeStudentsToday / stats.licensesTotal * 100).round()`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/institution/stats` | KPIs globaux | `§4.16` |
| `GET /api/institution/subject-stats` | Matières les plus étudiées | `§4.17` |
| `GET /api/institution/at-risk?summary=true` | Count élèves à risque | `count: 3` |

---

#### 📱 S5-2 — StudentDirectoryScreen

**Fichier :** `lib/institution/student_directory_screen.dart`  
**Navigation :** Shell Institution → Tab "Étudiants" → (c'est le tab lui-même, ou bouton dans le tab Groupes)

**Contenu affiché :**

- AppBar : "Annuaire des élèves" + bouton [📥 Importer CSV]
- Barre de recherche : "Rechercher par nom..."
- Chips filtres : [Tous · Tle C · 1ère · 2nde · BEPC] (niveaux présents)
- Chips statut : [Tous · Actifs · Inactifs]
- Liste étudiants :
  - Avatar (initiales)
  - Nom complet
  - Niveau (ex. "Tle C")
  - Groupe (ex. "Classe A")
  - Score moyen (ex. "78%") avec barre courte
  - Statut : 🟢 Actif / 🔴 Inactif
  - [💬 Contacter] → `MessagingScreen`
- En bas : "Affichage 25 sur 1 823 élèves"
- Pagination ou "Charger plus..."

**Tap [📥 Importer CSV] :**
- Dialog : "Import CSV — Choisissez un fichier CSV avec les colonnes : nom, email, niveau, groupe"
- Bouton [Choisir un fichier] → `FilePicker`
- Bouton [Annuler]
- Succès simulé : "Import en cours... 1 823 élèves importés avec succès !"

**Données locales (à implémenter maintenant) :**
- `String _search = ''`
- `String _levelFilter = 'Tous'`
- `String _statusFilter = 'Tous'`
- `List<MockStudent> get _filtered` → applique les 3 filtres simultanément
- Pagination locale : afficher 25 items, bouton "Charger 25 de plus" incrémente le compteur

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/institution/students` | Liste paginée étudiants | `§4.18` |
| `POST /api/institution/students/import` | Import CSV | Retourner `{'imported': 1823}` après 2s |

---

#### 📱 S5-3 — ReportsScreen

**Fichier :** `lib/institution/reports_screen.dart`  
**Navigation :** Shell Institution → Tab "Profil" (InstitutionAccountTab) → [📊 Exporter un rapport]  
OU : `InstitutionDashTab` → bouton dédié

**Contenu affiché :**

- AppBar : "Rapports"
- **Sélecteur de période** : [7 jours · 30 jours · Trimestre · Année]
- **Types de rapports disponibles** (cards avec icône) :
  - 📊 Rapport de performance global  
    Sous-titre : "Vue d'ensemble de tous les élèves, toutes matières"
  - 🏫 Rapport par classe  
    Sous-titre : "Comparaison des classes, taux de réussite"
  - 👤 Rapport individuel élève  
    Sous-titre : "Progression détaillée d'un élève spécifique"
  - 📉 Rapport élèves à risque  
    Sous-titre : "Élèves nécessitant une intervention"
- Pour chaque card : bouton [Générer PDF]

**Tap [Générer PDF] :**
- Dialog de génération :
  - Spinner + "Génération du rapport en cours..."
  - Après 2.5s : "✅ Rapport généré ! Partagez-le ou enregistrez-le."
  - Bouton [Partager] → `Share.shareFiles(...)` (simulé)
  - Bouton [Fermer]

**Données locales (à implémenter maintenant) :**
- `String _period = '30 jours'` — toggle sélecteur
- Simulation génération : `Future.delayed(const Duration(seconds: 2))`
- Pas de vrai PDF à générer — uniquement la simulation UX

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `POST /api/institution/reports` | Demande génération rapport | Retourner `{'url': 'mock-report.pdf'}` après 2.5s |

---

### SPRINT 6 — AUTH manquants

---

#### 📱 S6-1 — EmailVerifiedScreen

**Fichier :** `lib/auth/email_verified_screen.dart`  
**Navigation :** Deep link depuis email de vérification → app ouvre cet écran  
OU : `VerifyCodeScreen` après saisie du bon code → redirect ici

**Contenu affiché :**
- Animation confetti ou icône ✅ animée (Lottie ou simple AnimatedContainer)
- Titre : "Email vérifié ! 🎉"
- Sous-titre : "Votre compte WinPlus est maintenant actif."
- Bouton [Continuer] → `CompleteProfileScreen` si profil incomplet, sinon `RoleShell`

**Données locales (à implémenter maintenant) :**
- Check `SessionManager.getUserRole()` pour savoir où rediriger après [Continuer]
- Animation : `AnimatedContainer` avec scale 0→1 sur `initState` (pas de dépendance externe)

**Appels API (mockés) :** aucun

---

#### 📱 S6-2 — PeriodicConfirmScreen

**Fichier :** `lib/auth/periodic_confirm_screen.dart`  
**Navigation :** Affiché automatiquement au lancement de l'app si `SessionManager.needsReconfirmation()` retourne true (toutes les 30-45 jours)

**Contenu affiché :**
- AppBar sans bouton retour (obligatoire)
- Icône shield 🛡️
- Titre : "Vérifiez que c'est bien vous"
- Sous-titre : "Pour votre sécurité, confirmez votre identité (toutes les 30 jours)"
- Email masqué affiché : "m***@example.com"
- Bouton [Envoyer le code] → déclenche envoi email
- Message "Code envoyé à votre email" (après tap)
- Champ saisie code 6 chiffres (identique à `VerifyCodeScreen`)
- Bouton [Confirmer]
- Lien "Me déconnecter" (option de secours)

**Données locales (à implémenter maintenant) :**
- `SessionManager.needsReconfirmation()` → compare `lastConfirmedAt` avec `DateTime.now()`, vrai si > 35 jours
- `SessionManager.setLastConfirmed()` → enregistre la date après confirmation réussie
- Logique affichage dans `SplashScreen` : si `needsReconfirmation()` → navigate vers `PeriodicConfirmScreen`
- `TextEditingController _codeCtrl`
- `bool _codeSent = false`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `POST /api/auth/send-confirm-code` | Envoi code | Retourner `{'sent': true}` |
| `POST /api/auth/confirm-identity` | Validation code | Code "123456" → succès |

---

#### 📱 S6-3 — OnboardingSuccessScreen

**Fichier :** `lib/auth/onboarding_success_screen.dart`  
**Navigation :** `CompleteProfileScreen` → après enregistrement réussi du profil → cet écran

**Contenu affiché :**
- Animation confetti ou icône 🎓 animé
- Titre : "Bienvenue sur WinPlus, [Prénom] !"
- Sous-titre selon le rôle :
  - Étudiant : "Votre profil est prêt. Commencez à réviser !"
  - Parent : "Vous pouvez maintenant suivre vos enfants."
  - Professeur : "Publiez votre premier contenu !"
  - Institution : "Gérez votre établissement depuis votre tableau de bord."
- 3 features clés illustrées (icône + texte court) selon le rôle
- Bouton [Commencer] → `RoleShell`

**Données locales (à implémenter maintenant) :**
- Lire le rôle depuis `SessionManager.getUserRole()` pour adapter le contenu
- Animation identique à `EmailVerifiedScreen`

**Appels API (mockés) :** aucun

---

### SPRINT 7 — Enrichissement Étudiant

---

#### 📱 S7-1 — Notes & Tags dans ContentDetailScreen

**Fichier :** `lib/student/content_detail_screen.dart` (enrichir la section existante)  
**Navigation :** Shell Étudiant → Tab "Catalogue" → Tap sur un contenu → `ContentDetailScreen`

**Contenu à ajouter** (section en bas de la fiche, avant les boutons d'action) :

- Titre de section : "Mes notes de révision"
- **Tags rapides** (chips sélectionnables) :
  - [À réviser] · [Difficile] · [Maîtrisé] · [À acheter]
  - Tap sur un tag : toggle sélectionné/non sélectionné (accent/outline)
- **Mes notes** :
  - Si notes existantes : liste chips "Note 1 · Note 2 · ..."
  - [+ Ajouter une note] → inline text field apparaît (single line, max 150 chars)
  - Bouton [Enregistrer] à droite du champ ou action "Done" du clavier
  - Note enregistrée → ajoutée à la liste sans reload

**Données locales (à implémenter maintenant) :**
- `Set<String> _selectedTags = {}` — tags actifs pour ce contenu
- `List<String> _notes = []` — notes ajoutées
- `bool _addingNote = false` — affiche/cache le champ
- `TextEditingController _noteCtrl`
- Persistance locale via `shared_preferences` : clé `'notes_${content.id}'` (JSON list)
- Persistance tags via `shared_preferences` : clé `'tags_${content.id}'` (JSON set)
- Chargement dans `initState` depuis `shared_preferences`

**Appels API (mockés) :** aucun — 100% local via `shared_preferences`

---

#### 📱 S7-2 — StudyGroupsScreen

**Fichier :** `lib/student/study_groups_screen.dart`  
**Navigation :** Shell Étudiant → Tab "Moi" (ProfileHubTab) → "Mes groupes d'étude"

**Contenu affiché :**

- AppBar : "Mes groupes d'étude"
- **Mes groupes** (liste cards) :
  - Nom du groupe (ex. "BAC C Warriors")
  - Matière principale (ex. "Mathématiques")
  - Nombre de membres (ex. "5 membres")
  - Dernière activité (ex. "Message il y a 2h")
  - [Voir →] → `StudyGroupDetailScreen` (futur)
- **[+ Créer un groupe]** → bottom sheet :
  - Champ Nom du groupe
  - Dropdown Matière principale
  - Textarea Description (optionnel)
  - Bouton [Créer]
- **[Rejoindre par code]** → bottom sheet :
  - Champ code 6 caractères (ex. "ABC123")
  - Bouton [Rejoindre]
- Note badge plan : "Plan Ultime — Groupes illimités 🏆"

**Données locales (à implémenter maintenant) :**
- `bool _showCreateSheet = false`, `bool _showJoinSheet = false`
- Validation nom groupe : min 3 chars, max 50 chars
- Code de groupe généré localement : `_generateCode()` → 6 chars alphanumériques
- Création mock : ajoute le groupe à la liste locale sans reload

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/study-groups/me` | Mes groupes | Créer `mockStudyGroups` |
| `POST /api/study-groups` | Créer un groupe | Retourner groupe créé |
| `POST /api/study-groups/join` | Rejoindre par code | Code "ABC123" → succès |

```dart
static final List<StudyGroup> mockStudyGroups = [
  StudyGroup(id: 'g-001', name: 'BAC C Warriors', subject: 'Mathématiques',
    memberCount: 5, lastActivityAt: DateTime.now().subtract(const Duration(hours: 2))),
  StudyGroup(id: 'g-002', name: 'Chimie Élite', subject: 'Chimie',
    memberCount: 3, lastActivityAt: DateTime.now().subtract(const Duration(days: 1))),
  StudyGroup(id: 'g-003', name: 'Physique Squad', subject: 'Physique',
    memberCount: 8, lastActivityAt: DateTime.now().subtract(const Duration(hours: 5))),
];
```

---

#### 📱 S7-3 — StudentReportsScreen

**Fichier :** `lib/student/student_reports_screen.dart`  
**Navigation :** Shell Étudiant → Tab "Moi" (ProfileHubTab) → "Mes rapports de progression"

**Contenu affiché :**

- AppBar : "Mes rapports"
- **Sélecteur de période** (chips) : [7 jours · 30 jours · 90 jours · 1 an]
  - 30j et plus → afficher badge "Plan Standard requis" (pour Phase 2)
- **Score moyen global** : chiffre en grand (ex. "78%") + label "Score moyen"
- **Score par matière** (barres horizontales) :
  - Maths : 84% (barre verte)
  - Physique : 71% (barre orange)
  - Chimie : 52% (barre rouge)
  - Français : 79% (barre verte)
  - Tri : de la plus forte à la plus faible
- **Progression hebdomadaire** (graphique barres simples, 7 semaines) :
  - Semaine 1 : 65% · S2 : 70% · S3 : 72% · ... · S7 (actuelle) : 78%
  - Implémentation : `CustomPaint` ou barres `Container` simples
- **Quiz** :
  - Quiz réalisés : N total
  - Taux de réussite : X%
  - Meilleure matière : Maths 🏆
  - À améliorer : Chimie ⚠️
- Bouton [📥 Exporter PDF] (visible, action "bientôt disponible" pour Plan Standard+)

**Données locales (à implémenter maintenant) :**
- `String _period = '7 jours'` — sélecteur
- Calcul score moyen : moyenne des scores par matière
- Graphique progression : 7 `Container` dont la hauteur est proportionnelle au score
- Tri des matières : `entries.sorted((a, b) => b.value.compareTo(a.value))`

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/student/reports?period=7d` | Scores + progression + quiz stats | Créer `mockStudentReport` |

```dart
static final StudentReport mockStudentReport = StudentReport(
  avgScore: 78,
  subjectScores: {'math': 84, 'pc': 71, 'chimie': 52, 'fr': 79, 'svt': 66},
  weeklyScores: [65, 70, 72, 69, 74, 76, 78], // 7 semaines
  quizTotal: 47,
  quizSuccessRate: 74,
  bestSubject: 'math',
  weakestSubject: 'chimie',
);
```

---

#### 📱 S7-4 — QuizRevisionScreen

**Fichier :** `lib/student/quiz_revision_screen.dart`  
**Navigation :** Shell Étudiant → Tab "Quiz" → Bouton [🔁 Révision] en haut du `QuizHubScreen`

**Contenu affiché :**

- AppBar : "Quiz de révision"
- Sous-titre : "Questions que tu as ratées récemment"
- **Filtre matière** (chips) : [Toutes · Maths · Chimie · Physique · Français]
- **Liste des questions à réviser** :
  - Pour chaque question :
    - Badge matière coloré
    - Texte de la question (tronqué à 2 lignes)
    - Réponse donnée ❌ (rouge) + Bonne réponse ✅ (verte)
    - "Il y a N jours"
- En bas : Bouton [🚀 Lancer la révision] → `QuizActiveScreen` avec les questions filtrées
- Si aucune question : "Aucune question à réviser ! Tu maîtrises tout. 🎉"

**Données locales (à implémenter maintenant) :**
- `String _subjectFilter = 'Toutes'`
- Questions ratées stockées via `shared_preferences` : `'quiz_mistakes'` (JSON list)
- Après chaque quiz raté : `QuizResultScreen` appelle `QuizMistakeStorage.save(question)`
- `List<QuizMistake> get _filtered` → applique le filtre matière
- Si 0 questions filtrées → message vide

**Appels API (mockés) :**
| Endpoint | Données | Mock |
|---|---|---|
| `GET /api/quiz/mistakes` | Questions ratées récentes | Créer `mockQuizMistakes` — en attendant, utiliser `shared_preferences` local |

```dart
static final List<QuizMistake> mockQuizMistakes = [
  QuizMistake(id: 'qm-001', subject: 'chimie',
    question: 'Quelle est la formule de l\'acide sulfurique ?',
    givenAnswer: 'HCl', correctAnswer: 'H₂SO₄',
    mistakeAt: DateTime.now().subtract(const Duration(hours: 3))),
  QuizMistake(id: 'qm-002', subject: 'math',
    question: 'Calculer la limite de sin(x)/x quand x→0',
    givenAnswer: '0', correctAnswer: '1',
    mistakeAt: DateTime.now().subtract(const Duration(days: 1))),
  QuizMistake(id: 'qm-003', subject: 'pc',
    question: 'Unité du champ électrique ?',
    givenAnswer: 'Tesla', correctAnswer: 'V/m',
    mistakeAt: DateTime.now().subtract(const Duration(days: 2))),
];
```

---

### Écrans existants — Référence rapide

| Écran | Navigation | API connectée |
|---|---|---|
| `SplashScreen` | Point d'entrée app | `SessionManager` (local) |
| `WelcomeScreen` | Depuis Splash si non connecté | Aucune |
| `LoginScreen` | Welcome → "Se connecter" | `POST /api/auth/login` ✅ |
| `RoleScreen` | Signup → sélection rôle | Local |
| `CompleteProfileScreen` | Post-signup | `POST /api/users/profile` ✅ |
| `ProfileHubTab` | Shell Étudiant → Tab "Moi" | `GET /api/notifications` ✅ |
| `ProfileScreen` | Hub → "Paramètres" | `GET+PATCH /api/users/profile` ✅ |
| `NotificationsScreen` | Hub → 🔔 · AppBar cloche | `GET /api/notifications` ✅ |
| `AchievementsScreen` | Hub → "Mes badges" | `GET /api/achievements` mocké |
| `CertificatesScreen` | Hub → "Mes certificats" | `GET /api/certificates` mocké |
| `FavoritesScreen` | Hub → "Mes favoris" | `GET /api/favorites` mocké |
| `DownloadHistoryScreen` | Hub → "Téléchargements" | `GET /api/history` mocké |
| `StudentCatalogTab` | Shell → Tab "Catalogue" | `GET /api/subjects` ✅ |
| `ContentDetailScreen` | Catalogue → Tap card | `GET /api/subjects/{id}` ✅ |
| `SearchScreen` | Catalogue → Barre de recherche | `GET /api/subjects?q=...` ✅ |
| `QuizHubScreen` | Shell → Tab "Quiz" | `GET /api/quiz` mocké |
| `QuizActiveScreen` | QuizHub → Tap quiz | Local (questions reçues en param) |
| `QuizResultScreen` | QuizActive → Fin | Local |
| `ExamCoachScreen` | QuizHub ou Espace | Local + `GET /api/exams` mocké |
| `MessagingScreen` | Hub Parent / Teacher → Chat | `GET /api/messaging/conversations` ✅ |
| `ConversationScreen` | MessagingScreen → Tap conversation | `GET+POST /api/messaging/{id}` ✅ |
| `PricingScreen` | Hub → "Mon abonnement" | `GET /api/pricing/plans` ✅ |
| `GuestOrderScreen` | ContentDetail → [Acheter] | `POST /api/orders/guest` ✅ |
| `AtRiskScreen` | Institution Dashboard → Carte risque | `GET /api/institution/at-risk` mocké |
| `ActionPlanScreen` | AtRisk → [Plan d'action] | `GET /api/institution/action-plan` mocké |
