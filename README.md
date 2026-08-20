# WinPlus  Application mobile (Flutter)

Plateforme éducative camerounaise : du BEPC aux concours des grandes écoles (ENSP, Polytechnique, FMSB, ENAM, ENS…). Paiement Mobile Money (MTN / Orange) en XAF, assistant pédagogique **WinAI**, et 4 types de comptes.

> Ce projet est la **traduction Flutter fidèle** du prototype HTML de référence. La charte (couleurs, typographie, espacements, composants) y est intégralement reportée. Les comptes **Étudiant** et **Parent** sont câblés ; **Professeur** et **Institution** sont scaffoldés (écran « Bientôt disponible ») et se construisent sur la même architecture.

## Démarrage

```bash
flutter pub get
flutter run
```

Flutter SDK ≥ 3.3. Les polices **Fraunces** + **Manrope** sont chargées dynamiquement via `google_fonts` (aucun fichier de police à embarquer).

## Architecture

```
lib/
├── main.dart                  Point d'entrée, MaterialApp + thème réactif
├── app_state.dart             État global (thème clair/sombre + rôle actif)
│
├── theme/
│   ├── win_colors.dart        Tokens bruts : Ink, Teal, Blue, Cream, sémantique, espacements, rayons, ombres
│   ├── win_typography.dart    Échelle typographique (Fraunces + Manrope)
│   └── win_theme.dart         WinScheme (rôles clair/sombre) + WinTheme (InheritedWidget) + ThemeData
│
├── data/
│   ├── models.dart            Modèles : Subject, Content, Quiz, Child, Notification, RoleInfo…
│   └── mock_data.dart         Données camerounaises réalistes (épreuves, prix XAF, matières, enfants)
│
├── widgets/
│   └── win_widgets.dart       WinButton, WinCard, WinChip, WinBadge, WinTextField,
│                              WinAvatar (avec anneau de progression), WinProgressBar,
│                              WinAIOrb (animé), WinStreakFlame
│
├── auth/
│   ├── splash_screen.dart     Splash animé (logo) → bascule auto
│   ├── welcome_screen.dart    Accueil + emplacement d'image à remplir
│   ├── role_screen.dart       Sélection du rôle (Étudiant / Parent / Prof / Institution)
│   └── login_screen.dart      Connexion + boutons sociaux (Google bien visible)
│
├── shell/
│   └── role_shell.dart        Coquille + barre de navigation propre à chaque rôle
│
├── student/
│   ├── student_home.dart      Accueil étudiant (héro WinAI, recommandations, stats)
│   └── student_tabs.dart      Catalogue, Mon Espace, WinAI (chat), Communauté
│
├── parent/
│   └── parent_tabs.dart       Accueil (synthèse enfants + alertes WinAI), Enfants,
│                              Ressources, Paiements, Profil
│
├── teacher/
│   └── teacher_tabs.dart      Accueil, Contenus (statuts), Étudiants, Sessions, Revenus
│
└── institution/
    └── institution_tabs.dart  Accueil, Groupes, Catalogue, Analytics, Compte (licence)
```

## Les 4 comptes

Les **4 types de comptes sont complets** : Étudiant, Parent, Professeur, Institution. Chacun a sa propre barre de navigation et ses 5 onglets, gérés par `RoleShell` selon `WinAppState.role`.

## Mode sombre

Charcoal neutre type WhatsApp (`#121617`), jamais vert  le teal reste uniquement en couleur d'accent. Basculer : `WinAppScope.of(context).toggleTheme();`

## Rôles

`WinAppScope.of(context).setRole(WinRole.student)` change le compte actif. La coquille (`RoleShell`) recompose automatiquement la barre de navigation et les écrans correspondants.

## Images d'onboarding

Les écrans d'onboarding utilisent des emplacements (`_ImageSlot`). Remplace-les par un `Image.asset('assets/ton_image.png')` une fois tes visuels fournis (et ajoute-les à la section `assets:` du `pubspec.yaml`).

## À compléter (mêmes fondations)

- Inscription + OTP + complétion de profil (Google uniquement, le flow est cartographié dans le prototype HTML)
- Sous-écrans : détail de contenu, lecteur PDF, quiz interactif complet, paiement Mobile Money (sheet → attente → succès), centre de notifications, détail enfant / détail groupe
- Branchement d'un backend réel + état (Riverpod / Bloc recommandé) à la place des `mock_data`

---

© WinPlus  charte et contenu conformes au cahier des charges. Prix en XAF.
