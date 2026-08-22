# WinPlus — Fonctionnalités web absentes du mobile

Comparaison exhaustive entre l'application web et l'application Flutter mobile.
Chaque fonctionnalité présente dans le web est notée selon sa priorité d'intégration mobile.

**Légende priorités :** 🔴 Haute (v1) · 🟡 Moyenne (v1.5) · 🟢 Plus tard (v2) · ⚫ Non (web only)

---

## AUTH & ONBOARDING

| Fonctionnalité | Fichier web | Mobile actuel | Priorité | Note |
|---|---|---|---|---|
| Forgot password (flux email) | `src/pages/ForgotPassword.tsx` | ❌ Lien affiché, aucun écran | 🔴 | Flux critique, deep link email → écran reset |
| Reset password (token URL) | `src/pages/ResetPassword.tsx` | ❌ | 🔴 | Deep link depuis email → écran nouveau mdp |
| Email verification (code 6 chiffres) | `src/pages/VerifyCode.tsx` | ❌ Backend prêt | 🔴 | Backend `/verify-email` déjà en place |
| Confirmation périodique (code email) | Backend custom | ❌ Backend créé | 🔴 | Décision prise dans `MOBILE_BACKEND_PLAN.md`, WhatsApp-like toutes les 30-45 jours |
| Complete Profile onboarding (niveau → filière → objectif exam) | `src/pages/CompleteProfile.tsx` | ❌ | 🔴 | Obligatoire avant le dashboard pour personnaliser le contenu IA |
| Email verified confirmation | `src/pages/EmailVerified.tsx` | ❌ | 🔴 | Simple écran de succès post-vérification |
| Google OAuth | `src/pages/Login.tsx` | ❌ Bouton présent, non fonctionnel | 🟢 | Nécessite `google_sign_in` Flutter, pas urgent v1 |

---

## PAGES PUBLIQUES (web uniquement)

| Fonctionnalité | Priorité | Note |
|---|---|---|
| Landing page, About, Contact, FAQ, Help | ⚫ | Pages marketing — le web est la vitrine, l'app démarre sur Welcome screen |
| Pricing page | 🟡 | Afficher les plans dans le profil ou au moment de l'achat, pas de page dédiée |
| Privacy, Terms, Cookies | 🟡 | Pas d'écran dédié mais des **liens** depuis le profil — obligatoire légalement |

---

## ÉTUDIANT

| Fonctionnalité | Fichier web | Mobile actuel | Priorité | Note |
|---|---|---|---|---|
| Stats dashboard enrichies (score moyen, streak, objectif, heures hebdo, badges) | `StudentStats.tsx` | ❌ 3 cartes basiques | 🟡 | Dashboard actuel trop pauvre |
| Continue Learning (reprendre où l'étudiant s'est arrêté) | `StudentContinue.tsx` | ❌ | 🔴 | Feature UX clé pour la rétention |
| Recommandations IA concrètes (matières faibles, quiz suggérés) | `StudentRecommendations.tsx` | ❌ WinAI chat seulement | 🔴 | Relier WinAI aux recommandations sur le home |
| Activité récente (timeline : quiz, téléchargements, sessions) | `StudentActivity.tsx` | ❌ | 🟡 | Permet à l'étudiant de voir son historique d'apprentissage |
| Achievements / Badges débloqués | `StudentAchievements.tsx` | ❌ | 🟡 | Gamification — excellent pour l'engagement mobile |
| Compte à rebours examens à venir | `StudentUpcomingExams.tsx` | ❌ | 🟡 | Très pertinent mobile, contexte immédiat |
| Comparaison avec les pairs (percentile anonymisé) | `PeerComparison.tsx` | ❌ | 🟢 | Nécessite données réelles en volume |
| Prédiction de note IA | `GradePrediction.tsx` | ❌ | 🟢 | Feature premium, dépend des données d'usage |
| **Catalogue avancé** (filtres exam / matière / année / difficulté / tri) | `CatalogPage.tsx` | ❌ 6 chips basiques | 🔴 | Le catalogue est la fonctionnalité principale de l'app |
| **Fiche détail contenu** (description, avis, Q&A, contenu associé, prix) | `SubjectDetailsPage.tsx` | ❌ Cards sans page détail | 🔴 | Sans fiche détail l'utilisateur ne peut pas décider d'acheter |
| Recherche globale avec page résultats filtrés | `SearchPage.tsx` | ❌ Champ sans page résultats | 🔴 | Au minimum une page résultats basique |
| Favoris + Collections personnalisées | `Favorites.tsx` | ❌ | 🟡 | Favoris : simple et très attendu. Collections : v2 |
| Historique téléchargements (re-téléchargement rapide) | `History.tsx` | ❌ | 🟡 | Accès aux fichiers déjà achetés |
| **Quiz Engine complet** (timer, navigation Q, résultats, revue des réponses) | `QuizHub.tsx` + `QuizActive` + `QuizResult` + `QuizReview` | ❌ WinAI chat uniquement | 🔴 | Feature cœur — le mobile n'a aucun vrai moteur de quiz |
| Quiz adaptatif / liste de révision des fautes | `RevisionList.tsx` | ❌ | 🟡 | À intégrer juste après le quiz engine de base |
| Learning Style Quiz (VARK 12 questions) | `LearningStyleQuiz.tsx` | ❌ | 🟢 | Utile pour personnalisation mais pas urgent v1 |
| **Exam Coach / Plan de révision IA** (exam, date, heures/j → planning semaine/semaine) | `ExamCoach.tsx` | ❌ | 🔴 | Feature différenciante, à faire après le quiz engine |
| Study Session (Pomodoro / focus mode) | `StudySession.tsx` | ❌ | 🟢 | Utile mais non critique v1 |
| **Profil complet** (infos, sécurité, notifications, confidentialité, compte) | `Profile.tsx` — 5 tabs | ❌ Aucun écran profil étudiant | 🟡 | Au minimum : modifier infos, changer mdp, dark mode |
| Page Notifications (groupées par date, marquer comme lu, résumé IA) | `Notifications.tsx` | ❌ Icône cloche sans page | 🟡 | Page basique nécessaire, résumé IA en v2 |
| **Certificats** (téléchargement PDF, partage, lien de vérification) | `MyCertificates.tsx` | ❌ | 🟡 | Si le backend émet des certificats, l'affichage mobile est indispensable |

---

## PARENT

| Fonctionnalité | Fichier web | Mobile actuel | Priorité | Note |
|---|---|---|---|---|
| Activité récente de l'enfant (timeline) | `ChildActivityTimeline.tsx` | ❌ | 🔴 | Les parents veulent voir concrètement ce que fait leur enfant |
| WinAI Alerts détaillées (difficulté, streak rompu, progrès) | `WinAIAlerts.tsx` | ❌ Cards basiques | 🔴 | Core value du rôle Parent |
| Évènements à venir de l'enfant (examens, renouvellements) | `UpcomingEvents.tsx` | ❌ | 🟡 | Calendrier des échéances importantes |
| **Ajouter un enfant** (formulaire complet) | `AddChildSheet.tsx` | ❌ Bouton sans formulaire | 🔴 | Le bouton existe dans le mobile — il faut juste le formulaire |
| Score d'engagement enfant (indicateur 0-100, tendance hebdo) | `EngagementScore.tsx` | ❌ | 🟡 | Indicateur synthétique très utile pour les parents |
| Statut abonnement + date de renouvellement | `PaymentsOverview.tsx` | ❌ Historique seulement | 🔴 | Différent de l'historique : c'est le statut actif/expirant |
| Renouvellement abonnement (modal + NotchPay) | `RenewalSheet.tsx` | ❌ | 🔴 | Indispensable pour la rétention, à intégrer avec NotchPay |
| Envoyer message d'encouragement à l'enfant | `EncouragementSheet.tsx` | ❌ | 🟢 | Sympa mais secondaire v1 |
| Comparaison multi-enfants (radar chart) | `ChildrenComparison.tsx` | ❌ | 🟢 | Pertinent si 2+ enfants, pas prioritaire v1 |
| ROI éducatif (coût / heure d'apprentissage) | `EducationalROI.tsx` | ❌ | ⚫ | Feature trop niche, à évaluer selon feedback utilisateurs |

---

## PROFESSEUR

| Fonctionnalité | Fichier web | Mobile actuel | Priorité | Note |
|---|---|---|---|---|
| **Formulaire publication contenu** (upload fichier, type, matière, prix) | `ContentPublishFlow.tsx` | ❌ Bouton sans formulaire | 🔴 | Bouton "Publier" dans le mobile sans aucune action |
| **Correction Queue** (soumissions étudiants à corriger, feedback, note) | `CorrectionQueue.tsx` | ❌ | 🔴 | Feature métier centrale pour le professeur |
| Création de session (formulaire : titre, date, durée, max étudiants, lien) | `SessionCalendar.tsx` | ❌ Liste seulement | 🔴 | Le mobile liste les sessions mais ne permet pas d'en créer |
| Actions sur un contenu (éditer, supprimer, voir analytics) | `ContentList.tsx` row actions | ❌ Liste uniquement | 🔴 | Au minimum : changer le statut et voir les stats |
| Insights IA professeur (cours populaire, ratings) | `TeacherInsights.tsx` | ❌ | 🟡 | Simple à afficher, très motivant pour le prof |
| Revenue by content (top earners, breakdown par contenu) | `RevenueOverview.tsx` | ❌ Total + transactions seulement | 🟡 | Savoir quel contenu rapporte le plus est une info clé |
| Analyse de classe (moyenne, taux réussite, par matière, tendance) | `ClassAnalysis.tsx` | ❌ | 🟢 | Secondaire si les données réelles ne sont pas encore disponibles |

---

## INSTITUTION

| Fonctionnalité | Fichier web | Mobile actuel | Priorité | Note |
|---|---|---|---|---|
| **Élèves à risque** (tableau filtrable, actions en masse) | `AtRiskTable.tsx` | ❌ | 🔴 | Feature la plus utile pour une institution |
| **Plan d'action IA** (interventions recommandées par WinAI) | `ActionPlan.tsx` | ❌ | 🔴 | Donne des actions concrètes, pas juste des chiffres |
| **Formulaire création de groupe** (nom, niveau, étudiants) | N/A | ❌ Liste + recherche seulement | 🔴 | Indispensable pour la gestion des classes |
| Annuaire étudiants filtrable (niveau, statut, recherche) | Students view | ❌ | 🟡 | Version mobile simplifiée suffisante |
| Rapports exportables (PDF/Excel via serveur) | Reports view | ❌ | 🟡 | PDF généré côté backend, partage depuis le mobile |
| Prédiction taux de réussite de classe (IA) | `ClassPrediction.tsx` | ❌ | 🟢 | Nécessite un historique de données suffisant |
| Benchmark vs autres institutions | `BenchmarkPanel.tsx` | ❌ | ⚫ | Données sensibles, feature premium uniquement |

---

## ADMIN

| Fonctionnalité | Priorité | Note |
|---|---|---|
| Dashboard admin complet (users, contenus, ordres, analytics, promo codes, audit, logs, santé système…) | ⚫ | L'administration se fait sur le web. Pas de backoffice mobile v1 |
| Modération chat / logs système | ⚫ | Web only par conception |

---

## Récapitulatif des priorités

### 🔴 Haute — v1 (sans ça l'app n'est pas utilisable)

1. Écrans auth manquants : forgot password, reset password, email verification, complete profile onboarding
2. Fiche détail contenu + flow d'achat (NotchPay)
3. Quiz engine complet (actif, résultats, revue des réponses)
4. Catalogue avec filtres avancés + page résultats de recherche
5. Formulaire publication contenu (prof)
6. Correction Queue (prof)
7. Création de session (prof)
8. Formulaire ajout d'enfant (parent)
9. Statut abonnement + renouvellement (parent, NotchPay)
10. Activité récente enfant + WinAI alerts détaillées (parent)
11. Élèves à risque + Plan d'action IA (institution)
12. Formulaire création de groupe (institution)
13. Continue Learning (étudiant)
14. Recommandations IA sur le home (étudiant)

### 🟡 Moyenne — v1.5 (enrichit significativement l'app)

15. Achievements / Badges + streak enrichi
16. Favoris + Historique téléchargements
17. Exam Coach / Plan de révision IA
18. Activité récente étudiant (timeline)
19. Compte à rebours examens
20. Profil utilisateur (modifier infos, mdp, notifs)
21. Page Notifications
22. Certificats (affichage + téléchargement)
23. Revenue by content (prof)
24. Score d'engagement enfant (parent)
25. Annuaire étudiants + Rapports PDF (institution)

### 🟢 Plus tard — v2

- Google OAuth
- Learning Style Quiz (VARK)
- Study Session / Pomodoro
- Comparaison avec les pairs
- Prédiction de note IA
- Comparaison multi-enfants
- Analyse de classe (prof)
- Prédiction taux de réussite (institution)

### ⚫ Non (web only ou non pertinent mobile)

- Pages marketing (Landing, About, Contact, FAQ, Help)
- Benchmark institution
- ROI éducatif parent
- Backoffice admin complet
