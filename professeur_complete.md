Voilà, j'ai suffisamment de matière. Je vais tout synthétiser de façon structurée — fonctionnalités, user stories, workflows et UX mobile/web.

---

# Espace Professeur / Répétiteur WinPlus — Référentiel complet

---

## I. FEATURE SET COMPLET

### A. Profil Professeur-Répétiteur

**Identité et crédibilité**
- Photo de profil obligatoire (pas des initiales pour un répétiteur public)
- Nom complet ou nom professionnel
- Titre libre : "Prof de Maths — Terminale C/D" ou "Répétiteur en Physique-Chimie"
- Bio courte 300 caractères max — s'adresse directement à l'élève
- Vidéo d'introduction courte (lien externe YouTube ou upload direct) — les plateformes de tutorat qui affichent une vidéo d'introduction augmentent significativement les conversions de réservation
- Badge "Vérifié Diplôme" après upload et validation du justificatif par l'équipe WinPlus
- Badge "Expérimenté" déclenché automatiquement après N séances effectuées
- Badge "Très réactif" si taux de réponse aux demandes > 90 % en moins de 2h
- Note globale et nombre d'avis, affichés en premier

**Double mode d'exercice sur un seul compte**
- Mode Professeur Catalogue : publie des épreuves, corrections, formations dans le catalogue
- Mode Répétiteur : profil public pour cours particuliers avec réservation
- Les deux modes sont actifs simultanément, les revenus sont agrégés dans un seul tableau de bord
- Indicateur visuel sur le profil public : "Disponible pour cours particuliers" ou "Non disponible en ce moment"

**Expertise déclarée**
- Matières enseignées (multiselect)
- Niveaux couverts : 6ème à Tle, BEPC, BAC, prépas, concours ENSP / Polytechnique / FMSB / ENAM / ENS
- Spécialités : "Préparation concours", "Soutien scolaire", "Rattrapage express", "Cours de vacances"
- Style pédagogique déclaré : Structuré / Interactif / Mixte

**Tarification**
- Tarif horaire affiché en XAF
- Forfaits : Pack 5 séances, Pack 10 séances avec prix dégressif défini par le répétiteur
- Séance d'essai à tarif réduit ou gratuite (case à cocher)
- WinAI suggère un tarif horaire basé sur la matière, le niveau et les autres répétiteurs de la zone

**Modes d'intervention**
- À domicile chez l'élève — avec zones géographiques couvertes (quartiers / communes cochés)
- À domicile chez le répétiteur
- En ligne via WinPlus (session intégrée) ou lien externe (Meet, Zoom)
- Présentiel en espace neutre

**Disponibilités**
- Agenda hebdomadaire type : créneaux disponibles par heure, reconductibles automatiquement chaque semaine
- Délai de préavis minimum : 12h, 24h, 48h (choix du répétiteur)
- Nombre max de séances par semaine (auto-fermeture du calendrier quand le max est atteint)
- Statut "En vacances" : désactive les réservations sans supprimer le profil

**Avis vérifiés**
- Seuls les élèves ayant eu une séance confirmée via WinPlus peuvent noter
- Note sur 5 + commentaire texte court
- Le répétiteur peut répondre publiquement à chaque avis
- Signalement d'un avis abusif possible

---

### B. Moteur de recherche côté élève

- Matière (obligatoire)
- Niveau (obligatoire)
- Mode d'intervention : à domicile / en ligne / mixte
- Localisation : quartier ou commune pour le domicile
- Tarif horaire maximum en XAF
- Disponibilité : "ce week-end", "en soirée", "dès aujourd'hui"
- Note minimale
- Badge "Vérifié" uniquement
- Tri : pertinence (note × volume × réactivité), prix croissant, prochain créneau disponible
- Chaque résultat liste : photo, nom, titre, note, tarif, badge vérifié, prochain créneau libre, distance estimée pour le domicile

---

### C. Flow de réservation et paiement

- Demande de réservation par l'élève : matière, niveau, mode, créneau souhaité, message optionnel
- Messagerie pré-réservation : l'élève et le répétiteur échangent avant de confirmer — réduit les annulations et améliore la satisfaction à la première séance
- Le répétiteur accepte ou refuse dans le délai de préavis défini
- À l'acceptation : l'élève paie en avance via Mobile Money (MTN/Orange)
- Les fonds sont retenus par WinPlus (escrow) jusqu'à la confirmation post-séance — protège le répétiteur contre les no-shows et l'élève contre les défauts de prestation
- Libération automatique des fonds 2h après la fin de la séance si aucune contestation
- En cas de litige : gel des fonds, escalade vers le support WinPlus
- Politique d'annulation configurable par le répétiteur : remboursement total si annulation > 24h, partiel si < 24h, aucun si < 2h

**Packages / forfaits**
- L'élève achète un pack (ex. 10 séances) en une transaction
- Un compteur de séances restantes est visible pour les deux parties
- Re-booking automatique suggéré quand il reste 2 séances dans le pack

---

### D. Post-séance

- Le répétiteur marque la séance comme effectuée (déclenche la libération de l'escrow)
- L'élève est invité à noter la séance (notification push)
- WinAI propose au répétiteur un compte-rendu structuré à envoyer à l'élève ou aux parents : ce qu'on a vu, points bien assimilés, points à retravailler, exercices conseillés
- Suggestion automatique de re-booking : "Proposer la prochaine séance ?"

---

### E. Création de formation — fonctionnalités supplémentaires

**Drip content (publication progressive)**
- Le professeur programme le déblocage des leçons selon un calendrier (ex. leçon 3 débloquée 7 jours après l'inscription) ou selon la progression (ex. leçon 3 débloquée si score quiz leçon 2 ≥ 60 %)
- Les deux modes sont combinables par section

**Contenu interactif dans les leçons**
- Quiz intégré à la vidéo à un timestamp précis (pause automatique, question, reprise)
- Sondage en direct dans une leçon
- Tableau blanc interactif pour les leçons live : dessin, annotation, surlignage — crucial pour maths et sciences

**Gamification**
- Points attribués à la complétion de chaque leçon et quiz
- Badges débloqués par l'élève : "Premier quiz validé", "Formation complétée", "Score parfait"
- Classement optionnel au sein d'une formation (activable ou non par le professeur)
- WinAI ajuste la difficulté des challenges selon la progression individuelle

**Certificats vérifiables**
- Généré automatiquement à la complétion de la formation
- Signé numériquement avec identifiant unique WinPlus
- Partageable et vérifiable via un lien public

**Analytics par leçon**
- Taux de complétion par leçon (à quelle leçon les élèves décrochent)
- Temps moyen passé par leçon
- Score moyen au quiz de chaque leçon
- Alerte WinAI si le taux de complétion d'une leçon chute sous un seuil

**Parcours d'apprentissage adaptatif**
- Sur la base des scores aux quiz, WinAI réordonne ou suggère du contenu supplémentaire à l'élève
- Le professeur voit quels élèves sont "à risque de décrochage" sur sa formation

---

### F. WinAI — fonctionnalités supplémentaires pour le répétiteur

- Suggestion de tarif horaire contextualisée
- Optimisation du profil public (analyse et recommandations concrètes)
- Plan de progression élève multi-séances : à partir des notes et compte-rendus précédents, WinAI génère un plan de révision personnalisé
- Détection précoce de décrochage : sur les formations, WinAI identifie les élèves dont le pattern d'engagement prédit un abandon et alerte le professeur
- Suggestions de re-booking automatiques basées sur l'historique des séances
- Génération de compte-rendu de séance structuré

---

## II. USER STORIES

### Profil et onboarding

US-01 — En tant que professeur souhaitant proposer des cours particuliers, je veux activer le mode Répétiteur depuis mes paramètres afin que mon profil soit visible dans la recherche d'élèves.

US-02 — En tant que répétiteur, je veux renseigner mes matières, niveaux, zones d'intervention et tarif horaire afin que les élèves puissent évaluer si je corresponds à leurs besoins.

US-03 — En tant que répétiteur, je veux uploader mon diplôme ou relevé de notes afin d'obtenir le badge "Vérifié Diplôme" et renforcer ma crédibilité.

US-04 — En tant que répétiteur, je veux ajouter un lien vers une courte vidéo de présentation afin que les élèves puissent évaluer mon style pédagogique avant de réserver.

US-05 — En tant que répétiteur, je veux que WinAI analyse mon profil et me suggère des améliorations concrètes afin d'optimiser ma visibilité dans les résultats de recherche.

US-06 — En tant que répétiteur, je veux définir mes créneaux de disponibilité hebdomadaire et mon délai de préavis minimum afin de ne recevoir que des demandes compatibles avec mon agenda.

US-07 — En tant que répétiteur, je veux que WinAI me suggère un tarif horaire adapté à ma matière, mon niveau et ma zone afin de me positionner correctement sur le marché.

---

### Recherche et mise en relation (côté élève)

US-08 — En tant qu'élève, je veux rechercher un répétiteur par matière, niveau, mode d'intervention et localisation afin de trouver rapidement celui qui correspond à ma situation.

US-09 — En tant qu'élève, je veux voir le prochain créneau disponible de chaque répétiteur directement dans les résultats de recherche afin de choisir selon mon urgence.

US-10 — En tant qu'élève, je veux accéder à la fiche complète d'un répétiteur (bio, avis, vidéo, tarif, disponibilités) afin de prendre une décision éclairée avant de le contacter.

US-11 — En tant qu'élève, je veux envoyer un message au répétiteur avant de confirmer la réservation afin de préciser mes besoins et m'assurer qu'il peut m'aider.

US-12 — En tant qu'élève, je veux réserver un créneau et payer en avance via Mobile Money afin de sécuriser ma séance.

US-13 — En tant qu'élève, je veux choisir un forfait multi-séances avec un prix dégressif afin de m'engager sur du long terme à moindre coût.

US-14 — En tant qu'élève, je veux noter et commenter la séance après qu'elle s'est tenue afin d'aider d'autres élèves à choisir ce répétiteur.

---

### Gestion des réservations (côté répétiteur)

US-15 — En tant que répétiteur, je veux recevoir une notification push immédiate à chaque demande de réservation afin de pouvoir répondre dans le délai imparti.

US-16 — En tant que répétiteur, je veux accepter ou refuser une demande en un geste depuis la notification afin de ne pas perdre de temps.

US-17 — En tant que répétiteur, je veux marquer une séance comme effectuée depuis l'application afin de déclencher la libération des fonds et inviter l'élève à noter.

US-18 — En tant que répétiteur, je veux que WinAI me génère un compte-rendu structuré après chaque séance afin d'envoyer un rapport de qualité à l'élève ou à ses parents sans effort.

US-19 — En tant que répétiteur, je veux voir un planning de mes séances à venir sur une vue calendrier afin de gérer mon agenda facilement.

US-20 — En tant que répétiteur, je veux passer en mode "En vacances" sans perdre mon profil ni mes avis afin de suspendre temporairement les réservations.

---

### Revenus et paiements

US-21 — En tant que répétiteur, je veux voir mes revenus issus des séances et des ventes catalogue agrégés dans un seul tableau de bord afin d'avoir une vision complète de mon activité.

US-22 — En tant que répétiteur, je veux retirer mes revenus disponibles via MTN MoMo ou Orange Money afin d'encaisser mes gains rapidement.

US-23 — En tant que répétiteur, je veux voir le détail de chaque transaction (nom de l'élève, type de prestation, montant brut, commission WinPlus, montant net) afin de tenir ma comptabilité.

---

### Formation enrichie

US-24 — En tant que professeur, je veux programmer le déblocage progressif des leçons (drip content) afin de maintenir l'engagement des élèves sur la durée.

US-25 — En tant que professeur, je veux intégrer des quiz à des timestamps précis dans mes vidéos afin de vérifier la compréhension en temps réel.

US-26 — En tant que professeur, je veux activer la gamification sur une formation (points, badges, classement) afin de motiver mes élèves.

US-27 — En tant que professeur, je veux qu'un certificat vérifiable soit automatiquement généré à la complétion d'une formation afin de valoriser le travail de mes élèves.

US-28 — En tant que professeur, je veux voir à quelle leçon mes élèves décrochent afin d'améliorer le contenu de cette leçon.

US-29 — En tant que professeur, je veux être alerté par WinAI quand un élève est "à risque de décrochage" sur ma formation afin de le relancer proactivement.

---

## III. WORKFLOWS

---

### Workflow 1 — Onboarding Répétiteur

1. Le professeur ouvre ses paramètres de compte et active "Mode Répétiteur"
2. Un assistant d'onboarding en 5 étapes se lance (stepper) :
   - Étape 1 : Matières et niveaux (multiselect)
   - Étape 2 : Modes d'intervention + zones géographiques
   - Étape 3 : Tarif horaire (avec suggestion WinAI) + forfaits optionnels
   - Étape 4 : Disponibilités hebdomadaires + délai de préavis
   - Étape 5 : Bio, vidéo d'intro, upload diplôme (optionnel mais recommandé)
3. À la fin de l'étape 5, WinAI génère une prévisualisation du profil public avec un score de complétude et des recommandations
4. Le répétiteur valide → profil visible dans les résultats de recherche
5. Si diplôme uploadé → envoi en file de vérification admin → badge "Vérifié Diplôme" ajouté après validation

---

### Workflow 2 — Réservation d'une séance (end to end)

1. L'élève cherche un répétiteur (filtres) → ouvre une fiche → consulte disponibilités
2. L'élève envoie un message pré-réservation (optionnel) ou clique directement "Réserver"
3. L'élève choisit un créneau dans le calendrier du répétiteur, sélectionne la durée et le mode
4. Récapitulatif affiché : date, durée, mode, prix total avec commission visible
5. Paiement via Mobile Money → fonds retenus en escrow WinPlus
6. Notification push au répétiteur + email récapitulatif
7. Le répétiteur accepte (ou refuse avec motif)
8. Confirmation envoyée à l'élève avec détails de la session
9. Rappel automatique 24h avant et 1h avant pour les deux parties
10. Post-séance : le répétiteur marque "Séance effectuée"
11. WinPlus libère les fonds (délai de 2h pour contestation)
12. Notification à l'élève pour noter la séance
13. WinAI propose au répétiteur un compte-rendu à envoyer

---

### Workflow 3 — Gestion d'un litige

1. Après la séance, l'élève conteste via un bouton "Signaler un problème"
2. Les fonds restent gelés
3. WinPlus support reçoit le signalement avec l'historique de la messagerie pré-réservation
4. Le support contacte les deux parties dans les 24h
5. Décision : remboursement total, partiel ou libération des fonds au répétiteur

---

### Workflow 4 — Publication d'une formation avec drip content

1. Le professeur crée la formation (onglet Informations comme actuellement)
2. Dans l'onglet Contenu, pour chaque section il définit la règle de déblocage :
   - "Disponible dès l'inscription"
   - "Disponible X jours après l'inscription"
   - "Disponible si score quiz section précédente ≥ X %"
3. Pour chaque leçon vidéo, il peut ajouter des checkpoints : à tel timestamp, une question se pose
4. Il active ou non la gamification : points par leçon, badges, classement
5. Il active ou non le certificat de complétion
6. Soumission pour validation — même flow existant

---

### Workflow 5 — Alerte décrochage et relance élève

1. WinAI surveille en continu les métriques des élèves inscrits sur une formation
2. Si un élève n'a pas ouvert la formation depuis X jours alors qu'il reste des leçons, WinAI génère une alerte pour le professeur
3. Le professeur reçoit une notification : "3 élèves sont inactifs depuis 7 jours sur ta formation [titre]"
4. En un clic, le professeur envoie un message personnalisé (pré-rédigé par WinAI) à ces élèves
5. Le taux de réactivation est mesuré et affiché dans le tableau de bord de la formation

---

## IV. UX — APPLICATION MOBILE (Flutter)

---

### Navigation globale

La barre de navigation basse reste à 6 onglets. Le mode Répétiteur s'intègre dans les onglets existants sans en créer un nouveau : il enrichit les onglets Sessions et Revenus, et ajoute une section dans Accueil.

---

### Onglet Accueil — enrichissement

Le hero du tableau de bord affiche maintenant deux blocs distincts si le mode Répétiteur est actif :

Bloc Professeur Catalogue : contenus publiés, téléchargements, note moyenne.

Bloc Répétiteur : prochaine séance (J-X heures), demandes en attente (badge rouge), revenu séances ce mois.

Un switch rapide en haut du hero permet de basculer l'affichage entre les deux vues pour les utilisateurs qui veulent voir l'une ou l'autre en priorité.

---

### Onglet Sessions — enrichissement

Deux tabs en haut de l'écran : "Formations / Lives" (existant) et "Cours particuliers" (nouveau).

Tab "Cours particuliers" :
- Vue liste des séances à venir avec élève, matière, heure, mode, statut (confirmée / en attente)
- Badge "Demandes en attente (N)" en rouge sur le titre de l'onglet
- Carte de demande : photo élève, matière, niveau, créneau demandé, bouton "Accepter" (vert) et "Refuser" (gris) directement sur la carte — pas de navigation supplémentaire
- Carte de séance confirmée : bouton "Marquer effectuée" visible dès la fin prévue de la séance
- Bouton flottant "Gérer mes disponibilités" qui ouvre la grille hebdomadaire

---

### Vue disponibilités (modal bottom sheet)

Grille 7 jours × plages horaires (matin / après-midi / soir). L'utilisateur tape les cases pour les activer ou désactiver. Un bouton "Reproduire cette semaine" propage la grille indéfiniment. Sauvegarde instantanée à chaque tap — pas de bouton "Enregistrer" séparé.

---

### Fiche répétiteur (vue publique — côté élève dans l'app)

Scroll vertical avec :
- Photo grande, nom, titre, badges, note étoilée
- Bouton "Réserver" sticky en bas de la fiche (toujours visible)
- Section vidéo d'intro (player embarqué)
- Section tarifs et forfaits
- Section disponibilités (calendrier horizontal scrollable sur 14 jours, créneaux libres en vert)
- Section avis (les 3 premiers affichés, bouton "Voir tout")
- Section matières et niveaux

---

### Flow de réservation mobile (3 écrans maximum)

Écran 1 — Choix du créneau : calendrier horizontal, on sélectionne un jour, les créneaux disponibles apparaissent en dessous. On sélectionne l'heure et la durée.

Écran 2 — Récapitulatif + message optionnel : date, heure, durée, mode, prix. Champ message court (100 caractères). Bouton "Payer maintenant".

Écran 3 — Paiement Mobile Money : saisie du numéro, confirmation USSD, écran de succès avec récapitulatif et bouton "Voir ma séance".

---

### Post-séance mobile

Notification push → l'élève ouvre l'app → modal bottom sheet : "Comment s'est passée ta séance avec [Nom] ?" → 5 étoiles + champ texte optionnel → bouton "Envoyer mon avis" → confirmation.

---

### Profil répétiteur — édition mobile

Accessible depuis les paramètres ou depuis un bouton "Modifier mon profil répétiteur" dans l'onglet Accueil. Formulaire paginé en 5 étapes (même structure que l'onboarding). Chaque étape est sauvegardée indépendamment — si l'utilisateur ferme l'app en cours, il reprend là où il en était.

---

## V. UX — APPLICATION WEB (React)

---

### Navigation latérale — enrichissement

Ajout d'une entrée "Cours particuliers" dans la sidebar, entre Sessions et Revenus. Icône calendrier avec badge rouge si des demandes sont en attente.

---

### Vue "Cours particuliers" (web)

Deux colonnes :

Colonne gauche — Demandes en attente : liste des demandes non encore acceptées avec photo élève, matière, niveau, créneau demandé, message joint. Boutons "Accepter" et "Refuser" avec confirmation. Les demandes expirées (délai dépassé) sont grisées et archivées automatiquement.

Colonne droite — Calendrier des séances : calendrier hebdomadaire (même style que la vue Sessions existante) avec les séances de cours particuliers en couleur distincte (violet par exemple, pour les différencier des sessions Lives / Enregistrements / Corrections). Clic sur un bloc → détail de la séance, bouton "Marquer effectuée", lien de session.

---

### Gestion des disponibilités (web)

Page dédiée accessible depuis un bouton dans la vue "Cours particuliers". Grille hebdomadaire complète avec les heures de 6h à 22h. Le répétiteur clique sur les cases pour les activer. Un panneau latéral droit contient les paramètres : délai de préavis, nombre max de séances par semaine, statut "En vacances", politique d'annulation.

---

### Profil public — prévisualisation web

Un bouton "Voir mon profil comme un élève" dans les paramètres ouvre un onglet avec la fiche publique telle qu'elle apparaît dans les résultats de recherche. WinAI affiche un score de complétude (0 à 100) avec les items manquants listés et cliquables (clic → navigue directement vers le champ à compléter).

---

### Tableau de bord revenus — enrichissement web

Le graphique existant ajoute une série "Cours particuliers" en plus de la série "Catalogue". Le tableau de détails distingue les deux sources avec filtrage possible. L'historique des transactions détaille pour les séances : nom de l'élève, matière, durée, montant brut, commission WinPlus (%), montant net.

---

### Éditeur de formation — enrichissements web

Dans l'onglet Contenu de l'éditeur :

Pour chaque section, un selecteur "Règle de déblocage" s'affiche sous le titre de section : "Immédiat", "Après X jours", "Si score ≥ X %".

Pour chaque leçon vidéo, un bouton "Ajouter un checkpoint" ouvre un panneau latéral : saisie du timestamp (format mm:ss) et de la question (même éditeur que le quiz existant).

En bas de l'éditeur, un panneau "Options de formation" contient les toggles : Gamification activée (oui/non), Certificat de complétion (oui/non), Classement visible par les élèves (oui/non).

---
Parfait. Voici le complément complet — messagerie, achat de contenu et IA en profondeur.

---

# Complément — Messagerie, Achat de contenu et WinAI étendu

---

## I. MESSAGERIE — Système de communication complet

---

### Architecture générale

La messagerie WinPlus n'est pas un simple chat élève-professeur. C'est un système à trois niveaux : conversations directes 1-to-1, conversations de groupe, et canaux de classe ou de formation. Tout est interne à la plateforme — aucun lien externe, tout le fil de communication reste sur WinPlus, ce qui protège les deux parties en cas de litige et garde les données sur la plateforme.

---

### Types de conversations

**Conversation directe 1-to-1**

Accessible depuis :
- La liste des élèves liés (liaison directe existante)
- La fiche d'un élève dans une classe
- La fiche d'un répétiteur (côté élève)
- La liste des réservations de cours particuliers
- Un bouton "Message" sur tout profil WinPlus

Ce qui s'envoie dans une conversation directe :
- Texte brut
- Fichiers PDF (épreuves, corrections, fiches)
- Images (photos de cahier, schémas)
- Notes vocales — les plateformes de tutorat qui intègrent les notes vocales réduisent la friction sur mobile car taper du texte mathématique est pénible
- Liens vers un contenu WinPlus (épreuve, correction, formation) — le lien génère une carte de prévisualisation inline
- Lien de session (généré automatiquement à la confirmation d'une réservation)

**Conversation de groupe**

Le professeur crée un groupe depuis une classe ou manuellement en invitant des membres de son réseau. Cas d'usage : groupe de révision, groupe de parents d'élèves d'une classe, groupe de collègues professeurs.

Fonctionnalités du groupe :
- Nom et photo du groupe
- Annonces épinglées en haut du fil (seul le créateur peut épingler)
- Mention @Nom pour notifier un membre spécifique
- Partage de fichiers et de liens WinPlus
- Le créateur peut désactiver les réponses (mode "canal d'annonce" unidirectionnel)

**Canal de formation**

Chaque formation publiée peut avoir un canal dédié activable par le professeur. Les élèves inscrits rejoignent automatiquement. Le professeur y poste des annonces, des ressources complémentaires, des encouragements. Les élèves peuvent poser des questions dans le fil. WinAI peut répondre automatiquement aux questions fréquentes dans ce canal (voir section IA).

---

### Réseau du professeur — qui peut lui écrire

Le réseau d'un professeur sur WinPlus comprend :
- Ses élèves liés (liaison directe)
- Les membres de ses classes
- Les élèves inscrits à ses formations
- Les élèves ayant réservé une séance de cours particulier
- Les autres professeurs avec qui il a échangé ou qu'il suit
- Les membres de groupes communs

En dehors de ce réseau, un utilisateur inconnu ne peut pas envoyer de message directement — il doit d'abord envoyer une demande de contact que le professeur accepte ou refuse. Cela évite le spam.

---

### Fonctionnalités avancées de messagerie

**Réponses contextuelles**
Répondre à un message spécifique dans le fil, avec citation du message original. Essentiel dans les groupes actifs pour garder le contexte.

**Réactions emoji**
Réagir à un message sans encombrer le fil d'un "👍 OK Professeur". Standard sur toutes les plateformes de messagerie modernes.

**Statut de lecture**
Indicateur "Lu" sous les messages directs 1-to-1. Le professeur sait si l'élève a vu le message et inversement.

**Messages programmés**
Rédiger un message et le programmer pour une heure précise. Utile pour envoyer un rappel de session la veille au soir, ou partager une fiche de révision le dimanche soir avant le lundi d'examen.

**Réponses rapides IA**
WinAI analyse le message entrant et propose 2-3 réponses courtes en un tap. Le professeur choisit ou ignore. Exemples : "Oui, c'est bien compris", "On en parlera lors de la prochaine séance", "Envoyez-moi votre travail en PDF". WinAI génère aussi des réponses plus longues sur demande à partir d'un résumé.

**Modèles de messages**
Le professeur enregistre des modèles de messages fréquents : convocation à une session, rappel de correction en attente, félicitations pour un bon score. Il les envoie en deux taps.

**Filtres et recherche**
Recherche textuelle dans toutes les conversations. Filtres : non lus, avec pièces jointes, conversations avec un élève spécifique, par formation ou par classe.

**Archivage**
Archiver une conversation qui n'est plus active sans la supprimer. Elle reste accessible via un onglet "Archivées".

---

### UX Messagerie mobile

Onglet dédié "Messages" dans la barre de navigation basse — à intégrer soit en 7ème onglet soit en remplacement d'un onglet moins utilisé, à discuter selon le contexte WinPlus. Badge de notification (N) sur l'icône.

Écran liste : conversations triées par date du dernier message. Aperçu du dernier message. Swipe gauche → archiver. Swipe droit → marquer comme lu/non lu.

Écran conversation : bulle de composition sticky en bas avec boutons d'attachement (PDF, image, note vocale). Tap long sur un message → répondre, réagir, copier, supprimer.

---

### UX Messagerie web

Panneau latéral droit rétractable accessible depuis toutes les vues, avec badge de notification dans la sidebar. Le professeur peut chatter sans quitter la vue Revenus ou Corrections. En plein écran : interface deux colonnes (liste des conversations à gauche, fil à droite). La fenêtre de composition supporte le Markdown basique pour formater les messages longs.

---

## II. ACHAT DE CONTENU — Le professeur comme acheteur

---

### Positionnement

Le professeur n'est pas uniquement un créateur-vendeur. Il est aussi un acheteur. Deux raisons principales :

Premièrement, il cherche des ressources pour enrichir ses formations ou préparer ses cours particuliers — une épreuve bien construite d'un collègue peut lui servir de support pédagogique ou de devoir à donner.

Deuxièmement, un répétiteur qui couvre des concours spécifiques (ENSP, Polytechnique, FMSB) a besoin d'accéder aux meilleures épreuves disponibles sur la plateforme pour préparer ses élèves.

---

### Catalogue d'achat — fonctionnalités

**Recherche et filtres depuis l'espace professeur**

L'accès au catalogue public est déjà référencé dans la sidebar (raccourci "Catalogue"). Ce qui change : le catalogue doit détecter que l'utilisateur est un professeur et lui proposer une vue enrichie.

Filtres supplémentaires pour le professeur-acheteur :
- Type : Épreuve, Correction, Pack, Formation
- Matière et niveau
- Concours ciblé
- Auteur : uniquement les professeurs "Vérifiés" (pour garantir la qualité pédagogique)
- Note minimale
- Prix : gratuit, accès abonnement, prix libre
- "Populaire dans ma matière" (recommandation WinAI basée sur le profil du professeur)

**Fiche contenu enrichie pour un professeur**

Quand un professeur ouvre la fiche d'un contenu dans le catalogue, il voit en plus des informations standard :
- "X enseignants ont utilisé ce contenu dans leurs formations" — indicateur de confiance professionnelle
- Possibilité de l'ajouter directement comme ressource complémentaire dans l'une de ses formations en cours (bouton "Ajouter à une formation")
- Possibilité de l'assigner comme devoir à une classe (bouton "Assigner à une classe")

**Achat et téléchargement**

Flow identique à l'élève : paiement via Mobile Money ou solde WinPlus (le professeur peut utiliser ses revenus de vente pour acheter du contenu — circuit interne). Historique des achats séparé dans l'onglet Revenus, en section "Achats".

**Bibliothèque personnelle**

Tous les contenus achetés ou téléchargés gratuitement s'accumulent dans une bibliothèque personnelle accessible depuis l'espace professeur. Organisée en dossiers personnalisables. Chaque contenu peut être annoté (notes privées que seul le professeur voit). Un contenu de la bibliothèque peut être partagé dans une conversation de messagerie ou assigné directement à une classe.

**Contenu assigné à une classe**

Quand le professeur assigne un contenu acheté à une classe, les élèves de cette classe y accèdent sans repayer. WinPlus déduit une fois le montant du contenu depuis le compte du professeur et distribue les accès à tous les élèves de la classe. Chaque élève voit le contenu dans son espace comme "Assigné par [Nom du Professeur]".

**WinAI — recommandations d'achat**

WinAI analyse le profil du professeur (matières, niveaux, contenus déjà publiés, historique de ses formations) et propose proactivement des contenus pertinents dans le catalogue :
- "Les professeurs de Terminale C qui publient des contenus de Physique achètent souvent ces 3 épreuves"
- "Cette correction très bien notée couvre exactement les lacunes détectées dans ta classe de Tle D"
- "Ce pack de concours ENSP a été utilisé par 12 répétiteurs ce mois"

---

## III. WINAI — Fonctionnalités IA détaillées et nouvelles

---

### Ce qui existe déjà (rappel du document original)

Génération de quiz, optimisation de titre, génération de description, analyse collective de classe, score d'impact pédagogique, génération de correction type, prédiction de popularité, analyse de soumission d'élève.

---

### Nouvelles fonctionnalités IA — détail complet

---

**WinAI-1 — Génération de plan de cours complet (syllabus)**

Le professeur saisit : matière, niveau, durée totale (ex. 3 mois), objectifs pédagogiques généraux, examens visés. WinAI génère un syllabus structuré semaine par semaine : titre de chaque séance, notions abordées, activités proposées, durée estimée, ressources suggérées depuis le catalogue WinPlus. Le plan est exportable en PDF ou importable directement comme structure d'une formation WinPlus.

User story : En tant que professeur créant une formation de préparation au BAC C, je veux que WinAI me génère un plan de cours sur 3 mois afin de ne pas partir d'une page blanche.

---

**WinAI-2 — Génération de rubrique d'évaluation (barème)**

À partir d'un énoncé collé ou uploadé, WinAI génère automatiquement un barème détaillé question par question : points par sous-question, critères d'attribution partielle, erreurs types pénalisées. Le barème est utilisé ensuite dans le flow de correction pour guider le professeur ou le répétiteur.

User story : En tant que répétiteur corrigeant un devoir de maths Tle C, je veux un barème automatique depuis l'énoncé afin de noter de façon cohérente et équitable.

---

**WinAI-3 — Notation automatique premier niveau (pre-grading)**

Pour les quiz à choix multiples et les questions à réponse courte, WinAI propose une note automatique avec un intervalle de confiance (ex. "Entre 13 et 15 sur 20, à valider"). Pour les questions longues (développement, problèmes), WinAI surligne les éléments présents et absents dans la réponse de l'élève par rapport au barème, et suggère une note que le professeur accepte ou corrige. La décision finale reste toujours au professeur.

User story : En tant que professeur avec 30 copies à corriger, je veux que WinAI me fasse un premier passage de notation afin de réduire mon temps de correction de moitié.

---

**WinAI-4 — Résumé automatique de leçon (pour l'élève)**

Après qu'un élève a complété une leçon vidéo ou un article, WinAI génère automatiquement un résumé des points clés en 5 à 7 bullet points, une liste des formules ou définitions importantes, et 2-3 questions de vérification rapide. Ce résumé est disponible dans l'espace élève mais le professeur peut le désactiver ou le personnaliser pour chaque leçon.

User story : En tant que professeur, je veux que WinAI génère automatiquement un résumé de chaque leçon de ma formation afin que mes élèves aient une fiche de révision prête sans que j'aie à la rédiger séparément.

---

**WinAI-5 — Q&A automatique dans le canal de formation**

Le professeur active l'option "WinAI répond aux questions fréquentes" sur le canal de sa formation. WinAI analyse le contenu de toutes les leçons de la formation et répond automatiquement aux questions des élèves dans le canal avec une mention "Réponse générée par WinAI — à vérifier avec ton professeur". Si WinAI n'est pas sûr de la réponse (confiance inférieure à un seuil), il tague le professeur automatiquement au lieu de répondre. Le professeur voit toutes les interactions IA dans un journal dédié et peut corriger ou compléter une réponse IA en un clic.

User story : En tant que professeur gérant 80 élèves sur une formation, je veux que WinAI réponde aux questions simples dans le canal afin de ne pas être submergé par des demandes répétitives.

---

**WinAI-6 — Analyse comparative de performance (benchmarking)**

WinAI compare les performances d'une classe ou d'un groupe d'élèves d'un professeur avec les moyennes anonymisées de l'ensemble de la plateforme pour le même niveau et la même matière. Le résultat : "Tes élèves de Tle D en Maths sont 12 % en dessous de la moyenne WinPlus pour ce niveau. Les lacunes les plus fréquentes dans ta classe (trigonométrie, suites) sont différentes de la tendance nationale (fonctions dérivées, intégrales). Contenu recommandé pour combler ces écarts : [lien vers 2 épreuves du catalogue]."

User story : En tant que répétiteur préparant un élève au concours ENSP, je veux comparer ses scores aux moyennes des candidats sur la plateforme afin d'identifier où concentrer les efforts restants.

---

**WinAI-7 — Détection de plagiat entre soumissions**

Quand plusieurs élèves d'une même classe soumettent des travaux similaires, WinAI détecte les similarités textuelles et signale au professeur les paires de soumissions suspectes avec un score de similarité. Le professeur décide de la suite. Aucun élève n'est accusé directement — WinAI signale uniquement au professeur.

User story : En tant que professeur recevant 25 copies d'un devoir maison, je veux être alerté si des copies semblent identiques afin d'intervenir si nécessaire.

---

**WinAI-8 — Génération de fiche de révision personnalisée par élève**

Le répétiteur, après plusieurs séances avec un élève, demande à WinAI de générer une fiche de révision personnalisée basée sur les compte-rendus de séances précédents, les scores aux quiz et les erreurs identifiées. La fiche liste : notions à revoir en priorité, exercices recommandés depuis le catalogue WinPlus, méthodes et formules clés à mémoriser. Elle est partagée directement dans la conversation de messagerie avec l'élève.

User story : En tant que répétiteur suivant un élève depuis 2 mois, je veux que WinAI génère une fiche de révision personnalisée avant son examen afin de maximiser son efficacité dans les dernières semaines.

---

**WinAI-9 — Suggestion de contenu à publier (veille éditoriale)**

WinAI analyse en temps réel les tendances de recherche sur WinPlus : quelles matières, quels niveaux et quels concours génèrent le plus de recherches sans résultats satisfaisants. Il alerte le professeur : "Il y a cette semaine 200 élèves qui cherchent des épreuves de Chimie Tle D pour le concours FMSB sans trouver ce qu'ils cherchent. Tu enseignes cette matière — publier maintenant te positionnerait comme première offre sur ce créneau." La prédiction de popularité existante s'appuie sur cette veille.

User story : En tant que professeur de Sciences, je veux que WinAI me signale les besoins du marché non couverts afin de publier au bon moment et maximiser mes téléchargements.

---

**WinAI-10 — Transcription et résumé de session live**

Après une session live ou enregistrée, WinAI transcrit automatiquement l'audio (si la session passe par WinPlus), génère un résumé structuré (points abordés, questions posées par les élèves, décisions prises, devoirs annoncés) et envoie ce résumé aux élèves participants via le canal de messagerie. Le professeur peut éditer le résumé avant envoi.

User story : En tant que professeur ayant donné un cours live de 2h, je veux un résumé automatique de la séance afin que mes élèves aient une trace de ce qu'on a vu sans que j'aie à le retaper.

---

**WinAI-11 — Coach pédagogique pour le répétiteur**

Sur la base de l'historique complet des séances, des avis reçus et des progressions de ses élèves, WinAI génère un rapport mensuel de coaching pour le répétiteur : ses points forts déclarés par les élèves, les matières où ses élèves progressent le plus, les patterns d'amélioration ou de stagnation, des recommandations concrètes sur sa pratique pédagogique (ex. "Tes élèves décrochent en moyenne à la 45ème minute — essaie une pause ou un changement d'activité"). Ce rapport est visible dans le tableau de bord, onglet "Mon coaching WinAI".

User story : En tant que répétiteur voulant améliorer ma pratique, je veux recevoir un rapport mensuel WinAI sur mes performances pédagogiques afin de progresser professionnellement.

---

**WinAI-12 — Génération automatique de communication parents**

Le répétiteur ou le professeur rédige un résumé rapide en langage naturel ("l'élève a bien progressé en trigonométrie, encore des lacunes en géométrie analytique, devoirs à faire pages 45-47") et WinAI le transforme en un message formel et bienveillant adressable aux parents, avec la progression chiffrée, les points positifs soulignés, les axes d'amélioration, et les devoirs clairement listés. Envoyable directement via la messagerie WinPlus ou copié pour un envoi externe.

---

**WinAI-13 — Adaptive difficulty dans les quiz de formation**

Pour les formations avec quiz activé, WinAI ajuste dynamiquement la difficulté des questions proposées à chaque élève selon ses résultats précédents. Un élève qui réussit 90 % des questions reçoit des variantes plus difficiles. Un élève à 40 % reçoit des questions plus accessibles avec des indices progressifs. La difficulté est calibrée sans jamais bloquer la progression — un élève ne peut jamais rester "coincé".

---

**WinAI-14 — Mémoire conversationnelle enrichie**

La mémoire WinAI existante sur mobile est étendue et rendue explicite. Elle mémorise : les matières de prédilection du professeur, son style pédagogique déclaré, ses formats de quiz préférés, ses épreuves et formations publiées, les patterns de ses élèves, et les conversations précédentes. Quand le professeur revient sur WinAI après 3 jours, le chatbot dit "La dernière fois on avait commencé un quiz de Physique Tle C — tu veux qu'on le finalise ?" Ce contexte persistant évite de réexpliquer le contexte à chaque session.

---

**WinAI-15 — Détection de plagiat dans le contenu publié**

Avant qu'une épreuve ou correction soit soumise pour validation, WinAI vérifie si le contenu uploadé présente des similarités importantes avec des ressources déjà présentes sur WinPlus ou dans des bases de données publiques connues. Il signale au professeur les sections similaires et suggère de reformuler ou de citer la source. Ça protège WinPlus contre les publications de contenu plagié et protège le professeur contre une validation refusée.

---

### Récapitulatif de toutes les capacités WinAI pour le professeur-répétiteur

Pour ne rien oublier, voici la liste consolidée des 23 capacités IA :

Existantes : génération de quiz, optimisation de titre, génération de description, analyse collective de classe, score d'impact pédagogique, génération de correction type, prédiction de popularité, analyse de soumission élève, suggestions de commentaires, insights éditoriaux tableau de bord, suggestion de tarif répétiteur, optimisation de profil, compte-rendu de séance, plan de progression multi-séances, détection de décrochage sur formation.

Nouvelles : génération de syllabus/plan de cours, génération de barème, pre-grading automatique, résumé de leçon pour l'élève, Q&A automatique dans le canal de formation, analyse comparative benchmarking, détection de plagiat entre copies, fiche de révision personnalisée par élève, veille éditoriale et suggestion de publication, transcription et résumé de session live, coach pédagogique mensuel, génération de communication parents, adaptive difficulty dans les quiz, mémoire conversationnelle enrichie, détection de plagiat dans le contenu soumis.

---

Je vais rédiger les user stories complètes en couvrant tout — le document mis à jour, les fonctionnalités répétiteur, la messagerie enrichie, les achats et toutes les capacités WinAI qu'on a détaillées.

---

# User Stories — Espace Professeur / Répétiteur WinPlus

Convention de format :
US-[MODULE]-[Numéro] — En tant que [acteur], je veux [action] afin de [bénéfice].
Critères d'acceptation sous chaque story.

---

## MODULE 1 — ONBOARDING ET PROFIL

---

**US-PRO-01**
En tant que nouvel utilisateur choisissant le rôle Professeur, je veux compléter un profil en plusieurs étapes guidées afin d'être opérationnel rapidement sans me perdre dans une longue liste de champs.

Critères d'acceptation :
- L'onboarding est découpé en 5 étapes maximum avec un stepper visuel
- Chaque étape est sauvegardée indépendamment — une fermeture accidentelle ne remet pas à zéro
- Le profil est fonctionnel dès l'étape 3 complétée, les étapes 4 et 5 sont optionnelles
- Un score de complétude (0-100) est affiché à la fin avec les éléments manquants cliquables

---

**US-PRO-02**
En tant que professeur, je veux renseigner mes matières, niveaux et spécialités sur mon profil afin que mes élèves et les algorithmes WinPlus me trouvent facilement.

Critères d'acceptation :
- Multiselect pour les matières (liste exhaustive des matières camerounaises)
- Multiselect pour les niveaux (6ème à Tle, BEPC, BAC, prépas, concours ENSP / Polytechnique / FMSB / ENAM / ENS / ESSEC / ENSET / BTS)
- Champ "Spécialités" en tags libres : "Préparation concours", "Soutien scolaire", "Rattrapage express"
- Les informations sont indexées et visibles dans les résultats de recherche sous 5 minutes après enregistrement

---

**US-PRO-03**
En tant que professeur, je veux uploader mon diplôme ou relevé de notes afin d'obtenir le badge "Vérifié Diplôme" et renforcer ma crédibilité auprès des élèves.

Critères d'acceptation :
- Upload accepte PDF et images (JPG, PNG) jusqu'à 10 Mo
- Le document part en file de vérification admin
- Un email de confirmation est envoyé au professeur dans les 48h
- Le badge "Vérifié Diplôme" s'affiche sur le profil public après validation
- En cas de refus, un motif est communiqué et un nouveau dépôt est possible

---

**US-PRO-04**
En tant que professeur, je veux que WinAI analyse mon profil et me suggère des améliorations concrètes afin d'optimiser ma visibilité dans le catalogue et les recherches d'élèves.

Critères d'acceptation :
- L'analyse WinAI est déclenchable en un tap depuis les paramètres du profil
- WinAI identifie les champs manquants ou trop courts
- Chaque suggestion est accompagnée d'une explication et d'un bouton "Compléter" qui navigue directement vers le champ concerné
- L'analyse inclut une comparaison avec les profils les mieux notés dans la même matière

---

**US-PRO-05**
En tant que professeur voulant activer le mode Répétiteur, je veux un onboarding dédié en 5 étapes afin de configurer mon profil de répétiteur sans confondre les deux modes d'exercice.

Critères d'acceptation :
- L'activation se fait depuis les paramètres du compte, section "Modes d'exercice"
- Les 5 étapes couvrent : matières et niveaux, modes d'intervention et zones géographiques, tarif horaire et forfaits, disponibilités hebdomadaires, bio et vidéo d'intro
- WinAI suggère un tarif horaire contextualisé pendant l'étape 3
- À la fin, une prévisualisation du profil public est affichée avant activation
- Le profil répétiteur est visible dans la recherche immédiatement après activation

---

**US-PRO-06**
En tant que répétiteur, je veux ajouter un lien vers une courte vidéo de présentation afin que les élèves puissent évaluer mon style pédagogique avant de réserver une séance.

Critères d'acceptation :
- Champ URL acceptant YouTube, Vimeo ou upload direct (max 100 Mo)
- La vidéo s'affiche en lecteur embarqué sur la fiche publique
- Si le lien est invalide, un message d'erreur clair est affiché
- La vidéo est optionnelle — son absence n'empêche pas l'activation du profil répétiteur

---

**US-PRO-07**
En tant que répétiteur, je veux définir mes zones géographiques d'intervention afin que seuls les élèves dans mes zones puissent me trouver pour des cours à domicile.

Critères d'acceptation :
- Sélection par quartiers et communes (liste prédéfinie pour Douala, Yaoundé et autres villes)
- Option "En ligne uniquement" qui désactive la sélection géographique
- Option "À domicile chez moi" avec saisie d'adresse approximative (quartier, pas adresse exacte)
- Les zones sont modifiables à tout moment depuis les paramètres

---

**US-PRO-08**
En tant que répétiteur, je veux définir mes disponibilités hebdomadaires et mon délai de préavis minimum afin de ne recevoir que des demandes compatibles avec mon agenda.

Critères d'acceptation :
- Grille hebdomadaire 7 jours × plages horaires (matin/après-midi/soir ou par heure)
- Tap sur une case pour activer/désactiver — sauvegarde instantanée sans bouton "Enregistrer"
- Bouton "Reproduire cette semaine" qui propage la grille indéfiniment
- Choix du délai de préavis : 12h, 24h, 48h
- Choix du nombre max de séances par semaine (le calendrier se ferme automatiquement quand le max est atteint)

---

**US-PRO-09**
En tant que répétiteur, je veux activer un statut "En vacances" afin de suspendre temporairement les réservations sans perdre mon profil, mes avis ni mon historique.

Critères d'acceptation :
- Bouton "En vacances" accessible depuis les paramètres ou le tableau de bord
- Quand activé, le profil reste visible dans la recherche mais affiche "Indisponible pour le moment"
- Aucune nouvelle réservation n'est possible pendant ce statut
- Les séances déjà confirmées avant activation ne sont pas annulées
- Désactivation en un clic avec retour immédiat à la disponibilité normale

---

**US-PRO-10**
En tant que répétiteur, je veux proposer des forfaits multi-séances avec tarif dégressif afin d'encourager les élèves à s'engager sur le long terme.

Critères d'acceptation :
- Le répétiteur définit jusqu'à 3 forfaits : ex. "Pack 5 séances", "Pack 10 séances"
- Chaque forfait a un prix global (inférieur à la somme des séances individuelles)
- Les forfaits sont affichés clairement sur la fiche publique du répétiteur
- À l'achat d'un forfait, un compteur de séances restantes est visible pour les deux parties
- Une alerte est envoyée quand il reste 2 séances dans le forfait avec suggestion de renouvellement

---

**US-PRO-11**
En tant que répétiteur, je veux proposer une séance d'essai à tarif réduit ou gratuite afin de réduire la barrière d'entrée pour les nouveaux élèves.

Critères d'acceptation :
- Case à cocher "Proposer une séance d'essai" dans le profil répétiteur
- Prix de l'essai libre ou zéro (gratuit)
- Chaque élève ne peut bénéficier qu'une fois de la séance d'essai avec un même répétiteur
- La séance d'essai apparaît clairement sur la fiche publique avec une étiquette distinctive

---

## MODULE 2 — CATALOGUE ET ACHAT DE CONTENU

---

**US-CAT-01**
En tant que professeur, je veux rechercher des contenus dans le catalogue par mot-clé, type, examen, matière, année et prix afin de trouver rapidement les ressources dont j'ai besoin pour préparer mes cours ou mes élèves.

Critères d'acceptation :
- La recherche textuelle a un délai de frappe de 400ms avant déclenchement
- Les filtres disponibles : type (Épreuve, Correction, Quiz, Livre, Pack), examen (BEPC, BAC, Probatoire, ENS, ENSET, Polytechnique, ENAM, FMSB, ESSEC, BTS), matière, plage d'années, niveau de difficulté, prix (tout/gratuit/payant)
- Les tris disponibles : popularité, date, note, prix croissant, prix décroissant
- Les résultats peuvent être affichés en grille ou en liste
- Le nombre de résultats est affiché en temps réel

---

**US-CAT-02**
En tant que professeur, je veux voir sur la fiche d'un contenu combien d'enseignants l'ont utilisé dans leurs formations afin d'évaluer sa pertinence pédagogique professionnelle en plus des avis d'élèves.

Critères d'acceptation :
- Un compteur "X enseignants ont utilisé ce contenu dans leurs formations" est affiché sur la fiche
- Ce compteur est distinct du compteur de téléchargements général
- Il n'est visible que pour les utilisateurs connectés avec un rôle professeur

---

**US-CAT-03**
En tant que professeur, je veux ajouter un contenu acheté directement dans l'une de mes formations depuis sa fiche catalogue afin d'intégrer des ressources tierces dans mon cours sans quitter le flux de navigation.

Critères d'acceptation :
- Un bouton "Ajouter à une formation" est visible sur la fiche d'un contenu déjà acheté
- Un sélecteur liste les formations en brouillon du professeur
- Le contenu est ajouté comme leçon de type "Fichier" dans la section choisie
- Si le contenu n'est pas encore acheté, le bouton affiche "Acheter pour ajouter à une formation"

---

**US-CAT-04**
En tant que professeur, je veux assigner un contenu acheté à une de mes classes afin que tous mes élèves y accèdent sans que chacun paye individuellement.

Critères d'acceptation :
- Un bouton "Assigner à une classe" est visible sur la fiche d'un contenu déjà acheté
- Le professeur sélectionne une ou plusieurs classes parmi les siennes
- WinPlus déduit une fois le montant du contenu depuis le solde du professeur (ou effectue un achat unique)
- Tous les élèves de la classe voient le contenu dans leur espace avec la mention "Assigné par [Nom du Professeur]"
- Une confirmation du coût est affichée avant validation

---

**US-CAT-05**
En tant que professeur, je veux disposer d'une bibliothèque personnelle regroupant tous mes achats et téléchargements gratuits afin de retrouver facilement mes ressources sans retourner dans le catalogue.

Critères d'acceptation :
- La bibliothèque est accessible depuis la sidebar sous le nom "Ma bibliothèque"
- Les contenus sont organisables en dossiers personnalisables créés par le professeur
- Chaque contenu peut être annoté avec des notes privées (max 300 caractères) visibles uniquement par le professeur
- Un champ de recherche filtre les contenus de la bibliothèque par titre, matière ou niveau
- Un contenu de la bibliothèque peut être partagé dans une conversation de messagerie en un geste

---

**US-CAT-06**
En tant que professeur, je veux utiliser mon solde de revenus WinPlus pour acheter des contenus dans le catalogue afin d'éviter une transaction Mobile Money supplémentaire.

Critères d'acceptation :
- À l'étape de paiement du panier, une option "Payer avec mon solde WinPlus" est proposée si le solde est suffisant
- Si le solde est insuffisant, le différentiel est proposé en paiement Mobile Money complémentaire
- La transaction est enregistrée dans l'historique des débits du tableau de bord Revenus

---

**US-CAT-07**
En tant que professeur, je veux que WinAI me recommande proactivement des contenus pertinents dans le catalogue afin de découvrir des ressources utiles sans avoir à chercher manuellement.

Critères d'acceptation :
- Les recommandations WinAI sont affichées dans le tableau de bord, section "Recommandé pour toi"
- Les critères de recommandation : matières et niveaux du professeur, contenus de ses formations, lacunes détectées dans ses classes, tendances de recherche non satisfaites sur la plateforme
- Chaque recommandation est accompagnée d'une justification courte ("Tes élèves de Tle D ont des difficultés en trigonométrie — ce contenu est très bien noté sur ce thème")
- Le professeur peut masquer une recommandation ("Pas intéressé")

---

**US-CAT-08**
En tant que professeur, je veux ajouter des tags personnels et des notes sur les contenus consultés afin d'organiser ma veille pédagogique selon mes propres critères.

Critères d'acceptation :
- Tags disponibles : "À réviser", "Difficile", "Maîtrisé", "À acheter", plus tags libres personnalisables
- Notes texte libres jusqu'à 150 caractères par contenu
- Les annotations sont conservées entre les sessions
- Un filtre "Mes annotations" dans le catalogue affiche uniquement les contenus annotés

---

**US-CAT-09**
En tant que professeur, je veux accéder au hub des concours camerounais afin de trouver toutes les épreuves par examen, matière et année sur une seule page organisée.

Critères d'acceptation :
- Page dédiée listant : ENS, Polytechnique, ENAM, FMSB, ESSEC, ENSET, BAC, BEPC, Probatoire, BTS
- Chaque concours a sa propre page avec épreuves filtrables par année et matière, conseils de réussite, FAQ et calendrier des prochaines sessions
- Les sous-pages par matière permettent d'affiner la navigation
- Le contenu du hub est accessible sans abonnement payant

---

## MODULE 3 — PUBLICATION DE CONTENUS

---

**US-PUB-01**
En tant que professeur, je veux publier une épreuve en suivant un processus en 4 étapes clair afin de ne pas oublier d'informations importantes et de maximiser mes chances de validation.

Critères d'acceptation :
- Étape 1 : choix du type parmi Épreuve, Correction, Livre, Quiz, Pack
- Étape 2 : métadonnées complètes (titre min 5 caractères, matière, niveau, examen ciblé, année, prix, description max 500 caractères, difficulté)
- Étape 3 : upload fichier PDF max 50 Mo avec barre de progression, ou éditeur de quiz
- Étape 4 : prévisualisation complète avant soumission
- Navigation entre étapes sans perte de données
- Soumission place le contenu en statut "En révision"

---

**US-PUB-02**
En tant que professeur, je veux qu'à chaque étape de publication WinAI puisse m'assister afin de publier un contenu de meilleure qualité sans effort supplémentaire.

Critères d'acceptation :
- Étape 2 : bouton "Optimiser avec WinAI" sur le champ titre — génère une suggestion avec justification, acceptation en un clic
- Étape 2 : bouton "Générer une description" — produit 2-3 phrases à partir des métadonnées saisies
- Étape 3 (quiz) : bouton "Suggérer 10 questions" — génère des QCM calibrés pour l'examen ciblé, sélection individuelle avant import
- Étape 3 (correction) : bouton "Générer une correction type" — structure la correction question par question depuis l'énoncé collé
- Étape 4 : prédiction de popularité automatique (téléchargements estimés sur 30 jours, prix recommandé, meilleures ventes comparables, timing optimal)

---

**US-PUB-03**
En tant que professeur, je veux voir le score d'impact pédagogique de chacun de mes contenus publiés afin de savoir lesquels ont le plus d'effet sur la progression de mes élèves.

Critères d'acceptation :
- Score affiché en badge sur chaque carte de contenu dans "Mes contenus"
- Code couleur : vert si ≥ 70, orange entre 50 et 70, rouge en dessous
- Clic sur le badge → explication détaillée des 4 composantes du score (taux de complétion, amélioration avant/après, taux de rétention, note moyenne)
- Le score se met à jour automatiquement à chaque nouvelle donnée

---

**US-PUB-04**
En tant que professeur, je veux que WinAI me signale les créneaux éditoriaux non couverts sur la plateforme afin de publier le bon contenu au bon moment et maximiser mes téléchargements.

Critères d'acceptation :
- Notification proactive dans le tableau de bord ou dans WinAI chatbot
- Le message précise : la matière, le niveau, l'examen, le volume de recherches sans résultat satisfaisant cette semaine
- Un bouton "Publier sur ce sujet" pré-remplit les champs de la publication avec ces informations
- Les alertes éditoriales sont personnalisées selon les matières du professeur

---

**US-PUB-05**
En tant que professeur, je veux modifier, archiver ou supprimer mes contenus publiés afin de maintenir mon catalogue personnel propre et à jour.

Critères d'acceptation :
- Modification possible pour tous les statuts sauf "En révision"
- Archivage : le contenu disparaît du catalogue public mais reste dans la liste du professeur
- Suppression définitive : uniquement si aucune vente enregistrée, avec confirmation explicite
- Changement de statut immédiat avec appel serveur synchrone et feedback visuel

---

## MODULE 4 — CORRECTIONS

---

**US-COR-01**
En tant que professeur, je veux voir une file priorisée de toutes les soumissions en attente afin de traiter en priorité les corrections les plus urgentes sans en oublier.

Critères d'acceptation :
- Les soumissions en attente depuis plus de 48h sont signalées par un badge rouge "Urgent"
- La file est triée par ancienneté par défaut
- Filtres disponibles : toutes, en attente, déjà corrigées
- Le nombre exact de corrections à faire est affiché en badge sur l'onglet

---

**US-COR-02**
En tant que professeur, je veux que WinAI analyse automatiquement chaque soumission afin de me proposer une note et un commentaire que je n'ai qu'à valider ou ajuster.

Critères d'acceptation :
- L'analyse WinAI se déclenche automatiquement à l'ouverture d'une soumission
- Le résultat affiche : type d'erreur (méthodologique / de calcul / conceptuelle / aucune), détail de l'erreur, commentaire bienveillant suggéré, note proposée sur 20
- Le professeur peut accepter la note et le commentaire en un clic
- Le professeur peut modifier librement la note et le commentaire
- Des formulations alternatives sont proposées en chips cliquables
- La décision finale est toujours celle du professeur

---

**US-COR-03**
En tant que professeur, je veux que WinAI détecte les similarités entre les copies de mes élèves afin d'être alerté en cas de plagiat potentiel sans accuser un élève directement.

Critères d'acceptation :
- L'analyse de similarité est déclenchée automatiquement quand plusieurs soumissions arrivent pour le même exercice
- WinAI signale uniquement au professeur les paires de soumissions avec un score de similarité élevé (≥ 70 %)
- Aucun élève n'est notifié — la détection est un outil pour le professeur, pas une sanction automatique
- Le professeur peut marquer une alerte comme "Faux positif" pour l'exclure

---

**US-COR-04**
En tant que professeur, je veux enregistrer une correction en brouillon afin de pouvoir la compléter plus tard sans perdre mon travail en cours.

Critères d'acceptation :
- Bouton "Enregistrer en brouillon" disponible à tout moment dans l'interface de correction
- Le brouillon est signalé dans la file par un badge "Brouillon"
- À la réouverture, la note et le commentaire saisis précédemment sont restaurés
- Un brouillon non envoyé depuis 72h génère une alerte au professeur

---

**US-COR-05**
En tant que professeur, je veux que WinAI génère un barème détaillé depuis l'énoncé d'un exercice afin de noter de façon cohérente et équitable entre tous les élèves.

Critères d'acceptation :
- Le professeur colle ou uploade le texte de l'énoncé
- WinAI génère un barème structuré : points par sous-question, critères d'attribution partielle, erreurs types pénalisées
- Le barème est visible en panneau latéral pendant toute la session de correction
- Le barème peut être modifié avant utilisation

---

**US-COR-06**
En tant que professeur, je veux que WinAI propose un premier passage de notation automatique sur les QCM et réponses courtes afin de réduire mon temps de correction.

Critères d'acceptation :
- Pour les quiz à choix multiples : notation automatique directe avec score final
- Pour les réponses courtes : WinAI propose une note avec intervalle de confiance ("Entre 13 et 15/20, à valider")
- Pour les développements longs : WinAI surligne les éléments présents/absents par rapport au barème et suggère une note
- La décision finale reste toujours au professeur — aucune note n'est envoyée à l'élève sans validation manuelle

---

## MODULE 5 — SESSIONS

---

**US-SES-01**
En tant que professeur, je veux créer une session live, d'enregistrement ou de correction avec toutes ses caractéristiques afin de planifier mes enseignements en ligne de façon structurée.

Critères d'acceptation :
- Champs obligatoires : titre, type, matière, niveau, date, heure, durée (30 à 180 min par pas de 15)
- Champs optionnels : nombre max de participants (1 à 100), gratuite/payante (prix en XAF), lien externe
- La session créée apparaît dans le calendrier hebdomadaire avec un code couleur selon le type
- Une session payante déclenche un flow de paiement pour les participants

---

**US-SES-02**
En tant que professeur, je veux voir toutes mes sessions dans un calendrier hebdomadaire afin d'avoir une vision d'ensemble de mon planning d'enseignement.

Critères d'acceptation :
- Vue hebdomadaire du lundi au dimanche, plage horaire de 6h à 22h
- Les sessions sont positionnées selon leur heure de début et leur durée
- Code couleur : Live en bleu, Enregistrement en vert, Correction en orange, Cours particulier en violet
- Clic sur un bloc → détail complet de la session avec inscrits, revenus et lien

---

**US-SES-03**
En tant que professeur, je veux annuler une session avec notification automatique à tous les inscrits afin de gérer les imprévus sans avoir à contacter chaque participant manuellement.

Critères d'acceptation :
- Bouton "Annuler la session" avec confirmation explicite ("Cette action est irréversible")
- Après confirmation : notification push + email à tous les inscrits dans les 5 minutes
- Si la session était payante : remboursement automatique initié vers le moyen de paiement original
- La session annulée reste dans l'historique avec le statut "Annulée"

---

**US-SES-04**
En tant que professeur, je veux que WinAI transcrive et résume automatiquement mes sessions live afin d'envoyer un compte-rendu à mes élèves sans effort de rédaction.

Critères d'acceptation :
- La transcription est déclenchée automatiquement si la session passe par WinPlus
- Le résumé généré couvre : points abordés, questions posées par les élèves, décisions prises, devoirs annoncés
- Le professeur peut éditer le résumé avant envoi
- Envoi possible directement dans le canal de messagerie de la classe ou de la formation

---

## MODULE 6 — COURS PARTICULIERS (MODE RÉPÉTITEUR)

---

**US-REP-01**
En tant qu'élève, je veux rechercher un répétiteur par matière, niveau, mode d'intervention et localisation afin de trouver rapidement celui qui correspond à ma situation.

Critères d'acceptation :
- Filtres disponibles : matière, niveau, mode (à domicile / en ligne / mixte), quartier/commune, tarif horaire max, disponibilité ("ce week-end", "en soirée", "dès aujourd'hui"), note minimale, badge "Vérifié" uniquement
- Les résultats sont triés par défaut par pertinence (note × volume de séances × taux de réactivité)
- Chaque résultat affiche : photo, nom, titre, note, tarif horaire, badge vérifié, prochain créneau disponible
- La recherche géographique est disponible uniquement pour le mode "à domicile"

---

**US-REP-02**
En tant qu'élève, je veux accéder à la fiche complète d'un répétiteur afin de prendre une décision éclairée avant de le contacter.

Critères d'acceptation :
- La fiche affiche : photo, nom, titre, badges, note globale et nombre d'avis, bio, vidéo d'intro, tarifs et forfaits, disponibilités (calendrier horizontal 14 jours), avis vérifiés (3 en preview + "Voir tout"), matières et niveaux, zones d'intervention, politique d'annulation
- Le bouton "Réserver" est sticky en bas de la fiche — visible sans scroller
- Les créneaux disponibles sont affichés en vert, les indisponibles en gris

---

**US-REP-03**
En tant qu'élève, je veux envoyer un message au répétiteur avant de confirmer la réservation afin de préciser mes besoins et m'assurer qu'il peut m'aider.

Critères d'acceptation :
- Un bouton "Envoyer un message" est disponible sur la fiche avant toute réservation
- La conversation pré-réservation est accessible depuis la messagerie WinPlus
- Le répétiteur peut répondre depuis son onglet Messages ou depuis la notification
- La messagerie pré-réservation est conservée et devient la conversation officielle si la réservation est confirmée

---

**US-REP-04**
En tant qu'élève, je veux réserver une séance en 3 étapes maximum et payer en avance afin de sécuriser ma place sans processus complexe.

Critères d'acceptation :
- Étape 1 : sélection du créneau dans le calendrier du répétiteur
- Étape 2 : récapitulatif (date, heure, durée, mode, prix total commission incluse) + champ message optionnel (100 caractères)
- Étape 3 : paiement Mobile Money avec suivi du statut toutes les 3 secondes jusqu'à confirmation
- Écran de succès avec récapitulatif et bouton "Voir ma séance"
- Les fonds sont retenus en escrow jusqu'à confirmation post-séance

---

**US-REP-05**
En tant que répétiteur, je veux recevoir une notification push immédiate à chaque demande de réservation afin de pouvoir accepter ou refuser dans le délai imparti.

Critères d'acceptation :
- Notification push dans les 30 secondes après la demande de l'élève
- La notification inclut : nom de l'élève, matière, niveau, créneau demandé
- Depuis la notification, deux boutons directs : "Accepter" et "Refuser" sans ouvrir l'app
- Si le répétiteur ne répond pas dans le délai de préavis défini : la demande expire et l'élève est notifié avec remboursement automatique si paiement effectué

---

**US-REP-06**
En tant que répétiteur, je veux marquer une séance comme effectuée afin de déclencher la libération des fonds retenus en escrow.

Critères d'acceptation :
- Bouton "Marquer comme effectuée" visible sur la carte de la séance dès l'heure de fin prévue
- Après marquage : délai de 2h pendant lequel l'élève peut contester
- Sans contestation dans les 2h : fonds libérés automatiquement vers le solde WinPlus du répétiteur
- L'élève reçoit une invitation à noter la séance dès que les fonds sont libérés

---

**US-REP-07**
En tant que répétiteur, je veux que WinAI génère automatiquement un compte-rendu de séance structuré afin d'envoyer un rapport de qualité à l'élève ou à ses parents sans effort de rédaction.

Critères d'acceptation :
- Après marquage de la séance comme effectuée, WinAI propose automatiquement un compte-rendu
- Le professeur saisit un résumé rapide en langage naturel (2-3 lignes) ou valide sans input
- WinAI génère un message formel structuré : notions abordées, points bien assimilés, points à retravailler, devoirs suggérés
- Le compte-rendu est envoyable directement dans la conversation de messagerie avec l'élève en un tap

---

**US-REP-08**
En tant qu'élève, je veux noter et commenter une séance après qu'elle s'est tenue afin d'aider d'autres élèves à choisir ce répétiteur et de donner du feedback.

Critères d'acceptation :
- Invitation à noter envoyée par notification push après libération des fonds
- Interface de notation : 5 étoiles + champ commentaire optionnel (300 caractères max)
- Un élève ne peut noter qu'une fois par séance
- Seuls les élèves ayant eu une séance confirmée peuvent laisser un avis — les avis anonymes ou non vérifiés sont impossibles
- Le répétiteur peut répondre publiquement à chaque avis depuis son profil

---

**US-REP-09**
En tant que répétiteur, je veux gérer un litige avec un élève via WinPlus afin de ne pas perdre mes revenus en cas de contestation injustifiée.

Critères d'acceptation :
- L'élève peut contester dans les 2h suivant le marquage "Effectuée"
- À la contestation : les fonds restent gelés, les deux parties reçoivent une notification
- WinPlus support reçoit le dossier avec l'historique complet de la messagerie pré et post séance
- Le support contacte les deux parties dans les 24h
- Décision possible : remboursement total, partiel ou libération des fonds au répétiteur
- Les deux parties reçoivent la décision par notification et email

---

**US-REP-10**
En tant que répétiteur, je veux voir mes revenus de cours particuliers agrégés avec mes revenus catalogue dans un seul tableau de bord afin d'avoir une vision complète de mon activité.

Critères d'acceptation :
- Le graphique de revenus affiche deux séries distinctes : "Catalogue" et "Cours particuliers"
- Le tableau de détail liste séparément les transactions catalogue et les transactions cours particuliers
- Pour les cours particuliers : nom de l'élève, matière, durée, montant brut, commission WinPlus (%), montant net
- Le solde disponible agrège les deux sources

---

**US-REP-11**
En tant que répétiteur, je veux que WinAI génère une fiche de révision personnalisée pour un élève afin de maximiser son efficacité dans les semaines précédant un examen.

Critères d'acceptation :
- Accessible depuis la fiche de l'élève dans l'onglet "Cours particuliers"
- WinAI analyse : compte-rendus des séances précédentes, scores aux quiz, erreurs identifiées
- La fiche générée liste : notions à revoir en priorité, exercices recommandés depuis le catalogue WinPlus, méthodes et formules clés
- La fiche est partageable directement dans la conversation de messagerie avec l'élève
- Le professeur peut modifier la fiche avant envoi

---

**US-REP-12**
En tant que répétiteur, je veux recevoir un rapport mensuel WinAI sur mes performances pédagogiques afin de progresser professionnellement en identifiant mes points forts et axes d'amélioration.

Critères d'acceptation :
- Rapport généré automatiquement le 1er de chaque mois
- Contenu : points forts relevés dans les avis élèves, matières où les élèves progressent le plus, patterns de stagnation, recommandations concrètes sur la pratique pédagogique
- Le rapport est accessible depuis le tableau de bord, onglet "Mon coaching WinAI"
- Le professeur peut partager le rapport (PDF) ou le garder privé

---

## MODULE 7 — MESSAGERIE

---

**US-MSG-01**
En tant que professeur, je veux envoyer un message direct à n'importe quel membre de mon réseau (élèves liés, membres de mes classes, inscrits à mes formations, élèves ayant réservé une séance) afin de communiquer sans sortir de WinPlus.

Critères d'acceptation :
- La messagerie est accessible depuis la sidebar (web) et depuis un onglet dédié (mobile)
- Un utilisateur hors réseau ne peut pas envoyer de message direct sans avoir envoyé une demande de contact acceptée
- Les messages sont chiffrés en transit
- Un badge indique le nombre de messages non lus

---

**US-MSG-02**
En tant que professeur, je veux envoyer des fichiers PDF, images et notes vocales dans mes conversations afin de partager des ressources pédagogiques naturellement dans le fil de discussion.

Critères d'acceptation :
- PDF jusqu'à 20 Mo par fichier
- Images JPG/PNG jusqu'à 10 Mo
- Notes vocales jusqu'à 5 minutes, enregistrées directement dans l'app mobile
- Un lien vers un contenu WinPlus génère une carte de prévisualisation inline (titre, type, note)
- Le lien de session (cours particulier) génère une carte spéciale avec les détails de la séance

---

**US-MSG-03**
En tant que professeur, je veux créer des groupes de messagerie pour mes classes, mes groupes de révision ou mes collègues afin de communiquer avec plusieurs personnes en même temps.

Critères d'acceptation :
- Le professeur crée un groupe depuis une classe existante (import automatique des membres) ou manuellement
- Chaque groupe a un nom, une photo optionnelle et un créateur-administrateur
- Le créateur peut épingler des messages d'annonce en haut du fil
- Le créateur peut activer le mode "Canal d'annonce" — seul lui peut envoyer des messages, les membres ne peuvent que réagir
- Mentions @Nom pour notifier un membre spécifique

---

**US-MSG-04**
En tant que professeur, je veux activer un canal de messagerie pour chaque formation afin que mes élèves inscrits puissent poser des questions et recevoir mes annonces dans un espace dédié.

Critères d'acceptation :
- Activation depuis l'éditeur de formation, onglet Paramètres
- Les élèves inscrits rejoignent automatiquement le canal
- Le professeur peut poster des annonces, fichiers et liens
- Les élèves peuvent poster des questions
- WinAI peut répondre automatiquement aux questions fréquentes si l'option est activée par le professeur (voir US-AI-05)

---

**US-MSG-05**
En tant que professeur, je veux répondre à un message spécifique dans le fil de discussion afin de garder le contexte clair dans les groupes actifs.

Critères d'acceptation :
- Tap long (mobile) ou clic droit (web) sur un message → menu d'actions : Répondre, Réagir, Copier, Supprimer
- La réponse affiche le message original en citation au-dessus
- Les réactions emoji sont disponibles (set limité : 👍❤️😄😮😢)
- Le statut "Lu" est affiché sous les messages en conversation 1-to-1

---

**US-MSG-06**
En tant que professeur, je veux programmer l'envoi d'un message à une heure précise afin d'envoyer des rappels et des ressources au bon moment sans devoir être disponible à cet instant.

Critères d'acceptation :
- Option "Programmer l'envoi" disponible via tap long sur le bouton d'envoi
- Sélecteur de date et heure (minimum 15 minutes dans le futur)
- Les messages programmés sont listés dans une section dédiée "À envoyer"
- Un message programmé peut être annulé avant son heure d'envoi
- Les messages programmés sont envoyés même si le professeur est hors ligne

---

**US-MSG-07**
En tant que professeur, je veux que WinAI me propose des réponses rapides contextuelles à chaque message reçu afin de répondre efficacement sans rédiger chaque réponse depuis zéro.

Critères d'acceptation :
- 3 suggestions de réponse courte affichées sous chaque message reçu
- Les suggestions sont contextuelles au contenu du message
- Exemples : "Oui, c'est correct", "On en parlera lors de la prochaine séance", "Envoyez-moi votre travail en PDF"
- Tap sur une suggestion → pré-remplit le champ de composition, le professeur peut modifier avant envoi
- Un bouton "Générer une réponse longue avec WinAI" est disponible pour les messages complexes

---

**US-MSG-08**
En tant que professeur, je veux enregistrer des modèles de messages fréquents afin d'envoyer des communications récurrentes en deux taps sans les retaper à chaque fois.

Critères d'acceptation :
- Section "Mes modèles" accessible depuis les paramètres de messagerie
- Jusqu'à 20 modèles enregistrables avec un nom et le texte
- Variables dynamiques supportées : {{NomEleve}}, {{DateSession}}, {{Matière}}
- Accès aux modèles depuis un bouton dans la fenêtre de composition

---

**US-MSG-09**
En tant que professeur, je veux rechercher dans toutes mes conversations afin de retrouver un message ou une pièce jointe spécifique sans scroller manuellement.

Critères d'acceptation :
- Recherche textuelle dans toutes les conversations
- Filtres de recherche : non lus, avec pièces jointes, par conversation spécifique, par période
- Les résultats affichent le message dans son contexte (5 messages avant et après)
- Les pièces jointes trouvées sont prévisualisables directement depuis les résultats

---

**US-MSG-10**
En tant que professeur, je veux que WinAI génère une communication formelle destinée aux parents d'élèves afin de leur envoyer un rapport professionnel sans effort de mise en forme.

Critères d'acceptation :
- Le professeur tape un résumé libre en langage naturel (2-3 lignes)
- WinAI génère un message formel et bienveillant incluant : progression chiffrée, points positifs soulignés, axes d'amélioration, devoirs listés
- Le message généré est éditable avant envoi
- Envoi possible directement dans la conversation WinPlus ou copie dans le presse-papier pour envoi externe

---

## MODULE 8 — GESTION DES CLASSES

---

**US-CLA-01**
En tant que professeur, je veux créer une classe avec un nom, un niveau, une année académique et une description afin d'organiser mes élèves en groupes cohérents.

Critères d'acceptation :
- Champs obligatoires : nom, niveau, année académique
- Champ optionnel : description (300 caractères)
- La classe créée apparaît immédiatement dans la liste
- Une classe peut être modifiée, désactivée (sans suppression) ou supprimée (uniquement si vide)

---

**US-CLA-02**
En tant que professeur, je veux ajouter un élève à ma classe par son adresse email WinPlus afin de constituer mon groupe sans que l'élève ait besoin de faire une demande.

Critères d'acceptation :
- Champ email avec validation immédiate (l'adresse doit correspondre à un compte WinPlus existant)
- Détection des doublons : un élève déjà dans la classe ne peut pas être ajouté une deuxième fois
- L'élève reçoit une notification d'ajout à la classe
- Un élève peut être retiré à tout moment par le professeur

---

**US-CLA-03**
En tant que professeur, je veux voir la moyenne de classe colorée et les scores individuels de chaque élève afin d'identifier rapidement les élèves en difficulté.

Critères d'acceptation :
- Moyenne de classe calculée depuis les tentatives de quiz réelles
- Code couleur : vert au-dessus de 70 %, orange entre 50 et 70 %, rouge en dessous
- Liste des élèves avec : avatar, nom, score moyen, icône de tendance (hausse/baisse/stable)
- Clic sur un élève → fiche détaillée avec historique de ses tentatives et progression

---

**US-CLA-04**
En tant que professeur, je veux assigner un contenu du catalogue à toute une classe en un geste afin que mes élèves y accèdent directement dans leur espace.

Critères d'acceptation :
- Bouton "Assigner un contenu" sur la page de détail d'une classe
- Le professeur choisit depuis le catalogue ou depuis sa bibliothèque personnelle
- Le coût est déduit une fois du compte du professeur, non de chaque élève
- Les élèves voient le contenu avec la mention "Assigné par [Nom]" dans leur espace

---

## MODULE 9 — FORMATIONS STRUCTURÉES

---

**US-FOR-01**
En tant que professeur, je veux créer une formation complète avec sections et leçons de différents types afin de proposer un parcours pédagogique structuré à mes élèves.

Critères d'acceptation :
- Types de leçons : Vidéo (URL + durée), Article (texte/Markdown), Fichier téléchargeable
- Les sections et leçons sont réordonnables par drag and drop
- Chaque leçon peut être marquée comme aperçu public visible sans inscription
- La formation est soumise pour validation uniquement quand elle contient au moins une leçon publiée

---

**US-FOR-02**
En tant que professeur, je veux programmer le déblocage progressif des leçons (drip content) afin de maintenir l'engagement de mes élèves sur la durée de la formation.

Critères d'acceptation :
- Trois règles de déblocage par section : "Immédiatement à l'inscription", "X jours après l'inscription", "Si score quiz section précédente ≥ X %"
- Les deux dernières règles sont combinables
- Les leçons verrouillées affichent un cadenas et la condition de déblocage pour l'élève
- Le déblocage est automatique — aucune action manuelle du professeur n'est requise

---

**US-FOR-03**
En tant que professeur, je veux intégrer des quiz à des timestamps précis dans mes vidéos afin de vérifier la compréhension en temps réel pendant le visionnage.

Critères d'acceptation :
- Interface d'ajout de checkpoint dans l'éditeur de leçon vidéo
- Saisie du timestamp (format mm:ss) et de la question (éditeur QCM existant)
- La vidéo se met en pause automatiquement au timestamp, la question s'affiche, la vidéo reprend après réponse
- Les résultats des checkpoints sont visibles dans les analytics de la formation

---

**US-FOR-04**
En tant que professeur, je veux activer la gamification sur ma formation afin de motiver mes élèves par des points, badges et classements.

Critères d'acceptation :
- Toggle "Gamification" dans les paramètres de la formation
- Règles de points : X points par leçon complétée, Y points par quiz réussi, Z points bonus pour score parfait
- Badges débloquables : "Premier quiz validé", "Formation complétée à 50 %", "Score parfait", "Formation complétée"
- Classement optionnel : le professeur choisit si les élèves voient le classement des autres
- WinAI ajuste la difficulté des quiz selon la progression individuelle si l'adaptive difficulty est activée

---

**US-FOR-05**
En tant que professeur, je veux qu'un certificat vérifiable soit généré automatiquement à la complétion de ma formation afin de valoriser le travail de mes élèves.

Critères d'acceptation :
- Toggle "Certificat de complétion" dans les paramètres de la formation
- Le certificat est généré automatiquement quand l'élève complète 100 % des leçons
- Le certificat affiche : nom de l'élève, titre de la formation, nom du professeur, date, note obtenue, code de vérification unique
- Le code est vérifiable via la page "Vérification de certificats" de WinPlus
- L'élève peut partager son certificat ou le télécharger en PDF

---

**US-FOR-06**
En tant que professeur, je veux voir les analytics détaillées de ma formation afin de savoir à quelle leçon mes élèves décrochent et améliorer mon contenu.

Critères d'acceptation :
- Taux de complétion par leçon affiché en graphique barre
- Temps moyen passé par leçon
- Score moyen au quiz de chaque leçon
- Alerte WinAI si le taux de complétion d'une leçon chute sous 40 %
- Vue "Élèves à risque" : liste des élèves dont le pattern d'engagement prédit un abandon

---

**US-FOR-07**
En tant que professeur, je veux être alerté quand un élève est inactif sur ma formation depuis plusieurs jours afin de le relancer avant qu'il décroche définitivement.

Critères d'acceptation :
- WinAI détecte l'inactivité après X jours (configurable par le professeur, défaut 7 jours)
- Notification au professeur : "N élèves sont inactifs depuis 7 jours sur [titre de la formation]"
- Un clic depuis la notification → liste des élèves concernés avec leur dernière activité
- Bouton "Relancer ces élèves" → envoie un message pré-rédigé par WinAI dans la conversation individuelle ou dans le canal de la formation
- Le taux de réactivation est mesuré et affiché dans les analytics

---

**US-FOR-08**
En tant que professeur, je veux que WinAI active un Q&A automatique dans le canal de ma formation afin de répondre aux questions simples sans me mobiliser en permanence.

Critères d'acceptation :
- Toggle "WinAI répond aux questions" dans les paramètres du canal de la formation
- WinAI base ses réponses uniquement sur le contenu des leçons de la formation (pas de réponses génériques)
- Chaque réponse IA porte la mention "Réponse générée par WinAI — à vérifier avec ton professeur"
- Si la confiance de WinAI est inférieure à 70 % : il tague le professeur au lieu de répondre
- Le professeur voit un journal de toutes les interactions IA et peut corriger ou compléter en un clic

---

**US-FOR-09**
En tant que professeur, je veux que WinAI génère un plan de cours complet (syllabus) pour ma formation afin de ne pas partir d'une page blanche.

Critères d'acceptation :
- Accessible depuis le bouton "Générer un syllabus avec WinAI" dans l'éditeur de formation
- Le professeur saisit : matière, niveau, durée totale, objectifs généraux, examens visés
- WinAI génère un plan structuré semaine par semaine : titre de séance, notions, activités, durée, ressources suggérées depuis le catalogue
- Le plan peut être importé directement comme structure de sections et leçons dans la formation
- Le professeur peut modifier le plan avant import

---

## MODULE 10 — INTELLIGENCE DE CLASSE ET ANALYTICS

---

**US-ANA-01**
En tant que professeur, je veux lancer une analyse WinAI sur les performances de mes élèves inscrits à un contenu afin d'identifier les lacunes collectives et adapter mon enseignement.

Critères d'acceptation :
- Sélection d'un contenu publié parmi les siens
- L'analyse couvre les 90 derniers jours
- Résultat : score moyen avec barre colorée, nombre d'apprenants, distribution de maîtrise en 4 niveaux (Excellent/Bon/En difficulté/À risque), questions les plus échouées avec taux d'erreur, patterns d'erreurs fréquentes, actions recommandées en chips cliquables

---

**US-ANA-02**
En tant que professeur, je veux comparer les performances de ma classe avec les moyennes anonymisées de la plateforme afin de situer mes élèves par rapport à leurs pairs.

Critères d'acceptation :
- Bouton "Benchmarking WinAI" dans la vue Intelligence de Classe
- Le résultat indique l'écart en % avec la moyenne plateforme pour le même niveau et la même matière
- Les lacunes spécifiques à la classe sont distinguées des tendances générales
- Des contenus du catalogue sont recommandés pour combler les écarts identifiés

---

**US-ANA-03**
En tant que répétiteur, je veux comparer les scores d'un élève que je suis avec les moyennes des candidats sur la plateforme pour son concours cible afin d'identifier les efforts prioritaires.

Critères d'acceptation :
- Accessible depuis la fiche d'un élève lié en mode Répétiteur
- Le benchmarking est spécifique au concours cible déclaré (ENSP, Polytechnique, FMSB, etc.)
- Les résultats montrent : position estimée de l'élève, matières où l'écart est le plus fort, ressources recommandées

---

## MODULE 11 — WINAI GLOBAL

---

**US-AI-01**
En tant que professeur, je veux accéder à WinAI à tout moment depuis un bouton flottant afin d'obtenir une assistance immédiate sans interrompre ma navigation.

Critères d'acceptation :
- Bouton flottant WinAI présent sur toutes les pages (web et mobile)
- Ouverture en panneau latéral sur web, en modal bottom sheet sur mobile
- L'historique de toutes les conversations est consultable
- Les suggestions rapides prédéfinies sont disponibles (4 suggestions contextuelles selon la page active)

---

**US-AI-02**
En tant que professeur, je veux que WinAI mémorise mon profil, mes préférences et le contexte de nos échanges précédents afin de ne pas devoir réexpliquer mon contexte à chaque nouvelle session.

Critères d'acceptation :
- WinAI mémorise : matières de prédilection, niveau d'enseignement, style pédagogique déclaré, formats de quiz préférés, contenus et formations publiés, patterns des élèves
- Lors de la reprise d'une conversation, WinAI propose de continuer là où on s'était arrêtés
- Un bouton "Mémoire WinAI" affiche les éléments mémorisés et permet d'en supprimer
- La mémoire est séparée par rôle (mode Professeur vs mode Répétiteur)

---

**US-AI-03**
En tant que professeur, je veux que WinAI génère un résumé de chaque leçon de ma formation automatiquement afin que mes élèves disposent d'une fiche de révision sans que je la rédige séparément.

Critères d'acceptation :
- Génération déclenchable depuis l'éditeur de chaque leçon
- Le résumé produit : 5-7 points clés, définitions et formules importantes, 2-3 questions de vérification rapide
- Le résumé est visible dans l'espace élève après chaque leçon complétée
- Le professeur peut désactiver cette fonctionnalité par leçon ou globalement pour la formation

---

**US-AI-04**
En tant que professeur, je veux que WinAI ajuste dynamiquement la difficulté des quiz de ma formation selon la progression individuelle de chaque élève afin de garder chacun ni frustré ni ennuyé.

Critères d'acceptation :
- Activable via le toggle "Adaptive difficulty" dans les paramètres de la formation
- Un élève avec plus de 85 % de réussite reçoit des variantes de questions plus difficiles
- Un élève avec moins de 50 % reçoit des questions plus accessibles avec des indices progressifs
- La difficulté ne bloque jamais la progression — un élève ne reste pas "coincé" sur une leçon
- Le niveau de difficulté appliqué est visible dans les analytics pour le professeur

---

**US-AI-05**
En tant que professeur, je veux que WinAI détecte les élèves dont le comportement prédit un décrochage afin d'intervenir proactivement avant qu'ils abandonnent.

Critères d'acceptation :
- WinAI surveille : fréquence de connexion, temps passé par leçon, scores aux quiz, réponse aux messages
- Une alerte "À risque" est générée si le pattern d'un élève correspond au profil historique d'abandon
- L'alerte arrive dans le tableau de bord du professeur avec le nom de l'élève et les signaux détectés
- Un bouton "Contacter cet élève" ouvre directement la conversation de messagerie avec un message WinAI pré-rédigé

---

**US-AI-06**
En tant que professeur, je veux que WinAI vérifie l'originalité de mon contenu avant soumission afin d'éviter un refus de validation pour plagiat.

Critères d'acceptation :
- L'analyse de plagiat se déclenche automatiquement à l'étape de prévisualisation (étape 4) de la publication
- Si des similarités sont détectées : les sections concernées sont surlignées avec le pourcentage de similarité
- WinAI suggère de reformuler ou de citer la source
- Le professeur peut choisir d'ignorer un résultat et soumettre quand même — la décision finale est à la validation humaine
- Un contenu entièrement original reçoit un badge "Originalité confirmée par WinAI"

---

**US-AI-07**
En tant que professeur, je veux que WinAI m'aide à générer une communication formelle vers les parents depuis un résumé libre afin d'envoyer des rapports professionnels sans effort de mise en forme.

Critères d'acceptation :
- Accessible depuis la fiche d'un élève ou depuis la messagerie
- Le professeur saisit un résumé en 2-3 lignes en langage naturel
- WinAI génère un message formel avec : progression chiffrée, points positifs, axes d'amélioration, devoirs listés
- Le ton est bienveillant et professionnel
- Le professeur édite avant envoi ou copie pour envoi externe

---

## MODULE 12 — REVENUS ET RETRAITS

---

**US-REV-01**
En tant que professeur, je veux suivre mes revenus en temps réel avec un graphique filtrable par période afin d'analyser l'évolution de mon activité économique.

Critères d'acceptation :
- Graphique interactif filtrable : 7 jours, 30 jours, 3 mois, 12 mois
- Deux séries distinctes sur le graphique : revenus catalogue et revenus cours particuliers
- Tooltip au survol affichant la date et le montant précis
- Tableau de détail avec tri sur toutes les colonnes : contenu/élève, ventes, montant, tendance

---

**US-REV-02**
En tant que professeur, je veux retirer mes gains vers mon numéro Mobile Money afin d'encaisser mes revenus WinPlus.

Critères d'acceptation :
- Bouton de retrait désactivé si le solde est nul ou en dessous du minimum
- Choix de l'opérateur : MTN MoMo ou Orange Money avec détection automatique par préfixe
- Saisie du montant validé entre le minimum et le solde disponible
- Suivi du statut toutes les 3 secondes jusqu'à confirmation ou erreur
- Écran de succès avec récapitulatif de l'opération et mise à jour instantanée du solde

---

**US-REV-03**
En tant que professeur, je veux utiliser mon solde WinPlus comme moyen de paiement dans le catalogue afin d'éviter une transaction Mobile Money externe.

Critères d'acceptation :
- Option "Payer avec mon solde WinPlus" à l'étape de paiement du panier
- Le solde disponible est affiché avec le montant du panier pour comparaison
- Si le solde est insuffisant : option de paiement en deux parties (solde + complément Mobile Money)
- La transaction est enregistrée comme débit dans l'historique des transactions

---

## MODULE 13 — FORUM ET COMMUNAUTÉ

---

**US-FOR-COM-01**
En tant que professeur, je veux participer au forum d'entraide avec un label distinctif de professeur vérifié afin d'avoir une visibilité et une crédibilité accrues dans la communauté WinPlus.

Critères d'acceptation :
- Le label "Professeur Vérifié" s'affiche automatiquement sur tous les posts et réponses du professeur
- Le professeur peut créer des fils, répondre et suivre des discussions
- Les fils qu'il crée sont automatiquement mis en avant si sa réponse est marquée comme "Meilleure réponse" par l'OP
- Le professeur reçoit une notification quand quelqu'un répond à un fil qu'il suit

---

**US-FOR-COM-02**
En tant que professeur, je veux vérifier l'authenticité d'un certificat WinPlus afin de confirmer la complétion d'une formation par un élève ou un candidat.

Critères d'acceptation :
- Page de vérification accessible sans connexion
- Saisie du code de certificat → résultat immédiat : nom de l'étudiant, cours suivi, note obtenue, date d'émission, badge d'authenticité
- Un certificat invalide ou expiré affiche un message d'erreur clair

---

Voilà l'ensemble complet. On couvre maintenant 13 modules, 70+ user stories, avec tous les critères d'acceptation. La prochaine étape naturelle serait soit le backlog priorisé par sprint, soit le modèle de données, soit les endpoints API. Tu veux continuer sur quoi ?