// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aiAskHint => 'Écris ta question…';

  @override
  String get authAccountActive => 'Votre compte WinPlus est maintenant actif.';

  @override
  String get authAlreadyAccount => 'Déjà un compte ? ';

  @override
  String get authBackToLogin => 'Retour à la connexion';

  @override
  String authBornOn(Object date) {
    return 'Né(e) le $date';
  }

  @override
  String get authChooseProfile =>
      'Choisis ton profil pour une expérience personnalisée.';

  @override
  String get authChooseSecure => 'Choisissez un mot de passe sécurisé.';

  @override
  String get authCodeIncorrect => 'Code incorrect. Vérifiez votre email.';

  @override
  String get authCodeInvalid => 'Code invalide.';

  @override
  String get authCodeSentAddress =>
      'Un code à 6 chiffres a été envoyé à votre adresse.';

  @override
  String get authCodeSentEmail => 'Code envoyé à votre email';

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authCreateMyAccount => 'Créer mon compte';

  @override
  String get authDobOptional => 'Date de naissance (optionnel)';

  @override
  String get authEmailAddress => 'Adresse email';

  @override
  String get authEmailHint => 'votre@email.com';

  @override
  String get authEmailVerified => 'Email vérifié !';

  @override
  String get authErrNetwork => 'Erreur réseau.';

  @override
  String get authFeatInst1 => 'Dashboard centralisé';

  @override
  String get authFeatInst2 => 'Licences multi-élèves';

  @override
  String get authFeatInst3 => 'Indicateurs de vos élèves';

  @override
  String get authFeatParent1 => 'Suivez la progression de vos enfants';

  @override
  String get authFeatParent3 => 'Achetez des contenus pour eux';

  @override
  String get authFeatStudent1 =>
      'Annales et corrigés à lire dans l’application';

  @override
  String get authFeatStudent2 => 'Quiz IA personnalisés';

  @override
  String get authFeatStudent3 => 'Certificats de vos formations terminées';

  @override
  String get authFeatTeacher1 => 'Publiez et monétisez vos contenus';

  @override
  String get authFeatTeacher2 => 'Gérez vos classes';

  @override
  String get authFeatTeacher3 => 'Revenus sur vos ventes et vos séances';

  @override
  String get authFillRequired =>
      'Veuillez remplir tous les champs obligatoires.';

  @override
  String get authFinish => 'Terminer';

  @override
  String get authFirstName => 'Prénom';

  @override
  String get authFollowCloseHint =>
      'Alertes dès qu’un événement important survient.';

  @override
  String get authFollowCloseLabel => 'Suivi rapproché';

  @override
  String get authFollowMinimalHint =>
      'Je consulterai moi-même l’espace parent.';

  @override
  String get authFollowMinimalLabel => 'Le minimum';

  @override
  String get authFollowWeeklyHint =>
      'Un résumé de la semaine, sans alerte au fil de l’eau.';

  @override
  String get authFollowWeeklyLabel => 'Rapport hebdomadaire';

  @override
  String get authForgotIntro =>
      'Entrez votre adresse email, nous vous enverrons un lien de réinitialisation.';

  @override
  String get authForgotNotReceived => 'Vous n\'avez pas reçu l\'email ?';

  @override
  String authForgotSent(Object email) {
    return 'Email envoyé à $email. Vérifiez aussi vos spams.';
  }

  @override
  String get authForgotTitle => 'Mot de passe oublié';

  @override
  String get authGoToLogin => 'Aller à la connexion';

  @override
  String get authGoogleSoon => 'Google OAuth bientôt disponible !';

  @override
  String get authIAm => 'Je suis…';

  @override
  String get authLastName => 'Nom';

  @override
  String get authLogMeOut => 'Me déconnecter';

  @override
  String get authLvlEns => 'ENS École Normale';

  @override
  String get authLvlEssec => 'ESSEC Commerce';

  @override
  String get authLvlFmsb => 'FMSB Médecine';

  @override
  String get authLvlPrepa => 'Prépa';

  @override
  String get authNewPassword => 'Nouveau mot de passe';

  @override
  String get authNext => 'Suivant';

  @override
  String get authOptConcours => 'Concours';

  @override
  String get authOptEconomics => 'Économique';

  @override
  String get authOptLiterary => 'Littéraire';

  @override
  String get authOptOther => 'Autre';

  @override
  String get authOptPolytechnique => 'Polytechnique';

  @override
  String get authOptScience => 'Scientifique';

  @override
  String get authOptTechnical => 'Technique';

  @override
  String get authParentFollowHint =>
      'Vous pourrez changer cette préférence à tout moment.';

  @override
  String get authParentFollowTitle =>
      'Comment souhaitez-vous suivre sa scolarité ?';

  @override
  String get authParentGoalHint =>
      'En quelques mots : réussir un examen, combler une lacune, reprendre confiance…';

  @override
  String get authParentGoalPlaceholder =>
      'Ex. Aider mon fils à progresser en maths avant le brevet';

  @override
  String get authParentGoalTitle =>
      'Quel est votre objectif pour votre enfant ?';

  @override
  String get authPeriodicIntro =>
      'Pour votre sécurité, confirmez votre identité (toutes les 20 jours)';

  @override
  String get authPhoneOptional => 'Téléphone (optionnel)';

  @override
  String get authPhoneSoon => 'Connexion par téléphone bientôt disponible !';

  @override
  String get authPwdCriteria => 'Le mot de passe ne respecte pas les critères.';

  @override
  String get authPwdUpdated =>
      'Mot de passe mis à jour ! Vous pouvez maintenant vous connecter.';

  @override
  String get authResendCode => 'Renvoyer le code';

  @override
  String authResendCodeParen(Object seconds) {
    return 'Renvoyer le code (${seconds}s)';
  }

  @override
  String get authResendEmail => 'Renvoyer l\'email';

  @override
  String authResendIn(Object seconds) {
    return 'Renvoyer le code dans ${seconds}s';
  }

  @override
  String get authReset => 'Réinitialiser';

  @override
  String get authRoleInstitutionDesc =>
      'Lycée, université ou centre de formation';

  @override
  String get authRoleInstitutionLabel => 'Institution';

  @override
  String get authRoleParentDesc => 'Suivi et accompagnement de mes enfants';

  @override
  String get authRoleParentLabel => 'Parent / Tuteur';

  @override
  String get authRoleStudentDesc => 'Du BEPC aux concours des grandes écoles';

  @override
  String get authRoleStudentLabel => 'Étudiant / Apprenant';

  @override
  String get authRoleTeacherDesc =>
      'Publication de contenus et suivi des apprenants';

  @override
  String get authRoleTeacherLabel => 'Professeur / Formateur';

  @override
  String get authRule8 => 'Au moins 8 caractères';

  @override
  String get authRuleDigit => 'Au moins un chiffre';

  @override
  String get authRuleMatch => 'Les mots de passe correspondent';

  @override
  String get authRuleUpper => 'Au moins une majuscule';

  @override
  String get authSendCode => 'Envoyer le code';

  @override
  String get authSendLink => 'Envoyer le lien';

  @override
  String get authSignupFailed => 'Inscription impossible.';

  @override
  String get authSignupIntro => 'Quelques informations pour commencer.';

  @override
  String get authSkip => 'Passer';

  @override
  String get authSkipStep => 'Passer cette étape';

  @override
  String get authStart => 'Commencer';

  @override
  String get authStepFollowUp => 'Suivi';

  @override
  String get authStepGoal => 'Objectif';

  @override
  String get authStepLevels => 'Niveaux';

  @override
  String get authStepStream => 'Filière';

  @override
  String get authStepSubjects => 'Matières';

  @override
  String get authStudentGoalHint => 'L\'exam pour lequel tu veux te préparer.';

  @override
  String get authStudentGoalTitle => 'Quel est ton objectif ?';

  @override
  String get authStudentLevelHint =>
      'WinAI adapte le contenu à ton niveau scolaire.';

  @override
  String get authStudentLevelTitle => 'Quel est ton niveau ?';

  @override
  String get authStudentStreamHint =>
      'Pour mieux cibler les ressources disponibles.';

  @override
  String get authStudentStreamTitle => 'Quelle est ta filière ?';

  @override
  String get authSuccessInstitution =>
      'Gérez votre établissement depuis votre tableau de bord.';

  @override
  String get authSuccessParent => 'Vous pouvez maintenant suivre vos enfants.';

  @override
  String get authSuccessStudent =>
      'Votre profil est prêt. Commencez à réviser !';

  @override
  String get authSuccessTeacher => 'Publiez votre premier contenu !';

  @override
  String get authTeacherLevelsHint =>
      'Utile pour situer tes contenus et, plus tard, ton profil Mode Tuteur.';

  @override
  String get authTeacherLevelsTitle => 'Quels niveaux couvres-tu ?';

  @override
  String get authTeacherSubjectsHint =>
      'On adapte ton espace professeur et les suggestions WinAI à tes matières.';

  @override
  String get authTeacherSubjectsTitle => 'Quelles matières enseignes-tu ?';

  @override
  String get authVerify => 'Vérifier';

  @override
  String get authVerifyEmailTitle => 'Vérification email';

  @override
  String get authVerifyItsYou => 'Vérifiez que c\'est bien vous';

  @override
  String authWelcomeName(Object name) {
    return 'Bienvenue sur WinPlus, $name !';
  }

  @override
  String get authWelcomeSlide1Subtitle =>
      'Annales, corrigés et quiz du BEPC aux concours des grandes écoles.';

  @override
  String get authWelcomeSlide1Title => 'Toutes tes épreuves, réunies';

  @override
  String get authWelcomeSlide2Subtitle =>
      'Un assistant pédagogique qui identifie tes lacunes et te propose un plan de révision.';

  @override
  String get authWelcomeSlide2Title => 'WinAI à tes côtés';

  @override
  String get authWelcomeSlide3Subtitle =>
      'Parents, professeurs, élèves : chacun suit la progression de l’élève.';

  @override
  String get authWelcomeSlide3Title => 'Toute la famille impliquée';

  @override
  String get authXpUnlocked => '+50 XP débloqués';

  @override
  String get authYouDefault => 'toi';

  @override
  String get commonAccept => 'Accepter';

  @override
  String get commonActive => 'Actif';

  @override
  String get commonAll => 'Tout';

  @override
  String get studentSearchLangFr => 'Français';

  @override
  String get studentSearchLangEn => 'Anglais (GCE)';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonDarkMode => 'Mode sombre';

  @override
  String get commonDecline => 'Refuser';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonDraft => 'Brouillon';

  @override
  String get commonDuration => 'Durée';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonFree => 'Gratuit';

  @override
  String get commonLevel => 'Niveau';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonLogout => 'Se déconnecter';

  @override
  String get commonNetworkError => 'Erreur réseau';

  @override
  String get commonOnline => 'En ligne';

  @override
  String get commonPending => 'En attente';

  @override
  String get commonPublished => 'Publié';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSeeAll => 'Voir tout';

  @override
  String get commonSend => 'Envoyer';

  @override
  String get commonSubject => 'Matière';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonWinaiAlerts => 'Alertes WinAI';

  @override
  String get commonWinaiMemory => 'Mémoire WinAI';

  @override
  String get commonWinaiThinking => 'WinAI réfléchit…';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithPhone => 'Continuer avec le téléphone';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get dataSubjectChemistry => 'Chimie';

  @override
  String get dataSubjectComputing => 'Informatique';

  @override
  String get dataSubjectComputingShort => 'Info';

  @override
  String get dataSubjectEnglish => 'Anglais';

  @override
  String get dataSubjectFrench => 'Français';

  @override
  String get dataSubjectHistGeo => 'Histoire-Géo';

  @override
  String get dataSubjectHistGeoShort => 'Hist-Géo';

  @override
  String get dataSubjectMath => 'Mathématiques';

  @override
  String get dataSubjectMathShort => 'Maths';

  @override
  String get dataSubjectPhilosophy => 'Philosophie';

  @override
  String get dataSubjectPhilosophyShort => 'Philo';

  @override
  String get dataSubjectPhysics => 'Physique';

  @override
  String get dataTypeBook => 'Livre';

  @override
  String get dataTypeCorrection => 'Correction';

  @override
  String get dataTypePaper => 'Épreuve';

  @override
  String get email => 'Email';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String fmtDateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forumAll => 'Tous';

  @override
  String get forumAnonymous => 'Anonyme';

  @override
  String get forumCatDiscussions => 'Discussions';

  @override
  String get forumCatHelp => 'Aide';

  @override
  String get forumCatQuestions => 'Questions';

  @override
  String get forumCatResources => 'Ressources';

  @override
  String get forumCategory => 'Catégorie';

  @override
  String get forumContentField => 'Contenu *';

  @override
  String get forumContentHint => 'Détaillez votre question…';

  @override
  String get forumEmptyCategory => 'Aucun thread dans cette catégorie.';

  @override
  String forumError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get forumNewThread => 'Nouveau thread';

  @override
  String get forumPublish => 'Publier';

  @override
  String get forumReplyHint => 'Votre réponse…';

  @override
  String get forumRoleTeacher => 'Prof';

  @override
  String get forumSolved => 'Résolu';

  @override
  String get forumThread => 'Thread';

  @override
  String get forumTitle => 'Forum';

  @override
  String get forumTitleField => 'Titre *';

  @override
  String get forumTitleHint => 'Votre question ou sujet…';

  @override
  String get instAccountAdmins => 'Administrateurs';

  @override
  String get instAccountBilling => 'Facturation & reçus';

  @override
  String get instAccountGroups => 'Groupes & classes';

  @override
  String get instAccountLicense => 'Licence WinPlus : sièges et renouvellement';

  @override
  String get instAccountReports => 'Rapports exportables';

  @override
  String get instAccountSchool => 'Compte établissement';

  @override
  String get instAccountTutoring => 'Tutorat & portefeuille';

  @override
  String get instAiHint => 'Analyse, benchmark, plan d\'action…';

  @override
  String get instAiSuggestion1 => 'Analyse de cohorte';

  @override
  String get instAiSuggestion3 => 'Plan d\'action prioritaire';

  @override
  String get instAiSuggestion4 => 'Benchmark national';

  @override
  String get instAiTagline =>
      'Ton auditeur analytique & stratège institutionnel';

  @override
  String get instAnalyticsByGroup => 'Performance par groupe';

  @override
  String get instAnalyticsDownloadsMonth => 'Téléch./mois';

  @override
  String get instAnalyticsQuizMonth => 'Quiz/mois';

  @override
  String get instCatalogAssign => 'Assigner';

  @override
  String get instCatalogLicenseInfo =>
      'Licence établissement : contenus assignables à tous vos groupes.';

  @override
  String instDashActiveStudents(Object pct) {
    return 'Élèves actifs$pct';
  }

  @override
  String get instDashActiveStudentsLower => 'élèves actifs';

  @override
  String get instDashAiPlan => 'Plan d\'action IA';

  @override
  String get instDashAlertsInfo =>
      'Analysez les performances de vos groupes et identifiez les élèves à risque.';

  @override
  String get instDashDirectory => 'Annuaire';

  @override
  String get instDashNoLicense => 'Sans licence active';

  @override
  String get instDashQuickActions => 'Actions rapides';

  @override
  String get instDashQuizMonth => 'Quiz ce mois';

  @override
  String instDashStudentsCount(Object n) {
    return '$n élèves';
  }

  @override
  String instDashUrgent(Object n) {
    return '$n élèves nécessitent une attention urgente';
  }

  @override
  String get instDirActive => 'Actifs';

  @override
  String get instDirAddError => 'Impossible d\'ajouter cet élève';

  @override
  String get instDirAddSuccess => 'Élève ajouté avec succès';

  @override
  String get instDirAvg => 'Moy.';

  @override
  String instDirCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'élèves',
      one: 'élève',
    );
    return '$count $_temp0';
  }

  @override
  String get instDirEmailRequired => 'Email requis';

  @override
  String get instDirGroup => 'Groupe';

  @override
  String get instDirNoInstitution => 'Aucune institution associée.';

  @override
  String get instDirNoStudent => 'Aucun élève trouvé.';

  @override
  String get instDirSearchHint => 'Rechercher par nom ou email…';

  @override
  String get instDirStudents => 'Élèves';

  @override
  String get instDirTitle => 'Annuaire des élèves';

  @override
  String get instEndorseAction => 'Cautionner';

  @override
  String get instEndorseBadge => 'Cautionné';

  @override
  String get instEndorseChangeDate => 'Changer la date';

  @override
  String get instEndorseConfirm => 'Confirmer la caution';

  @override
  String get instEndorseEmpty =>
      'Aucun répétiteur rattaché à votre établissement pour le moment.';

  @override
  String get instEndorseHowHint =>
      'Entretien, pièce d\'identité vue en mains propres, contrat…';

  @override
  String get instEndorseHowLabel => 'Comment l\'avez-vous vérifié ?';

  @override
  String get instEndorseIntro =>
      'Si votre établissement a vérifié un répétiteur par ses propres moyens, cautionnez-le : il pourra proposer des séances présentielles. Vous pouvez retirer la caution à tout moment ; retirer le rattachement la retire aussi.';

  @override
  String get instEndorseNotEndorsed => 'Non cautionné';

  @override
  String instEndorseOnDate(Object date) {
    return 'Le $date';
  }

  @override
  String get instEndorseOtherRoute =>
      'Déjà vérifié pour le présentiel par une autre voie';

  @override
  String get instEndorseReasonLabel => 'Motif (transmis au répétiteur)';

  @override
  String get instEndorseRevoke => 'Retirer la caution';

  @override
  String get instEndorseRevokeAction => 'Retirer';

  @override
  String get instEndorseRevokeText =>
      'S\'il n\'est pas vérifié par une autre voie, il ne pourra plus proposer de séances présentielles.';

  @override
  String get instEndorseRevokeTitle => 'Retirer la caution ?';

  @override
  String get instEndorseRevoked => 'Caution retirée.';

  @override
  String get instEndorseSaved => 'Caution enregistrée.';

  @override
  String get instEndorseScreenTitle => 'Cautions des répétiteurs';

  @override
  String get instEndorseSheetInfo =>
      'Il pourra proposer des séances présentielles, avec le badge « Caution : votre établissement ».';

  @override
  String get instEndorseThisTutor => 'ce répétiteur';

  @override
  String instEndorseTitle(Object name) {
    return 'Cautionner $name';
  }

  @override
  String instEndorseVerifiedBy(Object name) {
    return 'Vérifié par $name';
  }

  @override
  String get instEndorseVerifierLabel => 'Vérifié par (nom et fonction)';

  @override
  String get instGroupAddStudents => 'Ajouter des élèves';

  @override
  String get instGroupAssignInfo =>
      'Sélectionnez des contenus depuis le catalogue pour les affecter à ce groupe.';

  @override
  String get instGroupAssignResources => 'Attribuer ressources';

  @override
  String instGroupAssignTo(Object name) {
    return 'Attribuer à $name';
  }

  @override
  String get instGroupBrowseCatalog => 'Parcourir le catalogue';

  @override
  String get instGroupCreateError => 'Erreur lors de la création du groupe.';

  @override
  String get instGroupCreateSubmit => 'Créer le groupe';

  @override
  String get instGroupCreated => 'Groupe créé !';

  @override
  String instGroupCreatedSummary(Object name, Object count) {
    return '$name  $count élève(s) ajouté(s).';
  }

  @override
  String get instGroupLevelLabel => 'Niveau *';

  @override
  String get instGroupLevelLicence => 'Licence';

  @override
  String get instGroupNameLabel => 'Nom du groupe *';

  @override
  String get instGroupNoMembers => 'Aucun élève dans ce groupe.';

  @override
  String get instGroupSearch => 'Rechercher un groupe…';

  @override
  String get instGroupSearchStudent => 'Rechercher un élève…';

  @override
  String get instGroupSeeStudents => 'Voir élèves';

  @override
  String instGroupSelected(Object count) {
    return '$count sélectionné(s)';
  }

  @override
  String instLicenseAccount(Object id) {
    return 'Compte $id';
  }

  @override
  String instLicenseAiBudget(Object value) {
    return 'Budget WinAI de l\'établissement utilisé : $value %';
  }

  @override
  String get instLicenseAutoRenew =>
      'Renouvellement automatique par le portefeuille';

  @override
  String instLicenseGridMin(Object min, Object perTeacher) {
    return 'Minimum $min sièges, un siège enseignant pour $perTeacher élèves.';
  }

  @override
  String instLicenseGridPrices(Object tiers) {
    return 'Prix TTC par élève et par an : $tiers.';
  }

  @override
  String instLicenseGridTier(Object price, Object seats) {
    return '$price XAF dès $seats sièges';
  }

  @override
  String instLicenseHeading(Object status) {
    return 'Licence $status';
  }

  @override
  String get instLicenseNegotiated => 'Négociée';

  @override
  String instLicensePastDue(Object date) {
    return 'Solde insuffisant au renouvellement : rechargez le portefeuille avant le $date.';
  }

  @override
  String get instLicensePaymentFrom =>
      'Paiement depuis le portefeuille de l\'établissement.';

  @override
  String instLicensePeriod(Object start, Object end) {
    return 'Du $start au $end';
  }

  @override
  String get instLicensePromo => 'Code promo';

  @override
  String get instLicensePurchase => 'Souscrire avec le portefeuille';

  @override
  String get instLicensePurchaseError => 'Souscription impossible.';

  @override
  String instLicenseQuoteLine(Object price, Object teacherSeats, Object date) {
    return '$price XAF par élève · $teacherSeats sièges enseignants · jusqu\'au $date';
  }

  @override
  String instLicenseQuoteTotal(Object amount) {
    return 'Total : $amount XAF TTC';
  }

  @override
  String get instLicenseRelease => 'Libérer';

  @override
  String get instLicenseReleaseError => 'Libération impossible.';

  @override
  String get instLicenseRenewWallet => 'Renouveler avec le portefeuille';

  @override
  String get instLicenseSeatBenefits =>
      'Chaque siège ouvre à l\'élève le catalogue, le plan d\'étude, la session guidée, Exam Coach et un bonus WinAI ; un siège enseignant ouvre les outils du plan Pro et une part de 75 % sur le tutorat.';

  @override
  String get instLicenseSeatsInfo =>
      'Un siège élève est attribué quand l\'élève accepte son rattachement ; un siège enseignant quand le professeur accepte l\'affiliation.';

  @override
  String get instLicenseSeatsTitle => 'Sièges attribués';

  @override
  String get instLicenseStatusEnded => 'Terminée';

  @override
  String get instLicenseStudentSeats => 'Sièges élèves';

  @override
  String instLicenseStudentSeatsUsed(Object used, Object total) {
    return 'Sièges élèves : $used / $total';
  }

  @override
  String get instLicenseSubscribeTitle => 'Souscrire une licence';

  @override
  String instLicenseTeacherSeatsUsed(Object used, Object total) {
    return 'Sièges enseignants : $used / $total';
  }

  @override
  String get instLicenseTermQuarter => 'Trimestre';

  @override
  String get instLicenseTermYear => 'Année scolaire';

  @override
  String get instLicenseTitle => 'Licence WinPlus';

  @override
  String instLicenseTrial(Object days, Object seats) {
    return 'Essai gratuit ($days jours, $seats sièges)';
  }

  @override
  String get instLicenseTrialError => 'Essai indisponible.';

  @override
  String get instLicenseUnavailable => 'Licence indisponible.';

  @override
  String get instLicenseUpdateError => 'Modification impossible.';

  @override
  String get instLicenseWait => 'Patientez…';

  @override
  String get instMySchool => 'Mon établissement';

  @override
  String get instPlanActionsDone => 'actions réalisées';

  @override
  String get instPlanDone => 'Réalisé';

  @override
  String get instPlanEmpty =>
      'WinAI n\'a proposé aucune action pour cette semaine.';

  @override
  String get instPlanForbidden =>
      'Votre compte n\'a pas accès au plan d\'action de l\'établissement.';

  @override
  String instPlanImpact(Object impact) {
    return 'Impact attendu : $impact';
  }

  @override
  String get instPlanMarkDone => 'Marquer comme fait';

  @override
  String instPlanPriority(Object n) {
    return 'Priorité $n';
  }

  @override
  String instPlanSummaryActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'actions prioritaires',
      one: 'action prioritaire',
      zero: 'action prioritaire',
    );
    return ', et recommande $count $_temp0.';
  }

  @override
  String instPlanSummaryAtRisk(Object n) {
    return ', dont $n en zone critique';
  }

  @override
  String instPlanSummaryStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'élèves',
      one: 'élève',
      zero: 'élève',
    );
    return 'WinAI a analysé $count $_temp0';
  }

  @override
  String get instPlanTitle => 'Plan d\'action WinAI';

  @override
  String get instPlanUnavailable =>
      'Le plan d\'action WinAI est indisponible pour le moment.';

  @override
  String get instReportAtRiskSub => 'Élèves nécessitant une intervention';

  @override
  String get instReportAtRiskTitle => 'Rapport élèves à risque';

  @override
  String get instReportGeneratePdf => 'Générer PDF';

  @override
  String get instReportGenerated => 'Rapport généré !';

  @override
  String get instReportGenerating => 'Génération en cours...';

  @override
  String get instReportGlobalSub => 'Vue d\'ensemble de tous les élèves';

  @override
  String get instReportGlobalTitle => 'Rapport de performance global';

  @override
  String get instReportGroupSub => 'Comparaison des classes, taux de réussite';

  @override
  String get instReportGroupTitle => 'Rapport par classe';

  @override
  String get instReportIndividualSub => 'Progression détaillée d\'un élève';

  @override
  String get instReportIndividualTitle => 'Rapport individuel élève';

  @override
  String instReportReady(Object title) {
    return 'Votre rapport \"$title\" est prêt.';
  }

  @override
  String get instReportWait => 'Patientez...';

  @override
  String get instReportsTitle => 'Rapports';

  @override
  String get instRiskActionPlan => 'Plan d\'action';

  @override
  String get instRiskContact => 'Contacter';

  @override
  String get instRiskCritical => 'Critique';

  @override
  String instRiskCriticalCount(Object n) {
    return '$n critiques';
  }

  @override
  String get instRiskEmpty => 'Aucun élève dans cette catégorie.';

  @override
  String instRiskInactiveFor(Object n) {
    return 'Inactif depuis ${n}j';
  }

  @override
  String get instRiskModerate => 'Modéré';

  @override
  String instRiskScore(Object n) {
    return 'Score : $n%';
  }

  @override
  String get instRiskTitle => 'Élèves à risque';

  @override
  String get instRiskWeakSubject => 'Matière faible ';

  @override
  String instStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'élèves',
      one: 'élève',
      zero: 'élève',
    );
    return '$count $_temp0';
  }

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageHint =>
      'La langue de l\'application, des e-mails et des notifications.';

  @override
  String get legalCgu1Body =>
      'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'accès et l\'utilisation de la plateforme WinPlus, application mobile éducative destinée aux élèves, parents et enseignants du système scolaire camerounais.';

  @override
  String get legalCgu1Title => '1. Objet';

  @override
  String get legalCgu2Body =>
      'L\'accès à WinPlus est ouvert à toute personne disposant d\'un appareil compatible et d\'une connexion internet. Certaines fonctionnalités nécessitent la création d\'un compte. L\'inscription est gratuite pour le plan de base.';

  @override
  String get legalCgu2Title => '2. Accès à la plateforme';

  @override
  String get legalCgu3Body =>
      'Vous êtes responsable de la confidentialité de vos identifiants. Toute activité effectuée depuis votre compte vous est attribuée. En cas de compromission, contactez-nous immédiatement à support@winplus.cm.';

  @override
  String get legalCgu3Title => '3. Comptes utilisateurs';

  @override
  String get legalCgu4Body =>
      'Les contenus publiés sur WinPlus (épreuves, corrections, quiz) sont protégés par le droit d\'auteur. Leur reproduction, redistribution ou revente sans autorisation est strictement interdite.';

  @override
  String get legalCgu4Title => '4. Contenu et propriété intellectuelle';

  @override
  String get legalCgu5Body =>
      'Les plans payants (Starter, Expert, Institution) sont facturés mensuellement via Mobile Money (MTN MoMo, Orange Money) ou carte bancaire. Les tarifs sont affichés en francs CFA (XAF) et peuvent évoluer avec préavis de 30 jours.';

  @override
  String get legalCgu5Title => '5. Abonnements et paiements';

  @override
  String get legalCgu6Body =>
      'Vous pouvez résilier votre abonnement à tout moment depuis votre profil. La résiliation prend effet à la fin de la période de facturation en cours. Aucun remboursement partiel n\'est accordé.';

  @override
  String get legalCgu6Title => '6. Résiliation';

  @override
  String get legalCgu7Body =>
      'WinPlus s\'efforce de maintenir la plateforme disponible 24h/24, mais ne saurait être tenue responsable des interruptions de service, pertes de données ou inexactitudes dans les contenus.';

  @override
  String get legalCgu7Title => '7. Responsabilité';

  @override
  String get legalCgu8Body =>
      'Les présentes CGU sont soumises au droit camerounais. Tout litige sera porté devant les juridictions compétentes de Yaoundé, Cameroun.';

  @override
  String get legalCgu8Title => '8. Droit applicable';

  @override
  String get legalCguTitle => 'Conditions Générales d\'Utilisation';

  @override
  String get legalContactBody =>
      'Pour toute question : support@winplus.cm\nWinPlus SAS  Yaoundé, Cameroun';

  @override
  String get legalContactTitle => 'Contact';

  @override
  String get legalLastUpdated => 'Dernière mise à jour : 1er juin 2025';

  @override
  String get legalPriv1Body =>
      'WinPlus collecte les données suivantes :\n• Données d\'identification : nom, prénom, adresse e-mail\n• Données de navigation : contenus consultés, résultats de quiz\n• Données de paiement : transmises directement à nos prestataires (MTN, Orange)\n• Données d\'appareil : modèle, système d\'exploitation, identifiant publicitaire';

  @override
  String get legalPriv1Title => '1. Données collectées';

  @override
  String get legalPriv2Body =>
      'Vos données sont utilisées pour :\n• Fournir et personnaliser les services WinPlus\n• Générer des recommandations pédagogiques via WinAI\n• Traiter vos paiements et gérer votre abonnement\n• Améliorer la plateforme via des analyses agrégées anonymisées';

  @override
  String get legalPriv2Title => '2. Finalités du traitement';

  @override
  String get legalPriv3Body =>
      'Le traitement repose sur votre consentement (art. 4 loi n° 2010/012 du Cameroun sur les communications électroniques) et sur l\'exécution du contrat de service que représentent les présentes CGU.';

  @override
  String get legalPriv3Title => '3. Base légale';

  @override
  String get legalPriv4Body =>
      'Vos données sont conservées pendant la durée de votre relation contractuelle avec WinPlus, augmentée de 3 ans à des fins de preuve. Les données de navigation sont anonymisées après 13 mois.';

  @override
  String get legalPriv4Title => '4. Conservation des données';

  @override
  String get legalPriv5Body =>
      'WinPlus ne vend pas vos données. Elles peuvent être partagées avec :\n• Nos hébergeurs (serveurs sécurisés en Europe)\n• Nos prestataires de paiement (MTN, Orange, Stripe)\n• Les autorités compétentes en cas d\'obligation légale';

  @override
  String get legalPriv5Title => '5. Partage des données';

  @override
  String get legalPriv6Body =>
      'Conformément à la législation applicable, vous disposez des droits d\'accès, de rectification, d\'effacement, de portabilité et d\'opposition. Exercez-les en écrivant à privacy@winplus.cm.';

  @override
  String get legalPriv6Title => '6. Vos droits';

  @override
  String get legalPriv7Body =>
      'L\'application utilise des identifiants anonymes pour mesurer les performances et améliorer l\'expérience utilisateur. Vous pouvez les désactiver dans les paramètres de votre appareil.';

  @override
  String get legalPriv7Title => '7. Cookies et traceurs';

  @override
  String get legalPrivacyTitle => 'Politique de Confidentialité';

  @override
  String get login => 'Se connecter';

  @override
  String get loginSubtitle => 'Connecte-toi à ton compte WinPlus.';

  @override
  String get loginTitle => 'Bon retour !';

  @override
  String msgDaysAgo(Object n) {
    return 'il y a ${n}j';
  }

  @override
  String get msgEmpty => 'Aucune conversation.';

  @override
  String get msgEmptyHint =>
      'Contactez un professeur depuis la fiche d\'un élève.';

  @override
  String get msgHint => 'Votre message…';

  @override
  String msgHoursAgo(Object n) {
    return 'il y a ${n}h';
  }

  @override
  String msgMinutesAgo(Object n) {
    return 'il y a $n min';
  }

  @override
  String get msgNow => 'maintenant';

  @override
  String get msgRoleUser => 'Utilisateur';

  @override
  String get msgStartConversation => 'Commencez la conversation.';

  @override
  String get msgTitle => 'Messages';

  @override
  String get noAccountYet => 'Pas encore de compte ? ';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get parentAddChildEmailLabel => 'Email de l\'enfant *';

  @override
  String get parentAddChildIntro =>
      'Entrez l\'adresse email du compte WinPlus de votre enfant pour le lier à votre espace parent.';

  @override
  String get parentAddChildInvalidEmail => 'Veuillez saisir un email valide.';

  @override
  String get parentAddChildLink => 'Lier l\'enfant';

  @override
  String get parentAddChildNoCatalog =>
      'Votre plan n\'ouvre pas le catalogue à vos enfants.';

  @override
  String get parentAddChildNotFound =>
      'Aucun élève trouvé avec cet email, ou déjà lié.';

  @override
  String parentAddChildPlanLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'enfants',
      one: 'enfant',
      zero: 'enfant',
    );
    return 'Votre plan suit $count $_temp0, sans catalogue pour eux. Un plan parent ouvre le catalogue et les alertes WinAI.';
  }

  @override
  String get parentAddChildSuccess =>
      'Enfant ajouté à votre compte avec succès.';

  @override
  String get parentAddChildTitle => 'Ajouter un enfant';

  @override
  String get parentAiHint => 'Posez votre question sur la scolarité…';

  @override
  String get parentAiSuggestion1 => 'Mon enfant est en difficulté';

  @override
  String get parentAiSuggestion2 => 'Plan de révision maison';

  @override
  String get parentAiSuggestion3 => 'Analyse ses résultats';

  @override
  String get parentAiSuggestion4 => 'Comment le motiver ?';

  @override
  String get parentAiTagline => 'Ton conseiller familial chaleureux';

  @override
  String get parentAlbumGoals => 'Objectifs de l\'année';

  @override
  String get parentAlbumIntensity => 'Moments d\'intensité';

  @override
  String parentAlbumMeta(Object year, Object date) {
    return 'Année scolaire $year · mis à jour le $date';
  }

  @override
  String parentAlbumNotGenerated(Object name) {
    return 'L\'album de $name n\'a pas encore été généré cette année.';
  }

  @override
  String get parentAlbumProgress => 'Progression observée';

  @override
  String get parentAlbumReportCard => 'Bulletin';

  @override
  String get parentAlbumSubjects => 'Matières travaillées';

  @override
  String parentAlbumTitle(Object name) {
    return 'Album de l\'année de $name';
  }

  @override
  String get parentAlbumTopContents => 'Contenus les plus consultés';

  @override
  String get parentAlertBadgeHigh => 'Alerte';

  @override
  String get parentAlertBadgeInfo => 'Info';

  @override
  String get parentAlertBadgeMedium => 'Attention';

  @override
  String get parentAlertsAllGood => 'Tout va bien pour vos enfants !';

  @override
  String get parentAlertsIntro =>
      'WinAI surveille les progrès de vos enfants et vous alerte en temps réel.';

  @override
  String get parentAlertsNone => 'Aucune alerte active.';

  @override
  String get parentAlertsRecent => 'Alertes récentes';

  @override
  String get parentAlertsSeeActivity => 'Voir l\'activité';

  @override
  String get parentAlertsTip1Text =>
      'Encouragez les sessions courtes régulières plutôt que les longues sessions irrégulières. La rétention est bien meilleure.';

  @override
  String get parentAlertsTip1Title => 'Sessions courtes et régulières';

  @override
  String get parentAlertsTip2Text =>
      'Les quiz quotidiens améliorent la rétention de 40% par rapport à la lecture passive.';

  @override
  String get parentAlertsTip2Title => 'Quiz quotidiens';

  @override
  String get parentAlertsTip3Text =>
      'Fixez un objectif d\'examen précis avec votre enfant  une date et un examen concrets  pour le motiver efficacement.';

  @override
  String get parentAlertsTip3Title => 'Objectif clair';

  @override
  String get parentAlertsTipsTitle => 'Conseils WinAI';

  @override
  String get parentBuyBalance => 'Solde disponible';

  @override
  String get parentBuyContentForChild => 'Acheter du contenu pour un enfant';

  @override
  String parentBuyFor(Object name) {
    return 'Acheter pour $name';
  }

  @override
  String get parentBuyNoContent => 'Aucun contenu disponible pour le moment.';

  @override
  String get parentBuyNoSubscription =>
      'Aucun abonnement payant actif : abonnez-vous pour obtenir des crédits à dépenser pour vos enfants.';

  @override
  String parentBuyRecommended(Object name, Object level) {
    return 'Contenu recommandé pour $name$level';
  }

  @override
  String get parentBuyTitle => 'Acheter pour…';

  @override
  String get parentBuyWhichChild => 'Pour quel enfant ?';

  @override
  String get parentChildActivityWeek => 'Activité cette semaine';

  @override
  String get parentChildAiWeek => 'IA/sem.';

  @override
  String get parentChildAllGood => 'Tout va bien !';

  @override
  String get parentChildAvgScore30 => 'Score moyen sur 30 jours';

  @override
  String get parentChildAvgScoreShort => 'Score moy.';

  @override
  String get parentChildBestSubject => 'Meilleure matière';

  @override
  String parentChildCatalogFiltered(Object name) {
    return 'Catalogue filtré pour $name';
  }

  @override
  String get parentChildDownloadsWeek => 'Téléch./sem.';

  @override
  String get parentChildEncourage => 'Encourager';

  @override
  String get parentChildGenerateQuiz => 'Générer un quiz';

  @override
  String get parentChildInactive => 'Inactif';

  @override
  String get parentChildLastQuiz => 'Dernier quiz';

  @override
  String get parentChildNoRecentActivity => 'Aucune activité récente.';

  @override
  String get parentChildNoResults => 'Pas encore de résultats ce mois-ci.';

  @override
  String get parentChildQuizGenerating => 'Quiz en cours de génération...';

  @override
  String get parentChildQuizWeek => 'Quiz/sem.';

  @override
  String get parentChildRecentActivity => 'Activité récente';

  @override
  String parentChildRegular(Object name) {
    return '$name est régulier(e) dans ses révisions.';
  }

  @override
  String get parentChildScoreBySubject => 'Score moyen par matière (30 jours)';

  @override
  String get parentChildSeeResources => 'Voir ressources';

  @override
  String get parentChildTabActivity => 'Activité';

  @override
  String get parentChildTabAlbum => 'Album';

  @override
  String get parentChildTabExamWatch => 'Veille examen';

  @override
  String get parentChildTabGoals => 'Objectifs';

  @override
  String get parentChildTabPortrait => 'Portrait';

  @override
  String get parentChildToWorkOn => 'À travailler';

  @override
  String parentChildrenLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'enfants',
      one: 'enfant',
      zero: 'enfant',
    );
    return '$count $_temp0 max avec votre plan';
  }

  @override
  String get parentCoveredAll =>
      'Votre plan couvre tous vos enfants liés : il n’y a rien à choisir.';

  @override
  String get parentCoveredBadge => 'Couvert';

  @override
  String get parentCoveredCustom => 'Choix enregistré';

  @override
  String get parentCoveredDefault =>
      'Par défaut, les enfants liés en premier sont couverts';

  @override
  String get parentCoveredLoadError =>
      'Les informations n’ont pas pu être chargées.';

  @override
  String get parentCoveredMore => 'Couvrir plus d’enfants';

  @override
  String parentCoveredNextChange(Object date) {
    return 'prochain changement possible le $date';
  }

  @override
  String get parentCoveredOnePerPeriod =>
      'un changement par période d’abonnement';

  @override
  String get parentCoveredSave => 'Enregistrer le choix';

  @override
  String get parentCoveredSaved =>
      'Votre choix est enregistré : il s’applique tout de suite.';

  @override
  String parentCoveredSubMany(Object max, Object total) {
    return 'Votre plan couvre $max enfants sur $total liés : catalogue, bonus WinAI et alertes.';
  }

  @override
  String parentCoveredSubOne(Object max, Object total) {
    return 'Votre plan couvre $max enfant sur $total liés : catalogue, bonus WinAI et alertes.';
  }

  @override
  String get parentCoveredTitle => 'Enfants couverts';

  @override
  String parentCoveredUpTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'enfants',
      one: 'enfant',
      zero: 'enfant',
    );
    return 'Votre plan couvre jusqu’à $count $_temp0 et tous vos enfants liés sont couverts.';
  }

  @override
  String get parentDashAlertsAdvice => 'Alertes & conseils WinAI';

  @override
  String get parentDashBalance => 'Solde';

  @override
  String get parentDashChildrenFollowed => 'enfants suivis';

  @override
  String get parentDashCreditsAvail => 'crédits dispo';

  @override
  String parentDashCreditsDetail(Object allocation, Object topups) {
    return 'Dont $allocation XAF de dotation du plan et $topups XAF de recharges';
  }

  @override
  String get parentDashCreditsTitle => 'Crédits disponibles';

  @override
  String get parentDashLoadingBalance => 'Chargement du solde…';

  @override
  String get parentDashNoChild =>
      'Aucun enfant suivi. Ajoutez un enfant depuis l\'onglet Enfants.';

  @override
  String get parentDashNoCredits =>
      'Aucun crédit : les crédits sont versés avec un abonnement parent actif.';

  @override
  String parentDashPeriodEndIn(Object plan, Object days) {
    return 'Plan $plan · Fin de période dans $days jours';
  }

  @override
  String parentDashRenewalEvent(Object plan) {
    return 'Fin de période · plan $plan';
  }

  @override
  String get parentDashSeeSubscription => 'Voir l\'abonnement';

  @override
  String get parentDashUpcomingEvents => 'Évènements à venir';

  @override
  String parentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours',
      one: 'jour',
      zero: 'jour',
    );
    return 'Il y a $count $_temp0';
  }

  @override
  String get parentEncourageChooseTemplate => 'Choisir un modèle';

  @override
  String get parentEncourageHint => 'Votre message...';

  @override
  String get parentEncourageOrWrite => 'Ou écrire un message personnalisé';

  @override
  String get parentEncourageSendError =>
      'Impossible d\'envoyer le message. Réessayez.';

  @override
  String parentEncourageSent(Object name) {
    return 'Message envoyé à $name !';
  }

  @override
  String get parentEncourageSub => 'Choisissez un message ou écrivez le vôtre';

  @override
  String parentEncourageTitle(Object name) {
    return 'Encourager $name';
  }

  @override
  String parentEncourageTpl1(Object name) {
    return 'Continue comme ça $name, je suis fier(e) de toi !';
  }

  @override
  String parentEncourageTpl2(Object name) {
    return 'N\'oublie pas de réviser la Chimie ce soir $name !';
  }

  @override
  String parentEncourageTpl3(Object name) {
    return '$name, tu peux le faire  le BAC approche !';
  }

  @override
  String parentEncourageTpl4(Object name, Object score) {
    return '$name, $score cette semaine, c\'est excellent !';
  }

  @override
  String get parentEncourageYourScore => 'ton score';

  @override
  String parentEventInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours',
      one: 'jour',
      zero: 'jour',
    );
    return 'dans $count $_temp0';
  }

  @override
  String get parentEventToday => 'aujourd\'hui';

  @override
  String get parentGoalActiveTitle => 'Objectifs actifs co-construits';

  @override
  String parentGoalDeadlineOn(Object date) {
    return 'Échéance : $date';
  }

  @override
  String get parentGoalFieldDescription => 'Description (optionnel)';

  @override
  String get parentGoalIntro =>
      'Votre proposition attend l\'accord de votre enfant : il peut l\'accepter telle quelle, l\'ajuster, ou la refuser.';

  @override
  String get parentGoalNoActive =>
      'Aucun objectif co-construit actif pour le moment.';

  @override
  String get parentGoalNoPending => 'Aucune proposition en attente de réponse.';

  @override
  String get parentGoalPendingTitle => 'Propositions en attente';

  @override
  String parentGoalProposeTo(Object name) {
    return 'Proposer un objectif à $name';
  }

  @override
  String get parentGoalSent => 'Proposition envoyée.';

  @override
  String get parentGoalSubmit => 'Proposer l\'objectif';

  @override
  String get parentGoalSubmitError =>
      'La proposition n\'a pas pu être envoyée. Réessayez.';

  @override
  String get parentGoalTypeAcademic => 'Scolaire';

  @override
  String get parentGoalTypePersonal => 'Personnel';

  @override
  String get parentGoalTypeSkill => 'Compétence';

  @override
  String get parentNoSubscription => 'Sans abonnement';

  @override
  String get parentPayStatusFailed => 'échoué';

  @override
  String get parentPayStatusPending => 'en attente';

  @override
  String get parentPayStatusRefundRequested => 'remboursement demandé';

  @override
  String get parentPayStatusRefunded => 'remboursé';

  @override
  String get parentPaymentsEmpty =>
      'Aucun paiement pour le moment. Vos achats, abonnements et recharges apparaîtront ici.';

  @override
  String get parentPaymentsLoadError =>
      'L\'historique n\'a pas pu être chargé.';

  @override
  String get parentPaymentsMonthSpent => 'DÉPENSES CE MOIS';

  @override
  String get parentPaymentsTitle => 'Paiements';

  @override
  String parentPlanName(Object plan) {
    return 'Plan $plan';
  }

  @override
  String get parentPortfolioAutonomy => 'Autonomie';

  @override
  String get parentPortfolioCuriosity => 'Curiosité';

  @override
  String parentPortfolioNoAutonomy(Object name) {
    return 'Pas encore de données d\'autonomie pour $name.';
  }

  @override
  String parentPortfolioNoCuriosity(Object name) {
    return 'Pas encore de données de curiosité pour $name.';
  }

  @override
  String parentPortfolioNoRegularity(Object name) {
    return 'Pas encore de données de régularité pour $name.';
  }

  @override
  String parentPortfolioNotYet(Object name) {
    return 'Le portrait de $name sera disponible après le premier calcul mensuel.';
  }

  @override
  String get parentPortfolioRegularity => 'Régularité';

  @override
  String parentPortfolioTitle(Object name) {
    return 'Portrait de $name';
  }

  @override
  String parentPortfolioUpdatedOn(Object date) {
    return 'Dernière mise à jour le $date';
  }

  @override
  String get parentProfileCovered => 'Enfants couverts par mon plan';

  @override
  String get parentProfileCredits => 'Crédits';

  @override
  String get parentProfileManageSub => 'Gérer l\'abonnement';

  @override
  String get parentProfileMyAccount => 'Mon compte';

  @override
  String get parentProfilePayments => 'Paiements & historique';

  @override
  String get parentProfileTutoring => 'Cours particuliers de mes enfants';

  @override
  String get parentResourcesIntro =>
      'D\'après les résultats de vos enfants, ces ressources cibleront leurs points faibles.';

  @override
  String get parentResourcesRecommended => 'Recommandées par WinAI';

  @override
  String get parentSubAiFree => 'Usage WinAI du plan gratuit';

  @override
  String parentSubAiMultiplier(Object n) {
    return '${n}x plus d\'usage WinAI que le plan gratuit';
  }

  @override
  String get parentSubAutoRenewOn => 'Renouvellement automatique activé';

  @override
  String get parentSubBackToFree => 'Vous repasserez sur l\'offre gratuite.';

  @override
  String get parentSubCancel => 'Résilier';

  @override
  String get parentSubCancelChange => 'Annuler ce changement';

  @override
  String get parentSubCancelConfirmTitle => 'Résilier ?';

  @override
  String parentSubCancelledUntil(Object date) {
    return 'Résilié : accès jusqu\'au $date';
  }

  @override
  String get parentSubChangePlan => 'Changer de plan';

  @override
  String get parentSubChildrenFollowed => 'Enfants suivis';

  @override
  String get parentSubDisableAutoRenew =>
      'Désactiver le renouvellement automatique';

  @override
  String get parentSubEnableAutoRenew =>
      'Renouveler automatiquement avec mon solde';

  @override
  String get parentSubFailed => 'Échoué';

  @override
  String get parentSubIncludes => 'Ce que comprend votre plan';

  @override
  String parentSubKeepAccessUntil(Object date) {
    return 'Vous gardez l\'accès jusqu\'au $date, sans remboursement de la période en cours.';
  }

  @override
  String get parentSubLimitReached => 'Limite atteinte';

  @override
  String get parentSubLoadError => 'Impossible de charger l\'abonnement.';

  @override
  String get parentSubManualRenew => 'Renouvellement manuel';

  @override
  String get parentSubMyChildren => 'Mes enfants';

  @override
  String get parentSubNoPayment => 'Aucun paiement enregistré pour l\'instant.';

  @override
  String get parentSubPaid => 'Payé';

  @override
  String get parentSubPaymentHistory => 'Historique des paiements';

  @override
  String get parentSubPaymentPending => 'Paiement en attente';

  @override
  String parentSubPendingSwitch(Object plan) {
    return 'Passage à $plan programmé à l\'échéance.';
  }

  @override
  String parentSubPeriodUntil(Object date) {
    return 'Période en cours jusqu\'au $date';
  }

  @override
  String get parentSubRenewNow => 'Renouveler maintenant';

  @override
  String get parentSubResume => 'Reprendre l\'abonnement';

  @override
  String get parentSubTitle => 'Mon Abonnement';

  @override
  String get parentSubTrial => 'Essai';

  @override
  String get parentWatchActivate => 'Activer la veille';

  @override
  String get parentWatchActivateError =>
      'Impossible d\'activer la veille pour le moment.';

  @override
  String get parentWatchBeforeExam => 'avant l\'examen';

  @override
  String parentWatchCountdown(Object n) {
    return 'J-$n';
  }

  @override
  String get parentWatchDeactivate => 'Désactiver la veille';

  @override
  String get parentWatchDeactivateError =>
      'Impossible de désactiver la veille pour le moment.';

  @override
  String get parentWatchExamDate => 'Date de l\'examen';

  @override
  String parentWatchExamOn(Object date) {
    return 'Examen le $date';
  }

  @override
  String get parentWatchExamType => 'Type d\'examen';

  @override
  String get parentWatchExamTypeHint => 'Ex : BEPC, Baccalauréat série C…';

  @override
  String get parentWatchFormRequired =>
      'Choisissez un type d\'examen et une date.';

  @override
  String get parentWatchIntro =>
      'Un suivi rapproché pendant la période d\'examen : WinAI adapte ses conseils et vous propose des questions pertinentes dans l\'assistant familial.';

  @override
  String get parentWatchSubmitError =>
      'La veille n\'a pas pu être activée. Réessayez.';

  @override
  String get parentWatchTitle => 'Veille d\'examen';

  @override
  String get password => 'Mot de passe';

  @override
  String get roleInstitution => 'Établissement';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleStudent => 'Élève';

  @override
  String get roleTeacher => 'Professeur';

  @override
  String get roleTutor => 'Répétiteur';

  @override
  String get shellTabAccount => 'Compte';

  @override
  String get shellTabAnalytics => 'Analytics';

  @override
  String get shellTabCatalog => 'Catalogue';

  @override
  String get shellTabChildren => 'Enfants';

  @override
  String get shellTabContent => 'Contenus';

  @override
  String get shellTabEarnings => 'Revenus';

  @override
  String get shellTabGroups => 'Groupes';

  @override
  String get shellTabHome => 'Accueil';

  @override
  String get shellTabMe => 'Moi';

  @override
  String get shellTabMessages => 'Messages';

  @override
  String get shellTabMySpace => 'Mon Espace';

  @override
  String get shellTabProfile => 'Profil';

  @override
  String get shellTabResources => 'Ressources';

  @override
  String get shellTabSessions => 'Sessions';

  @override
  String get shellTabStudents => 'Étudiants';

  @override
  String get shopAccountRequiredBody =>
      'Connectez-vous ou créez un compte avant le paiement : le contenu acheté est rattaché à votre compte et reste accessible sur tous vos appareils.';

  @override
  String get shopAccountRequiredTitle =>
      'Un compte est nécessaire pour acheter';

  @override
  String get shopAmount => 'Montant';

  @override
  String get shopApply => 'Appliquer';

  @override
  String get shopAwaitingConfirmation => 'En attente de confirmation…';

  @override
  String get shopBackToCatalog => 'Retour au catalogue';

  @override
  String get shopBuy => 'Acheter';

  @override
  String get shopBuyFromAccountBody =>
      'Le paiement dans l\'application arrive bientôt. En attendant, achetez ce contenu depuis votre compte sur winplus.cm avec les mêmes identifiants : il sera ensuite disponible ici.';

  @override
  String get shopBuyFromAccountTitle => 'Achat depuis votre compte';

  @override
  String get shopCartEmpty => 'Votre panier est vide.';

  @override
  String get shopCartLoadFailed => 'Impossible de charger le panier.';

  @override
  String get shopCartRemoveFailed => 'Impossible de retirer cet article.';

  @override
  String get shopCartTitle => 'Mon panier';

  @override
  String get shopCheckNow => 'Vérifier maintenant';

  @override
  String get shopCheckoutStepConfirm => 'Confirmation';

  @override
  String get shopCheckoutStepSummary => 'Récapitulatif & paiement';

  @override
  String get shopContentAvailable =>
      'Vos contenus sont maintenant disponibles.';

  @override
  String get shopExploreCatalog => 'Explorer le catalogue';

  @override
  String get shopInvalidPhone => 'Numéro de téléphone invalide.';

  @override
  String get shopInvoiceLoadFailed => 'Impossible de charger la facture.';

  @override
  String shopInvoiceTitle(Object number) {
    return 'Facture $number';
  }

  @override
  String get shopItems => 'Articles';

  @override
  String shopItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: '0 article',
    );
    return '$_temp0';
  }

  @override
  String get shopMyOrders => 'Mes commandes';

  @override
  String get shopNoOrders => 'Aucune commande pour le moment.';

  @override
  String get shopOrder => 'Commande';

  @override
  String get shopOrderCancelled => 'Annulée';

  @override
  String get shopOrderFailed => 'Échouée';

  @override
  String get shopOrderPaid => 'Payée';

  @override
  String get shopOrderRefundRequested => 'Remboursement demandé';

  @override
  String get shopOrderRefunded => 'Remboursée';

  @override
  String shopPayAmount(Object amount) {
    return 'Payer $amount XAF';
  }

  @override
  String get shopPaymentConfirmed => 'Paiement confirmé !';

  @override
  String get shopPaymentFailed => 'Paiement échoué';

  @override
  String get shopPaymentMethod => 'Mode de paiement';

  @override
  String get shopPaymentNotConfirmed =>
      'Le paiement n\'a pas pu être confirmé.';

  @override
  String get shopPhoneNumber => 'Numéro de téléphone';

  @override
  String get shopPlaceOrder => 'Passer la commande';

  @override
  String shopPromoApplied(Object amount) {
    return 'Réduction appliquée : -$amount XAF';
  }

  @override
  String get shopPromoCode => 'Code promo';

  @override
  String shopReference(Object ref) {
    return 'Réf. : $ref';
  }

  @override
  String get shopRefundFailed => 'Impossible d\'envoyer la demande.';

  @override
  String get shopRefundSent => 'Demande de remboursement envoyée.';

  @override
  String get shopRequestRefund => 'Demander un remboursement';

  @override
  String get shopSeeMyOrders => 'Voir mes commandes';

  @override
  String get shopSlowPayment =>
      'Le paiement met plus de temps que prévu. Vous pouvez vérifier plus tard dans \"Mes commandes\".';

  @override
  String get shopStillPending => 'Toujours en attente';

  @override
  String shopSubjectFallback(Object id) {
    return 'Sujet #$id';
  }

  @override
  String get shopSubtotal => 'Sous-total';

  @override
  String get shopTotal => 'Total';

  @override
  String get shopTotalTtc => 'Total TTC';

  @override
  String get shopUnexpectedError => 'Erreur inattendue. Réessayez.';

  @override
  String get shopUssdNotice =>
      'Vous recevrez une notification USSD pour valider.';

  @override
  String get shopValidateUssd =>
      'Valide le paiement via le message USSD envoyé sur ton téléphone.';

  @override
  String get shopVatIncluded => 'dont TVA 19,25 % incluse';

  @override
  String get shopViewInvoice => 'Voir la facture';

  @override
  String studentAchBadgesUnlocked(Object unlocked, Object total) {
    return '$unlocked / $total badges débloqués';
  }

  @override
  String get studentAchCurrentStreak => 'Série actuelle';

  @override
  String get studentAchLocked => 'Verrouillé';

  @override
  String get studentAchMyBadges => 'Mes badges';

  @override
  String studentAchStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours consécutifs',
      one: '$count jours consécutifs',
    );
    return '$_temp0';
  }

  @override
  String get studentAchStreakLoadError =>
      'Impossible de charger ta série réelle. La série ci-dessous peut ne pas être à jour.';

  @override
  String get studentAchTitle => 'Achievements';

  @override
  String get studentAchUnlocked => 'Débloqué';

  @override
  String get studentCatalogAccess => 'Accès';

  @override
  String get studentCatalogAllAccess => 'Tous';

  @override
  String get studentCatalogApply => 'Appliquer';

  @override
  String get studentCatalogCatSciences => 'Sciences';

  @override
  String get studentCatalogEmpty => 'Aucune formation trouvée.';

  @override
  String get studentCatalogFilters => 'Filtres';

  @override
  String get studentCatalogLevelAdvanced => 'avancé';

  @override
  String get studentCatalogLevelBeginner => 'débutant';

  @override
  String get studentCatalogLevelIntermediate => 'intermédiaire';

  @override
  String get studentCatalogLoadMore => 'Charger plus';

  @override
  String get studentCatalogPaid => 'Payant';

  @override
  String studentCatalogPriceTtc(Object amount) {
    return '$amount XAF TTC';
  }

  @override
  String get studentCatalogReset => 'Réinitialiser';

  @override
  String get studentCatalogSearchHint => 'Rechercher une formation…';

  @override
  String get studentCertCourses => 'Formations';

  @override
  String get studentCertDownloadPdf => 'Télécharger PDF';

  @override
  String get studentCertEmpty => 'Aucun certificat pour l\'instant';

  @override
  String get studentCertEmptyHint =>
      'Complétez des quiz et des parcours pour\ndécrocher vos premiers certificats.';

  @override
  String studentCertIssuedOn(Object date) {
    return 'Délivré le $date';
  }

  @override
  String get studentCertLoadError => 'Impossible de charger les certificats.';

  @override
  String get studentCertMentionGood => 'Mention Bien';

  @override
  String get studentCertMentionVeryGood => 'Mention Très Bien';

  @override
  String get studentCertPapersAndPaths => 'Épreuves et parcours';

  @override
  String get studentCertPdfLoadError =>
      'Le certificat n\'a pas pu être chargé.';

  @override
  String get studentCertSeePdf => 'Voir le certificat (PDF)';

  @override
  String get studentCertShare => 'Partager';

  @override
  String get studentCertTitle => 'Mes Certificats';

  @override
  String studentCertVerificationCode(Object code) {
    return 'Code de vérification : $code';
  }

  @override
  String studentCoachCompletion(Object pct) {
    return '$pct% du plan complété';
  }

  @override
  String studentCoachDaysLeft(Object days) {
    return '$days j restants';
  }

  @override
  String get studentCoachDeleteBody => 'Cette action est irréversible.';

  @override
  String get studentCoachDeletePlan => 'Supprimer le plan';

  @override
  String get studentCoachDeleteTitle => 'Supprimer ce plan ?';

  @override
  String get studentCoachExamDate => 'Date de l\'examen';

  @override
  String get studentCoachGenerate => 'Générer mon plan avec WinAI';

  @override
  String get studentCoachGenerateError =>
      'Impossible de générer le plan. Réessaie dans un instant.';

  @override
  String get studentCoachGenerating => 'Génération…';

  @override
  String get studentCoachHoursPerDay => 'Heures d\'étude par jour';

  @override
  String get studentCoachIntro =>
      'WinAI génère un planning jour par jour adapté à ta date d\'examen et ton rythme.';

  @override
  String get studentCoachLoadError =>
      'Impossible de charger ton plan. Vérifie ta connexion.';

  @override
  String get studentCoachLocked =>
      'Disponible à partir du plan Standard.\nWinAI génère un planning adapté à tes lacunes.';

  @override
  String get studentCoachMarkToday => 'Marquer la session du jour comme faite';

  @override
  String get studentCoachNoWeek => 'Planning indisponible pour cette semaine.';

  @override
  String get studentCoachPickDate => 'Choisir une date';

  @override
  String studentCoachReliability(Object value) {
    return 'Fiabilité du plan : $value%';
  }

  @override
  String get studentCoachRest => 'Repos';

  @override
  String get studentCoachSeePlans => 'Voir les plans';

  @override
  String get studentCoachTargetExam => 'Examen cible';

  @override
  String get studentCoachThisWeek => 'Cette semaine';

  @override
  String studentCoachTodayDay(Object day) {
    return 'Aujourd\'hui · J$day';
  }

  @override
  String get studentCoachTodayDone => 'Session du jour complétée';

  @override
  String get studentCourseBuy => 'Acheter la formation';

  @override
  String studentCourseBuyNote(Object amount) {
    return '$amount XAF TTC (TVA 19,25 % incluse). Formation vendue seule, accès à vie dès la confirmation du paiement.';
  }

  @override
  String get studentCourseCertIncluded => 'Certificat de réussite inclus';

  @override
  String get studentCourseContent => 'Contenu';

  @override
  String get studentCourseContinue => 'Continuer la formation';

  @override
  String studentCourseCurriculumSummary(
      Object sections, Object lessons, Object duration) {
    return '$sections sections · $lessons leçons · $duration';
  }

  @override
  String get studentCourseEnrolError => 'Erreur lors de l\'inscription.';

  @override
  String studentCourseEnrolled(Object n) {
    return '$n inscrits';
  }

  @override
  String get studentCourseError => 'Erreur';

  @override
  String get studentCourseLeaveReview => 'Donnez votre avis';

  @override
  String studentCourseLessons(Object n) {
    return '$n leçons';
  }

  @override
  String get studentCourseNoChild =>
      'Aucun enfant n\'est rattaché à votre compte.';

  @override
  String get studentCourseNoReviews => 'Aucun avis pour le moment.';

  @override
  String get studentCourseNotFound => 'Formation introuvable.';

  @override
  String get studentCourseObjectives => 'Ce que vous apprendrez';

  @override
  String get studentCourseOfferChild => 'Offrir à mon enfant';

  @override
  String studentCourseOfferTitle(Object title, Object amount) {
    return 'Offrir « $title » ($amount XAF TTC, débité du portefeuille)';
  }

  @override
  String studentCourseOffered(Object name) {
    return 'Formation offerte à $name : accès ouvert.';
  }

  @override
  String get studentCoursePayBalance => 'Payer avec mon solde WinPlus';

  @override
  String get studentCoursePayMomo => 'Payer par Mobile Money';

  @override
  String get studentCoursePostReview => 'Publier mon avis';

  @override
  String get studentCoursePreview => 'Aperçu';

  @override
  String get studentCoursePurchased =>
      'Formation achetée : elle est dans « Mes formations ».';

  @override
  String get studentCoursePurchasedBadge => 'Achetée';

  @override
  String get studentCoursePurchasedStart => 'Achetée : commencer';

  @override
  String get studentCourseRequirements => 'Prérequis';

  @override
  String get studentCourseReviewHint =>
      'Partagez votre expérience (optionnel)…';

  @override
  String get studentCourseReviewSubmitError => 'Erreur lors de la soumission.';

  @override
  String get studentCourseReviewThanks => 'Merci pour votre avis !';

  @override
  String get studentCourseReviews => 'Avis';

  @override
  String get studentCourseStartFree => 'Commencer gratuitement';

  @override
  String get studentCourseVatNote =>
      'TTC, TVA 19,25 % incluse · hors abonnement';

  @override
  String get studentCourseYours => 'Votre formation';

  @override
  String get studentDetailAddNote => 'Ajouter une note';

  @override
  String get studentDetailAddNoteHint => 'Ajouter une note…';

  @override
  String get studentDetailAddToCartError => 'Impossible d\'ajouter au panier.';

  @override
  String studentDetailAddToCartPrice(Object price) {
    return 'Ajouter au panier  $price XAF';
  }

  @override
  String get studentDetailAddedToCart => 'Ajouté au panier.';

  @override
  String studentDetailBy(Object teacher) {
    return 'Par $teacher';
  }

  @override
  String get studentDetailDefaultDescription => 'Contenu éducatif de qualité.';

  @override
  String get studentDetailDemoNoDocument =>
      'Ce contenu de démonstration n\'a pas de document à afficher.';

  @override
  String get studentDetailDemoNoSubject =>
      'Ce contenu de démonstration n\'a pas de sujet réel.';

  @override
  String get studentDetailMyNotes => 'Mes notes';

  @override
  String get studentDetailNoReviews => 'Aucun avis pour l\'instant.';

  @override
  String get studentDetailOrSubscriptions => 'ou découvrez les abonnements';

  @override
  String studentDetailRatingCount(Object rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '$count avis',
    );
    return '$rating ($_temp0)';
  }

  @override
  String get studentDetailReadBook => 'Lire le livre';

  @override
  String get studentDetailReadInApp => 'Lire dans l\'application';

  @override
  String studentDetailReadPreview(Object pages) {
    return 'Lire l\'aperçu ($pages pages)';
  }

  @override
  String studentDetailReviewsHeader(Object count) {
    return 'Avis ($count)';
  }

  @override
  String get studentDetailSimilar => 'Contenus similaires';

  @override
  String get studentDetailStartQuiz => 'Commencer le quiz';

  @override
  String get studentDetailTagHard => 'Difficile';

  @override
  String get studentDetailTagMastered => 'Maîtrisé';

  @override
  String get studentDetailTagToBuy => 'À acheter';

  @override
  String get studentDetailTagToRevise => 'À réviser';

  @override
  String get studentDetailVerified => 'Vérifié';

  @override
  String get studentDetailViewAnswers => 'Voir le corrigé';

  @override
  String get studentDetailViewCart => 'Voir le panier';

  @override
  String studentDetailViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consultations',
      one: '$count consultations',
    );
    return '$_temp0';
  }

  @override
  String studentFavAddedOn(Object date) {
    return 'Ajouté le $date';
  }

  @override
  String studentFavCount(Object count) {
    return '$count contenu(s) sauvegardé(s)';
  }

  @override
  String get studentFavEmpty => 'Aucun favori pour l\'instant';

  @override
  String get studentFavExplore => 'Explorer le catalogue';

  @override
  String studentFavLimit(Object max) {
    return 'Votre plan permet $max favoris. Passez à un plan supérieur pour en sauvegarder plus.';
  }

  @override
  String get studentFavLoadError => 'Impossible de charger les favoris.';

  @override
  String get studentFavTitle => 'Mes Favoris';

  @override
  String get studentGoalsAcceptError =>
      'Impossible d\'accepter cet objectif pour le moment.';

  @override
  String studentGoalsDeadlineOn(Object date) {
    return 'Échéance : $date';
  }

  @override
  String get studentGoalsFieldDeadline => 'Échéance';

  @override
  String get studentGoalsFieldTitle => 'Titre';

  @override
  String get studentGoalsProposedBy => 'Proposé par un de vos parents';

  @override
  String get studentGoalsRefuseConfirm => 'Refuser définitivement ?';

  @override
  String get studentGoalsRefuseError =>
      'Impossible de refuser cet objectif pour le moment.';

  @override
  String get studentGoalsRequired => 'Le titre et l\'échéance sont requis.';

  @override
  String get studentGoalsSaveActivate => 'Enregistrer et activer';

  @override
  String get studentGoalsSaveError =>
      'Impossible d\'enregistrer les modifications pour le moment.';

  @override
  String get studentGoalsTitle => 'Objectifs proposés par vos parents';

  @override
  String studentGroupsAlreadyMember(Object name) {
    return 'Vous faites déjà partie de « $name ».';
  }

  @override
  String get studentGroupsCodeIncomplete =>
      'Entrez le code d\'invitation complet.';

  @override
  String get studentGroupsCodeNotFound =>
      'Aucun groupe ne correspond à ce code.';

  @override
  String get studentGroupsCreate => 'Créer un groupe';

  @override
  String get studentGroupsCreateBtn => 'Créer';

  @override
  String get studentGroupsCreateError => 'Le groupe n\'a pas pu être créé.';

  @override
  String get studentGroupsCreatePlus => '+ Créer un groupe';

  @override
  String get studentGroupsCreating => 'Création…';

  @override
  String get studentGroupsDetailLoadError => 'Impossible de charger ce groupe.';

  @override
  String get studentGroupsEmpty => 'Aucun groupe pour le moment.';

  @override
  String get studentGroupsEmptyHint =>
      'Créez un groupe ou rejoignez celui d\'un camarade avec son code.';

  @override
  String get studentGroupsInviteCode => 'Code d\'invitation';

  @override
  String get studentGroupsJoin => 'Rejoindre';

  @override
  String get studentGroupsJoinByCode => 'Rejoindre par code';

  @override
  String studentGroupsJoined(Object name) {
    return 'Groupe « $name » rejoint avec succès !';
  }

  @override
  String get studentGroupsLeaderboard => 'Classement (7 derniers jours)';

  @override
  String get studentGroupsLeaderboardUnavailable =>
      'Classement indisponible pour le moment.';

  @override
  String get studentGroupsLeave => 'Quitter';

  @override
  String studentGroupsLeaveConfirm(Object name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get studentGroupsLeaveError =>
      'Vous n\'avez pas pu quitter ce groupe.';

  @override
  String studentGroupsLeaveOwner(Object name) {
    return 'Quitter « $name » ? Le groupe sera archivé pour tous ses membres.';
  }

  @override
  String get studentGroupsLeaveTitle => 'Quitter ce groupe ?';

  @override
  String get studentGroupsLoadError =>
      'Vos groupes n\'ont pas pu être chargés.';

  @override
  String get studentGroupsMember => 'Membre';

  @override
  String studentGroupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membre',
    );
    return '$_temp0';
  }

  @override
  String get studentGroupsMembers => 'Membres';

  @override
  String studentGroupsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membres',
    );
    return '$_temp0';
  }

  @override
  String get studentGroupsMine => 'Mes groupes';

  @override
  String get studentGroupsNameHint => 'Nom du groupe (min 3 caractères)';

  @override
  String get studentGroupsNameTooShort =>
      'Le nom doit contenir au moins 3 caractères.';

  @override
  String get studentGroupsNoActivity =>
      'Personne n\'a encore d\'activité cette semaine.';

  @override
  String get studentGroupsOwner => 'Propriétaire';

  @override
  String studentGroupsRankLine(Object quizzes, Object minutes) {
    return '$quizzes quiz réussis · $minutes min étudiées';
  }

  @override
  String get studentGroupsSending => 'Envoi…';

  @override
  String get studentGroupsSubjectHint => 'Matière principale (optionnel)';

  @override
  String get studentHistCatCourse => 'Cours';

  @override
  String get studentHistCatDocument => 'Document';

  @override
  String get studentHistCatExercise => 'Exercice';

  @override
  String get studentHistCatPaper => 'Épreuve';

  @override
  String get studentHistCatSummary => 'Résumé';

  @override
  String studentHistDaysAgo(Object n) {
    return 'Il y a $n jours';
  }

  @override
  String get studentHistEmpty => 'Aucun document consulté pour l\'instant.';

  @override
  String get studentHistEmptyHint => 'Ouvre des épreuves depuis le catalogue.';

  @override
  String studentHistEmptyPeriod(Object period) {
    return 'Aucun document consulté sur $period.';
  }

  @override
  String studentHistFileCount(int count, Object period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers · $period',
      one: '$count fichier · $period',
      zero: '$count fichier · $period',
    );
    return '$_temp0';
  }

  @override
  String get studentHistLoadError => 'Impossible de charger l\'historique.';

  @override
  String get studentHistPeriod1y => '1 an';

  @override
  String get studentHistPeriod30d => '30j';

  @override
  String get studentHistPeriod7d => '7j';

  @override
  String get studentHistPeriod90d => '90j';

  @override
  String get studentHistTitle => 'Documents consultés';

  @override
  String get studentHomeAvgScore => 'score moyen';

  @override
  String get studentHomeBadges => 'Badges';

  @override
  String get studentHomeContinue => 'Continue où tu t\'es arrêté';

  @override
  String studentHomeDate(Object weekday, Object date) {
    return '$weekday $date';
  }

  @override
  String get studentHomeDaysInARow => 'jours d\'affilée';

  @override
  String get studentHomeDaysLabel => 'jours';

  @override
  String get studentHomeDownloads => 'Téléchargements';

  @override
  String get studentHomeGoodAfternoon => 'Bon après-midi';

  @override
  String get studentHomeGoodEvening => 'Bonsoir';

  @override
  String get studentHomeGoodMorning => 'Bonjour';

  @override
  String get studentHomeInARow => ' d\'affilée !';

  @override
  String get studentHomeOpenFailed =>
      'Ce contenu n\'a pas pu être ouvert. Réessaie plus tard.';

  @override
  String get studentHomeQuizPerWeek => 'Quiz / sem.';

  @override
  String get studentHomeResume => 'Reprendre';

  @override
  String get studentHomeSee => 'Voir';

  @override
  String get studentHomeStreak => 'Streak';

  @override
  String studentHomeStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jours',
    );
    return '$_temp0';
  }

  @override
  String get studentHomeStudyPerWeek => 'Étude / sem.';

  @override
  String get studentHomeStudyThisWeek => 'd\'étude cette semaine';

  @override
  String get studentHomeTimeLogged => 'Temps enregistré';

  @override
  String get studentHomeUpcomingExams => 'Examens à venir';

  @override
  String get studentHomeUpgrade =>
      'Avec un abonnement, tout le catalogue s\'ouvre et WinAI vous accompagne davantage.';

  @override
  String get studentHubAccount => 'Compte';

  @override
  String get studentHubBadgesSub => '14 débloqués';

  @override
  String get studentHubCertificates => 'Mes certificats';

  @override
  String get studentHubCertificatesSub => '2 signés';

  @override
  String get studentHubCommunity => 'Communauté';

  @override
  String get studentHubDefaultName => 'Étudiant';

  @override
  String get studentHubFavorites => 'Mes favoris';

  @override
  String get studentHubFavoritesSub => 'Vos contenus enregistrés';

  @override
  String get studentHubForum => 'Forum communauté';

  @override
  String get studentHubForumSub => 'Questions & réponses';

  @override
  String get studentHubGroups => 'Mes groupes d\'étude';

  @override
  String get studentHubGroupsSub => '3 groupes';

  @override
  String get studentHubHistory => 'Historique des téléchargements';

  @override
  String get studentHubLearning => 'Apprentissage';

  @override
  String get studentHubLogoutBody =>
      'Vous serez redirigé vers l\'écran d\'accueil.';

  @override
  String get studentHubLogoutConfirm => 'Déconnecter';

  @override
  String get studentHubLogoutTitle => 'Se déconnecter ?';

  @override
  String get studentHubNetworkSub => 'Parents, profs, établissement';

  @override
  String studentHubPlan(Object planName) {
    return 'Plan $planName';
  }

  @override
  String get studentHubPomodoroSub => '25 min focus · 5 min pause';

  @override
  String get studentHubPrivacy => 'Politique de confidentialité';

  @override
  String get studentHubProfileSettings => 'Paramètres du profil';

  @override
  String get studentHubReports => 'Mes rapports de progression';

  @override
  String get studentHubRevisionQuiz => 'Quiz de révision';

  @override
  String get studentHubRevisionQuizSub => 'Reprendre les questions ratées';

  @override
  String get studentHubSoon => 'Bientôt disponible !';

  @override
  String get studentHubSubscription => 'Mon abonnement';

  @override
  String studentHubSubscriptionSub(Object planName) {
    return 'Plan $planName · Gérer';
  }

  @override
  String get studentHubTerms => 'Conditions d\'utilisation';

  @override
  String get studentHubTutorPolicy => 'Politique de tutorat';

  @override
  String get studentHubWinaiSub => 'Ton assistant pédagogique';

  @override
  String get studentLinksActionFailed => 'Action impossible, réessaie.';

  @override
  String get studentLinksAttachAccepted => 'rattachement confirmé';

  @override
  String get studentLinksAttachPending =>
      'rattachement en attente de ta réponse';

  @override
  String get studentLinksAttachRefused =>
      'rattachement refusé pour les cours particuliers';

  @override
  String studentLinksClass(Object group) {
    return 'Classe $group';
  }

  @override
  String get studentLinksInvitations => 'Invitations reçues';

  @override
  String get studentLinksLoadError => 'Erreur de chargement';

  @override
  String get studentLinksParents => 'Parents';

  @override
  String get studentLinksRoleInstitution => 'institution';

  @override
  String get studentLinksRoleParent => 'parent';

  @override
  String get studentLinksSchools => 'Établissements';

  @override
  String get studentLinksSchoolsHint =>
      'En acceptant, l\'établissement peut réserver, payer et attribuer des cours particuliers pour toi. Tu peux changer d\'avis à tout moment.';

  @override
  String get studentLinksStudyGroups => 'Groupes d\'étude';

  @override
  String studentLinksTeacherClass(Object className) {
    return 'Professeur · $className';
  }

  @override
  String get studentLinksTeacherPending => 'Professeur · invitation en attente';

  @override
  String get studentLinksTeachers => 'Professeurs';

  @override
  String get studentLinksTitle => 'Mon réseau';

  @override
  String get studentLinksWithdraw => 'Retirer mon accord';

  @override
  String get studentMyCoursesEmpty => 'Aucune formation en cours';

  @override
  String get studentMyCoursesEmptyHint =>
      'Explorez notre catalogue et commencez à apprendre dès aujourd\'hui.';

  @override
  String get studentMyCoursesExplore => 'Explorer les formations';

  @override
  String get studentMyCoursesLoadError =>
      'Impossible de charger vos formations.';

  @override
  String get studentMyCoursesReplay => 'Revoir';

  @override
  String get studentMyCoursesStart => 'Commencer';

  @override
  String get studentMyCoursesTitle => 'Mes formations';

  @override
  String get studentNotifAllCaughtUp => 'Tout est à jour !';

  @override
  String studentNotifHoursAgo(Object n) {
    return 'Il y a ${n}h';
  }

  @override
  String get studentNotifJustNow => 'À l\'instant';

  @override
  String get studentNotifMarkFailed =>
      'Impossible de marquer les notifications comme lues. Réessaie.';

  @override
  String studentNotifMinutesAgo(Object n) {
    return 'Il y a $n min';
  }

  @override
  String get studentNotifReadAll => 'Tout lire';

  @override
  String get studentNotifSeeMore => 'Voir plus';

  @override
  String get studentNotifTitle => 'Notifications';

  @override
  String get studentPlayerAttachedFile => 'Fichier joint';

  @override
  String get studentPlayerCertAvailable => 'Votre certificat est disponible.';

  @override
  String get studentPlayerCertGenerating =>
      'Félicitations ! Votre certificat est en cours de génération.';

  @override
  String get studentPlayerCourseDone => 'Formation terminée !';

  @override
  String get studentPlayerCurriculum => 'Curriculum';

  @override
  String get studentPlayerDone => 'Terminé';

  @override
  String get studentPlayerDownloadFailed =>
      'Téléchargement impossible. Réessaie plus tard.';

  @override
  String get studentPlayerDownloadOffline => 'Télécharger hors-ligne';

  @override
  String get studentPlayerDownloaded =>
      'Leçon téléchargée pour un visionnage hors-ligne.';

  @override
  String get studentPlayerLessonDone => 'Leçon terminée';

  @override
  String get studentPlayerMarkDone => 'Marquer terminé';

  @override
  String get studentPlayerOfflinePlayback => 'Lecture hors-ligne';

  @override
  String get studentPlayerOpenViewer =>
      'Ouvrir dans la visionneuse (consultation en ligne)';

  @override
  String get studentPlayerRemoveOffline => 'Retirer le hors-ligne';

  @override
  String get studentPlayerSelectLesson => 'Sélectionnez une leçon.';

  @override
  String get studentPlayerTapToDownload => 'Appuyez pour télécharger';

  @override
  String get studentPlayerVideoUnavailable =>
      'Vidéo indisponible pour le moment.';

  @override
  String get studentProfile2fa => 'Authentification à 2 facteurs';

  @override
  String get studentProfile2faHint => 'Un code email à chaque connexion.';

  @override
  String get studentProfileActiveSessions => 'Sessions actives';

  @override
  String get studentProfileAnonStats => 'Statistiques anonymisées';

  @override
  String get studentProfileAnonStatsHint => 'Aide à améliorer WinPlus.';

  @override
  String get studentProfileChange => 'Changer';

  @override
  String get studentProfileChangePhoto => 'Modifier la photo';

  @override
  String get studentProfileChangePwd => 'Changer le mot de passe';

  @override
  String get studentProfileCodeReceived => 'Code reçu par email';

  @override
  String studentProfileCodeSent(Object email) {
    return 'Code envoyé à $email. Il expire après 15 minutes.';
  }

  @override
  String get studentProfileConfirmCode => 'Code de confirmation';

  @override
  String get studentProfileCurrentPwd => 'Mot de passe actuel';

  @override
  String get studentProfileCurrentSession => 'Maintenant · Session actuelle';

  @override
  String get studentProfileDangerZone => 'Zone dangereuse';

  @override
  String get studentProfileDeleteAccount => 'Supprimer mon compte';

  @override
  String get studentProfileDeleteBody =>
      'Cette action est irréversible. Toutes vos données seront perdues.';

  @override
  String get studentProfileDeleteTitle => 'Supprimer le compte ?';

  @override
  String get studentProfileDeleteWarning =>
      'La suppression de votre compte est irréversible.';

  @override
  String get studentProfileEmailAddress => 'Adresse e-mail';

  @override
  String get studentProfileEmailChanged => 'Adresse email modifiée.';

  @override
  String studentProfileEmailCurrent(Object email) {
    return 'Actuelle : $email';
  }

  @override
  String get studentProfileEmailInvalid => 'Adresse email invalide.';

  @override
  String get studentProfileEmailSame => 'C\'est déjà votre adresse actuelle.';

  @override
  String get studentProfileEnterCode => 'Saisis le code reçu par email.';

  @override
  String get studentProfileFullName => 'Nom complet';

  @override
  String get studentProfileGetCode => 'Recevoir un code';

  @override
  String get studentProfileLearningStyle => 'Mon style d’apprentissage';

  @override
  String get studentProfileManageSub => 'Gérer mon abonnement';

  @override
  String get studentProfileNewEmail => 'Nouvel email';

  @override
  String get studentProfileNewEmailAddress => 'Nouvelle adresse e-mail';

  @override
  String get studentProfileNotifAi => 'Recommandations WinAI';

  @override
  String get studentProfileNotifAiSub => 'Alertes et conseils personnalisés';

  @override
  String get studentProfileNotifCommunitySub => 'Réponses à vos questions';

  @override
  String get studentProfileNotifExam => 'Rappels d\'examens';

  @override
  String get studentProfileNotifExamSub => 'Compte à rebours avant vos examens';

  @override
  String get studentProfileNotifPromo => 'Offres et promotions';

  @override
  String get studentProfileNotifPromoSub => 'Nouveaux contenus, promotions';

  @override
  String get studentProfileNotifQuiz => 'Résultats de quiz';

  @override
  String get studentProfileNotifQuizSub =>
      'Recevoir vos scores après chaque quiz';

  @override
  String studentProfilePeriodEnd(Object date) {
    return 'Fin de période le $date';
  }

  @override
  String get studentProfilePhone => 'Téléphone';

  @override
  String get studentProfilePwdChanged => 'Mot de passe modifié.';

  @override
  String get studentProfilePwdMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get studentProfilePwdWrong => 'Mot de passe actuel incorrect.';

  @override
  String get studentProfileSaveChanges => 'Enregistrer les modifications';

  @override
  String get studentProfileTabPrivacy => 'Confidentialité';

  @override
  String get studentProfileTabSecurity => 'Sécurité';

  @override
  String get studentProfileTitle => 'Profil';

  @override
  String get studentProfileUpdateError => 'Erreur lors de la mise à jour.';

  @override
  String get studentProfileUpdated => 'Profil mis à jour.';

  @override
  String get studentProfileVisible => 'Profil visible';

  @override
  String get studentProfileVisibleHint => 'Visible par la communauté WinPlus.';

  @override
  String get studentQuizAvailable => 'Quiz disponibles';

  @override
  String get studentQuizBackToCatalog => 'Retour au catalogue';

  @override
  String get studentQuizCorrect => 'Correctes';

  @override
  String studentQuizCounter(Object current, Object total) {
    return 'Question $current sur $total';
  }

  @override
  String get studentQuizExcellent => 'Excellent !';

  @override
  String get studentQuizFinish => 'Terminer le quiz';

  @override
  String get studentQuizGoodWork => 'Bon travail';

  @override
  String get studentQuizIncorrect => 'Incorrectes';

  @override
  String studentQuizMeta(Object count, Object minutes) {
    return '$count questions · $minutes min';
  }

  @override
  String get studentQuizMyQuizzes => 'Mes Quiz';

  @override
  String get studentQuizNone => 'Aucun quiz disponible.';

  @override
  String get studentQuizNow => 'Maintenant';

  @override
  String get studentQuizResults => 'Résultats';

  @override
  String get studentQuizRetake => 'Refaire le quiz';

  @override
  String get studentQuizReview => 'Révision';

  @override
  String get studentQuizReviewAnswers => 'Revoir les réponses';

  @override
  String get studentQuizToImprove => 'À améliorer';

  @override
  String get studentReportsAvgScore => 'Score moyen';

  @override
  String get studentReportsBestSubject => 'Meilleure matière : Maths';

  @override
  String get studentReportsBySubject => 'Score par matière';

  @override
  String get studentReportsExportPdf => 'Exporter PDF';

  @override
  String get studentReportsPeriod30 => '30 jours';

  @override
  String get studentReportsPeriod7 => '7 jours';

  @override
  String get studentReportsPeriod90 => '90 jours';

  @override
  String get studentReportsPlanRequired =>
      'Plan Standard requis pour cette période';

  @override
  String get studentReportsQuiz => 'Quiz';

  @override
  String get studentReportsQuizDone => 'Quiz réalisés';

  @override
  String get studentReportsStandardOnly => 'Disponible avec le Plan Standard';

  @override
  String get studentReportsSuccessRate => 'Taux de réussite';

  @override
  String get studentReportsTitle => 'Mes rapports';

  @override
  String get studentReportsToImprove => 'À améliorer : Chimie';

  @override
  String studentReportsWeekShort(Object n) {
    return 'S$n';
  }

  @override
  String get studentReportsWeekly => 'Progression hebdomadaire';

  @override
  String get studentRevisionAll => 'Toutes';

  @override
  String get studentRevisionBackToCatalog => 'Revoir le catalogue';

  @override
  String studentRevisionDaysAgo(Object n) {
    return 'il y a ${n}j';
  }

  @override
  String get studentRevisionEmpty =>
      'Aucune question à réviser !\nTu maîtrises tout.';

  @override
  String studentRevisionHoursAgo(Object n) {
    return 'il y a ${n}h';
  }

  @override
  String get studentRevisionLoadError => 'Impossible de charger tes erreurs.';

  @override
  String studentRevisionMinutesAgo(Object n) {
    return 'il y a ${n}min';
  }

  @override
  String get studentRevisionSubtitle => 'Questions que tu as ratées récemment';

  @override
  String get studentRevisionYesterday => 'hier';

  @override
  String get studentSearchHint => 'BAC C Maths, ENSP, SVT…';

  @override
  String get studentSearchIdle => 'Recherchez dans le catalogue';

  @override
  String studentSearchNoResults(Object query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get studentSessionDone => 'Session terminée !';

  @override
  String studentSessionDoneScore(Object pct, Object subject) {
    return 'Score : $pct% sur $subject';
  }

  @override
  String get studentSessionFinish => 'Terminer la session';

  @override
  String get studentSessionHistory => 'Voir mes sessions passées';

  @override
  String studentSessionHistoryLine(Object duration, Object score, Object date) {
    return '$duration min · $score · $date';
  }

  @override
  String get studentSessionIntro =>
      'Choisis une matière et une durée. WinAI prépare un briefing, un quiz progressif puis une synthèse personnalisée.';

  @override
  String studentSessionMinutes(Object d) {
    return '$d min';
  }

  @override
  String get studentSessionNextQuestion => 'Question suivante';

  @override
  String get studentSessionNoHistory =>
      'Aucune session terminée pour le moment.';

  @override
  String get studentSessionNoScore => 'sans score';

  @override
  String get studentSessionNoSubjects =>
      'Aucune matière disponible pour le moment.';

  @override
  String get studentSessionPickSubject => 'Choisis une matière pour commencer.';

  @override
  String get studentSessionQuizError =>
      'Impossible de générer le quiz. Réessaie dans un instant.';

  @override
  String studentSessionScoreLine(Object correct, Object total, Object pct) {
    return '$correct/$total correctes · $pct%';
  }

  @override
  String get studentSessionSeeSummary => 'Voir la synthèse';

  @override
  String get studentSessionStart => 'Démarrer la session';

  @override
  String get studentSessionStartError =>
      'Impossible de démarrer la session. Réessaie.';

  @override
  String get studentSessionStepBriefing => 'Briefing';

  @override
  String get studentSessionStepQuiz => 'Quiz progressif';

  @override
  String get studentSessionStepSummary => 'Synthèse WinAI';

  @override
  String get studentSessionSummaryError =>
      'La synthèse n\'a pas pu être générée, mais tes réponses sont bien conservées.';

  @override
  String studentTabsAiFileAttached(Object name) {
    return 'Fichier joint : $name';
  }

  @override
  String get studentTabsAiFileReceived => 'Fichier reçu ! Je l\'analyse...';

  @override
  String get studentTabsAiHint => 'Pose ta question à WinAI…';

  @override
  String get studentTabsAiNoReply =>
      'Désolé, je n\'ai pas pu répondre. Réessaie.';

  @override
  String get studentTabsAiSuggest1 => 'Explique-moi les dérivées';

  @override
  String get studentTabsAiSuggest2 => 'Plan de révision BAC C';

  @override
  String get studentTabsAiSuggest3 => 'Mes matières faibles ?';

  @override
  String get studentTabsAiSuggest4 => 'Génère un quiz Chimie';

  @override
  String get studentTabsAiTagline => 'Ton assistant pédagogique personnel';

  @override
  String get studentTabsAttachDocument => 'Document (PDF, Word…)';

  @override
  String get studentTabsAttachFile => 'Joindre un fichier';

  @override
  String get studentTabsAttachImage => 'Image / Photo';

  @override
  String get studentTabsAttachVoice => 'Message vocal';

  @override
  String get studentTabsAttachment => 'Pièce jointe';

  @override
  String get studentTabsCatalogLoadError =>
      'Impossible de charger le catalogue.';

  @override
  String get studentTabsCertificates => 'Certificats';

  @override
  String get studentTabsCourseCatalog => 'Catalogue formations';

  @override
  String get studentTabsExamCoach => 'Coach Exam';

  @override
  String get studentTabsFavorites => 'Favoris';

  @override
  String get studentTabsFindTutor => 'Trouver un tuteur';

  @override
  String get studentTabsFindTutorSub =>
      'Cours particuliers en ligne ou à domicile';

  @override
  String get studentTabsGuidedSession => 'Session d\'étude guidée';

  @override
  String get studentTabsMyBookings => 'Mes réservations';

  @override
  String get studentTabsMyCart => 'Mon panier';

  @override
  String get studentTabsMyOrders => 'Mes commandes';

  @override
  String get studentTabsNoContent => 'Aucun contenu disponible.';

  @override
  String get studentTabsSearchHint => 'BAC C Maths 2023…';

  @override
  String get studentTabsStructuredCourses => 'Formations structurées';

  @override
  String get studentTabsStructuredCoursesSub =>
      'Apprenez à votre rythme · Certificats inclus';

  @override
  String get studentTabsStudyThisWeek => 'Étude cette semaine';

  @override
  String get studentTabsTypeBooks => 'Livres';

  @override
  String get studentTabsTypeCorrections => 'Corrections';

  @override
  String get studentTabsTypePacks => 'Packs';

  @override
  String get studentTabsTypePapers => 'Épreuves';

  @override
  String get studentTabsVoiceSoon =>
      'Enregistrement vocal disponible prochainement';

  @override
  String get studentVarkApplied => 'Style appliqué !';

  @override
  String get studentVarkApply => 'Appliquer mon style';

  @override
  String get studentVarkApplying => 'Application…';

  @override
  String get studentVarkAuditory => 'Apprenant Auditif';

  @override
  String get studentVarkKinesthetic => 'Apprenant Kinesthésique';

  @override
  String get studentVarkMixed => 'Profil Mixte';

  @override
  String get studentVarkQ1 =>
      'Quand tu apprends quelque chose de nouveau, tu préfères…';

  @override
  String get studentVarkQ1A => 'Écouter une explication orale';

  @override
  String get studentVarkQ1K => 'Essayer directement par la pratique';

  @override
  String get studentVarkQ1R => 'Lire un cours écrit détaillé';

  @override
  String get studentVarkQ1V => 'Dessiner un schéma ou voir un diagramme';

  @override
  String get studentVarkQ2 => 'Pour mémoriser une formule de mathématiques…';

  @override
  String get studentVarkQ2A => 'La répéter à voix haute plusieurs fois';

  @override
  String get studentVarkQ2K => 'Résoudre des exercices jusqu\'à l\'automatisme';

  @override
  String get studentVarkQ2R => 'L\'écrire et la réécrire dans tes notes';

  @override
  String get studentVarkQ2V => 'La visualiser telle qu\'elle est écrite';

  @override
  String get studentVarkQ3 => 'Quand tu bloques sur un exercice difficile…';

  @override
  String get studentVarkQ3A =>
      'En parler à quelqu\'un pour l\'expliquer oralement';

  @override
  String get studentVarkQ3K => 'Recommencer l\'exercice en variant les étapes';

  @override
  String get studentVarkQ3R => 'Relire tes notes depuis le début';

  @override
  String get studentVarkQ3V => 'Chercher un exemple illustré';

  @override
  String get studentVarkQ4 => 'En classe, tu retiens mieux quand…';

  @override
  String get studentVarkQ4A => 'Le prof explique avec des exemples parlés';

  @override
  String get studentVarkQ4K =>
      'Il y a des exercices pratiques pendant le cours';

  @override
  String get studentVarkQ4R => 'Tu as un cours bien structuré à lire';

  @override
  String get studentVarkQ4V =>
      'Le prof dessine au tableau ou montre des slides';

  @override
  String get studentVarkQ5 => 'Ta méthode de révision favorite…';

  @override
  String get studentVarkQ5A =>
      'M\'enregistrer en train de réciter à voix haute';

  @override
  String get studentVarkQ5K => 'Enchaîner des exercices et annales corrigées';

  @override
  String get studentVarkQ5R => 'Rédiger des résumés écrits condensés';

  @override
  String get studentVarkQ5V => 'Créer des fiches avec schémas et couleurs';

  @override
  String get studentVarkQ6 =>
      'Comment tu sais que tu as vraiment compris quelque chose ?';

  @override
  String get studentVarkQ6A =>
      'L\'expliquer clairement à voix haute à quelqu\'un';

  @override
  String get studentVarkQ6K => 'Résoudre des exercices variés sans aide';

  @override
  String get studentVarkQ6R => 'Rédiger un résumé complet de mémoire';

  @override
  String get studentVarkQ6V =>
      'Le représenter graphiquement sans regarder tes notes';

  @override
  String studentVarkQuestionCount(Object n, Object total) {
    return 'Question $n / $total';
  }

  @override
  String get studentVarkReadWrite => 'Lecteur / Scripteur';

  @override
  String get studentVarkSaved =>
      'Ce résultat est enregistré sur ton profil : WinAI et les contenus générés s’y adaptent, sur le web comme sur mobile.';

  @override
  String get studentVarkTitle => 'Mon style d\'apprentissage';

  @override
  String get studentVarkVisual => 'Apprenant Visuel';

  @override
  String get studentViewerAddToCart => 'Ajouter au panier';

  @override
  String studentViewerCorrectionTitle(Object title) {
    return 'Corrigé · $title';
  }

  @override
  String get studentViewerLoadFailed =>
      'Impossible de charger le document pour le moment.';

  @override
  String get studentViewerNoAccess =>
      'Ce contenu n\'est pas inclus dans votre accès. Achetez-le ou abonnez-vous pour le consulter.';

  @override
  String get studentViewerNoConnection =>
      'Connexion impossible. Vérifiez votre réseau puis réessayez.';

  @override
  String get studentViewerNoCorrection =>
      'Le corrigé de cette épreuve n\'est pas encore disponible.';

  @override
  String get studentViewerNoDocument =>
      'Ce document n\'est pas disponible pour le moment.';

  @override
  String studentViewerPreviewFirst(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: 'Aperçu : $pages premières pages',
      one: 'Aperçu : $pages première page',
      zero: 'Aperçu : $pages première page',
    );
    return '$_temp0';
  }

  @override
  String studentViewerPreviewOf(int pages, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: 'Aperçu : $pages pages sur $total',
      one: 'Aperçu : $pages page sur $total',
      zero: 'Aperçu : $pages page sur $total',
    );
    return '$_temp0';
  }

  @override
  String get studentViewerReadOnly =>
      'Lecture seule : ni téléchargement, ni partage, ni impression';

  @override
  String get studentViewerSessionExpired =>
      'Votre session a expiré. Reconnectez-vous pour consulter ce document.';

  @override
  String get studentViewerSubscriptions => 'Abonnements';

  @override
  String get studentViewerUnlockRest =>
      'La suite se débloque avec l\'achat de ce contenu ou un abonnement qui inclut le catalogue.';

  @override
  String get subActivate => 'Activer';

  @override
  String get subActivated => 'Abonnement activé.';

  @override
  String get subAutoRenew => 'Renouveler avec mon solde à l\'échéance';

  @override
  String get subAutoRenewHint =>
      '3 jours de grâce si le solde manque · résiliable à tout moment';

  @override
  String get subBadgeCurrent => 'ACTUEL';

  @override
  String get subBadgePopular => 'POPULAIRE';

  @override
  String get subChoosePlan => 'Choisir ce plan';

  @override
  String get subComputingPrice => 'Calcul du prix…';

  @override
  String subDiscount(Object code) {
    return 'Remise $code';
  }

  @override
  String get subDueNow => 'À payer maintenant';

  @override
  String get subEnterMomoNumber =>
      'Saisissez un numéro Mobile Money (9 chiffres).';

  @override
  String subFeatureAvailableFrom(Object feature, Object plan) {
    return '$feature est disponible à partir du plan $plan.';
  }

  @override
  String subFeatureOfPlan(Object plan) {
    return 'Fonctionnalité $plan';
  }

  @override
  String get subFinalizeFailed => 'Impossible de finaliser. Réessayez.';

  @override
  String get subFooterTtc =>
      'Prix TTC · accès jusqu\'à la fin de la période payée en cas de résiliation';

  @override
  String subFromPerMonth(Object amount) {
    return 'À partir de $amount XAF TTC/mois';
  }

  @override
  String get subInstitutionLicenseNote =>
      'Les établissements passent par une licence (sièges élèves, année scolaire) : gérez-la depuis l\'onglet Licence de votre espace établissement.';

  @override
  String get subLater => 'Plus tard';

  @override
  String get subLoadError => 'Erreur de chargement';

  @override
  String get subMyBalance => 'Mon solde';

  @override
  String get subNotOffered => 'Non proposé sur cette période';

  @override
  String get subOurPlans => 'Nos plans';

  @override
  String get subPaymentInitiated =>
      'Paiement initié : confirmez-le sur votre téléphone. Votre abonnement s\'active à la confirmation.';

  @override
  String subPerUnitTtc(Object unit) {
    return ' XAF TTC / $unit';
  }

  @override
  String get subPeriodMonthly => 'Mensuel';

  @override
  String get subPeriodQuarterly => 'Trimestriel';

  @override
  String subPeriodTtc(Object period) {
    return '$period · prix TTC';
  }

  @override
  String get subPeriodYearly => 'Annuel';

  @override
  String get subPleaseWait => 'Patientez…';

  @override
  String get subPricingFootnote =>
      'Prix TTC · MTN Mobile Money, Orange Money ou solde WinPlus · résiliable à tout moment, accès jusqu\'à la fin de la période payée';

  @override
  String get subQuoteUnavailable => 'Devis indisponible.';

  @override
  String get subRenewOrChange => 'Renouveler ou changer de période';

  @override
  String get subScheduleChange => 'Programmer le changement';

  @override
  String get subSeePlans => 'Voir les plans';

  @override
  String get subStartTrial => 'Commencer l\'essai gratuit';

  @override
  String get subUnitMonth => 'mois';

  @override
  String get subUnitQuarter => 'trimestre';

  @override
  String get subUnitYear => 'an';

  @override
  String get subUnusedPeriod => 'Période en cours non utilisée';

  @override
  String get svcAssignmentActive => 'Active';

  @override
  String get svcAssignmentEnded => 'Terminée';

  @override
  String get svcBalancePaymentFailed =>
      'Le paiement par solde a échoué. Réessaie.';

  @override
  String svcBookedForOthers(Object names, Object payer) {
    return 'Pour : $names · payée par $payer.';
  }

  @override
  String svcBookedForYou(Object payer, Object group, Object count) {
    return 'Réservée pour toi par $payer$group$count.';
  }

  @override
  String get svcCancelFailed => 'Annulation impossible.';

  @override
  String get svcCartAddCourseFailed =>
      'Impossible d\'ajouter la formation au panier.';

  @override
  String svcDurationHours(Object h) {
    return '$h h';
  }

  @override
  String svcDurationHoursMin(Object h, Object m) {
    return '$h h $m';
  }

  @override
  String svcDurationMin(Object m) {
    return '$m min';
  }

  @override
  String get svcEndorseFailed => 'Caution impossible.';

  @override
  String get svcEngStatusActive => 'En cours';

  @override
  String get svcEngStatusCancelled => 'Annulé';

  @override
  String get svcEngStatusCompleted => 'Terminé';

  @override
  String get svcEngStatusExpired => 'Expiré (sans réponse)';

  @override
  String get svcEngStatusRejected => 'Refusé par le tuteur';

  @override
  String get svcGenericError => 'Une erreur est survenue. Réessaie.';

  @override
  String get svcIdDocCni => 'Carte nationale d\'identité';

  @override
  String get svcIdDocDrivingLicense => 'Permis de conduire';

  @override
  String get svcIdDocOther => 'Autre pièce officielle';

  @override
  String get svcIdDocPassport => 'Passeport';

  @override
  String get svcIdDocResidencePermit => 'Titre de séjour';

  @override
  String get svcInterviewCancelled => 'Annulé';

  @override
  String get svcInterviewFailed => 'Non concluant';

  @override
  String get svcInterviewNoShow => 'Absent';

  @override
  String get svcInterviewPassed => 'Réussi';

  @override
  String get svcInterviewRequested => 'Demandé';

  @override
  String get svcInterviewScheduled => 'Planifié';

  @override
  String get svcInvalidCode => 'Code invalide';

  @override
  String get svcInvalidPromo => 'Code promo invalide.';

  @override
  String get svcLoginFailed => 'Connexion impossible';

  @override
  String get svcMaterialDraft => 'Support en brouillon';

  @override
  String get svcMaterialShared => 'Support partagé';

  @override
  String get svcMaterialSharedWithChanges => 'Support modifié, non repartagé';

  @override
  String get svcMoneyPartial => 'Remboursé en partie';

  @override
  String get svcMoneyUnpaid => 'Non payé';

  @override
  String get svcOfflineAction =>
      'Cette action nécessite une connexion internet.';

  @override
  String get svcOfflineFileMissing =>
      'Fichier hors-ligne introuvable (a-t-il été effacé par le système ?).';

  @override
  String get svcOfflineNotSaved => 'Cette leçon n\'a pas été téléchargée.';

  @override
  String get svcOfflinePlayNoAccount =>
      'Lecture hors-ligne impossible : aucun compte connecté.';

  @override
  String get svcOfflineSaveNoAccount =>
      'Téléchargement hors-ligne impossible : aucun compte connecté.';

  @override
  String get svcOrderCreateFailed => 'Impossible de créer la commande.';

  @override
  String svcPartyCount(Object n) {
    return ' · $n élèves';
  }

  @override
  String svcPartyGroup(Object name) {
    return ' (groupe $name)';
  }

  @override
  String get svcPayerInstitution => 'Institution';

  @override
  String get svcPayerStudyGroup => 'Groupe d\'étude';

  @override
  String get svcPaymentInitFailed => 'Impossible d\'initier le paiement.';

  @override
  String get svcPurchaseNotCompleted => 'L\'achat n\'a pas pu être finalisé.';

  @override
  String svcRefundFeeDeducted(Object fee) {
    return 'frais Mobile Money de $fee XAF déduits';
  }

  @override
  String svcRefundFeesExceed(Object fee) {
    return 'Aucun remboursement : les frais Mobile Money ($fee XAF) dépassent la part remboursable.';
  }

  @override
  String get svcRefundFull => ' (remboursement intégral)';

  @override
  String get svcRefundInstitutionWallet => 'le portefeuille de l\'institution';

  @override
  String get svcRefundMyWallet => 'ton portefeuille WinPlus';

  @override
  String svcRefundPartial(Object percent, Object fee) {
    return ' ($percent % selon la politique du tuteur$fee)';
  }

  @override
  String get svcRefundTooLate =>
      'Aucun remboursement : annulation trop tardive selon la politique du tuteur.';

  @override
  String get svcRefundWhoPaid => 'celui qui a payé';

  @override
  String svcRefundedOn(Object amount, Object target, Object detail) {
    return '$amount XAF remboursés sur $target$detail.';
  }

  @override
  String svcRefundedTo(Object amount, Object name, Object detail) {
    return '$amount XAF remboursés à $name$detail.';
  }

  @override
  String get svcReplySendFailed => 'Impossible d\'envoyer la réponse.';

  @override
  String get svcReportFailed => 'Signalement impossible.';

  @override
  String get svcReportHarassment => 'Harcèlement ou propos déplacés';

  @override
  String get svcReportIdentity => 'Ce n\'est pas la personne du profil';

  @override
  String get svcReportInappropriate => 'Comportement inapproprié';

  @override
  String get svcReportNoShow => 'Absent à la séance';

  @override
  String get svcReportOffPlatform => 'Demande de paiement hors WinPlus';

  @override
  String get svcReportPoorQuality => 'Séance de mauvaise qualité';

  @override
  String get svcReportSafety => 'Problème de sécurité';

  @override
  String get svcRequestFailed => 'Demande impossible.';

  @override
  String get svcReviewSendFailed => 'Impossible d\'envoyer l\'avis.';

  @override
  String get svcSendFailed => 'Envoi impossible.';

  @override
  String get svcSessionStatusConfirmed => 'Prévue';

  @override
  String get svcSignupFailed => 'Inscription impossible';

  @override
  String svcStudentFallback(Object id) {
    return 'Élève #$id';
  }

  @override
  String get svcTopUpDone => 'Recharge effectuée.';

  @override
  String get svcTutorsLoadFailed => 'Impossible de charger vos répétiteurs.';

  @override
  String get svcVerifEventIdentityApproved => 'Pièce d\'identité validée';

  @override
  String get svcVerifEventIdentityFilesPurged =>
      'Fichiers supprimés (conservation limitée)';

  @override
  String get svcVerifEventIdentityRejected => 'Pièce d\'identité refusée';

  @override
  String get svcVerifEventIdentitySubmitted => 'Pièce d\'identité déposée';

  @override
  String get svcVerifEventIdentitySuperseded => 'Dépôt remplacé';

  @override
  String get svcVerifEventInstitutionEndorsed => 'Caution d\'une institution';

  @override
  String get svcVerifEventInstitutionRevoked => 'Caution retirée';

  @override
  String get svcVerifEventInterviewCancelled => 'Entretien annulé';

  @override
  String get svcVerifEventInterviewFailed => 'Entretien non concluant';

  @override
  String get svcVerifEventInterviewNoShow => 'Absent à l\'entretien';

  @override
  String get svcVerifEventInterviewPassed => 'Entretien réussi';

  @override
  String get svcVerifEventInterviewRequested => 'Entretien demandé';

  @override
  String get svcVerifEventInterviewScheduled => 'Entretien planifié';

  @override
  String get svcVerifEventStatusUnverified => 'Vérification retirée';

  @override
  String get svcVerifEventSuspensionLifted => 'Suspension levée';

  @override
  String get svcVerifLoadFailed => 'Impossible de charger ta vérification.';

  @override
  String get svcVerifRouteInstitution => 'Caution d\'une institution';

  @override
  String get svcVerifRouteInterview => 'Entretien';

  @override
  String get svcWinaiLimit =>
      'Vous avez atteint votre limite WinAI. Passez à un plan supérieur pour continuer.';

  @override
  String get svcWinaiUnavailable =>
      'WinAI est momentanément indisponible. Réessayez dans quelques minutes.';

  @override
  String get svcWithdrawFailed => 'Retrait impossible.';

  @override
  String switchToLanguage(String lang) {
    return 'Passer en $lang';
  }

  @override
  String get teacherAiInputHint => 'Génère un quiz, une fiche, une correction…';

  @override
  String get teacherAiSuggestCorrection => 'Correction type';

  @override
  String get teacherAiSuggestQuiz => 'Quiz Terminale C (10 QCM)';

  @override
  String get teacherAiSuggestSheet => 'Fiche de cours';

  @override
  String get teacherAiSuggestTitle => 'Optimiser un titre';

  @override
  String get teacherAiTagline => 'Ton assistant éditorial & pédagogique';

  @override
  String get teacherBookingAcceptError =>
      'Impossible d\'accepter cette demande.';

  @override
  String get teacherBookingAcceptMonth => 'Accepter le mois';

  @override
  String get teacherBookingAssignments => 'Attributions';

  @override
  String get teacherBookingAutoMaterial =>
      'Support WinAI généré à l\'acceptation';

  @override
  String get teacherBookingAutoMaterialHint =>
      'Décompté de ton usage WinAI ; tu le relis avant de le partager.';

  @override
  String teacherBookingBeneficiaries(Object count) {
    return '$count élève(s) :';
  }

  @override
  String get teacherBookingCompleteError =>
      'Impossible de clôturer cette séance.';

  @override
  String get teacherBookingConfirmedEmpty =>
      'Aucune séance confirmée pour le moment.';

  @override
  String get teacherBookingDeclineEngagementMessage =>
      'Le payeur est remboursé intégralement, séance par séance ; si le mois a été payé par Mobile Money, les frais sont retenus sur ton solde.';

  @override
  String get teacherBookingDeclineEngagementTitle =>
      'Refuser l\'engagement entier';

  @override
  String get teacherBookingDeclineError =>
      'Impossible de refuser cette demande.';

  @override
  String get teacherBookingDeclineMessage =>
      'Celui qui a payé (élève, parent, institution ou membre du groupe) sera remboursé intégralement sur son portefeuille WinPlus ; si la séance a été payée par Mobile Money, les frais de l\'opérateur seront retenus sur ton solde.';

  @override
  String get teacherBookingDeclineTitle => 'Refuser la demande';

  @override
  String get teacherBookingDeclined =>
      'Demande refusée : le payeur est remboursé sur son portefeuille.';

  @override
  String teacherBookingDeclinedFee(Object amount) {
    return 'Demande refusée : le payeur est remboursé, $amount XAF de frais Mobile Money retenus sur ton solde.';
  }

  @override
  String get teacherBookingDetail => 'Détail';

  @override
  String teacherBookingDiscount(Object percent) {
    return '(remise $percent %)';
  }

  @override
  String teacherBookingDisputeReason(Object reason) {
    return 'Motif de contestation : $reason';
  }

  @override
  String get teacherBookingEngagementAccepted =>
      'Engagement accepté : toutes les séances du mois sont confirmées.';

  @override
  String get teacherBookingEngagementRequests =>
      'Demandes d\'engagement mensuel';

  @override
  String get teacherBookingExpiresSoon => 'Expire bientôt';

  @override
  String teacherBookingGroupSession(Object count) {
    return 'Séance de groupe · $count élèves';
  }

  @override
  String get teacherBookingHidePrice => 'Masquer le détail du prix';

  @override
  String get teacherBookingMarkCompleted => 'Marquer effectuée';

  @override
  String teacherBookingMinutes(Object count) {
    return '$count min';
  }

  @override
  String teacherBookingMinutesToAnswer(Object count) {
    return '$count min pour répondre';
  }

  @override
  String get teacherBookingModeStudentHome => 'À domicile (élève)';

  @override
  String teacherBookingPaidBy(Object payer) {
    return 'Payée par : $payer';
  }

  @override
  String teacherBookingPaidInAdvance(Object amount) {
    return '$amount XAF payés d\'avance';
  }

  @override
  String get teacherBookingPaidPerSession => 'versés séance par séance';

  @override
  String teacherBookingParticipants(Object who, Object names) {
    return '$who : $names';
  }

  @override
  String get teacherBookingPendingEmpty =>
      'Aucune demande en attente pour le moment.';

  @override
  String get teacherBookingPendingTitle => 'Demandes en attente';

  @override
  String get teacherBookingPrepareMaterial => 'Préparer le support avec WinAI';

  @override
  String teacherBookingQuote(Object note) {
    return '« $note »';
  }

  @override
  String get teacherBookingReasonHint => 'Motif (optionnel)';

  @override
  String teacherBookingSessionsCount(Object count) {
    return '$count séances';
  }

  @override
  String get teacherBookingSettingError => 'Réglage impossible.';

  @override
  String get teacherBookingShowPrice => 'Voir le détail du prix';

  @override
  String get teacherBookingTheStudent => 'l\'élève';

  @override
  String get teacherBookingTopics => 'Sujets à travailler';

  @override
  String get teacherBookingUpcomingTitle => 'Séances à venir / à clôturer';

  @override
  String get teacherBookingViaAssignment => 'via une attribution';

  @override
  String get teacherClassAdd => 'Ajouter';

  @override
  String get teacherClassAddStudent => 'Ajouter un élève';

  @override
  String get teacherClassAddStudentError =>
      'Cet élève n\'a pas pu être ajouté.';

  @override
  String get teacherClassAddStudentErrorDetail =>
      'Cet élève n\'a pas pu être ajouté (email inconnu ou déjà membre).';

  @override
  String get teacherClassAssignmentCreateError =>
      'Le devoir n\'a pas pu être créé.';

  @override
  String get teacherClassAssignmentCreated =>
      'Devoir créé. Les élèves sont notifiés.';

  @override
  String get teacherClassAssignmentTitle => 'Titre du devoir';

  @override
  String get teacherClassAssignmentTitleHint => 'Ex. Devoir maison n°3';

  @override
  String get teacherClassAssignmentsLoadError =>
      'Les devoirs n\'ont pas pu être chargés.';

  @override
  String get teacherClassAssignmentsTab => 'Devoirs';

  @override
  String teacherClassCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies',
      one: '$count copie',
    );
    return '$_temp0';
  }

  @override
  String get teacherClassCreateAssignment => 'Créer le devoir';

  @override
  String get teacherClassNewAssignment => 'Nouveau devoir';

  @override
  String get teacherClassNoAssignments => 'Aucun devoir pour l\'instant';

  @override
  String get teacherClassNoStudents => 'Aucun élève dans cette classe';

  @override
  String get teacherClassNoStudentsHint =>
      'Ajoute un élève par son email WinPlus.';

  @override
  String get teacherClassReferenceHint => 'Ton propre corrigé…';

  @override
  String get teacherClassReferenceLabel => 'Corrigé de référence (facultatif)';

  @override
  String get teacherClassRemove => 'Retirer';

  @override
  String get teacherClassRemoveFromClass => 'Retirer de la classe';

  @override
  String teacherClassRemoveStudentBody(Object name, Object className) {
    return '$name sera retiré(e) de « $className ».';
  }

  @override
  String get teacherClassRemoveStudentError =>
      'Cet élève n\'a pas pu être retiré.';

  @override
  String get teacherClassRemoveStudentTitle => 'Retirer cet élève ?';

  @override
  String get teacherClassStatementHint => 'Colle l\'énoncé…';

  @override
  String get teacherClassStatementLabel => 'Énoncé (génère le barème WinAI)';

  @override
  String get teacherClassStudentAdded => 'Élève ajouté.';

  @override
  String get teacherClassStudentEmailHint => 'eleve@exemple.cm';

  @override
  String get teacherClassStudentEmailLabel => 'Email WinPlus de l\'élève';

  @override
  String get teacherClassStudentsLoadError =>
      'Les élèves n\'ont pas pu être chargés.';

  @override
  String teacherClassToMark(Object count) {
    return '$count à corriger';
  }

  @override
  String get teacherClassesActionFailed => 'Cette action a échoué.';

  @override
  String teacherClassesAverage(Object avg) {
    return '$avg% moy.';
  }

  @override
  String get teacherClassesCreate => 'Créer une classe';

  @override
  String get teacherClassesCreateError =>
      'Cette classe n\'a pas pu être créée (nom déjà utilisé ?).';

  @override
  String teacherClassesCreated(Object name) {
    return 'Classe « $name » créée.';
  }

  @override
  String teacherClassesDeactivateBody(Object name, Object count) {
    return '« $name » contient $count élève(s) : elle sera désactivée (pas supprimée) et retirée de la liste.';
  }

  @override
  String get teacherClassesDeactivateTitle => 'Désactiver la classe ?';

  @override
  String teacherClassesDeleteBody(Object name) {
    return 'Supprimer définitivement « $name » ?';
  }

  @override
  String get teacherClassesDeleteTitle => 'Supprimer la classe ?';

  @override
  String get teacherClassesHideInactive => 'Masquer désactivées';

  @override
  String get teacherClassesInactive => 'Désactivée';

  @override
  String get teacherClassesLevelHint => 'Ex: Terminale';

  @override
  String get teacherClassesLoadError =>
      'Vos classes n\'ont pas pu être chargées.';

  @override
  String get teacherClassesMyBookings => 'Mes réservations élèves';

  @override
  String get teacherClassesMyLinks => 'Mes liaisons directes';

  @override
  String get teacherClassesName => 'Nom de la classe';

  @override
  String get teacherClassesNameHint => 'Ex: Terminale C Maths';

  @override
  String get teacherClassesNone => 'Aucune classe';

  @override
  String get teacherClassesNoneYet => 'Aucune classe pour le moment';

  @override
  String get teacherClassesReactivateError =>
      'Cette classe n\'a pas pu être réactivée.';

  @override
  String get teacherClassesRequired => 'Nom, niveau et année sont requis.';

  @override
  String get teacherClassesShowInactive => 'Voir désactivées';

  @override
  String teacherClassesStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count élèves',
      one: '$count élève',
    );
    return '$_temp0';
  }

  @override
  String get teacherClassesTitle => 'Mes classes';

  @override
  String get teacherClassesYear => 'Année académique';

  @override
  String get teacherClassesYearHint => 'Ex: 2026-2027';

  @override
  String get teacherContentChangeStatus => 'Changer le statut';

  @override
  String get teacherContentComingSoon => 'Bientôt disponible';

  @override
  String get teacherContentCoursesBanner =>
      'Créez et gérez vos cours structurés';

  @override
  String teacherContentDeleteBody(Object title) {
    return '« $title » sera définitivement supprimé.';
  }

  @override
  String get teacherContentDeleteTitle => 'Supprimer ?';

  @override
  String get teacherContentDownloadsShort => 'Téléch.';

  @override
  String get teacherContentEditInfo => 'Modifier les infos';

  @override
  String get teacherContentEmpty => 'Aucun contenu.';

  @override
  String get teacherContentManage => 'Gérer';

  @override
  String get teacherContentRating => 'Note';

  @override
  String get teacherContentStats => 'Statistiques';

  @override
  String get teacherContentStatusArchived => 'Archivé';

  @override
  String teacherContentStatusChanged(Object status) {
    return 'Statut changé : $status';
  }

  @override
  String get teacherContentStatusReview => 'En révision';

  @override
  String get teacherCorrectionCorrect => 'Corriger';

  @override
  String get teacherCorrectionEmpty => 'Aucune soumission';

  @override
  String get teacherCorrectionFeedbackHint =>
      'Commentaires et retours à l\'étudiant…';

  @override
  String get teacherCorrectionFilterMarked => 'Corrigé';

  @override
  String get teacherCorrectionGrade => 'Note : ';

  @override
  String teacherCorrectionPendingCount(Object count) {
    return '$count en attente';
  }

  @override
  String get teacherCorrectionQueueTitle => 'File de corrections';

  @override
  String get teacherCorrectionSend => 'Envoyer la correction';

  @override
  String get teacherCorrectionSendError => 'Erreur lors de l\'envoi.';

  @override
  String teacherCorrectionSent(Object name) {
    return 'Correction envoyée à $name.';
  }

  @override
  String teacherCorrectionSheetTitle(Object name) {
    return 'Corriger : $name';
  }

  @override
  String get teacherCorrectionView => 'Voir la correction';

  @override
  String get teacherCoursesCopyLink => 'Copier le lien';

  @override
  String teacherCoursesCreateOnWeb(Object url) {
    return 'La création et l\'édition des formations se font sur le site WinPlus, depuis votre espace enseignant, avec le même compte :\n\n$url\n\nVos formations apparaissent ensuite ici.';
  }

  @override
  String get teacherCoursesCreateTitle => 'Créer une formation';

  @override
  String teacherCoursesDeleteBody(Object title) {
    return 'Cette action est irréversible. La formation « $title » sera définitivement supprimée.';
  }

  @override
  String get teacherCoursesDeleteError =>
      'Impossible de supprimer la formation.';

  @override
  String get teacherCoursesDeleteTitle => 'Supprimer la formation ?';

  @override
  String get teacherCoursesDeleted => 'Formation supprimée.';

  @override
  String get teacherCoursesDetailError => 'Impossible de charger les détails.';

  @override
  String get teacherCoursesEmptyAll => 'Vous n\'avez pas encore de formation.';

  @override
  String get teacherCoursesEmptyStatus => 'Aucune formation avec ce statut.';

  @override
  String teacherCoursesEnrolled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inscrits',
      one: '$count inscrit',
    );
    return '$_temp0';
  }

  @override
  String teacherCoursesEnrolledMany(Object count) {
    return '$count inscrits';
  }

  @override
  String teacherCoursesLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leçons',
      one: '$count leçon',
    );
    return '$_temp0';
  }

  @override
  String teacherCoursesLimitPending(Object count) {
    return '$count en attente de validation';
  }

  @override
  String teacherCoursesLimitPublished(Object published, Object max) {
    return 'Formations publiées : $published / $max';
  }

  @override
  String get teacherCoursesLimitReached =>
      'limite de votre plan atteinte : passez à un plan supérieur pour en publier davantage.';

  @override
  String get teacherCoursesLimitUnlimited =>
      'Votre plan permet de publier un nombre illimité de formations.';

  @override
  String get teacherCoursesLinkCopied =>
      'Lien copié : ouvrez-le dans votre navigateur.';

  @override
  String get teacherCoursesLoadError => 'Impossible de charger les formations.';

  @override
  String get teacherCoursesSubmit => 'Soumettre à validation';

  @override
  String get teacherCoursesSubmitError =>
      'La formation n\'a pas pu être soumise.';

  @override
  String get teacherCoursesSubmitted => 'Formation soumise à validation.';

  @override
  String get teacherCoursesViewDetails => 'Voir détails';

  @override
  String get teacherDashActiveStudents => 'Étudiants actifs';

  @override
  String get teacherDashAvgRating => 'Note moyenne';

  @override
  String get teacherDashAvgShort => 'note moy.';

  @override
  String get teacherDashDownloads => 'Téléchargements';

  @override
  String teacherDashDownloadsCount(Object count) {
    return '$count téléch.';
  }

  @override
  String get teacherDashLast4Weeks => '4 dernières semaines';

  @override
  String get teacherDashMonthRevenue => 'Revenus du mois';

  @override
  String get teacherDashNoContent => 'Aucun contenu publié.';

  @override
  String get teacherDashOutOf5 => 'Sur 5';

  @override
  String teacherDashPlan(Object plan) {
    return 'PLAN $plan';
  }

  @override
  String get teacherDashPublished => 'publiés';

  @override
  String get teacherDashPublishedContent => 'Contenus publiés';

  @override
  String get teacherDashRecentContent => 'Contenus récents';

  @override
  String get teacherDashShareLabel => 'Part sur vos séances : ';

  @override
  String teacherDashShareValue(Object percent) {
    return '$percent % de vos revenus';
  }

  @override
  String teacherDashThisMonth(Object amount) {
    return '$amount XAF ce mois';
  }

  @override
  String get teacherGroupApplyFlat => 'Prix fixe';

  @override
  String get teacherGroupApplyPerStudent => 'Prix par élève';

  @override
  String teacherGroupBasedOn(Object count) {
    return '(d\'après $count tuteurs)';
  }

  @override
  String get teacherGroupEstimate => '(estimation)';

  @override
  String get teacherGroupFlatExample =>
      'Ex. 150 % : une séance individuelle à 6 000 XAF coûte 9 000 XAF pour le groupe, quel que soit le nombre d\'élèves.';

  @override
  String get teacherGroupFlatLabel => 'Prix du groupe (% du prix individuel)';

  @override
  String teacherGroupFlatLine(Object percent) {
    return 'Ou prix fixe pour le groupe : $percent % du prix individuel';
  }

  @override
  String get teacherGroupIntro =>
      'Un parent, une institution ou un groupe d\'étude peut réserver pour plusieurs élèves. Une séance de groupe occupe ton créneau une seule fois.';

  @override
  String get teacherGroupMaxSizeLabel => 'Taille maximale du groupe (élèves)';

  @override
  String teacherGroupMaxSizeLine(Object count) {
    return 'Taille maximale : $count élèves';
  }

  @override
  String get teacherGroupMethodFlat => 'Prix fixe pour le groupe';

  @override
  String get teacherGroupMethodNone => 'Individuel seulement';

  @override
  String get teacherGroupMethodPerStudent => 'Prix par élève dégressif';

  @override
  String teacherGroupPerStudentLine(Object count, Object percent) {
    return 'Prix par élève, dès $count élèves : −$percent %';
  }

  @override
  String teacherGroupStudents(Object count) {
    return '$count élèves';
  }

  @override
  String get teacherGroupSubjectsFirst => 'Choisis d\'abord tes matières.';

  @override
  String get teacherGroupSuggest => 'Proposer (WinAI)';

  @override
  String get teacherGroupSuggestError =>
      'WinAI n\'a pas pu proposer de réglages de groupe pour l\'instant.';

  @override
  String get teacherGroupSuggested => 'Réglages proposés par WinAI';

  @override
  String get teacherGroupTierHint =>
      'Seul le palier le plus haut atteint s\'applique. Sans palier, chaque élève paie le prix individuel.';

  @override
  String get teacherGroupTitle => 'Séances de groupe';

  @override
  String get teacherLinksInvite => 'Inviter un élève';

  @override
  String get teacherLinksInviteSent => 'Invitation envoyée !';

  @override
  String get teacherLinksLinkedTab => 'Liés';

  @override
  String get teacherLinksNoLinked => 'Aucun élève lié';

  @override
  String get teacherLinksNoPending => 'Aucune invitation en attente';

  @override
  String get teacherLinksSearchHint => 'Nom, email ou téléphone…';

  @override
  String get teacherLinksTitle => 'Mes liaisons élèves';

  @override
  String get teacherPricingAddMod => '+ Ajouter une modulation';

  @override
  String get teacherPricingAddRate => '+ Ajouter un tarif';

  @override
  String get teacherPricingAddTier => 'Ajouter un palier';

  @override
  String get teacherPricingAddTierPlus => '+ Ajouter un palier';

  @override
  String get teacherPricingAllDay => 'Toute la journée';

  @override
  String get teacherPricingAllModes => 'Tous modes';

  @override
  String get teacherPricingBaseTitle => 'Tarif de base par matière et par mode';

  @override
  String get teacherPricingDurHint =>
      'Seul le palier le plus haut atteint s\'applique.';

  @override
  String get teacherPricingDurTitle => 'Dégressivité selon la durée';

  @override
  String get teacherPricingEnd => 'Fin';

  @override
  String get teacherPricingFrom => 'Dès ';

  @override
  String get teacherPricingGridIntro =>
      'Sans grille, ton tarif horaire s\'applique partout. Facturation au prorata des tranches de 30 min ; le prix exact est calculé par WinPlus et montré à l\'élève avant paiement.';

  @override
  String get teacherPricingGridTitle => 'Grille tarifaire (facultatif)';

  @override
  String get teacherPricingIgnore => 'Ignorer';

  @override
  String get teacherPricingInPerson => 'Présentiel';

  @override
  String get teacherPricingModExample => 'Ex. +20 % le soir, −10 % en matinée.';

  @override
  String get teacherPricingModName => 'Nom (ex. Soir)';

  @override
  String get teacherPricingModTitle => 'Modulation par créneau';

  @override
  String get teacherPricingRemoveMod => 'Supprimer cette modulation';

  @override
  String get teacherPricingRemoveRate => 'Supprimer ce tarif';

  @override
  String get teacherPricingRemoveTier => 'Supprimer ce palier';

  @override
  String get teacherPricingSubjectsFirst =>
      'Choisis d\'abord tes matières (étape 1).';

  @override
  String get teacherPricingSuggest => 'Proposer une grille (WinAI)';

  @override
  String get teacherPricingSuggestError =>
      'WinAI n\'a pas pu proposer de grille.';

  @override
  String get teacherPricingSuggested => 'Grille proposée par WinAI';

  @override
  String get teacherProfileActivate => 'Activer';

  @override
  String get teacherProfileActivateError =>
      'Complète les champs essentiels avant d\'activer ton profil.';

  @override
  String get teacherProfileActivated =>
      'Ton profil tuteur est visible dans la recherche !';

  @override
  String get teacherProfileActiveAfterSuspension =>
      'Actif après examen de la suspension';

  @override
  String get teacherProfileActiveAfterVerification =>
      'Actif après vérification';

  @override
  String get teacherProfileAddZone => 'Ajouter cette zone';

  @override
  String get teacherProfileAiSuggestion => 'Suggestion WinAI';

  @override
  String get teacherProfileAiUnavailable =>
      'WinAI indisponible pour l\'instant.';

  @override
  String get teacherProfileAtMyHome => 'À domicile chez moi';

  @override
  String get teacherProfileAtStudentHome => 'À domicile chez l\'élève';

  @override
  String get teacherProfileBackToEdit => 'Retour à l\'édition';

  @override
  String get teacherProfileBio => 'Bio courte (300 caractères max)';

  @override
  String get teacherProfileBlockedDefault =>
      'Le présentiel est réservé aux tuteurs vérifiés.';

  @override
  String get teacherProfileBookPreview => 'Réserver (aperçu  désactivé)';

  @override
  String get teacherProfileChooseCity => 'Choisir une ville…';

  @override
  String get teacherProfileCityOrDistrictHint => 'Nom de la ville / quartier';

  @override
  String get teacherProfileCompletion => 'Complétude du profil';

  @override
  String get teacherProfileDiploma =>
      'Diplôme (facultatif, badge « Diplôme vérifié », sans effet sur le présentiel)';

  @override
  String get teacherProfileDistrictHint => 'Quartier (optionnel)…';

  @override
  String teacherProfileDocStatus(Object status) {
    return 'Statut : $status';
  }

  @override
  String get teacherProfileDocUrlHint => 'URL du document uploadé';

  @override
  String get teacherProfileFullRefund =>
      'Remboursement total si annulé au moins';

  @override
  String get teacherProfileGetVerified => 'Me faire vérifier';

  @override
  String get teacherProfileHourlyRate => 'Tarif horaire (XAF)';

  @override
  String get teacherProfileHourlyRateHint => 'ex: 3000';

  @override
  String teacherProfileHours(Object count) {
    return '$count h';
  }

  @override
  String get teacherProfileHoursBefore => 'h avant';

  @override
  String get teacherProfileKeptSuspended =>
      'Tes choix présentiels restent enregistrés et redeviendront actifs à la levée de la suspension.';

  @override
  String get teacherProfileKeptUnverified =>
      'Tes choix présentiels sont enregistrés et deviendront actifs dès ta vérification.';

  @override
  String get teacherProfileLevelEnam => 'ENAM Administration';

  @override
  String get teacherProfileLevelsCovered => 'Niveaux couverts';

  @override
  String get teacherProfileLoadError =>
      'Impossible de charger ton profil tuteur.';

  @override
  String get teacherProfileMaxPerWeek => 'Séances max par semaine';

  @override
  String get teacherProfileModes => 'Modes d\'intervention';

  @override
  String get teacherProfileMonthlyDesc =>
      'Mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance ; tu es payé séance par séance.';

  @override
  String teacherProfileMonthlyDiscountHint(Object max) {
    return 'Remise mensuelle en % (0 à $max)';
  }

  @override
  String get teacherProfileMonthlyHint =>
      'Appliquée au prix de chaque séance du mois, calculé par ta grille.';

  @override
  String get teacherProfileMonthlyToggle => 'Proposer l\'engagement mensuel';

  @override
  String get teacherProfileNeutralPlace => 'Présentiel en espace neutre';

  @override
  String get teacherProfileNoRefund => 'Aucun remboursement à moins de';

  @override
  String get teacherProfileNoneF => 'Aucune';

  @override
  String get teacherProfileNoneM => 'Aucun';

  @override
  String get teacherProfileNotice => 'Délai de préavis minimum';

  @override
  String get teacherProfileOnHoliday => 'En vacances';

  @override
  String get teacherProfileOnlineViaWinplus => 'En ligne via WinPlus';

  @override
  String get teacherProfileOtherCity => 'Autre ville';

  @override
  String get teacherProfilePartialRefund => 'Ensuite, part remboursée';

  @override
  String teacherProfilePolicyBounds(Object fullMin, Object fullMax,
      Object partialMin, Object partialMax, Object noMin, Object noMax) {
    return 'Limites fixées par WinPlus : remboursement total entre $fullMin h et $fullMax h avant, part remboursée de $partialMin à $partialMax %, aucun remboursement en dessous de $noMin à $noMax h.';
  }

  @override
  String get teacherProfilePolicyIntro =>
      'Ce que l\'élève récupère s\'il annule lui-même (les frais Mobile Money restent à sa charge).';

  @override
  String get teacherProfilePreview => 'Voir mon profil comme un élève';

  @override
  String get teacherProfilePrevious => 'Précédent';

  @override
  String get teacherProfileProTitle => 'Titre professionnel';

  @override
  String get teacherProfileProTitleHint => 'ex: Prof de Maths  Terminale C/D';

  @override
  String get teacherProfileRate => 'Tarif';

  @override
  String teacherProfileRateSuggested(
      Object rate, Object low, Object high, Object explanation) {
    return '$rate XAF/h suggéré ($low-$high). $explanation';
  }

  @override
  String get teacherProfileReviewsSoon => 'Avis bientôt disponibles';

  @override
  String get teacherProfileSaveError => 'Erreur lors de l\'enregistrement.';

  @override
  String get teacherProfileSaving => 'Enregistrement…';

  @override
  String get teacherProfileSpecCatchUp => 'Rattrapage express';

  @override
  String get teacherProfileSpecContestPrep => 'Préparation concours';

  @override
  String get teacherProfileSpecHoliday => 'Cours de vacances';

  @override
  String get teacherProfileSpecSchoolSupport => 'Soutien scolaire';

  @override
  String get teacherProfileSpecialties => 'Spécialités';

  @override
  String get teacherProfileStepSaved => 'Étape enregistrée.';

  @override
  String get teacherProfileStyle => 'Style pédagogique';

  @override
  String get teacherProfileStyleInteractive => 'Interactif';

  @override
  String get teacherProfileStyleMixed => 'Mixte';

  @override
  String get teacherProfileStyleStructured => 'Structuré';

  @override
  String get teacherProfileSubjectsTaught => 'Matières enseignées';

  @override
  String get teacherProfileTitle => 'Mode Tuteur';

  @override
  String get teacherProfileTrialOffered => 'Séance d\'essai proposée';

  @override
  String get teacherProfileTrialPriceHint => 'Prix (0 = gratuite)';

  @override
  String get teacherProfileTrialToggle => 'Proposer une séance d\'essai';

  @override
  String get teacherProfileUnlimited => 'Illimité';

  @override
  String get teacherProfileUseRate => 'Utiliser ce tarif';

  @override
  String get teacherProfileVerifOpen => 'Vérifié : présentiel ouvert';

  @override
  String get teacherProfileVerifRoutes =>
      'Pièce d\'identité, entretien ou caution d\'institution';

  @override
  String get teacherProfileVerifSuspended =>
      'Présentiel suspendu en attendant un examen';

  @override
  String get teacherProfileVerification => 'Vérification pour le présentiel';

  @override
  String get teacherProfileVideo => 'Vidéo de présentation (optionnel)';

  @override
  String get teacherProfileWeeklySlots =>
      'Créneaux hebdomadaires (tap pour activer)';

  @override
  String get teacherProfileZones => 'Zones géographiques couvertes';

  @override
  String get teacherPublishAmountHint => 'Montant en XAF (ex: 500)';

  @override
  String get teacherPublishChooseFile => 'Choisir un fichier';

  @override
  String get teacherPublishDescriptionHint =>
      'Décrivez le contenu (objectifs, niveau, contenu…)';

  @override
  String get teacherPublishFileRequired => 'Veuillez choisir un fichier.';

  @override
  String get teacherPublishFreePrice => 'Prix libre';

  @override
  String get teacherPublishFreePriceHint => 'Fixez votre propre prix en XAF';

  @override
  String get teacherPublishNetworkError => 'Erreur réseau. Réessayez.';

  @override
  String get teacherPublishReviewNote =>
      'Votre contenu sera examiné avant d\'être publié (24-48h)';

  @override
  String teacherPublishSizeBytes(Object size) {
    return '$size o';
  }

  @override
  String teacherPublishSizeKb(Object size) {
    return '$size Ko';
  }

  @override
  String teacherPublishSizeMb(Object size) {
    return '$size Mo';
  }

  @override
  String get teacherPublishSubmit => 'Publier pour révision';

  @override
  String get teacherPublishSubmitFailed => 'Échec de la soumission. Réessayez.';

  @override
  String get teacherPublishSubmitted => 'Contenu soumis pour révision !';

  @override
  String get teacherPublishSubscriptionOnly => 'Abonnement uniquement';

  @override
  String get teacherPublishSubscriptionOnlyHint =>
      'Accessible à tous les abonnés';

  @override
  String get teacherPublishTitle => 'Publier un contenu';

  @override
  String get teacherPublishTitleHint => 'Ex: BAC C Mathématiques 2024';

  @override
  String get teacherPublishTitleRequired => 'Veuillez saisir un titre.';

  @override
  String get teacherPublishType => 'Type';

  @override
  String get teacherPublishTypePack => 'Pack';

  @override
  String get teacherPublishTypeSheet => 'Fiche';

  @override
  String get teacherPublishYear => 'Année';

  @override
  String get teacherPublishYearHint => 'Ex: 2024';

  @override
  String get teacherSession30Min => '30 min';

  @override
  String get teacherSession3h => '3h';

  @override
  String get teacherSessionCreateButton => 'Créer la session';

  @override
  String get teacherSessionCreateError => 'Erreur lors de la création.';

  @override
  String get teacherSessionCreateTitle => 'Créer une session';

  @override
  String get teacherSessionCreated => 'Session créée !';

  @override
  String get teacherSessionCreatedHint =>
      'Les étudiants inscrits recevront une notification.';

  @override
  String get teacherSessionDateHint => '25 août 2026 à 14h00';

  @override
  String get teacherSessionDateLabel => 'Date et heure';

  @override
  String teacherSessionDuration(Object minutes) {
    return 'Durée : $minutes minutes';
  }

  @override
  String get teacherSessionLinkLabel => 'Lien de la session (Zoom, Meet…)';

  @override
  String teacherSessionMaxStudents(Object count) {
    return 'Max étudiants : $count';
  }

  @override
  String get teacherSessionTitleHint => 'Révision Dérivées  BAC C';

  @override
  String get teacherSessionTitleLabel => 'Titre de la session *';

  @override
  String get teacherSessionsDemo1 => 'Révision Dérivées  Tle C';

  @override
  String get teacherSessionsDemo2 => 'Correction épreuve Physique';

  @override
  String get teacherSessionsPlan => 'Planifier une session';

  @override
  String get teacherSessionsSoon => '● Bientôt';

  @override
  String teacherSessionsToday(Object weekday, Object date) {
    return 'Aujourd\'hui, $weekday $date';
  }

  @override
  String get teacherSessionsViewDetails => 'Voir les détails';

  @override
  String get teacherVerifActive => 'Active';

  @override
  String get teacherVerifAttach =>
      'Joindre ma pièce et mon selfie à l\'entretien';

  @override
  String get teacherVerifAvailability => 'Tes disponibilités';

  @override
  String get teacherVerifAvailabilityHint => 'Ex. : mardi et jeudi après 17 h';

  @override
  String get teacherVerifBack => 'Verso (si besoin)';

  @override
  String get teacherVerifCameraUnavailable =>
      'Appareil photo indisponible : choisis plutôt une photo de ton visage dans tes fichiers.';

  @override
  String get teacherVerifCancelRequest => 'Annuler la demande';

  @override
  String get teacherVerifCancelled => 'Demande annulée.';

  @override
  String get teacherVerifChoose => 'Choisir';

  @override
  String get teacherVerifCityHint => 'Douala, Yaoundé…';

  @override
  String get teacherVerifDocType => 'Type de pièce';

  @override
  String get teacherVerifFile => 'Fichier';

  @override
  String teacherVerifFileLine(Object label, Object fileName) {
    return '$label : $fileName';
  }

  @override
  String get teacherVerifFileTooBig =>
      'Fichier trop volumineux (8 Mo maximum).';

  @override
  String get teacherVerifFront => 'Recto de la pièce';

  @override
  String get teacherVerifHistory => 'Historique';

  @override
  String get teacherVerifIdentityOk => 'Ta pièce d\'identité est validée.';

  @override
  String get teacherVerifIdentityText =>
      'Un administrateur compare la photo de ta pièce et ton visage.';

  @override
  String get teacherVerifIdentityTitle => 'Pièce d\'identité et selfie';

  @override
  String get teacherVerifInactiveLink => '(rattachement inactif)';

  @override
  String get teacherVerifInstitutionText =>
      'Si tu es rattaché à un établissement sur WinPlus, il peut te cautionner après t\'avoir vérifié par ses propres moyens. Si le rattachement ou la caution est retiré, cette voie tombe.';

  @override
  String get teacherVerifInstitutionTitle => 'Caution de ton institution';

  @override
  String get teacherVerifInterviewText =>
      'En visio ou en rencontre. L\'entretien ne remplace pas l\'identité : prépare ta pièce, elle est jointe au dossier avec un selfie.';

  @override
  String get teacherVerifInterviewTitle => 'Entretien avec un agent';

  @override
  String get teacherVerifIntro =>
      'Les séances chez l\'élève, chez toi ou en lieu neutre sont réservées aux tuteurs vérifiés. Choisis une des trois voies : une seule suffit. Le diplôme reste un badge facultatif.';

  @override
  String teacherVerifLastInterview(Object reason) {
    return 'Dernier entretien : $reason';
  }

  @override
  String teacherVerifLink(Object url) {
    return 'Lien : $url';
  }

  @override
  String get teacherVerifMeeting => 'Rencontre';

  @override
  String get teacherVerifMeetingCity => 'Ville de la rencontre';

  @override
  String get teacherVerifMessage => 'Message (facultatif)';

  @override
  String get teacherVerifNeedFiles =>
      'Ajoute au moins le recto de ta pièce et un selfie.';

  @override
  String get teacherVerifNoEndorsement =>
      'Aucune caution pour le moment. Demande à ton établissement de rattachement (Réseau) de te cautionner.';

  @override
  String get teacherVerifPassed => 'Entretien réussi.';

  @override
  String get teacherVerifPassedNeedIdentity =>
      'Il reste à valider ta pièce d\'identité et ton selfie pour ouvrir le présentiel.';

  @override
  String teacherVerifPendingSince(Object date) {
    return 'En cours de vérification depuis le $date.';
  }

  @override
  String get teacherVerifPhotoTooBig =>
      'Photo trop volumineuse (8 Mo maximum).';

  @override
  String teacherVerifPlace(Object place) {
    return 'Lieu : $place';
  }

  @override
  String teacherVerifReasonSuffix(Object reason) {
    return ' : $reason';
  }

  @override
  String teacherVerifRejected(Object reason) {
    return 'Refusée : $reason. Tu peux envoyer de nouveaux documents.';
  }

  @override
  String get teacherVerifRequestInterview => 'Demander un entretien';

  @override
  String get teacherVerifRequested =>
      'Demande envoyée. Un agent WinPlus va te proposer une date.';

  @override
  String teacherVerifRequestedOn(Object date) {
    return 'Demande envoyée le $date. Un agent va te proposer une date.';
  }

  @override
  String get teacherVerifRetake => 'Reprendre';

  @override
  String teacherVerifRetention(Object approved, Object rejected) {
    return 'Fichiers privés, vus seulement par l\'équipe WinPlus, jamais affichés sur ton profil. Supprimés $approved jours après la validation ($rejected jours après un refus) ; seule la décision est conservée.';
  }

  @override
  String teacherVerifRevoked(Object name, Object date) {
    return 'Caution de $name retirée le $date';
  }

  @override
  String teacherVerifRoutesValidated(Object routes) {
    return 'Voie(s) validée(s) : $routes';
  }

  @override
  String teacherVerifScheduledOn(Object date) {
    return 'Prévu le $date';
  }

  @override
  String get teacherVerifSelfie => 'Selfie (ton visage)';

  @override
  String get teacherVerifSent =>
      'Documents envoyés. L\'équipe WinPlus va les comparer.';

  @override
  String get teacherVerifSubmit => 'Envoyer pour vérification';

  @override
  String get teacherVerifSuspended => 'Présentiel suspendu';

  @override
  String get teacherVerifSuspendedBanner =>
      'Suite à des signalements, tes séances présentielles sont suspendues le temps qu\'un membre de l\'équipe WinPlus examine la situation. Tes séances en ligne restent possibles.';

  @override
  String get teacherVerifTake => 'Prendre';

  @override
  String get teacherVerifTitle => 'Vérification présentiel';

  @override
  String get teacherVerifValidated => 'Validée';

  @override
  String teacherVerifVerifiedBy(Object name) {
    return 'vérifié par $name';
  }

  @override
  String get teacherVerifVideo => 'Visio';

  @override
  String get timerBackToWork => 'Retour au travail !';

  @override
  String get timerBreakDone => 'Pause terminée !';

  @override
  String timerDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pomodoros',
      one: '$count pomodoro',
      zero: '$count pomodoro',
    );
    return 'Bravo ! Tu as complété $_temp0 aujourd\'hui.';
  }

  @override
  String get timerModeLongBreak => 'Pause longue';

  @override
  String get timerModePomodoro => 'Pomodoro';

  @override
  String get timerModeShortBreak => 'Pause courte';

  @override
  String get timerNewPomodoro => 'Nouveau pomodoro';

  @override
  String get timerPomodoroDone => 'Pomodoro terminé !';

  @override
  String get timerReset => 'Réinitialiser';

  @override
  String get timerTip =>
      '25 min de focus + 5 min de pause = 1 pomodoro. Après 4 pomodoros, prends une pause longue de 15 min.';

  @override
  String get timerTitle => 'Timer Pomodoro';

  @override
  String timerTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pomodoros aujourd\'hui',
      one: '$count pomodoro aujourd\'hui',
      zero: '$count pomodoros aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get tutoringActionFailed => 'Action impossible.';

  @override
  String get tutoringAddTopic => 'Ajouter ce sujet';

  @override
  String get tutoringAllClasses => 'Toutes les classes';

  @override
  String get tutoringAllLevels => 'Tous niveaux';

  @override
  String get tutoringAllSubjects => 'Toutes matières';

  @override
  String get tutoringAnotherTopic => 'Autre sujet…';

  @override
  String tutoringAssignAllClass(Object name) {
    return 'Toute la classe $name';
  }

  @override
  String get tutoringAssignChildrenLabel => 'Enfants bénéficiaires';

  @override
  String get tutoringAssignChooseChild => 'Choisis au moins un enfant.';

  @override
  String get tutoringAssignChooseStudents =>
      'Choisis des élèves ou une classe.';

  @override
  String get tutoringAssignChooseTutor => 'Choisis un répétiteur.';

  @override
  String get tutoringAssignError => 'Attribution impossible.';

  @override
  String get tutoringAssignIntro =>
      'Le répétiteur reçoit la demande et l\'accepte ou la refuse. L\'attribution ne réserve rien : elle le met en avant et présélectionne les élèves pour réserver en un clic.';

  @override
  String get tutoringAssignNoChild =>
      'Aucun enfant lié (le lien doit être accepté par l\'enfant).';

  @override
  String get tutoringAssignNoStudent =>
      'Aucun élève actif au rattachement confirmé dans ton institution.';

  @override
  String get tutoringAssignNoTutor => 'Aucun répétiteur trouvé.';

  @override
  String get tutoringAssignNoWholeClass => 'Pas de classe entière';

  @override
  String get tutoringAssignNoteHint =>
      'Un mot pour le répétiteur (objectifs, fréquence…)';

  @override
  String tutoringAssignPending(Object count) {
    return '$count élève(s) rattaché(s) n\'ont pas encore confirmé leur rattachement : ils n\'apparaissent pas ici tant qu\'ils ne l\'ont pas accepté depuis leur compte.';
  }

  @override
  String tutoringAssignResponse(Object note) {
    return 'Réponse : « $note »';
  }

  @override
  String get tutoringAssignStudentsLabel => 'Élèves bénéficiaires';

  @override
  String get tutoringAssignSubjectHint => 'Matière (ex. Mathématiques)';

  @override
  String get tutoringAssignSubmit => 'Envoyer l\'attribution';

  @override
  String get tutoringAssignTutor => 'Attribuer un tuteur';

  @override
  String tutoringAssignedBy(Object name) {
    return 'attribué par $name';
  }

  @override
  String get tutoringAssignedLabel => 'Attribués :';

  @override
  String get tutoringAssignedTitle => 'Tes répétiteurs attribués';

  @override
  String get tutoringAssignedTutor => 'Répétiteur attribué';

  @override
  String get tutoringAssignedTutors => 'Répétiteurs attribués';

  @override
  String get tutoringAvailability14 => 'Disponibilités (14 prochains jours)';

  @override
  String get tutoringAvailableSlots => 'Créneaux disponibles';

  @override
  String get tutoringAvailableSoon => 'Disponible sous 48h';

  @override
  String tutoringBalanceNotCover(Object hint) {
    return 'Le solde ne couvre pas le prix de cette séance. $hint';
  }

  @override
  String tutoringBaseRate(Object rate) {
    return 'Tarif de base : $rate XAF / h';
  }

  @override
  String get tutoringBook => 'Réserver';

  @override
  String get tutoringBookMonthly => 'Réserver au mois';

  @override
  String get tutoringBookSession => 'Réserver une séance';

  @override
  String get tutoringBookedSessions => 'Séances réservées';

  @override
  String get tutoringBookingCancelled => 'Réservation annulée';

  @override
  String get tutoringBookingCreateError =>
      'Erreur lors de la création de la réservation.';

  @override
  String get tutoringBookingsDisputeError =>
      'Impossible d\'envoyer le signalement.';

  @override
  String get tutoringBookingsDisputeSent => 'Votre signalement a été envoyé.';

  @override
  String get tutoringBookingsEmpty => 'Aucune réservation pour le moment.';

  @override
  String get tutoringBookingsLoadError =>
      'Impossible de charger vos réservations.';

  @override
  String get tutoringBookingsTitle => 'Mes réservations';

  @override
  String get tutoringCalendarError =>
      'Impossible de charger les disponibilités.';

  @override
  String get tutoringCancellationPolicy => 'Politique d\'annulation';

  @override
  String get tutoringCheckNow => 'Vérifier maintenant';

  @override
  String get tutoringChooseDay => 'Choisissez un jour';

  @override
  String tutoringClassName(Object name) {
    return 'Classe $name';
  }

  @override
  String get tutoringDate => 'Date';

  @override
  String get tutoringDefaultName => 'Tuteur WinPlus';

  @override
  String get tutoringDiplomaVerified => 'Diplôme vérifié';

  @override
  String get tutoringDispute => 'Contester';

  @override
  String tutoringDisputeSentReason(Object reason) {
    return 'Signalement envoyé : $reason';
  }

  @override
  String get tutoringDisputeSession => 'Contester la séance';

  @override
  String tutoringDisputeUntil(Object date, Object time, Object hours) {
    return 'Un problème ? Tu peux contester jusqu\'au $date à $time ($hours h après la séance). Ensuite, le paiement est versé au tuteur.';
  }

  @override
  String get tutoringDurationHint =>
      'Par tranches de 30 min, jusqu\'à la fin de la plage libre.';

  @override
  String get tutoringEndAssignment => 'Mettre fin';

  @override
  String tutoringEndorsedBy(Object name) {
    return 'Caution : $name';
  }

  @override
  String tutoringEndsAt(Object time) {
    return '· fin à $time';
  }

  @override
  String get tutoringEngAccept => 'Accepter l\'engagement';

  @override
  String get tutoringEngAccepted =>
      'Engagement accepté : les séances sont confirmées.';

  @override
  String get tutoringEngAddSlot => 'Ajouter un créneau';

  @override
  String tutoringEngAutoFailed(Object reason) {
    return 'Renouvellement automatique impossible : $reason';
  }

  @override
  String get tutoringEngAutoOff => 'Renouvellement automatique désactivé.';

  @override
  String get tutoringEngAutoOn => 'Renouvellement automatique activé.';

  @override
  String get tutoringEngAutoRenew =>
      'Renouveler automatiquement chaque mois sur le solde';

  @override
  String tutoringEngAutoRenewAt(Object date) {
    return 'Tentative le $date, si les créneaux sont encore libres et le solde suffisant.';
  }

  @override
  String get tutoringEngAutoRenewHelp =>
      'Mêmes créneaux. Tentative 3 jours avant la fin, après un rappel 7 jours avant ; si le solde ne suffit pas ou si un créneau n\'est plus libre, rien n\'est débité et tu es prévenu.';

  @override
  String get tutoringEngAutoRenewIf =>
      'Si les créneaux sont encore libres et le solde suffisant.';

  @override
  String get tutoringEngAutoRenewTitle =>
      'Renouvellement automatique sur le solde';

  @override
  String get tutoringEngAutoRenewWalletOnly =>
      'Le renouvellement automatique n\'est possible qu\'avec un paiement par solde.';

  @override
  String get tutoringEngAutoWalletOnly =>
      'Le renouvellement automatique n\'est possible que pour un engagement payé par solde.';

  @override
  String get tutoringEngCancel => 'Annuler l\'engagement';

  @override
  String get tutoringEngCancelPayerConfirm =>
      'Annuler ? Les séances passées restent dues ; chaque séance à venir est remboursée selon la politique du tuteur.';

  @override
  String get tutoringEngCancelSession => 'Annuler cette séance';

  @override
  String tutoringEngCancelSessionConfirm(Object date) {
    return 'Annuler seulement la séance du $date ?';
  }

  @override
  String get tutoringEngCancelTutorConfirm =>
      'Annuler ? Les séances à venir sont remboursées intégralement au payeur.';

  @override
  String get tutoringEngCancelled =>
      'Engagement annulé, remboursements crédités.';

  @override
  String get tutoringEngCreateError => 'Création de l\'engagement impossible.';

  @override
  String get tutoringEngDay => 'Jour';

  @override
  String get tutoringEngDeclineConfirm =>
      'Refuser l\'engagement ? Le payeur est remboursé intégralement.';

  @override
  String get tutoringEngDeclined =>
      'Engagement refusé : le payeur est remboursé.';

  @override
  String tutoringEngDiscountNote(Object percent, Object amount) {
    return 'Remise mensuelle $percent % ($amount XAF). ';
  }

  @override
  String get tutoringEngDisputePrompt => 'Pourquoi contestes-tu cette séance ?';

  @override
  String tutoringEngDisputeUntil(Object date) {
    return 'contestation possible jusqu\'au $date';
  }

  @override
  String get tutoringEngDisputed =>
      'Séance contestée : le support va examiner. Les autres séances ne sont pas bloquées.';

  @override
  String get tutoringEngEditSlots => 'Modifier les créneaux';

  @override
  String get tutoringEngExplainProblem => 'Explique le problème';

  @override
  String tutoringEngFeesNote(Object amount) {
    return ' Frais Mobile Money retenus sur les remboursements : $amount XAF.';
  }

  @override
  String get tutoringEngFirstDay => 'Premier jour';

  @override
  String get tutoringEngHeld => 'Bloqué';

  @override
  String get tutoringEngIntro =>
      'Les mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance';

  @override
  String tutoringEngIntroDiscount(Object percent) {
    return ', avec $percent % de remise mensuelle';
  }

  @override
  String get tutoringEngIntroEnd =>
      '. Le tuteur est payé séance par séance, après chaque séance effectuée.';

  @override
  String get tutoringEngMarkedCompleted => 'Séance marquée effectuée.';

  @override
  String get tutoringEngMmSent =>
      'Demande de paiement envoyée sur ton téléphone.';

  @override
  String get tutoringEngMomoChip => 'Mobile Money (MTN MoMo ou Orange Money)';

  @override
  String get tutoringEngMoneyFlow =>
      'L\'argent est versé au tuteur séance par séance, après chaque séance effectuée et non contestée.';

  @override
  String tutoringEngMonthlyDiscount(Object percent) {
    return 'Remise mensuelle ($percent %)';
  }

  @override
  String get tutoringEngNotFound => 'Engagement introuvable.';

  @override
  String get tutoringEngNotOffered =>
      'Ce tuteur ne propose pas l\'engagement mensuel.';

  @override
  String get tutoringEngPaidAdvance => 'Payé d\'avance';

  @override
  String tutoringEngPaidByLine(Object subject, Object payer, Object method) {
    return '$subject · payé par $payer · $method';
  }

  @override
  String get tutoringEngPayMonth => 'Payer le mois';

  @override
  String get tutoringEngPaymentNotConfirmed => 'Paiement non confirmé';

  @override
  String get tutoringEngPaymentPending => 'Paiement en attente de confirmation';

  @override
  String get tutoringEngPaymentReceived =>
      'Paiement reçu, en attente du tuteur';

  @override
  String tutoringEngPerMonth(Object count) {
    return '$count séances sur le mois, vérifiées dans l\'agenda du tuteur.';
  }

  @override
  String get tutoringEngPhoneFormat =>
      'Numéro Mobile Money : 9 chiffres (ex. 670000000).';

  @override
  String get tutoringEngQuoteError => 'Impossible de calculer le devis.';

  @override
  String get tutoringEngQuoteHelp =>
      'Le tuteur accepte ou refuse l\'engagement entier ; s\'il refuse ou ne répond pas, tout est remboursé. L\'argent reste bloqué et n\'est versé au tuteur que séance par séance. En cas d\'annulation, la politique ci-dessus s\'applique à chaque séance à venir.';

  @override
  String tutoringEngQuoteRange(Object from, Object to, Object count) {
    return 'Du $from au $to · $count séances';
  }

  @override
  String tutoringEngQuoteStudents(Object count) {
    return ' · $count élèves';
  }

  @override
  String get tutoringEngQuoteUnavailable => 'Devis indisponible.';

  @override
  String tutoringEngRangeSummary(Object from, Object to, Object slots) {
    return 'Du $from au $to · $slots';
  }

  @override
  String tutoringEngReason(Object reason) {
    return 'Motif : $reason';
  }

  @override
  String tutoringEngRefundedAmount(Object amount) {
    return '$amount XAF remboursés';
  }

  @override
  String get tutoringEngRefundedTile => 'Remboursé';

  @override
  String get tutoringEngReleased => 'Versé au tuteur';

  @override
  String get tutoringEngRemoveSlot => 'Retirer ce créneau';

  @override
  String get tutoringEngRenewMm => 'Renouveler par Mobile Money';

  @override
  String get tutoringEngRenewWallet => 'Renouveler (payer avec le solde)';

  @override
  String get tutoringEngRenewal => 'Renouvellement';

  @override
  String get tutoringEngRenewedWallet =>
      'Mois suivant réservé et payé par solde.';

  @override
  String tutoringEngReplyBefore(Object date) {
    return 'Réponds avant le $date';
  }

  @override
  String tutoringEngSameSlots(Object date) {
    return 'Mêmes créneaux à partir du $date. Manuel par défaut ; rappel 7 jours avant la fin.';
  }

  @override
  String get tutoringEngSeeEngagement => 'Voir l\'engagement';

  @override
  String get tutoringEngSeeNextMonth => 'Voir le mois suivant';

  @override
  String get tutoringEngSeeQuote => 'Voir le devis du mois';

  @override
  String get tutoringEngSessionCancelled => 'Séance annulée.';

  @override
  String tutoringEngSessions(Object done, Object total) {
    return 'Séances ($done effectuée(s) sur $total)';
  }

  @override
  String get tutoringEngSomeUnavailable =>
      'Certaines séances ne sont pas disponibles : change le jour, l\'heure ou la date de début.';

  @override
  String get tutoringEngStagePayment => 'Paiement d\'avance';

  @override
  String get tutoringEngStagePlan => 'Engagement mensuel';

  @override
  String get tutoringEngStageQuote => 'Devis du mois';

  @override
  String get tutoringEngStageSuccess => 'Engagement payé';

  @override
  String get tutoringEngStart => 'Début';

  @override
  String get tutoringEngSubtotal => 'Sous-total (grille du tuteur)';

  @override
  String tutoringEngSuccessText(Object count, Object from, Object to) {
    return '$count séances du $from au $to. Le tuteur doit accepter l\'engagement entier ; s\'il refuse ou ne répond pas à temps, tout est remboursé sur le portefeuille WinPlus du payeur.';
  }

  @override
  String tutoringEngTileTotal(Object amount, Object done, Object total) {
    return '$amount XAF · $done/$total séances effectuées';
  }

  @override
  String get tutoringEngTotalAdvance => 'Total payé d\'avance';

  @override
  String get tutoringEngValidateOnPhone =>
      'Valide le paiement sur ton téléphone';

  @override
  String tutoringEngWalletMissing(Object amount) {
    return 'Solde insuffisant : il manque $amount XAF.';
  }

  @override
  String get tutoringEngWalletShort =>
      'Le solde ne couvre pas le total du mois. Choisis Mobile Money ou recharge le portefeuille.';

  @override
  String get tutoringEngWeeklySlots => 'Créneaux de chaque semaine';

  @override
  String tutoringEngWith(Object name) {
    return 'Avec $name';
  }

  @override
  String get tutoringEngagementsTitle => 'Engagements mensuels';

  @override
  String get tutoringEveryDay => 'tous les jours';

  @override
  String get tutoringFilterInPerson => 'Présentiel (vérifiés)';

  @override
  String get tutoringFilterNeutralPlace => 'Espace neutre';

  @override
  String get tutoringFilterStudentHome => 'À mon domicile';

  @override
  String get tutoringForMe => 'Pour moi';

  @override
  String get tutoringForStudentsTitle => 'Tutorat de mes élèves';

  @override
  String get tutoringForWhomGroupHelp =>
      'C\'est toi qui paies la séance du groupe (ton solde ou Mobile Money) et qui reçois un éventuel remboursement.';

  @override
  String tutoringForWhomInstitutionHelp(Object count) {
    return '$count élève(s) choisi(s). Payé par le portefeuille de l\'institution ou Mobile Money.';
  }

  @override
  String tutoringForWhomMaxGroup(Object count) {
    return 'Ce tuteur accepte au plus $count élèves par séance.';
  }

  @override
  String get tutoringForWhomNoChild =>
      'Aucun enfant lié à ton compte (le lien doit être accepté par l\'enfant).';

  @override
  String get tutoringForWhomNoGroup =>
      'Ce tuteur ne propose pas de séances de groupe : choisis un seul élève.';

  @override
  String tutoringForWhomNoStudent(Object name) {
    return 'Aucun élève actif rattaché à $name.';
  }

  @override
  String get tutoringForWhomParentHelp =>
      'Tu paies avec ton portefeuille parent ou Mobile Money ; tes enfants voient la séance dans leur espace.';

  @override
  String tutoringForWhomPendingConfirmation(Object count) {
    return '$count élève(s) rattaché(s) n\'apparaissent pas : ils doivent d\'abord confirmer leur rattachement à l\'institution depuis leur compte (Mon réseau).';
  }

  @override
  String get tutoringForWhomTitle => 'Pour qui ?';

  @override
  String get tutoringFrom => 'à partir de';

  @override
  String tutoringFromDuration(Object duration, Object percent) {
    return 'À partir de $duration : −$percent %';
  }

  @override
  String tutoringGroupDiscount(Object percent) {
    return 'Prix de groupe : −$percent % par élève';
  }

  @override
  String get tutoringGroupEachPays =>
      'Chaque élève paie le prix d\'une séance individuelle.';

  @override
  String tutoringGroupFlat(Object count) {
    return 'Prix fixe du groupe ($count élèves)';
  }

  @override
  String tutoringGroupFlatHint(Object percent, Object amount) {
    return '$percent % du prix individuel · ≈ $amount XAF par élève';
  }

  @override
  String tutoringGroupFlatSummary(Object percent) {
    return 'Prix fixe pour le groupe : $percent % du prix d\'une séance individuelle.';
  }

  @override
  String tutoringGroupFromSize(Object count, Object percent) {
    return 'À partir de $count élèves : −$percent % par élève';
  }

  @override
  String tutoringGroupName(Object name) {
    return 'Groupe : $name';
  }

  @override
  String tutoringGroupUpTo(Object count) {
    return 'Séances de groupe jusqu\'à $count élèves.';
  }

  @override
  String get tutoringInPersonPossible => 'Présentiel possible';

  @override
  String get tutoringInPersonVerified => 'Vérifié pour le présentiel';

  @override
  String get tutoringInstitutionWalletHelp =>
      'Partagé par tous les comptes de l\'institution : il se recharge par Mobile Money, paie les séances et reçoit les remboursements. Il ne se retire pas vers Mobile Money.';

  @override
  String get tutoringIntroVideo => 'Vidéo de présentation';

  @override
  String get tutoringLeaveReview => 'Laisser un avis';

  @override
  String get tutoringLevels => 'Niveaux';

  @override
  String tutoringLongSession(Object percent) {
    return 'Séance longue (−$percent %)';
  }

  @override
  String get tutoringMatAddExercise => 'Ajouter un exercice';

  @override
  String get tutoringMatAddPart => 'Ajouter une partie';

  @override
  String get tutoringMatAddQuestion => 'Ajouter une question';

  @override
  String tutoringMatAnswerLine(Object title, Object answer) {
    return '$title : $answer';
  }

  @override
  String get tutoringMatAnswersSent => 'Réponses envoyées à ton tuteur.';

  @override
  String get tutoringMatChanged => 'Modifié depuis le partage';

  @override
  String get tutoringMatCourse => 'Cours';

  @override
  String get tutoringMatDraftSaved => 'Brouillon enregistré.';

  @override
  String get tutoringMatEasy => 'Facile';

  @override
  String get tutoringMatEditTitle => 'Modifier le support';

  @override
  String tutoringMatExample(Object text) {
    return 'Exemple : $text';
  }

  @override
  String tutoringMatExerciseN(Object n) {
    return 'Exercice $n';
  }

  @override
  String get tutoringMatExercises => 'Exercices';

  @override
  String get tutoringMatExercisesSubmitted => 'Exercices rendus';

  @override
  String tutoringMatFieldAnswer(Object id) {
    return 'Réponse $id';
  }

  @override
  String get tutoringMatFieldContent => 'Contenu';

  @override
  String get tutoringMatFieldExample => 'Exemple (facultatif)';

  @override
  String get tutoringMatFieldExplanation => 'Explication';

  @override
  String get tutoringMatFieldHints => 'Indices (un par ligne)';

  @override
  String get tutoringMatFieldKeyPoints => 'Points clés (un par ligne)';

  @override
  String get tutoringMatFieldObjectives => 'Objectifs (un par ligne)';

  @override
  String get tutoringMatFieldPartTitle => 'Titre de la partie';

  @override
  String get tutoringMatFieldSolution =>
      'Corrigé (visible après la réponse de l\'élève)';

  @override
  String get tutoringMatFieldStatement => 'Énoncé';

  @override
  String get tutoringMatFieldTitle => 'Titre';

  @override
  String get tutoringMatGenerate => 'Générer avec WinAI';

  @override
  String get tutoringMatGenerateHelp =>
      'WinAI prépare un cours, un quiz et des exercices à partir des sujets de la séance. La génération est décomptée de ton usage WinAI ; rien n\'est envoyé aux élèves avant que tu partages.';

  @override
  String get tutoringMatGenerated =>
      'Support généré : relis-le avant de le partager.';

  @override
  String tutoringMatGroupPrefix(Object count) {
    return 'Groupe ($count élèves) : ';
  }

  @override
  String get tutoringMatHard => 'Difficile';

  @override
  String get tutoringMatHints => 'Indices';

  @override
  String get tutoringMatInstructionsHint =>
      'Consigne pour WinAI (facultatif) : « plus d\'exercices », « niveau plus simple »…';

  @override
  String get tutoringMatMedium => 'Moyen';

  @override
  String get tutoringMatNoAnswer => 'Aucune réponse pour l\'instant.';

  @override
  String get tutoringMatNotFound => 'Support introuvable.';

  @override
  String get tutoringMatNotShared =>
      'Le tuteur n\'a pas encore partagé de support pour cette séance.';

  @override
  String tutoringMatNotYet(Object names) {
    return 'Pas encore répondu : $names';
  }

  @override
  String get tutoringMatObjectives => 'Objectifs';

  @override
  String get tutoringMatOutdated => 'Réponses à une version précédente';

  @override
  String tutoringMatPart(Object n) {
    return 'Partie $n';
  }

  @override
  String tutoringMatQuizCount(Object count) {
    return 'Quiz ($count questions)';
  }

  @override
  String get tutoringMatReadOnly =>
      'Consultation seule : les élèves répondent au quiz et aux exercices dans leur compte.';

  @override
  String get tutoringMatRegenerate => 'Régénérer';

  @override
  String get tutoringMatRegenerateConfirm =>
      'Régénérer remplace ton brouillon actuel (la version partagée reste visible jusqu\'au prochain partage). Continuer ?';

  @override
  String get tutoringMatResults => 'Résultats';

  @override
  String get tutoringMatSaveDraft => 'Enregistrer le brouillon';

  @override
  String get tutoringMatShare => 'Partager avec les élèves';

  @override
  String get tutoringMatShareNew => 'Partager la nouvelle version';

  @override
  String get tutoringMatShared => 'Partagé';

  @override
  String get tutoringMatSharedToast =>
      'Support partagé avec les élèves et le payeur.';

  @override
  String tutoringMatSolution(Object solution) {
    return 'Corrigé : $solution';
  }

  @override
  String get tutoringMatStudentAnswers => 'Réponses des élèves';

  @override
  String get tutoringMatStudentPrefix => 'Élève : ';

  @override
  String get tutoringMatSubmit => 'Envoyer mes réponses';

  @override
  String get tutoringMatSummary => 'À retenir';

  @override
  String tutoringMatUnanswered(Object count) {
    return '$count question(s) sans réponse. Envoyer quand même ? Tu ne pourras plus modifier tes réponses.';
  }

  @override
  String tutoringMatYourAnswer(Object answer) {
    return 'Ta réponse : $answer';
  }

  @override
  String get tutoringMatYourAnswerHint => 'Ta réponse…';

  @override
  String get tutoringMaterial => 'Support de séance';

  @override
  String get tutoringMaterialFull => 'Support, quiz et exercices';

  @override
  String get tutoringMe => 'Moi';

  @override
  String get tutoringMode => 'Mode';

  @override
  String get tutoringModeAll => 'tous modes';

  @override
  String get tutoringModeInPerson => 'présentiel';

  @override
  String get tutoringModeNeutralPlace => 'Lieu neutre';

  @override
  String get tutoringModeOnlineLower => 'en ligne';

  @override
  String get tutoringModeStudentHome => 'À domicile';

  @override
  String get tutoringModeStudentHomeMine => 'À domicile (chez moi)';

  @override
  String get tutoringModeTutorHome => 'Chez le tuteur';

  @override
  String tutoringModifierLine(Object label, Object when, Object adjust) {
    return '$label ($when) : $adjust';
  }

  @override
  String get tutoringMomoHint => 'MTN MoMo ou Orange Money';

  @override
  String get tutoringMomoNumber => 'Numéro Mobile Money';

  @override
  String get tutoringMonthly => 'Au mois';

  @override
  String get tutoringMonthlyText =>
      'Mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance et versés au tuteur séance par séance.';

  @override
  String get tutoringMustAccept =>
      'Le tuteur doit accepter ta demande. Tu seras notifié·e dès sa réponse, et remboursé·e intégralement sur ton portefeuille WinPlus s\'il refuse ou ne répond pas à temps.';

  @override
  String tutoringMyRating(Object rating) {
    return 'Ta note : $rating/5';
  }

  @override
  String get tutoringNoAssignment => 'Aucune attribution pour l\'instant.';

  @override
  String get tutoringNoModeConfigured =>
      'Ce tuteur n\'a pas encore configuré de mode de séance.';

  @override
  String get tutoringNoReviewsYet => 'Pas encore d\'avis';

  @override
  String get tutoringNoSlotAvailable =>
      'Aucun créneau disponible pour le moment.';

  @override
  String get tutoringNoSlotThatDay => 'Aucun créneau ce jour-là.';

  @override
  String get tutoringNotSpecified => 'Non renseigné';

  @override
  String get tutoringOnlineOnly => 'En ligne uniquement';

  @override
  String get tutoringPay => 'Payer';

  @override
  String tutoringPayAmount(Object amount) {
    return 'Payer $amount XAF';
  }

  @override
  String get tutoringPayMethod => 'Moyen de paiement';

  @override
  String get tutoringPayNow => 'Payer maintenant';

  @override
  String get tutoringPayWithBalance => 'Payer avec mon solde';

  @override
  String get tutoringPayWithInstitutionWallet =>
      'Payer avec le portefeuille de l\'institution';

  @override
  String get tutoringPayWithParentWallet =>
      'Payer avec mon portefeuille parent';

  @override
  String get tutoringPaymentNotConfirmed =>
      'Le paiement n\'a pas pu être confirmé.';

  @override
  String get tutoringPaymentReceivedAwaiting =>
      'Paiement reçu  en attente du tuteur';

  @override
  String get tutoringPaymentSlow =>
      'Le paiement met plus de temps que prévu. Tu peux vérifier plus tard dans \"Mes séances\".';

  @override
  String get tutoringPerHour => '/ heure';

  @override
  String tutoringPerStudentLine(Object count, Object amount) {
    return '$count élèves × $amount XAF';
  }

  @override
  String tutoringPercent(Object value) {
    return '$value %';
  }

  @override
  String get tutoringPhoneHint =>
      'Numéro Cameroun sans indicatif pays (ex: 670000000).';

  @override
  String get tutoringPhoneInvalid => 'Numéro de téléphone invalide.';

  @override
  String get tutoringPolicyCardTitle => 'Politique d\'annulation de ce tuteur';

  @override
  String tutoringPolicyDispute(Object hours) {
    return 'Après la séance, tu as $hours h pour la contester.';
  }

  @override
  String get tutoringPolicyFactDispute => 'pour contester une séance';

  @override
  String get tutoringPolicyFactFee =>
      'de frais Mobile Money si tu annules toi-même';

  @override
  String get tutoringPolicyFactImmediate => 'Immédiat';

  @override
  String get tutoringPolicyFactRefund => 'remboursement au portefeuille';

  @override
  String tutoringPolicyFull(Object hours) {
    return 'Remboursement intégral si tu annules au moins $hours h avant la séance.';
  }

  @override
  String get tutoringPolicyIntro =>
      'Les règles communes à toutes les séances de cours particuliers réservées sur WinPlus.';

  @override
  String get tutoringPolicyLoadError => 'Impossible de charger la politique.';

  @override
  String tutoringPolicyNone(Object hours) {
    return 'Aucun remboursement à moins de $hours h.';
  }

  @override
  String tutoringPolicyPartial(Object percent, Object min, Object max) {
    return '$percent % remboursés entre $min h et $max h avant.';
  }

  @override
  String get tutoringPolicyRead => 'Lire la politique de tutorat';

  @override
  String get tutoringPolicyTutorCancels =>
      'Si le tuteur annule, refuse ou ne répond pas : remboursement intégral.';

  @override
  String get tutoringPolicyUntilStart =>
      'Remboursement possible jusqu\'au début de la séance.';

  @override
  String tutoringPolicyVersion(Object date) {
    return 'Version du $date.';
  }

  @override
  String get tutoringPolicyWallet =>
      'Remboursements versés immédiatement sur ton portefeuille WinPlus.';

  @override
  String tutoringPolicyWalletFee(Object fee) {
    return 'Remboursements versés immédiatement sur ton portefeuille WinPlus. Si tu annules une séance payée par Mobile Money, $fee % de frais de l\'opérateur sont déduits ; aucun frais pour un paiement par solde.';
  }

  @override
  String get tutoringPrice => 'Prix';

  @override
  String get tutoringPriceUnavailable => 'Prix indisponible.';

  @override
  String get tutoringPrivateLessons => 'Cours particuliers';

  @override
  String get tutoringProfileLoadError => 'Impossible de charger ce profil.';

  @override
  String get tutoringProrata =>
      'Facturation au prorata des tranches de 30 min.';

  @override
  String get tutoringQuoteError => 'Impossible de calculer le prix.';

  @override
  String tutoringRateFrom(Object amount) {
    return 'dès $amount XAF/h';
  }

  @override
  String tutoringRateLine(Object subject, Object mode, Object rate) {
    return '$subject · $mode : $rate XAF / h';
  }

  @override
  String get tutoringRateNa => 'Tarif ND';

  @override
  String get tutoringRateNotGiven => 'Tarif non communiqué';

  @override
  String get tutoringRatesPackages => 'Tarifs & forfaits';

  @override
  String tutoringRatingReviews(Object rating, Object count) {
    return '$rating/5 ($count avis)';
  }

  @override
  String get tutoringReasonOptional => 'Motif (facultatif)';

  @override
  String tutoringRechargeAmount(Object amount) {
    return 'Montant (minimum $amount FCFA)';
  }

  @override
  String get tutoringRechargeConfirmOnPhone =>
      'Confirme le paiement sur ton téléphone ; le solde s\'actualise dès la confirmation.';

  @override
  String get tutoringRechargeConfirmed =>
      'Recharge confirmée : le solde de l\'institution est à jour.';

  @override
  String get tutoringRechargeFailed =>
      'La recharge n\'a pas abouti : aucun montant n\'a été débité.';

  @override
  String get tutoringRechargePending =>
      'Recharge en attente de confirmation sur le téléphone…';

  @override
  String get tutoringRechargePhone => 'Numéro (6XXXXXXXX)';

  @override
  String get tutoringRechargeStartError =>
      'La recharge n\'a pas pu être lancée.';

  @override
  String get tutoringRechargeStillPending =>
      'Recharge toujours en attente : tire vers le bas pour actualiser le solde plus tard.';

  @override
  String get tutoringRechargeTitle => 'Recharger le portefeuille';

  @override
  String tutoringReference(Object ref) {
    return 'Réf. : $ref';
  }

  @override
  String get tutoringReportChooseReason => 'Choisis un motif.';

  @override
  String get tutoringReportDescribe =>
      'Décris ce qui s\'est passé (10 caractères au moins).';

  @override
  String get tutoringReportDescriptionOptional => 'Description (facultative)';

  @override
  String get tutoringReportIntro =>
      'Ton signalement est transmis à l\'équipe WinPlus, qui l\'examine. Le tuteur ne voit pas qui l\'a signalé. Pour un remboursement, utilise plutôt « Contester la séance ».';

  @override
  String tutoringReportName(Object name) {
    return 'Signaler $name';
  }

  @override
  String get tutoringReportPlaceholder =>
      'Ce qui s\'est passé, quand, comment.';

  @override
  String get tutoringReportProblem => 'Signaler un problème';

  @override
  String get tutoringReportProblemHint =>
      'Décrivez le problème rencontré pendant cette séance.';

  @override
  String get tutoringReportProblemPlaceholder =>
      'Ex : le tuteur ne s\'est pas présenté…';

  @override
  String get tutoringReportReason => 'Motif';

  @override
  String get tutoringReportSentTeam =>
      'Signalement du tuteur envoyé à l\'équipe WinPlus.';

  @override
  String get tutoringReportSubmit => 'Envoyer le signalement';

  @override
  String get tutoringReportTutor => 'Signaler le tuteur';

  @override
  String get tutoringReviewChooseRating =>
      'Choisissez une note avant d\'envoyer.';

  @override
  String get tutoringReviewCommentHint =>
      'Commentaire (optionnel, 300 caractères max)';

  @override
  String get tutoringReviewSubmit => 'Envoyer mon avis';

  @override
  String get tutoringReviewThanks => 'Merci pour votre avis !';

  @override
  String get tutoringSearchEmpty => 'Aucun tuteur trouvé pour ces critères.';

  @override
  String get tutoringSearchLoadError => 'Impossible de charger les tuteurs.';

  @override
  String get tutoringSearchStudent => 'Rechercher un élève';

  @override
  String get tutoringSearchTopicsHint =>
      'Sujets à travailler (ex. dérivées, dissertation)';

  @override
  String get tutoringSending => 'Envoi en cours…';

  @override
  String get tutoringSession => 'Séance';

  @override
  String get tutoringSessionConfirmed => 'Séance confirmée !';

  @override
  String get tutoringSessionMode => 'Mode de séance';

  @override
  String get tutoringShortfallInstitution =>
      'Choisis Mobile Money ou recharge le portefeuille de l\'institution (écran Tutorat).';

  @override
  String get tutoringShortfallMine => 'Choisis Mobile Money.';

  @override
  String get tutoringShortfallParent =>
      'Choisis Mobile Money ou recharge ton portefeuille parent.';

  @override
  String get tutoringSlotGone => 'Ce créneau n\'est plus disponible.';

  @override
  String get tutoringSoloPrice => 'Prix pour un élève';

  @override
  String get tutoringStatusCancelled => 'Annulée';

  @override
  String get tutoringStatusCompleted => 'Effectuée';

  @override
  String get tutoringStatusConfirmed => 'Confirmée';

  @override
  String get tutoringStatusDisputed => 'Contestée';

  @override
  String get tutoringStatusExpired => 'Expirée';

  @override
  String get tutoringStatusPendingPayment => 'Paiement en cours';

  @override
  String get tutoringStatusPendingTutor => 'En attente du tuteur';

  @override
  String get tutoringStatusRejected => 'Refusée';

  @override
  String get tutoringStepChooseSlot => 'Choisir un créneau';

  @override
  String get tutoringStepPayment => 'Paiement';

  @override
  String get tutoringStepRecap => 'Récapitulatif';

  @override
  String get tutoringStepSlot => 'Créneau';

  @override
  String get tutoringStillWaiting => 'Toujours en attente';

  @override
  String tutoringStudentFallback(Object id) {
    return 'Élève #$id';
  }

  @override
  String tutoringStudentsCountPrefix(Object count) {
    return '$count élève(s) : ';
  }

  @override
  String tutoringStudentsN(Object count) {
    return 'Élèves ($count)';
  }

  @override
  String get tutoringSubjectEconomics => 'Économie';

  @override
  String get tutoringSubjects => 'Matières';

  @override
  String get tutoringSubjectsLevels => 'Matières & niveaux';

  @override
  String get tutoringSubtotal => 'Sous-total';

  @override
  String get tutoringTheTutor => 'le tuteur';

  @override
  String get tutoringTime => 'Heure';

  @override
  String get tutoringTopUp => 'Recharger';

  @override
  String get tutoringTopics => 'Sujets';

  @override
  String get tutoringTopicsHelp =>
      'Le tuteur les verra dans ta demande pour préparer la séance.';

  @override
  String get tutoringTopicsOptional => 'Sujets à travailler (facultatif)';

  @override
  String get tutoringTopicsPlaceholder => 'Ex. équations du second degré';

  @override
  String get tutoringTotal => 'Total';

  @override
  String get tutoringTotalGroup => 'Total (groupe)';

  @override
  String get tutoringTrialFree => 'Séance d\'essai gratuite';

  @override
  String tutoringTrialPrice(Object amount) {
    return 'Séance d\'essai : $amount XAF';
  }

  @override
  String get tutoringTutor => 'Tuteur';

  @override
  String get tutoringTutoring => 'Tutorat';

  @override
  String get tutoringUnavailable => 'Indisponible';

  @override
  String get tutoringUnavailableParen => '(indisponible)';

  @override
  String get tutoringUnavailableShort => '(indisp.)';

  @override
  String get tutoringViewMySession => 'Voir ma séance';

  @override
  String get tutoringWaitingConfirmation => 'En attente de confirmation…';

  @override
  String get tutoringWaitingUssd =>
      'Valide le paiement via le message USSD envoyé sur ton téléphone.';

  @override
  String tutoringWalletAvailable(Object amount) {
    return 'Disponible : $amount XAF';
  }

  @override
  String get tutoringWalletInstitution => 'Portefeuille de l\'institution';

  @override
  String get tutoringWalletLoading => 'Lecture du solde…';

  @override
  String get tutoringWalletMine => 'Mon solde WinPlus';

  @override
  String get tutoringWalletMineGroup =>
      'Mon solde WinPlus (je paie pour le groupe)';

  @override
  String tutoringWalletMissing(Object amount, Object hint) {
    return 'Solde insuffisant : il manque $amount XAF. $hint';
  }

  @override
  String get tutoringWalletOk =>
      'Paiement immédiat et sans frais. Ta demande part tout de suite au tuteur.';

  @override
  String get tutoringWalletParent => 'Mon portefeuille parent';

  @override
  String get tutoringWalletUnavailable => 'Solde indisponible';

  @override
  String get tutoringWinplusBalance => 'solde WinPlus';

  @override
  String tutoringWithName(Object name) {
    return 'avec $name';
  }

  @override
  String get tutoringYourInstitution => 'ton institution';

  @override
  String get tutoringYourTutor => 'ton tuteur';

  @override
  String get welcomeTagline => 'Ta réussite, notre mission';

  @override
  String get widgetKbOff =>
      ' · désactivée. L\'activer cherche dans les cours et vos fichiers, mais consomme plus de tokens.';

  @override
  String get widgetKbOn =>
      ' · activée : chaque message consomme nettement plus de tokens.';

  @override
  String get widgetKbTitle => 'Base de connaissance';

  @override
  String get widgetMemDeleteFailed => 'Suppression échouée.';

  @override
  String get widgetMemDifficulty => 'Difficulté';

  @override
  String get widgetMemEmpty =>
      'WinAI n\'a pas encore mémorisé d\'informations. Continue à interagir !';

  @override
  String get widgetMemExam => 'Examen';

  @override
  String get widgetMemLoadError => 'Impossible de charger les mémoires.';

  @override
  String get widgetMemMastered => 'Maîtrisé';

  @override
  String get widgetMemMemory => 'Mémoire';

  @override
  String get widgetMemMotivation => 'Motivation';

  @override
  String get widgetMemPreference => 'Préférence';

  @override
  String get widgetMemRefresh => 'Actualiser';

  @override
  String get widgetMemSubtitle => 'Ce que WinAI a retenu de toi';

  @override
  String widgetOfflineBanner(Object when) {
    return 'Hors ligne  dernière mise à jour : $when';
  }

  @override
  String get widgetOfflineUnknown => 'inconnue';

  @override
  String get wrongCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get instMonthlyReportTitle => 'Rapport mensuel par e-mail';

  @override
  String get instMonthlyReportSub => 'Reçu par e-mail le 1er de chaque mois';

  @override
  String get instMonthlyReportMeta =>
      'Chiffres du mois, devoirs, annonces, bulletins, élèves à relancer et plan d\'action WinAI.';

  @override
  String get instMonthlyReportSendNow => 'Recevoir maintenant';

  @override
  String get instMonthlyReportSending => 'Envoi…';

  @override
  String get instMonthlyReportSent =>
      'Envoyé : vérifiez votre boîte de réception (et les indésirables).';

  @override
  String get instMonthlyReportError =>
      'L\'envoi a échoué. Réessayez dans un instant.';

  @override
  String get instMonthlyReportNoEmail => 'Aucune adresse e-mail sur ce compte.';

  @override
  String get studentPdfLoadError => 'Le document n\'a pas pu être chargé.';

  @override
  String get studentPlayerTapToOpen => 'Appuyez pour ouvrir le document';

  @override
  String get studentPlayerOpenOnWeb =>
      'Ce type de fichier s\'ouvre depuis le site winplus.cm.';

  @override
  String get studentCertCopyLink => 'Copier le lien';

  @override
  String get studentCertLinkCopied => 'Lien de vérification copié.';
}
