🔍  MAÎTRE — À envoyer en premier à Claude Code
Tu travailles sur WinPlus/Réussir, une plateforme éducative camerounaise.
Stack technique :
- Backend 1 : ASP.NET Core 8 (C#) — API principale, gestion des utilisateurs, paiements NotchPay (MTN/Orange MoMo), sessions, cours particuliers
- Backend 2 : FastAPI (Python) — IA/ML, WinAI, analyses, génération de contenu
- Frontend : React 18 — interface web professeur et élève
- DB : PostgreSQL
- Storage : AWS S3

Règles absolues pour toutes tes interventions :
1. Avant toute implémentation, explore le code existant (dotnet, Python, React) et dis-moi ce qui est déjà en place, partiellement implémenté, ou absent.
2. Pour les modifications frontend, charge et respecte impérativement le skill UI/UX situé à : C:\Users\Miguel\.claude\skills\ui-ux-pro-max — il définit les composants, tokens de design, patterns UX et conventions de nommage du projet.
3. Ne jamais casser une feature existante. Toujours vérifier les dépendances avant de modifier un fichier.
4. Lister les fichiers modifiés à la fin de chaque intervention.
MODULE 1 — PROFIL RÉPÉTITEUR
 1A — Audit profil répétiteur
Audit complet du mode Répétiteur sur WinPlus.

Explore le code C# (ASP.NET Core) et React pour répondre à ces questions :
1. Existe-t-il un modèle/entité "Tutor", "Répétiteur" ou équivalent dans le schéma PostgreSQL (migrations EF Core ou SQL brut) ?
2. Y a-t-il des endpoints API pour activer le mode Répétiteur, gérer le profil répétiteur, les disponibilités, les zones géographiques ?
3. Côté React, existe-t-il des pages ou composants liés au profil répétiteur (fiche publique, onboarding, édition) ?
4. Le système de badges (Vérifié Diplôme, Expérimenté, Très Réactif) est-il modélisé quelque part ?

Dresse un tableau de l'existant : Fonctionnalité | Statut (Implémenté / Partiel / Absent) | Fichiers concernés.
Ne modifie rien pour l'instant.
 1B — Onboarding répétiteur en 5 étapes
Sur la base de l'audit précédent, implémente l'onboarding répétiteur en 5 étapes.

Backend C# :
- Si le modèle TutorProfile n'existe pas : crée l'entité avec les champs (matières, niveaux, zones, tarif horaire, forfaits, délai de préavis, max séances/semaine, bio, vidéoUrl, statutVacances) + migration EF Core
- Endpoints nécessaires : POST /api/tutors/activate, PUT /api/tutors/profile (patch par étape), GET /api/tutors/profile

Frontend React :
- Charge le skill C:\Users\Miguel\.claude\skills\ui-ux-pro-max avant de créer quoi que ce soit
- Crée un composant TutorOnboardingStepper avec 5 étapes (matières/niveaux, zones, tarif, disponibilités, bio/vidéo)
- Chaque étape est sauvegardée indépendamment via PATCH
- Si l'utilisateur ferme l'app en cours, il reprend à la dernière étape sauvegardée
- Afficher le score de complétude 0-100 à la fin avec items manquants cliquables

Respecte l'UI/UX existant. Liste les fichiers créés/modifiés.
 1C — Grille de disponibilités
Implémente la gestion des disponibilités hebdomadaires du répétiteur.

Audit d'abord :
- Cherche dans le code C# et Python toute modélisation de créneaux, slots, availability, schedule
- Cherche dans React tout composant de calendrier ou grille horaire existant

Puis implémente :
Backend C# :
- Entité TutorAvailability (jour 0-6, heureDebut, heureFin, récurrent bool)
- Endpoints : PUT /api/tutors/availability (sauvegarde immédiate, pas de bouton Enregistrer côté API)
- Logique : fermeture automatique du calendrier quand le nb max de séances/semaine est atteint

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Composant WeeklyAvailabilityGrid : 7 colonnes × plages horaires (matin/AM/soir)
- Tap/click sur une case = toggle immédiat avec appel PATCH optimiste
- Bouton "Reproduire cette semaine" qui propage la grille indéfiniment
- Aucun bouton "Enregistrer" séparé — sauvegarde instantanée visible

Ne touche pas aux composants de session/calendrier existants sans vérifier les dépendances.
MODULE 2 — RECHERCHE ET RÉSERVATION
 2A — Audit moteur de recherche répétiteur
Audit du moteur de recherche côté élève pour trouver un répétiteur.

Explore C# et React :
1. Existe-t-il un endpoint de recherche de tuteurs/répétiteurs avec filtres ?
2. Les filtres suivants sont-ils implémentés : matière, niveau, mode d'intervention, localisation/quartier, tarif max, disponibilité immédiate, note minimale, badge vérifié ?
3. Y a-t-il une logique de tri par pertinence (note × volume séances × réactivité) ?
4. Côté React, existe-t-il une page de résultats de recherche de répétiteurs ?

Résultat attendu : tableau Filtre | Implémenté | Endpoint/Composant.
Ne modifie rien.
 2B — Flow de réservation 3 écrans
Implémente le flow de réservation d'une séance de cours particulier.

Audit préalable :
- Cherche dans C# toute entité Booking, Reservation, Session (cours particulier, pas live)
- Cherche dans le code NotchPay/MoMo la logique d'escrow (fonds retenus jusqu'à confirmation)
- Cherche dans React tout composant de réservation ou paiement Mobile Money existant

Implémente :
Backend C# :
- Entité TutorBooking (élèveId, tuteurId, créneau, durée, mode, montant, statut: EnAttente/Confirmé/Effectué/Contesté, escrowReleasedAt)
- Endpoints : POST /api/bookings, PUT /api/bookings/{id}/confirm, PUT /api/bookings/{id}/decline, PUT /api/bookings/{id}/complete
- Logique escrow : à la confirmation de paiement NotchPay, fonds retenus. Libération automatique 2h après statut "Effectuée" sans contestation
- Webhook NotchPay pour confirmer le paiement

Frontend React (3 écrans max) :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Écran 1 : sélection créneau (calendrier horizontal du répétiteur, créneaux disponibles en vert)
- Écran 2 : récapitulatif + champ message 100 chars + bouton "Payer maintenant"
- Écran 3 : paiement Mobile Money avec polling statut toutes 3s + écran succès
- Bouton "Réserver" sticky en bas de la fiche répétiteur

Liste tous les fichiers modifiés.
 2C — Gestion des demandes côté répétiteur
Implémente la gestion des demandes de réservation côté répétiteur.

Audit préalable :
- Vérifie si un système de notifications push existe déjà (endpoints, service, Firebase/OneSignal?)
- Cherche dans React tout composant de liste de demandes ou tableau de bord répétiteur

Implémente :
Backend C# :
- Endpoint GET /api/tutors/bookings/pending (demandes en attente avec délai restant)
- Notification push déclenchée dès qu'une nouvelle demande arrive (dans les 30s)
- Logique d'expiration : si pas de réponse dans le délai de préavis défini → statut "Expiré" + remboursement automatique + notification élève

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Tab "Cours particuliers" dans l'onglet Sessions existant (ne pas casser l'onglet existant)
- Carte de demande : photo élève, matière, niveau, créneau, boutons "Accepter" (vert) et "Refuser" (gris) directement sur la carte
- Bouton "Marquer effectuée" visible dès l'heure de fin prévue de la séance
- Badge rouge "N demandes en attente" sur le titre de l'onglet

Ne modifie pas la structure de l'onglet Sessions existant sans audit préalable de ses composants.
MODULE 3 — MESSAGERIE
 3A — Audit système de messagerie
Audit complet du système de messagerie WinPlus.

Explore C#, Python et React :
1. Existe-t-il un modèle Message, Conversation, Channel dans la base de données ?
2. Y a-t-il des endpoints REST ou WebSocket/SignalR pour la messagerie temps réel ?
3. Existe-t-il dans React un composant de chat, messagerie ou inbox ?
4. Les types de pièces jointes (PDF, image, note vocale) sont-ils gérés quelque part ?
5. Le réseau de contacts (qui peut écrire à qui) est-il modélisé ?

Résultat : inventaire complet avec statut et fichiers.
 3B — Messagerie directe 1-to-1
Sur la base de l'audit messagerie, implémente la messagerie directe 1-to-1.

Backend C# :
- Si pas de modèle existant : entités Conversation (participantA, participantB), Message (conversationId, senderId, type, contenu, fichierUrl, programmeSendAt, luPar[])
- Endpoints : GET /api/messages/conversations, GET /api/messages/conversations/{id}, POST /api/messages (texte + fichier), PATCH /api/messages/{id}/read
- Logique réseau : bloquer les messages entrants d'utilisateurs hors réseau (non liés, non élèves, non inscrits à une formation, non ayant réservé)
- Messages programmés : job background pour l'envoi à l'heure définie

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Si un composant de messagerie existe déjà : étends-le plutôt que d'en créer un nouveau
- Liste des conversations triée par dernier message, aperçu du dernier message, badge non lus
- Écran conversation : bulles, statut "Lu", boutons d'attachement (PDF, image, note vocale)
- Tap long → menu : Répondre (avec citation), Réagir (👍❤️😄), Copier, Supprimer
- Panneau latéral rétractable sur web (accessible depuis toutes les vues sans quitter la page)
 3C — Canal de formation + Q&A WinAI
Implémente le canal de messagerie par formation avec Q&A automatique WinAI.

Audit préalable :
- Vérifie si le modèle Formation a un champ "canalActif" ou équivalent
- Cherche dans FastAPI (Python) tout endpoint lié à la génération de réponses contextuelles

Backend C# :
- Ajouter champ canalMessagerie (bool) sur l'entité Formation
- Endpoint POST /api/formations/{id}/canal/messages
- À chaque nouveau message dans le canal : si WinAI Q&A activé → appel à FastAPI /winai/canal-qa avec le contenu des leçons de la formation comme contexte

Backend Python (FastAPI) :
- Endpoint POST /winai/canal-qa : reçoit la question + le contenu des leçons → génère une réponse contextualisée avec score de confiance
- Si confiance < 0.70 : retourner {"action": "tag_professor"} au lieu d'une réponse
- Loguer toutes les interactions dans une table WinAI_InteractionLog

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Canal de formation : fil de discussion, messages IA avec badge "Réponse WinAI — à vérifier"
- Journal des interactions IA visible uniquement par le professeur avec bouton "Corriger cette réponse"
- Toggle d'activation du Q&A dans les paramètres de la formation
MODULE 4 — CATALOGUE ET BIBLIOTHÈQUE
 4A — Audit catalogue côté professeur-acheteur
Audit du catalogue WinPlus du point de vue du professeur en tant qu'acheteur.

Explore C# et React :
1. Le catalogue distingue-t-il les rôles (professeur vs élève) dans les filtres ou la fiche produit ?
2. Existe-t-il un indicateur "X enseignants ont utilisé ce contenu dans leurs formations" ?
3. Y a-t-il une fonctionnalité "Ajouter à une formation" ou "Assigner à une classe" depuis la fiche catalogue ?
4. Existe-t-il une bibliothèque personnelle (achats et téléchargements) séparée du catalogue ?
5. Le solde WinPlus peut-il être utilisé comme moyen de paiement dans le catalogue ?

Résultat : tableau fonctionnalité/statut/fichiers. Ne modifie rien.
 4B — Bibliothèque personnelle + assignation classe
Implémente la bibliothèque personnelle du professeur et l'assignation de contenu à une classe.

Backend C# :
- Entité BibliothequeItem (professeurId, contenuId, dossierId, notesPrivées, dateAjout)
- Entité DossierBibliotheque (professeurId, nom)
- Endpoint POST /api/bibliotheque/contenu/{id} (ajouter après achat ou téléchargement gratuit)
- Endpoint POST /api/classes/{classId}/assignations (assigne un contenu acheté à tous les élèves de la classe, débite une fois le compte du professeur, génère un accès par élève)
- Endpoint GET /api/bibliotheque (avec filtres titre/matière/niveau + dossiers)

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Page "Ma bibliothèque" dans la sidebar (ne pas perturber la navigation existante)
- Vue dossiers personnalisables avec glisser-déposer des contenus
- Champ notes privées (max 300 chars) par contenu, visible uniquement par le professeur
- Bouton "Ajouter à une formation" et "Assigner à une classe" sur chaque item
- Depuis la fiche catalogue : bouton "Acheter pour ajouter à une formation" si pas encore acheté
MODULE 5 — FORMATIONS ENRICHIES
 5A — Audit formations (drip content, gamification, certificats)
Audit des fonctionnalités avancées de formation WinPlus.

Explore C#, Python et React :
1. Le modèle Section/Leçon a-t-il un champ de règle de déblocage (drip content) ?
2. La gamification (points, badges, classement) est-elle modélisée ou partielle ?
3. La génération de certificats est-elle implémentée (modèle, génération PDF, code de vérification unique) ?
4. Les analytics par leçon (taux de complétion, temps moyen, score quiz) sont-elles collectées ?
5. Les checkpoints vidéo (quiz à un timestamp) existent-ils dans l'éditeur ou dans le player ?

Résultat attendu : fonctionnalité / statut / fichiers.
 5B — Drip content et checkpoints vidéo
Implémente le drip content (déblocage progressif) et les checkpoints vidéo.

Audit préalable obligatoire : lis les modèles Section et Leçon dans le code C# avant de toucher au schéma.

Backend C# :
- Ajouter sur Section : regleDeblocage (enum: Immédiat/DelaiJours/ScoreMinimum), delaiJours (int?), scoreMinimum (int?)
- Ajouter sur Leçon : checkpoints (JSON : liste de {timestampMs, question, options[], bonneReponse})
- Endpoint GET /api/formations/{id}/acces-eleve : retourne pour chaque section si elle est déverrouillée pour cet élève (calcule la règle en temps réel)
- Job background : débloquer automatiquement les sections dont la condition est remplie

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Dans l'éditeur de formation : sélecteur "Règle de déblocage" sous chaque titre de section
- Dans l'éditeur de leçon vidéo : bouton "Ajouter un checkpoint" → panneau latéral avec saisie timestamp (mm:ss) + question QCM
- Dans le player vidéo : détection des timestamps, pause auto, affichage question, reprise après réponse
- Côté élève : sections verrouillées avec cadenas + texte de la condition ("Disponible dans X jours" ou "Complète le quiz précédent avec ≥ 60%")
 5C — Gamification et certificats
Implémente la gamification et les certificats vérifiables pour les formations.

Backend C# :
- Entités : FormationGamification (formationId, pointsParLeçon, pointsParQuiz, pointsBonusParfait, classementVisible), ElèveBadge (elèveId, formationId, badgeType, dateObtention), CertificatCompletion (elèveId, formationId, codeVerification uuid, dateEmission, noteObtenue)
- Logique attribution points : à chaque complétion de leçon et quiz réussi → incrémenter ElèveProgression.points
- Logique badges : "Premier quiz validé", "Formation 50%", "Score parfait", "Formation complétée" — déclenchés par événements
- Génération certificat : automatique quand l'élève atteint 100% → générer PDF avec QRCode pointant vers la page de vérification
- Endpoint public GET /api/certificats/{code} (sans authentification) pour vérification

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Dans les paramètres de formation : toggles "Gamification", "Certificat de complétion", "Classement visible"
- Widget de progression gamifiée dans l'espace élève : points, badges débloqués, rang dans le classement
- Page publique de vérification de certificat : saisie du code → résultat avec nom, cours, note, date, badge d'authenticité
- Téléchargement du certificat en PDF par l'élève
MODULE 6 — WINAI
 6A — Audit WinAI existant
Audit complet de WinAI dans le codebase WinPlus.

Explore FastAPI (Python) et C# :
1. Quels endpoints WinAI existent déjà dans FastAPI ? (génération quiz, optimisation titre, description, correction type, analyse de classe, etc.)
2. Quelle API LLM est utilisée en dessous (DeepSeek, OpenAI, autre) ? Comment est géré le contexte ?
3. Existe-t-il une mémoire conversationnelle persistante pour WinAI ?
4. Le chatbot WinAI est-il accessible depuis l'UI React ? Sous quelle forme (bouton flottant, panneau, modal) ?
5. Les fonctionnalités IA côté répétiteur (suggestion de tarif, compte-rendu de séance, plan de progression) sont-elles implémentées ?

Résultat : inventaire de toutes les capacités IA existantes avec endpoint + fichier Python/C#.
Ne modifie rien.
 6B — Compte-rendu de séance + fiche de révision
Implémente la génération de compte-rendu de séance et de fiche de révision personnalisée.

Audit préalable : lis les endpoints FastAPI existants pour ne pas dupliquer la logique LLM déjà en place.

Backend Python (FastAPI) :
- Endpoint POST /winai/compte-rendu-seance : reçoit {résumé libre du répétiteur (str), historiqueSeances (list), matière, niveau} → génère un message formel structuré (notions abordées, points assimilés, à retravailler, devoirs conseillés)
- Endpoint POST /winai/fiche-revision : reçoit {elèveId, compteRendus[], scoresQuiz[], erreursIdentifiées[]} → génère une fiche personnalisée (notions prioritaires, exercices recommandés du catalogue, formules clés)
- Utilise le même client LLM que le reste de WinAI pour la cohérence

Backend C# :
- Après PUT /api/bookings/{id}/complete : appel async à FastAPI /winai/compte-rendu-seance
- Stocker le compte-rendu généré dans une entité CompteRenduSeance
- Endpoint GET /api/bookings/{id}/compte-rendu pour récupérer et modifier avant envoi

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Post-séance : modal "Compte-rendu disponible" avec champ d'édition + bouton "Envoyer à l'élève" (déclenche l'envoi dans la conversation messagerie)
- Depuis la fiche élève (mode répétiteur) : bouton "Générer fiche de révision" → résultat éditable + bouton "Partager dans la conversation"
 6C — Mémoire conversationnelle WinAI
Implémente la mémoire conversationnelle persistante pour le chatbot WinAI.

Backend Python (FastAPI) :
- Modèle WinAI_Memoire (userId, role: professeur/répétiteur, clé: str, valeur: str, updatedAt)
- À chaque conversation WinAI : extraire et persister les éléments durables (matières, style pédagogique, formats préférés, conversation en cours non finalisée)
- Endpoint GET /winai/memoire : retourne les éléments mémorisés pour l'utilisateur connecté
- Endpoint DELETE /winai/memoire/{cle} : supprime un élément de mémoire
- Au démarrage d'une session chatbot : injecter la mémoire pertinente dans le  système
- Si une conversation non finalisée existe : première suggestion "On avait commencé [X] — tu veux continuer ?"

Backend C# :
- Proxy endpoint GET /api/winai/memoire → FastAPI (pour ne pas exposer FastAPI directement au front)

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Dans le chatbot WinAI (bouton flottant existant) : section "Mémoire WinAI" accessible en bas du panneau
- Liste des éléments mémorisés avec bouton de suppression individuelle
- La suggestion de continuation s'affiche comme premier message de la session si applicable
MODULE 7 — REVENUS ET PAIEMENTS
 7A — Audit tableau de bord revenus
Audit du tableau de bord revenus WinPlus.

Explore C# et React :
1. Le graphique de revenus distingue-t-il déjà plusieurs sources (catalogue vs cours particuliers) ?
2. Le détail des transactions (montant brut, commission, montant net) est-il calculé et stocké ?
3. La logique de retrait Mobile Money via NotchPay est-elle implémentée ? Avec quel statut de suivi ?
4. Le solde disponible est-il calculé en temps réel ou pré-calculé dans la DB ?
5. L'historique des achats (professeur-acheteur) est-il séparé de l'historique des ventes ?

Résultat : inventaire avec statut et fichiers.
 7B — Revenus agrégés multi-sources
Étends le tableau de bord revenus pour afficher les cours particuliers comme source distincte.

Audit préalable : lis les composants React du tableau de bord revenus existant avant toute modification.

Backend C# :
- Endpoint GET /api/revenus/dashboard : retourner {totalCatalogue, totalCoursParticuliers, totalSolde, graphique: [{date, montantCatalogue, montantCoursParticuliers}], transactions: [{type, source, elève/contenu, montantBrut, commission, montantNet, statut}]}
- Calcul commission : déduite selon les règles WinPlus (à vérifier dans le code existant)
- L'historique distingue explicitement : Vente catalogue / Cours particulier / Achat catalogue (débit)

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Modifie le composant de graphique existant pour ajouter une 2ème série "Cours particuliers" (sans casser la série existante)
- Tableau de détail avec colonne "Source" filtrable (Catalogue / Cours particuliers / Achats)
- Pour les cours particuliers : afficher nom élève, matière, durée, montant brut, commission %, montant net
- Ne pas refaire le composant de retrait Mobile Money s'il existe déjà — l'étendre si besoin
MODULE 8 — ANALYTICS ET DÉTECTION DE DÉCROCHAGE
 8A — Détection de décrochage + alertes
Implémente la détection de décrochage sur les formations avec alertes WinAI.

Audit préalable :
- Cherche dans Python et C# tout système de tracking de progression élève (dernière connexion, leçons complétées, scores)
- Vérifie si un job scheduler existe (Hangfire, Celery, APScheduler)

Backend Python (FastAPI) :
- Endpoint POST /winai/detection-decrochage : reçoit les métriques d'engagement d'une formation → identifie les élèves "à risque" (inactifs depuis X jours, temps passé en baisse, scores en chute) → retourne la liste avec les signaux détectés
- Modèle de scoring : inactivité > 7 jours = risque faible, > 14 jours = risque élevé, combiné avec baisse de score

Backend C# :
- Job planifié (daily) : pour chaque formation active, appelle FastAPI detection-decrochage et stocke les alertes dans AlerteDecrochage (formationId, elèveId, niveau, signaux, dateDétection, traitée bool)
- Endpoint GET /api/professeurs/alertes-decrochage : retourne les alertes non traitées
- Endpoint POST /api/alertes/{id}/relancer : marque comme traitée + envoie message pré-rédigé WinAI à l'élève

Frontend React :
- Charge C:\Users\Miguel\.claude\skills\ui-ux-pro-max
- Dans les analytics de formation : widget "Élèves à risque" avec liste et signaux
- Bouton "Relancer ces élèves" → confirmation → envoi groupé du message WinAI
- Taux de réactivation affiché dans les analytics (% d'élèves relancés qui sont revenus dans les 7 jours)
 TRANSVERSAL — Tests et non-régression
Avant de merger les modifications apportées dans cette session, effectue une vérification de non-régression.

1. Liste tous les fichiers C# modifiés et vérifie que les migrations EF Core ne cassent pas les données existantes (utilise des migrations additive uniquement — pas de suppression de colonne sans vérification préalable)
2. Liste tous les fichiers Python modifiés et vérifie que les endpoints existants répondent toujours correctement (teste manuellement ou avec les tests pytest existants s'ils existent)
3. Liste tous les fichiers React modifiés et vérifie que les routes existantes s'affichent toujours (pas de 404 introduit)
4. Vérifie que le skill UI/UX C:\Users\Miguel\.claude\skills\ui-ux-pro-max a bien été respecté pour toutes les modifications frontend (tokens, composants, conventions)
5. Génère un résumé de ce qui a été implémenté, ce qui reste à faire, et les éventuels blocages détectés