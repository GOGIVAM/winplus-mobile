# Cas de test manuel — Espace Professeur / Répétiteur WinPlus

Basé sur `professeur_complete.md` et `prompt_prof.md`.
Convention ID : `TC-[MODULE]-[Numéro]`. Priorité : Haute / Moyenne / Basse.

---

## MODULE 1 — ONBOARDING ET PROFIL

**TC-PRO-01 — Onboarding complet en 5 étapes**
- Précondition : nouvel utilisateur avec rôle Professeur, aucun profil rempli.
- Étapes : Lancer l'onboarding → remplir étapes 1 à 5 → valider à chaque étape.
- Résultat attendu : stepper visuel affiche la progression ; chaque étape sauvegarde indépendamment ; score de complétude (0-100) affiché à la fin avec éléments manquants cliquables.
- Priorité : Haute

**TC-PRO-02 — Reprise après fermeture accidentelle**
- Précondition : onboarding démarré, étapes 1-2 complétées.
- Étapes : Fermer l'app/onglet sans terminer → rouvrir l'onboarding.
- Résultat attendu : l'utilisateur reprend à l'étape 3, données des étapes 1-2 conservées.
- Priorité : Haute

**TC-PRO-03 — Profil fonctionnel dès l'étape 3**
- Étapes : Compléter uniquement les étapes 1 à 3, ignorer 4 et 5, valider.
- Résultat attendu : le profil est activable/fonctionnel ; étapes 4-5 restent marquées optionnelles.
- Priorité : Moyenne

**TC-PRO-04 — Multiselect matières et niveaux**
- Étapes : Sélectionner plusieurs matières et niveaux (6ème à Tle, BEPC, BAC, prépas, concours ENSP/Polytechnique/FMSB/ENAM/ENS) → enregistrer.
- Résultat attendu : toutes les sélections sont conservées ; profil indexé et visible en recherche sous 5 minutes.
- Priorité : Haute

**TC-PRO-05 — Champ spécialités en tags libres**
- Étapes : Ajouter des tags "Préparation concours", "Rattrapage express" + un tag personnalisé.
- Résultat attendu : tags enregistrés et affichés sur le profil public.
- Priorité : Basse

**TC-PRO-06 — Upload diplôme valide (PDF)**
- Étapes : Uploader un PDF de 5 Mo comme justificatif de diplôme.
- Résultat attendu : upload réussi, document en file de vérification admin, statut "En attente de vérification".
- Priorité : Haute

**TC-PRO-07 — Upload diplôme fichier trop volumineux**
- Étapes : Tenter d'uploader un PDF de 15 Mo (> 10 Mo).
- Résultat attendu : message d'erreur clair, upload refusé.
- Priorité : Moyenne

**TC-PRO-08 — Upload diplôme format non supporté**
- Étapes : Tenter d'uploader un fichier .docx.
- Résultat attendu : rejet avec message précisant les formats acceptés (PDF, JPG, PNG).
- Priorité : Basse

**TC-PRO-09 — Validation admin du diplôme (badge)**
- Précondition : diplôme uploadé et en attente.
- Étapes : (Côté admin) valider le document.
- Résultat attendu : email de confirmation envoyé (sous 48h simulées) ; badge "Vérifié Diplôme" apparaît sur le profil public.
- Priorité : Haute

**TC-PRO-10 — Refus du diplôme par l'admin**
- Étapes : (Côté admin) refuser le document avec un motif.
- Résultat attendu : le professeur reçoit le motif ; possibilité de soumettre un nouveau document.
- Priorité : Moyenne

**TC-PRO-11 — Analyse WinAI du profil**
- Précondition : profil partiellement rempli (bio courte, pas de vidéo).
- Étapes : Déclencher "Analyser mon profil avec WinAI".
- Résultat attendu : suggestions concrètes affichées, chaque suggestion a un bouton "Compléter" qui navigue vers le champ concerné ; comparaison avec profils bien notés de la même matière.
- Priorité : Moyenne

**TC-PRO-12 — Activation du mode Répétiteur**
- Précondition : compte Professeur existant, mode Répétiteur inactif.
- Étapes : Aller dans Paramètres > Modes d'exercice > Activer "Mode Répétiteur".
- Résultat attendu : onboarding dédié en 5 étapes se lance (matières/niveaux, zones, tarif, disponibilités, bio/vidéo).
- Priorité : Haute

**TC-PRO-13 — Suggestion de tarif WinAI pendant l'étape 3**
- Étapes : Arriver à l'étape tarif de l'onboarding répétiteur.
- Résultat attendu : WinAI propose un tarif horaire contextualisé (matière/niveau/zone) ; le professeur peut l'accepter ou le modifier.
- Priorité : Moyenne

**TC-PRO-14 — Prévisualisation avant activation du profil répétiteur**
- Étapes : Terminer les 5 étapes → écran de prévisualisation.
- Résultat attendu : aperçu fidèle du profil public affiché avant validation finale ; activation rend le profil visible immédiatement en recherche.
- Priorité : Haute

**TC-PRO-15 — Ajout vidéo d'introduction (lien YouTube valide)**
- Étapes : Coller une URL YouTube valide dans le champ vidéo.
- Résultat attendu : vidéo lisible en lecteur embarqué sur la fiche publique.
- Priorité : Moyenne

**TC-PRO-16 — Ajout vidéo d'introduction (lien invalide)**
- Étapes : Saisir une URL invalide/non vidéo.
- Résultat attendu : message d'erreur clair, champ non validé, activation du profil non bloquée (vidéo optionnelle).
- Priorité : Basse

**TC-PRO-17 — Zones géographiques d'intervention**
- Étapes : Sélectionner plusieurs quartiers/communes (Douala, Yaoundé) pour "à domicile".
- Résultat attendu : zones enregistrées ; option "En ligne uniquement" désactive la sélection géographique quand cochée.
- Priorité : Moyenne

**TC-PRO-18 — Grille de disponibilités hebdomadaires**
- Étapes : Ouvrir la grille 7 jours × plages horaires → taper plusieurs cases pour les activer.
- Résultat attendu : sauvegarde instantanée sans bouton "Enregistrer" ; état visuellement confirmé.
- Priorité : Haute

**TC-PRO-19 — Bouton "Reproduire cette semaine"**
- Précondition : une semaine de disponibilités configurée.
- Étapes : Cliquer sur "Reproduire cette semaine".
- Résultat attendu : la grille se propage aux semaines suivantes indéfiniment (vérifier au moins 2-3 semaines à venir).
- Priorité : Moyenne

**TC-PRO-20 — Délai de préavis minimum**
- Étapes : Choisir un délai de préavis (12h/24h/48h) → enregistrer → tenter une réservation élève dans ce délai.
- Résultat attendu : réservation dans le délai bloquée ou signalée comme non conforme.
- Priorité : Haute

**TC-PRO-21 — Nombre max de séances/semaine atteint**
- Précondition : max séances/semaine = 3, 3 séances déjà confirmées cette semaine.
- Étapes : Un élève tente de réserver une 4e séance sur la même semaine.
- Résultat attendu : calendrier fermé automatiquement pour cette semaine côté élève.
- Priorité : Haute

**TC-PRO-22 — Statut "En vacances"**
- Étapes : Activer le statut "En vacances" depuis les paramètres.
- Résultat attendu : profil reste visible en recherche avec mention "Indisponible pour le moment" ; aucune nouvelle réservation possible ; séances déjà confirmées non annulées.
- Priorité : Haute

**TC-PRO-23 — Désactivation du statut "En vacances"**
- Étapes : Cliquer sur "Désactiver".
- Résultat attendu : retour immédiat à la disponibilité normale, réservations à nouveau possibles.
- Priorité : Moyenne

**TC-PRO-24 — Création de forfaits multi-séances**
- Étapes : Créer "Pack 5 séances" et "Pack 10 séances" avec prix dégressif.
- Résultat attendu : forfaits affichés sur la fiche publique ; prix inférieur à la somme des séances individuelles.
- Priorité : Moyenne

**TC-PRO-25 — Achat d'un forfait et compteur de séances**
- Précondition : forfait "Pack 5 séances" créé.
- Étapes : Un élève achète le pack → consomme 3 séances.
- Résultat attendu : compteur "2 séances restantes" visible pour les deux parties.
- Priorité : Haute

**TC-PRO-26 — Alerte renouvellement de forfait**
- Précondition : il reste 2 séances dans le pack.
- Étapes : Consulter le profil/dashboard de l'élève ou du répétiteur.
- Résultat attendu : suggestion de renouvellement affichée automatiquement.
- Priorité : Basse

**TC-PRO-27 — Séance d'essai (gratuite ou tarif réduit)**
- Étapes : Cocher "Proposer une séance d'essai" avec prix 0.
- Résultat attendu : étiquette distinctive visible sur la fiche publique ; un même élève ne peut en bénéficier qu'une fois avec ce répétiteur (tenter une 2e réservation d'essai → refusée).
- Priorité : Moyenne

---

## MODULE 2 — RECHERCHE ET RÉSERVATION (CÔTÉ ÉLÈVE)

**TC-REP-01 — Recherche par matière et niveau (obligatoires)**
- Étapes : Lancer une recherche sans renseigner matière ni niveau.
- Résultat attendu : validation bloque la recherche ou affiche un message demandant ces champs obligatoires.
- Priorité : Haute

**TC-REP-02 — Recherche avec tous les filtres combinés**
- Étapes : Filtrer par matière, niveau, mode (à domicile/en ligne/mixte), quartier, tarif max, disponibilité ("dès aujourd'hui"), note minimale, badge "Vérifié".
- Résultat attendu : résultats cohérents avec tous les filtres appliqués simultanément.
- Priorité : Haute

**TC-REP-03 — Tri par pertinence (défaut)**
- Étapes : Effectuer une recherche sans changer le tri.
- Résultat attendu : résultats triés par pertinence (note × volume séances × réactivité), vérifiable par comparaison de 2-3 profils connus.
- Priorité : Moyenne

**TC-REP-04 — Tri prix croissant / prochain créneau**
- Étapes : Changer le tri vers "Prix croissant" puis "Prochain créneau disponible".
- Résultat attendu : l'ordre des résultats change en conséquence.
- Priorité : Basse

**TC-REP-05 — Filtre géographique disponible seulement en mode "à domicile"**
- Étapes : Sélectionner mode "En ligne" puis vérifier le filtre localisation.
- Résultat attendu : le filtre quartier/commune est désactivé ou masqué en mode "En ligne".
- Priorité : Basse

**TC-REP-06 — Carte résultat complète**
- Étapes : Consulter la liste de résultats.
- Résultat attendu : chaque carte affiche photo, nom, note, tarif, badge vérifié, prochain créneau libre, distance estimée (si domicile).
- Priorité : Moyenne

**TC-REP-07 — Fiche répétiteur complète**
- Étapes : Ouvrir la fiche d'un répétiteur depuis les résultats.
- Résultat attendu : bio, vidéo, tarifs/forfaits, calendrier horizontal 14 jours, avis (3 + "Voir tout"), matières/niveaux, zones, politique d'annulation tous visibles ; bouton "Réserver" sticky en bas.
- Priorité : Haute

**TC-REP-08 — Message pré-réservation**
- Étapes : Depuis la fiche, cliquer "Envoyer un message" avant réservation.
- Résultat attendu : conversation créée dans la messagerie ; le répétiteur peut y répondre depuis son onglet Messages ou la notification.
- Priorité : Moyenne

**TC-REP-09 — Réservation écran 1 : choix créneau**
- Étapes : Sélectionner un jour dans le calendrier horizontal → choisir un créneau vert (disponible) et une durée.
- Résultat attendu : créneau sélectionné mis en évidence, passage à l'écran récapitulatif.
- Priorité : Haute

**TC-REP-10 — Tentative de réservation sur un créneau indisponible**
- Étapes : Tenter de sélectionner un créneau grisé.
- Résultat attendu : sélection impossible / bouton désactivé.
- Priorité : Haute

**TC-REP-11 — Réservation écran 2 : récapitulatif + message**
- Étapes : Vérifier date/heure/durée/mode/prix (avec commission visible) ; saisir un message de 100 caractères max.
- Résultat attendu : au-delà de 100 caractères, saisie bloquée ; bouton "Payer maintenant" actif.
- Priorité : Moyenne

**TC-REP-12 — Réservation écran 3 : paiement Mobile Money réussi**
- Étapes : Saisir numéro MTN/Orange, confirmer via USSD (simulation), attendre polling de statut.
- Résultat attendu : écran de succès avec récapitulatif et bouton "Voir ma séance" ; fonds retenus en escrow.
- Priorité : Haute

**TC-REP-13 — Paiement Mobile Money échoué**
- Étapes : Simuler un échec de paiement (solde insuffisant / annulation USSD).
- Résultat attendu : message d'erreur clair, réservation non créée, aucun fond débité.
- Priorité : Haute

**TC-REP-14 — Notification push nouvelle demande au répétiteur**
- Précondition : réservation payée par un élève.
- Étapes : Attendre jusqu'à 30s après la demande.
- Résultat attendu : notification reçue par le répétiteur avec nom élève, matière, niveau, créneau.
- Priorité : Haute

**TC-REP-15 — Acceptation d'une demande depuis la notification**
- Étapes : Cliquer "Accepter" directement depuis la notification (sans ouvrir l'app).
- Résultat attendu : réservation confirmée ; élève notifié avec détails de session.
- Priorité : Haute

**TC-REP-16 — Refus d'une demande**
- Étapes : Cliquer "Refuser" avec motif optionnel.
- Résultat attendu : élève notifié du refus ; remboursement automatique déclenché.
- Priorité : Haute

**TC-REP-17 — Expiration automatique d'une demande**
- Précondition : délai de préavis 24h configuré.
- Étapes : Ne pas répondre à une demande pendant 24h.
- Résultat attendu : statut passe à "Expiré", remboursement automatique, élève notifié.
- Priorité : Haute

**TC-REP-18 — Marquer une séance comme effectuée**
- Précondition : séance confirmée, heure de fin atteinte.
- Étapes : Cliquer "Marquer comme effectuée".
- Résultat attendu : bouton visible dès l'heure de fin prévue ; délai de contestation de 2h démarre.
- Priorité : Haute

**TC-REP-19 — Libération automatique des fonds sans contestation**
- Précondition : séance marquée effectuée il y a plus de 2h, aucune contestation.
- Étapes : Vérifier le solde du répétiteur.
- Résultat attendu : fonds libérés automatiquement vers le solde WinPlus ; élève invité à noter la séance.
- Priorité : Haute

**TC-REP-20 — Contestation dans les 2h (litige)**
- Étapes : L'élève clique "Signaler un problème" moins de 2h après le marquage.
- Résultat attendu : fonds gelés, les deux parties notifiées, dossier envoyé au support avec historique de messagerie.
- Priorité : Haute

**TC-REP-21 — Résolution d'un litige (remboursement/libération)**
- Précondition : litige en cours.
- Étapes : (Côté support) décider remboursement total / partiel / libération.
- Résultat attendu : les deux parties reçoivent la décision par notification et email ; solde mis à jour en conséquence.
- Priorité : Moyenne

**TC-REP-22 — Notation post-séance**
- Précondition : fonds libérés.
- Étapes : Répondre à l'invitation de notation → 5 étoiles + commentaire (300 caractères max).
- Résultat attendu : avis enregistré ; un élève ne peut noter qu'une seule fois par séance.
- Priorité : Haute

**TC-REP-23 — Tentative de double notation**
- Étapes : Tenter de noter deux fois la même séance.
- Résultat attendu : action bloquée après la première notation.
- Priorité : Basse

**TC-REP-24 — Réponse publique du répétiteur à un avis**
- Étapes : Depuis le profil, répondre à un avis existant.
- Résultat attendu : réponse visible publiquement sous l'avis.
- Priorité : Basse

**TC-REP-25 — Signalement d'un avis abusif**
- Étapes : Cliquer "Signaler" sur un avis.
- Résultat attendu : signalement transmis à la modération, avis marqué en attente de revue.
- Priorité : Basse

---

## MODULE 3 — MESSAGERIE

**TC-MSG-01 — Envoi message texte à un contact du réseau**
- Précondition : élève lié / inscrit à une formation / classe / réservation existante.
- Étapes : Ouvrir la conversation → envoyer un message texte.
- Résultat attendu : message envoyé, visible immédiatement chez le destinataire.
- Priorité : Haute

**TC-MSG-02 — Blocage message hors réseau**
- Précondition : utilisateur A et B sans lien commun (pas élève, pas classe, pas formation, pas réservation).
- Étapes : A tente d'envoyer un message direct à B.
- Résultat attendu : message bloqué ; une demande de contact doit être envoyée et acceptée au préalable.
- Priorité : Haute

**TC-MSG-03 — Envoi pièce jointe PDF**
- Étapes : Joindre un PDF de 15 Mo (< 20 Mo).
- Résultat attendu : envoi réussi, aperçu du fichier dans le fil.
- Priorité : Moyenne

**TC-MSG-04 — Envoi pièce jointe trop lourde**
- Étapes : Joindre un PDF de 25 Mo.
- Résultat attendu : rejet avec message d'erreur clair (limite 20 Mo).
- Priorité : Basse

**TC-MSG-05 — Envoi note vocale**
- Étapes : Enregistrer une note vocale de 2 minutes et l'envoyer (mobile).
- Résultat attendu : note vocale lisible dans le fil ; rejet si > 5 minutes.
- Priorité : Moyenne

**TC-MSG-06 — Partage d'un lien contenu WinPlus**
- Étapes : Partager un lien vers une épreuve du catalogue dans une conversation.
- Résultat attendu : carte de prévisualisation inline générée (titre, type, note).
- Priorité : Basse

**TC-MSG-07 — Carte lien de session (cours particulier)**
- Précondition : réservation confirmée.
- Étapes : Vérifier la conversation liée à la réservation.
- Résultat attendu : carte spéciale avec les détails de la séance générée automatiquement.
- Priorité : Moyenne

**TC-MSG-08 — Création d'un groupe depuis une classe**
- Étapes : Créer un groupe en important les membres d'une classe existante.
- Résultat attendu : tous les membres de la classe ajoutés automatiquement au groupe.
- Priorité : Moyenne

**TC-MSG-09 — Épingler une annonce dans un groupe**
- Précondition : professeur créateur du groupe.
- Étapes : Épingler un message.
- Résultat attendu : message affiché en haut du fil ; un membre non-créateur ne peut pas épingler.
- Priorité : Basse

**TC-MSG-10 — Mode "Canal d'annonce" (unidirectionnel)**
- Étapes : Activer le mode annonce → un membre tente de répondre.
- Résultat attendu : seuls les réactions sont possibles pour les membres, pas de nouveaux messages.
- Priorité : Moyenne

**TC-MSG-11 — Mention @Nom dans un groupe**
- Étapes : Taper "@" et sélectionner un membre.
- Résultat attendu : le membre mentionné reçoit une notification spécifique.
- Priorité : Basse

**TC-MSG-12 — Activation du canal de formation**
- Étapes : Depuis les paramètres de la formation, activer le canal.
- Résultat attendu : tous les élèves inscrits rejoignent automatiquement le canal.
- Priorité : Moyenne

**TC-MSG-13 — Q&A automatique WinAI (réponse confiante)**
- Précondition : Q&A activé sur le canal.
- Étapes : Un élève pose une question dont la réponse est dans le contenu des leçons.
- Résultat attendu : WinAI répond avec la mention "Réponse générée par WinAI — à vérifier avec ton professeur".
- Priorité : Haute

**TC-MSG-14 — Q&A automatique WinAI (confiance faible)**
- Étapes : Poser une question ambiguë ou hors contenu de la formation.
- Résultat attendu : WinAI ne répond pas et tague automatiquement le professeur au lieu de répondre.
- Priorité : Haute

**TC-MSG-15 — Correction d'une réponse IA par le professeur**
- Étapes : Depuis le journal des interactions IA, corriger une réponse WinAI.
- Résultat attendu : correction enregistrée et visible dans le canal.
- Priorité : Basse

**TC-MSG-16 — Réponse contextuelle (citation)**
- Étapes : Tap long sur un message → "Répondre".
- Résultat attendu : le message original apparaît en citation au-dessus de la réponse.
- Priorité : Basse

**TC-MSG-17 — Réaction emoji**
- Étapes : Réagir à un message avec 👍.
- Résultat attendu : réaction visible sous le message sans encombrer le fil.
- Priorité : Basse

**TC-MSG-18 — Statut de lecture**
- Étapes : Envoyer un message 1-to-1 → destinataire ouvre la conversation.
- Résultat attendu : statut "Lu" apparaît sous le message côté expéditeur.
- Priorité : Moyenne

**TC-MSG-19 — Message programmé**
- Étapes : Rédiger un message, programmer l'envoi dans 20 minutes.
- Résultat attendu : message listé dans "À envoyer", envoyé automatiquement à l'heure prévue même si l'expéditeur est hors ligne.
- Priorité : Moyenne

**TC-MSG-20 — Annulation d'un message programmé**
- Étapes : Annuler un message programmé avant son heure d'envoi.
- Résultat attendu : le message n'est jamais envoyé.
- Priorité : Basse

**TC-MSG-21 — Programmation à moins de 15 minutes**
- Étapes : Tenter de programmer un envoi dans 5 minutes.
- Résultat attendu : validation refuse (minimum 15 minutes).
- Priorité : Basse

**TC-MSG-22 — Réponses rapides IA**
- Étapes : Recevoir un message → vérifier les 3 suggestions affichées.
- Résultat attendu : suggestions contextuelles pertinentes ; tap pré-remplit le champ de composition (modifiable avant envoi).
- Priorité : Moyenne

**TC-MSG-23 — Modèles de messages**
- Étapes : Créer un modèle avec variable {{NomEleve}} → l'utiliser dans une conversation.
- Résultat attendu : variable remplacée automatiquement par le nom réel de l'élève.
- Priorité : Basse

**TC-MSG-24 — Recherche dans les conversations**
- Étapes : Rechercher un mot-clé présent dans un ancien message.
- Résultat attendu : résultat affiché avec contexte (5 messages avant/après), filtrable par non lus/pièces jointes/conversation/période.
- Priorité : Moyenne

**TC-MSG-25 — Archivage d'une conversation**
- Étapes : Swipe gauche (mobile) ou action équivalente (web) sur une conversation → archiver.
- Résultat attendu : conversation déplacée dans l'onglet "Archivées", reste accessible.
- Priorité : Basse

**TC-MSG-26 — Génération communication parents via WinAI**
- Étapes : Saisir un résumé libre (2-3 lignes) → générer.
- Résultat attendu : message formel généré avec progression chiffrée, points positifs, axes d'amélioration, devoirs listés ; éditable avant envoi.
- Priorité : Moyenne

---

## MODULE 4 — CATALOGUE ET BIBLIOTHÈQUE (PROFESSEUR-ACHETEUR)

**TC-CAT-01 — Recherche catalogue avec filtres combinés**
- Étapes : Filtrer par type, examen, matière, année, difficulté, prix.
- Résultat attendu : résultats cohérents ; compteur de résultats mis à jour en temps réel ; recherche textuelle avec délai ~400ms.
- Priorité : Haute

**TC-CAT-02 — Indicateur "X enseignants ont utilisé ce contenu"**
- Précondition : compte connecté avec rôle Professeur.
- Étapes : Ouvrir une fiche contenu.
- Résultat attendu : compteur visible et distinct du compteur de téléchargements ; invisible pour un compte élève.
- Priorité : Moyenne

**TC-CAT-03 — Ajouter un contenu acheté à une formation**
- Précondition : contenu déjà acheté, au moins une formation en brouillon.
- Étapes : Cliquer "Ajouter à une formation" → sélectionner la formation.
- Résultat attendu : contenu ajouté comme leçon "Fichier" dans la section choisie.
- Priorité : Haute

**TC-CAT-04 — Bouton "Acheter pour ajouter" si non acheté**
- Étapes : Ouvrir la fiche d'un contenu non acheté.
- Résultat attendu : le bouton affiche "Acheter pour ajouter à une formation" au lieu de "Ajouter".
- Priorité : Basse

**TC-CAT-05 — Assigner un contenu à une classe**
- Précondition : contenu acheté, au moins une classe créée.
- Étapes : Cliquer "Assigner à une classe" → sélectionner une ou plusieurs classes → confirmer le coût affiché.
- Résultat attendu : montant déduit une seule fois du solde professeur ; tous les élèves de la classe voient le contenu avec la mention "Assigné par [Nom]".
- Priorité : Haute

**TC-CAT-06 — Bibliothèque personnelle : organisation en dossiers**
- Étapes : Créer un dossier personnalisé → y déplacer un contenu.
- Résultat attendu : contenu classé, retrouvable via le dossier.
- Priorité : Moyenne

**TC-CAT-07 — Notes privées sur un contenu**
- Étapes : Ajouter une note de 300 caractères sur un contenu de la bibliothèque.
- Résultat attendu : note visible uniquement par le professeur propriétaire ; dépassement de 300 caractères bloqué.
- Priorité : Basse

**TC-CAT-08 — Recherche dans la bibliothèque**
- Étapes : Rechercher par titre/matière/niveau dans "Ma bibliothèque".
- Résultat attendu : résultats filtrés correctement.
- Priorité : Basse

**TC-CAT-09 — Partage d'un contenu de la bibliothèque en messagerie**
- Étapes : Depuis un item de la bibliothèque, cliquer "Partager dans une conversation".
- Résultat attendu : carte de prévisualisation envoyée dans la conversation choisie.
- Priorité : Basse

**TC-CAT-10 — Paiement avec solde WinPlus**
- Précondition : solde suffisant pour le contenu du panier.
- Étapes : À l'étape de paiement, choisir "Payer avec mon solde WinPlus".
- Résultat attendu : transaction validée sans Mobile Money, débit enregistré dans l'historique.
- Priorité : Moyenne

**TC-CAT-11 — Paiement avec solde insuffisant (complément MoMo)**
- Précondition : solde inférieur au prix du contenu.
- Étapes : Choisir paiement solde + complément Mobile Money.
- Résultat attendu : le différentiel est proposé en paiement MoMo ; transaction combinée réussie.
- Priorité : Moyenne

**TC-CAT-12 — Recommandations WinAI proactives**
- Étapes : Consulter le tableau de bord, section "Recommandé pour toi".
- Résultat attendu : recommandations accompagnées d'une justification courte ; bouton "Pas intéressé" masque durablement la recommandation.
- Priorité : Basse

**TC-CAT-13 — Tags et annotations personnelles**
- Étapes : Ajouter un tag "À acheter" et une note de 150 caractères sur un contenu consulté.
- Résultat attendu : annotation conservée entre sessions ; filtre "Mes annotations" affiche uniquement les contenus annotés.
- Priorité : Basse

**TC-CAT-14 — Hub des concours camerounais**
- Étapes : Naviguer vers le hub, sélectionner un concours (ex. ENSP) puis filtrer par année/matière.
- Résultat attendu : page dédiée accessible sans abonnement, épreuves filtrables, FAQ et calendrier visibles.
- Priorité : Basse

---

## MODULE 5 — PUBLICATION DE CONTENU

**TC-PUB-01 — Publication en 4 étapes (parcours complet)**
- Étapes : Étape 1 type → Étape 2 métadonnées → Étape 3 upload PDF → Étape 4 prévisualisation → soumission.
- Résultat attendu : navigation sans perte de données entre étapes ; statut final "En révision".
- Priorité : Haute

**TC-PUB-02 — Titre trop court**
- Étapes : Saisir un titre de 3 caractères (< 5 minimum).
- Résultat attendu : validation bloque le passage à l'étape suivante.
- Priorité : Basse

**TC-PUB-03 — Upload fichier > 50 Mo**
- Étapes : Uploader un PDF de 60 Mo.
- Résultat attendu : rejet avec message clair sur la limite.
- Priorité : Moyenne

**TC-PUB-04 — Assistance WinAI : optimiser le titre**
- Étapes : Cliquer "Optimiser avec WinAI" sur le champ titre.
- Résultat attendu : suggestion avec justification, acceptable en un clic.
- Priorité : Moyenne

**TC-PUB-05 — Génération de quiz WinAI (10 questions)**
- Étapes : Cliquer "Suggérer 10 questions" à l'étape 3 (quiz).
- Résultat attendu : QCM calibrés pour l'examen ciblé, sélection individuelle avant import (pas d'import en masse imposé).
- Priorité : Moyenne

**TC-PUB-06 — Détection de plagiat avant soumission**
- Étapes : Uploader un contenu très similaire à un contenu déjà présent → arriver à l'étape 4.
- Résultat attendu : sections similaires surlignées avec % de similarité ; possibilité d'ignorer et soumettre quand même.
- Priorité : Haute

**TC-PUB-07 — Score d'impact pédagogique**
- Précondition : contenu publié avec données d'usage (complétion, notes).
- Étapes : Consulter "Mes contenus" → ouvrir le badge de score.
- Résultat attendu : code couleur correct (vert ≥70, orange 50-70, rouge <50) ; détail des 4 composantes affiché au clic.
- Priorité : Moyenne

**TC-PUB-08 — Alerte veille éditoriale WinAI**
- Étapes : Consulter le tableau de bord / chatbot pour une alerte de créneau non couvert.
- Résultat attendu : message précis (matière, niveau, examen, volume de recherches) ; bouton "Publier sur ce sujet" pré-remplit la publication.
- Priorité : Basse

**TC-PUB-09 — Modification / archivage / suppression de contenu**
- Étapes : Modifier un contenu publié (statut ≠ "En révision") ; archiver un contenu ; tenter de supprimer un contenu ayant des ventes.
- Résultat attendu : modification acceptée hors "En révision" ; archivage retire du catalogue public sans le supprimer ; suppression refusée s'il existe des ventes.
- Priorité : Moyenne

---

## MODULE 6 — CORRECTIONS

**TC-COR-01 — File priorisée avec badge "Urgent"**
- Précondition : une soumission en attente depuis plus de 48h.
- Étapes : Ouvrir la file de corrections.
- Résultat attendu : badge rouge "Urgent" affiché ; tri par ancienneté par défaut ; compteur exact sur l'onglet.
- Priorité : Haute

**TC-COR-02 — Pre-grading WinAI et validation**
- Étapes : Ouvrir une soumission → WinAI propose type d'erreur, commentaire, note.
- Résultat attendu : proposition affichée automatiquement ; accepter en un clic ou modifier librement la note/commentaire.
- Priorité : Haute

**TC-COR-03 — Détection de similarité (plagiat entre copies)**
- Précondition : deux soumissions très similaires pour le même exercice.
- Étapes : Ouvrir la file de corrections après soumission des deux copies.
- Résultat attendu : alerte au professeur uniquement (élèves non notifiés), score de similarité ≥70% affiché ; possibilité de marquer "Faux positif".
- Priorité : Haute

**TC-COR-04 — Enregistrement en brouillon**
- Étapes : Commencer une correction, cliquer "Enregistrer en brouillon", quitter, rouvrir.
- Résultat attendu : badge "Brouillon" dans la file ; note et commentaire restaurés à la réouverture.
- Priorité : Moyenne

**TC-COR-05 — Alerte brouillon non envoyé depuis 72h**
- Précondition : brouillon non finalisé depuis plus de 72h.
- Étapes : Consulter les alertes du professeur.
- Résultat attendu : alerte générée.
- Priorité : Basse

**TC-COR-06 — Génération de barème WinAI**
- Étapes : Coller un énoncé → générer le barème.
- Résultat attendu : barème structuré (points/sous-question, critères partiels, erreurs types), modifiable, visible en panneau latéral pendant la correction.
- Priorité : Moyenne

**TC-COR-07 — Notation automatique QCM**
- Étapes : Ouvrir une soumission QCM.
- Résultat attendu : note finale calculée automatiquement sans intervention.
- Priorité : Moyenne

**TC-COR-08 — Décision finale toujours au professeur**
- Étapes : Vérifier qu'aucune note n'est envoyée à l'élève sans validation manuelle explicite, même pour un développement long noté par WinAI.
- Résultat attendu : la note reste en attente de validation professeur avant envoi à l'élève.
- Priorité : Haute

---

## MODULE 7 — SESSIONS (LIVE / ENREGISTREMENT / CORRECTION / COURS PARTICULIER)

**TC-SES-01 — Création d'une session complète**
- Étapes : Créer une session live avec tous les champs obligatoires + optionnels (participants max, prix, lien externe).
- Résultat attendu : session visible dans le calendrier hebdomadaire avec le bon code couleur.
- Priorité : Haute

**TC-SES-02 — Session payante déclenche paiement**
- Étapes : Créer une session payante → un participant s'inscrit.
- Résultat attendu : flow de paiement déclenché avant confirmation d'inscription.
- Priorité : Moyenne

**TC-SES-03 — Calendrier hebdomadaire multi-types**
- Étapes : Créer une session de chaque type (Live, Enregistrement, Correction, Cours particulier).
- Résultat attendu : couleurs distinctes respectées (bleu/vert/orange/violet).
- Priorité : Moyenne

**TC-SES-04 — Annulation de session avec notification**
- Précondition : session payante avec inscrits.
- Étapes : Annuler la session, confirmer.
- Résultat attendu : notification push + email à tous les inscrits sous 5 min ; remboursement automatique déclenché ; statut "Annulée" conservé dans l'historique.
- Priorité : Haute

**TC-SES-05 — Transcription et résumé automatique de session live**
- Précondition : session live tenue via WinPlus.
- Étapes : Attendre la fin de la session.
- Résultat attendu : résumé généré (points abordés, questions, décisions, devoirs), éditable par le professeur avant envoi au canal.
- Priorité : Moyenne

---

## MODULE 8 — GESTION DES CLASSES

**TC-CLA-01 — Création de classe**
- Étapes : Créer une classe avec nom, niveau, année académique.
- Résultat attendu : classe visible immédiatement dans la liste.
- Priorité : Haute

**TC-CLA-02 — Ajout d'élève par email**
- Étapes : Ajouter un élève via un email correspondant à un compte WinPlus existant.
- Résultat attendu : élève ajouté, notification envoyée à l'élève.
- Priorité : Haute

**TC-CLA-03 — Ajout d'élève avec email inexistant**
- Étapes : Saisir un email ne correspondant à aucun compte.
- Résultat attendu : erreur de validation immédiate.
- Priorité : Moyenne

**TC-CLA-04 — Détection de doublon**
- Étapes : Ajouter un élève déjà présent dans la classe.
- Résultat attendu : ajout refusé, message explicite.
- Priorité : Basse

**TC-CLA-05 — Moyenne de classe et code couleur**
- Étapes : Consulter la vue classe avec plusieurs élèves ayant des scores variés.
- Résultat attendu : couleurs correctes (vert ≥70%, orange 50-70%, rouge <50%) ; icône de tendance par élève.
- Priorité : Moyenne

**TC-CLA-06 — Assignation de contenu à une classe entière**
- Étapes : Assigner un contenu depuis la page classe.
- Résultat attendu : coût déduit une seule fois du compte professeur ; tous les élèves voient "Assigné par [Nom]".
- Priorité : Haute

---

## MODULE 9 — FORMATIONS STRUCTURÉES

**TC-FOR-01 — Création de formation avec sections/leçons**
- Étapes : Créer sections et leçons (Vidéo, Article, Fichier) → réordonner par drag and drop.
- Résultat attendu : ordre respecté après réorganisation ; soumission bloquée tant qu'aucune leçon publiée n'existe.
- Priorité : Haute

**TC-FOR-02 — Leçon en aperçu public**
- Étapes : Marquer une leçon comme aperçu public.
- Résultat attendu : accessible sans inscription depuis la fiche formation.
- Priorité : Basse

**TC-FOR-03 — Drip content : déblocage immédiat**
- Étapes : Configurer une section "Immédiatement à l'inscription" → un élève s'inscrit.
- Résultat attendu : section accessible dès l'inscription.
- Priorité : Haute

**TC-FOR-04 — Drip content : délai en jours**
- Étapes : Configurer "Disponible 7 jours après l'inscription".
- Résultat attendu : section verrouillée avec cadenas et texte de condition jusqu'à J+7, déblocage automatique après.
- Priorité : Haute

**TC-FOR-05 — Drip content : score minimum**
- Étapes : Configurer "Si score quiz précédent ≥ 60%" → élève obtient 50% puis 65%.
- Résultat attendu : section verrouillée à 50%, débloquée automatiquement dès 65% atteint.
- Priorité : Haute

**TC-FOR-06 — Combinaison délai + score**
- Étapes : Configurer les deux règles sur la même section.
- Résultat attendu : les deux conditions sont appliquées correctement (ET logique attendu, à vérifier selon spec).
- Priorité : Moyenne

**TC-FOR-07 — Checkpoint vidéo (quiz au timestamp)**
- Étapes : Ajouter un checkpoint à 02:30 avec une question QCM → lire la vidéo côté élève jusqu'à ce timestamp.
- Résultat attendu : pause automatique, question affichée, reprise de la vidéo après réponse.
- Priorité : Haute

**TC-FOR-08 — Résultats des checkpoints dans les analytics**
- Étapes : Après plusieurs élèves ayant répondu aux checkpoints, consulter les analytics.
- Résultat attendu : résultats agrégés visibles.
- Priorité : Basse

**TC-FOR-09 — Activation gamification (points/badges)**
- Étapes : Activer la gamification, définir les points par leçon/quiz → élève complète une leçon.
- Résultat attendu : points attribués, badges débloqués selon les règles ("Premier quiz validé", etc.).
- Priorité : Moyenne

**TC-FOR-10 — Classement visible / masqué**
- Étapes : Activer puis désactiver le classement.
- Résultat attendu : les élèves voient/ne voient pas le classement des autres selon le paramètre.
- Priorité : Basse

**TC-FOR-11 — Génération automatique de certificat**
- Étapes : Un élève complète 100% des leçons d'une formation avec certificat activé.
- Résultat attendu : certificat généré automatiquement avec nom, formation, professeur, date, note, code unique.
- Priorité : Haute

**TC-FOR-12 — Vérification publique de certificat**
- Étapes : Sur la page de vérification, saisir le code du certificat généré.
- Résultat attendu : détails corrects affichés ; code invalide → message d'erreur clair.
- Priorité : Moyenne

**TC-FOR-13 — Téléchargement du certificat en PDF**
- Étapes : Depuis l'espace élève, télécharger le certificat.
- Résultat attendu : PDF valide généré et téléchargeable.
- Priorité : Basse

**TC-FOR-14 — Analytics : taux de complétion et alerte**
- Précondition : une leçon a un taux de complétion < 40%.
- Étapes : Consulter les analytics de la formation.
- Résultat attendu : graphique par leçon affiché ; alerte WinAI déclenchée pour la leçon sous le seuil.
- Priorité : Moyenne

**TC-FOR-15 — Vue "Élèves à risque"**
- Étapes : Consulter la vue "Élèves à risque" sur une formation ayant des inactifs.
- Résultat attendu : liste correcte avec signaux (inactivité, baisse de score).
- Priorité : Moyenne

**TC-FOR-16 — Alerte inactivité et relance groupée**
- Précondition : élèves inactifs depuis 7+ jours configurés.
- Étapes : Recevoir la notification → cliquer "Relancer ces élèves".
- Résultat attendu : message pré-rédigé WinAI envoyé en groupé ; taux de réactivation mesuré ensuite dans les analytics.
- Priorité : Moyenne

**TC-FOR-17 — Génération de syllabus WinAI**
- Étapes : Saisir matière/niveau/durée/objectifs/examens → générer.
- Résultat attendu : plan semaine par semaine généré, importable comme structure de sections/leçons, modifiable avant import.
- Priorité : Moyenne

---

## MODULE 10 — INTELLIGENCE DE CLASSE ET ANALYTICS

**TC-ANA-01 — Analyse WinAI sur un contenu**
- Étapes : Sélectionner un contenu publié → lancer l'analyse.
- Résultat attendu : score moyen, distribution de maîtrise en 4 niveaux, questions les plus échouées, actions recommandées affichés.
- Priorité : Moyenne

**TC-ANA-02 — Benchmarking classe vs plateforme**
- Étapes : Lancer le benchmarking WinAI sur une classe.
- Résultat attendu : écart en % affiché, lacunes spécifiques distinguées des tendances générales, contenus recommandés.
- Priorité : Moyenne

**TC-ANA-03 — Benchmarking élève concours (répétiteur)**
- Précondition : élève lié avec concours cible déclaré (ex. ENSP).
- Étapes : Ouvrir le benchmarking depuis la fiche élève.
- Résultat attendu : position estimée, matières à écart fort, ressources recommandées.
- Priorité : Basse

---

## MODULE 11 — WINAI GLOBAL

**TC-AI-01 — Accès WinAI depuis bouton flottant**
- Étapes : Cliquer le bouton flottant sur différentes pages.
- Résultat attendu : panneau latéral (web) / modal bottom sheet (mobile) ; 4 suggestions contextuelles selon la page active ; historique consultable.
- Priorité : Haute

**TC-AI-02 — Mémoire conversationnelle persistante**
- Précondition : conversation WinAI précédente non finalisée.
- Étapes : Revenir sur WinAI après quelques jours.
- Résultat attendu : proposition explicite de reprendre là où c'était arrêté.
- Priorité : Moyenne

**TC-AI-03 — Suppression d'un élément de mémoire**
- Étapes : Ouvrir "Mémoire WinAI" → supprimer un élément.
- Résultat attendu : élément retiré, non réutilisé dans les échanges suivants.
- Priorité : Basse

**TC-AI-04 — Mémoire séparée par rôle**
- Précondition : compte avec mode Professeur et mode Répétiteur actifs.
- Étapes : Consulter la mémoire dans chaque mode.
- Résultat attendu : les éléments mémorisés sont distincts entre les deux modes.
- Priorité : Basse

**TC-AI-05 — Résumé automatique de leçon**
- Étapes : Un élève complète une leçon.
- Résultat attendu : résumé (5-7 points, définitions/formules, 2-3 questions) visible côté élève ; désactivable par le professeur.
- Priorité : Moyenne

**TC-AI-06 — Adaptive difficulty (élève fort / faible)**
- Étapes : Simuler un élève à 90% de réussite puis un élève à 40%.
- Résultat attendu : questions plus difficiles pour le premier, plus accessibles avec indices pour le second ; aucun blocage de progression.
- Priorité : Moyenne

**TC-AI-07 — Détection de décrochage et alerte**
- Étapes : Simuler un pattern d'inactivité/baisse de score correspondant au profil de décrochage.
- Résultat attendu : alerte "À risque" générée avec nom élève et signaux ; bouton "Contacter cet élève" ouvre la messagerie avec message pré-rédigé.
- Priorité : Haute

**TC-AI-08 — Vérification d'originalité (plagiat contenu)**
- Étapes : Soumettre un contenu à l'étape 4 avec du texte copié d'un contenu existant.
- Résultat attendu : sections surlignées avec % de similarité ; soumission possible malgré l'alerte (décision humaine) ; contenu original reçoit le badge "Originalité confirmée".
- Priorité : Haute

---

## MODULE 12 — REVENUS ET RETRAITS

**TC-REV-01 — Graphique revenus filtrable par période**
- Étapes : Basculer entre 7 jours / 30 jours / 3 mois / 12 mois.
- Résultat attendu : graphique mis à jour avec les deux séries (catalogue, cours particuliers) ; tooltip correct au survol.
- Priorité : Moyenne

**TC-REV-02 — Retrait Mobile Money réussi**
- Précondition : solde disponible supérieur au minimum de retrait.
- Étapes : Choisir opérateur (auto-détecté par préfixe), saisir montant, confirmer.
- Résultat attendu : suivi de statut toutes les 3s, écran de succès, solde mis à jour instantanément.
- Priorité : Haute

**TC-REV-03 — Retrait bloqué si solde nul/insuffisant**
- Étapes : Tenter un retrait avec solde à 0 ou sous le minimum.
- Résultat attendu : bouton de retrait désactivé.
- Priorité : Haute

**TC-REV-04 — Retrait avec montant hors bornes**
- Étapes : Saisir un montant supérieur au solde disponible.
- Résultat attendu : validation refuse le montant.
- Priorité : Moyenne

**TC-REV-05 — Détail des transactions (source distincte)**
- Étapes : Consulter le tableau détaillé des transactions.
- Résultat attendu : source clairement distinguée (Catalogue / Cours particulier / Achat) avec montant brut, commission, net.
- Priorité : Haute

**TC-REV-06 — Paiement catalogue via solde WinPlus**
- Voir TC-CAT-10 / TC-CAT-11 (couvert dans Module 4).

---

## MODULE 13 — FORUM ET COMMUNAUTÉ

**TC-COM-01 — Label "Professeur Vérifié" sur le forum**
- Précondition : professeur avec badge Vérifié Diplôme.
- Étapes : Publier un post ou une réponse sur le forum.
- Résultat attendu : label affiché automatiquement sur tous les posts/réponses.
- Priorité : Basse

**TC-COM-02 — Mise en avant "Meilleure réponse"**
- Étapes : L'auteur d'un fil marque la réponse du professeur comme "Meilleure réponse".
- Résultat attendu : le fil est automatiquement mis en avant.
- Priorité : Basse

**TC-COM-03 — Notification de réponse sur un fil suivi**
- Étapes : Suivre un fil → quelqu'un y répond.
- Résultat attendu : notification reçue par le professeur.
- Priorité : Basse

---

## TRANSVERSAL — NON-RÉGRESSION

**TC-NR-01 — Coexistence Mode Catalogue / Mode Répétiteur**
- Étapes : Activer le mode Répétiteur sur un compte ayant déjà des publications catalogue.
- Résultat attendu : les deux modes actifs simultanément ; revenus agrégés dans un seul tableau de bord ; aucune régression sur les fonctionnalités catalogue existantes.
- Priorité : Haute

**TC-NR-02 — Onglet Sessions non cassé par l'ajout "Cours particuliers"**
- Étapes : Naviguer entre les tabs "Formations/Lives" et "Cours particuliers".
- Résultat attendu : contenu et fonctionnalités de l'onglet existant "Formations/Lives" inchangés.
- Priorité : Haute

**TC-NR-03 — Sidebar / navigation web non cassée**
- Étapes : Vérifier toutes les entrées de la sidebar après ajout de "Cours particuliers", "Ma bibliothèque", badge messagerie.
- Résultat attendu : aucune route en 404, navigation existante intacte.
- Priorité : Haute

**TC-NR-04 — Graphique revenus existant non cassé**
- Étapes : Consulter le graphique après ajout de la série "Cours particuliers".
- Résultat attendu : la série "Catalogue" préexistante reste correcte et lisible.
- Priorité : Moyenne

**TC-NR-05 — Cohérence UI/UX**
- Étapes : Comparer les nouveaux écrans (onboarding répétiteur, disponibilités, réservation, messagerie) avec les composants/tokens de design existants.
- Résultat attendu : conventions de nommage, composants et patterns UX respectés (skill ui-ux-pro-max).
- Priorité : Moyenne

---

*Total : environ 140 cas de test couvrant les 13 modules fonctionnels + non-régression. Chaque cas peut être exécuté indépendamment ; les préconditions doivent être vérifiées avant exécution (comptes de test Professeur, Répétiteur, Élève, Admin).*
