# Journal des versions de WinPlus mobile

Le nom de version (par exemple 3.1.0) est dans `pubspec.yaml`. Le numéro de compilation des versions produites par GitHub Actions est le numéro d'exécution + 100 : il augmente toujours, comme l'exige le Play Store.

Pour publier une version : passer le nom de version dans `pubspec.yaml`, déplacer la rubrique « Non publié » sous ce numéro, puis poser l'étiquette `vX.Y.Z`. L'étiquette lance aussi la compilation iOS sans signature.

## Non publié

### Application

- Ouverture directe sur l'espace du compte, ou sur la connexion sans session. Les écrans de présentation du site ne sont plus repris.
- Connexion redessinée sur la version téléphone du site.
- La version de production a enfin accès au réseau (permission Internet).
- Session : jetons dans le stockage sécurisé du téléphone ; retour à la connexion avec un message quand la session expire ; l'e-mail enregistré n'est plus effacé au renouvellement du jeton.
- Reconfirmation d'identité demandée par le serveur, jamais bloquante hors ligne.
- Notifications application fermée sur Android, sans Firebase : écoute instantanée avec une notification discrète, désactivable dans l'écran des notifications ; vérification de secours toutes les 15 minutes environ.
- Nombreux débordements d'affichage corrigés sur les petits écrans.
- Répétiteurs attribués visibles même sans réservation ; formateur affiché sur la fiche d'une formation.

### Plateformes

- Projet iOS créé (identifiant `cm.winplus.app`) : icônes, écran de démarrage, textes d'autorisation (appareil photo, photos). Compilation et signature reportées.
- Compilation automatique (GitHub Actions) : tests, APK et AAB Android ; iOS sans signature sur étiquette.

### Qualité

- Suite de tests remise en service : plus de 1 300 tests, une minute au plus par test d'écran.

## 3.1.0 (2)

Dernière version avant ce journal.
