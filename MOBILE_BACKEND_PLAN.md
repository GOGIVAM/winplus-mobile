# WinPlus Mobile — Plan d'intégration Backend

> Document de référence pour l'implémentation du backend mobile, de l'authentification, de la persistence, des paiements et du logging.
> Statut : **Planification** — aucun code produit à ce stade.

---

## 1. État actuel du code mobile

### Ce qui existe

| Fichier | Contenu actuel | Statut |
|---|---|---|
| `lib/main.dart` | Bootstrap app + MaterialApp | Fonctionnel |
| `lib/app_state.dart` | ChangeNotifier (thème + rôle) | À remplacer par Riverpod |
| `lib/data/models.dart` | Modèles Dart (WinRole, Content, Subject…) | À enrichir |
| `lib/data/mock_data.dart` | Données statiques camerounaises | À supprimer progressivement |
| `lib/auth/splash_screen.dart` | Animation logo 2.3s | Garder |
| `lib/auth/welcome_screen.dart` | CTAs Créer / Se connecter | Garder le UI |
| `lib/auth/role_screen.dart` | Sélection de rôle | Garder le UI |
| `lib/auth/login_screen.dart` | Login simulé (1s de délai) | À câbler au backend |
| `lib/shell/role_shell.dart` | Nav 5 tabs par rôle | Garder |
| `lib/student/student_tabs.dart` | Catalogue, Mon Espace, **WinAI** (chat mock), Communauté | WinAI à câbler |
| `lib/student/student_home.dart` | Hero, stats, recommandations | À câbler |
| `lib/widgets/win_widgets.dart` | WinButton, WinCard, WinChip, etc. | Stable |

### Ce qui manque

- **Aucun appel HTTP** — tout est mock
- **Aucune persistance** — reset à chaque redémarrage
- **Aucune authentification réelle**
- **WinAI / Chatbot** : le tab `StudentWinAITab` dans `student_tabs.dart` est la bonne UI, mais la réponse est un string fixe hardcodé. Il n'est pas câblé à `POST /api/chatbot/message` ni à l'historique.
- **Paiements** : UI absente (bouton "Acheter" visible sur les `ContentCard` mais sans action)

---

## 2. Backend WinPlus — Endpoints disponibles pour le mobile

Backend URL : **`https://api.winplus.cm`**

### Auth
| Méthode | Endpoint | Usage mobile |
|---|---|---|
| POST | `/api/auth/signup` | Création de compte |
| POST | `/api/auth/signin` | Login |
| POST | `/api/auth/verify-email` | Vérification email |
| POST | `/api/auth/resend-verification` | Renvoyer code |
| POST | `/api/auth/refresh-token` | Renouveler JWT |
| POST | `/api/auth/forgot-password` | Mot de passe oublié |
| POST | `/api/auth/reset-password` | Reset mot de passe |
| POST | `/api/auth/logout` | Déconnexion |
| POST | `/api/auth/change-password` | Changer mot de passe |
| POST | `/api/auth/send-confirmation-code` | Code de reconfirmation périodique |
| POST | `/api/auth/verify-confirmation` | Valider code périodique |

### Catalogue
| Méthode | Endpoint | Usage mobile |
|---|---|---|
| GET | `/api/subjects` | Liste catalogue (paginée) |
| GET | `/api/subjects/{id}` | Détail sujet |
| GET | `/api/subjects/search` | Recherche |
| GET | `/api/subjects/popular` | Recommandations |
| GET | `/api/subjects/{id}/download` | Téléchargement (voir §8) |

### Paiements
| Méthode | Endpoint | Usage mobile |
|---|---|---|
| POST | `/api/payments/initiate` | Initier paiement NotchPay |
| GET | `/api/payments/{orderId}/status` | Polling statut |
| GET | `/api/payments/history` | Historique |

### Chatbot / WinAI
| Méthode | Endpoint | Usage mobile |
|---|---|---|
| POST | `/api/chatbot/message` | Envoyer message |
| GET | `/api/chatbot/history` | Historique conversation |
| POST | `/api/chatbot/clear` | Effacer conversation |

### Autres
| Méthode | Endpoint | Usage mobile |
|---|---|---|
| GET | `/api/enrollments/user/{userId}` | Mes contenus achetés |
| POST | `/api/enrollments/{id}/progress` | Mise à jour progression |
| GET | `/api/notifications` | Notifications |
| GET | `/api/student/progress` | Tableau de bord étudiant |
| GET | `/api/parent/children` | Enfants (rôle parent) |
| GET | `/api/teacher/courses` | Cours (rôle professeur) |
| GET | `/api/analytics/dashboard` | Analytics |

---

## 3. Politique Online / Offline

### Règle générale
> Mobile-first, dégradé gracieux. L'app fonctionne en lecture depuis le cache SQLite. Les actions critiques (paiement, première connexion, confirmation périodique) bloquent avec un message clair.

| Fonctionnalité | Online | Offline |
|---|---|---|
| Création de compte | ✅ Obligatoire | ❌ Message bloquant |
| Login (1ère fois / token expiré) | ✅ Obligatoire | ❌ Message bloquant |
| Login (token valide < 30j) | Facultatif | ✅ Biométrie / PIN |
| Reconfirmation périodique | ✅ **Obligatoire** | ❌ Message bloquant |
| Catalogue | Sync | ✅ Cache SQLite |
| Contenu téléchargé | Téléchargement initial | ✅ Fichier local |
| Paiement | ✅ Obligatoire | ❌ Message bloquant |
| Historique paiements | Sync | ✅ SQLite |
| WinAI / Chatbot | ✅ Obligatoire | ❌ Mode dégradé (message offline) |
| Progression / quiz | Sync | ✅ File d'attente SQLite |
| Notifications | Sync | ✅ Dernières notifs SQLite |

### Détection réseau
- Package `connectivity_plus`
- Écoute en temps réel via `StreamSubscription`
- Bannière discrète non-bloquante en haut de l'app quand offline
- Blocage modal uniquement sur les actions critiques

### File d'attente offline (`offline_queue` SQLite)
Actions différées quand pas de réseau, rejouées au retour de la connectivité :
- Marquer quiz terminé
- Mise à jour de progression
- Envoi analytics

---

## 4. Authentification

### 4.1 Création de compte (online uniquement)

```
App → POST /api/auth/signup { email, password, role, name }
       ↓
   Email de vérification (code 6 chiffres, 24h, via Resend)
       ↓
App → Écran saisie code → POST /api/auth/verify-email
       ↓
   Backend retourne JWT (1440 min) + RefreshToken (30 jours)
       ↓
   Stockage : flutter_secure_storage (JWT + refresh)
             SQLite auth_session (userId, email, role, expiry)
       ↓
   Proposer activation biométrie / PIN
```

### 4.2 Login (première fois ou token expiré)

```
App → POST /api/auth/signin { email, password }
       ↓
   JWT + RefreshToken → flutter_secure_storage
   Profil → SQLite auth_session
       ↓
   RoleShell
```

### 4.3 Login (token valide — offline possible)

```
App ouvre / reprend en foreground
       ↓
flutter_secure_storage.read(jwt) → JWT présent ?
       ↓ Oui — vérifier expiry locale
JWT valide ?
       ↓ Oui
local_auth.authenticate()    ← biométrie ET/OU saisie mot de passe
(proposition comme WhatsApp : l'un ou l'autre selon les préférences user)
       ↓ Succès
RoleShell

JWT expiré ?
       ↓
Online → POST /api/auth/refresh-token → nouveau JWT
Offline → Rediriger vers login (connexion requise)
```

### 4.4 Mot de passe + Biométrie (style WhatsApp)

- **À l'activation** : l'app propose d'activer la biométrie. L'utilisateur peut refuser.
- **À l'ouverture** : si biométrie activée → `local_auth.authenticate()` en priorité.
- Si l'appareil ne supporte pas la biométrie → saisie du mot de passe de l'application (pas du PIN système).
- Le choix biométrie/mot de passe est sauvegardé dans `shared_preferences`.
- L'utilisateur peut toujours choisir "Utiliser le mot de passe" même si biométrie activée.

### 4.5 Reconfirmation périodique (style WhatsApp)

**Fréquence : 30 à 45 jours** (valeur configurable côté backend, stockée localement dans SQLite).

```
Au démarrage de l'app :
  Lire auth_session.last_confirmed_at depuis SQLite
  Calculer nb de jours depuis dernière confirmation
  Si > seuil (30–45j) ET online → déclencher flux de reconfirmation
  Si > seuil ET offline → afficher message "Confirme ton identité dès que tu es en ligne"

Flux de reconfirmation :
  App → POST /api/auth/send-confirmation-code
          ↓ (email envoyé par le backend via Resend)
  Écran modal plein écran (non dismissable)
  Saisie du code 6 chiffres (expiration 5 min)
          ↓
  App → POST /api/auth/verify-confirmation { code }
          ↓ Succès
  SQLite : mettre à jour last_confirmed_at = now()
  Nouveau JWT émis → flutter_secure_storage mis à jour
          ↓
  RoleShell

  Si code invalide ou expiré → renvoyer + afficher erreur
  Si l'utilisateur ferme l'app sans confirmer → forcer à la prochaine ouverture
```

> **Règle** : la reconfirmation se passe entièrement dans l'app. L'utilisateur doit être en ligne. Le code arrive par email.

### 4.6 JWT et Refresh Token

- **Access token** : 1440 min (24h) — configuré backend
- **Refresh token** : 30 jours — configuré backend
- **Interceptor Dio** :
  1. Ajouter `Authorization: Bearer <jwt>` à chaque requête
  2. Sur réponse 401 → tenter `POST /api/auth/refresh-token`
  3. Si refresh OK → rejouer la requête originale
  4. Si refresh échoue → logout + redirection login screen

---

## 5. Base de données SQLite locale

Package : `sqflite`

### Schéma complet

```sql
-- Session et token utilisateur
CREATE TABLE auth_session (
  id              INTEGER PRIMARY KEY,
  user_id         TEXT NOT NULL,
  email           TEXT NOT NULL,
  role            TEXT NOT NULL,
  refresh_expiry  INTEGER,          -- Unix timestamp (ms)
  last_confirmed  INTEGER,          -- Unix timestamp (ms)
  biometric_on    INTEGER DEFAULT 0 -- 0=non, 1=oui
);

-- Cache catalogue (sujets/contenus)
CREATE TABLE subjects_cache (
  id          TEXT PRIMARY KEY,
  data        TEXT NOT NULL,        -- JSON sérialisé
  cached_at   INTEGER NOT NULL      -- Unix timestamp (ms)
);

-- Contenu acheté / téléchargé localement
CREATE TABLE downloads (
  id            TEXT PRIMARY KEY,
  subject_id    TEXT NOT NULL,
  title         TEXT NOT NULL,
  file_path     TEXT NOT NULL,      -- Chemin absolu local
  downloaded_at INTEGER NOT NULL
);

-- Historique paiements (sync depuis API)
CREATE TABLE payments (
  id         TEXT PRIMARY KEY,
  order_id   TEXT,
  amount     INTEGER,
  currency   TEXT DEFAULT 'XAF',
  status     TEXT,                  -- pending, completed, failed
  method     TEXT,                  -- mtn, orange, notchpay
  created_at INTEGER
);

-- File d'attente actions offline
CREATE TABLE offline_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  action_type TEXT NOT NULL,        -- 'quiz_complete', 'progress_update'
  payload     TEXT NOT NULL,        -- JSON
  created_at  INTEGER NOT NULL,
  synced      INTEGER DEFAULT 0
);

-- Cache notifications
CREATE TABLE notifications_cache (
  id        TEXT PRIMARY KEY,
  data      TEXT NOT NULL,
  read      INTEGER DEFAULT 0,
  cached_at INTEGER NOT NULL
);
```

---

## 6. Paiements — NotchPay (sans WebView, 100% API)

### Pourquoi pas de WebView
Le `NotchPayService.cs` effectue le paiement en **2 appels API directs** :
- **Step 1** : `POST /payments` → crée la session de paiement (retourne une référence)
- **Step 2** : `POST /payments/{reference}` avec `{ channel: "cm.mtn"|"cm.orange", data: { phone: "+237XXXXXXXXX" } }` → déclenche un **push USSD** sur le téléphone de l'utilisateur

L'opérateur (MTN/Orange) envoie une popup USSD nativement sur le téléphone. L'utilisateur la confirme directement. **Aucune redirection, aucun WebView.**

### Le backend a déjà
- `POST /api/payments/initiate` (rate limitée : 5 / 10 min)
- `GET /api/payments/{orderId}/status`
- `POST /api/payments/webhook/notchpay` (HMAC-SHA256 vérifié)
- Entité `WebhookIdempotencyKey` pour la déduplication

### Flux mobile complet

```
User tape "Acheter" sur un ContentCard
       ↓
Vérifier connectivity → offline ? → Modal bloquant "Connexion requise"
       ↓ Online
Afficher bottom sheet :
  - Montant et label du contenu
  - Choix opérateur : [MTN Mobile Money] [Orange Money]
  - Numéro de téléphone (pré-rempli depuis profil si renseigné, sinon saisie)
  - Bouton "Payer X XAF"
       ↓
POST /api/payments/initiate {
  orderId, amount, currency: "XAF",
  phone: "+237XXXXXXXXX",       // E.164
  channel: "cm.mtn" | "cm.orange"
}
       ↓
Backend déclenche push USSD sur le téléphone → l'utilisateur voit la popup opérateur
       ↓
App affiche écran d'attente animé : "Confirme le paiement sur ton téléphone"
Polling toutes les 3s : GET /api/payments/{orderId}/status (max 15 tentatives / 45s)
       ↓ completed
  - Enrollment automatique (backend via webhook)
  - Stocker dans SQLite payments
  - Écran de succès + accès au contenu
       ↓ failed / expired
  - Message d'erreur avec option de réessayer
```

### Numéro de téléphone
- Prérempli depuis `user.phone` (profil) si renseigné au format E.164
- Sinon l'utilisateur saisit son numéro paiement (peut être différent du numéro d'inscription)
- Validation locale avant envoi : format `+237 6XXXXXXXX` ou `+237 2XXXXXXXX`

### Stockage local
La table `payments` SQLite est alimentée à chaque transaction confirmée.
L'écran "Paiements" (tab parent / étudiant) lit d'abord SQLite, puis sync avec l'API si online.

---

## 7. Téléchargement de fichiers — Solution proposée

### Contexte
Les fichiers (PDF, etc.) sont stockés sur **AWS S3** (`winplus-files-prod`).
Le backend a un endpoint `GET /api/subjects/{id}/download`.

### Solution recommandée : URL Signée (Signed URL)

**Flux :**
```
App → GET /api/subjects/{id}/download
      (avec JWT Authorization header)
       ↓
Backend génère une URL S3 pré-signée (15 min d'expiration)
Backend retourne { signed_url, filename, size }
       ↓
App télécharge directement depuis S3 via l'URL signée
(pas de transit par le backend → pas de charge serveur)
       ↓
Fichier sauvegardé dans getApplicationDocumentsDirectory()/downloads/
Entrée créée dans SQLite downloads
```

**Avantages :**
- Le backend vérifie l'auth avant d'émettre l'URL → sécurisé
- Le téléchargement est direct S3 → rapide, pas de bottleneck
- L'URL expire en 15 min → ne peut pas être partagée

**Inconvénient :**
- Nécessite que le backend gère les signed URLs (à vérifier / implémenter si pas déjà fait)

**Fallback** : si signed URL non supporté côté backend, utiliser le proxy backend (`/api/subjects/{id}/download` en streaming) jusqu'à implémentation.

---

## 8. Architecture des couches Flutter (à créer)

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Instance Dio + interceptors
│   │   ├── api_endpoints.dart         # Constantes URLs
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart  # Inject JWT + refresh
│   │       └── connectivity_interceptor.dart
│   ├── db/
│   │   ├── database.dart              # Init SQLite + migrations
│   │   └── daos/
│   │       ├── auth_dao.dart
│   │       ├── subjects_dao.dart
│   │       ├── payments_dao.dart
│   │       ├── downloads_dao.dart
│   │       └── queue_dao.dart
│   ├── auth/
│   │   ├── auth_repository.dart       # Login, signup, refresh, confirm
│   │   ├── biometric_service.dart     # local_auth wrapper
│   │   └── token_service.dart         # flutter_secure_storage wrapper
│   ├── connectivity/
│   │   └── connectivity_service.dart
│   └── logging/
│       └── app_logger.dart            # Logger vers fichier (voir §9)
│
├── features/
│   ├── auth/                          # Screens auth câblés
│   ├── catalog/                       # Catalogue depuis API
│   ├── payments/                      # Flux NotchPay
│   ├── chatbot/                       # WinAI câblé au backend
│   ├── student/
│   ├── parent/
│   ├── teacher/
│   └── institution/
│
├── data/
│   ├── models.dart                    # Garder + enrichir avec fromJson()
│   └── mock_data.dart                 # Garder temporairement pendant transition
```

---

## 9. Logging vers fichier (plus de terminal en production)

### Packages
- `logger: ^2.4.0`
- `path_provider: ^2.1.4`

### Logique

| Environnement | Console | Fichier |
|---|---|---|
| Debug (`kDebugMode`) | ✅ Actif | ✅ Actif |
| Release / Production | ❌ Désactivé | ✅ Actif |

### Format de fichier
- **Nom** : `winplus_YYYY-MM-DD.log`
- **Répertoire** : `getApplicationDocumentsDirectory()/logs/`
- **Format ligne** : `[2026-08-20T14:32:11] [LEVEL] [TAG] message`
- **Rotation** : supprimer les fichiers de plus de 7 jours au démarrage
- **Niveaux** : DEBUG, INFO, WARNING, ERROR

### Exemple de sortie fichier
```
[2026-08-20T14:32:11] [INFO] [AUTH] Login success — user: ahmed@email.cm, role: student
[2026-08-20T14:33:02] [WARN] [CONNECTIVITY] Network lost — queuing 1 action
[2026-08-20T14:35:44] [ERROR] [API] POST /api/payments/initiate → 422 phone format invalid
[2026-08-20T14:37:10] [INFO] [PAYMENT] Payment completed — orderId: ord_xxx, amount: 3000 XAF
```

### En debug
Les logs apparaissent aussi en console avec couleurs et formatage lisible (`PrettyPrinter`).

---

## 10. WinAI / Chatbot — État actuel et cible

### État actuel (mock)
Dans `lib/student/student_tabs.dart`, `StudentWinAITab` :
- UI de chat fonctionnelle (bulles, saisie, suggestions)
- Réponse hardcodée : `"Bien sûr ! Voici une explication claire..."` après 900ms
- Aucun appel réseau

### Cible
Câbler au backend :
```
User envoie un message
       ↓
POST /api/chatbot/message { conversationId?, message, context? }
       ↓
Backend → Python FastAPI (DeepSeek LLM)
       ↓
Réponse streaming ou différée
       ↓
Afficher dans les bulles
```

Historique :
```
Tab ouvert → GET /api/chatbot/history
           → charger les derniers messages dans la liste
```

L'`WinAIOrb` animée et l'interface de chat sont prêtes — seule la couche réseau est à brancher.

---

## 11. Packages Flutter à ajouter dans pubspec.yaml

```yaml
dependencies:
  # Existants
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8

  # À ajouter
  dio: ^5.4.0
  flutter_secure_storage: ^9.2.4
  local_auth: ^2.3.0
  sqflite: ^2.3.3
  connectivity_plus: ^6.1.1
  go_router: ^14.6.2
  flutter_riverpod: ^2.6.1
  logger: ^2.4.0
  path_provider: ^2.1.4
  shared_preferences: ^2.3.3
  url_launcher: ^6.3.1       # Pour ouvrir page NotchPay
  webview_flutter: ^4.10.0   # Alternative WebView in-app pour paiement

dev_dependencies:
  flutter_lints: ^4.0.0
```

---

## 12. Décisions arrêtées

| # | Question | Décision |
|---|---|---|
| 1 | Code de reconfirmation par email ou SMS ? | ✅ **Email** (Resend déjà configuré backend) |
| 2 | Fréquence de reconfirmation | ✅ **30 à 45 jours** (vérification côté mobile) |
| 3 | Biométrie obligatoire ou optionnelle ? | ✅ **Proposée à l'activation, jamais forcée** (style WhatsApp) |
| 4 | URL de base API | ✅ **`https://api.winplus.cm`** |
| 5 | Téléchargement fichiers S3 | ✅ **Signed URL déjà implémenté** (`SubjectsController.cs` L440–447, 15 min d'expiration) |
| 6 | Paiement in-app | ✅ **Pas de WebView** — flux 100% API, push USSD natif (MTN/Orange) |
| 7 | Endpoint `send-confirmation-code` | ✅ **Créé** — `POST /api/auth/send-confirmation-code` |
| 8 | Endpoint `verify-confirmation` | ✅ **Créé** — `POST /api/auth/verify-confirmation` |

---

## 13. Ordre d'implémentation recommandé

1. **`core/logging`** — logger fichier d'abord (observabilité dès le départ)
2. **`pubspec.yaml`** — ajouter tous les packages
3. **`core/db`** — SQLite, schéma, DAOs
4. **`core/api`** — Dio client + interceptors auth + connectivity
5. **`core/auth`** — token service + biometric service + auth repository
6. **Auth screens** — câbler login / signup / email verify / reconfirmation
7. **Catalog** — remplacer mock_data par appels API + cache SQLite
8. **Payments** — flux NotchPay complet
9. **WinAI** — câbler chatbot (`/api/chatbot/message`)
10. **Offline queue** — sync des actions différées
11. **Logs** — vérifier rotation et format en production

---

*Dernière mise à jour : 2026-08-20*
