# Lot 4 — socle visuel et authentification

Première livraison du 15 novembre 2026. Le lot 4 reste **en cours**.

## Changements

- En-tête réutilisable : retour rond de 44 px, titre, marque et action facultatifs.
- Formulaires défilants limités à 460 px, compatibles avec le clavier.
- Champs de 54 px minimum, bordure fine, rayon 14, libellé au-dessus et aucune icône à gauche. Les actions de fin de champ restent accessibles.
- Typographie Archivo pour les titres et le corps, rayons et boutons rapprochés des variables du site actuel. Les petits boutons font au moins 44 px.
- État vide, erreur avec nouvelle tentative et feuille du bas communs, prêts à être adoptés par les autres écrans.
- Squelette, boutons et mascotte respectant la réduction des animations. Les boutons chargent avec les trois points ; la lecture du rôle utilise Kamé et les points. Les planches de Kamé viennent des fichiers existants du site.
- Reprise visuelle du choix de rôle, inscription, vérification du code, mots de passe, questionnaires de profil, succès et adresse vérifiée. Conservation des appels serveur, validations et destinations de navigation.
- Suppression du héros dégradé de l'inscription. Suppression du confetti et de son animation sur la confirmation d'adresse.

Le mode sombre existant est conservé. Aucun service, fichier Android/iOS, mécanisme hors ligne ni traduction n'est modifié par cette livraison.

## Vérifications

- Suite complète : **1 481 tests passent, 8 ignorés**.
- Après le dernier remplacement du chargement de rôle : **172 tests d'authentification passent**, captures comprises.
- Matrice de 108 cas : 9 écrans, français/anglais, clair/sombre, largeurs 320/390/768, texte système doublé. Pas de débordement détecté. Cette matrice couvre l'état initial de chaque écran, pas chaque état métier.
- Vérification du formulaire d'inscription avec clavier ouvert à 320 px ; contrôle des zones tactiles et de l'arrêt des animations.
- Analyse : aucune erreur ni avertissement ; les informations de style préexistantes restent à traiter séparément.
- Tests des composants actualisés pour les nouvelles spécifications du site (rayons, couleur, points de chargement, minimum tactile et absence d'icône dans les champs).

Les tests utilisent le faux réseau du projet, sans créer de compte ni écrire en production.

## Captures et reproduction

Les artefacts locaux sont dans `M:/dev-cache/mobile-lot4-artifacts/` : journaux, neuf captures Flutter à 390 px, captures du site et page de comparaison `comparaison.html`.

```powershell
flutter test --no-pub test/ecrans/auth
flutter test --no-pub
flutter analyze --no-pub

# Captures facultatives : le dossier de polices contient Archivo_400.ttf à
# Archivo_900.ttf, correspondant aux variantes du paquet google_fonts.
$env:LOT4_CAPTURES = '<dossier de sortie>'
$env:LOT4_FONTS = '<dossier des polices Archivo>'
flutter test --no-pub test/ecrans/auth/lot4_design_test.dart --plain-name capture
```

Sans polices de revue, Flutter utilise sa police de test : ces images servent uniquement à examiner la structure. Le chargement des vraies polices et des icônes est facultatif et réservé à la production de captures locales.

## À poursuivre avant de clore le lot

- Comparaison visuelle et captures de tous les écrans et états, dans les quatre espaces. Cette livraison ne valide pas une parité visuelle complète de l'authentification : des textes et structures diffèrent encore, notamment l'inscription en étapes du site et le formulaire natif, ainsi que le logo central de connexion.
- L'adresse vérifiée du site redirige vers la connexion sans session : sa capture ne prouve pas l'équivalence de l'écran de confirmation. Les états privés nécessitent un parcours de test connecté.
- Relecture des accueils, onglets et catalogue, puis contenu, formations, quiz, commerce, communauté, répétiteurs et espaces métiers dans l'ordre du plan.
- Adoption progressive des nouveaux états et en-têtes communs par les autres écrans.
- Suppression des références `heroFrom`/`heroTo` restantes dans l'espace parent, le portefeuille professeur et le profil public du répétiteur. Le portefeuille professeur est actuellement modifié par l'autre travail en cours ; il n'est pas touché ici.
- Revue des états suivants des questionnaires professeur et parent, des erreurs et des succès sur petit écran avec texte agrandi ; captures clair/sombre supplémentaires.
- Décision produit sur le maintien à terme du mode sombre et vérifications sur téléphone réel.

Aucun déploiement, aucune publication de version mobile.
