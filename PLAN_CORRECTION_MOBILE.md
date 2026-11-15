# WinPlus mobile : plan de correction

Analyse du 14 novembre 2026, sur la branche `main` après récupération des commits `91c1884`, `09e0b59` et `dd8d7b9`.

Objectif : une application mobile complète, publiable sur Android et iOS, utilisable hors ligne, au design de la version téléphone du site, en français et en anglais, avec toutes les fonctionnalités WinPlus adaptées au mobile.

Ce document remplace `FEATURE_GAP_MOBILE.md` (août 2026), devenu faux : la plupart de ses « ❌ » sont faits.

## Comment lire ce plan

- Le travail est découpé en **lots**, dans l'ordre où ils doivent être faits. Un lot ne commence que si ceux dont il dépend sont terminés.
- Chaque lot se termine par ses **critères de fin**. Un lot n'est fini que lorsque tous sont vérifiés.
- Règles du projet, valables pour chaque lot :
  - `git pull` avant toute modification, un collègue travaille en parallèle ;
  - deux vérifications (analyse `flutter analyze` sans erreur, tests du lot au vert) puis commit, sans co-auteur ;
  - aucune donnée fictive, aucun texte en dur : tout texte passe par `lib/l10n/app_fr.arb` et `app_en.arb` ;
  - aucun déploiement ni publication sans l'accord de Georges.
- Les constats marqués **(à confirmer)** viennent d'une recherche par mots-clés dans le code. Ils sont à vérifier à l'ouverture du lot, avant de coder.

## État des lieux

| Sujet | État | Détail |
|---|---|---|
| Parcours de démarrage | Fait le 14/11 | Ouverture directe de l'espace du compte, ou de la connexion sans session. Le carrousel de présentation est supprimé. |
| Données réelles | Presque | 41 services branchés sur `api.winplus.cm`. Un écran reste simulé (reconfirmation d'identité). |
| Publication Android | Bloquée | Pas de permission INTERNET en production, pas de clé de signature. |
| iOS | Absent | Pas de dossier `ios`. |
| Hors ligne | Partiel | Cache sur 4 services de lecture sur 41, file d'attente pour 2 actions. |
| Design | Partiel | Accueils, onglets, palette et connexion alignés sur le site. Le reste garde l'ancienne mise en page. |
| Langues | Presque | 2 291 clés, français et anglais complets. Environ 129 lignes de texte français en dur dans 18 fichiers. |
| Parité avec le site | Partielle | Une trentaine de fonctions du site sans équivalent mobile (liste au lot 7). |
| Tests | Fragiles | 21 tests d'écrans d'authentification en échec, dont une partie déjà avant le 14/11. |

## Lot 0 : remettre les tests au vert

Sans tests fiables, aucun des lots suivants ne peut être vérifié.

1. Lancer toute la suite (`flutter test`) et noter les échecs par fichier.
2. Corriger les 21 échecs connus de `test/ecrans/auth` : inscription, choix du profil, nouveau mot de passe, profil initial, page légale, code de vérification. Les messages (« widget hors écran », libellé introuvable) indiquent des tests en retard sur les écrans, pas forcément des bogues : comparer l'écran et le test avant de choisir lequel corriger.
3. Enregistrer dans git le dossier `test/` et l'ajout de `flutter_test` dans `pubspec.yaml`, aujourd'hui seulement en local.

**Critères de fin :** `flutter test` passe entièrement ; `flutter analyze` ne renvoie aucune erreur ; les tests sont dans le dépôt.

## Lot 1 : ce qui empêche l'application de fonctionner

Dépend du lot 0.

1. **Permission INTERNET.** Elle manque dans `android/app/src/main/AndroidManifest.xml` (présente seulement en `debug` et `profile`). Une version de production ne peut pas joindre le serveur.
2. **Reconfirmation d'identité simulée** (`lib/auth/periodic_confirm_screen.dart`).
   - Aujourd'hui : aucun code envoyé, seul `123456` est accepté, et l'écran se ferme sur du vide (écran noir) car il est ouvert en remplacement de l'écran de démarrage.
   - À faire : reprendre le fonctionnement du site (`frontend/src/pages/auth/PeriodicConfirm.tsx`, `services/authExtraService.ts`, route `/auth/reconfirmation-status`). C'est le serveur qui décide si la reconfirmation est due, plus le compteur local de `SessionManager`.
   - Après validation : ouvrir l'espace du compte. Après refus ou abandon : déconnecter et ouvrir la connexion.
3. **Session expirée.** Quand le renouvellement du jeton échoue, `api_client.dart` efface la session mais laisse l'utilisateur sur un écran en erreur. Le ramener à la connexion avec un message.
4. **Jetons en clair.** `SessionManager` range les jetons dans `SharedPreferences`. Les déplacer dans `flutter_secure_storage` (déjà dans le projet), avec reprise des sessions existantes.
5. **Sans réseau au démarrage.** Une session valide doit ouvrir l'espace du compte même sans réseau (voir lot 3).

**Critères de fin :** une version de production installée sur un téléphone se connecte et charge l'accueil ; la reconfirmation fonctionne avec un vrai code reçu par e-mail ; une session expirée ramène à la connexion ; plus aucun `Future.delayed` ne remplace un appel serveur.

## Lot 2 : écosystème Android et iOS

Dépend du lot 1. Les étapes marquées *Georges* demandent une décision ou un compte que lui seul possède.

### Android

1. Clé de signature de production et `key.properties` hors du dépôt (*Georges* : création et conservation de la clé). Remplacer la signature de développement dans `android/app/build.gradle.kts`.
2. Nom affiché « WinPlus » (aujourd'hui « winplus »).
3. Réduction et obscurcissement du code en production, avec les règles nécessaires aux bibliothèques utilisées.
4. Écran de démarrage natif aux couleurs de la marque (vert profond `#0B3530`), pour éviter l'écran blanc avant Flutter.
5. Sauvegarde automatique Android : exclure les jetons et les leçons chiffrées.
6. Protection des contenus payants : interdire la capture d'écran dans la visionneuse et le lecteur (`FLAG_SECURE`), comme le filigrane du site.
7. Fiche Play Store : captures, description en français et en anglais, politique de confidentialité, déclaration des données collectées (*Georges* : compte développeur).

### iOS

1. Créer le projet iOS (`flutter create --platforms=ios .`), identifiant `cm.winplus.app`.
2. Icônes iOS (`flutter_launcher_icons` est réglé sur `ios: false`), écran de démarrage, nom affiché.
3. Textes de demande d'autorisation dans `Info.plist` : appareil photo, photos, fichiers (selfie de vérification, pièces jointes).
4. Vérifier chaque bibliothèque sur iOS : `pdfrx`, `video_player`, `file_picker`, `image_picker`, `flutter_secure_storage`, `connectivity_plus`.
5. **Compilation et signature iOS : reportées** (décision du 14/11). Pas de compilation sur Mac pour l'instant. Les points 1 à 4 se préparent sous Windows ; ils seront vérifiés quand un Mac ou un service de compilation sera disponible.
6. **Paiement sur iOS : hors périmètre** (décision du 14/11).

### Communs aux deux

1. **Liens profonds.** Les liens des e-mails (réinitialisation du mot de passe, vérification de l'adresse, vérification d'un certificat) et le retour de paiement doivent ouvrir l'application : App Links sur Android, Universal Links sur iOS, fichiers d'association à publier sur `winplus.cm`.
2. **Notifications application fermée, sans Firebase** (décision du 14/11). Aujourd'hui, rien n'arrive quand l'application est fermée (`push_service.dart` n'écoute qu'au premier plan). Sur Android :
   - vérification périodique en arrière-plan (WorkManager, au mieux toutes les 15 minutes) de `/notifications`, puis notification locale (`flutter_local_notifications`). Aucun service tiers, mais un délai de quelques minutes à quelques heures, et certaines marques (Tecno, Infinix, Xiaomi) coupent les tâches de fond ;
   - réception instantanée par **ntfy intégré à l'application** (décision du 14/11) : un service Android au premier plan garde ouvert le flux `/notifications/sse` déjà utilisé par `push_service.dart`. Rien à installer à côté. Android impose une notification fixe tant que l'écoute est active (type de service `remoteMessaging`). L'écoute est désactivable dans les réglages ; elle redémarre avec le téléphone ;
   - la vérification périodique reste en secours, quand le service est coupé par le système ou désactivé.
   Sur iOS, seul APNs permet de recevoir une notification application fermée. Firebase n'est pas nécessaire : le serveur peut écrire directement à APNs. À traiter quand la compilation iOS sera possible.
3. **Connexion Google**, active sur le site, encore « bientôt » sur mobile (`google_sign_in` et route serveur existante).
4. **Ouverture de liens et partage** : `url_launcher` et `share_plus` sont absents (lien de vérification d'un certificat, partage d'un contenu).
5. Environnements : l'adresse du serveur est figée sur la production dans `app_config.dart`. Ajouter l'intégration (`integration.winplus.cm`) par variable de compilation, pour tester sans toucher la production.
6. Numéro de version, journal des versions, et compilation automatique (GitHub Actions) des deux plateformes.

**Critères de fin :** un fichier Android signé prêt pour le Play Store ; le projet iOS créé et prêt à compiler (la compilation elle-même est reportée) ; un lien de réinitialisation reçu par e-mail ouvre l'application sur Android ; une notification arrive application fermée sur Android, selon l'option retenue.

## Lot 3 : mode hors ligne

Dépend du lot 1.

### Ce qui existe

- Détection du réseau (`connectivity_service.dart`) et bandeau hors ligne (`widgets/offline_banner.dart`, posé sur 4 écrans seulement).
- Cache local (`local_cache_service.dart`, Hive), utilisé par 4 services : quiz, rapports, coach d'examen, parent.
- File d'attente (`outbox_service.dart`) pour 2 actions : soumission d'un quiz, envoi d'un message.
- Leçons de formation téléchargeables et chiffrées (`course_offline_service.dart`).

### Règle à appliquer partout

Pour toute lecture : afficher tout de suite la dernière version connue, rafraîchir en arrière-plan si le réseau est là, et indiquer la date des données quand elles viennent du cache. Mettre cette règle dans `api_client.dart` ou dans un service commun, plutôt que de la recopier dans 37 services.

### Lectures à mettre en cache

| Priorité | Services |
|---|---|
| 1 | `user_service` (profil, notifications), `student_service` (accueil), `subject_service` (catalogue), `course_service` (formations, mes formations), `subscription_service` |
| 2 | `favorites_service`, `achievement_service`, `certificate_service`, `order_service`, `wallet_service`, `messaging_service` (conversations et messages), `goals_service`, `study_group_service`, `forum_service` |
| 3 | `teacher_service`, `institution_service`, `tutor_booking_service`, `tutor_engagement_service`, `tutor_profile_service`, `linking_service`, `quiz_mistakes_service` |

### Actions à mettre en file d'attente

Favoris, progression d'une leçon, séance d'étude (minuteur), notification lue, objectif accepté ou refusé, note personnelle, message de forum, encouragement d'un parent, réponse à un devoir.

À prévoir : identifiant unique par action pour que le serveur ignore un double envoi, nombre d'essais limité, et un écran « En attente d'envoi » visible par l'utilisateur.

### Ce qui reste volontairement en ligne

- Paiements, réservations de répétiteur, WinAI, inscription et connexion.
- Épreuves, corrigés et livres : non téléchargeables par décision produit (module 44). Hors ligne, afficher un message clair, pas une erreur.

### Autres points

- Bandeau hors ligne dans l'enveloppe des espaces (`role_shell.dart`), donc sur tous les écrans.
- Démarrage sans réseau avec session valide : ouvrir l'espace depuis le cache.
- Cache séparé par compte et effacé à la déconnexion ; taille plafonnée.
- Écran « Mes téléchargements » : place occupée, suppression.

**Critères de fin :** en mode avion, avec une session ouverte, les écrans de priorité 1 et 2 s'affichent avec leurs dernières données ; une action faite hors ligne part au retour du réseau, une seule fois ; aucune page blanche ni erreur technique visible hors ligne ; tests automatiques avec le faux réseau de `test/helpers/faux_reseau.dart`.

## Lot 4 : design de la version téléphone du site

Dépend du lot 0. Peut avancer en parallèle des lots 2 et 3.

### Référence

Le site sous 640 px de large : `frontend/src/styles/auth-mobile.css`, `frontend/src/styles/responsive.css`, `frontend/src/components/dashboard/kit/MobileHome.tsx` et les 71 feuilles de style qui ont une règle « téléphone ». Pour chaque écran : ouvrir la page du site en largeur téléphone, puis aligner l'écran mobile.

### Composants communs à créer d'abord

1. En-tête d'écran secondaire : retour rond bordé, titre, action à droite (à partir de `_AuthTopBar` de `login_screen.dart`, à déplacer dans `widgets/`).
2. Champ de saisie du site : libellé au-dessus, bordure fine, rayon 14, hauteur 54, sans icône à gauche (`WinTextField` en a encore une version différente).
3. Carte, pastille, bandeau d'alerte, feuille du bas, état vide, état de chargement (squelette), état d'erreur avec « Réessayer ».
4. Suppression du style « Funica » : dégradés `heroFrom`/`heroTo` et grands rayons, encore présents dans 7 fichiers.

### Écrans, par ordre

| Ordre | Écrans | État |
|---|---|---|
| 1 | Connexion, démarrage | Fait le 14/11 |
| 2 | Choix du profil, inscription, code de vérification, mot de passe oublié, nouveau mot de passe, profil initial, succès, adresse vérifiée | Ancien style |
| 3 | Accueils des 4 espaces, onglets, catalogue | Fait par le collègue, à relire écran par écran |
| 4 | Détail d'un contenu, visionneuse, formations (catalogue, détail, lecteur), quiz, recherche | Palette à jour, mise en page à aligner |
| 5 | Panier, paiement, commandes, abonnement, portefeuille | Idem |
| 6 | Messagerie, forum, groupes d'étude, notifications, profil et réglages | Idem |
| 7 | Répétiteurs : recherche, profil public, réservation, engagements | Profil public en ancien style |
| 8 | Espace parent : enfants, activité, alertes, album, portefeuille | En partie en ancien style |
| 9 | Espace professeur : contenus, corrections, classes, séances, revenus, portefeuille | Portefeuille en ancien style |
| 10 | Espace établissement : groupes, annuaire, élèves à risque, plan d'action, rapports, licence | À aligner |

### Points transverses

- Mode sombre : il existe (`WinScheme.dark_`), le site n'en a pas. Décider de le garder ou non (*Georges*). S'il reste, chaque écran aligné doit être vérifié dans les deux modes.
- Accessibilité : zones tactiles de 44 px minimum, contraste, taille de texte du système, lecteur d'écran sur les boutons sans texte.
- Petits écrans (largeur 320) et tablettes.
- Animations coupées quand l'appareil le demande (déjà prévu dans `win_motion.dart`).

**Critères de fin :** pour chaque écran, une capture mobile et une capture du site en largeur téléphone, côte à côte, sans écart de structure, de couleurs ni de typographie ; plus aucune référence à `heroFrom` hors du thème ; aucun débordement à 320 px de large.

## Lot 5 : français et anglais partout

Dépend du lot 0.

1. **Textes en dur** : environ 129 lignes dans 18 fichiers. Les plus chargés :
   - `teacher/teacher_wallet_view.dart` (24) et `teacher/tutor_profile_screen.dart` (24) ;
   - `student/tutors/tutor_search_screen.dart` (13), `auth/complete_profile_screen.dart` (11), `teacher/teacher_tabs.dart` (10) ;
   - `student/course_catalog_screen.dart` (8), `teacher/content_publish_screen.dart` (7), `services/wallet_service.dart` (7).
2. **Listes de référence en français seulement** : matières, niveaux, filières, statuts (« Publié », « Corrigé », « Modéré »), dans `data/models.dart`, `data/mock_data.dart` et plusieurs écrans. Les faire venir du serveur avec leurs deux libellés, ou les traduire par clé. Attention : certaines de ces valeurs sont envoyées au serveur telles quelles ; séparer la valeur technique du libellé affiché.
3. **Messages d'erreur des services** : ils sont écrits en français dans les services (`wallet_service`, `parent_service`…). Les services doivent renvoyer un code, l'écran choisit le texte.
4. **Messages du serveur** : envoyer la langue de l'application dans l'en-tête `Accept-Language` de chaque requête.
5. **Nettoyage** : `mock_data.dart` (886 lignes) ne sert plus qu'à quelques listes. Le supprimer après le point 2. Retirer aussi `WinData.catalog` et les branches « contenu de démonstration ».
6. Dates, nombres et montants (FCFA) par `WinFormat`, jamais à la main.
7. Garde-fou : un test qui échoue si une chaîne accentuée apparaît dans `lib/` hors de `l10n/`.

**Critères de fin :** l'application passée en anglais ne montre plus aucun mot français, sur les 4 espaces ; `mock_data.dart` supprimé ; le garde-fou est en place et passe.

## Lot 6 : fonctions encore factices ou renvoyées vers le site

Dépend du lot 1.

| Fonction | Aujourd'hui | À faire |
|---|---|---|
| Achat d'un contenu | `account_required_purchase_screen.dart` affiche « achetez depuis winplus.cm », alors que `checkout_screen.dart` sait payer par Mobile Money | Brancher l'achat sur le panier et le paiement de l'application (sauf iOS selon la décision du lot 2) |
| Création d'une formation (professeur) | Renvoi vers le site (`teacher_courses_screen.dart`) | Écran de création et d'édition, ou au moins ouverture directe du site déjà connecté |
| Certains fichiers du lecteur de formation | « S'ouvre depuis le site » | Lister les types concernés et les prendre en charge, ou ouvrir le lien |
| Connexion Google | « Bientôt » | Voir lot 2 |
| Dictée vocale dans WinAI | « Prochainement » | Enregistrement et envoi, comme le site |
| Avis sur le profil du professeur | « Bientôt » | Afficher les avis (`tutor_review_service` existe) |
| Blocs « Bientôt disponible » élève et professeur | Affichés | Brancher ou retirer |

**Critères de fin :** plus aucun message « bientôt » ni renvoi vers le site pour une fonction que le site propose.

## Lot 7 : parité avec le site

Dépend des lots 3 à 5, pour que chaque nouvel écran naisse avec le cache, le bon design et les deux langues. Tous les constats de ce lot sont **(à confirmer)** : pour chacun, ouvrir le composant du site indiqué, relever ses routes serveur, puis vérifier que le mobile ne l'a pas sous un autre nom.

### Tous les profils

| Fonction du site | Référence |
|---|---|
| Centre d'aide, questions fréquentes, contact | `pages/Help.tsx`, `FAQ.tsx`, `Contact.tsx` |
| Vérification d'un certificat par son code | `pages/CertificateVerify.tsx` |
| Réactions et réponses citées dans la messagerie | `pages/Messages/` |
| Résumé des notifications par WinAI | `student/NotificationAISummary.tsx` |

### Élève

| Fonction du site | Référence |
|---|---|
| Hub des concours et pages par concours | `pages/concours/` |
| Mes devoirs | `pages/MesDevoirs.tsx` (un seul fichier mobile en parle) |
| Résultats des étudiants | `pages/resultats/` |
| Comparaison anonyme avec les pairs | `student/PeerComparison.tsx` |
| Prédiction de note | à rechercher dans le site |
| Notes de révision | `student/RevisionNotes.tsx` |

### Parent

| Fonction du site | Référence |
|---|---|
| Baromètre | `parent/BarometreScreen.tsx` |
| Comparaison entre enfants | `parent/ChildrenComparison.tsx` |
| Fiche de révision générée pour un enfant | `parent/GenerateRevisionForChildSheet.tsx` |
| Rappels | `parent/ParentReminders.tsx` |
| Impact des achats, contenus recommandés | `parent/PurchaseImpactCard.tsx`, `RecommendedContentCard.tsx` |

### Professeur

| Fonction du site | Référence |
|---|---|
| Programme d'affiliation | `teacher/AffiliateProgramPanel.tsx` |
| Analyse de classe, alertes de décrochage | `teacher/ClassAnalysis.tsx`, `DecrochageAlertsPanel.tsx` |
| Coaching WinAI du répétiteur, conseils | `teacher/TutorCoachingPanel.tsx`, `TeacherInsights.tsx` |
| Formations : création, statistiques, ludification | `teacher/TeacherFormations.tsx`, `CourseGamificationPanel.tsx` |
| Bibliothèque | `teacher/TeacherLibrary.tsx` |

### Établissement

| Fonction du site | Référence |
|---|---|
| Enseignants | `institution/InstitutionTeachers.tsx` |
| Annonces | `institution/InstitutionAnnouncements.tsx` |
| Devoirs, examens blancs, bulletins | `InstitutionHomework.tsx`, `InstitutionMockExams.tsx`, `InstitutionBulletins.tsx` |
| Comparaison entre établissements et par région | `BenchmarkPanel.tsx`, `RegionalComparison.tsx` |
| Prédiction par classe | `ClassPrediction.tsx` |

### Hors périmètre mobile

- Administration (`components/dashboard/admin/`) : reste sur le site.
- Pages de présentation (accueil public, à propos, tarifs publics, fonctionnalités) : décision du 14/11, l'application ouvre directement l'espace du compte.
- Conditions, confidentialité : déjà dans `shared/legal_screen.dart`.

**Critères de fin :** un tableau de parité tenu à jour dans ce fichier, une ligne par fonction du site, avec l'écran mobile correspondant ou la mention « hors périmètre » et sa raison.

## Lot 8 : qualité avant publication

Dépend de tous les lots précédents.

1. Tests sur de vrais téléphones : un Android d'entrée de gamme (2 Go de mémoire, Android 8), un Android récent, un iPhone.
2. Réseau lent et instable (2G/3G), cas le plus courant des utilisateurs : délais, reprises, taille des images.
3. Poids de l'application et temps de démarrage. Les polices sont téléchargées au premier lancement par `google_fonts` : les embarquer dans l'application, sinon le premier lancement hors ligne n'a pas les bonnes polices.
4. Suivi des plantages en production (*Georges* : choix de l'outil).
5. Parcours complets sur l'intégration, avec les comptes de test (élève 30, parent 26, professeur 50) : inscription, achat, quiz, formation, réservation, message, hors ligne puis retour du réseau.
6. Relecture de sécurité : jetons, cache chiffré, captures d'écran, liens profonds.

**Critères de fin :** aucun plantage sur les parcours du point 5, sur les trois téléphones ; premier lancement utilisable en moins de 5 secondes sur l'appareil d'entrée de gamme.

## Ordre et dépendances

```
Lot 0 ─┬─ Lot 1 ─┬─ Lot 2 (Android, iOS)
       │         ├─ Lot 3 (hors ligne) ──┐
       │         └─ Lot 6 (factice)      ├─ Lot 7 (parité) ── Lot 8 (qualité)
       ├─ Lot 4 (design) ────────────────┤
       └─ Lot 5 (langues) ───────────────┘
```

## Décisions attendues de Georges

1. Clé de signature Android : qui la crée, où elle est conservée.
2. Compte développeur Google Play. (Compilation iOS reportée et paiement iOS hors périmètre, décisions du 14/11.)
4. Mode sombre : le garder ou le retirer.
5. Outil de suivi des plantages.
6. Ordre de priorité des fonctions du lot 7, s'il faut publier avant la parité complète.
