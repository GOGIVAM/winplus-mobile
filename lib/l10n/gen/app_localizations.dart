import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @aiAskHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta question…'**
  String get aiAskHint;

  /// No description provided for @authAccountActive.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte WinPlus est maintenant actif.'**
  String get authAccountActive;

  /// No description provided for @authAlreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? '**
  String get authAlreadyAccount;

  /// No description provided for @authBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get authBackToLogin;

  /// No description provided for @authBornOn.
  ///
  /// In fr, this message translates to:
  /// **'Né(e) le {date}'**
  String authBornOn(Object date);

  /// No description provided for @authChooseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton profil pour une expérience personnalisée.'**
  String get authChooseProfile;

  /// No description provided for @authChooseSecure.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot de passe sécurisé.'**
  String get authChooseSecure;

  /// No description provided for @authCodeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Vérifiez votre email.'**
  String get authCodeIncorrect;

  /// No description provided for @authCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide.'**
  String get authCodeInvalid;

  /// No description provided for @authCodeSentAddress.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé à votre adresse.'**
  String get authCodeSentAddress;

  /// No description provided for @authCodeSentEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à votre email'**
  String get authCodeSentEmail;

  /// No description provided for @authConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPassword;

  /// No description provided for @authCreateMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authCreateMyAccount;

  /// No description provided for @authDobOptional.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance (optionnel)'**
  String get authDobOptional;

  /// No description provided for @authEmailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get authEmailAddress;

  /// No description provided for @authEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre@email.com'**
  String get authEmailHint;

  /// No description provided for @authEmailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié !'**
  String get authEmailVerified;

  /// No description provided for @authErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau.'**
  String get authErrNetwork;

  /// No description provided for @authFeatInst1.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard centralisé'**
  String get authFeatInst1;

  /// No description provided for @authFeatInst2.
  ///
  /// In fr, this message translates to:
  /// **'Licences multi-élèves'**
  String get authFeatInst2;

  /// No description provided for @authFeatInst3.
  ///
  /// In fr, this message translates to:
  /// **'Indicateurs de vos élèves'**
  String get authFeatInst3;

  /// No description provided for @authFeatParent1.
  ///
  /// In fr, this message translates to:
  /// **'Suivez la progression de vos enfants'**
  String get authFeatParent1;

  /// No description provided for @authFeatParent3.
  ///
  /// In fr, this message translates to:
  /// **'Achetez des contenus pour eux'**
  String get authFeatParent3;

  /// No description provided for @authFeatStudent1.
  ///
  /// In fr, this message translates to:
  /// **'Annales et corrigés à lire dans l’application'**
  String get authFeatStudent1;

  /// No description provided for @authFeatStudent2.
  ///
  /// In fr, this message translates to:
  /// **'Quiz IA personnalisés'**
  String get authFeatStudent2;

  /// No description provided for @authFeatStudent3.
  ///
  /// In fr, this message translates to:
  /// **'Certificats de vos formations terminées'**
  String get authFeatStudent3;

  /// No description provided for @authFeatTeacher1.
  ///
  /// In fr, this message translates to:
  /// **'Publiez et monétisez vos contenus'**
  String get authFeatTeacher1;

  /// No description provided for @authFeatTeacher2.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos classes'**
  String get authFeatTeacher2;

  /// No description provided for @authFeatTeacher3.
  ///
  /// In fr, this message translates to:
  /// **'Revenus sur vos ventes et vos séances'**
  String get authFeatTeacher3;

  /// No description provided for @authFillRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs obligatoires.'**
  String get authFillRequired;

  /// No description provided for @authFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get authFinish;

  /// No description provided for @authFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get authFirstName;

  /// No description provided for @authFollowCloseHint.
  ///
  /// In fr, this message translates to:
  /// **'Alertes dès qu’un événement important survient.'**
  String get authFollowCloseHint;

  /// No description provided for @authFollowCloseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Suivi rapproché'**
  String get authFollowCloseLabel;

  /// No description provided for @authFollowMinimalHint.
  ///
  /// In fr, this message translates to:
  /// **'Je consulterai moi-même l’espace parent.'**
  String get authFollowMinimalHint;

  /// No description provided for @authFollowMinimalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Le minimum'**
  String get authFollowMinimalLabel;

  /// No description provided for @authFollowWeeklyHint.
  ///
  /// In fr, this message translates to:
  /// **'Un résumé de la semaine, sans alerte au fil de l’eau.'**
  String get authFollowWeeklyHint;

  /// No description provided for @authFollowWeeklyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rapport hebdomadaire'**
  String get authFollowWeeklyLabel;

  /// No description provided for @authForgotIntro.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse email, nous vous enverrons un lien de réinitialisation.'**
  String get authForgotIntro;

  /// No description provided for @authForgotNotReceived.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas reçu l\'email ?'**
  String get authForgotNotReceived;

  /// No description provided for @authForgotSent.
  ///
  /// In fr, this message translates to:
  /// **'Email envoyé à {email}. Vérifiez aussi vos spams.'**
  String authForgotSent(Object email);

  /// No description provided for @authForgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get authForgotTitle;

  /// No description provided for @authGoToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Aller à la connexion'**
  String get authGoToLogin;

  /// No description provided for @authGoogleSoon.
  ///
  /// In fr, this message translates to:
  /// **'Google OAuth bientôt disponible !'**
  String get authGoogleSoon;

  /// No description provided for @authIAm.
  ///
  /// In fr, this message translates to:
  /// **'Je suis…'**
  String get authIAm;

  /// No description provided for @authLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get authLastName;

  /// No description provided for @authLogMeOut.
  ///
  /// In fr, this message translates to:
  /// **'Me déconnecter'**
  String get authLogMeOut;

  /// No description provided for @authLvlEns.
  ///
  /// In fr, this message translates to:
  /// **'ENS École Normale'**
  String get authLvlEns;

  /// No description provided for @authLvlEssec.
  ///
  /// In fr, this message translates to:
  /// **'ESSEC Commerce'**
  String get authLvlEssec;

  /// No description provided for @authLvlFmsb.
  ///
  /// In fr, this message translates to:
  /// **'FMSB Médecine'**
  String get authLvlFmsb;

  /// No description provided for @authLvlPrepa.
  ///
  /// In fr, this message translates to:
  /// **'Prépa'**
  String get authLvlPrepa;

  /// No description provided for @authNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get authNewPassword;

  /// No description provided for @authNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get authNext;

  /// No description provided for @authOptConcours.
  ///
  /// In fr, this message translates to:
  /// **'Concours'**
  String get authOptConcours;

  /// No description provided for @authOptEconomics.
  ///
  /// In fr, this message translates to:
  /// **'Économique'**
  String get authOptEconomics;

  /// No description provided for @authOptLiterary.
  ///
  /// In fr, this message translates to:
  /// **'Littéraire'**
  String get authOptLiterary;

  /// No description provided for @authOptOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get authOptOther;

  /// No description provided for @authOptPolytechnique.
  ///
  /// In fr, this message translates to:
  /// **'Polytechnique'**
  String get authOptPolytechnique;

  /// No description provided for @authOptScience.
  ///
  /// In fr, this message translates to:
  /// **'Scientifique'**
  String get authOptScience;

  /// No description provided for @authOptTechnical.
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get authOptTechnical;

  /// No description provided for @authParentFollowHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez changer cette préférence à tout moment.'**
  String get authParentFollowHint;

  /// No description provided for @authParentFollowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous suivre sa scolarité ?'**
  String get authParentFollowTitle;

  /// No description provided for @authParentGoalHint.
  ///
  /// In fr, this message translates to:
  /// **'En quelques mots : réussir un examen, combler une lacune, reprendre confiance…'**
  String get authParentGoalHint;

  /// No description provided for @authParentGoalPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Aider mon fils à progresser en maths avant le brevet'**
  String get authParentGoalPlaceholder;

  /// No description provided for @authParentGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre objectif pour votre enfant ?'**
  String get authParentGoalTitle;

  /// No description provided for @authPeriodicIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour votre sécurité, confirmez votre identité (toutes les 20 jours)'**
  String get authPeriodicIntro;

  /// No description provided for @authPhoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get authPhoneOptional;

  /// No description provided for @authPhoneSoon.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par téléphone bientôt disponible !'**
  String get authPhoneSoon;

  /// No description provided for @authPwdCriteria.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe ne respecte pas les critères.'**
  String get authPwdCriteria;

  /// No description provided for @authPwdUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour ! Vous pouvez maintenant vous connecter.'**
  String get authPwdUpdated;

  /// No description provided for @authResendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get authResendCode;

  /// No description provided for @authResendCodeParen.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code ({seconds}s)'**
  String authResendCodeParen(Object seconds);

  /// No description provided for @authResendEmail.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get authResendEmail;

  /// No description provided for @authResendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {seconds}s'**
  String authResendIn(Object seconds);

  /// No description provided for @authReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get authReset;

  /// No description provided for @authRoleInstitutionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lycée, université ou centre de formation'**
  String get authRoleInstitutionDesc;

  /// No description provided for @authRoleInstitutionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Institution'**
  String get authRoleInstitutionLabel;

  /// No description provided for @authRoleParentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suivi et accompagnement de mes enfants'**
  String get authRoleParentDesc;

  /// No description provided for @authRoleParentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Parent / Tuteur'**
  String get authRoleParentLabel;

  /// No description provided for @authRoleStudentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Du BEPC aux concours des grandes écoles'**
  String get authRoleStudentDesc;

  /// No description provided for @authRoleStudentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant / Apprenant'**
  String get authRoleStudentLabel;

  /// No description provided for @authRoleTeacherDesc.
  ///
  /// In fr, this message translates to:
  /// **'Publication de contenus et suivi des apprenants'**
  String get authRoleTeacherDesc;

  /// No description provided for @authRoleTeacherLabel.
  ///
  /// In fr, this message translates to:
  /// **'Professeur / Formateur'**
  String get authRoleTeacherLabel;

  /// No description provided for @authRule8.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get authRule8;

  /// No description provided for @authRuleDigit.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un chiffre'**
  String get authRuleDigit;

  /// No description provided for @authRuleMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe correspondent'**
  String get authRuleMatch;

  /// No description provided for @authRuleUpper.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une majuscule'**
  String get authRuleUpper;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro incomplet : 9 chiffres (ex. 6 90 12 34 56) ou numéro international commençant par +.'**
  String get authPhoneInvalid;

  /// No description provided for @authRuleLower.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une minuscule'**
  String get authRuleLower;

  /// No description provided for @authRuleSpecial.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un caractère spécial (- _ @ ! …)'**
  String get authRuleSpecial;

  /// No description provided for @authSendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get authSendCode;

  /// No description provided for @authSendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get authSendLink;

  /// No description provided for @authSignupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Inscription impossible.'**
  String get authSignupFailed;

  /// No description provided for @authSignupIntro.
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations pour commencer.'**
  String get authSignupIntro;

  /// No description provided for @authSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get authSkip;

  /// No description provided for @authSkipStep.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get authSkipStep;

  /// No description provided for @authStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get authStart;

  /// No description provided for @authStepFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get authStepFollowUp;

  /// No description provided for @authStepGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get authStepGoal;

  /// No description provided for @authStepLevels.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux'**
  String get authStepLevels;

  /// No description provided for @authStepStream.
  ///
  /// In fr, this message translates to:
  /// **'Filière'**
  String get authStepStream;

  /// No description provided for @authStepSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get authStepSubjects;

  /// No description provided for @authStudentGoalHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'exam pour lequel tu veux te préparer.'**
  String get authStudentGoalHint;

  /// No description provided for @authStudentGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est ton objectif ?'**
  String get authStudentGoalTitle;

  /// No description provided for @authStudentLevelHint.
  ///
  /// In fr, this message translates to:
  /// **'WinAI adapte le contenu à ton niveau scolaire.'**
  String get authStudentLevelHint;

  /// No description provided for @authStudentLevelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est ton niveau ?'**
  String get authStudentLevelTitle;

  /// No description provided for @authStudentStreamHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour mieux cibler les ressources disponibles.'**
  String get authStudentStreamHint;

  /// No description provided for @authStudentStreamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle est ta filière ?'**
  String get authStudentStreamTitle;

  /// No description provided for @authSuccessInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre établissement depuis votre tableau de bord.'**
  String get authSuccessInstitution;

  /// No description provided for @authSuccessParent.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant suivre vos enfants.'**
  String get authSuccessParent;

  /// No description provided for @authSuccessStudent.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil est prêt. Commencez à réviser !'**
  String get authSuccessStudent;

  /// No description provided for @authSuccessTeacher.
  ///
  /// In fr, this message translates to:
  /// **'Publiez votre premier contenu !'**
  String get authSuccessTeacher;

  /// No description provided for @authTeacherLevelsHint.
  ///
  /// In fr, this message translates to:
  /// **'Utile pour situer tes contenus et, plus tard, ton profil Mode Tuteur.'**
  String get authTeacherLevelsHint;

  /// No description provided for @authTeacherLevelsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quels niveaux couvres-tu ?'**
  String get authTeacherLevelsTitle;

  /// No description provided for @authTeacherSubjectsHint.
  ///
  /// In fr, this message translates to:
  /// **'On adapte ton espace professeur et les suggestions WinAI à tes matières.'**
  String get authTeacherSubjectsHint;

  /// No description provided for @authTeacherSubjectsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelles matières enseignes-tu ?'**
  String get authTeacherSubjectsTitle;

  /// No description provided for @authVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get authVerify;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyItsYou.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que c\'est bien vous'**
  String get authVerifyItsYou;

  /// No description provided for @authWelcomeName.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur WinPlus, {name} !'**
  String authWelcomeName(Object name);

  /// No description provided for @authWelcomeSlide1Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Annales, corrigés et quiz du BEPC aux concours des grandes écoles.'**
  String get authWelcomeSlide1Subtitle;

  /// No description provided for @authWelcomeSlide1Title.
  ///
  /// In fr, this message translates to:
  /// **'Toutes tes épreuves, réunies'**
  String get authWelcomeSlide1Title;

  /// No description provided for @authWelcomeSlide2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un assistant pédagogique qui identifie tes lacunes et te propose un plan de révision.'**
  String get authWelcomeSlide2Subtitle;

  /// No description provided for @authWelcomeSlide2Title.
  ///
  /// In fr, this message translates to:
  /// **'WinAI à tes côtés'**
  String get authWelcomeSlide2Title;

  /// No description provided for @authWelcomeSlide3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Parents, professeurs, élèves : chacun suit la progression de l’élève.'**
  String get authWelcomeSlide3Subtitle;

  /// No description provided for @authWelcomeSlide3Title.
  ///
  /// In fr, this message translates to:
  /// **'Toute la famille impliquée'**
  String get authWelcomeSlide3Title;

  /// No description provided for @authXpUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'+50 XP débloqués'**
  String get authXpUnlocked;

  /// No description provided for @authYouDefault.
  ///
  /// In fr, this message translates to:
  /// **'toi'**
  String get authYouDefault;

  /// No description provided for @commonAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get commonAccept;

  /// No description provided for @commonActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get commonActive;

  /// No description provided for @studentExamModuleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz de fin de module'**
  String get studentExamModuleTitle;

  /// No description provided for @studentExamFinalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Examen final'**
  String get studentExamFinalTitle;

  /// No description provided for @studentExamFinalIntro.
  ///
  /// In fr, this message translates to:
  /// **'L’examen final couvre toute la formation : au moins {score} % pour obtenir le certificat.'**
  String studentExamFinalIntro(int score);

  /// No description provided for @studentExamFinalLocked.
  ///
  /// In fr, this message translates to:
  /// **'Termine toutes les leçons pour ouvrir l’examen final.'**
  String get studentExamFinalLocked;

  /// No description provided for @studentExamStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get studentExamStart;

  /// No description provided for @studentExamRetry.
  ///
  /// In fr, this message translates to:
  /// **'Repasser'**
  String get studentExamRetry;

  /// No description provided for @studentExamLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get studentExamLoading;

  /// No description provided for @studentExamLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’examen. Réessaie dans un instant.'**
  String get studentExamLoadFailed;

  /// No description provided for @studentExamPausedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pause de révision'**
  String get studentExamPausedTitle;

  /// No description provided for @studentExamPausedBody.
  ///
  /// In fr, this message translates to:
  /// **'{failures} échecs de suite : l’examen se rouvre le {date}. Profite de ce temps pour combler tes lacunes avec WinAI.'**
  String studentExamPausedBody(int failures, String date);

  /// No description provided for @studentExamRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Encore 1 tentative avant une pause de révision de 24 h.} other{Encore {count} tentatives avant une pause de révision de 24 h.}}'**
  String studentExamRemaining(int count);

  /// No description provided for @studentExamWeakTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les questions qui te posent problème'**
  String get studentExamWeakTitle;

  /// No description provided for @studentExamHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'WinAI t’aide à progresser'**
  String get studentExamHelpTitle;

  /// No description provided for @studentExamAskWinAI.
  ///
  /// In fr, this message translates to:
  /// **'Plan de révision'**
  String get studentExamAskWinAI;

  /// No description provided for @studentExamPractice.
  ///
  /// In fr, this message translates to:
  /// **'Quiz d’entraînement'**
  String get studentExamPractice;

  /// No description provided for @studentExamStudySession.
  ///
  /// In fr, this message translates to:
  /// **'Session de travail'**
  String get studentExamStudySession;

  /// No description provided for @studentExamLessonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Leçons à revoir'**
  String get studentExamLessonsTitle;

  /// No description provided for @studentExamNoWeakPoints.
  ///
  /// In fr, this message translates to:
  /// **'(pas de question précise : revoir l’ensemble du module)'**
  String get studentExamNoWeakPoints;

  /// No description provided for @studentExamPlanPrompt.
  ///
  /// In fr, this message translates to:
  /// **'J’ai échoué {failures} fois à l’examen « {exam} » de la formation « {course} ». Les points qui me posent problème :\n{points}\nPropose-moi un plan de révision court : les leçons à revoir, des conseils de méthode et quelques exercices pour combler ces lacunes.'**
  String studentExamPlanPrompt(
      int failures, String exam, String course, String points);

  /// No description provided for @studentExamPracticePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Prépare-moi un quiz d’entraînement de 6 questions à choix multiples, avec la correction expliquée, pour l’examen « {exam} », centré sur ces points :\n{points}'**
  String studentExamPracticePrompt(String exam, String points);

  /// No description provided for @commonAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get commonAll;

  /// No description provided for @studentSearchLangFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get studentSearchLangFr;

  /// No description provided for @studentSearchLangEn.
  ///
  /// In fr, this message translates to:
  /// **'Anglais (GCE)'**
  String get studentSearchLangEn;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonDarkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get commonDarkMode;

  /// No description provided for @commonDecline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get commonDecline;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get commonDraft;

  /// No description provided for @commonDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get commonDuration;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get commonFree;

  /// No description provided for @commonLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get commonLevel;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get commonLogout;

  /// No description provided for @commonNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau'**
  String get commonNetworkError;

  /// No description provided for @commonOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get commonOnline;

  /// No description provided for @commonPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get commonPending;

  /// No description provided for @commonPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get commonPublished;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get commonSeeAll;

  /// No description provided for @commonSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get commonSend;

  /// No description provided for @commonSubject.
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get commonSubject;

  /// No description provided for @commonToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get commonToday;

  /// No description provided for @commonWinaiAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes WinAI'**
  String get commonWinaiAlerts;

  /// No description provided for @commonWinaiMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire WinAI'**
  String get commonWinaiMemory;

  /// No description provided for @commonWinaiThinking.
  ///
  /// In fr, this message translates to:
  /// **'WinAI réfléchit…'**
  String get commonWinaiThinking;

  /// No description provided for @commonYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get commonYesterday;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithPhone.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec le téléphone'**
  String get continueWithPhone;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @dataSubjectChemistry.
  ///
  /// In fr, this message translates to:
  /// **'Chimie'**
  String get dataSubjectChemistry;

  /// No description provided for @dataSubjectComputing.
  ///
  /// In fr, this message translates to:
  /// **'Informatique'**
  String get dataSubjectComputing;

  /// No description provided for @dataSubjectComputingShort.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get dataSubjectComputingShort;

  /// No description provided for @dataSubjectEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get dataSubjectEnglish;

  /// No description provided for @dataSubjectFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get dataSubjectFrench;

  /// No description provided for @dataSubjectHistGeo.
  ///
  /// In fr, this message translates to:
  /// **'Histoire-Géo'**
  String get dataSubjectHistGeo;

  /// No description provided for @dataSubjectHistGeoShort.
  ///
  /// In fr, this message translates to:
  /// **'Hist-Géo'**
  String get dataSubjectHistGeoShort;

  /// No description provided for @dataSubjectMath.
  ///
  /// In fr, this message translates to:
  /// **'Mathématiques'**
  String get dataSubjectMath;

  /// No description provided for @dataSubjectMathShort.
  ///
  /// In fr, this message translates to:
  /// **'Maths'**
  String get dataSubjectMathShort;

  /// No description provided for @dataSubjectPhilosophy.
  ///
  /// In fr, this message translates to:
  /// **'Philosophie'**
  String get dataSubjectPhilosophy;

  /// No description provided for @dataSubjectPhilosophyShort.
  ///
  /// In fr, this message translates to:
  /// **'Philo'**
  String get dataSubjectPhilosophyShort;

  /// No description provided for @dataSubjectPhysics.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get dataSubjectPhysics;

  /// No description provided for @dataTypeBook.
  ///
  /// In fr, this message translates to:
  /// **'Livre'**
  String get dataTypeBook;

  /// No description provided for @dataTypeCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Correction'**
  String get dataTypeCorrection;

  /// No description provided for @dataTypePaper.
  ///
  /// In fr, this message translates to:
  /// **'Épreuve'**
  String get dataTypePaper;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @fillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs.'**
  String get fillAllFields;

  /// No description provided for @fmtDateAtTime.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String fmtDateAtTime(String date, String time);

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @forumAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get forumAll;

  /// No description provided for @forumAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get forumAnonymous;

  /// No description provided for @forumCatDiscussions.
  ///
  /// In fr, this message translates to:
  /// **'Discussions'**
  String get forumCatDiscussions;

  /// No description provided for @forumCatHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get forumCatHelp;

  /// No description provided for @forumCatQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get forumCatQuestions;

  /// No description provided for @forumCatResources.
  ///
  /// In fr, this message translates to:
  /// **'Ressources'**
  String get forumCatResources;

  /// No description provided for @forumCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get forumCategory;

  /// No description provided for @forumContentField.
  ///
  /// In fr, this message translates to:
  /// **'Contenu *'**
  String get forumContentField;

  /// No description provided for @forumContentHint.
  ///
  /// In fr, this message translates to:
  /// **'Détaillez votre question…'**
  String get forumContentHint;

  /// No description provided for @forumEmptyCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun thread dans cette catégorie.'**
  String get forumEmptyCategory;

  /// No description provided for @forumError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String forumError(Object error);

  /// No description provided for @forumNewThread.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau thread'**
  String get forumNewThread;

  /// No description provided for @forumPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get forumPublish;

  /// No description provided for @forumReplyHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse…'**
  String get forumReplyHint;

  /// No description provided for @forumRoleTeacher.
  ///
  /// In fr, this message translates to:
  /// **'Prof'**
  String get forumRoleTeacher;

  /// No description provided for @forumSolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get forumSolved;

  /// No description provided for @forumThread.
  ///
  /// In fr, this message translates to:
  /// **'Thread'**
  String get forumThread;

  /// No description provided for @forumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Forum'**
  String get forumTitle;

  /// No description provided for @forumTitleField.
  ///
  /// In fr, this message translates to:
  /// **'Titre *'**
  String get forumTitleField;

  /// No description provided for @forumTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre question ou sujet…'**
  String get forumTitleHint;

  /// No description provided for @instAccountAdmins.
  ///
  /// In fr, this message translates to:
  /// **'Administrateurs'**
  String get instAccountAdmins;

  /// No description provided for @instAccountBilling.
  ///
  /// In fr, this message translates to:
  /// **'Facturation & reçus'**
  String get instAccountBilling;

  /// No description provided for @instAccountGroups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes & classes'**
  String get instAccountGroups;

  /// No description provided for @instAccountLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence WinPlus : sièges et renouvellement'**
  String get instAccountLicense;

  /// No description provided for @instAccountReports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports exportables'**
  String get instAccountReports;

  /// No description provided for @instAccountSchool.
  ///
  /// In fr, this message translates to:
  /// **'Compte établissement'**
  String get instAccountSchool;

  /// No description provided for @instAccountTutoring.
  ///
  /// In fr, this message translates to:
  /// **'Tutorat & portefeuille'**
  String get instAccountTutoring;

  /// No description provided for @instAiHint.
  ///
  /// In fr, this message translates to:
  /// **'Analyse, benchmark, plan d\'action…'**
  String get instAiHint;

  /// No description provided for @instAiSuggestion1.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de cohorte'**
  String get instAiSuggestion1;

  /// No description provided for @instAiSuggestion3.
  ///
  /// In fr, this message translates to:
  /// **'Plan d\'action prioritaire'**
  String get instAiSuggestion3;

  /// No description provided for @instAiSuggestion4.
  ///
  /// In fr, this message translates to:
  /// **'Benchmark national'**
  String get instAiSuggestion4;

  /// No description provided for @instAiTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton auditeur analytique & stratège institutionnel'**
  String get instAiTagline;

  /// No description provided for @instAnalyticsByGroup.
  ///
  /// In fr, this message translates to:
  /// **'Performance par groupe'**
  String get instAnalyticsByGroup;

  /// No description provided for @instAnalyticsDownloadsMonth.
  ///
  /// In fr, this message translates to:
  /// **'Téléch./mois'**
  String get instAnalyticsDownloadsMonth;

  /// No description provided for @instAnalyticsQuizMonth.
  ///
  /// In fr, this message translates to:
  /// **'Quiz/mois'**
  String get instAnalyticsQuizMonth;

  /// No description provided for @instCatalogAssign.
  ///
  /// In fr, this message translates to:
  /// **'Assigner'**
  String get instCatalogAssign;

  /// No description provided for @instCatalogLicenseInfo.
  ///
  /// In fr, this message translates to:
  /// **'Licence établissement : contenus assignables à tous vos groupes.'**
  String get instCatalogLicenseInfo;

  /// No description provided for @instDashActiveStudents.
  ///
  /// In fr, this message translates to:
  /// **'Élèves actifs{pct}'**
  String instDashActiveStudents(Object pct);

  /// No description provided for @instDashActiveStudentsLower.
  ///
  /// In fr, this message translates to:
  /// **'élèves actifs'**
  String get instDashActiveStudentsLower;

  /// No description provided for @instDashAiPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan d\'action IA'**
  String get instDashAiPlan;

  /// No description provided for @instDashAlertsInfo.
  ///
  /// In fr, this message translates to:
  /// **'Analysez les performances de vos groupes et identifiez les élèves à risque.'**
  String get instDashAlertsInfo;

  /// No description provided for @instDashDirectory.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire'**
  String get instDashDirectory;

  /// No description provided for @instDashNoLicense.
  ///
  /// In fr, this message translates to:
  /// **'Sans licence active'**
  String get instDashNoLicense;

  /// No description provided for @instDashQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get instDashQuickActions;

  /// No description provided for @instDashQuizMonth.
  ///
  /// In fr, this message translates to:
  /// **'Quiz ce mois'**
  String get instDashQuizMonth;

  /// No description provided for @instDashStudentsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} élèves'**
  String instDashStudentsCount(Object n);

  /// No description provided for @instDashUrgent.
  ///
  /// In fr, this message translates to:
  /// **'{n} élèves nécessitent une attention urgente'**
  String instDashUrgent(Object n);

  /// No description provided for @instDirActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get instDirActive;

  /// No description provided for @instDirAddError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cet élève'**
  String get instDirAddError;

  /// No description provided for @instDirAddSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Élève ajouté avec succès'**
  String get instDirAddSuccess;

  /// No description provided for @instDirAvg.
  ///
  /// In fr, this message translates to:
  /// **'Moy.'**
  String get instDirAvg;

  /// No description provided for @instDirCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} {count, plural, =1{élève} other{élèves}}'**
  String instDirCount(int count);

  /// No description provided for @instDirEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get instDirEmailRequired;

  /// No description provided for @instDirGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get instDirGroup;

  /// No description provided for @instDirNoInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Aucune institution associée.'**
  String get instDirNoInstitution;

  /// No description provided for @instDirNoStudent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève trouvé.'**
  String get instDirNoStudent;

  /// No description provided for @instDirSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom ou email…'**
  String get instDirSearchHint;

  /// No description provided for @instDirStudents.
  ///
  /// In fr, this message translates to:
  /// **'Élèves'**
  String get instDirStudents;

  /// No description provided for @instDirTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire des élèves'**
  String get instDirTitle;

  /// No description provided for @instEndorseAction.
  ///
  /// In fr, this message translates to:
  /// **'Cautionner'**
  String get instEndorseAction;

  /// No description provided for @instEndorseBadge.
  ///
  /// In fr, this message translates to:
  /// **'Cautionné'**
  String get instEndorseBadge;

  /// No description provided for @instEndorseChangeDate.
  ///
  /// In fr, this message translates to:
  /// **'Changer la date'**
  String get instEndorseChangeDate;

  /// No description provided for @instEndorseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la caution'**
  String get instEndorseConfirm;

  /// No description provided for @instEndorseEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun répétiteur rattaché à votre établissement pour le moment.'**
  String get instEndorseEmpty;

  /// No description provided for @instEndorseHowHint.
  ///
  /// In fr, this message translates to:
  /// **'Entretien, pièce d\'identité vue en mains propres, contrat…'**
  String get instEndorseHowHint;

  /// No description provided for @instEndorseHowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Comment l\'avez-vous vérifié ?'**
  String get instEndorseHowLabel;

  /// No description provided for @instEndorseIntro.
  ///
  /// In fr, this message translates to:
  /// **'Si votre établissement a vérifié un répétiteur par ses propres moyens, cautionnez-le : il pourra proposer des séances présentielles. Vous pouvez retirer la caution à tout moment ; retirer le rattachement la retire aussi.'**
  String get instEndorseIntro;

  /// No description provided for @instEndorseNotEndorsed.
  ///
  /// In fr, this message translates to:
  /// **'Non cautionné'**
  String get instEndorseNotEndorsed;

  /// No description provided for @instEndorseOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Le {date}'**
  String instEndorseOnDate(Object date);

  /// No description provided for @instEndorseOtherRoute.
  ///
  /// In fr, this message translates to:
  /// **'Déjà vérifié pour le présentiel par une autre voie'**
  String get instEndorseOtherRoute;

  /// No description provided for @instEndorseReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif (transmis au répétiteur)'**
  String get instEndorseReasonLabel;

  /// No description provided for @instEndorseRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la caution'**
  String get instEndorseRevoke;

  /// No description provided for @instEndorseRevokeAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get instEndorseRevokeAction;

  /// No description provided for @instEndorseRevokeText.
  ///
  /// In fr, this message translates to:
  /// **'S\'il n\'est pas vérifié par une autre voie, il ne pourra plus proposer de séances présentielles.'**
  String get instEndorseRevokeText;

  /// No description provided for @instEndorseRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la caution ?'**
  String get instEndorseRevokeTitle;

  /// No description provided for @instEndorseRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Caution retirée.'**
  String get instEndorseRevoked;

  /// No description provided for @instEndorseSaved.
  ///
  /// In fr, this message translates to:
  /// **'Caution enregistrée.'**
  String get instEndorseSaved;

  /// No description provided for @instEndorseScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cautions des répétiteurs'**
  String get instEndorseScreenTitle;

  /// No description provided for @instEndorseSheetInfo.
  ///
  /// In fr, this message translates to:
  /// **'Il pourra proposer des séances présentielles, avec le badge « Caution : votre établissement ».'**
  String get instEndorseSheetInfo;

  /// No description provided for @instEndorseThisTutor.
  ///
  /// In fr, this message translates to:
  /// **'ce répétiteur'**
  String get instEndorseThisTutor;

  /// No description provided for @instEndorseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cautionner {name}'**
  String instEndorseTitle(Object name);

  /// No description provided for @instEndorseVerifiedBy.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié par {name}'**
  String instEndorseVerifiedBy(Object name);

  /// No description provided for @instEndorseVerifierLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié par (nom et fonction)'**
  String get instEndorseVerifierLabel;

  /// No description provided for @instGroupAddStudents.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des élèves'**
  String get instGroupAddStudents;

  /// No description provided for @instGroupAssignInfo.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez des contenus depuis le catalogue pour les affecter à ce groupe.'**
  String get instGroupAssignInfo;

  /// No description provided for @instGroupAssignResources.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer ressources'**
  String get instGroupAssignResources;

  /// No description provided for @instGroupAssignTo.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer à {name}'**
  String instGroupAssignTo(Object name);

  /// No description provided for @instGroupBrowseCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir le catalogue'**
  String get instGroupBrowseCatalog;

  /// No description provided for @instGroupCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création du groupe.'**
  String get instGroupCreateError;

  /// No description provided for @instGroupCreateSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get instGroupCreateSubmit;

  /// No description provided for @instGroupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Groupe créé !'**
  String get instGroupCreated;

  /// No description provided for @instGroupCreatedSummary.
  ///
  /// In fr, this message translates to:
  /// **'{name}  {count} élève(s) ajouté(s).'**
  String instGroupCreatedSummary(Object name, Object count);

  /// No description provided for @instGroupLevelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau *'**
  String get instGroupLevelLabel;

  /// No description provided for @instGroupLevelLicence.
  ///
  /// In fr, this message translates to:
  /// **'Licence'**
  String get instGroupLevelLicence;

  /// No description provided for @instGroupNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe *'**
  String get instGroupNameLabel;

  /// No description provided for @instGroupNoMembers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève dans ce groupe.'**
  String get instGroupNoMembers;

  /// No description provided for @instGroupSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un groupe…'**
  String get instGroupSearch;

  /// No description provided for @instGroupSearchStudent.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un élève…'**
  String get instGroupSearchStudent;

  /// No description provided for @instGroupSeeStudents.
  ///
  /// In fr, this message translates to:
  /// **'Voir élèves'**
  String get instGroupSeeStudents;

  /// No description provided for @instGroupSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionné(s)'**
  String instGroupSelected(Object count);

  /// No description provided for @instLicenseAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte {id}'**
  String instLicenseAccount(Object id);

  /// No description provided for @instLicenseAiBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget WinAI de l\'établissement utilisé : {value} %'**
  String instLicenseAiBudget(Object value);

  /// No description provided for @instLicenseAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique par le portefeuille'**
  String get instLicenseAutoRenew;

  /// No description provided for @instLicenseGridMin.
  ///
  /// In fr, this message translates to:
  /// **'Minimum {min} sièges, un siège enseignant pour {perTeacher} élèves.'**
  String instLicenseGridMin(Object min, Object perTeacher);

  /// No description provided for @instLicenseGridPrices.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC par élève et par an : {tiers}.'**
  String instLicenseGridPrices(Object tiers);

  /// No description provided for @instLicenseGridTier.
  ///
  /// In fr, this message translates to:
  /// **'{price} XAF dès {seats} sièges'**
  String instLicenseGridTier(Object price, Object seats);

  /// No description provided for @instLicenseHeading.
  ///
  /// In fr, this message translates to:
  /// **'Licence {status}'**
  String instLicenseHeading(Object status);

  /// No description provided for @instLicenseNegotiated.
  ///
  /// In fr, this message translates to:
  /// **'Négociée'**
  String get instLicenseNegotiated;

  /// No description provided for @instLicensePastDue.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant au renouvellement : rechargez le portefeuille avant le {date}.'**
  String instLicensePastDue(Object date);

  /// No description provided for @instLicensePaymentFrom.
  ///
  /// In fr, this message translates to:
  /// **'Paiement depuis le portefeuille de l\'établissement.'**
  String get instLicensePaymentFrom;

  /// No description provided for @instLicensePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Du {start} au {end}'**
  String instLicensePeriod(Object start, Object end);

  /// No description provided for @instLicensePromo.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get instLicensePromo;

  /// No description provided for @instLicensePurchase.
  ///
  /// In fr, this message translates to:
  /// **'Souscrire avec le portefeuille'**
  String get instLicensePurchase;

  /// No description provided for @instLicensePurchaseError.
  ///
  /// In fr, this message translates to:
  /// **'Souscription impossible.'**
  String get instLicensePurchaseError;

  /// No description provided for @instLicenseQuoteLine.
  ///
  /// In fr, this message translates to:
  /// **'{price} XAF par élève · {teacherSeats} sièges enseignants · jusqu\'au {date}'**
  String instLicenseQuoteLine(Object price, Object teacherSeats, Object date);

  /// No description provided for @instLicenseQuoteTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total : {amount} XAF TTC'**
  String instLicenseQuoteTotal(Object amount);

  /// No description provided for @instLicenseRelease.
  ///
  /// In fr, this message translates to:
  /// **'Libérer'**
  String get instLicenseRelease;

  /// No description provided for @instLicenseReleaseError.
  ///
  /// In fr, this message translates to:
  /// **'Libération impossible.'**
  String get instLicenseReleaseError;

  /// No description provided for @instLicenseRenewWallet.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler avec le portefeuille'**
  String get instLicenseRenewWallet;

  /// No description provided for @instLicenseSeatBenefits.
  ///
  /// In fr, this message translates to:
  /// **'Chaque siège ouvre à l\'élève le catalogue, le plan d\'étude, la session guidée, Exam Coach et un bonus WinAI ; un siège enseignant ouvre les outils du plan Pro et une part de 75 % sur le tutorat.'**
  String get instLicenseSeatBenefits;

  /// No description provided for @instLicenseSeatsInfo.
  ///
  /// In fr, this message translates to:
  /// **'Un siège élève est attribué quand l\'élève accepte son rattachement ; un siège enseignant quand le professeur accepte l\'affiliation.'**
  String get instLicenseSeatsInfo;

  /// No description provided for @instLicenseSeatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sièges attribués'**
  String get instLicenseSeatsTitle;

  /// No description provided for @instLicenseStatusEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get instLicenseStatusEnded;

  /// No description provided for @instLicenseStudentSeats.
  ///
  /// In fr, this message translates to:
  /// **'Sièges élèves'**
  String get instLicenseStudentSeats;

  /// No description provided for @instLicenseStudentSeatsUsed.
  ///
  /// In fr, this message translates to:
  /// **'Sièges élèves : {used} / {total}'**
  String instLicenseStudentSeatsUsed(Object used, Object total);

  /// No description provided for @instLicenseSubscribeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souscrire une licence'**
  String get instLicenseSubscribeTitle;

  /// No description provided for @instLicenseTeacherSeatsUsed.
  ///
  /// In fr, this message translates to:
  /// **'Sièges enseignants : {used} / {total}'**
  String instLicenseTeacherSeatsUsed(Object used, Object total);

  /// No description provided for @instLicenseTermQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Trimestre'**
  String get instLicenseTermQuarter;

  /// No description provided for @instLicenseTermYear.
  ///
  /// In fr, this message translates to:
  /// **'Année scolaire'**
  String get instLicenseTermYear;

  /// No description provided for @instLicenseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Licence WinPlus'**
  String get instLicenseTitle;

  /// No description provided for @instLicenseTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit ({days} jours, {seats} sièges)'**
  String instLicenseTrial(Object days, Object seats);

  /// No description provided for @instLicenseTrialError.
  ///
  /// In fr, this message translates to:
  /// **'Essai indisponible.'**
  String get instLicenseTrialError;

  /// No description provided for @instLicenseUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Licence indisponible.'**
  String get instLicenseUnavailable;

  /// No description provided for @instLicenseUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Modification impossible.'**
  String get instLicenseUpdateError;

  /// No description provided for @instLicenseWait.
  ///
  /// In fr, this message translates to:
  /// **'Patientez…'**
  String get instLicenseWait;

  /// No description provided for @instMySchool.
  ///
  /// In fr, this message translates to:
  /// **'Mon établissement'**
  String get instMySchool;

  /// No description provided for @instPlanActionsDone.
  ///
  /// In fr, this message translates to:
  /// **'actions réalisées'**
  String get instPlanActionsDone;

  /// No description provided for @instPlanDone.
  ///
  /// In fr, this message translates to:
  /// **'Réalisé'**
  String get instPlanDone;

  /// No description provided for @instPlanEmpty.
  ///
  /// In fr, this message translates to:
  /// **'WinAI n\'a proposé aucune action pour cette semaine.'**
  String get instPlanEmpty;

  /// No description provided for @instPlanForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n\'a pas accès au plan d\'action de l\'établissement.'**
  String get instPlanForbidden;

  /// No description provided for @instPlanImpact.
  ///
  /// In fr, this message translates to:
  /// **'Impact attendu : {impact}'**
  String instPlanImpact(Object impact);

  /// No description provided for @instPlanMarkDone.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme fait'**
  String get instPlanMarkDone;

  /// No description provided for @instPlanPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité {n}'**
  String instPlanPriority(Object n);

  /// No description provided for @instPlanSummaryActions.
  ///
  /// In fr, this message translates to:
  /// **', et recommande {count} {count, plural, =0{action prioritaire} =1{action prioritaire} other{actions prioritaires}}.'**
  String instPlanSummaryActions(int count);

  /// No description provided for @instPlanSummaryAtRisk.
  ///
  /// In fr, this message translates to:
  /// **', dont {n} en zone critique'**
  String instPlanSummaryAtRisk(Object n);

  /// No description provided for @instPlanSummaryStudents.
  ///
  /// In fr, this message translates to:
  /// **'WinAI a analysé {count} {count, plural, =0{élève} =1{élève} other{élèves}}'**
  String instPlanSummaryStudents(int count);

  /// No description provided for @instPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan d\'action WinAI'**
  String get instPlanTitle;

  /// No description provided for @instPlanUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le plan d\'action WinAI est indisponible pour le moment.'**
  String get instPlanUnavailable;

  /// No description provided for @instReportAtRiskSub.
  ///
  /// In fr, this message translates to:
  /// **'Élèves nécessitant une intervention'**
  String get instReportAtRiskSub;

  /// No description provided for @instReportAtRiskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport élèves à risque'**
  String get instReportAtRiskTitle;

  /// No description provided for @instReportGeneratePdf.
  ///
  /// In fr, this message translates to:
  /// **'Générer PDF'**
  String get instReportGeneratePdf;

  /// No description provided for @instReportGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Rapport généré !'**
  String get instReportGenerated;

  /// No description provided for @instReportGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération en cours...'**
  String get instReportGenerating;

  /// No description provided for @instReportGlobalSub.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de tous les élèves'**
  String get instReportGlobalSub;

  /// No description provided for @instReportGlobalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport de performance global'**
  String get instReportGlobalTitle;

  /// No description provided for @instReportGroupSub.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison des classes, taux de réussite'**
  String get instReportGroupSub;

  /// No description provided for @instReportGroupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport par classe'**
  String get instReportGroupTitle;

  /// No description provided for @instReportIndividualSub.
  ///
  /// In fr, this message translates to:
  /// **'Progression détaillée d\'un élève'**
  String get instReportIndividualSub;

  /// No description provided for @instReportIndividualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport individuel élève'**
  String get instReportIndividualTitle;

  /// No description provided for @instReportReady.
  ///
  /// In fr, this message translates to:
  /// **'Votre rapport \"{title}\" est prêt.'**
  String instReportReady(Object title);

  /// No description provided for @instReportWait.
  ///
  /// In fr, this message translates to:
  /// **'Patientez...'**
  String get instReportWait;

  /// No description provided for @instReportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get instReportsTitle;

  /// No description provided for @instRiskActionPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan d\'action'**
  String get instRiskActionPlan;

  /// No description provided for @instRiskContact.
  ///
  /// In fr, this message translates to:
  /// **'Contacter'**
  String get instRiskContact;

  /// No description provided for @instRiskCritical.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get instRiskCritical;

  /// No description provided for @instRiskCriticalCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} critiques'**
  String instRiskCriticalCount(Object n);

  /// No description provided for @instRiskEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève dans cette catégorie.'**
  String get instRiskEmpty;

  /// No description provided for @instRiskInactiveFor.
  ///
  /// In fr, this message translates to:
  /// **'Inactif depuis {n}j'**
  String instRiskInactiveFor(Object n);

  /// No description provided for @instRiskModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get instRiskModerate;

  /// No description provided for @instRiskScore.
  ///
  /// In fr, this message translates to:
  /// **'Score : {n}%'**
  String instRiskScore(Object n);

  /// No description provided for @instRiskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Élèves à risque'**
  String get instRiskTitle;

  /// No description provided for @instRiskWeakSubject.
  ///
  /// In fr, this message translates to:
  /// **'Matière faible '**
  String get instRiskWeakSubject;

  /// No description provided for @instStudentCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} {count, plural, =0{élève} =1{élève} other{élèves}}'**
  String instStudentCount(int count);

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageHint.
  ///
  /// In fr, this message translates to:
  /// **'La langue de l\'application, des e-mails et des notifications.'**
  String get languageHint;

  /// No description provided for @legalCgu1Body.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'accès et l\'utilisation de la plateforme WinPlus, application mobile éducative destinée aux élèves, parents et enseignants du système scolaire camerounais.'**
  String get legalCgu1Body;

  /// No description provided for @legalCgu1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Objet'**
  String get legalCgu1Title;

  /// No description provided for @legalCgu2Body.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à WinPlus est ouvert à toute personne disposant d\'un appareil compatible et d\'une connexion internet. Certaines fonctionnalités nécessitent la création d\'un compte. L\'inscription est gratuite pour le plan de base.'**
  String get legalCgu2Body;

  /// No description provided for @legalCgu2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Accès à la plateforme'**
  String get legalCgu2Title;

  /// No description provided for @legalCgu3Body.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes responsable de la confidentialité de vos identifiants. Toute activité effectuée depuis votre compte vous est attribuée. En cas de compromission, contactez-nous immédiatement à support@winplus.cm.'**
  String get legalCgu3Body;

  /// No description provided for @legalCgu3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Comptes utilisateurs'**
  String get legalCgu3Title;

  /// No description provided for @legalCgu4Body.
  ///
  /// In fr, this message translates to:
  /// **'Les contenus publiés sur WinPlus (épreuves, corrections, quiz) sont protégés par le droit d\'auteur. Leur reproduction, redistribution ou revente sans autorisation est strictement interdite.'**
  String get legalCgu4Body;

  /// No description provided for @legalCgu4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Contenu et propriété intellectuelle'**
  String get legalCgu4Title;

  /// No description provided for @legalCgu5Body.
  ///
  /// In fr, this message translates to:
  /// **'Les plans payants (Starter, Expert, Institution) sont facturés mensuellement via Mobile Money (MTN MoMo, Orange Money) ou carte bancaire. Les tarifs sont affichés en francs CFA (XAF) et peuvent évoluer avec préavis de 30 jours.'**
  String get legalCgu5Body;

  /// No description provided for @legalCgu5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Abonnements et paiements'**
  String get legalCgu5Title;

  /// No description provided for @legalCgu6Body.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez résilier votre abonnement à tout moment depuis votre profil. La résiliation prend effet à la fin de la période de facturation en cours. Aucun remboursement partiel n\'est accordé.'**
  String get legalCgu6Body;

  /// No description provided for @legalCgu6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Résiliation'**
  String get legalCgu6Title;

  /// No description provided for @legalCgu7Body.
  ///
  /// In fr, this message translates to:
  /// **'WinPlus s\'efforce de maintenir la plateforme disponible 24h/24, mais ne saurait être tenue responsable des interruptions de service, pertes de données ou inexactitudes dans les contenus.'**
  String get legalCgu7Body;

  /// No description provided for @legalCgu7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Responsabilité'**
  String get legalCgu7Title;

  /// No description provided for @legalCgu8Body.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes CGU sont soumises au droit camerounais. Tout litige sera porté devant les juridictions compétentes de Yaoundé, Cameroun.'**
  String get legalCgu8Body;

  /// No description provided for @legalCgu8Title.
  ///
  /// In fr, this message translates to:
  /// **'8. Droit applicable'**
  String get legalCgu8Title;

  /// No description provided for @legalCguTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions Générales d\'Utilisation'**
  String get legalCguTitle;

  /// No description provided for @legalContactBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question : support@winplus.cm\nWinPlus SAS  Yaoundé, Cameroun'**
  String get legalContactBody;

  /// No description provided for @legalContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get legalContactTitle;

  /// No description provided for @legalLastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 1er juin 2025'**
  String get legalLastUpdated;

  /// No description provided for @legalPriv1Body.
  ///
  /// In fr, this message translates to:
  /// **'WinPlus collecte les données suivantes :\n• Données d\'identification : nom, prénom, adresse e-mail\n• Données de navigation : contenus consultés, résultats de quiz\n• Données de paiement : transmises directement à nos prestataires (MTN, Orange)\n• Données d\'appareil : modèle, système d\'exploitation, identifiant publicitaire'**
  String get legalPriv1Body;

  /// No description provided for @legalPriv1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Données collectées'**
  String get legalPriv1Title;

  /// No description provided for @legalPriv2Body.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont utilisées pour :\n• Fournir et personnaliser les services WinPlus\n• Générer des recommandations pédagogiques via WinAI\n• Traiter vos paiements et gérer votre abonnement\n• Améliorer la plateforme via des analyses agrégées anonymisées'**
  String get legalPriv2Body;

  /// No description provided for @legalPriv2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Finalités du traitement'**
  String get legalPriv2Title;

  /// No description provided for @legalPriv3Body.
  ///
  /// In fr, this message translates to:
  /// **'Le traitement repose sur votre consentement (art. 4 loi n° 2010/012 du Cameroun sur les communications électroniques) et sur l\'exécution du contrat de service que représentent les présentes CGU.'**
  String get legalPriv3Body;

  /// No description provided for @legalPriv3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Base légale'**
  String get legalPriv3Title;

  /// No description provided for @legalPriv4Body.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont conservées pendant la durée de votre relation contractuelle avec WinPlus, augmentée de 3 ans à des fins de preuve. Les données de navigation sont anonymisées après 13 mois.'**
  String get legalPriv4Body;

  /// No description provided for @legalPriv4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Conservation des données'**
  String get legalPriv4Title;

  /// No description provided for @legalPriv5Body.
  ///
  /// In fr, this message translates to:
  /// **'WinPlus ne vend pas vos données. Elles peuvent être partagées avec :\n• Nos hébergeurs (serveurs sécurisés en Europe)\n• Nos prestataires de paiement (MTN, Orange, Stripe)\n• Les autorités compétentes en cas d\'obligation légale'**
  String get legalPriv5Body;

  /// No description provided for @legalPriv5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Partage des données'**
  String get legalPriv5Title;

  /// No description provided for @legalPriv6Body.
  ///
  /// In fr, this message translates to:
  /// **'Conformément à la législation applicable, vous disposez des droits d\'accès, de rectification, d\'effacement, de portabilité et d\'opposition. Exercez-les en écrivant à privacy@winplus.cm.'**
  String get legalPriv6Body;

  /// No description provided for @legalPriv6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Vos droits'**
  String get legalPriv6Title;

  /// No description provided for @legalPriv7Body.
  ///
  /// In fr, this message translates to:
  /// **'L\'application utilise des identifiants anonymes pour mesurer les performances et améliorer l\'expérience utilisateur. Vous pouvez les désactiver dans les paramètres de votre appareil.'**
  String get legalPriv7Body;

  /// No description provided for @legalPriv7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Cookies et traceurs'**
  String get legalPriv7Title;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de Confidentialité'**
  String get legalPrivacyTitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à ton compte WinPlus.'**
  String get loginSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour !'**
  String get loginTitle;

  /// No description provided for @msgDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n}j'**
  String msgDaysAgo(Object n);

  /// No description provided for @msgEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation.'**
  String get msgEmpty;

  /// No description provided for @msgEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Contactez un professeur depuis la fiche d\'un élève.'**
  String get msgEmptyHint;

  /// No description provided for @msgHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre message…'**
  String get msgHint;

  /// No description provided for @msgHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n}h'**
  String msgHoursAgo(Object n);

  /// No description provided for @msgMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} min'**
  String msgMinutesAgo(Object n);

  /// No description provided for @msgNow.
  ///
  /// In fr, this message translates to:
  /// **'maintenant'**
  String get msgNow;

  /// No description provided for @msgRoleUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get msgRoleUser;

  /// No description provided for @msgStartConversation.
  ///
  /// In fr, this message translates to:
  /// **'Commencez la conversation.'**
  String get msgStartConversation;

  /// No description provided for @msgTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get msgTitle;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get noAccountYet;

  /// No description provided for @orContinueWith.
  ///
  /// In fr, this message translates to:
  /// **'ou continuer avec'**
  String get orContinueWith;

  /// No description provided for @parentAddChildEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email de l\'enfant *'**
  String get parentAddChildEmailLabel;

  /// No description provided for @parentAddChildIntro.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'adresse email du compte WinPlus de votre enfant pour le lier à votre espace parent.'**
  String get parentAddChildIntro;

  /// No description provided for @parentAddChildInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un email valide.'**
  String get parentAddChildInvalidEmail;

  /// No description provided for @parentAddChildLink.
  ///
  /// In fr, this message translates to:
  /// **'Lier l\'enfant'**
  String get parentAddChildLink;

  /// No description provided for @parentAddChildNoCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan n\'ouvre pas le catalogue à vos enfants.'**
  String get parentAddChildNoCatalog;

  /// No description provided for @parentAddChildNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève trouvé avec cet email, ou déjà lié.'**
  String get parentAddChildNotFound;

  /// No description provided for @parentAddChildPlanLimit.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan suit {count} {count, plural, =0{enfant} =1{enfant} other{enfants}}, sans catalogue pour eux. Un plan parent ouvre le catalogue et les alertes WinAI.'**
  String parentAddChildPlanLimit(int count);

  /// No description provided for @parentAddChildSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Enfant ajouté à votre compte avec succès.'**
  String get parentAddChildSuccess;

  /// No description provided for @parentAddChildTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un enfant'**
  String get parentAddChildTitle;

  /// No description provided for @parentAiHint.
  ///
  /// In fr, this message translates to:
  /// **'Posez votre question sur la scolarité…'**
  String get parentAiHint;

  /// No description provided for @parentAiSuggestion1.
  ///
  /// In fr, this message translates to:
  /// **'Mon enfant est en difficulté'**
  String get parentAiSuggestion1;

  /// No description provided for @parentAiSuggestion2.
  ///
  /// In fr, this message translates to:
  /// **'Plan de révision maison'**
  String get parentAiSuggestion2;

  /// No description provided for @parentAiSuggestion3.
  ///
  /// In fr, this message translates to:
  /// **'Analyse ses résultats'**
  String get parentAiSuggestion3;

  /// No description provided for @parentAiSuggestion4.
  ///
  /// In fr, this message translates to:
  /// **'Comment le motiver ?'**
  String get parentAiSuggestion4;

  /// No description provided for @parentAiTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton conseiller familial chaleureux'**
  String get parentAiTagline;

  /// No description provided for @parentAlbumGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs de l\'année'**
  String get parentAlbumGoals;

  /// No description provided for @parentAlbumIntensity.
  ///
  /// In fr, this message translates to:
  /// **'Moments d\'intensité'**
  String get parentAlbumIntensity;

  /// No description provided for @parentAlbumMeta.
  ///
  /// In fr, this message translates to:
  /// **'Année scolaire {year} · mis à jour le {date}'**
  String parentAlbumMeta(Object year, Object date);

  /// No description provided for @parentAlbumNotGenerated.
  ///
  /// In fr, this message translates to:
  /// **'L\'album de {name} n\'a pas encore été généré cette année.'**
  String parentAlbumNotGenerated(Object name);

  /// No description provided for @parentAlbumProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression observée'**
  String get parentAlbumProgress;

  /// No description provided for @parentAlbumReportCard.
  ///
  /// In fr, this message translates to:
  /// **'Bulletin'**
  String get parentAlbumReportCard;

  /// No description provided for @parentAlbumSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Matières travaillées'**
  String get parentAlbumSubjects;

  /// No description provided for @parentAlbumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Album de l\'année de {name}'**
  String parentAlbumTitle(Object name);

  /// No description provided for @parentAlbumTopContents.
  ///
  /// In fr, this message translates to:
  /// **'Contenus les plus consultés'**
  String get parentAlbumTopContents;

  /// No description provided for @parentAlertBadgeHigh.
  ///
  /// In fr, this message translates to:
  /// **'Alerte'**
  String get parentAlertBadgeHigh;

  /// No description provided for @parentAlertBadgeInfo.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get parentAlertBadgeInfo;

  /// No description provided for @parentAlertBadgeMedium.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get parentAlertBadgeMedium;

  /// No description provided for @parentAlertsAllGood.
  ///
  /// In fr, this message translates to:
  /// **'Tout va bien pour vos enfants !'**
  String get parentAlertsAllGood;

  /// No description provided for @parentAlertsIntro.
  ///
  /// In fr, this message translates to:
  /// **'WinAI surveille les progrès de vos enfants et vous alerte en temps réel.'**
  String get parentAlertsIntro;

  /// No description provided for @parentAlertsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte active.'**
  String get parentAlertsNone;

  /// No description provided for @parentAlertsRecent.
  ///
  /// In fr, this message translates to:
  /// **'Alertes récentes'**
  String get parentAlertsRecent;

  /// No description provided for @parentAlertsSeeActivity.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'activité'**
  String get parentAlertsSeeActivity;

  /// No description provided for @parentAlertsTip1Text.
  ///
  /// In fr, this message translates to:
  /// **'Encouragez les sessions courtes régulières plutôt que les longues sessions irrégulières. La rétention est bien meilleure.'**
  String get parentAlertsTip1Text;

  /// No description provided for @parentAlertsTip1Title.
  ///
  /// In fr, this message translates to:
  /// **'Sessions courtes et régulières'**
  String get parentAlertsTip1Title;

  /// No description provided for @parentAlertsTip2Text.
  ///
  /// In fr, this message translates to:
  /// **'Les quiz quotidiens améliorent la rétention de 40% par rapport à la lecture passive.'**
  String get parentAlertsTip2Text;

  /// No description provided for @parentAlertsTip2Title.
  ///
  /// In fr, this message translates to:
  /// **'Quiz quotidiens'**
  String get parentAlertsTip2Title;

  /// No description provided for @parentAlertsTip3Text.
  ///
  /// In fr, this message translates to:
  /// **'Fixez un objectif d\'examen précis avec votre enfant  une date et un examen concrets  pour le motiver efficacement.'**
  String get parentAlertsTip3Text;

  /// No description provided for @parentAlertsTip3Title.
  ///
  /// In fr, this message translates to:
  /// **'Objectif clair'**
  String get parentAlertsTip3Title;

  /// No description provided for @parentAlertsTipsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils WinAI'**
  String get parentAlertsTipsTitle;

  /// No description provided for @parentBuyBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible'**
  String get parentBuyBalance;

  /// No description provided for @parentBuyContentForChild.
  ///
  /// In fr, this message translates to:
  /// **'Acheter du contenu pour un enfant'**
  String get parentBuyContentForChild;

  /// No description provided for @parentBuyFor.
  ///
  /// In fr, this message translates to:
  /// **'Acheter pour {name}'**
  String parentBuyFor(Object name);

  /// No description provided for @parentBuyNoContent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu disponible pour le moment.'**
  String get parentBuyNoContent;

  /// No description provided for @parentBuyNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement payant actif : abonnez-vous pour obtenir des crédits à dépenser pour vos enfants.'**
  String get parentBuyNoSubscription;

  /// No description provided for @parentBuyRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Contenu recommandé pour {name}{level}'**
  String parentBuyRecommended(Object name, Object level);

  /// No description provided for @parentBuyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Acheter pour…'**
  String get parentBuyTitle;

  /// No description provided for @parentBuyWhichChild.
  ///
  /// In fr, this message translates to:
  /// **'Pour quel enfant ?'**
  String get parentBuyWhichChild;

  /// No description provided for @parentChildActivityWeek.
  ///
  /// In fr, this message translates to:
  /// **'Activité cette semaine'**
  String get parentChildActivityWeek;

  /// No description provided for @parentChildAiWeek.
  ///
  /// In fr, this message translates to:
  /// **'IA/sem.'**
  String get parentChildAiWeek;

  /// No description provided for @parentChildAllGood.
  ///
  /// In fr, this message translates to:
  /// **'Tout va bien !'**
  String get parentChildAllGood;

  /// No description provided for @parentChildAvgScore30.
  ///
  /// In fr, this message translates to:
  /// **'Score moyen sur 30 jours'**
  String get parentChildAvgScore30;

  /// No description provided for @parentChildAvgScoreShort.
  ///
  /// In fr, this message translates to:
  /// **'Score moy.'**
  String get parentChildAvgScoreShort;

  /// No description provided for @parentChildBestSubject.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure matière'**
  String get parentChildBestSubject;

  /// No description provided for @parentChildCatalogFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue filtré pour {name}'**
  String parentChildCatalogFiltered(Object name);

  /// No description provided for @parentChildDownloadsWeek.
  ///
  /// In fr, this message translates to:
  /// **'Téléch./sem.'**
  String get parentChildDownloadsWeek;

  /// No description provided for @parentChildEncourage.
  ///
  /// In fr, this message translates to:
  /// **'Encourager'**
  String get parentChildEncourage;

  /// No description provided for @parentChildGenerateQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Générer un quiz'**
  String get parentChildGenerateQuiz;

  /// No description provided for @parentChildInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get parentChildInactive;

  /// No description provided for @parentChildLastQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Dernier quiz'**
  String get parentChildLastQuiz;

  /// No description provided for @parentChildNoRecentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité récente.'**
  String get parentChildNoRecentActivity;

  /// No description provided for @parentChildNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de résultats ce mois-ci.'**
  String get parentChildNoResults;

  /// No description provided for @parentChildQuizGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Quiz en cours de génération...'**
  String get parentChildQuizGenerating;

  /// No description provided for @parentChildQuizWeek.
  ///
  /// In fr, this message translates to:
  /// **'Quiz/sem.'**
  String get parentChildQuizWeek;

  /// No description provided for @parentChildRecentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get parentChildRecentActivity;

  /// No description provided for @parentChildRegular.
  ///
  /// In fr, this message translates to:
  /// **'{name} est régulier(e) dans ses révisions.'**
  String parentChildRegular(Object name);

  /// No description provided for @parentChildScoreBySubject.
  ///
  /// In fr, this message translates to:
  /// **'Score moyen par matière (30 jours)'**
  String get parentChildScoreBySubject;

  /// No description provided for @parentChildSeeResources.
  ///
  /// In fr, this message translates to:
  /// **'Voir ressources'**
  String get parentChildSeeResources;

  /// No description provided for @parentChildTabActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get parentChildTabActivity;

  /// No description provided for @parentChildTabAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get parentChildTabAlbum;

  /// No description provided for @parentChildTabExamWatch.
  ///
  /// In fr, this message translates to:
  /// **'Veille examen'**
  String get parentChildTabExamWatch;

  /// No description provided for @parentChildTabGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get parentChildTabGoals;

  /// No description provided for @parentChildTabPortrait.
  ///
  /// In fr, this message translates to:
  /// **'Portrait'**
  String get parentChildTabPortrait;

  /// No description provided for @parentChildToWorkOn.
  ///
  /// In fr, this message translates to:
  /// **'À travailler'**
  String get parentChildToWorkOn;

  /// No description provided for @parentChildrenLimit.
  ///
  /// In fr, this message translates to:
  /// **'{count} {count, plural, =0{enfant} =1{enfant} other{enfants}} max avec votre plan'**
  String parentChildrenLimit(int count);

  /// No description provided for @parentCoveredAll.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan couvre tous vos enfants liés : il n’y a rien à choisir.'**
  String get parentCoveredAll;

  /// No description provided for @parentCoveredBadge.
  ///
  /// In fr, this message translates to:
  /// **'Couvert'**
  String get parentCoveredBadge;

  /// No description provided for @parentCoveredCustom.
  ///
  /// In fr, this message translates to:
  /// **'Choix enregistré'**
  String get parentCoveredCustom;

  /// No description provided for @parentCoveredDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut, les enfants liés en premier sont couverts'**
  String get parentCoveredDefault;

  /// No description provided for @parentCoveredLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Les informations n’ont pas pu être chargées.'**
  String get parentCoveredLoadError;

  /// No description provided for @parentCoveredMore.
  ///
  /// In fr, this message translates to:
  /// **'Couvrir plus d’enfants'**
  String get parentCoveredMore;

  /// No description provided for @parentCoveredNextChange.
  ///
  /// In fr, this message translates to:
  /// **'prochain changement possible le {date}'**
  String parentCoveredNextChange(Object date);

  /// No description provided for @parentCoveredOnePerPeriod.
  ///
  /// In fr, this message translates to:
  /// **'un changement par période d’abonnement'**
  String get parentCoveredOnePerPeriod;

  /// No description provided for @parentCoveredSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le choix'**
  String get parentCoveredSave;

  /// No description provided for @parentCoveredSaved.
  ///
  /// In fr, this message translates to:
  /// **'Votre choix est enregistré : il s’applique tout de suite.'**
  String get parentCoveredSaved;

  /// No description provided for @parentCoveredSubMany.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan couvre {max} enfants sur {total} liés : catalogue, bonus WinAI et alertes.'**
  String parentCoveredSubMany(Object max, Object total);

  /// No description provided for @parentCoveredSubOne.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan couvre {max} enfant sur {total} liés : catalogue, bonus WinAI et alertes.'**
  String parentCoveredSubOne(Object max, Object total);

  /// No description provided for @parentCoveredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enfants couverts'**
  String get parentCoveredTitle;

  /// No description provided for @parentCoveredUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan couvre jusqu’à {count} {count, plural, =0{enfant} =1{enfant} other{enfants}} et tous vos enfants liés sont couverts.'**
  String parentCoveredUpTo(int count);

  /// No description provided for @parentDashAlertsAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Alertes & conseils WinAI'**
  String get parentDashAlertsAdvice;

  /// No description provided for @parentDashBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get parentDashBalance;

  /// No description provided for @parentDashChildrenFollowed.
  ///
  /// In fr, this message translates to:
  /// **'enfants suivis'**
  String get parentDashChildrenFollowed;

  /// No description provided for @parentDashCreditsAvail.
  ///
  /// In fr, this message translates to:
  /// **'crédits dispo'**
  String get parentDashCreditsAvail;

  /// No description provided for @parentDashCreditsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Dont {allocation} XAF de dotation du plan et {topups} XAF de recharges'**
  String parentDashCreditsDetail(Object allocation, Object topups);

  /// No description provided for @parentDashCreditsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Crédits disponibles'**
  String get parentDashCreditsTitle;

  /// No description provided for @parentDashLoadingBalance.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du solde…'**
  String get parentDashLoadingBalance;

  /// No description provided for @parentDashNoChild.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant suivi. Ajoutez un enfant depuis l\'onglet Enfants.'**
  String get parentDashNoChild;

  /// No description provided for @parentDashNoCredits.
  ///
  /// In fr, this message translates to:
  /// **'Aucun crédit : les crédits sont versés avec un abonnement parent actif.'**
  String get parentDashNoCredits;

  /// No description provided for @parentDashPeriodEndIn.
  ///
  /// In fr, this message translates to:
  /// **'Plan {plan} · Fin de période dans {days} jours'**
  String parentDashPeriodEndIn(Object plan, Object days);

  /// No description provided for @parentDashRenewalEvent.
  ///
  /// In fr, this message translates to:
  /// **'Fin de période · plan {plan}'**
  String parentDashRenewalEvent(Object plan);

  /// No description provided for @parentDashSeeSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'abonnement'**
  String get parentDashSeeSubscription;

  /// No description provided for @parentDashUpcomingEvents.
  ///
  /// In fr, this message translates to:
  /// **'Évènements à venir'**
  String get parentDashUpcomingEvents;

  /// No description provided for @parentDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} {count, plural, =0{jour} =1{jour} other{jours}}'**
  String parentDaysAgo(int count);

  /// No description provided for @parentEncourageChooseTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un modèle'**
  String get parentEncourageChooseTemplate;

  /// No description provided for @parentEncourageHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre message...'**
  String get parentEncourageHint;

  /// No description provided for @parentEncourageOrWrite.
  ///
  /// In fr, this message translates to:
  /// **'Ou écrire un message personnalisé'**
  String get parentEncourageOrWrite;

  /// No description provided for @parentEncourageSendError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le message. Réessayez.'**
  String get parentEncourageSendError;

  /// No description provided for @parentEncourageSent.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé à {name} !'**
  String parentEncourageSent(Object name);

  /// No description provided for @parentEncourageSub.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un message ou écrivez le vôtre'**
  String get parentEncourageSub;

  /// No description provided for @parentEncourageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encourager {name}'**
  String parentEncourageTitle(Object name);

  /// No description provided for @parentEncourageTpl1.
  ///
  /// In fr, this message translates to:
  /// **'Continue comme ça {name}, je suis fier(e) de toi !'**
  String parentEncourageTpl1(Object name);

  /// No description provided for @parentEncourageTpl2.
  ///
  /// In fr, this message translates to:
  /// **'N\'oublie pas de réviser la Chimie ce soir {name} !'**
  String parentEncourageTpl2(Object name);

  /// No description provided for @parentEncourageTpl3.
  ///
  /// In fr, this message translates to:
  /// **'{name}, tu peux le faire  le BAC approche !'**
  String parentEncourageTpl3(Object name);

  /// No description provided for @parentEncourageTpl4.
  ///
  /// In fr, this message translates to:
  /// **'{name}, {score} cette semaine, c\'est excellent !'**
  String parentEncourageTpl4(Object name, Object score);

  /// No description provided for @parentEncourageYourScore.
  ///
  /// In fr, this message translates to:
  /// **'ton score'**
  String get parentEncourageYourScore;

  /// No description provided for @parentEventInDays.
  ///
  /// In fr, this message translates to:
  /// **'dans {count} {count, plural, =0{jour} =1{jour} other{jours}}'**
  String parentEventInDays(int count);

  /// No description provided for @parentEventToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get parentEventToday;

  /// No description provided for @parentGoalActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs actifs co-construits'**
  String get parentGoalActiveTitle;

  /// No description provided for @parentGoalDeadlineOn.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String parentGoalDeadlineOn(Object date);

  /// No description provided for @parentGoalFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get parentGoalFieldDescription;

  /// No description provided for @parentGoalIntro.
  ///
  /// In fr, this message translates to:
  /// **'Votre proposition attend l\'accord de votre enfant : il peut l\'accepter telle quelle, l\'ajuster, ou la refuser.'**
  String get parentGoalIntro;

  /// No description provided for @parentGoalNoActive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif co-construit actif pour le moment.'**
  String get parentGoalNoActive;

  /// No description provided for @parentGoalNoPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition en attente de réponse.'**
  String get parentGoalNoPending;

  /// No description provided for @parentGoalPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propositions en attente'**
  String get parentGoalPendingTitle;

  /// No description provided for @parentGoalProposeTo.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un objectif à {name}'**
  String parentGoalProposeTo(Object name);

  /// No description provided for @parentGoalSent.
  ///
  /// In fr, this message translates to:
  /// **'Proposition envoyée.'**
  String get parentGoalSent;

  /// No description provided for @parentGoalSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Proposer l\'objectif'**
  String get parentGoalSubmit;

  /// No description provided for @parentGoalSubmitError.
  ///
  /// In fr, this message translates to:
  /// **'La proposition n\'a pas pu être envoyée. Réessayez.'**
  String get parentGoalSubmitError;

  /// No description provided for @parentGoalTypeAcademic.
  ///
  /// In fr, this message translates to:
  /// **'Scolaire'**
  String get parentGoalTypeAcademic;

  /// No description provided for @parentGoalTypePersonal.
  ///
  /// In fr, this message translates to:
  /// **'Personnel'**
  String get parentGoalTypePersonal;

  /// No description provided for @parentGoalTypeSkill.
  ///
  /// In fr, this message translates to:
  /// **'Compétence'**
  String get parentGoalTypeSkill;

  /// No description provided for @parentNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Sans abonnement'**
  String get parentNoSubscription;

  /// No description provided for @parentPayStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'échoué'**
  String get parentPayStatusFailed;

  /// No description provided for @parentPayStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'en attente'**
  String get parentPayStatusPending;

  /// No description provided for @parentPayStatusRefundRequested.
  ///
  /// In fr, this message translates to:
  /// **'remboursement demandé'**
  String get parentPayStatusRefundRequested;

  /// No description provided for @parentPayStatusRefunded.
  ///
  /// In fr, this message translates to:
  /// **'remboursé'**
  String get parentPayStatusRefunded;

  /// No description provided for @parentPaymentsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement pour le moment. Vos achats, abonnements et recharges apparaîtront ici.'**
  String get parentPaymentsEmpty;

  /// No description provided for @parentPaymentsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'L\'historique n\'a pas pu être chargé.'**
  String get parentPaymentsLoadError;

  /// No description provided for @parentPaymentsMonthSpent.
  ///
  /// In fr, this message translates to:
  /// **'DÉPENSES CE MOIS'**
  String get parentPaymentsMonthSpent;

  /// No description provided for @parentPaymentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get parentPaymentsTitle;

  /// No description provided for @parentPlanName.
  ///
  /// In fr, this message translates to:
  /// **'Plan {plan}'**
  String parentPlanName(Object plan);

  /// No description provided for @parentPortfolioAutonomy.
  ///
  /// In fr, this message translates to:
  /// **'Autonomie'**
  String get parentPortfolioAutonomy;

  /// No description provided for @parentPortfolioCuriosity.
  ///
  /// In fr, this message translates to:
  /// **'Curiosité'**
  String get parentPortfolioCuriosity;

  /// No description provided for @parentPortfolioNoAutonomy.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données d\'autonomie pour {name}.'**
  String parentPortfolioNoAutonomy(Object name);

  /// No description provided for @parentPortfolioNoCuriosity.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données de curiosité pour {name}.'**
  String parentPortfolioNoCuriosity(Object name);

  /// No description provided for @parentPortfolioNoRegularity.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données de régularité pour {name}.'**
  String parentPortfolioNoRegularity(Object name);

  /// No description provided for @parentPortfolioNotYet.
  ///
  /// In fr, this message translates to:
  /// **'Le portrait de {name} sera disponible après le premier calcul mensuel.'**
  String parentPortfolioNotYet(Object name);

  /// No description provided for @parentPortfolioRegularity.
  ///
  /// In fr, this message translates to:
  /// **'Régularité'**
  String get parentPortfolioRegularity;

  /// No description provided for @parentPortfolioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Portrait de {name}'**
  String parentPortfolioTitle(Object name);

  /// No description provided for @parentPortfolioUpdatedOn.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour le {date}'**
  String parentPortfolioUpdatedOn(Object date);

  /// No description provided for @parentProfileCovered.
  ///
  /// In fr, this message translates to:
  /// **'Enfants couverts par mon plan'**
  String get parentProfileCovered;

  /// No description provided for @parentProfileCredits.
  ///
  /// In fr, this message translates to:
  /// **'Crédits'**
  String get parentProfileCredits;

  /// No description provided for @parentProfileManageSub.
  ///
  /// In fr, this message translates to:
  /// **'Gérer l\'abonnement'**
  String get parentProfileManageSub;

  /// No description provided for @parentProfileMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get parentProfileMyAccount;

  /// No description provided for @parentProfilePayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements & historique'**
  String get parentProfilePayments;

  /// No description provided for @parentProfileTutoring.
  ///
  /// In fr, this message translates to:
  /// **'Cours particuliers de mes enfants'**
  String get parentProfileTutoring;

  /// No description provided for @parentResourcesIntro.
  ///
  /// In fr, this message translates to:
  /// **'D\'après les résultats de vos enfants, ces ressources cibleront leurs points faibles.'**
  String get parentResourcesIntro;

  /// No description provided for @parentResourcesRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Recommandées par WinAI'**
  String get parentResourcesRecommended;

  /// No description provided for @parentSubAiFree.
  ///
  /// In fr, this message translates to:
  /// **'Usage WinAI du plan gratuit'**
  String get parentSubAiFree;

  /// No description provided for @parentSubAiMultiplier.
  ///
  /// In fr, this message translates to:
  /// **'{n}x plus d\'usage WinAI que le plan gratuit'**
  String parentSubAiMultiplier(Object n);

  /// No description provided for @parentSubAutoRenewOn.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique activé'**
  String get parentSubAutoRenewOn;

  /// No description provided for @parentSubBackToFree.
  ///
  /// In fr, this message translates to:
  /// **'Vous repasserez sur l\'offre gratuite.'**
  String get parentSubBackToFree;

  /// No description provided for @parentSubCancel.
  ///
  /// In fr, this message translates to:
  /// **'Résilier'**
  String get parentSubCancel;

  /// No description provided for @parentSubCancelChange.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce changement'**
  String get parentSubCancelChange;

  /// No description provided for @parentSubCancelConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résilier ?'**
  String get parentSubCancelConfirmTitle;

  /// No description provided for @parentSubCancelledUntil.
  ///
  /// In fr, this message translates to:
  /// **'Résilié : accès jusqu\'au {date}'**
  String parentSubCancelledUntil(Object date);

  /// No description provided for @parentSubChangePlan.
  ///
  /// In fr, this message translates to:
  /// **'Changer de plan'**
  String get parentSubChangePlan;

  /// No description provided for @parentSubChildrenFollowed.
  ///
  /// In fr, this message translates to:
  /// **'Enfants suivis'**
  String get parentSubChildrenFollowed;

  /// No description provided for @parentSubDisableAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le renouvellement automatique'**
  String get parentSubDisableAutoRenew;

  /// No description provided for @parentSubEnableAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler automatiquement avec mon solde'**
  String get parentSubEnableAutoRenew;

  /// No description provided for @parentSubFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get parentSubFailed;

  /// No description provided for @parentSubIncludes.
  ///
  /// In fr, this message translates to:
  /// **'Ce que comprend votre plan'**
  String get parentSubIncludes;

  /// No description provided for @parentSubKeepAccessUntil.
  ///
  /// In fr, this message translates to:
  /// **'Vous gardez l\'accès jusqu\'au {date}, sans remboursement de la période en cours.'**
  String parentSubKeepAccessUntil(Object date);

  /// No description provided for @parentSubLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte'**
  String get parentSubLimitReached;

  /// No description provided for @parentSubLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'abonnement.'**
  String get parentSubLoadError;

  /// No description provided for @parentSubManualRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement manuel'**
  String get parentSubManualRenew;

  /// No description provided for @parentSubMyChildren.
  ///
  /// In fr, this message translates to:
  /// **'Mes enfants'**
  String get parentSubMyChildren;

  /// No description provided for @parentSubNoPayment.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement enregistré pour l\'instant.'**
  String get parentSubNoPayment;

  /// No description provided for @parentSubPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get parentSubPaid;

  /// No description provided for @parentSubPaymentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des paiements'**
  String get parentSubPaymentHistory;

  /// No description provided for @parentSubPaymentPending.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente'**
  String get parentSubPaymentPending;

  /// No description provided for @parentSubPendingSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Passage à {plan} programmé à l\'échéance.'**
  String parentSubPendingSwitch(Object plan);

  /// No description provided for @parentSubPeriodUntil.
  ///
  /// In fr, this message translates to:
  /// **'Période en cours jusqu\'au {date}'**
  String parentSubPeriodUntil(Object date);

  /// No description provided for @parentSubRenewNow.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler maintenant'**
  String get parentSubRenewNow;

  /// No description provided for @parentSubResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre l\'abonnement'**
  String get parentSubResume;

  /// No description provided for @parentSubTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon Abonnement'**
  String get parentSubTitle;

  /// No description provided for @parentSubTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get parentSubTrial;

  /// No description provided for @parentWatchActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer la veille'**
  String get parentWatchActivate;

  /// No description provided for @parentWatchActivateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'activer la veille pour le moment.'**
  String get parentWatchActivateError;

  /// No description provided for @parentWatchBeforeExam.
  ///
  /// In fr, this message translates to:
  /// **'avant l\'examen'**
  String get parentWatchBeforeExam;

  /// No description provided for @parentWatchCountdown.
  ///
  /// In fr, this message translates to:
  /// **'J-{n}'**
  String parentWatchCountdown(Object n);

  /// No description provided for @parentWatchDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la veille'**
  String get parentWatchDeactivate;

  /// No description provided for @parentWatchDeactivateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de désactiver la veille pour le moment.'**
  String get parentWatchDeactivateError;

  /// No description provided for @parentWatchExamDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de l\'examen'**
  String get parentWatchExamDate;

  /// No description provided for @parentWatchExamOn.
  ///
  /// In fr, this message translates to:
  /// **'Examen le {date}'**
  String parentWatchExamOn(Object date);

  /// No description provided for @parentWatchExamType.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'examen'**
  String get parentWatchExamType;

  /// No description provided for @parentWatchExamTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : BEPC, Baccalauréat série C…'**
  String get parentWatchExamTypeHint;

  /// No description provided for @parentWatchFormRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un type d\'examen et une date.'**
  String get parentWatchFormRequired;

  /// No description provided for @parentWatchIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un suivi rapproché pendant la période d\'examen : WinAI adapte ses conseils et vous propose des questions pertinentes dans l\'assistant familial.'**
  String get parentWatchIntro;

  /// No description provided for @parentWatchSubmitError.
  ///
  /// In fr, this message translates to:
  /// **'La veille n\'a pas pu être activée. Réessayez.'**
  String get parentWatchSubmitError;

  /// No description provided for @parentWatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Veille d\'examen'**
  String get parentWatchTitle;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @roleInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get roleInstitution;

  /// No description provided for @roleParent.
  ///
  /// In fr, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleStudent.
  ///
  /// In fr, this message translates to:
  /// **'Élève'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In fr, this message translates to:
  /// **'Professeur'**
  String get roleTeacher;

  /// No description provided for @roleTutor.
  ///
  /// In fr, this message translates to:
  /// **'Répétiteur'**
  String get roleTutor;

  /// No description provided for @shellTabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get shellTabAccount;

  /// No description provided for @shellTabAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Analytics'**
  String get shellTabAnalytics;

  /// No description provided for @shellTabCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get shellTabCatalog;

  /// No description provided for @shellTabChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get shellTabChildren;

  /// No description provided for @shellTabContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus'**
  String get shellTabContent;

  /// No description provided for @shellTabEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get shellTabEarnings;

  /// No description provided for @shellTabGroups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get shellTabGroups;

  /// No description provided for @shellTabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get shellTabHome;

  /// No description provided for @shellTabMe.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get shellTabMe;

  /// No description provided for @shellTabMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get shellTabMessages;

  /// No description provided for @shellTabMySpace.
  ///
  /// In fr, this message translates to:
  /// **'Mon Espace'**
  String get shellTabMySpace;

  /// No description provided for @shellTabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get shellTabProfile;

  /// No description provided for @shellTabResources.
  ///
  /// In fr, this message translates to:
  /// **'Ressources'**
  String get shellTabResources;

  /// No description provided for @shellTabSessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions'**
  String get shellTabSessions;

  /// No description provided for @shellTabStudents.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants'**
  String get shellTabStudents;

  /// No description provided for @shopAccountRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous ou créez un compte avant le paiement : le contenu acheté est rattaché à votre compte et reste accessible sur tous vos appareils.'**
  String get shopAccountRequiredBody;

  /// No description provided for @shopAccountRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un compte est nécessaire pour acheter'**
  String get shopAccountRequiredTitle;

  /// No description provided for @shopAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get shopAmount;

  /// No description provided for @shopApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get shopApply;

  /// No description provided for @shopAwaitingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation…'**
  String get shopAwaitingConfirmation;

  /// No description provided for @shopBackToCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Retour au catalogue'**
  String get shopBackToCatalog;

  /// No description provided for @shopBuy.
  ///
  /// In fr, this message translates to:
  /// **'Acheter'**
  String get shopBuy;

  /// No description provided for @shopBuyFromAccountBody.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement dans l\'application arrive bientôt. En attendant, achetez ce contenu depuis votre compte sur winplus.cm avec les mêmes identifiants : il sera ensuite disponible ici.'**
  String get shopBuyFromAccountBody;

  /// No description provided for @shopBuyFromAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat depuis votre compte'**
  String get shopBuyFromAccountTitle;

  /// No description provided for @shopCartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide.'**
  String get shopCartEmpty;

  /// No description provided for @shopCartLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le panier.'**
  String get shopCartLoadFailed;

  /// No description provided for @shopCartRemoveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer cet article.'**
  String get shopCartRemoveFailed;

  /// No description provided for @shopCartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon panier'**
  String get shopCartTitle;

  /// No description provided for @shopCheckNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get shopCheckNow;

  /// No description provided for @shopCheckoutStepConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get shopCheckoutStepConfirm;

  /// No description provided for @shopCheckoutStepSummary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif & paiement'**
  String get shopCheckoutStepSummary;

  /// No description provided for @shopContentAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Vos contenus sont maintenant disponibles.'**
  String get shopContentAvailable;

  /// No description provided for @shopExploreCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Explorer le catalogue'**
  String get shopExploreCatalog;

  /// No description provided for @shopInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get shopInvalidPhone;

  /// No description provided for @shopInvoiceLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la facture.'**
  String get shopInvoiceLoadFailed;

  /// No description provided for @shopInvoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facture {number}'**
  String shopInvoiceTitle(Object number);

  /// No description provided for @shopItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get shopItems;

  /// No description provided for @shopItemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 article} =1{1 article} other{{count} articles}}'**
  String shopItemsCount(int count);

  /// No description provided for @shopMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get shopMyOrders;

  /// No description provided for @shopNoOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande pour le moment.'**
  String get shopNoOrders;

  /// No description provided for @shopOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get shopOrder;

  /// No description provided for @shopOrderCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get shopOrderCancelled;

  /// No description provided for @shopOrderFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get shopOrderFailed;

  /// No description provided for @shopOrderPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get shopOrderPaid;

  /// No description provided for @shopOrderRefundRequested.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement demandé'**
  String get shopOrderRefundRequested;

  /// No description provided for @shopOrderRefunded.
  ///
  /// In fr, this message translates to:
  /// **'Remboursée'**
  String get shopOrderRefunded;

  /// No description provided for @shopPayAmount.
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount} XAF'**
  String shopPayAmount(Object amount);

  /// No description provided for @shopPaymentConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé !'**
  String get shopPaymentConfirmed;

  /// No description provided for @shopPaymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get shopPaymentFailed;

  /// No description provided for @shopPaymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get shopPaymentMethod;

  /// No description provided for @shopPaymentNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas pu être confirmé.'**
  String get shopPaymentNotConfirmed;

  /// No description provided for @shopPhoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get shopPhoneNumber;

  /// No description provided for @shopPlaceOrder.
  ///
  /// In fr, this message translates to:
  /// **'Passer la commande'**
  String get shopPlaceOrder;

  /// No description provided for @shopPromoApplied.
  ///
  /// In fr, this message translates to:
  /// **'Réduction appliquée : -{amount} XAF'**
  String shopPromoApplied(Object amount);

  /// No description provided for @shopPromoCode.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get shopPromoCode;

  /// No description provided for @shopReference.
  ///
  /// In fr, this message translates to:
  /// **'Réf. : {ref}'**
  String shopReference(Object ref);

  /// No description provided for @shopRefundFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la demande.'**
  String get shopRefundFailed;

  /// No description provided for @shopRefundSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande de remboursement envoyée.'**
  String get shopRefundSent;

  /// No description provided for @shopRequestRefund.
  ///
  /// In fr, this message translates to:
  /// **'Demander un remboursement'**
  String get shopRequestRefund;

  /// No description provided for @shopSeeMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes commandes'**
  String get shopSeeMyOrders;

  /// No description provided for @shopSlowPayment.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement met plus de temps que prévu. Vous pouvez vérifier plus tard dans \"Mes commandes\".'**
  String get shopSlowPayment;

  /// No description provided for @shopStillPending.
  ///
  /// In fr, this message translates to:
  /// **'Toujours en attente'**
  String get shopStillPending;

  /// No description provided for @shopSubjectFallback.
  ///
  /// In fr, this message translates to:
  /// **'Sujet #{id}'**
  String shopSubjectFallback(Object id);

  /// No description provided for @shopSubtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get shopSubtotal;

  /// No description provided for @shopTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get shopTotal;

  /// No description provided for @shopTotalTtc.
  ///
  /// In fr, this message translates to:
  /// **'Total TTC'**
  String get shopTotalTtc;

  /// No description provided for @shopUnexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue. Réessayez.'**
  String get shopUnexpectedError;

  /// No description provided for @shopUssdNotice.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez une notification USSD pour valider.'**
  String get shopUssdNotice;

  /// No description provided for @shopValidateUssd.
  ///
  /// In fr, this message translates to:
  /// **'Valide le paiement via le message USSD envoyé sur ton téléphone.'**
  String get shopValidateUssd;

  /// No description provided for @shopVatIncluded.
  ///
  /// In fr, this message translates to:
  /// **'dont TVA 19,25 % incluse'**
  String get shopVatIncluded;

  /// No description provided for @shopViewInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Voir la facture'**
  String get shopViewInvoice;

  /// No description provided for @studentAchBadgesUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'{unlocked} / {total} badges débloqués'**
  String studentAchBadgesUnlocked(Object unlocked, Object total);

  /// No description provided for @studentAchCurrentStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série actuelle'**
  String get studentAchCurrentStreak;

  /// No description provided for @studentAchLocked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillé'**
  String get studentAchLocked;

  /// No description provided for @studentAchMyBadges.
  ///
  /// In fr, this message translates to:
  /// **'Mes badges'**
  String get studentAchMyBadges;

  /// No description provided for @studentAchStreakDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} jours consécutifs} other{{count} jours consécutifs}}'**
  String studentAchStreakDays(int count);

  /// No description provided for @studentAchStreakLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ta série réelle. La série ci-dessous peut ne pas être à jour.'**
  String get studentAchStreakLoadError;

  /// No description provided for @studentAchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achievements'**
  String get studentAchTitle;

  /// No description provided for @studentAchUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Débloqué'**
  String get studentAchUnlocked;

  /// No description provided for @studentCatalogAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès'**
  String get studentCatalogAccess;

  /// No description provided for @studentCatalogAllAccess.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get studentCatalogAllAccess;

  /// No description provided for @studentCatalogApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get studentCatalogApply;

  /// No description provided for @studentCatalogCatSciences.
  ///
  /// In fr, this message translates to:
  /// **'Sciences'**
  String get studentCatalogCatSciences;

  /// No description provided for @studentCatalogEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formation trouvée.'**
  String get studentCatalogEmpty;

  /// No description provided for @studentCatalogFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get studentCatalogFilters;

  /// No description provided for @studentCatalogLevelAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'avancé'**
  String get studentCatalogLevelAdvanced;

  /// No description provided for @studentCatalogLevelBeginner.
  ///
  /// In fr, this message translates to:
  /// **'débutant'**
  String get studentCatalogLevelBeginner;

  /// No description provided for @studentCatalogLevelIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'intermédiaire'**
  String get studentCatalogLevelIntermediate;

  /// No description provided for @studentCatalogLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Charger plus'**
  String get studentCatalogLoadMore;

  /// No description provided for @studentCatalogPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payant'**
  String get studentCatalogPaid;

  /// No description provided for @studentCatalogPriceTtc.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF TTC'**
  String studentCatalogPriceTtc(Object amount);

  /// No description provided for @studentCatalogReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get studentCatalogReset;

  /// No description provided for @studentCatalogSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une formation…'**
  String get studentCatalogSearchHint;

  /// No description provided for @studentCertCourses.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get studentCertCourses;

  /// No description provided for @studentCertDownloadPdf.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger PDF'**
  String get studentCertDownloadPdf;

  /// No description provided for @studentCertEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun certificat pour l\'instant'**
  String get studentCertEmpty;

  /// No description provided for @studentCertEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Complétez des quiz et des parcours pour\ndécrocher vos premiers certificats.'**
  String get studentCertEmptyHint;

  /// No description provided for @studentCertIssuedOn.
  ///
  /// In fr, this message translates to:
  /// **'Délivré le {date}'**
  String studentCertIssuedOn(Object date);

  /// No description provided for @studentCertLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les certificats.'**
  String get studentCertLoadError;

  /// No description provided for @studentCertMentionGood.
  ///
  /// In fr, this message translates to:
  /// **'Mention Bien'**
  String get studentCertMentionGood;

  /// No description provided for @studentCertMentionVeryGood.
  ///
  /// In fr, this message translates to:
  /// **'Mention Très Bien'**
  String get studentCertMentionVeryGood;

  /// No description provided for @studentCertPapersAndPaths.
  ///
  /// In fr, this message translates to:
  /// **'Épreuves et parcours'**
  String get studentCertPapersAndPaths;

  /// No description provided for @studentCertPdfLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Le certificat n\'a pas pu être chargé.'**
  String get studentCertPdfLoadError;

  /// No description provided for @studentCertSeePdf.
  ///
  /// In fr, this message translates to:
  /// **'Voir le certificat (PDF)'**
  String get studentCertSeePdf;

  /// No description provided for @studentCertShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get studentCertShare;

  /// No description provided for @studentCertTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Certificats'**
  String get studentCertTitle;

  /// No description provided for @studentCertVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification : {code}'**
  String studentCertVerificationCode(Object code);

  /// No description provided for @studentCoachCompletion.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% du plan complété'**
  String studentCoachCompletion(Object pct);

  /// No description provided for @studentCoachDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{days} j restants'**
  String studentCoachDaysLeft(Object days);

  /// No description provided for @studentCoachDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get studentCoachDeleteBody;

  /// No description provided for @studentCoachDeletePlan.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le plan'**
  String get studentCoachDeletePlan;

  /// No description provided for @studentCoachDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce plan ?'**
  String get studentCoachDeleteTitle;

  /// No description provided for @studentCoachExamDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de l\'examen'**
  String get studentCoachExamDate;

  /// No description provided for @studentCoachGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Générer mon plan avec WinAI'**
  String get studentCoachGenerate;

  /// No description provided for @studentCoachGenerateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le plan. Réessaie dans un instant.'**
  String get studentCoachGenerateError;

  /// No description provided for @studentCoachGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération…'**
  String get studentCoachGenerating;

  /// No description provided for @studentCoachHoursPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Heures d\'étude par jour'**
  String get studentCoachHoursPerDay;

  /// No description provided for @studentCoachIntro.
  ///
  /// In fr, this message translates to:
  /// **'WinAI génère un planning jour par jour adapté à ta date d\'examen et ton rythme.'**
  String get studentCoachIntro;

  /// No description provided for @studentCoachLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton plan. Vérifie ta connexion.'**
  String get studentCoachLoadError;

  /// No description provided for @studentCoachLocked.
  ///
  /// In fr, this message translates to:
  /// **'Disponible à partir du plan Standard.\nWinAI génère un planning adapté à tes lacunes.'**
  String get studentCoachLocked;

  /// No description provided for @studentCoachMarkToday.
  ///
  /// In fr, this message translates to:
  /// **'Marquer la session du jour comme faite'**
  String get studentCoachMarkToday;

  /// No description provided for @studentCoachNoWeek.
  ///
  /// In fr, this message translates to:
  /// **'Planning indisponible pour cette semaine.'**
  String get studentCoachNoWeek;

  /// No description provided for @studentCoachPickDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get studentCoachPickDate;

  /// No description provided for @studentCoachReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité du plan : {value}%'**
  String studentCoachReliability(Object value);

  /// No description provided for @studentCoachRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get studentCoachRest;

  /// No description provided for @studentCoachSeePlans.
  ///
  /// In fr, this message translates to:
  /// **'Voir les plans'**
  String get studentCoachSeePlans;

  /// No description provided for @studentCoachTargetExam.
  ///
  /// In fr, this message translates to:
  /// **'Examen cible'**
  String get studentCoachTargetExam;

  /// No description provided for @studentCoachThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get studentCoachThisWeek;

  /// No description provided for @studentCoachTodayDay.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui · J{day}'**
  String studentCoachTodayDay(Object day);

  /// No description provided for @studentCoachTodayDone.
  ///
  /// In fr, this message translates to:
  /// **'Session du jour complétée'**
  String get studentCoachTodayDone;

  /// No description provided for @studentCourseBuy.
  ///
  /// In fr, this message translates to:
  /// **'Acheter la formation'**
  String get studentCourseBuy;

  /// No description provided for @studentCourseBuyNote.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF TTC (TVA 19,25 % incluse). Formation vendue seule, accès à vie dès la confirmation du paiement.'**
  String studentCourseBuyNote(Object amount);

  /// No description provided for @studentCourseCertIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de réussite inclus'**
  String get studentCourseCertIncluded;

  /// No description provided for @studentCourseContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get studentCourseContent;

  /// No description provided for @studentCourseContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la formation'**
  String get studentCourseContinue;

  /// No description provided for @studentCourseCurriculumSummary.
  ///
  /// In fr, this message translates to:
  /// **'{sections} sections · {lessons} leçons · {duration}'**
  String studentCourseCurriculumSummary(
      Object sections, Object lessons, Object duration);

  /// No description provided for @studentCourseEnrolError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'inscription.'**
  String get studentCourseEnrolError;

  /// No description provided for @studentCourseEnrolled.
  ///
  /// In fr, this message translates to:
  /// **'{n} inscrits'**
  String studentCourseEnrolled(Object n);

  /// No description provided for @studentCourseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get studentCourseError;

  /// No description provided for @studentCourseLeaveReview.
  ///
  /// In fr, this message translates to:
  /// **'Donnez votre avis'**
  String get studentCourseLeaveReview;

  /// No description provided for @studentCourseLessons.
  ///
  /// In fr, this message translates to:
  /// **'{n} leçons'**
  String studentCourseLessons(Object n);

  /// No description provided for @studentCourseNoChild.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant n\'est rattaché à votre compte.'**
  String get studentCourseNoChild;

  /// No description provided for @studentCourseNoReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour le moment.'**
  String get studentCourseNoReviews;

  /// No description provided for @studentCourseNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Formation introuvable.'**
  String get studentCourseNotFound;

  /// No description provided for @studentCourseObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous apprendrez'**
  String get studentCourseObjectives;

  /// No description provided for @studentCourseOfferChild.
  ///
  /// In fr, this message translates to:
  /// **'Offrir à mon enfant'**
  String get studentCourseOfferChild;

  /// No description provided for @studentCourseOfferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Offrir « {title} » ({amount} XAF TTC, débité du portefeuille)'**
  String studentCourseOfferTitle(Object title, Object amount);

  /// No description provided for @studentCourseOffered.
  ///
  /// In fr, this message translates to:
  /// **'Formation offerte à {name} : accès ouvert.'**
  String studentCourseOffered(Object name);

  /// No description provided for @studentCoursePayBalance.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec mon solde WinPlus'**
  String get studentCoursePayBalance;

  /// No description provided for @studentCoursePayMomo.
  ///
  /// In fr, this message translates to:
  /// **'Payer par Mobile Money'**
  String get studentCoursePayMomo;

  /// No description provided for @studentCoursePostReview.
  ///
  /// In fr, this message translates to:
  /// **'Publier mon avis'**
  String get studentCoursePostReview;

  /// No description provided for @studentCoursePreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get studentCoursePreview;

  /// No description provided for @studentCoursePurchased.
  ///
  /// In fr, this message translates to:
  /// **'Formation achetée : elle est dans « Mes formations ».'**
  String get studentCoursePurchased;

  /// No description provided for @studentCoursePurchasedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Achetée'**
  String get studentCoursePurchasedBadge;

  /// No description provided for @studentCoursePurchasedStart.
  ///
  /// In fr, this message translates to:
  /// **'Achetée : commencer'**
  String get studentCoursePurchasedStart;

  /// No description provided for @studentCourseRequirements.
  ///
  /// In fr, this message translates to:
  /// **'Prérequis'**
  String get studentCourseRequirements;

  /// No description provided for @studentCourseReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience (optionnel)…'**
  String get studentCourseReviewHint;

  /// No description provided for @studentCourseReviewSubmitError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la soumission.'**
  String get studentCourseReviewSubmitError;

  /// No description provided for @studentCourseReviewThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get studentCourseReviewThanks;

  /// No description provided for @studentCourseReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get studentCourseReviews;

  /// No description provided for @studentCourseStartFree.
  ///
  /// In fr, this message translates to:
  /// **'Commencer gratuitement'**
  String get studentCourseStartFree;

  /// No description provided for @studentCourseVatNote.
  ///
  /// In fr, this message translates to:
  /// **'TTC, TVA 19,25 % incluse · hors abonnement'**
  String get studentCourseVatNote;

  /// No description provided for @studentCourseYours.
  ///
  /// In fr, this message translates to:
  /// **'Votre formation'**
  String get studentCourseYours;

  /// No description provided for @studentDetailAddNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get studentDetailAddNote;

  /// No description provided for @studentDetailAddNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note…'**
  String get studentDetailAddNoteHint;

  /// No description provided for @studentDetailAddToCartError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter au panier.'**
  String get studentDetailAddToCartError;

  /// No description provided for @studentDetailAddToCartPrice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier  {price} XAF'**
  String studentDetailAddToCartPrice(Object price);

  /// No description provided for @studentDetailAddedToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier.'**
  String get studentDetailAddedToCart;

  /// No description provided for @studentDetailBy.
  ///
  /// In fr, this message translates to:
  /// **'Par {teacher}'**
  String studentDetailBy(Object teacher);

  /// No description provided for @studentDetailDefaultDescription.
  ///
  /// In fr, this message translates to:
  /// **'Contenu éducatif de qualité.'**
  String get studentDetailDefaultDescription;

  /// No description provided for @studentDetailDemoNoDocument.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu de démonstration n\'a pas de document à afficher.'**
  String get studentDetailDemoNoDocument;

  /// No description provided for @studentDetailDemoNoSubject.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu de démonstration n\'a pas de sujet réel.'**
  String get studentDetailDemoNoSubject;

  /// No description provided for @studentDetailMyNotes.
  ///
  /// In fr, this message translates to:
  /// **'Mes notes'**
  String get studentDetailMyNotes;

  /// No description provided for @studentDetailNoReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour l\'instant.'**
  String get studentDetailNoReviews;

  /// No description provided for @studentDetailOrSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'ou découvrez les abonnements'**
  String get studentDetailOrSubscriptions;

  /// No description provided for @studentDetailRatingCount.
  ///
  /// In fr, this message translates to:
  /// **'{rating} ({count, plural, =1{{count} avis} other{{count} avis}})'**
  String studentDetailRatingCount(Object rating, int count);

  /// No description provided for @studentDetailReadBook.
  ///
  /// In fr, this message translates to:
  /// **'Lire le livre'**
  String get studentDetailReadBook;

  /// No description provided for @studentDetailReadInApp.
  ///
  /// In fr, this message translates to:
  /// **'Lire dans l\'application'**
  String get studentDetailReadInApp;

  /// No description provided for @studentDetailReadPreview.
  ///
  /// In fr, this message translates to:
  /// **'Lire l\'aperçu ({pages} pages)'**
  String studentDetailReadPreview(Object pages);

  /// No description provided for @studentDetailReviewsHeader.
  ///
  /// In fr, this message translates to:
  /// **'Avis ({count})'**
  String studentDetailReviewsHeader(Object count);

  /// No description provided for @studentDetailSimilar.
  ///
  /// In fr, this message translates to:
  /// **'Contenus similaires'**
  String get studentDetailSimilar;

  /// No description provided for @studentDetailStartQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le quiz'**
  String get studentDetailStartQuiz;

  /// No description provided for @studentDetailTagHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get studentDetailTagHard;

  /// No description provided for @studentDetailTagMastered.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisé'**
  String get studentDetailTagMastered;

  /// No description provided for @studentDetailTagToBuy.
  ///
  /// In fr, this message translates to:
  /// **'À acheter'**
  String get studentDetailTagToBuy;

  /// No description provided for @studentDetailTagToRevise.
  ///
  /// In fr, this message translates to:
  /// **'À réviser'**
  String get studentDetailTagToRevise;

  /// No description provided for @studentDetailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get studentDetailVerified;

  /// No description provided for @studentDetailViewAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Voir le corrigé'**
  String get studentDetailViewAnswers;

  /// No description provided for @studentDetailViewCart.
  ///
  /// In fr, this message translates to:
  /// **'Voir le panier'**
  String get studentDetailViewCart;

  /// No description provided for @studentDetailViews.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} consultations} other{{count} consultations}}'**
  String studentDetailViews(int count);

  /// No description provided for @studentFavAddedOn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté le {date}'**
  String studentFavAddedOn(Object date);

  /// No description provided for @studentFavCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} contenu(s) sauvegardé(s)'**
  String studentFavCount(Object count);

  /// No description provided for @studentFavEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l\'instant'**
  String get studentFavEmpty;

  /// No description provided for @studentFavExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer le catalogue'**
  String get studentFavExplore;

  /// No description provided for @studentFavLimit.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan permet {max} favoris. Passez à un plan supérieur pour en sauvegarder plus.'**
  String studentFavLimit(Object max);

  /// No description provided for @studentFavLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les favoris.'**
  String get studentFavLoadError;

  /// No description provided for @studentFavTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Favoris'**
  String get studentFavTitle;

  /// No description provided for @studentGoalsAcceptError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'accepter cet objectif pour le moment.'**
  String get studentGoalsAcceptError;

  /// No description provided for @studentGoalsDeadlineOn.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String studentGoalsDeadlineOn(Object date);

  /// No description provided for @studentGoalsFieldDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get studentGoalsFieldDeadline;

  /// No description provided for @studentGoalsFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get studentGoalsFieldTitle;

  /// No description provided for @studentGoalsProposedBy.
  ///
  /// In fr, this message translates to:
  /// **'Proposé par un de vos parents'**
  String get studentGoalsProposedBy;

  /// No description provided for @studentGoalsRefuseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Refuser définitivement ?'**
  String get studentGoalsRefuseConfirm;

  /// No description provided for @studentGoalsRefuseError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de refuser cet objectif pour le moment.'**
  String get studentGoalsRefuseError;

  /// No description provided for @studentGoalsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le titre et l\'échéance sont requis.'**
  String get studentGoalsRequired;

  /// No description provided for @studentGoalsSaveActivate.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et activer'**
  String get studentGoalsSaveActivate;

  /// No description provided for @studentGoalsSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications pour le moment.'**
  String get studentGoalsSaveError;

  /// No description provided for @studentGoalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs proposés par vos parents'**
  String get studentGoalsTitle;

  /// No description provided for @studentGroupsAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites déjà partie de « {name} ».'**
  String studentGroupsAlreadyMember(Object name);

  /// No description provided for @studentGroupsCodeIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code d\'invitation complet.'**
  String get studentGroupsCodeIncomplete;

  /// No description provided for @studentGroupsCodeNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe ne correspond à ce code.'**
  String get studentGroupsCodeNotFound;

  /// No description provided for @studentGroupsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get studentGroupsCreate;

  /// No description provided for @studentGroupsCreateBtn.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get studentGroupsCreateBtn;

  /// No description provided for @studentGroupsCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Le groupe n\'a pas pu être créé.'**
  String get studentGroupsCreateError;

  /// No description provided for @studentGroupsCreatePlus.
  ///
  /// In fr, this message translates to:
  /// **'+ Créer un groupe'**
  String get studentGroupsCreatePlus;

  /// No description provided for @studentGroupsCreating.
  ///
  /// In fr, this message translates to:
  /// **'Création…'**
  String get studentGroupsCreating;

  /// No description provided for @studentGroupsDetailLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce groupe.'**
  String get studentGroupsDetailLoadError;

  /// No description provided for @studentGroupsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe pour le moment.'**
  String get studentGroupsEmpty;

  /// No description provided for @studentGroupsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez un groupe ou rejoignez celui d\'un camarade avec son code.'**
  String get studentGroupsEmptyHint;

  /// No description provided for @studentGroupsInviteCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get studentGroupsInviteCode;

  /// No description provided for @studentGroupsJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get studentGroupsJoin;

  /// No description provided for @studentGroupsJoinByCode.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre par code'**
  String get studentGroupsJoinByCode;

  /// No description provided for @studentGroupsJoined.
  ///
  /// In fr, this message translates to:
  /// **'Groupe « {name} » rejoint avec succès !'**
  String studentGroupsJoined(Object name);

  /// No description provided for @studentGroupsLeaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement (7 derniers jours)'**
  String get studentGroupsLeaderboard;

  /// No description provided for @studentGroupsLeaderboardUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Classement indisponible pour le moment.'**
  String get studentGroupsLeaderboardUnavailable;

  /// No description provided for @studentGroupsLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get studentGroupsLeave;

  /// No description provided for @studentGroupsLeaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String studentGroupsLeaveConfirm(Object name);

  /// No description provided for @studentGroupsLeaveError.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas pu quitter ce groupe.'**
  String get studentGroupsLeaveError;

  /// No description provided for @studentGroupsLeaveOwner.
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ? Le groupe sera archivé pour tous ses membres.'**
  String studentGroupsLeaveOwner(Object name);

  /// No description provided for @studentGroupsLeaveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce groupe ?'**
  String get studentGroupsLeaveTitle;

  /// No description provided for @studentGroupsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Vos groupes n\'ont pas pu être chargés.'**
  String get studentGroupsLoadError;

  /// No description provided for @studentGroupsMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get studentGroupsMember;

  /// No description provided for @studentGroupsMemberCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} membre} other{{count} membres}}'**
  String studentGroupsMemberCount(int count);

  /// No description provided for @studentGroupsMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get studentGroupsMembers;

  /// No description provided for @studentGroupsMembersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} membres} other{{count} membres}}'**
  String studentGroupsMembersCount(int count);

  /// No description provided for @studentGroupsMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes'**
  String get studentGroupsMine;

  /// No description provided for @studentGroupsNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe (min 3 caractères)'**
  String get studentGroupsNameHint;

  /// No description provided for @studentGroupsNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 3 caractères.'**
  String get studentGroupsNameTooShort;

  /// No description provided for @studentGroupsNoActivity.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a encore d\'activité cette semaine.'**
  String get studentGroupsNoActivity;

  /// No description provided for @studentGroupsOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get studentGroupsOwner;

  /// No description provided for @studentGroupsRankLine.
  ///
  /// In fr, this message translates to:
  /// **'{quizzes} quiz réussis · {minutes} min étudiées'**
  String studentGroupsRankLine(Object quizzes, Object minutes);

  /// No description provided for @studentGroupsSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get studentGroupsSending;

  /// No description provided for @studentGroupsSubjectHint.
  ///
  /// In fr, this message translates to:
  /// **'Matière principale (optionnel)'**
  String get studentGroupsSubjectHint;

  /// No description provided for @studentHistCatCourse.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get studentHistCatCourse;

  /// No description provided for @studentHistCatDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document'**
  String get studentHistCatDocument;

  /// No description provided for @studentHistCatExercise.
  ///
  /// In fr, this message translates to:
  /// **'Exercice'**
  String get studentHistCatExercise;

  /// No description provided for @studentHistCatPaper.
  ///
  /// In fr, this message translates to:
  /// **'Épreuve'**
  String get studentHistCatPaper;

  /// No description provided for @studentHistCatSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get studentHistCatSummary;

  /// No description provided for @studentHistDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n} jours'**
  String studentHistDaysAgo(Object n);

  /// No description provided for @studentHistEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document consulté pour l\'instant.'**
  String get studentHistEmpty;

  /// No description provided for @studentHistEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre des épreuves depuis le catalogue.'**
  String get studentHistEmptyHint;

  /// No description provided for @studentHistEmptyPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document consulté sur {period}.'**
  String studentHistEmptyPeriod(Object period);

  /// No description provided for @studentHistFileCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} fichier · {period}} =1{{count} fichier · {period}} other{{count} fichiers · {period}}}'**
  String studentHistFileCount(int count, Object period);

  /// No description provided for @studentHistLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get studentHistLoadError;

  /// No description provided for @studentHistPeriod1y.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get studentHistPeriod1y;

  /// No description provided for @studentHistPeriod30d.
  ///
  /// In fr, this message translates to:
  /// **'30j'**
  String get studentHistPeriod30d;

  /// No description provided for @studentHistPeriod7d.
  ///
  /// In fr, this message translates to:
  /// **'7j'**
  String get studentHistPeriod7d;

  /// No description provided for @studentHistPeriod90d.
  ///
  /// In fr, this message translates to:
  /// **'90j'**
  String get studentHistPeriod90d;

  /// No description provided for @studentHistTitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents consultés'**
  String get studentHistTitle;

  /// No description provided for @studentHomeAvgScore.
  ///
  /// In fr, this message translates to:
  /// **'score moyen'**
  String get studentHomeAvgScore;

  /// No description provided for @studentHomeBadges.
  ///
  /// In fr, this message translates to:
  /// **'Badges'**
  String get studentHomeBadges;

  /// No description provided for @studentHomeContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continue où tu t\'es arrêté'**
  String get studentHomeContinue;

  /// No description provided for @studentHomeDate.
  ///
  /// In fr, this message translates to:
  /// **'{weekday} {date}'**
  String studentHomeDate(Object weekday, Object date);

  /// No description provided for @studentHomeDaysInARow.
  ///
  /// In fr, this message translates to:
  /// **'jours d\'affilée'**
  String get studentHomeDaysInARow;

  /// No description provided for @studentHomeDaysLabel.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get studentHomeDaysLabel;

  /// No description provided for @studentHomeDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get studentHomeDownloads;

  /// No description provided for @studentHomeGoodAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get studentHomeGoodAfternoon;

  /// No description provided for @studentHomeGoodEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get studentHomeGoodEvening;

  /// No description provided for @studentHomeGoodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get studentHomeGoodMorning;

  /// No description provided for @studentHomeInARow.
  ///
  /// In fr, this message translates to:
  /// **' d\'affilée !'**
  String get studentHomeInARow;

  /// No description provided for @studentHomeOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu n\'a pas pu être ouvert. Réessaie plus tard.'**
  String get studentHomeOpenFailed;

  /// No description provided for @studentHomeQuizPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'Quiz / sem.'**
  String get studentHomeQuizPerWeek;

  /// No description provided for @studentHomeResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get studentHomeResume;

  /// No description provided for @studentHomeSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get studentHomeSee;

  /// No description provided for @studentHomeStreak.
  ///
  /// In fr, this message translates to:
  /// **'Streak'**
  String get studentHomeStreak;

  /// No description provided for @studentHomeStreakDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} jours} other{{count} jours}}'**
  String studentHomeStreakDays(int count);

  /// No description provided for @studentHomeStudyPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'Étude / sem.'**
  String get studentHomeStudyPerWeek;

  /// No description provided for @studentHomeStudyThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'d\'étude cette semaine'**
  String get studentHomeStudyThisWeek;

  /// No description provided for @studentHomeTimeLogged.
  ///
  /// In fr, this message translates to:
  /// **'Temps enregistré'**
  String get studentHomeTimeLogged;

  /// No description provided for @studentHomeUpcomingExams.
  ///
  /// In fr, this message translates to:
  /// **'Examens à venir'**
  String get studentHomeUpcomingExams;

  /// No description provided for @studentHomeUpgrade.
  ///
  /// In fr, this message translates to:
  /// **'Avec un abonnement, tout le catalogue s\'ouvre et WinAI vous accompagne davantage.'**
  String get studentHomeUpgrade;

  /// No description provided for @studentHubAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get studentHubAccount;

  /// No description provided for @studentHubBadgesSub.
  ///
  /// In fr, this message translates to:
  /// **'14 débloqués'**
  String get studentHubBadgesSub;

  /// No description provided for @studentHubCertificates.
  ///
  /// In fr, this message translates to:
  /// **'Mes certificats'**
  String get studentHubCertificates;

  /// No description provided for @studentHubCertificatesSub.
  ///
  /// In fr, this message translates to:
  /// **'2 signés'**
  String get studentHubCertificatesSub;

  /// No description provided for @studentHubCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get studentHubCommunity;

  /// No description provided for @studentHubDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant'**
  String get studentHubDefaultName;

  /// No description provided for @studentHubFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get studentHubFavorites;

  /// No description provided for @studentHubFavoritesSub.
  ///
  /// In fr, this message translates to:
  /// **'Vos contenus enregistrés'**
  String get studentHubFavoritesSub;

  /// No description provided for @studentHubForum.
  ///
  /// In fr, this message translates to:
  /// **'Forum communauté'**
  String get studentHubForum;

  /// No description provided for @studentHubForumSub.
  ///
  /// In fr, this message translates to:
  /// **'Questions & réponses'**
  String get studentHubForumSub;

  /// No description provided for @studentHubGroups.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes d\'étude'**
  String get studentHubGroups;

  /// No description provided for @studentHubGroupsSub.
  ///
  /// In fr, this message translates to:
  /// **'3 groupes'**
  String get studentHubGroupsSub;

  /// No description provided for @studentHubHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des téléchargements'**
  String get studentHubHistory;

  /// No description provided for @studentHubLearning.
  ///
  /// In fr, this message translates to:
  /// **'Apprentissage'**
  String get studentHubLearning;

  /// No description provided for @studentHubLogoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez redirigé vers l\'écran d\'accueil.'**
  String get studentHubLogoutBody;

  /// No description provided for @studentHubLogoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get studentHubLogoutConfirm;

  /// No description provided for @studentHubLogoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get studentHubLogoutTitle;

  /// No description provided for @studentHubNetworkSub.
  ///
  /// In fr, this message translates to:
  /// **'Parents, profs, établissement'**
  String get studentHubNetworkSub;

  /// No description provided for @studentHubPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan {planName}'**
  String studentHubPlan(Object planName);

  /// No description provided for @studentHubPomodoroSub.
  ///
  /// In fr, this message translates to:
  /// **'25 min focus · 5 min pause'**
  String get studentHubPomodoroSub;

  /// No description provided for @studentHubPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get studentHubPrivacy;

  /// No description provided for @studentHubProfileSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du profil'**
  String get studentHubProfileSettings;

  /// No description provided for @studentHubReports.
  ///
  /// In fr, this message translates to:
  /// **'Mes rapports de progression'**
  String get studentHubReports;

  /// No description provided for @studentHubRevisionQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz de révision'**
  String get studentHubRevisionQuiz;

  /// No description provided for @studentHubRevisionQuizSub.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre les questions ratées'**
  String get studentHubRevisionQuizSub;

  /// No description provided for @studentHubSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible !'**
  String get studentHubSoon;

  /// No description provided for @studentHubSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Mon abonnement'**
  String get studentHubSubscription;

  /// No description provided for @studentHubSubscriptionSub.
  ///
  /// In fr, this message translates to:
  /// **'Plan {planName} · Gérer'**
  String studentHubSubscriptionSub(Object planName);

  /// No description provided for @studentHubTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get studentHubTerms;

  /// No description provided for @studentHubTutorPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de tutorat'**
  String get studentHubTutorPolicy;

  /// No description provided for @studentHubWinaiSub.
  ///
  /// In fr, this message translates to:
  /// **'Ton assistant pédagogique'**
  String get studentHubWinaiSub;

  /// No description provided for @studentLinksActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible, réessaie.'**
  String get studentLinksActionFailed;

  /// No description provided for @studentLinksAttachAccepted.
  ///
  /// In fr, this message translates to:
  /// **'rattachement confirmé'**
  String get studentLinksAttachAccepted;

  /// No description provided for @studentLinksAttachPending.
  ///
  /// In fr, this message translates to:
  /// **'rattachement en attente de ta réponse'**
  String get studentLinksAttachPending;

  /// No description provided for @studentLinksAttachRefused.
  ///
  /// In fr, this message translates to:
  /// **'rattachement refusé pour les cours particuliers'**
  String get studentLinksAttachRefused;

  /// No description provided for @studentLinksClass.
  ///
  /// In fr, this message translates to:
  /// **'Classe {group}'**
  String studentLinksClass(Object group);

  /// No description provided for @studentLinksInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Invitations reçues'**
  String get studentLinksInvitations;

  /// No description provided for @studentLinksLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get studentLinksLoadError;

  /// No description provided for @studentLinksParents.
  ///
  /// In fr, this message translates to:
  /// **'Parents'**
  String get studentLinksParents;

  /// No description provided for @studentLinksRoleInstitution.
  ///
  /// In fr, this message translates to:
  /// **'institution'**
  String get studentLinksRoleInstitution;

  /// No description provided for @studentLinksRoleParent.
  ///
  /// In fr, this message translates to:
  /// **'parent'**
  String get studentLinksRoleParent;

  /// No description provided for @studentLinksSchools.
  ///
  /// In fr, this message translates to:
  /// **'Établissements'**
  String get studentLinksSchools;

  /// No description provided for @studentLinksSchoolsHint.
  ///
  /// In fr, this message translates to:
  /// **'En acceptant, l\'établissement peut réserver, payer et attribuer des cours particuliers pour toi. Tu peux changer d\'avis à tout moment.'**
  String get studentLinksSchoolsHint;

  /// No description provided for @studentLinksStudyGroups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes d\'étude'**
  String get studentLinksStudyGroups;

  /// No description provided for @studentLinksTeacherClass.
  ///
  /// In fr, this message translates to:
  /// **'Professeur · {className}'**
  String studentLinksTeacherClass(Object className);

  /// No description provided for @studentLinksTeacherPending.
  ///
  /// In fr, this message translates to:
  /// **'Professeur · invitation en attente'**
  String get studentLinksTeacherPending;

  /// No description provided for @studentLinksTeachers.
  ///
  /// In fr, this message translates to:
  /// **'Professeurs'**
  String get studentLinksTeachers;

  /// No description provided for @studentLinksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon réseau'**
  String get studentLinksTitle;

  /// No description provided for @studentLinksWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer mon accord'**
  String get studentLinksWithdraw;

  /// No description provided for @studentMyCoursesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formation en cours'**
  String get studentMyCoursesEmpty;

  /// No description provided for @studentMyCoursesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Explorez notre catalogue et commencez à apprendre dès aujourd\'hui.'**
  String get studentMyCoursesEmptyHint;

  /// No description provided for @studentMyCoursesExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer les formations'**
  String get studentMyCoursesExplore;

  /// No description provided for @studentMyCoursesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos formations.'**
  String get studentMyCoursesLoadError;

  /// No description provided for @studentMyCoursesReplay.
  ///
  /// In fr, this message translates to:
  /// **'Revoir'**
  String get studentMyCoursesReplay;

  /// No description provided for @studentMyCoursesStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get studentMyCoursesStart;

  /// No description provided for @studentMyCoursesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes formations'**
  String get studentMyCoursesTitle;

  /// No description provided for @studentNotifAllCaughtUp.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à jour !'**
  String get studentNotifAllCaughtUp;

  /// No description provided for @studentNotifHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n}h'**
  String studentNotifHoursAgo(Object n);

  /// No description provided for @studentNotifJustNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get studentNotifJustNow;

  /// No description provided for @studentNotifMarkFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de marquer les notifications comme lues. Réessaie.'**
  String get studentNotifMarkFailed;

  /// No description provided for @studentNotifMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n} min'**
  String studentNotifMinutesAgo(Object n);

  /// No description provided for @studentNotifReadAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get studentNotifReadAll;

  /// No description provided for @studentNotifSeeMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get studentNotifSeeMore;

  /// No description provided for @studentNotifTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get studentNotifTitle;

  /// No description provided for @studentPlayerAttachedFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier joint'**
  String get studentPlayerAttachedFile;

  /// No description provided for @studentPlayerCertAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat est disponible.'**
  String get studentPlayerCertAvailable;

  /// No description provided for @studentPlayerCertGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Félicitations ! Votre certificat est en cours de génération.'**
  String get studentPlayerCertGenerating;

  /// No description provided for @studentPlayerCourseDone.
  ///
  /// In fr, this message translates to:
  /// **'Formation terminée !'**
  String get studentPlayerCourseDone;

  /// No description provided for @studentPlayerCurriculum.
  ///
  /// In fr, this message translates to:
  /// **'Curriculum'**
  String get studentPlayerCurriculum;

  /// No description provided for @studentPlayerDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get studentPlayerDone;

  /// No description provided for @studentPlayerDownloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement impossible. Réessaie plus tard.'**
  String get studentPlayerDownloadFailed;

  /// No description provided for @studentPlayerDownloadOffline.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger hors-ligne'**
  String get studentPlayerDownloadOffline;

  /// No description provided for @studentPlayerDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Leçon téléchargée pour un visionnage hors-ligne.'**
  String get studentPlayerDownloaded;

  /// No description provided for @studentPlayerLessonDone.
  ///
  /// In fr, this message translates to:
  /// **'Leçon terminée'**
  String get studentPlayerLessonDone;

  /// No description provided for @studentPlayerMarkDone.
  ///
  /// In fr, this message translates to:
  /// **'Marquer terminé'**
  String get studentPlayerMarkDone;

  /// No description provided for @studentPlayerOfflinePlayback.
  ///
  /// In fr, this message translates to:
  /// **'Lecture hors-ligne'**
  String get studentPlayerOfflinePlayback;

  /// No description provided for @studentPlayerOpenViewer.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans la visionneuse (consultation en ligne)'**
  String get studentPlayerOpenViewer;

  /// No description provided for @studentPlayerRemoveOffline.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le hors-ligne'**
  String get studentPlayerRemoveOffline;

  /// No description provided for @studentPlayerSelectLesson.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une leçon.'**
  String get studentPlayerSelectLesson;

  /// No description provided for @studentPlayerTapToDownload.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour télécharger'**
  String get studentPlayerTapToDownload;

  /// No description provided for @studentPlayerVideoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo indisponible pour le moment.'**
  String get studentPlayerVideoUnavailable;

  /// No description provided for @studentProfile2fa.
  ///
  /// In fr, this message translates to:
  /// **'Authentification à 2 facteurs'**
  String get studentProfile2fa;

  /// No description provided for @studentProfile2faHint.
  ///
  /// In fr, this message translates to:
  /// **'Un code email à chaque connexion.'**
  String get studentProfile2faHint;

  /// No description provided for @studentProfileActiveSessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions actives'**
  String get studentProfileActiveSessions;

  /// No description provided for @studentProfileAnonStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques anonymisées'**
  String get studentProfileAnonStats;

  /// No description provided for @studentProfileAnonStatsHint.
  ///
  /// In fr, this message translates to:
  /// **'Aide à améliorer WinPlus.'**
  String get studentProfileAnonStatsHint;

  /// No description provided for @studentProfileChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get studentProfileChange;

  /// No description provided for @studentProfileChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la photo'**
  String get studentProfileChangePhoto;

  /// No description provided for @studentProfileChangePwd.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get studentProfileChangePwd;

  /// No description provided for @studentProfileCodeReceived.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par email'**
  String get studentProfileCodeReceived;

  /// No description provided for @studentProfileCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à {email}. Il expire après 15 minutes.'**
  String studentProfileCodeSent(Object email);

  /// No description provided for @studentProfileConfirmCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de confirmation'**
  String get studentProfileConfirmCode;

  /// No description provided for @studentProfileCurrentPwd.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get studentProfileCurrentPwd;

  /// No description provided for @studentProfileCurrentSession.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant · Session actuelle'**
  String get studentProfileCurrentSession;

  /// No description provided for @studentProfileDangerZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone dangereuse'**
  String get studentProfileDangerZone;

  /// No description provided for @studentProfileDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get studentProfileDeleteAccount;

  /// No description provided for @studentProfileDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront perdues.'**
  String get studentProfileDeleteBody;

  /// No description provided for @studentProfileDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get studentProfileDeleteTitle;

  /// No description provided for @studentProfileDeleteWarning.
  ///
  /// In fr, this message translates to:
  /// **'La suppression de votre compte est irréversible.'**
  String get studentProfileDeleteWarning;

  /// No description provided for @studentProfileEmailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get studentProfileEmailAddress;

  /// No description provided for @studentProfileEmailChanged.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email modifiée.'**
  String get studentProfileEmailChanged;

  /// No description provided for @studentProfileEmailCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Actuelle : {email}'**
  String studentProfileEmailCurrent(Object email);

  /// No description provided for @studentProfileEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide.'**
  String get studentProfileEmailInvalid;

  /// No description provided for @studentProfileEmailSame.
  ///
  /// In fr, this message translates to:
  /// **'C\'est déjà votre adresse actuelle.'**
  String get studentProfileEmailSame;

  /// No description provided for @studentProfileEnterCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le code reçu par email.'**
  String get studentProfileEnterCode;

  /// No description provided for @studentProfileFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get studentProfileFullName;

  /// No description provided for @studentProfileGetCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get studentProfileGetCode;

  /// No description provided for @studentProfileLearningStyle.
  ///
  /// In fr, this message translates to:
  /// **'Mon style d’apprentissage'**
  String get studentProfileLearningStyle;

  /// No description provided for @studentProfileManageSub.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon abonnement'**
  String get studentProfileManageSub;

  /// No description provided for @studentProfileNewEmail.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel email'**
  String get studentProfileNewEmail;

  /// No description provided for @studentProfileNewEmailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse e-mail'**
  String get studentProfileNewEmailAddress;

  /// No description provided for @studentProfileNotifAi.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations WinAI'**
  String get studentProfileNotifAi;

  /// No description provided for @studentProfileNotifAiSub.
  ///
  /// In fr, this message translates to:
  /// **'Alertes et conseils personnalisés'**
  String get studentProfileNotifAiSub;

  /// No description provided for @studentProfileNotifCommunitySub.
  ///
  /// In fr, this message translates to:
  /// **'Réponses à vos questions'**
  String get studentProfileNotifCommunitySub;

  /// No description provided for @studentProfileNotifExam.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'examens'**
  String get studentProfileNotifExam;

  /// No description provided for @studentProfileNotifExamSub.
  ///
  /// In fr, this message translates to:
  /// **'Compte à rebours avant vos examens'**
  String get studentProfileNotifExamSub;

  /// No description provided for @studentProfileNotifPromo.
  ///
  /// In fr, this message translates to:
  /// **'Offres et promotions'**
  String get studentProfileNotifPromo;

  /// No description provided for @studentProfileNotifPromoSub.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux contenus, promotions'**
  String get studentProfileNotifPromoSub;

  /// No description provided for @studentProfileNotifQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Résultats de quiz'**
  String get studentProfileNotifQuiz;

  /// No description provided for @studentProfileNotifQuizSub.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir vos scores après chaque quiz'**
  String get studentProfileNotifQuizSub;

  /// No description provided for @studentProfilePeriodEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin de période le {date}'**
  String studentProfilePeriodEnd(Object date);

  /// No description provided for @studentProfilePhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get studentProfilePhone;

  /// No description provided for @studentProfilePwdChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié.'**
  String get studentProfilePwdChanged;

  /// No description provided for @studentProfilePwdMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get studentProfilePwdMismatch;

  /// No description provided for @studentProfilePwdWrong.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect.'**
  String get studentProfilePwdWrong;

  /// No description provided for @studentProfileSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get studentProfileSaveChanges;

  /// No description provided for @studentProfileTabPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get studentProfileTabPrivacy;

  /// No description provided for @studentProfileTabSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get studentProfileTabSecurity;

  /// No description provided for @studentProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get studentProfileTitle;

  /// No description provided for @studentProfileUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour.'**
  String get studentProfileUpdateError;

  /// No description provided for @studentProfileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get studentProfileUpdated;

  /// No description provided for @studentProfileVisible.
  ///
  /// In fr, this message translates to:
  /// **'Profil visible'**
  String get studentProfileVisible;

  /// No description provided for @studentProfileVisibleHint.
  ///
  /// In fr, this message translates to:
  /// **'Visible par la communauté WinPlus.'**
  String get studentProfileVisibleHint;

  /// No description provided for @studentQuizAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Quiz disponibles'**
  String get studentQuizAvailable;

  /// No description provided for @studentQuizBackToCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Retour au catalogue'**
  String get studentQuizBackToCatalog;

  /// No description provided for @studentQuizCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Correctes'**
  String get studentQuizCorrect;

  /// No description provided for @studentQuizCounter.
  ///
  /// In fr, this message translates to:
  /// **'Question {current} sur {total}'**
  String studentQuizCounter(Object current, Object total);

  /// No description provided for @studentQuizExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get studentQuizExcellent;

  /// No description provided for @studentQuizFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le quiz'**
  String get studentQuizFinish;

  /// No description provided for @studentQuizGoodWork.
  ///
  /// In fr, this message translates to:
  /// **'Bon travail'**
  String get studentQuizGoodWork;

  /// No description provided for @studentQuizIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Incorrectes'**
  String get studentQuizIncorrect;

  /// No description provided for @studentQuizMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count} questions · {minutes} min'**
  String studentQuizMeta(Object count, Object minutes);

  /// No description provided for @studentQuizMyQuizzes.
  ///
  /// In fr, this message translates to:
  /// **'Mes Quiz'**
  String get studentQuizMyQuizzes;

  /// No description provided for @studentQuizNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun quiz disponible.'**
  String get studentQuizNone;

  /// No description provided for @studentQuizNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get studentQuizNow;

  /// No description provided for @studentQuizResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get studentQuizResults;

  /// No description provided for @studentQuizRetake.
  ///
  /// In fr, this message translates to:
  /// **'Refaire le quiz'**
  String get studentQuizRetake;

  /// No description provided for @studentQuizReview.
  ///
  /// In fr, this message translates to:
  /// **'Révision'**
  String get studentQuizReview;

  /// No description provided for @studentQuizReviewAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Revoir les réponses'**
  String get studentQuizReviewAnswers;

  /// No description provided for @studentQuizToImprove.
  ///
  /// In fr, this message translates to:
  /// **'À améliorer'**
  String get studentQuizToImprove;

  /// No description provided for @studentReportsAvgScore.
  ///
  /// In fr, this message translates to:
  /// **'Score moyen'**
  String get studentReportsAvgScore;

  /// No description provided for @studentReportsBestSubject.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure matière : Maths'**
  String get studentReportsBestSubject;

  /// No description provided for @studentReportsBySubject.
  ///
  /// In fr, this message translates to:
  /// **'Score par matière'**
  String get studentReportsBySubject;

  /// No description provided for @studentReportsExportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter PDF'**
  String get studentReportsExportPdf;

  /// No description provided for @studentReportsPeriod30.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get studentReportsPeriod30;

  /// No description provided for @studentReportsPeriod7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get studentReportsPeriod7;

  /// No description provided for @studentReportsPeriod90.
  ///
  /// In fr, this message translates to:
  /// **'90 jours'**
  String get studentReportsPeriod90;

  /// No description provided for @studentReportsPlanRequired.
  ///
  /// In fr, this message translates to:
  /// **'Plan Standard requis pour cette période'**
  String get studentReportsPlanRequired;

  /// No description provided for @studentReportsQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get studentReportsQuiz;

  /// No description provided for @studentReportsQuizDone.
  ///
  /// In fr, this message translates to:
  /// **'Quiz réalisés'**
  String get studentReportsQuizDone;

  /// No description provided for @studentReportsStandardOnly.
  ///
  /// In fr, this message translates to:
  /// **'Disponible avec le Plan Standard'**
  String get studentReportsStandardOnly;

  /// No description provided for @studentReportsSuccessRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de réussite'**
  String get studentReportsSuccessRate;

  /// No description provided for @studentReportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes rapports'**
  String get studentReportsTitle;

  /// No description provided for @studentReportsToImprove.
  ///
  /// In fr, this message translates to:
  /// **'À améliorer : Chimie'**
  String get studentReportsToImprove;

  /// No description provided for @studentReportsWeekShort.
  ///
  /// In fr, this message translates to:
  /// **'S{n}'**
  String studentReportsWeekShort(Object n);

  /// No description provided for @studentReportsWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Progression hebdomadaire'**
  String get studentReportsWeekly;

  /// No description provided for @studentRevisionAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get studentRevisionAll;

  /// No description provided for @studentRevisionBackToCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Revoir le catalogue'**
  String get studentRevisionBackToCatalog;

  /// No description provided for @studentRevisionDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n}j'**
  String studentRevisionDaysAgo(Object n);

  /// No description provided for @studentRevisionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune question à réviser !\nTu maîtrises tout.'**
  String get studentRevisionEmpty;

  /// No description provided for @studentRevisionHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n}h'**
  String studentRevisionHoursAgo(Object n);

  /// No description provided for @studentRevisionLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes erreurs.'**
  String get studentRevisionLoadError;

  /// No description provided for @studentRevisionMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n}min'**
  String studentRevisionMinutesAgo(Object n);

  /// No description provided for @studentRevisionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Questions que tu as ratées récemment'**
  String get studentRevisionSubtitle;

  /// No description provided for @studentRevisionYesterday.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get studentRevisionYesterday;

  /// No description provided for @studentSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'BAC C Maths, ENSP, SVT…'**
  String get studentSearchHint;

  /// No description provided for @studentSearchIdle.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez dans le catalogue'**
  String get studentSearchIdle;

  /// No description provided for @studentSearchNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {query} »'**
  String studentSearchNoResults(Object query);

  /// No description provided for @studentSessionDone.
  ///
  /// In fr, this message translates to:
  /// **'Session terminée !'**
  String get studentSessionDone;

  /// No description provided for @studentSessionDoneScore.
  ///
  /// In fr, this message translates to:
  /// **'Score : {pct}% sur {subject}'**
  String studentSessionDoneScore(Object pct, Object subject);

  /// No description provided for @studentSessionFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la session'**
  String get studentSessionFinish;

  /// No description provided for @studentSessionHistory.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes sessions passées'**
  String get studentSessionHistory;

  /// No description provided for @studentSessionHistoryLine.
  ///
  /// In fr, this message translates to:
  /// **'{duration} min · {score} · {date}'**
  String studentSessionHistoryLine(Object duration, Object score, Object date);

  /// No description provided for @studentSessionIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une matière et une durée. WinAI prépare un briefing, un quiz progressif puis une synthèse personnalisée.'**
  String get studentSessionIntro;

  /// No description provided for @studentSessionMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{d} min'**
  String studentSessionMinutes(Object d);

  /// No description provided for @studentSessionNextQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get studentSessionNextQuestion;

  /// No description provided for @studentSessionNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session terminée pour le moment.'**
  String get studentSessionNoHistory;

  /// No description provided for @studentSessionNoScore.
  ///
  /// In fr, this message translates to:
  /// **'sans score'**
  String get studentSessionNoScore;

  /// No description provided for @studentSessionNoSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière disponible pour le moment.'**
  String get studentSessionNoSubjects;

  /// No description provided for @studentSessionPickSubject.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une matière pour commencer.'**
  String get studentSessionPickSubject;

  /// No description provided for @studentSessionQuizError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le quiz. Réessaie dans un instant.'**
  String get studentSessionQuizError;

  /// No description provided for @studentSessionScoreLine.
  ///
  /// In fr, this message translates to:
  /// **'{correct}/{total} correctes · {pct}%'**
  String studentSessionScoreLine(Object correct, Object total, Object pct);

  /// No description provided for @studentSessionSeeSummary.
  ///
  /// In fr, this message translates to:
  /// **'Voir la synthèse'**
  String get studentSessionSeeSummary;

  /// No description provided for @studentSessionStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la session'**
  String get studentSessionStart;

  /// No description provided for @studentSessionStartError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer la session. Réessaie.'**
  String get studentSessionStartError;

  /// No description provided for @studentSessionStepBriefing.
  ///
  /// In fr, this message translates to:
  /// **'Briefing'**
  String get studentSessionStepBriefing;

  /// No description provided for @studentSessionStepQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz progressif'**
  String get studentSessionStepQuiz;

  /// No description provided for @studentSessionStepSummary.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse WinAI'**
  String get studentSessionStepSummary;

  /// No description provided for @studentSessionSummaryError.
  ///
  /// In fr, this message translates to:
  /// **'La synthèse n\'a pas pu être générée, mais tes réponses sont bien conservées.'**
  String get studentSessionSummaryError;

  /// No description provided for @studentTabsAiFileAttached.
  ///
  /// In fr, this message translates to:
  /// **'Fichier joint : {name}'**
  String studentTabsAiFileAttached(Object name);

  /// No description provided for @studentTabsAiFileReceived.
  ///
  /// In fr, this message translates to:
  /// **'Fichier reçu ! Je l\'analyse...'**
  String get studentTabsAiFileReceived;

  /// No description provided for @studentTabsAiHint.
  ///
  /// In fr, this message translates to:
  /// **'Pose ta question à WinAI…'**
  String get studentTabsAiHint;

  /// No description provided for @studentTabsAiNoReply.
  ///
  /// In fr, this message translates to:
  /// **'Désolé, je n\'ai pas pu répondre. Réessaie.'**
  String get studentTabsAiNoReply;

  /// No description provided for @studentTabsAiSuggest1.
  ///
  /// In fr, this message translates to:
  /// **'Explique-moi les dérivées'**
  String get studentTabsAiSuggest1;

  /// No description provided for @studentTabsAiSuggest2.
  ///
  /// In fr, this message translates to:
  /// **'Plan de révision BAC C'**
  String get studentTabsAiSuggest2;

  /// No description provided for @studentTabsAiSuggest3.
  ///
  /// In fr, this message translates to:
  /// **'Mes matières faibles ?'**
  String get studentTabsAiSuggest3;

  /// No description provided for @studentTabsAiSuggest4.
  ///
  /// In fr, this message translates to:
  /// **'Génère un quiz Chimie'**
  String get studentTabsAiSuggest4;

  /// No description provided for @studentTabsAiTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton assistant pédagogique personnel'**
  String get studentTabsAiTagline;

  /// No description provided for @studentTabsAttachDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document (PDF, Word…)'**
  String get studentTabsAttachDocument;

  /// No description provided for @studentTabsAttachFile.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un fichier'**
  String get studentTabsAttachFile;

  /// No description provided for @studentTabsAttachImage.
  ///
  /// In fr, this message translates to:
  /// **'Image / Photo'**
  String get studentTabsAttachImage;

  /// No description provided for @studentTabsAttachVoice.
  ///
  /// In fr, this message translates to:
  /// **'Message vocal'**
  String get studentTabsAttachVoice;

  /// No description provided for @studentTabsAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Pièce jointe'**
  String get studentTabsAttachment;

  /// No description provided for @studentTabsCatalogLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le catalogue.'**
  String get studentTabsCatalogLoadError;

  /// No description provided for @studentTabsCertificates.
  ///
  /// In fr, this message translates to:
  /// **'Certificats'**
  String get studentTabsCertificates;

  /// No description provided for @studentTabsCourseCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue formations'**
  String get studentTabsCourseCatalog;

  /// No description provided for @studentTabsExamCoach.
  ///
  /// In fr, this message translates to:
  /// **'Coach Exam'**
  String get studentTabsExamCoach;

  /// No description provided for @studentTabsFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get studentTabsFavorites;

  /// No description provided for @studentTabsFindTutor.
  ///
  /// In fr, this message translates to:
  /// **'Trouver un tuteur'**
  String get studentTabsFindTutor;

  /// No description provided for @studentTabsFindTutorSub.
  ///
  /// In fr, this message translates to:
  /// **'Cours particuliers en ligne ou à domicile'**
  String get studentTabsFindTutorSub;

  /// No description provided for @studentTabsGuidedSession.
  ///
  /// In fr, this message translates to:
  /// **'Session d\'étude guidée'**
  String get studentTabsGuidedSession;

  /// No description provided for @studentTabsMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get studentTabsMyBookings;

  /// No description provided for @studentTabsMyCart.
  ///
  /// In fr, this message translates to:
  /// **'Mon panier'**
  String get studentTabsMyCart;

  /// No description provided for @studentTabsMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get studentTabsMyOrders;

  /// No description provided for @studentTabsNoContent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu disponible.'**
  String get studentTabsNoContent;

  /// No description provided for @studentTabsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'BAC C Maths 2023…'**
  String get studentTabsSearchHint;

  /// No description provided for @studentTabsStructuredCourses.
  ///
  /// In fr, this message translates to:
  /// **'Formations structurées'**
  String get studentTabsStructuredCourses;

  /// No description provided for @studentTabsStructuredCoursesSub.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez à votre rythme · Certificats inclus'**
  String get studentTabsStructuredCoursesSub;

  /// No description provided for @studentTabsStudyThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Étude cette semaine'**
  String get studentTabsStudyThisWeek;

  /// No description provided for @studentTabsTypeBooks.
  ///
  /// In fr, this message translates to:
  /// **'Livres'**
  String get studentTabsTypeBooks;

  /// No description provided for @studentTabsTypeCorrections.
  ///
  /// In fr, this message translates to:
  /// **'Corrections'**
  String get studentTabsTypeCorrections;

  /// No description provided for @studentTabsTypePacks.
  ///
  /// In fr, this message translates to:
  /// **'Packs'**
  String get studentTabsTypePacks;

  /// No description provided for @studentTabsTypePapers.
  ///
  /// In fr, this message translates to:
  /// **'Épreuves'**
  String get studentTabsTypePapers;

  /// No description provided for @studentTabsVoiceSoon.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement vocal disponible prochainement'**
  String get studentTabsVoiceSoon;

  /// No description provided for @studentVarkApplied.
  ///
  /// In fr, this message translates to:
  /// **'Style appliqué !'**
  String get studentVarkApplied;

  /// No description provided for @studentVarkApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer mon style'**
  String get studentVarkApply;

  /// No description provided for @studentVarkApplying.
  ///
  /// In fr, this message translates to:
  /// **'Application…'**
  String get studentVarkApplying;

  /// No description provided for @studentVarkAuditory.
  ///
  /// In fr, this message translates to:
  /// **'Apprenant Auditif'**
  String get studentVarkAuditory;

  /// No description provided for @studentVarkKinesthetic.
  ///
  /// In fr, this message translates to:
  /// **'Apprenant Kinesthésique'**
  String get studentVarkKinesthetic;

  /// No description provided for @studentVarkMixed.
  ///
  /// In fr, this message translates to:
  /// **'Profil Mixte'**
  String get studentVarkMixed;

  /// No description provided for @studentVarkQ1.
  ///
  /// In fr, this message translates to:
  /// **'Quand tu apprends quelque chose de nouveau, tu préfères…'**
  String get studentVarkQ1;

  /// No description provided for @studentVarkQ1A.
  ///
  /// In fr, this message translates to:
  /// **'Écouter une explication orale'**
  String get studentVarkQ1A;

  /// No description provided for @studentVarkQ1K.
  ///
  /// In fr, this message translates to:
  /// **'Essayer directement par la pratique'**
  String get studentVarkQ1K;

  /// No description provided for @studentVarkQ1R.
  ///
  /// In fr, this message translates to:
  /// **'Lire un cours écrit détaillé'**
  String get studentVarkQ1R;

  /// No description provided for @studentVarkQ1V.
  ///
  /// In fr, this message translates to:
  /// **'Dessiner un schéma ou voir un diagramme'**
  String get studentVarkQ1V;

  /// No description provided for @studentVarkQ2.
  ///
  /// In fr, this message translates to:
  /// **'Pour mémoriser une formule de mathématiques…'**
  String get studentVarkQ2;

  /// No description provided for @studentVarkQ2A.
  ///
  /// In fr, this message translates to:
  /// **'La répéter à voix haute plusieurs fois'**
  String get studentVarkQ2A;

  /// No description provided for @studentVarkQ2K.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre des exercices jusqu\'à l\'automatisme'**
  String get studentVarkQ2K;

  /// No description provided for @studentVarkQ2R.
  ///
  /// In fr, this message translates to:
  /// **'L\'écrire et la réécrire dans tes notes'**
  String get studentVarkQ2R;

  /// No description provided for @studentVarkQ2V.
  ///
  /// In fr, this message translates to:
  /// **'La visualiser telle qu\'elle est écrite'**
  String get studentVarkQ2V;

  /// No description provided for @studentVarkQ3.
  ///
  /// In fr, this message translates to:
  /// **'Quand tu bloques sur un exercice difficile…'**
  String get studentVarkQ3;

  /// No description provided for @studentVarkQ3A.
  ///
  /// In fr, this message translates to:
  /// **'En parler à quelqu\'un pour l\'expliquer oralement'**
  String get studentVarkQ3A;

  /// No description provided for @studentVarkQ3K.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer l\'exercice en variant les étapes'**
  String get studentVarkQ3K;

  /// No description provided for @studentVarkQ3R.
  ///
  /// In fr, this message translates to:
  /// **'Relire tes notes depuis le début'**
  String get studentVarkQ3R;

  /// No description provided for @studentVarkQ3V.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un exemple illustré'**
  String get studentVarkQ3V;

  /// No description provided for @studentVarkQ4.
  ///
  /// In fr, this message translates to:
  /// **'En classe, tu retiens mieux quand…'**
  String get studentVarkQ4;

  /// No description provided for @studentVarkQ4A.
  ///
  /// In fr, this message translates to:
  /// **'Le prof explique avec des exemples parlés'**
  String get studentVarkQ4A;

  /// No description provided for @studentVarkQ4K.
  ///
  /// In fr, this message translates to:
  /// **'Il y a des exercices pratiques pendant le cours'**
  String get studentVarkQ4K;

  /// No description provided for @studentVarkQ4R.
  ///
  /// In fr, this message translates to:
  /// **'Tu as un cours bien structuré à lire'**
  String get studentVarkQ4R;

  /// No description provided for @studentVarkQ4V.
  ///
  /// In fr, this message translates to:
  /// **'Le prof dessine au tableau ou montre des slides'**
  String get studentVarkQ4V;

  /// No description provided for @studentVarkQ5.
  ///
  /// In fr, this message translates to:
  /// **'Ta méthode de révision favorite…'**
  String get studentVarkQ5;

  /// No description provided for @studentVarkQ5A.
  ///
  /// In fr, this message translates to:
  /// **'M\'enregistrer en train de réciter à voix haute'**
  String get studentVarkQ5A;

  /// No description provided for @studentVarkQ5K.
  ///
  /// In fr, this message translates to:
  /// **'Enchaîner des exercices et annales corrigées'**
  String get studentVarkQ5K;

  /// No description provided for @studentVarkQ5R.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger des résumés écrits condensés'**
  String get studentVarkQ5R;

  /// No description provided for @studentVarkQ5V.
  ///
  /// In fr, this message translates to:
  /// **'Créer des fiches avec schémas et couleurs'**
  String get studentVarkQ5V;

  /// No description provided for @studentVarkQ6.
  ///
  /// In fr, this message translates to:
  /// **'Comment tu sais que tu as vraiment compris quelque chose ?'**
  String get studentVarkQ6;

  /// No description provided for @studentVarkQ6A.
  ///
  /// In fr, this message translates to:
  /// **'L\'expliquer clairement à voix haute à quelqu\'un'**
  String get studentVarkQ6A;

  /// No description provided for @studentVarkQ6K.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre des exercices variés sans aide'**
  String get studentVarkQ6K;

  /// No description provided for @studentVarkQ6R.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger un résumé complet de mémoire'**
  String get studentVarkQ6R;

  /// No description provided for @studentVarkQ6V.
  ///
  /// In fr, this message translates to:
  /// **'Le représenter graphiquement sans regarder tes notes'**
  String get studentVarkQ6V;

  /// No description provided for @studentVarkQuestionCount.
  ///
  /// In fr, this message translates to:
  /// **'Question {n} / {total}'**
  String studentVarkQuestionCount(Object n, Object total);

  /// No description provided for @studentVarkReadWrite.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur / Scripteur'**
  String get studentVarkReadWrite;

  /// No description provided for @studentVarkSaved.
  ///
  /// In fr, this message translates to:
  /// **'Ce résultat est enregistré sur ton profil : WinAI et les contenus générés s’y adaptent, sur le web comme sur mobile.'**
  String get studentVarkSaved;

  /// No description provided for @studentVarkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon style d\'apprentissage'**
  String get studentVarkTitle;

  /// No description provided for @studentVarkVisual.
  ///
  /// In fr, this message translates to:
  /// **'Apprenant Visuel'**
  String get studentVarkVisual;

  /// No description provided for @studentViewerAddToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get studentViewerAddToCart;

  /// No description provided for @studentViewerCorrectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé · {title}'**
  String studentViewerCorrectionTitle(Object title);

  /// No description provided for @studentViewerLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le document pour le moment.'**
  String get studentViewerLoadFailed;

  /// No description provided for @studentViewerNoAccess.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu n\'est pas inclus dans votre accès. Achetez-le ou abonnez-vous pour le consulter.'**
  String get studentViewerNoAccess;

  /// No description provided for @studentViewerNoConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau puis réessayez.'**
  String get studentViewerNoConnection;

  /// No description provided for @studentViewerNoCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Le corrigé de cette épreuve n\'est pas encore disponible.'**
  String get studentViewerNoCorrection;

  /// No description provided for @studentViewerNoDocument.
  ///
  /// In fr, this message translates to:
  /// **'Ce document n\'est pas disponible pour le moment.'**
  String get studentViewerNoDocument;

  /// No description provided for @studentViewerPreviewFirst.
  ///
  /// In fr, this message translates to:
  /// **'{pages, plural, =0{Aperçu : {pages} première page} =1{Aperçu : {pages} première page} other{Aperçu : {pages} premières pages}}'**
  String studentViewerPreviewFirst(int pages);

  /// No description provided for @studentViewerPreviewOf.
  ///
  /// In fr, this message translates to:
  /// **'{pages, plural, =0{Aperçu : {pages} page sur {total}} =1{Aperçu : {pages} page sur {total}} other{Aperçu : {pages} pages sur {total}}}'**
  String studentViewerPreviewOf(int pages, Object total);

  /// No description provided for @studentViewerReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule : ni téléchargement, ni partage, ni impression'**
  String get studentViewerReadOnly;

  /// No description provided for @studentViewerSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous pour consulter ce document.'**
  String get studentViewerSessionExpired;

  /// No description provided for @studentViewerSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get studentViewerSubscriptions;

  /// No description provided for @studentViewerUnlockRest.
  ///
  /// In fr, this message translates to:
  /// **'La suite se débloque avec l\'achat de ce contenu ou un abonnement qui inclut le catalogue.'**
  String get studentViewerUnlockRest;

  /// No description provided for @subActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get subActivate;

  /// No description provided for @subActivated.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement activé.'**
  String get subActivated;

  /// No description provided for @subAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler avec mon solde à l\'échéance'**
  String get subAutoRenew;

  /// No description provided for @subAutoRenewHint.
  ///
  /// In fr, this message translates to:
  /// **'3 jours de grâce si le solde manque · résiliable à tout moment'**
  String get subAutoRenewHint;

  /// No description provided for @subBadgeCurrent.
  ///
  /// In fr, this message translates to:
  /// **'ACTUEL'**
  String get subBadgeCurrent;

  /// No description provided for @subBadgePopular.
  ///
  /// In fr, this message translates to:
  /// **'POPULAIRE'**
  String get subBadgePopular;

  /// No description provided for @subChoosePlan.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ce plan'**
  String get subChoosePlan;

  /// No description provided for @subComputingPrice.
  ///
  /// In fr, this message translates to:
  /// **'Calcul du prix…'**
  String get subComputingPrice;

  /// No description provided for @subDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Remise {code}'**
  String subDiscount(Object code);

  /// No description provided for @subDueNow.
  ///
  /// In fr, this message translates to:
  /// **'À payer maintenant'**
  String get subDueNow;

  /// No description provided for @subEnterMomoNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro Mobile Money (9 chiffres).'**
  String get subEnterMomoNumber;

  /// No description provided for @subFeatureAvailableFrom.
  ///
  /// In fr, this message translates to:
  /// **'{feature} est disponible à partir du plan {plan}.'**
  String subFeatureAvailableFrom(Object feature, Object plan);

  /// No description provided for @subFeatureOfPlan.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité {plan}'**
  String subFeatureOfPlan(Object plan);

  /// No description provided for @subFinalizeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de finaliser. Réessayez.'**
  String get subFinalizeFailed;

  /// No description provided for @subFooterTtc.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC · accès jusqu\'à la fin de la période payée en cas de résiliation'**
  String get subFooterTtc;

  /// No description provided for @subFromPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'À partir de {amount} XAF TTC/mois'**
  String subFromPerMonth(Object amount);

  /// No description provided for @subInstitutionLicenseNote.
  ///
  /// In fr, this message translates to:
  /// **'Les établissements passent par une licence (sièges élèves, année scolaire) : gérez-la depuis l\'onglet Licence de votre espace établissement.'**
  String get subInstitutionLicenseNote;

  /// No description provided for @subLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get subLater;

  /// No description provided for @subLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get subLoadError;

  /// No description provided for @subMyBalance.
  ///
  /// In fr, this message translates to:
  /// **'Mon solde'**
  String get subMyBalance;

  /// No description provided for @subNotOffered.
  ///
  /// In fr, this message translates to:
  /// **'Non proposé sur cette période'**
  String get subNotOffered;

  /// No description provided for @subOurPlans.
  ///
  /// In fr, this message translates to:
  /// **'Nos plans'**
  String get subOurPlans;

  /// No description provided for @subPaymentInitiated.
  ///
  /// In fr, this message translates to:
  /// **'Paiement initié : confirmez-le sur votre téléphone. Votre abonnement s\'active à la confirmation.'**
  String get subPaymentInitiated;

  /// No description provided for @subPerUnitTtc.
  ///
  /// In fr, this message translates to:
  /// **' XAF TTC / {unit}'**
  String subPerUnitTtc(Object unit);

  /// No description provided for @subPeriodMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get subPeriodMonthly;

  /// No description provided for @subPeriodQuarterly.
  ///
  /// In fr, this message translates to:
  /// **'Trimestriel'**
  String get subPeriodQuarterly;

  /// No description provided for @subPeriodTtc.
  ///
  /// In fr, this message translates to:
  /// **'{period} · prix TTC'**
  String subPeriodTtc(Object period);

  /// No description provided for @subPeriodYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get subPeriodYearly;

  /// No description provided for @subPleaseWait.
  ///
  /// In fr, this message translates to:
  /// **'Patientez…'**
  String get subPleaseWait;

  /// No description provided for @subPricingFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC · MTN Mobile Money, Orange Money ou solde WinPlus · résiliable à tout moment, accès jusqu\'à la fin de la période payée'**
  String get subPricingFootnote;

  /// No description provided for @subQuoteUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Devis indisponible.'**
  String get subQuoteUnavailable;

  /// No description provided for @subRenewOrChange.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler ou changer de période'**
  String get subRenewOrChange;

  /// No description provided for @subScheduleChange.
  ///
  /// In fr, this message translates to:
  /// **'Programmer le changement'**
  String get subScheduleChange;

  /// No description provided for @subSeePlans.
  ///
  /// In fr, this message translates to:
  /// **'Voir les plans'**
  String get subSeePlans;

  /// No description provided for @subStartTrial.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'essai gratuit'**
  String get subStartTrial;

  /// No description provided for @subUnitMonth.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get subUnitMonth;

  /// No description provided for @subUnitQuarter.
  ///
  /// In fr, this message translates to:
  /// **'trimestre'**
  String get subUnitQuarter;

  /// No description provided for @subUnitYear.
  ///
  /// In fr, this message translates to:
  /// **'an'**
  String get subUnitYear;

  /// No description provided for @subUnusedPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période en cours non utilisée'**
  String get subUnusedPeriod;

  /// No description provided for @svcAssignmentActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get svcAssignmentActive;

  /// No description provided for @svcAssignmentEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get svcAssignmentEnded;

  /// No description provided for @svcBalancePaymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement par solde a échoué. Réessaie.'**
  String get svcBalancePaymentFailed;

  /// No description provided for @svcBookedForOthers.
  ///
  /// In fr, this message translates to:
  /// **'Pour : {names} · payée par {payer}.'**
  String svcBookedForOthers(Object names, Object payer);

  /// No description provided for @svcBookedForYou.
  ///
  /// In fr, this message translates to:
  /// **'Réservée pour toi par {payer}{group}{count}.'**
  String svcBookedForYou(Object payer, Object group, Object count);

  /// No description provided for @svcCancelFailed.
  ///
  /// In fr, this message translates to:
  /// **'Annulation impossible.'**
  String get svcCancelFailed;

  /// No description provided for @svcCartAddCourseFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter la formation au panier.'**
  String get svcCartAddCourseFailed;

  /// No description provided for @svcDurationHours.
  ///
  /// In fr, this message translates to:
  /// **'{h} h'**
  String svcDurationHours(Object h);

  /// No description provided for @svcDurationHoursMin.
  ///
  /// In fr, this message translates to:
  /// **'{h} h {m}'**
  String svcDurationHoursMin(Object h, Object m);

  /// No description provided for @svcDurationMin.
  ///
  /// In fr, this message translates to:
  /// **'{m} min'**
  String svcDurationMin(Object m);

  /// No description provided for @svcEndorseFailed.
  ///
  /// In fr, this message translates to:
  /// **'Caution impossible.'**
  String get svcEndorseFailed;

  /// No description provided for @svcEngStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get svcEngStatusActive;

  /// No description provided for @svcEngStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get svcEngStatusCancelled;

  /// No description provided for @svcEngStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get svcEngStatusCompleted;

  /// No description provided for @svcEngStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré (sans réponse)'**
  String get svcEngStatusExpired;

  /// No description provided for @svcEngStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé par le tuteur'**
  String get svcEngStatusRejected;

  /// No description provided for @svcGenericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get svcGenericError;

  /// No description provided for @svcIdDocCni.
  ///
  /// In fr, this message translates to:
  /// **'Carte nationale d\'identité'**
  String get svcIdDocCni;

  /// No description provided for @svcIdDocDrivingLicense.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get svcIdDocDrivingLicense;

  /// No description provided for @svcIdDocOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre pièce officielle'**
  String get svcIdDocOther;

  /// No description provided for @svcIdDocPassport.
  ///
  /// In fr, this message translates to:
  /// **'Passeport'**
  String get svcIdDocPassport;

  /// No description provided for @svcIdDocResidencePermit.
  ///
  /// In fr, this message translates to:
  /// **'Titre de séjour'**
  String get svcIdDocResidencePermit;

  /// No description provided for @svcInterviewCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get svcInterviewCancelled;

  /// No description provided for @svcInterviewFailed.
  ///
  /// In fr, this message translates to:
  /// **'Non concluant'**
  String get svcInterviewFailed;

  /// No description provided for @svcInterviewNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get svcInterviewNoShow;

  /// No description provided for @svcInterviewPassed.
  ///
  /// In fr, this message translates to:
  /// **'Réussi'**
  String get svcInterviewPassed;

  /// No description provided for @svcInterviewRequested.
  ///
  /// In fr, this message translates to:
  /// **'Demandé'**
  String get svcInterviewRequested;

  /// No description provided for @svcInterviewScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Planifié'**
  String get svcInterviewScheduled;

  /// No description provided for @svcInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get svcInvalidCode;

  /// No description provided for @svcInvalidPromo.
  ///
  /// In fr, this message translates to:
  /// **'Code promo invalide.'**
  String get svcInvalidPromo;

  /// No description provided for @svcLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible'**
  String get svcLoginFailed;

  /// No description provided for @svcMaterialDraft.
  ///
  /// In fr, this message translates to:
  /// **'Support en brouillon'**
  String get svcMaterialDraft;

  /// No description provided for @svcMaterialShared.
  ///
  /// In fr, this message translates to:
  /// **'Support partagé'**
  String get svcMaterialShared;

  /// No description provided for @svcMaterialSharedWithChanges.
  ///
  /// In fr, this message translates to:
  /// **'Support modifié, non repartagé'**
  String get svcMaterialSharedWithChanges;

  /// No description provided for @svcMoneyPartial.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé en partie'**
  String get svcMoneyPartial;

  /// No description provided for @svcMoneyUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payé'**
  String get svcMoneyUnpaid;

  /// No description provided for @svcOfflineAction.
  ///
  /// In fr, this message translates to:
  /// **'Cette action nécessite une connexion internet.'**
  String get svcOfflineAction;

  /// No description provided for @svcOfflineFileMissing.
  ///
  /// In fr, this message translates to:
  /// **'Fichier hors-ligne introuvable (a-t-il été effacé par le système ?).'**
  String get svcOfflineFileMissing;

  /// No description provided for @svcOfflineNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Cette leçon n\'a pas été téléchargée.'**
  String get svcOfflineNotSaved;

  /// No description provided for @svcOfflinePlayNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Lecture hors-ligne impossible : aucun compte connecté.'**
  String get svcOfflinePlayNoAccount;

  /// No description provided for @svcOfflineSaveNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement hors-ligne impossible : aucun compte connecté.'**
  String get svcOfflineSaveNoAccount;

  /// No description provided for @svcOrderCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer la commande.'**
  String get svcOrderCreateFailed;

  /// No description provided for @svcPartyCount.
  ///
  /// In fr, this message translates to:
  /// **' · {n} élèves'**
  String svcPartyCount(Object n);

  /// No description provided for @svcPartyGroup.
  ///
  /// In fr, this message translates to:
  /// **' (groupe {name})'**
  String svcPartyGroup(Object name);

  /// No description provided for @svcPayerInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Institution'**
  String get svcPayerInstitution;

  /// No description provided for @svcPayerStudyGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe d\'étude'**
  String get svcPayerStudyGroup;

  /// No description provided for @svcPaymentInitFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'initier le paiement.'**
  String get svcPaymentInitFailed;

  /// No description provided for @svcPurchaseNotCompleted.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat n\'a pas pu être finalisé.'**
  String get svcPurchaseNotCompleted;

  /// No description provided for @svcRefundFeeDeducted.
  ///
  /// In fr, this message translates to:
  /// **'frais Mobile Money de {fee} XAF déduits'**
  String svcRefundFeeDeducted(Object fee);

  /// No description provided for @svcRefundFeesExceed.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement : les frais Mobile Money ({fee} XAF) dépassent la part remboursable.'**
  String svcRefundFeesExceed(Object fee);

  /// No description provided for @svcRefundFull.
  ///
  /// In fr, this message translates to:
  /// **' (remboursement intégral)'**
  String get svcRefundFull;

  /// No description provided for @svcRefundInstitutionWallet.
  ///
  /// In fr, this message translates to:
  /// **'le portefeuille de l\'institution'**
  String get svcRefundInstitutionWallet;

  /// No description provided for @svcRefundMyWallet.
  ///
  /// In fr, this message translates to:
  /// **'ton portefeuille WinPlus'**
  String get svcRefundMyWallet;

  /// No description provided for @svcRefundPartial.
  ///
  /// In fr, this message translates to:
  /// **' ({percent} % selon la politique du tuteur{fee})'**
  String svcRefundPartial(Object percent, Object fee);

  /// No description provided for @svcRefundTooLate.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement : annulation trop tardive selon la politique du tuteur.'**
  String get svcRefundTooLate;

  /// No description provided for @svcRefundWhoPaid.
  ///
  /// In fr, this message translates to:
  /// **'celui qui a payé'**
  String get svcRefundWhoPaid;

  /// No description provided for @svcRefundedOn.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF remboursés sur {target}{detail}.'**
  String svcRefundedOn(Object amount, Object target, Object detail);

  /// No description provided for @svcRefundedTo.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF remboursés à {name}{detail}.'**
  String svcRefundedTo(Object amount, Object name, Object detail);

  /// No description provided for @svcReplySendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la réponse.'**
  String get svcReplySendFailed;

  /// No description provided for @svcReportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Signalement impossible.'**
  String get svcReportFailed;

  /// No description provided for @svcReportHarassment.
  ///
  /// In fr, this message translates to:
  /// **'Harcèlement ou propos déplacés'**
  String get svcReportHarassment;

  /// No description provided for @svcReportIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas la personne du profil'**
  String get svcReportIdentity;

  /// No description provided for @svcReportInappropriate.
  ///
  /// In fr, this message translates to:
  /// **'Comportement inapproprié'**
  String get svcReportInappropriate;

  /// No description provided for @svcReportNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent à la séance'**
  String get svcReportNoShow;

  /// No description provided for @svcReportOffPlatform.
  ///
  /// In fr, this message translates to:
  /// **'Demande de paiement hors WinPlus'**
  String get svcReportOffPlatform;

  /// No description provided for @svcReportPoorQuality.
  ///
  /// In fr, this message translates to:
  /// **'Séance de mauvaise qualité'**
  String get svcReportPoorQuality;

  /// No description provided for @svcReportSafety.
  ///
  /// In fr, this message translates to:
  /// **'Problème de sécurité'**
  String get svcReportSafety;

  /// No description provided for @svcRequestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Demande impossible.'**
  String get svcRequestFailed;

  /// No description provided for @svcReviewSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'avis.'**
  String get svcReviewSendFailed;

  /// No description provided for @svcSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible.'**
  String get svcSendFailed;

  /// No description provided for @svcSessionStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Prévue'**
  String get svcSessionStatusConfirmed;

  /// No description provided for @svcSignupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Inscription impossible'**
  String get svcSignupFailed;

  /// No description provided for @svcStudentFallback.
  ///
  /// In fr, this message translates to:
  /// **'Élève #{id}'**
  String svcStudentFallback(Object id);

  /// No description provided for @svcTopUpDone.
  ///
  /// In fr, this message translates to:
  /// **'Recharge effectuée.'**
  String get svcTopUpDone;

  /// No description provided for @svcTutorsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos répétiteurs.'**
  String get svcTutorsLoadFailed;

  /// No description provided for @svcVerifEventIdentityApproved.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité validée'**
  String get svcVerifEventIdentityApproved;

  /// No description provided for @svcVerifEventIdentityFilesPurged.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers supprimés (conservation limitée)'**
  String get svcVerifEventIdentityFilesPurged;

  /// No description provided for @svcVerifEventIdentityRejected.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité refusée'**
  String get svcVerifEventIdentityRejected;

  /// No description provided for @svcVerifEventIdentitySubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité déposée'**
  String get svcVerifEventIdentitySubmitted;

  /// No description provided for @svcVerifEventIdentitySuperseded.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt remplacé'**
  String get svcVerifEventIdentitySuperseded;

  /// No description provided for @svcVerifEventInstitutionEndorsed.
  ///
  /// In fr, this message translates to:
  /// **'Caution d\'une institution'**
  String get svcVerifEventInstitutionEndorsed;

  /// No description provided for @svcVerifEventInstitutionRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Caution retirée'**
  String get svcVerifEventInstitutionRevoked;

  /// No description provided for @svcVerifEventInterviewCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Entretien annulé'**
  String get svcVerifEventInterviewCancelled;

  /// No description provided for @svcVerifEventInterviewFailed.
  ///
  /// In fr, this message translates to:
  /// **'Entretien non concluant'**
  String get svcVerifEventInterviewFailed;

  /// No description provided for @svcVerifEventInterviewNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent à l\'entretien'**
  String get svcVerifEventInterviewNoShow;

  /// No description provided for @svcVerifEventInterviewPassed.
  ///
  /// In fr, this message translates to:
  /// **'Entretien réussi'**
  String get svcVerifEventInterviewPassed;

  /// No description provided for @svcVerifEventInterviewRequested.
  ///
  /// In fr, this message translates to:
  /// **'Entretien demandé'**
  String get svcVerifEventInterviewRequested;

  /// No description provided for @svcVerifEventInterviewScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Entretien planifié'**
  String get svcVerifEventInterviewScheduled;

  /// No description provided for @svcVerifEventStatusUnverified.
  ///
  /// In fr, this message translates to:
  /// **'Vérification retirée'**
  String get svcVerifEventStatusUnverified;

  /// No description provided for @svcVerifEventSuspensionLifted.
  ///
  /// In fr, this message translates to:
  /// **'Suspension levée'**
  String get svcVerifEventSuspensionLifted;

  /// No description provided for @svcVerifLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ta vérification.'**
  String get svcVerifLoadFailed;

  /// No description provided for @svcVerifRouteInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Caution d\'une institution'**
  String get svcVerifRouteInstitution;

  /// No description provided for @svcVerifRouteInterview.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get svcVerifRouteInterview;

  /// No description provided for @svcWinaiLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint votre limite WinAI. Passez à un plan supérieur pour continuer.'**
  String get svcWinaiLimit;

  /// No description provided for @svcWinaiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'WinAI est momentanément indisponible. Réessayez dans quelques minutes.'**
  String get svcWinaiUnavailable;

  /// No description provided for @svcWithdrawFailed.
  ///
  /// In fr, this message translates to:
  /// **'Retrait impossible.'**
  String get svcWithdrawFailed;

  /// No description provided for @switchToLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Passer en {lang}'**
  String switchToLanguage(String lang);

  /// No description provided for @teacherAiInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Génère un quiz, une fiche, une correction…'**
  String get teacherAiInputHint;

  /// No description provided for @teacherAiSuggestCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Correction type'**
  String get teacherAiSuggestCorrection;

  /// No description provided for @teacherAiSuggestQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz Terminale C (10 QCM)'**
  String get teacherAiSuggestQuiz;

  /// No description provided for @teacherAiSuggestSheet.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de cours'**
  String get teacherAiSuggestSheet;

  /// No description provided for @teacherAiSuggestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Optimiser un titre'**
  String get teacherAiSuggestTitle;

  /// No description provided for @teacherAiTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton assistant éditorial & pédagogique'**
  String get teacherAiTagline;

  /// No description provided for @teacherBookingAcceptError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'accepter cette demande.'**
  String get teacherBookingAcceptError;

  /// No description provided for @teacherBookingAcceptMonth.
  ///
  /// In fr, this message translates to:
  /// **'Accepter le mois'**
  String get teacherBookingAcceptMonth;

  /// No description provided for @teacherBookingAssignments.
  ///
  /// In fr, this message translates to:
  /// **'Attributions'**
  String get teacherBookingAssignments;

  /// No description provided for @teacherBookingAutoMaterial.
  ///
  /// In fr, this message translates to:
  /// **'Support WinAI généré à l\'acceptation'**
  String get teacherBookingAutoMaterial;

  /// No description provided for @teacherBookingAutoMaterialHint.
  ///
  /// In fr, this message translates to:
  /// **'Décompté de ton usage WinAI ; tu le relis avant de le partager.'**
  String get teacherBookingAutoMaterialHint;

  /// No description provided for @teacherBookingBeneficiaries.
  ///
  /// In fr, this message translates to:
  /// **'{count} élève(s) :'**
  String teacherBookingBeneficiaries(Object count);

  /// No description provided for @teacherBookingCompleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de clôturer cette séance.'**
  String get teacherBookingCompleteError;

  /// No description provided for @teacherBookingConfirmedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance confirmée pour le moment.'**
  String get teacherBookingConfirmedEmpty;

  /// No description provided for @teacherBookingDeclineEngagementMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le payeur est remboursé intégralement, séance par séance ; si le mois a été payé par Mobile Money, les frais sont retenus sur ton solde.'**
  String get teacherBookingDeclineEngagementMessage;

  /// No description provided for @teacherBookingDeclineEngagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser l\'engagement entier'**
  String get teacherBookingDeclineEngagementTitle;

  /// No description provided for @teacherBookingDeclineError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de refuser cette demande.'**
  String get teacherBookingDeclineError;

  /// No description provided for @teacherBookingDeclineMessage.
  ///
  /// In fr, this message translates to:
  /// **'Celui qui a payé (élève, parent, institution ou membre du groupe) sera remboursé intégralement sur son portefeuille WinPlus ; si la séance a été payée par Mobile Money, les frais de l\'opérateur seront retenus sur ton solde.'**
  String get teacherBookingDeclineMessage;

  /// No description provided for @teacherBookingDeclineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la demande'**
  String get teacherBookingDeclineTitle;

  /// No description provided for @teacherBookingDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée : le payeur est remboursé sur son portefeuille.'**
  String get teacherBookingDeclined;

  /// No description provided for @teacherBookingDeclinedFee.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée : le payeur est remboursé, {amount} XAF de frais Mobile Money retenus sur ton solde.'**
  String teacherBookingDeclinedFee(Object amount);

  /// No description provided for @teacherBookingDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get teacherBookingDetail;

  /// No description provided for @teacherBookingDiscount.
  ///
  /// In fr, this message translates to:
  /// **'(remise {percent} %)'**
  String teacherBookingDiscount(Object percent);

  /// No description provided for @teacherBookingDisputeReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif de contestation : {reason}'**
  String teacherBookingDisputeReason(Object reason);

  /// No description provided for @teacherBookingEngagementAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Engagement accepté : toutes les séances du mois sont confirmées.'**
  String get teacherBookingEngagementAccepted;

  /// No description provided for @teacherBookingEngagementRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d\'engagement mensuel'**
  String get teacherBookingEngagementRequests;

  /// No description provided for @teacherBookingExpiresSoon.
  ///
  /// In fr, this message translates to:
  /// **'Expire bientôt'**
  String get teacherBookingExpiresSoon;

  /// No description provided for @teacherBookingGroupSession.
  ///
  /// In fr, this message translates to:
  /// **'Séance de groupe · {count} élèves'**
  String teacherBookingGroupSession(Object count);

  /// No description provided for @teacherBookingHidePrice.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le détail du prix'**
  String get teacherBookingHidePrice;

  /// No description provided for @teacherBookingMarkCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Marquer effectuée'**
  String get teacherBookingMarkCompleted;

  /// No description provided for @teacherBookingMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String teacherBookingMinutes(Object count);

  /// No description provided for @teacherBookingMinutesToAnswer.
  ///
  /// In fr, this message translates to:
  /// **'{count} min pour répondre'**
  String teacherBookingMinutesToAnswer(Object count);

  /// No description provided for @teacherBookingModeStudentHome.
  ///
  /// In fr, this message translates to:
  /// **'À domicile (élève)'**
  String get teacherBookingModeStudentHome;

  /// No description provided for @teacherBookingPaidBy.
  ///
  /// In fr, this message translates to:
  /// **'Payée par : {payer}'**
  String teacherBookingPaidBy(Object payer);

  /// No description provided for @teacherBookingPaidInAdvance.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF payés d\'avance'**
  String teacherBookingPaidInAdvance(Object amount);

  /// No description provided for @teacherBookingPaidPerSession.
  ///
  /// In fr, this message translates to:
  /// **'versés séance par séance'**
  String get teacherBookingPaidPerSession;

  /// No description provided for @teacherBookingParticipants.
  ///
  /// In fr, this message translates to:
  /// **'{who} : {names}'**
  String teacherBookingParticipants(Object who, Object names);

  /// No description provided for @teacherBookingPendingEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente pour le moment.'**
  String get teacherBookingPendingEmpty;

  /// No description provided for @teacherBookingPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes en attente'**
  String get teacherBookingPendingTitle;

  /// No description provided for @teacherBookingPrepareMaterial.
  ///
  /// In fr, this message translates to:
  /// **'Préparer le support avec WinAI'**
  String get teacherBookingPrepareMaterial;

  /// No description provided for @teacherBookingQuote.
  ///
  /// In fr, this message translates to:
  /// **'« {note} »'**
  String teacherBookingQuote(Object note);

  /// No description provided for @teacherBookingReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Motif (optionnel)'**
  String get teacherBookingReasonHint;

  /// No description provided for @teacherBookingSessionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} séances'**
  String teacherBookingSessionsCount(Object count);

  /// No description provided for @teacherBookingSettingError.
  ///
  /// In fr, this message translates to:
  /// **'Réglage impossible.'**
  String get teacherBookingSettingError;

  /// No description provided for @teacherBookingShowPrice.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail du prix'**
  String get teacherBookingShowPrice;

  /// No description provided for @teacherBookingTheStudent.
  ///
  /// In fr, this message translates to:
  /// **'l\'élève'**
  String get teacherBookingTheStudent;

  /// No description provided for @teacherBookingTopics.
  ///
  /// In fr, this message translates to:
  /// **'Sujets à travailler'**
  String get teacherBookingTopics;

  /// No description provided for @teacherBookingUpcomingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Séances à venir / à clôturer'**
  String get teacherBookingUpcomingTitle;

  /// No description provided for @teacherBookingViaAssignment.
  ///
  /// In fr, this message translates to:
  /// **'via une attribution'**
  String get teacherBookingViaAssignment;

  /// No description provided for @teacherClassAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get teacherClassAdd;

  /// No description provided for @teacherClassAddStudent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élève'**
  String get teacherClassAddStudent;

  /// No description provided for @teacherClassAddStudentError.
  ///
  /// In fr, this message translates to:
  /// **'Cet élève n\'a pas pu être ajouté.'**
  String get teacherClassAddStudentError;

  /// No description provided for @teacherClassAddStudentErrorDetail.
  ///
  /// In fr, this message translates to:
  /// **'Cet élève n\'a pas pu être ajouté (email inconnu ou déjà membre).'**
  String get teacherClassAddStudentErrorDetail;

  /// No description provided for @teacherClassAssignmentCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Le devoir n\'a pas pu être créé.'**
  String get teacherClassAssignmentCreateError;

  /// No description provided for @teacherClassAssignmentCreated.
  ///
  /// In fr, this message translates to:
  /// **'Devoir créé. Les élèves sont notifiés.'**
  String get teacherClassAssignmentCreated;

  /// No description provided for @teacherClassAssignmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre du devoir'**
  String get teacherClassAssignmentTitle;

  /// No description provided for @teacherClassAssignmentTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Devoir maison n°3'**
  String get teacherClassAssignmentTitleHint;

  /// No description provided for @teacherClassAssignmentsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Les devoirs n\'ont pas pu être chargés.'**
  String get teacherClassAssignmentsLoadError;

  /// No description provided for @teacherClassAssignmentsTab.
  ///
  /// In fr, this message translates to:
  /// **'Devoirs'**
  String get teacherClassAssignmentsTab;

  /// No description provided for @teacherClassCopies.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} copie} other{{count} copies}}'**
  String teacherClassCopies(int count);

  /// No description provided for @teacherClassCreateAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Créer le devoir'**
  String get teacherClassCreateAssignment;

  /// No description provided for @teacherClassNewAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau devoir'**
  String get teacherClassNewAssignment;

  /// No description provided for @teacherClassNoAssignments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun devoir pour l\'instant'**
  String get teacherClassNoAssignments;

  /// No description provided for @teacherClassNoStudents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève dans cette classe'**
  String get teacherClassNoStudents;

  /// No description provided for @teacherClassNoStudentsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un élève par son email WinPlus.'**
  String get teacherClassNoStudentsHint;

  /// No description provided for @teacherClassReferenceHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton propre corrigé…'**
  String get teacherClassReferenceHint;

  /// No description provided for @teacherClassReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé de référence (facultatif)'**
  String get teacherClassReferenceLabel;

  /// No description provided for @teacherClassRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get teacherClassRemove;

  /// No description provided for @teacherClassRemoveFromClass.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la classe'**
  String get teacherClassRemoveFromClass;

  /// No description provided for @teacherClassRemoveStudentBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} sera retiré(e) de « {className} ».'**
  String teacherClassRemoveStudentBody(Object name, Object className);

  /// No description provided for @teacherClassRemoveStudentError.
  ///
  /// In fr, this message translates to:
  /// **'Cet élève n\'a pas pu être retiré.'**
  String get teacherClassRemoveStudentError;

  /// No description provided for @teacherClassRemoveStudentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cet élève ?'**
  String get teacherClassRemoveStudentTitle;

  /// No description provided for @teacherClassStatementHint.
  ///
  /// In fr, this message translates to:
  /// **'Colle l\'énoncé…'**
  String get teacherClassStatementHint;

  /// No description provided for @teacherClassStatementLabel.
  ///
  /// In fr, this message translates to:
  /// **'Énoncé (génère le barème WinAI)'**
  String get teacherClassStatementLabel;

  /// No description provided for @teacherClassStudentAdded.
  ///
  /// In fr, this message translates to:
  /// **'Élève ajouté.'**
  String get teacherClassStudentAdded;

  /// No description provided for @teacherClassStudentEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'eleve@exemple.cm'**
  String get teacherClassStudentEmailHint;

  /// No description provided for @teacherClassStudentEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email WinPlus de l\'élève'**
  String get teacherClassStudentEmailLabel;

  /// No description provided for @teacherClassStudentsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Les élèves n\'ont pas pu être chargés.'**
  String get teacherClassStudentsLoadError;

  /// No description provided for @teacherClassToMark.
  ///
  /// In fr, this message translates to:
  /// **'{count} à corriger'**
  String teacherClassToMark(Object count);

  /// No description provided for @teacherClassesActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Cette action a échoué.'**
  String get teacherClassesActionFailed;

  /// No description provided for @teacherClassesAverage.
  ///
  /// In fr, this message translates to:
  /// **'{avg}% moy.'**
  String teacherClassesAverage(Object avg);

  /// No description provided for @teacherClassesCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer une classe'**
  String get teacherClassesCreate;

  /// No description provided for @teacherClassesCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Cette classe n\'a pas pu être créée (nom déjà utilisé ?).'**
  String get teacherClassesCreateError;

  /// No description provided for @teacherClassesCreated.
  ///
  /// In fr, this message translates to:
  /// **'Classe « {name} » créée.'**
  String teacherClassesCreated(Object name);

  /// No description provided for @teacherClassesDeactivateBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » contient {count} élève(s) : elle sera désactivée (pas supprimée) et retirée de la liste.'**
  String teacherClassesDeactivateBody(Object name, Object count);

  /// No description provided for @teacherClassesDeactivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la classe ?'**
  String get teacherClassesDeactivateTitle;

  /// No description provided for @teacherClassesDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement « {name} » ?'**
  String teacherClassesDeleteBody(Object name);

  /// No description provided for @teacherClassesDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la classe ?'**
  String get teacherClassesDeleteTitle;

  /// No description provided for @teacherClassesHideInactive.
  ///
  /// In fr, this message translates to:
  /// **'Masquer désactivées'**
  String get teacherClassesHideInactive;

  /// No description provided for @teacherClassesInactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get teacherClassesInactive;

  /// No description provided for @teacherClassesLevelHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Terminale'**
  String get teacherClassesLevelHint;

  /// No description provided for @teacherClassesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Vos classes n\'ont pas pu être chargées.'**
  String get teacherClassesLoadError;

  /// No description provided for @teacherClassesMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations élèves'**
  String get teacherClassesMyBookings;

  /// No description provided for @teacherClassesMyLinks.
  ///
  /// In fr, this message translates to:
  /// **'Mes liaisons directes'**
  String get teacherClassesMyLinks;

  /// No description provided for @teacherClassesName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la classe'**
  String get teacherClassesName;

  /// No description provided for @teacherClassesNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Terminale C Maths'**
  String get teacherClassesNameHint;

  /// No description provided for @teacherClassesNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe'**
  String get teacherClassesNone;

  /// No description provided for @teacherClassesNoneYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe pour le moment'**
  String get teacherClassesNoneYet;

  /// No description provided for @teacherClassesReactivateError.
  ///
  /// In fr, this message translates to:
  /// **'Cette classe n\'a pas pu être réactivée.'**
  String get teacherClassesReactivateError;

  /// No description provided for @teacherClassesRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom, niveau et année sont requis.'**
  String get teacherClassesRequired;

  /// No description provided for @teacherClassesShowInactive.
  ///
  /// In fr, this message translates to:
  /// **'Voir désactivées'**
  String get teacherClassesShowInactive;

  /// No description provided for @teacherClassesStudents.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} élève} other{{count} élèves}}'**
  String teacherClassesStudents(int count);

  /// No description provided for @teacherClassesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes classes'**
  String get teacherClassesTitle;

  /// No description provided for @teacherClassesYear.
  ///
  /// In fr, this message translates to:
  /// **'Année académique'**
  String get teacherClassesYear;

  /// No description provided for @teacherClassesYearHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 2026-2027'**
  String get teacherClassesYearHint;

  /// No description provided for @teacherContentChangeStatus.
  ///
  /// In fr, this message translates to:
  /// **'Changer le statut'**
  String get teacherContentChangeStatus;

  /// No description provided for @teacherContentComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get teacherContentComingSoon;

  /// No description provided for @teacherContentCoursesBanner.
  ///
  /// In fr, this message translates to:
  /// **'Créez et gérez vos cours structurés'**
  String get teacherContentCoursesBanner;

  /// No description provided for @teacherContentDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera définitivement supprimé.'**
  String teacherContentDeleteBody(Object title);

  /// No description provided for @teacherContentDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ?'**
  String get teacherContentDeleteTitle;

  /// No description provided for @teacherContentDownloadsShort.
  ///
  /// In fr, this message translates to:
  /// **'Téléch.'**
  String get teacherContentDownloadsShort;

  /// No description provided for @teacherContentEditInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les infos'**
  String get teacherContentEditInfo;

  /// No description provided for @teacherContentEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu.'**
  String get teacherContentEmpty;

  /// No description provided for @teacherContentManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get teacherContentManage;

  /// No description provided for @teacherContentRating.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get teacherContentRating;

  /// No description provided for @teacherContentStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get teacherContentStats;

  /// No description provided for @teacherContentStatusArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get teacherContentStatusArchived;

  /// No description provided for @teacherContentStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut changé : {status}'**
  String teacherContentStatusChanged(Object status);

  /// No description provided for @teacherContentStatusReview.
  ///
  /// In fr, this message translates to:
  /// **'En révision'**
  String get teacherContentStatusReview;

  /// No description provided for @teacherCorrectionCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get teacherCorrectionCorrect;

  /// No description provided for @teacherCorrectionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune soumission'**
  String get teacherCorrectionEmpty;

  /// No description provided for @teacherCorrectionFeedbackHint.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires et retours à l\'étudiant…'**
  String get teacherCorrectionFeedbackHint;

  /// No description provided for @teacherCorrectionFilterMarked.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé'**
  String get teacherCorrectionFilterMarked;

  /// No description provided for @teacherCorrectionGrade.
  ///
  /// In fr, this message translates to:
  /// **'Note : '**
  String get teacherCorrectionGrade;

  /// No description provided for @teacherCorrectionPendingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente'**
  String teacherCorrectionPendingCount(Object count);

  /// No description provided for @teacherCorrectionQueueTitle.
  ///
  /// In fr, this message translates to:
  /// **'File de corrections'**
  String get teacherCorrectionQueueTitle;

  /// No description provided for @teacherCorrectionSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la correction'**
  String get teacherCorrectionSend;

  /// No description provided for @teacherCorrectionSendError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi.'**
  String get teacherCorrectionSendError;

  /// No description provided for @teacherCorrectionSent.
  ///
  /// In fr, this message translates to:
  /// **'Correction envoyée à {name}.'**
  String teacherCorrectionSent(Object name);

  /// No description provided for @teacherCorrectionSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corriger : {name}'**
  String teacherCorrectionSheetTitle(Object name);

  /// No description provided for @teacherCorrectionView.
  ///
  /// In fr, this message translates to:
  /// **'Voir la correction'**
  String get teacherCorrectionView;

  /// No description provided for @teacherCoursesCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get teacherCoursesCopyLink;

  /// No description provided for @teacherCoursesCreateOnWeb.
  ///
  /// In fr, this message translates to:
  /// **'La création et l\'édition des formations se font sur le site WinPlus, depuis votre espace enseignant, avec le même compte :\n\n{url}\n\nVos formations apparaissent ensuite ici.'**
  String teacherCoursesCreateOnWeb(Object url);

  /// No description provided for @teacherCoursesCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une formation'**
  String get teacherCoursesCreateTitle;

  /// No description provided for @teacherCoursesDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. La formation « {title} » sera définitivement supprimée.'**
  String teacherCoursesDeleteBody(Object title);

  /// No description provided for @teacherCoursesDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer la formation.'**
  String get teacherCoursesDeleteError;

  /// No description provided for @teacherCoursesDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la formation ?'**
  String get teacherCoursesDeleteTitle;

  /// No description provided for @teacherCoursesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Formation supprimée.'**
  String get teacherCoursesDeleted;

  /// No description provided for @teacherCoursesDetailError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails.'**
  String get teacherCoursesDetailError;

  /// No description provided for @teacherCoursesEmptyAll.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore de formation.'**
  String get teacherCoursesEmptyAll;

  /// No description provided for @teacherCoursesEmptyStatus.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formation avec ce statut.'**
  String get teacherCoursesEmptyStatus;

  /// No description provided for @teacherCoursesEnrolled.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} inscrit} other{{count} inscrits}}'**
  String teacherCoursesEnrolled(int count);

  /// No description provided for @teacherCoursesEnrolledMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} inscrits'**
  String teacherCoursesEnrolledMany(Object count);

  /// No description provided for @teacherCoursesLessons.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} leçon} other{{count} leçons}}'**
  String teacherCoursesLessons(int count);

  /// No description provided for @teacherCoursesLimitPending.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente de validation'**
  String teacherCoursesLimitPending(Object count);

  /// No description provided for @teacherCoursesLimitPublished.
  ///
  /// In fr, this message translates to:
  /// **'Formations publiées : {published} / {max}'**
  String teacherCoursesLimitPublished(Object published, Object max);

  /// No description provided for @teacherCoursesLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'limite de votre plan atteinte : passez à un plan supérieur pour en publier davantage.'**
  String get teacherCoursesLimitReached;

  /// No description provided for @teacherCoursesLimitUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan permet de publier un nombre illimité de formations.'**
  String get teacherCoursesLimitUnlimited;

  /// No description provided for @teacherCoursesLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié : ouvrez-le dans votre navigateur.'**
  String get teacherCoursesLinkCopied;

  /// No description provided for @teacherCoursesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les formations.'**
  String get teacherCoursesLoadError;

  /// No description provided for @teacherCoursesSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre à validation'**
  String get teacherCoursesSubmit;

  /// No description provided for @teacherCoursesSubmitError.
  ///
  /// In fr, this message translates to:
  /// **'La formation n\'a pas pu être soumise.'**
  String get teacherCoursesSubmitError;

  /// No description provided for @teacherCoursesSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Formation soumise à validation.'**
  String get teacherCoursesSubmitted;

  /// No description provided for @teacherCoursesViewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir détails'**
  String get teacherCoursesViewDetails;

  /// No description provided for @teacherDashActiveStudents.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants actifs'**
  String get teacherDashActiveStudents;

  /// No description provided for @teacherDashAvgRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get teacherDashAvgRating;

  /// No description provided for @teacherDashAvgShort.
  ///
  /// In fr, this message translates to:
  /// **'note moy.'**
  String get teacherDashAvgShort;

  /// No description provided for @teacherDashDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get teacherDashDownloads;

  /// No description provided for @teacherDashDownloadsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} téléch.'**
  String teacherDashDownloadsCount(Object count);

  /// No description provided for @teacherDashLast4Weeks.
  ///
  /// In fr, this message translates to:
  /// **'4 dernières semaines'**
  String get teacherDashLast4Weeks;

  /// No description provided for @teacherDashMonthRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus du mois'**
  String get teacherDashMonthRevenue;

  /// No description provided for @teacherDashNoContent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu publié.'**
  String get teacherDashNoContent;

  /// No description provided for @teacherDashOutOf5.
  ///
  /// In fr, this message translates to:
  /// **'Sur 5'**
  String get teacherDashOutOf5;

  /// No description provided for @teacherDashPlan.
  ///
  /// In fr, this message translates to:
  /// **'PLAN {plan}'**
  String teacherDashPlan(Object plan);

  /// No description provided for @teacherDashPublished.
  ///
  /// In fr, this message translates to:
  /// **'publiés'**
  String get teacherDashPublished;

  /// No description provided for @teacherDashPublishedContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus publiés'**
  String get teacherDashPublishedContent;

  /// No description provided for @teacherDashRecentContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus récents'**
  String get teacherDashRecentContent;

  /// No description provided for @teacherDashShareLabel.
  ///
  /// In fr, this message translates to:
  /// **'Part sur vos séances : '**
  String get teacherDashShareLabel;

  /// No description provided for @teacherDashShareValue.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % de vos revenus'**
  String teacherDashShareValue(Object percent);

  /// No description provided for @teacherDashThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF ce mois'**
  String teacherDashThisMonth(Object amount);

  /// No description provided for @teacherGroupApplyFlat.
  ///
  /// In fr, this message translates to:
  /// **'Prix fixe'**
  String get teacherGroupApplyFlat;

  /// No description provided for @teacherGroupApplyPerStudent.
  ///
  /// In fr, this message translates to:
  /// **'Prix par élève'**
  String get teacherGroupApplyPerStudent;

  /// No description provided for @teacherGroupBasedOn.
  ///
  /// In fr, this message translates to:
  /// **'(d\'après {count} tuteurs)'**
  String teacherGroupBasedOn(Object count);

  /// No description provided for @teacherGroupEstimate.
  ///
  /// In fr, this message translates to:
  /// **'(estimation)'**
  String get teacherGroupEstimate;

  /// No description provided for @teacherGroupFlatExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 150 % : une séance individuelle à 6 000 XAF coûte 9 000 XAF pour le groupe, quel que soit le nombre d\'élèves.'**
  String get teacherGroupFlatExample;

  /// No description provided for @teacherGroupFlatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix du groupe (% du prix individuel)'**
  String get teacherGroupFlatLabel;

  /// No description provided for @teacherGroupFlatLine.
  ///
  /// In fr, this message translates to:
  /// **'Ou prix fixe pour le groupe : {percent} % du prix individuel'**
  String teacherGroupFlatLine(Object percent);

  /// No description provided for @teacherGroupIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un parent, une institution ou un groupe d\'étude peut réserver pour plusieurs élèves. Une séance de groupe occupe ton créneau une seule fois.'**
  String get teacherGroupIntro;

  /// No description provided for @teacherGroupMaxSizeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taille maximale du groupe (élèves)'**
  String get teacherGroupMaxSizeLabel;

  /// No description provided for @teacherGroupMaxSizeLine.
  ///
  /// In fr, this message translates to:
  /// **'Taille maximale : {count} élèves'**
  String teacherGroupMaxSizeLine(Object count);

  /// No description provided for @teacherGroupMethodFlat.
  ///
  /// In fr, this message translates to:
  /// **'Prix fixe pour le groupe'**
  String get teacherGroupMethodFlat;

  /// No description provided for @teacherGroupMethodNone.
  ///
  /// In fr, this message translates to:
  /// **'Individuel seulement'**
  String get teacherGroupMethodNone;

  /// No description provided for @teacherGroupMethodPerStudent.
  ///
  /// In fr, this message translates to:
  /// **'Prix par élève dégressif'**
  String get teacherGroupMethodPerStudent;

  /// No description provided for @teacherGroupPerStudentLine.
  ///
  /// In fr, this message translates to:
  /// **'Prix par élève, dès {count} élèves : −{percent} %'**
  String teacherGroupPerStudentLine(Object count, Object percent);

  /// No description provided for @teacherGroupStudents.
  ///
  /// In fr, this message translates to:
  /// **'{count} élèves'**
  String teacherGroupStudents(Object count);

  /// No description provided for @teacherGroupSubjectsFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisis d\'abord tes matières.'**
  String get teacherGroupSubjectsFirst;

  /// No description provided for @teacherGroupSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Proposer (WinAI)'**
  String get teacherGroupSuggest;

  /// No description provided for @teacherGroupSuggestError.
  ///
  /// In fr, this message translates to:
  /// **'WinAI n\'a pas pu proposer de réglages de groupe pour l\'instant.'**
  String get teacherGroupSuggestError;

  /// No description provided for @teacherGroupSuggested.
  ///
  /// In fr, this message translates to:
  /// **'Réglages proposés par WinAI'**
  String get teacherGroupSuggested;

  /// No description provided for @teacherGroupTierHint.
  ///
  /// In fr, this message translates to:
  /// **'Seul le palier le plus haut atteint s\'applique. Sans palier, chaque élève paie le prix individuel.'**
  String get teacherGroupTierHint;

  /// No description provided for @teacherGroupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Séances de groupe'**
  String get teacherGroupTitle;

  /// No description provided for @teacherLinksInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un élève'**
  String get teacherLinksInvite;

  /// No description provided for @teacherLinksInviteSent.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée !'**
  String get teacherLinksInviteSent;

  /// No description provided for @teacherLinksLinkedTab.
  ///
  /// In fr, this message translates to:
  /// **'Liés'**
  String get teacherLinksLinkedTab;

  /// No description provided for @teacherLinksNoLinked.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève lié'**
  String get teacherLinksNoLinked;

  /// No description provided for @teacherLinksNoPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucune invitation en attente'**
  String get teacherLinksNoPending;

  /// No description provided for @teacherLinksSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, email ou téléphone…'**
  String get teacherLinksSearchHint;

  /// No description provided for @teacherLinksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes liaisons élèves'**
  String get teacherLinksTitle;

  /// No description provided for @teacherPricingAddMod.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter une modulation'**
  String get teacherPricingAddMod;

  /// No description provided for @teacherPricingAddRate.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter un tarif'**
  String get teacherPricingAddRate;

  /// No description provided for @teacherPricingAddTier.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un palier'**
  String get teacherPricingAddTier;

  /// No description provided for @teacherPricingAddTierPlus.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter un palier'**
  String get teacherPricingAddTierPlus;

  /// No description provided for @teacherPricingAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Toute la journée'**
  String get teacherPricingAllDay;

  /// No description provided for @teacherPricingAllModes.
  ///
  /// In fr, this message translates to:
  /// **'Tous modes'**
  String get teacherPricingAllModes;

  /// No description provided for @teacherPricingBaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tarif de base par matière et par mode'**
  String get teacherPricingBaseTitle;

  /// No description provided for @teacherPricingDurHint.
  ///
  /// In fr, this message translates to:
  /// **'Seul le palier le plus haut atteint s\'applique.'**
  String get teacherPricingDurHint;

  /// No description provided for @teacherPricingDurTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dégressivité selon la durée'**
  String get teacherPricingDurTitle;

  /// No description provided for @teacherPricingEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get teacherPricingEnd;

  /// No description provided for @teacherPricingFrom.
  ///
  /// In fr, this message translates to:
  /// **'Dès '**
  String get teacherPricingFrom;

  /// No description provided for @teacherPricingGridIntro.
  ///
  /// In fr, this message translates to:
  /// **'Sans grille, ton tarif horaire s\'applique partout. Facturation au prorata des tranches de 30 min ; le prix exact est calculé par WinPlus et montré à l\'élève avant paiement.'**
  String get teacherPricingGridIntro;

  /// No description provided for @teacherPricingGridTitle.
  ///
  /// In fr, this message translates to:
  /// **'Grille tarifaire (facultatif)'**
  String get teacherPricingGridTitle;

  /// No description provided for @teacherPricingIgnore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get teacherPricingIgnore;

  /// No description provided for @teacherPricingInPerson.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel'**
  String get teacherPricingInPerson;

  /// No description provided for @teacherPricingModExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. +20 % le soir, −10 % en matinée.'**
  String get teacherPricingModExample;

  /// No description provided for @teacherPricingModName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (ex. Soir)'**
  String get teacherPricingModName;

  /// No description provided for @teacherPricingModTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modulation par créneau'**
  String get teacherPricingModTitle;

  /// No description provided for @teacherPricingRemoveMod.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette modulation'**
  String get teacherPricingRemoveMod;

  /// No description provided for @teacherPricingRemoveRate.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce tarif'**
  String get teacherPricingRemoveRate;

  /// No description provided for @teacherPricingRemoveTier.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce palier'**
  String get teacherPricingRemoveTier;

  /// No description provided for @teacherPricingSubjectsFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisis d\'abord tes matières (étape 1).'**
  String get teacherPricingSubjectsFirst;

  /// No description provided for @teacherPricingSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une grille (WinAI)'**
  String get teacherPricingSuggest;

  /// No description provided for @teacherPricingSuggestError.
  ///
  /// In fr, this message translates to:
  /// **'WinAI n\'a pas pu proposer de grille.'**
  String get teacherPricingSuggestError;

  /// No description provided for @teacherPricingSuggested.
  ///
  /// In fr, this message translates to:
  /// **'Grille proposée par WinAI'**
  String get teacherPricingSuggested;

  /// No description provided for @teacherProfileActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get teacherProfileActivate;

  /// No description provided for @teacherProfileActivateError.
  ///
  /// In fr, this message translates to:
  /// **'Complète les champs essentiels avant d\'activer ton profil.'**
  String get teacherProfileActivateError;

  /// No description provided for @teacherProfileActivated.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil tuteur est visible dans la recherche !'**
  String get teacherProfileActivated;

  /// No description provided for @teacherProfileActiveAfterSuspension.
  ///
  /// In fr, this message translates to:
  /// **'Actif après examen de la suspension'**
  String get teacherProfileActiveAfterSuspension;

  /// No description provided for @teacherProfileActiveAfterVerification.
  ///
  /// In fr, this message translates to:
  /// **'Actif après vérification'**
  String get teacherProfileActiveAfterVerification;

  /// No description provided for @teacherProfileAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter cette zone'**
  String get teacherProfileAddZone;

  /// No description provided for @teacherProfileAiSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion WinAI'**
  String get teacherProfileAiSuggestion;

  /// No description provided for @teacherProfileAiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'WinAI indisponible pour l\'instant.'**
  String get teacherProfileAiUnavailable;

  /// No description provided for @teacherProfileAtMyHome.
  ///
  /// In fr, this message translates to:
  /// **'À domicile chez moi'**
  String get teacherProfileAtMyHome;

  /// No description provided for @teacherProfileAtStudentHome.
  ///
  /// In fr, this message translates to:
  /// **'À domicile chez l\'élève'**
  String get teacherProfileAtStudentHome;

  /// No description provided for @teacherProfileBackToEdit.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'édition'**
  String get teacherProfileBackToEdit;

  /// No description provided for @teacherProfileBio.
  ///
  /// In fr, this message translates to:
  /// **'Bio courte (300 caractères max)'**
  String get teacherProfileBio;

  /// No description provided for @teacherProfileBlockedDefault.
  ///
  /// In fr, this message translates to:
  /// **'Le présentiel est réservé aux tuteurs vérifiés.'**
  String get teacherProfileBlockedDefault;

  /// No description provided for @teacherProfileBookPreview.
  ///
  /// In fr, this message translates to:
  /// **'Réserver (aperçu  désactivé)'**
  String get teacherProfileBookPreview;

  /// No description provided for @teacherProfileChooseCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une ville…'**
  String get teacherProfileChooseCity;

  /// No description provided for @teacherProfileCityOrDistrictHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la ville / quartier'**
  String get teacherProfileCityOrDistrictHint;

  /// No description provided for @teacherProfileCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Complétude du profil'**
  String get teacherProfileCompletion;

  /// No description provided for @teacherProfileDiploma.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme (facultatif, badge « Diplôme vérifié », sans effet sur le présentiel)'**
  String get teacherProfileDiploma;

  /// No description provided for @teacherProfileDistrictHint.
  ///
  /// In fr, this message translates to:
  /// **'Quartier (optionnel)…'**
  String get teacherProfileDistrictHint;

  /// No description provided for @teacherProfileDocStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String teacherProfileDocStatus(Object status);

  /// No description provided for @teacherProfileDocUrlHint.
  ///
  /// In fr, this message translates to:
  /// **'URL du document uploadé'**
  String get teacherProfileDocUrlHint;

  /// No description provided for @teacherProfileFullRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement total si annulé au moins'**
  String get teacherProfileFullRefund;

  /// No description provided for @teacherProfileGetVerified.
  ///
  /// In fr, this message translates to:
  /// **'Me faire vérifier'**
  String get teacherProfileGetVerified;

  /// No description provided for @teacherProfileHourlyRate.
  ///
  /// In fr, this message translates to:
  /// **'Tarif horaire (XAF)'**
  String get teacherProfileHourlyRate;

  /// No description provided for @teacherProfileHourlyRateHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 3000'**
  String get teacherProfileHourlyRateHint;

  /// No description provided for @teacherProfileHours.
  ///
  /// In fr, this message translates to:
  /// **'{count} h'**
  String teacherProfileHours(Object count);

  /// No description provided for @teacherProfileHoursBefore.
  ///
  /// In fr, this message translates to:
  /// **'h avant'**
  String get teacherProfileHoursBefore;

  /// No description provided for @teacherProfileKeptSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Tes choix présentiels restent enregistrés et redeviendront actifs à la levée de la suspension.'**
  String get teacherProfileKeptSuspended;

  /// No description provided for @teacherProfileKeptUnverified.
  ///
  /// In fr, this message translates to:
  /// **'Tes choix présentiels sont enregistrés et deviendront actifs dès ta vérification.'**
  String get teacherProfileKeptUnverified;

  /// No description provided for @teacherProfileLevelEnam.
  ///
  /// In fr, this message translates to:
  /// **'ENAM Administration'**
  String get teacherProfileLevelEnam;

  /// No description provided for @teacherProfileLevelsCovered.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux couverts'**
  String get teacherProfileLevelsCovered;

  /// No description provided for @teacherProfileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton profil tuteur.'**
  String get teacherProfileLoadError;

  /// No description provided for @teacherProfileMaxPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'Séances max par semaine'**
  String get teacherProfileMaxPerWeek;

  /// No description provided for @teacherProfileModes.
  ///
  /// In fr, this message translates to:
  /// **'Modes d\'intervention'**
  String get teacherProfileModes;

  /// No description provided for @teacherProfileMonthlyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance ; tu es payé séance par séance.'**
  String get teacherProfileMonthlyDesc;

  /// No description provided for @teacherProfileMonthlyDiscountHint.
  ///
  /// In fr, this message translates to:
  /// **'Remise mensuelle en % (0 à {max})'**
  String teacherProfileMonthlyDiscountHint(Object max);

  /// No description provided for @teacherProfileMonthlyHint.
  ///
  /// In fr, this message translates to:
  /// **'Appliquée au prix de chaque séance du mois, calculé par ta grille.'**
  String get teacherProfileMonthlyHint;

  /// No description provided for @teacherProfileMonthlyToggle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer l\'engagement mensuel'**
  String get teacherProfileMonthlyToggle;

  /// No description provided for @teacherProfileNeutralPlace.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel en espace neutre'**
  String get teacherProfileNeutralPlace;

  /// No description provided for @teacherProfileNoRefund.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement à moins de'**
  String get teacherProfileNoRefund;

  /// No description provided for @teacherProfileNoneF.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get teacherProfileNoneF;

  /// No description provided for @teacherProfileNoneM.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get teacherProfileNoneM;

  /// No description provided for @teacherProfileNotice.
  ///
  /// In fr, this message translates to:
  /// **'Délai de préavis minimum'**
  String get teacherProfileNotice;

  /// No description provided for @teacherProfileOnHoliday.
  ///
  /// In fr, this message translates to:
  /// **'En vacances'**
  String get teacherProfileOnHoliday;

  /// No description provided for @teacherProfileOnlineViaWinplus.
  ///
  /// In fr, this message translates to:
  /// **'En ligne via WinPlus'**
  String get teacherProfileOnlineViaWinplus;

  /// No description provided for @teacherProfileOtherCity.
  ///
  /// In fr, this message translates to:
  /// **'Autre ville'**
  String get teacherProfileOtherCity;

  /// No description provided for @teacherProfilePartialRefund.
  ///
  /// In fr, this message translates to:
  /// **'Ensuite, part remboursée'**
  String get teacherProfilePartialRefund;

  /// No description provided for @teacherProfilePolicyBounds.
  ///
  /// In fr, this message translates to:
  /// **'Limites fixées par WinPlus : remboursement total entre {fullMin} h et {fullMax} h avant, part remboursée de {partialMin} à {partialMax} %, aucun remboursement en dessous de {noMin} à {noMax} h.'**
  String teacherProfilePolicyBounds(Object fullMin, Object fullMax,
      Object partialMin, Object partialMax, Object noMin, Object noMax);

  /// No description provided for @teacherProfilePolicyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ce que l\'élève récupère s\'il annule lui-même (les frais Mobile Money restent à sa charge).'**
  String get teacherProfilePolicyIntro;

  /// No description provided for @teacherProfilePreview.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon profil comme un élève'**
  String get teacherProfilePreview;

  /// No description provided for @teacherProfilePrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get teacherProfilePrevious;

  /// No description provided for @teacherProfileProTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre professionnel'**
  String get teacherProfileProTitle;

  /// No description provided for @teacherProfileProTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Prof de Maths  Terminale C/D'**
  String get teacherProfileProTitleHint;

  /// No description provided for @teacherProfileRate.
  ///
  /// In fr, this message translates to:
  /// **'Tarif'**
  String get teacherProfileRate;

  /// No description provided for @teacherProfileRateSuggested.
  ///
  /// In fr, this message translates to:
  /// **'{rate} XAF/h suggéré ({low}-{high}). {explanation}'**
  String teacherProfileRateSuggested(
      Object rate, Object low, Object high, Object explanation);

  /// No description provided for @teacherProfileReviewsSoon.
  ///
  /// In fr, this message translates to:
  /// **'Avis bientôt disponibles'**
  String get teacherProfileReviewsSoon;

  /// No description provided for @teacherProfileSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement.'**
  String get teacherProfileSaveError;

  /// No description provided for @teacherProfileSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get teacherProfileSaving;

  /// No description provided for @teacherProfileSpecCatchUp.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage express'**
  String get teacherProfileSpecCatchUp;

  /// No description provided for @teacherProfileSpecContestPrep.
  ///
  /// In fr, this message translates to:
  /// **'Préparation concours'**
  String get teacherProfileSpecContestPrep;

  /// No description provided for @teacherProfileSpecHoliday.
  ///
  /// In fr, this message translates to:
  /// **'Cours de vacances'**
  String get teacherProfileSpecHoliday;

  /// No description provided for @teacherProfileSpecSchoolSupport.
  ///
  /// In fr, this message translates to:
  /// **'Soutien scolaire'**
  String get teacherProfileSpecSchoolSupport;

  /// No description provided for @teacherProfileSpecialties.
  ///
  /// In fr, this message translates to:
  /// **'Spécialités'**
  String get teacherProfileSpecialties;

  /// No description provided for @teacherProfileStepSaved.
  ///
  /// In fr, this message translates to:
  /// **'Étape enregistrée.'**
  String get teacherProfileStepSaved;

  /// No description provided for @teacherProfileStyle.
  ///
  /// In fr, this message translates to:
  /// **'Style pédagogique'**
  String get teacherProfileStyle;

  /// No description provided for @teacherProfileStyleInteractive.
  ///
  /// In fr, this message translates to:
  /// **'Interactif'**
  String get teacherProfileStyleInteractive;

  /// No description provided for @teacherProfileStyleMixed.
  ///
  /// In fr, this message translates to:
  /// **'Mixte'**
  String get teacherProfileStyleMixed;

  /// No description provided for @teacherProfileStyleStructured.
  ///
  /// In fr, this message translates to:
  /// **'Structuré'**
  String get teacherProfileStyleStructured;

  /// No description provided for @teacherProfileSubjectsTaught.
  ///
  /// In fr, this message translates to:
  /// **'Matières enseignées'**
  String get teacherProfileSubjectsTaught;

  /// No description provided for @teacherProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode Tuteur'**
  String get teacherProfileTitle;

  /// No description provided for @teacherProfileTrialOffered.
  ///
  /// In fr, this message translates to:
  /// **'Séance d\'essai proposée'**
  String get teacherProfileTrialOffered;

  /// No description provided for @teacherProfileTrialPriceHint.
  ///
  /// In fr, this message translates to:
  /// **'Prix (0 = gratuite)'**
  String get teacherProfileTrialPriceHint;

  /// No description provided for @teacherProfileTrialToggle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une séance d\'essai'**
  String get teacherProfileTrialToggle;

  /// No description provided for @teacherProfileUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimité'**
  String get teacherProfileUnlimited;

  /// No description provided for @teacherProfileUseRate.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce tarif'**
  String get teacherProfileUseRate;

  /// No description provided for @teacherProfileVerifOpen.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié : présentiel ouvert'**
  String get teacherProfileVerifOpen;

  /// No description provided for @teacherProfileVerifRoutes.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité, entretien ou caution d\'institution'**
  String get teacherProfileVerifRoutes;

  /// No description provided for @teacherProfileVerifSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel suspendu en attendant un examen'**
  String get teacherProfileVerifSuspended;

  /// No description provided for @teacherProfileVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification pour le présentiel'**
  String get teacherProfileVerification;

  /// No description provided for @teacherProfileVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo de présentation (optionnel)'**
  String get teacherProfileVideo;

  /// No description provided for @teacherProfileWeeklySlots.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux hebdomadaires (tap pour activer)'**
  String get teacherProfileWeeklySlots;

  /// No description provided for @teacherProfileZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones géographiques couvertes'**
  String get teacherProfileZones;

  /// No description provided for @teacherPublishAmountHint.
  ///
  /// In fr, this message translates to:
  /// **'Montant en XAF (ex: 500)'**
  String get teacherPublishAmountHint;

  /// No description provided for @teacherPublishChooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get teacherPublishChooseFile;

  /// No description provided for @teacherPublishDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le contenu (objectifs, niveau, contenu…)'**
  String get teacherPublishDescriptionHint;

  /// No description provided for @teacherPublishFileRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un fichier.'**
  String get teacherPublishFileRequired;

  /// No description provided for @teacherPublishFreePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix libre'**
  String get teacherPublishFreePrice;

  /// No description provided for @teacherPublishFreePriceHint.
  ///
  /// In fr, this message translates to:
  /// **'Fixez votre propre prix en XAF'**
  String get teacherPublishFreePriceHint;

  /// No description provided for @teacherPublishNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau. Réessayez.'**
  String get teacherPublishNetworkError;

  /// No description provided for @teacherPublishReviewNote.
  ///
  /// In fr, this message translates to:
  /// **'Votre contenu sera examiné avant d\'être publié (24-48h)'**
  String get teacherPublishReviewNote;

  /// No description provided for @teacherPublishSizeBytes.
  ///
  /// In fr, this message translates to:
  /// **'{size} o'**
  String teacherPublishSizeBytes(Object size);

  /// No description provided for @teacherPublishSizeKb.
  ///
  /// In fr, this message translates to:
  /// **'{size} Ko'**
  String teacherPublishSizeKb(Object size);

  /// No description provided for @teacherPublishSizeMb.
  ///
  /// In fr, this message translates to:
  /// **'{size} Mo'**
  String teacherPublishSizeMb(Object size);

  /// No description provided for @teacherPublishSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Publier pour révision'**
  String get teacherPublishSubmit;

  /// No description provided for @teacherPublishSubmitFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la soumission. Réessayez.'**
  String get teacherPublishSubmitFailed;

  /// No description provided for @teacherPublishSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Contenu soumis pour révision !'**
  String get teacherPublishSubmitted;

  /// No description provided for @teacherPublishSubscriptionOnly.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement uniquement'**
  String get teacherPublishSubscriptionOnly;

  /// No description provided for @teacherPublishSubscriptionOnlyHint.
  ///
  /// In fr, this message translates to:
  /// **'Accessible à tous les abonnés'**
  String get teacherPublishSubscriptionOnlyHint;

  /// No description provided for @teacherPublishTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier un contenu'**
  String get teacherPublishTitle;

  /// No description provided for @teacherPublishTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: BAC C Mathématiques 2024'**
  String get teacherPublishTitleHint;

  /// No description provided for @teacherPublishTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un titre.'**
  String get teacherPublishTitleRequired;

  /// No description provided for @teacherPublishType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get teacherPublishType;

  /// No description provided for @teacherPublishTypePack.
  ///
  /// In fr, this message translates to:
  /// **'Pack'**
  String get teacherPublishTypePack;

  /// No description provided for @teacherPublishTypeSheet.
  ///
  /// In fr, this message translates to:
  /// **'Fiche'**
  String get teacherPublishTypeSheet;

  /// No description provided for @teacherPublishYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get teacherPublishYear;

  /// No description provided for @teacherPublishYearHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 2024'**
  String get teacherPublishYearHint;

  /// No description provided for @teacherSession30Min.
  ///
  /// In fr, this message translates to:
  /// **'30 min'**
  String get teacherSession30Min;

  /// No description provided for @teacherSession3h.
  ///
  /// In fr, this message translates to:
  /// **'3h'**
  String get teacherSession3h;

  /// No description provided for @teacherSessionCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer la session'**
  String get teacherSessionCreateButton;

  /// No description provided for @teacherSessionCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création.'**
  String get teacherSessionCreateError;

  /// No description provided for @teacherSessionCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une session'**
  String get teacherSessionCreateTitle;

  /// No description provided for @teacherSessionCreated.
  ///
  /// In fr, this message translates to:
  /// **'Session créée !'**
  String get teacherSessionCreated;

  /// No description provided for @teacherSessionCreatedHint.
  ///
  /// In fr, this message translates to:
  /// **'Les étudiants inscrits recevront une notification.'**
  String get teacherSessionCreatedHint;

  /// No description provided for @teacherSessionDateHint.
  ///
  /// In fr, this message translates to:
  /// **'25 août 2026 à 14h00'**
  String get teacherSessionDateHint;

  /// No description provided for @teacherSessionDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get teacherSessionDateLabel;

  /// No description provided for @teacherSessionDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée : {minutes} minutes'**
  String teacherSessionDuration(Object minutes);

  /// No description provided for @teacherSessionLinkLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lien de la session (Zoom, Meet…)'**
  String get teacherSessionLinkLabel;

  /// No description provided for @teacherSessionMaxStudents.
  ///
  /// In fr, this message translates to:
  /// **'Max étudiants : {count}'**
  String teacherSessionMaxStudents(Object count);

  /// No description provided for @teacherSessionTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Révision Dérivées  BAC C'**
  String get teacherSessionTitleHint;

  /// No description provided for @teacherSessionTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la session *'**
  String get teacherSessionTitleLabel;

  /// No description provided for @teacherSessionsDemo1.
  ///
  /// In fr, this message translates to:
  /// **'Révision Dérivées  Tle C'**
  String get teacherSessionsDemo1;

  /// No description provided for @teacherSessionsDemo2.
  ///
  /// In fr, this message translates to:
  /// **'Correction épreuve Physique'**
  String get teacherSessionsDemo2;

  /// No description provided for @teacherSessionsPlan.
  ///
  /// In fr, this message translates to:
  /// **'Planifier une session'**
  String get teacherSessionsPlan;

  /// No description provided for @teacherSessionsSoon.
  ///
  /// In fr, this message translates to:
  /// **'● Bientôt'**
  String get teacherSessionsSoon;

  /// No description provided for @teacherSessionsToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui, {weekday} {date}'**
  String teacherSessionsToday(Object weekday, Object date);

  /// No description provided for @teacherSessionsViewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get teacherSessionsViewDetails;

  /// No description provided for @teacherVerifActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get teacherVerifActive;

  /// No description provided for @teacherVerifAttach.
  ///
  /// In fr, this message translates to:
  /// **'Joindre ma pièce et mon selfie à l\'entretien'**
  String get teacherVerifAttach;

  /// No description provided for @teacherVerifAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Tes disponibilités'**
  String get teacherVerifAvailability;

  /// No description provided for @teacherVerifAvailabilityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : mardi et jeudi après 17 h'**
  String get teacherVerifAvailabilityHint;

  /// No description provided for @teacherVerifBack.
  ///
  /// In fr, this message translates to:
  /// **'Verso (si besoin)'**
  String get teacherVerifBack;

  /// No description provided for @teacherVerifCameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo indisponible : choisis plutôt une photo de ton visage dans tes fichiers.'**
  String get teacherVerifCameraUnavailable;

  /// No description provided for @teacherVerifCancelRequest.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get teacherVerifCancelRequest;

  /// No description provided for @teacherVerifCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande annulée.'**
  String get teacherVerifCancelled;

  /// No description provided for @teacherVerifChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get teacherVerifChoose;

  /// No description provided for @teacherVerifCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Douala, Yaoundé…'**
  String get teacherVerifCityHint;

  /// No description provided for @teacherVerifDocType.
  ///
  /// In fr, this message translates to:
  /// **'Type de pièce'**
  String get teacherVerifDocType;

  /// No description provided for @teacherVerifFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier'**
  String get teacherVerifFile;

  /// No description provided for @teacherVerifFileLine.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {fileName}'**
  String teacherVerifFileLine(Object label, Object fileName);

  /// No description provided for @teacherVerifFileTooBig.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (8 Mo maximum).'**
  String get teacherVerifFileTooBig;

  /// No description provided for @teacherVerifFront.
  ///
  /// In fr, this message translates to:
  /// **'Recto de la pièce'**
  String get teacherVerifFront;

  /// No description provided for @teacherVerifHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get teacherVerifHistory;

  /// No description provided for @teacherVerifIdentityOk.
  ///
  /// In fr, this message translates to:
  /// **'Ta pièce d\'identité est validée.'**
  String get teacherVerifIdentityOk;

  /// No description provided for @teacherVerifIdentityText.
  ///
  /// In fr, this message translates to:
  /// **'Un administrateur compare la photo de ta pièce et ton visage.'**
  String get teacherVerifIdentityText;

  /// No description provided for @teacherVerifIdentityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité et selfie'**
  String get teacherVerifIdentityTitle;

  /// No description provided for @teacherVerifInactiveLink.
  ///
  /// In fr, this message translates to:
  /// **'(rattachement inactif)'**
  String get teacherVerifInactiveLink;

  /// No description provided for @teacherVerifInstitutionText.
  ///
  /// In fr, this message translates to:
  /// **'Si tu es rattaché à un établissement sur WinPlus, il peut te cautionner après t\'avoir vérifié par ses propres moyens. Si le rattachement ou la caution est retiré, cette voie tombe.'**
  String get teacherVerifInstitutionText;

  /// No description provided for @teacherVerifInstitutionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Caution de ton institution'**
  String get teacherVerifInstitutionTitle;

  /// No description provided for @teacherVerifInterviewText.
  ///
  /// In fr, this message translates to:
  /// **'En visio ou en rencontre. L\'entretien ne remplace pas l\'identité : prépare ta pièce, elle est jointe au dossier avec un selfie.'**
  String get teacherVerifInterviewText;

  /// No description provided for @teacherVerifInterviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entretien avec un agent'**
  String get teacherVerifInterviewTitle;

  /// No description provided for @teacherVerifIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les séances chez l\'élève, chez toi ou en lieu neutre sont réservées aux tuteurs vérifiés. Choisis une des trois voies : une seule suffit. Le diplôme reste un badge facultatif.'**
  String get teacherVerifIntro;

  /// No description provided for @teacherVerifLastInterview.
  ///
  /// In fr, this message translates to:
  /// **'Dernier entretien : {reason}'**
  String teacherVerifLastInterview(Object reason);

  /// No description provided for @teacherVerifLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien : {url}'**
  String teacherVerifLink(Object url);

  /// No description provided for @teacherVerifMeeting.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre'**
  String get teacherVerifMeeting;

  /// No description provided for @teacherVerifMeetingCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville de la rencontre'**
  String get teacherVerifMeetingCity;

  /// No description provided for @teacherVerifMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message (facultatif)'**
  String get teacherVerifMessage;

  /// No description provided for @teacherVerifNeedFiles.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins le recto de ta pièce et un selfie.'**
  String get teacherVerifNeedFiles;

  /// No description provided for @teacherVerifNoEndorsement.
  ///
  /// In fr, this message translates to:
  /// **'Aucune caution pour le moment. Demande à ton établissement de rattachement (Réseau) de te cautionner.'**
  String get teacherVerifNoEndorsement;

  /// No description provided for @teacherVerifPassed.
  ///
  /// In fr, this message translates to:
  /// **'Entretien réussi.'**
  String get teacherVerifPassed;

  /// No description provided for @teacherVerifPassedNeedIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Il reste à valider ta pièce d\'identité et ton selfie pour ouvrir le présentiel.'**
  String get teacherVerifPassedNeedIdentity;

  /// No description provided for @teacherVerifPendingSince.
  ///
  /// In fr, this message translates to:
  /// **'En cours de vérification depuis le {date}.'**
  String teacherVerifPendingSince(Object date);

  /// No description provided for @teacherVerifPhotoTooBig.
  ///
  /// In fr, this message translates to:
  /// **'Photo trop volumineuse (8 Mo maximum).'**
  String get teacherVerifPhotoTooBig;

  /// No description provided for @teacherVerifPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu : {place}'**
  String teacherVerifPlace(Object place);

  /// No description provided for @teacherVerifReasonSuffix.
  ///
  /// In fr, this message translates to:
  /// **' : {reason}'**
  String teacherVerifReasonSuffix(Object reason);

  /// No description provided for @teacherVerifRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée : {reason}. Tu peux envoyer de nouveaux documents.'**
  String teacherVerifRejected(Object reason);

  /// No description provided for @teacherVerifRequestInterview.
  ///
  /// In fr, this message translates to:
  /// **'Demander un entretien'**
  String get teacherVerifRequestInterview;

  /// No description provided for @teacherVerifRequested.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée. Un agent WinPlus va te proposer une date.'**
  String get teacherVerifRequested;

  /// No description provided for @teacherVerifRequestedOn.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée le {date}. Un agent va te proposer une date.'**
  String teacherVerifRequestedOn(Object date);

  /// No description provided for @teacherVerifRetake.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get teacherVerifRetake;

  /// No description provided for @teacherVerifRetention.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers privés, vus seulement par l\'équipe WinPlus, jamais affichés sur ton profil. Supprimés {approved} jours après la validation ({rejected} jours après un refus) ; seule la décision est conservée.'**
  String teacherVerifRetention(Object approved, Object rejected);

  /// No description provided for @teacherVerifRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Caution de {name} retirée le {date}'**
  String teacherVerifRevoked(Object name, Object date);

  /// No description provided for @teacherVerifRoutesValidated.
  ///
  /// In fr, this message translates to:
  /// **'Voie(s) validée(s) : {routes}'**
  String teacherVerifRoutesValidated(Object routes);

  /// No description provided for @teacherVerifScheduledOn.
  ///
  /// In fr, this message translates to:
  /// **'Prévu le {date}'**
  String teacherVerifScheduledOn(Object date);

  /// No description provided for @teacherVerifSelfie.
  ///
  /// In fr, this message translates to:
  /// **'Selfie (ton visage)'**
  String get teacherVerifSelfie;

  /// No description provided for @teacherVerifSent.
  ///
  /// In fr, this message translates to:
  /// **'Documents envoyés. L\'équipe WinPlus va les comparer.'**
  String get teacherVerifSent;

  /// No description provided for @teacherVerifSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer pour vérification'**
  String get teacherVerifSubmit;

  /// No description provided for @teacherVerifSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel suspendu'**
  String get teacherVerifSuspended;

  /// No description provided for @teacherVerifSuspendedBanner.
  ///
  /// In fr, this message translates to:
  /// **'Suite à des signalements, tes séances présentielles sont suspendues le temps qu\'un membre de l\'équipe WinPlus examine la situation. Tes séances en ligne restent possibles.'**
  String get teacherVerifSuspendedBanner;

  /// No description provided for @teacherVerifTake.
  ///
  /// In fr, this message translates to:
  /// **'Prendre'**
  String get teacherVerifTake;

  /// No description provided for @teacherVerifTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification présentiel'**
  String get teacherVerifTitle;

  /// No description provided for @teacherVerifValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get teacherVerifValidated;

  /// No description provided for @teacherVerifVerifiedBy.
  ///
  /// In fr, this message translates to:
  /// **'vérifié par {name}'**
  String teacherVerifVerifiedBy(Object name);

  /// No description provided for @teacherVerifVideo.
  ///
  /// In fr, this message translates to:
  /// **'Visio'**
  String get teacherVerifVideo;

  /// No description provided for @timerBackToWork.
  ///
  /// In fr, this message translates to:
  /// **'Retour au travail !'**
  String get timerBackToWork;

  /// No description provided for @timerBreakDone.
  ///
  /// In fr, this message translates to:
  /// **'Pause terminée !'**
  String get timerBreakDone;

  /// No description provided for @timerDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Bravo ! Tu as complété {count, plural, =0{{count} pomodoro} =1{{count} pomodoro} other{{count} pomodoros}} aujourd\'hui.'**
  String timerDoneBody(int count);

  /// No description provided for @timerModeLongBreak.
  ///
  /// In fr, this message translates to:
  /// **'Pause longue'**
  String get timerModeLongBreak;

  /// No description provided for @timerModePomodoro.
  ///
  /// In fr, this message translates to:
  /// **'Pomodoro'**
  String get timerModePomodoro;

  /// No description provided for @timerModeShortBreak.
  ///
  /// In fr, this message translates to:
  /// **'Pause courte'**
  String get timerModeShortBreak;

  /// No description provided for @timerNewPomodoro.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau pomodoro'**
  String get timerNewPomodoro;

  /// No description provided for @timerPomodoroDone.
  ///
  /// In fr, this message translates to:
  /// **'Pomodoro terminé !'**
  String get timerPomodoroDone;

  /// No description provided for @timerReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get timerReset;

  /// No description provided for @timerTip.
  ///
  /// In fr, this message translates to:
  /// **'25 min de focus + 5 min de pause = 1 pomodoro. Après 4 pomodoros, prends une pause longue de 15 min.'**
  String get timerTip;

  /// No description provided for @timerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Timer Pomodoro'**
  String get timerTitle;

  /// No description provided for @timerTodayCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} pomodoros aujourd\'hui} =1{{count} pomodoro aujourd\'hui} other{{count} pomodoros aujourd\'hui}}'**
  String timerTodayCount(int count);

  /// No description provided for @tutoringActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible.'**
  String get tutoringActionFailed;

  /// No description provided for @tutoringAddTopic.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ce sujet'**
  String get tutoringAddTopic;

  /// No description provided for @tutoringAllClasses.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les classes'**
  String get tutoringAllClasses;

  /// No description provided for @tutoringAllLevels.
  ///
  /// In fr, this message translates to:
  /// **'Tous niveaux'**
  String get tutoringAllLevels;

  /// No description provided for @tutoringAllSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Toutes matières'**
  String get tutoringAllSubjects;

  /// No description provided for @tutoringAnotherTopic.
  ///
  /// In fr, this message translates to:
  /// **'Autre sujet…'**
  String get tutoringAnotherTopic;

  /// No description provided for @tutoringAssignAllClass.
  ///
  /// In fr, this message translates to:
  /// **'Toute la classe {name}'**
  String tutoringAssignAllClass(Object name);

  /// No description provided for @tutoringAssignChildrenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enfants bénéficiaires'**
  String get tutoringAssignChildrenLabel;

  /// No description provided for @tutoringAssignChooseChild.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un enfant.'**
  String get tutoringAssignChooseChild;

  /// No description provided for @tutoringAssignChooseStudents.
  ///
  /// In fr, this message translates to:
  /// **'Choisis des élèves ou une classe.'**
  String get tutoringAssignChooseStudents;

  /// No description provided for @tutoringAssignChooseTutor.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un répétiteur.'**
  String get tutoringAssignChooseTutor;

  /// No description provided for @tutoringAssignError.
  ///
  /// In fr, this message translates to:
  /// **'Attribution impossible.'**
  String get tutoringAssignError;

  /// No description provided for @tutoringAssignIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le répétiteur reçoit la demande et l\'accepte ou la refuse. L\'attribution ne réserve rien : elle le met en avant et présélectionne les élèves pour réserver en un clic.'**
  String get tutoringAssignIntro;

  /// No description provided for @tutoringAssignNoChild.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant lié (le lien doit être accepté par l\'enfant).'**
  String get tutoringAssignNoChild;

  /// No description provided for @tutoringAssignNoStudent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève actif au rattachement confirmé dans ton institution.'**
  String get tutoringAssignNoStudent;

  /// No description provided for @tutoringAssignNoTutor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun répétiteur trouvé.'**
  String get tutoringAssignNoTutor;

  /// No description provided for @tutoringAssignNoWholeClass.
  ///
  /// In fr, this message translates to:
  /// **'Pas de classe entière'**
  String get tutoringAssignNoWholeClass;

  /// No description provided for @tutoringAssignNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Un mot pour le répétiteur (objectifs, fréquence…)'**
  String get tutoringAssignNoteHint;

  /// No description provided for @tutoringAssignPending.
  ///
  /// In fr, this message translates to:
  /// **'{count} élève(s) rattaché(s) n\'ont pas encore confirmé leur rattachement : ils n\'apparaissent pas ici tant qu\'ils ne l\'ont pas accepté depuis leur compte.'**
  String tutoringAssignPending(Object count);

  /// No description provided for @tutoringAssignResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse : « {note} »'**
  String tutoringAssignResponse(Object note);

  /// No description provided for @tutoringAssignStudentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Élèves bénéficiaires'**
  String get tutoringAssignStudentsLabel;

  /// No description provided for @tutoringAssignSubjectHint.
  ///
  /// In fr, this message translates to:
  /// **'Matière (ex. Mathématiques)'**
  String get tutoringAssignSubjectHint;

  /// No description provided for @tutoringAssignSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'attribution'**
  String get tutoringAssignSubmit;

  /// No description provided for @tutoringAssignTutor.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer un tuteur'**
  String get tutoringAssignTutor;

  /// No description provided for @tutoringAssignedBy.
  ///
  /// In fr, this message translates to:
  /// **'attribué par {name}'**
  String tutoringAssignedBy(Object name);

  /// No description provided for @tutoringAssignedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Attribués :'**
  String get tutoringAssignedLabel;

  /// No description provided for @tutoringAssignedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes répétiteurs attribués'**
  String get tutoringAssignedTitle;

  /// No description provided for @tutoringAssignedTutor.
  ///
  /// In fr, this message translates to:
  /// **'Répétiteur attribué'**
  String get tutoringAssignedTutor;

  /// No description provided for @tutoringAssignedTutors.
  ///
  /// In fr, this message translates to:
  /// **'Répétiteurs attribués'**
  String get tutoringAssignedTutors;

  /// No description provided for @tutoringAvailability14.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilités (14 prochains jours)'**
  String get tutoringAvailability14;

  /// No description provided for @tutoringAvailableSlots.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux disponibles'**
  String get tutoringAvailableSlots;

  /// No description provided for @tutoringAvailableSoon.
  ///
  /// In fr, this message translates to:
  /// **'Disponible sous 48h'**
  String get tutoringAvailableSoon;

  /// No description provided for @tutoringBalanceNotCover.
  ///
  /// In fr, this message translates to:
  /// **'Le solde ne couvre pas le prix de cette séance. {hint}'**
  String tutoringBalanceNotCover(Object hint);

  /// No description provided for @tutoringBaseRate.
  ///
  /// In fr, this message translates to:
  /// **'Tarif de base : {rate} XAF / h'**
  String tutoringBaseRate(Object rate);

  /// No description provided for @tutoringBook.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get tutoringBook;

  /// No description provided for @tutoringBookMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Réserver au mois'**
  String get tutoringBookMonthly;

  /// No description provided for @tutoringBookSession.
  ///
  /// In fr, this message translates to:
  /// **'Réserver une séance'**
  String get tutoringBookSession;

  /// No description provided for @tutoringBookedSessions.
  ///
  /// In fr, this message translates to:
  /// **'Séances réservées'**
  String get tutoringBookedSessions;

  /// No description provided for @tutoringBookingCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée'**
  String get tutoringBookingCancelled;

  /// No description provided for @tutoringBookingCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création de la réservation.'**
  String get tutoringBookingCreateError;

  /// No description provided for @tutoringBookingsDisputeError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le signalement.'**
  String get tutoringBookingsDisputeError;

  /// No description provided for @tutoringBookingsDisputeSent.
  ///
  /// In fr, this message translates to:
  /// **'Votre signalement a été envoyé.'**
  String get tutoringBookingsDisputeSent;

  /// No description provided for @tutoringBookingsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation pour le moment.'**
  String get tutoringBookingsEmpty;

  /// No description provided for @tutoringBookingsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos réservations.'**
  String get tutoringBookingsLoadError;

  /// No description provided for @tutoringBookingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get tutoringBookingsTitle;

  /// No description provided for @tutoringCalendarError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les disponibilités.'**
  String get tutoringCalendarError;

  /// No description provided for @tutoringCancellationPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique d\'annulation'**
  String get tutoringCancellationPolicy;

  /// No description provided for @tutoringCheckNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get tutoringCheckNow;

  /// No description provided for @tutoringChooseDay.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un jour'**
  String get tutoringChooseDay;

  /// No description provided for @tutoringClassName.
  ///
  /// In fr, this message translates to:
  /// **'Classe {name}'**
  String tutoringClassName(Object name);

  /// No description provided for @tutoringDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get tutoringDate;

  /// No description provided for @tutoringDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur WinPlus'**
  String get tutoringDefaultName;

  /// No description provided for @tutoringDiplomaVerified.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme vérifié'**
  String get tutoringDiplomaVerified;

  /// No description provided for @tutoringDispute.
  ///
  /// In fr, this message translates to:
  /// **'Contester'**
  String get tutoringDispute;

  /// No description provided for @tutoringDisputeSentReason.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé : {reason}'**
  String tutoringDisputeSentReason(Object reason);

  /// No description provided for @tutoringDisputeSession.
  ///
  /// In fr, this message translates to:
  /// **'Contester la séance'**
  String get tutoringDisputeSession;

  /// No description provided for @tutoringDisputeUntil.
  ///
  /// In fr, this message translates to:
  /// **'Un problème ? Tu peux contester jusqu\'au {date} à {time} ({hours} h après la séance). Ensuite, le paiement est versé au tuteur.'**
  String tutoringDisputeUntil(Object date, Object time, Object hours);

  /// No description provided for @tutoringDurationHint.
  ///
  /// In fr, this message translates to:
  /// **'Par tranches de 30 min, jusqu\'à la fin de la plage libre.'**
  String get tutoringDurationHint;

  /// No description provided for @tutoringEndAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Mettre fin'**
  String get tutoringEndAssignment;

  /// No description provided for @tutoringEndorsedBy.
  ///
  /// In fr, this message translates to:
  /// **'Caution : {name}'**
  String tutoringEndorsedBy(Object name);

  /// No description provided for @tutoringEndsAt.
  ///
  /// In fr, this message translates to:
  /// **'· fin à {time}'**
  String tutoringEndsAt(Object time);

  /// No description provided for @tutoringEngAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter l\'engagement'**
  String get tutoringEngAccept;

  /// No description provided for @tutoringEngAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Engagement accepté : les séances sont confirmées.'**
  String get tutoringEngAccepted;

  /// No description provided for @tutoringEngAddSlot.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un créneau'**
  String get tutoringEngAddSlot;

  /// No description provided for @tutoringEngAutoFailed.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique impossible : {reason}'**
  String tutoringEngAutoFailed(Object reason);

  /// No description provided for @tutoringEngAutoOff.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique désactivé.'**
  String get tutoringEngAutoOff;

  /// No description provided for @tutoringEngAutoOn.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique activé.'**
  String get tutoringEngAutoOn;

  /// No description provided for @tutoringEngAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler automatiquement chaque mois sur le solde'**
  String get tutoringEngAutoRenew;

  /// No description provided for @tutoringEngAutoRenewAt.
  ///
  /// In fr, this message translates to:
  /// **'Tentative le {date}, si les créneaux sont encore libres et le solde suffisant.'**
  String tutoringEngAutoRenewAt(Object date);

  /// No description provided for @tutoringEngAutoRenewHelp.
  ///
  /// In fr, this message translates to:
  /// **'Mêmes créneaux. Tentative 3 jours avant la fin, après un rappel 7 jours avant ; si le solde ne suffit pas ou si un créneau n\'est plus libre, rien n\'est débité et tu es prévenu.'**
  String get tutoringEngAutoRenewHelp;

  /// No description provided for @tutoringEngAutoRenewIf.
  ///
  /// In fr, this message translates to:
  /// **'Si les créneaux sont encore libres et le solde suffisant.'**
  String get tutoringEngAutoRenewIf;

  /// No description provided for @tutoringEngAutoRenewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique sur le solde'**
  String get tutoringEngAutoRenewTitle;

  /// No description provided for @tutoringEngAutoRenewWalletOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le renouvellement automatique n\'est possible qu\'avec un paiement par solde.'**
  String get tutoringEngAutoRenewWalletOnly;

  /// No description provided for @tutoringEngAutoWalletOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le renouvellement automatique n\'est possible que pour un engagement payé par solde.'**
  String get tutoringEngAutoWalletOnly;

  /// No description provided for @tutoringEngCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'engagement'**
  String get tutoringEngCancel;

  /// No description provided for @tutoringEngCancelPayerConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ? Les séances passées restent dues ; chaque séance à venir est remboursée selon la politique du tuteur.'**
  String get tutoringEngCancelPayerConfirm;

  /// No description provided for @tutoringEngCancelSession.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette séance'**
  String get tutoringEngCancelSession;

  /// No description provided for @tutoringEngCancelSessionConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler seulement la séance du {date} ?'**
  String tutoringEngCancelSessionConfirm(Object date);

  /// No description provided for @tutoringEngCancelTutorConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ? Les séances à venir sont remboursées intégralement au payeur.'**
  String get tutoringEngCancelTutorConfirm;

  /// No description provided for @tutoringEngCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Engagement annulé, remboursements crédités.'**
  String get tutoringEngCancelled;

  /// No description provided for @tutoringEngCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Création de l\'engagement impossible.'**
  String get tutoringEngCreateError;

  /// No description provided for @tutoringEngDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get tutoringEngDay;

  /// No description provided for @tutoringEngDeclineConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Refuser l\'engagement ? Le payeur est remboursé intégralement.'**
  String get tutoringEngDeclineConfirm;

  /// No description provided for @tutoringEngDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Engagement refusé : le payeur est remboursé.'**
  String get tutoringEngDeclined;

  /// No description provided for @tutoringEngDiscountNote.
  ///
  /// In fr, this message translates to:
  /// **'Remise mensuelle {percent} % ({amount} XAF). '**
  String tutoringEngDiscountNote(Object percent, Object amount);

  /// No description provided for @tutoringEngDisputePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi contestes-tu cette séance ?'**
  String get tutoringEngDisputePrompt;

  /// No description provided for @tutoringEngDisputeUntil.
  ///
  /// In fr, this message translates to:
  /// **'contestation possible jusqu\'au {date}'**
  String tutoringEngDisputeUntil(Object date);

  /// No description provided for @tutoringEngDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Séance contestée : le support va examiner. Les autres séances ne sont pas bloquées.'**
  String get tutoringEngDisputed;

  /// No description provided for @tutoringEngEditSlots.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les créneaux'**
  String get tutoringEngEditSlots;

  /// No description provided for @tutoringEngExplainProblem.
  ///
  /// In fr, this message translates to:
  /// **'Explique le problème'**
  String get tutoringEngExplainProblem;

  /// No description provided for @tutoringEngFeesNote.
  ///
  /// In fr, this message translates to:
  /// **' Frais Mobile Money retenus sur les remboursements : {amount} XAF.'**
  String tutoringEngFeesNote(Object amount);

  /// No description provided for @tutoringEngFirstDay.
  ///
  /// In fr, this message translates to:
  /// **'Premier jour'**
  String get tutoringEngFirstDay;

  /// No description provided for @tutoringEngHeld.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué'**
  String get tutoringEngHeld;

  /// No description provided for @tutoringEngIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance'**
  String get tutoringEngIntro;

  /// No description provided for @tutoringEngIntroDiscount.
  ///
  /// In fr, this message translates to:
  /// **', avec {percent} % de remise mensuelle'**
  String tutoringEngIntroDiscount(Object percent);

  /// No description provided for @tutoringEngIntroEnd.
  ///
  /// In fr, this message translates to:
  /// **'. Le tuteur est payé séance par séance, après chaque séance effectuée.'**
  String get tutoringEngIntroEnd;

  /// No description provided for @tutoringEngMarkedCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Séance marquée effectuée.'**
  String get tutoringEngMarkedCompleted;

  /// No description provided for @tutoringEngMmSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande de paiement envoyée sur ton téléphone.'**
  String get tutoringEngMmSent;

  /// No description provided for @tutoringEngMomoChip.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money (MTN MoMo ou Orange Money)'**
  String get tutoringEngMomoChip;

  /// No description provided for @tutoringEngMoneyFlow.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent est versé au tuteur séance par séance, après chaque séance effectuée et non contestée.'**
  String get tutoringEngMoneyFlow;

  /// No description provided for @tutoringEngMonthlyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Remise mensuelle ({percent} %)'**
  String tutoringEngMonthlyDiscount(Object percent);

  /// No description provided for @tutoringEngNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Engagement introuvable.'**
  String get tutoringEngNotFound;

  /// No description provided for @tutoringEngNotOffered.
  ///
  /// In fr, this message translates to:
  /// **'Ce tuteur ne propose pas l\'engagement mensuel.'**
  String get tutoringEngNotOffered;

  /// No description provided for @tutoringEngPaidAdvance.
  ///
  /// In fr, this message translates to:
  /// **'Payé d\'avance'**
  String get tutoringEngPaidAdvance;

  /// No description provided for @tutoringEngPaidByLine.
  ///
  /// In fr, this message translates to:
  /// **'{subject} · payé par {payer} · {method}'**
  String tutoringEngPaidByLine(Object subject, Object payer, Object method);

  /// No description provided for @tutoringEngPayMonth.
  ///
  /// In fr, this message translates to:
  /// **'Payer le mois'**
  String get tutoringEngPayMonth;

  /// No description provided for @tutoringEngPaymentNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement non confirmé'**
  String get tutoringEngPaymentNotConfirmed;

  /// No description provided for @tutoringEngPaymentPending.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente de confirmation'**
  String get tutoringEngPaymentPending;

  /// No description provided for @tutoringEngPaymentReceived.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu, en attente du tuteur'**
  String get tutoringEngPaymentReceived;

  /// No description provided for @tutoringEngPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'{count} séances sur le mois, vérifiées dans l\'agenda du tuteur.'**
  String tutoringEngPerMonth(Object count);

  /// No description provided for @tutoringEngPhoneFormat.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Mobile Money : 9 chiffres (ex. 670000000).'**
  String get tutoringEngPhoneFormat;

  /// No description provided for @tutoringEngQuoteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de calculer le devis.'**
  String get tutoringEngQuoteError;

  /// No description provided for @tutoringEngQuoteHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le tuteur accepte ou refuse l\'engagement entier ; s\'il refuse ou ne répond pas, tout est remboursé. L\'argent reste bloqué et n\'est versé au tuteur que séance par séance. En cas d\'annulation, la politique ci-dessus s\'applique à chaque séance à venir.'**
  String get tutoringEngQuoteHelp;

  /// No description provided for @tutoringEngQuoteRange.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to} · {count} séances'**
  String tutoringEngQuoteRange(Object from, Object to, Object count);

  /// No description provided for @tutoringEngQuoteStudents.
  ///
  /// In fr, this message translates to:
  /// **' · {count} élèves'**
  String tutoringEngQuoteStudents(Object count);

  /// No description provided for @tutoringEngQuoteUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Devis indisponible.'**
  String get tutoringEngQuoteUnavailable;

  /// No description provided for @tutoringEngRangeSummary.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to} · {slots}'**
  String tutoringEngRangeSummary(Object from, Object to, Object slots);

  /// No description provided for @tutoringEngReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String tutoringEngReason(Object reason);

  /// No description provided for @tutoringEngRefundedAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF remboursés'**
  String tutoringEngRefundedAmount(Object amount);

  /// No description provided for @tutoringEngRefundedTile.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get tutoringEngRefundedTile;

  /// No description provided for @tutoringEngReleased.
  ///
  /// In fr, this message translates to:
  /// **'Versé au tuteur'**
  String get tutoringEngReleased;

  /// No description provided for @tutoringEngRemoveSlot.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce créneau'**
  String get tutoringEngRemoveSlot;

  /// No description provided for @tutoringEngRenewMm.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler par Mobile Money'**
  String get tutoringEngRenewMm;

  /// No description provided for @tutoringEngRenewWallet.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler (payer avec le solde)'**
  String get tutoringEngRenewWallet;

  /// No description provided for @tutoringEngRenewal.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement'**
  String get tutoringEngRenewal;

  /// No description provided for @tutoringEngRenewedWallet.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant réservé et payé par solde.'**
  String get tutoringEngRenewedWallet;

  /// No description provided for @tutoringEngReplyBefore.
  ///
  /// In fr, this message translates to:
  /// **'Réponds avant le {date}'**
  String tutoringEngReplyBefore(Object date);

  /// No description provided for @tutoringEngSameSlots.
  ///
  /// In fr, this message translates to:
  /// **'Mêmes créneaux à partir du {date}. Manuel par défaut ; rappel 7 jours avant la fin.'**
  String tutoringEngSameSlots(Object date);

  /// No description provided for @tutoringEngSeeEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'engagement'**
  String get tutoringEngSeeEngagement;

  /// No description provided for @tutoringEngSeeNextMonth.
  ///
  /// In fr, this message translates to:
  /// **'Voir le mois suivant'**
  String get tutoringEngSeeNextMonth;

  /// No description provided for @tutoringEngSeeQuote.
  ///
  /// In fr, this message translates to:
  /// **'Voir le devis du mois'**
  String get tutoringEngSeeQuote;

  /// No description provided for @tutoringEngSessionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Séance annulée.'**
  String get tutoringEngSessionCancelled;

  /// No description provided for @tutoringEngSessions.
  ///
  /// In fr, this message translates to:
  /// **'Séances ({done} effectuée(s) sur {total})'**
  String tutoringEngSessions(Object done, Object total);

  /// No description provided for @tutoringEngSomeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Certaines séances ne sont pas disponibles : change le jour, l\'heure ou la date de début.'**
  String get tutoringEngSomeUnavailable;

  /// No description provided for @tutoringEngStagePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement d\'avance'**
  String get tutoringEngStagePayment;

  /// No description provided for @tutoringEngStagePlan.
  ///
  /// In fr, this message translates to:
  /// **'Engagement mensuel'**
  String get tutoringEngStagePlan;

  /// No description provided for @tutoringEngStageQuote.
  ///
  /// In fr, this message translates to:
  /// **'Devis du mois'**
  String get tutoringEngStageQuote;

  /// No description provided for @tutoringEngStageSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Engagement payé'**
  String get tutoringEngStageSuccess;

  /// No description provided for @tutoringEngStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get tutoringEngStart;

  /// No description provided for @tutoringEngSubtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total (grille du tuteur)'**
  String get tutoringEngSubtotal;

  /// No description provided for @tutoringEngSuccessText.
  ///
  /// In fr, this message translates to:
  /// **'{count} séances du {from} au {to}. Le tuteur doit accepter l\'engagement entier ; s\'il refuse ou ne répond pas à temps, tout est remboursé sur le portefeuille WinPlus du payeur.'**
  String tutoringEngSuccessText(Object count, Object from, Object to);

  /// No description provided for @tutoringEngTileTotal.
  ///
  /// In fr, this message translates to:
  /// **'{amount} XAF · {done}/{total} séances effectuées'**
  String tutoringEngTileTotal(Object amount, Object done, Object total);

  /// No description provided for @tutoringEngTotalAdvance.
  ///
  /// In fr, this message translates to:
  /// **'Total payé d\'avance'**
  String get tutoringEngTotalAdvance;

  /// No description provided for @tutoringEngValidateOnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Valide le paiement sur ton téléphone'**
  String get tutoringEngValidateOnPhone;

  /// No description provided for @tutoringEngWalletMissing.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant : il manque {amount} XAF.'**
  String tutoringEngWalletMissing(Object amount);

  /// No description provided for @tutoringEngWalletShort.
  ///
  /// In fr, this message translates to:
  /// **'Le solde ne couvre pas le total du mois. Choisis Mobile Money ou recharge le portefeuille.'**
  String get tutoringEngWalletShort;

  /// No description provided for @tutoringEngWeeklySlots.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux de chaque semaine'**
  String get tutoringEngWeeklySlots;

  /// No description provided for @tutoringEngWith.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name}'**
  String tutoringEngWith(Object name);

  /// No description provided for @tutoringEngagementsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Engagements mensuels'**
  String get tutoringEngagementsTitle;

  /// No description provided for @tutoringEveryDay.
  ///
  /// In fr, this message translates to:
  /// **'tous les jours'**
  String get tutoringEveryDay;

  /// No description provided for @tutoringFilterInPerson.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel (vérifiés)'**
  String get tutoringFilterInPerson;

  /// No description provided for @tutoringFilterNeutralPlace.
  ///
  /// In fr, this message translates to:
  /// **'Espace neutre'**
  String get tutoringFilterNeutralPlace;

  /// No description provided for @tutoringFilterStudentHome.
  ///
  /// In fr, this message translates to:
  /// **'À mon domicile'**
  String get tutoringFilterStudentHome;

  /// No description provided for @tutoringForMe.
  ///
  /// In fr, this message translates to:
  /// **'Pour moi'**
  String get tutoringForMe;

  /// No description provided for @tutoringForStudentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tutorat de mes élèves'**
  String get tutoringForStudentsTitle;

  /// No description provided for @tutoringForWhomGroupHelp.
  ///
  /// In fr, this message translates to:
  /// **'C\'est toi qui paies la séance du groupe (ton solde ou Mobile Money) et qui reçois un éventuel remboursement.'**
  String get tutoringForWhomGroupHelp;

  /// No description provided for @tutoringForWhomInstitutionHelp.
  ///
  /// In fr, this message translates to:
  /// **'{count} élève(s) choisi(s). Payé par le portefeuille de l\'institution ou Mobile Money.'**
  String tutoringForWhomInstitutionHelp(Object count);

  /// No description provided for @tutoringForWhomMaxGroup.
  ///
  /// In fr, this message translates to:
  /// **'Ce tuteur accepte au plus {count} élèves par séance.'**
  String tutoringForWhomMaxGroup(Object count);

  /// No description provided for @tutoringForWhomNoChild.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant lié à ton compte (le lien doit être accepté par l\'enfant).'**
  String get tutoringForWhomNoChild;

  /// No description provided for @tutoringForWhomNoGroup.
  ///
  /// In fr, this message translates to:
  /// **'Ce tuteur ne propose pas de séances de groupe : choisis un seul élève.'**
  String get tutoringForWhomNoGroup;

  /// No description provided for @tutoringForWhomNoStudent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élève actif rattaché à {name}.'**
  String tutoringForWhomNoStudent(Object name);

  /// No description provided for @tutoringForWhomParentHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tu paies avec ton portefeuille parent ou Mobile Money ; tes enfants voient la séance dans leur espace.'**
  String get tutoringForWhomParentHelp;

  /// No description provided for @tutoringForWhomPendingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'{count} élève(s) rattaché(s) n\'apparaissent pas : ils doivent d\'abord confirmer leur rattachement à l\'institution depuis leur compte (Mon réseau).'**
  String tutoringForWhomPendingConfirmation(Object count);

  /// No description provided for @tutoringForWhomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour qui ?'**
  String get tutoringForWhomTitle;

  /// No description provided for @tutoringFrom.
  ///
  /// In fr, this message translates to:
  /// **'à partir de'**
  String get tutoringFrom;

  /// No description provided for @tutoringFromDuration.
  ///
  /// In fr, this message translates to:
  /// **'À partir de {duration} : −{percent} %'**
  String tutoringFromDuration(Object duration, Object percent);

  /// No description provided for @tutoringGroupDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Prix de groupe : −{percent} % par élève'**
  String tutoringGroupDiscount(Object percent);

  /// No description provided for @tutoringGroupEachPays.
  ///
  /// In fr, this message translates to:
  /// **'Chaque élève paie le prix d\'une séance individuelle.'**
  String get tutoringGroupEachPays;

  /// No description provided for @tutoringGroupFlat.
  ///
  /// In fr, this message translates to:
  /// **'Prix fixe du groupe ({count} élèves)'**
  String tutoringGroupFlat(Object count);

  /// No description provided for @tutoringGroupFlatHint.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % du prix individuel · ≈ {amount} XAF par élève'**
  String tutoringGroupFlatHint(Object percent, Object amount);

  /// No description provided for @tutoringGroupFlatSummary.
  ///
  /// In fr, this message translates to:
  /// **'Prix fixe pour le groupe : {percent} % du prix d\'une séance individuelle.'**
  String tutoringGroupFlatSummary(Object percent);

  /// No description provided for @tutoringGroupFromSize.
  ///
  /// In fr, this message translates to:
  /// **'À partir de {count} élèves : −{percent} % par élève'**
  String tutoringGroupFromSize(Object count, Object percent);

  /// No description provided for @tutoringGroupName.
  ///
  /// In fr, this message translates to:
  /// **'Groupe : {name}'**
  String tutoringGroupName(Object name);

  /// No description provided for @tutoringGroupUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Séances de groupe jusqu\'à {count} élèves.'**
  String tutoringGroupUpTo(Object count);

  /// No description provided for @tutoringInPersonPossible.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel possible'**
  String get tutoringInPersonPossible;

  /// No description provided for @tutoringInPersonVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié pour le présentiel'**
  String get tutoringInPersonVerified;

  /// No description provided for @tutoringInstitutionWalletHelp.
  ///
  /// In fr, this message translates to:
  /// **'Partagé par tous les comptes de l\'institution : il se recharge par Mobile Money, paie les séances et reçoit les remboursements. Il ne se retire pas vers Mobile Money.'**
  String get tutoringInstitutionWalletHelp;

  /// No description provided for @tutoringIntroVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo de présentation'**
  String get tutoringIntroVideo;

  /// No description provided for @tutoringLeaveReview.
  ///
  /// In fr, this message translates to:
  /// **'Laisser un avis'**
  String get tutoringLeaveReview;

  /// No description provided for @tutoringLevels.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux'**
  String get tutoringLevels;

  /// No description provided for @tutoringLongSession.
  ///
  /// In fr, this message translates to:
  /// **'Séance longue (−{percent} %)'**
  String tutoringLongSession(Object percent);

  /// No description provided for @tutoringMatAddExercise.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un exercice'**
  String get tutoringMatAddExercise;

  /// No description provided for @tutoringMatAddPart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une partie'**
  String get tutoringMatAddPart;

  /// No description provided for @tutoringMatAddQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une question'**
  String get tutoringMatAddQuestion;

  /// No description provided for @tutoringMatAnswerLine.
  ///
  /// In fr, this message translates to:
  /// **'{title} : {answer}'**
  String tutoringMatAnswerLine(Object title, Object answer);

  /// No description provided for @tutoringMatAnswersSent.
  ///
  /// In fr, this message translates to:
  /// **'Réponses envoyées à ton tuteur.'**
  String get tutoringMatAnswersSent;

  /// No description provided for @tutoringMatChanged.
  ///
  /// In fr, this message translates to:
  /// **'Modifié depuis le partage'**
  String get tutoringMatChanged;

  /// No description provided for @tutoringMatCourse.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get tutoringMatCourse;

  /// No description provided for @tutoringMatDraftSaved.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon enregistré.'**
  String get tutoringMatDraftSaved;

  /// No description provided for @tutoringMatEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get tutoringMatEasy;

  /// No description provided for @tutoringMatEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le support'**
  String get tutoringMatEditTitle;

  /// No description provided for @tutoringMatExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : {text}'**
  String tutoringMatExample(Object text);

  /// No description provided for @tutoringMatExerciseN.
  ///
  /// In fr, this message translates to:
  /// **'Exercice {n}'**
  String tutoringMatExerciseN(Object n);

  /// No description provided for @tutoringMatExercises.
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get tutoringMatExercises;

  /// No description provided for @tutoringMatExercisesSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Exercices rendus'**
  String get tutoringMatExercisesSubmitted;

  /// No description provided for @tutoringMatFieldAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Réponse {id}'**
  String tutoringMatFieldAnswer(Object id);

  /// No description provided for @tutoringMatFieldContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get tutoringMatFieldContent;

  /// No description provided for @tutoringMatFieldExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple (facultatif)'**
  String get tutoringMatFieldExample;

  /// No description provided for @tutoringMatFieldExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Explication'**
  String get tutoringMatFieldExplanation;

  /// No description provided for @tutoringMatFieldHints.
  ///
  /// In fr, this message translates to:
  /// **'Indices (un par ligne)'**
  String get tutoringMatFieldHints;

  /// No description provided for @tutoringMatFieldKeyPoints.
  ///
  /// In fr, this message translates to:
  /// **'Points clés (un par ligne)'**
  String get tutoringMatFieldKeyPoints;

  /// No description provided for @tutoringMatFieldObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs (un par ligne)'**
  String get tutoringMatFieldObjectives;

  /// No description provided for @tutoringMatFieldPartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la partie'**
  String get tutoringMatFieldPartTitle;

  /// No description provided for @tutoringMatFieldSolution.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé (visible après la réponse de l\'élève)'**
  String get tutoringMatFieldSolution;

  /// No description provided for @tutoringMatFieldStatement.
  ///
  /// In fr, this message translates to:
  /// **'Énoncé'**
  String get tutoringMatFieldStatement;

  /// No description provided for @tutoringMatFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get tutoringMatFieldTitle;

  /// No description provided for @tutoringMatGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Générer avec WinAI'**
  String get tutoringMatGenerate;

  /// No description provided for @tutoringMatGenerateHelp.
  ///
  /// In fr, this message translates to:
  /// **'WinAI prépare un cours, un quiz et des exercices à partir des sujets de la séance. La génération est décomptée de ton usage WinAI ; rien n\'est envoyé aux élèves avant que tu partages.'**
  String get tutoringMatGenerateHelp;

  /// No description provided for @tutoringMatGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Support généré : relis-le avant de le partager.'**
  String get tutoringMatGenerated;

  /// No description provided for @tutoringMatGroupPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Groupe ({count} élèves) : '**
  String tutoringMatGroupPrefix(Object count);

  /// No description provided for @tutoringMatHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get tutoringMatHard;

  /// No description provided for @tutoringMatHints.
  ///
  /// In fr, this message translates to:
  /// **'Indices'**
  String get tutoringMatHints;

  /// No description provided for @tutoringMatInstructionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Consigne pour WinAI (facultatif) : « plus d\'exercices », « niveau plus simple »…'**
  String get tutoringMatInstructionsHint;

  /// No description provided for @tutoringMatMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get tutoringMatMedium;

  /// No description provided for @tutoringMatNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réponse pour l\'instant.'**
  String get tutoringMatNoAnswer;

  /// No description provided for @tutoringMatNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Support introuvable.'**
  String get tutoringMatNotFound;

  /// No description provided for @tutoringMatNotShared.
  ///
  /// In fr, this message translates to:
  /// **'Le tuteur n\'a pas encore partagé de support pour cette séance.'**
  String get tutoringMatNotShared;

  /// No description provided for @tutoringMatNotYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore répondu : {names}'**
  String tutoringMatNotYet(Object names);

  /// No description provided for @tutoringMatObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get tutoringMatObjectives;

  /// No description provided for @tutoringMatOutdated.
  ///
  /// In fr, this message translates to:
  /// **'Réponses à une version précédente'**
  String get tutoringMatOutdated;

  /// No description provided for @tutoringMatPart.
  ///
  /// In fr, this message translates to:
  /// **'Partie {n}'**
  String tutoringMatPart(Object n);

  /// No description provided for @tutoringMatQuizCount.
  ///
  /// In fr, this message translates to:
  /// **'Quiz ({count} questions)'**
  String tutoringMatQuizCount(Object count);

  /// No description provided for @tutoringMatReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule : les élèves répondent au quiz et aux exercices dans leur compte.'**
  String get tutoringMatReadOnly;

  /// No description provided for @tutoringMatRegenerate.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get tutoringMatRegenerate;

  /// No description provided for @tutoringMatRegenerateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer remplace ton brouillon actuel (la version partagée reste visible jusqu\'au prochain partage). Continuer ?'**
  String get tutoringMatRegenerateConfirm;

  /// No description provided for @tutoringMatResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get tutoringMatResults;

  /// No description provided for @tutoringMatSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get tutoringMatSaveDraft;

  /// No description provided for @tutoringMatShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager avec les élèves'**
  String get tutoringMatShare;

  /// No description provided for @tutoringMatShareNew.
  ///
  /// In fr, this message translates to:
  /// **'Partager la nouvelle version'**
  String get tutoringMatShareNew;

  /// No description provided for @tutoringMatShared.
  ///
  /// In fr, this message translates to:
  /// **'Partagé'**
  String get tutoringMatShared;

  /// No description provided for @tutoringMatSharedToast.
  ///
  /// In fr, this message translates to:
  /// **'Support partagé avec les élèves et le payeur.'**
  String get tutoringMatSharedToast;

  /// No description provided for @tutoringMatSolution.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé : {solution}'**
  String tutoringMatSolution(Object solution);

  /// No description provided for @tutoringMatStudentAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Réponses des élèves'**
  String get tutoringMatStudentAnswers;

  /// No description provided for @tutoringMatStudentPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Élève : '**
  String get tutoringMatStudentPrefix;

  /// No description provided for @tutoringMatSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mes réponses'**
  String get tutoringMatSubmit;

  /// No description provided for @tutoringMatSummary.
  ///
  /// In fr, this message translates to:
  /// **'À retenir'**
  String get tutoringMatSummary;

  /// No description provided for @tutoringMatUnanswered.
  ///
  /// In fr, this message translates to:
  /// **'{count} question(s) sans réponse. Envoyer quand même ? Tu ne pourras plus modifier tes réponses.'**
  String tutoringMatUnanswered(Object count);

  /// No description provided for @tutoringMatYourAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse : {answer}'**
  String tutoringMatYourAnswer(Object answer);

  /// No description provided for @tutoringMatYourAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse…'**
  String get tutoringMatYourAnswerHint;

  /// No description provided for @tutoringMaterial.
  ///
  /// In fr, this message translates to:
  /// **'Support de séance'**
  String get tutoringMaterial;

  /// No description provided for @tutoringMaterialFull.
  ///
  /// In fr, this message translates to:
  /// **'Support, quiz et exercices'**
  String get tutoringMaterialFull;

  /// No description provided for @tutoringMe.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get tutoringMe;

  /// No description provided for @tutoringMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get tutoringMode;

  /// No description provided for @tutoringModeAll.
  ///
  /// In fr, this message translates to:
  /// **'tous modes'**
  String get tutoringModeAll;

  /// No description provided for @tutoringModeInPerson.
  ///
  /// In fr, this message translates to:
  /// **'présentiel'**
  String get tutoringModeInPerson;

  /// No description provided for @tutoringModeNeutralPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu neutre'**
  String get tutoringModeNeutralPlace;

  /// No description provided for @tutoringModeOnlineLower.
  ///
  /// In fr, this message translates to:
  /// **'en ligne'**
  String get tutoringModeOnlineLower;

  /// No description provided for @tutoringModeStudentHome.
  ///
  /// In fr, this message translates to:
  /// **'À domicile'**
  String get tutoringModeStudentHome;

  /// No description provided for @tutoringModeStudentHomeMine.
  ///
  /// In fr, this message translates to:
  /// **'À domicile (chez moi)'**
  String get tutoringModeStudentHomeMine;

  /// No description provided for @tutoringModeTutorHome.
  ///
  /// In fr, this message translates to:
  /// **'Chez le tuteur'**
  String get tutoringModeTutorHome;

  /// No description provided for @tutoringModifierLine.
  ///
  /// In fr, this message translates to:
  /// **'{label} ({when}) : {adjust}'**
  String tutoringModifierLine(Object label, Object when, Object adjust);

  /// No description provided for @tutoringMomoHint.
  ///
  /// In fr, this message translates to:
  /// **'MTN MoMo ou Orange Money'**
  String get tutoringMomoHint;

  /// No description provided for @tutoringMomoNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Mobile Money'**
  String get tutoringMomoNumber;

  /// No description provided for @tutoringMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Au mois'**
  String get tutoringMonthly;

  /// No description provided for @tutoringMonthlyText.
  ///
  /// In fr, this message translates to:
  /// **'Mêmes créneaux chaque semaine pendant 4 semaines, payés d\'avance et versés au tuteur séance par séance.'**
  String get tutoringMonthlyText;

  /// No description provided for @tutoringMustAccept.
  ///
  /// In fr, this message translates to:
  /// **'Le tuteur doit accepter ta demande. Tu seras notifié·e dès sa réponse, et remboursé·e intégralement sur ton portefeuille WinPlus s\'il refuse ou ne répond pas à temps.'**
  String get tutoringMustAccept;

  /// No description provided for @tutoringMyRating.
  ///
  /// In fr, this message translates to:
  /// **'Ta note : {rating}/5'**
  String tutoringMyRating(Object rating);

  /// No description provided for @tutoringNoAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Aucune attribution pour l\'instant.'**
  String get tutoringNoAssignment;

  /// No description provided for @tutoringNoModeConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Ce tuteur n\'a pas encore configuré de mode de séance.'**
  String get tutoringNoModeConfigured;

  /// No description provided for @tutoringNoReviewsYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'avis'**
  String get tutoringNoReviewsYet;

  /// No description provided for @tutoringNoSlotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau disponible pour le moment.'**
  String get tutoringNoSlotAvailable;

  /// No description provided for @tutoringNoSlotThatDay.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau ce jour-là.'**
  String get tutoringNoSlotThatDay;

  /// No description provided for @tutoringNotSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get tutoringNotSpecified;

  /// No description provided for @tutoringOnlineOnly.
  ///
  /// In fr, this message translates to:
  /// **'En ligne uniquement'**
  String get tutoringOnlineOnly;

  /// No description provided for @tutoringPay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get tutoringPay;

  /// No description provided for @tutoringPayAmount.
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount} XAF'**
  String tutoringPayAmount(Object amount);

  /// No description provided for @tutoringPayMethod.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get tutoringPayMethod;

  /// No description provided for @tutoringPayNow.
  ///
  /// In fr, this message translates to:
  /// **'Payer maintenant'**
  String get tutoringPayNow;

  /// No description provided for @tutoringPayWithBalance.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec mon solde'**
  String get tutoringPayWithBalance;

  /// No description provided for @tutoringPayWithInstitutionWallet.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec le portefeuille de l\'institution'**
  String get tutoringPayWithInstitutionWallet;

  /// No description provided for @tutoringPayWithParentWallet.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec mon portefeuille parent'**
  String get tutoringPayWithParentWallet;

  /// No description provided for @tutoringPaymentNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas pu être confirmé.'**
  String get tutoringPaymentNotConfirmed;

  /// No description provided for @tutoringPaymentReceivedAwaiting.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu  en attente du tuteur'**
  String get tutoringPaymentReceivedAwaiting;

  /// No description provided for @tutoringPaymentSlow.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement met plus de temps que prévu. Tu peux vérifier plus tard dans \"Mes séances\".'**
  String get tutoringPaymentSlow;

  /// No description provided for @tutoringPerHour.
  ///
  /// In fr, this message translates to:
  /// **'/ heure'**
  String get tutoringPerHour;

  /// No description provided for @tutoringPerStudentLine.
  ///
  /// In fr, this message translates to:
  /// **'{count} élèves × {amount} XAF'**
  String tutoringPerStudentLine(Object count, Object amount);

  /// No description provided for @tutoringPercent.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String tutoringPercent(Object value);

  /// No description provided for @tutoringPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Cameroun sans indicatif pays (ex: 670000000).'**
  String get tutoringPhoneHint;

  /// No description provided for @tutoringPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get tutoringPhoneInvalid;

  /// No description provided for @tutoringPolicyCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique d\'annulation de ce tuteur'**
  String get tutoringPolicyCardTitle;

  /// No description provided for @tutoringPolicyDispute.
  ///
  /// In fr, this message translates to:
  /// **'Après la séance, tu as {hours} h pour la contester.'**
  String tutoringPolicyDispute(Object hours);

  /// No description provided for @tutoringPolicyFactDispute.
  ///
  /// In fr, this message translates to:
  /// **'pour contester une séance'**
  String get tutoringPolicyFactDispute;

  /// No description provided for @tutoringPolicyFactFee.
  ///
  /// In fr, this message translates to:
  /// **'de frais Mobile Money si tu annules toi-même'**
  String get tutoringPolicyFactFee;

  /// No description provided for @tutoringPolicyFactImmediate.
  ///
  /// In fr, this message translates to:
  /// **'Immédiat'**
  String get tutoringPolicyFactImmediate;

  /// No description provided for @tutoringPolicyFactRefund.
  ///
  /// In fr, this message translates to:
  /// **'remboursement au portefeuille'**
  String get tutoringPolicyFactRefund;

  /// No description provided for @tutoringPolicyFull.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement intégral si tu annules au moins {hours} h avant la séance.'**
  String tutoringPolicyFull(Object hours);

  /// No description provided for @tutoringPolicyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les règles communes à toutes les séances de cours particuliers réservées sur WinPlus.'**
  String get tutoringPolicyIntro;

  /// No description provided for @tutoringPolicyLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la politique.'**
  String get tutoringPolicyLoadError;

  /// No description provided for @tutoringPolicyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement à moins de {hours} h.'**
  String tutoringPolicyNone(Object hours);

  /// No description provided for @tutoringPolicyPartial.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % remboursés entre {min} h et {max} h avant.'**
  String tutoringPolicyPartial(Object percent, Object min, Object max);

  /// No description provided for @tutoringPolicyRead.
  ///
  /// In fr, this message translates to:
  /// **'Lire la politique de tutorat'**
  String get tutoringPolicyRead;

  /// No description provided for @tutoringPolicyTutorCancels.
  ///
  /// In fr, this message translates to:
  /// **'Si le tuteur annule, refuse ou ne répond pas : remboursement intégral.'**
  String get tutoringPolicyTutorCancels;

  /// No description provided for @tutoringPolicyUntilStart.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement possible jusqu\'au début de la séance.'**
  String get tutoringPolicyUntilStart;

  /// No description provided for @tutoringPolicyVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version du {date}.'**
  String tutoringPolicyVersion(Object date);

  /// No description provided for @tutoringPolicyWallet.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements versés immédiatement sur ton portefeuille WinPlus.'**
  String get tutoringPolicyWallet;

  /// No description provided for @tutoringPolicyWalletFee.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements versés immédiatement sur ton portefeuille WinPlus. Si tu annules une séance payée par Mobile Money, {fee} % de frais de l\'opérateur sont déduits ; aucun frais pour un paiement par solde.'**
  String tutoringPolicyWalletFee(Object fee);

  /// No description provided for @tutoringPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get tutoringPrice;

  /// No description provided for @tutoringPriceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Prix indisponible.'**
  String get tutoringPriceUnavailable;

  /// No description provided for @tutoringPrivateLessons.
  ///
  /// In fr, this message translates to:
  /// **'Cours particuliers'**
  String get tutoringPrivateLessons;

  /// No description provided for @tutoringProfileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce profil.'**
  String get tutoringProfileLoadError;

  /// No description provided for @tutoringProrata.
  ///
  /// In fr, this message translates to:
  /// **'Facturation au prorata des tranches de 30 min.'**
  String get tutoringProrata;

  /// No description provided for @tutoringQuoteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de calculer le prix.'**
  String get tutoringQuoteError;

  /// No description provided for @tutoringRateFrom.
  ///
  /// In fr, this message translates to:
  /// **'dès {amount} XAF/h'**
  String tutoringRateFrom(Object amount);

  /// No description provided for @tutoringRateLine.
  ///
  /// In fr, this message translates to:
  /// **'{subject} · {mode} : {rate} XAF / h'**
  String tutoringRateLine(Object subject, Object mode, Object rate);

  /// No description provided for @tutoringRateNa.
  ///
  /// In fr, this message translates to:
  /// **'Tarif ND'**
  String get tutoringRateNa;

  /// No description provided for @tutoringRateNotGiven.
  ///
  /// In fr, this message translates to:
  /// **'Tarif non communiqué'**
  String get tutoringRateNotGiven;

  /// No description provided for @tutoringRatesPackages.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs & forfaits'**
  String get tutoringRatesPackages;

  /// No description provided for @tutoringRatingReviews.
  ///
  /// In fr, this message translates to:
  /// **'{rating}/5 ({count} avis)'**
  String tutoringRatingReviews(Object rating, Object count);

  /// No description provided for @tutoringReasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get tutoringReasonOptional;

  /// No description provided for @tutoringRechargeAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant (minimum {amount} FCFA)'**
  String tutoringRechargeAmount(Object amount);

  /// No description provided for @tutoringRechargeConfirmOnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le paiement sur ton téléphone ; le solde s\'actualise dès la confirmation.'**
  String get tutoringRechargeConfirmOnPhone;

  /// No description provided for @tutoringRechargeConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Recharge confirmée : le solde de l\'institution est à jour.'**
  String get tutoringRechargeConfirmed;

  /// No description provided for @tutoringRechargeFailed.
  ///
  /// In fr, this message translates to:
  /// **'La recharge n\'a pas abouti : aucun montant n\'a été débité.'**
  String get tutoringRechargeFailed;

  /// No description provided for @tutoringRechargePending.
  ///
  /// In fr, this message translates to:
  /// **'Recharge en attente de confirmation sur le téléphone…'**
  String get tutoringRechargePending;

  /// No description provided for @tutoringRechargePhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro (6XXXXXXXX)'**
  String get tutoringRechargePhone;

  /// No description provided for @tutoringRechargeStartError.
  ///
  /// In fr, this message translates to:
  /// **'La recharge n\'a pas pu être lancée.'**
  String get tutoringRechargeStartError;

  /// No description provided for @tutoringRechargeStillPending.
  ///
  /// In fr, this message translates to:
  /// **'Recharge toujours en attente : tire vers le bas pour actualiser le solde plus tard.'**
  String get tutoringRechargeStillPending;

  /// No description provided for @tutoringRechargeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharger le portefeuille'**
  String get tutoringRechargeTitle;

  /// No description provided for @tutoringReference.
  ///
  /// In fr, this message translates to:
  /// **'Réf. : {ref}'**
  String tutoringReference(Object ref);

  /// No description provided for @tutoringReportChooseReason.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un motif.'**
  String get tutoringReportChooseReason;

  /// No description provided for @tutoringReportDescribe.
  ///
  /// In fr, this message translates to:
  /// **'Décris ce qui s\'est passé (10 caractères au moins).'**
  String get tutoringReportDescribe;

  /// No description provided for @tutoringReportDescriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultative)'**
  String get tutoringReportDescriptionOptional;

  /// No description provided for @tutoringReportIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ton signalement est transmis à l\'équipe WinPlus, qui l\'examine. Le tuteur ne voit pas qui l\'a signalé. Pour un remboursement, utilise plutôt « Contester la séance ».'**
  String get tutoringReportIntro;

  /// No description provided for @tutoringReportName.
  ///
  /// In fr, this message translates to:
  /// **'Signaler {name}'**
  String tutoringReportName(Object name);

  /// No description provided for @tutoringReportPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui s\'est passé, quand, comment.'**
  String get tutoringReportPlaceholder;

  /// No description provided for @tutoringReportProblem.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get tutoringReportProblem;

  /// No description provided for @tutoringReportProblemHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème rencontré pendant cette séance.'**
  String get tutoringReportProblemHint;

  /// No description provided for @tutoringReportProblemPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex : le tuteur ne s\'est pas présenté…'**
  String get tutoringReportProblemPlaceholder;

  /// No description provided for @tutoringReportReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get tutoringReportReason;

  /// No description provided for @tutoringReportSentTeam.
  ///
  /// In fr, this message translates to:
  /// **'Signalement du tuteur envoyé à l\'équipe WinPlus.'**
  String get tutoringReportSentTeam;

  /// No description provided for @tutoringReportSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get tutoringReportSubmit;

  /// No description provided for @tutoringReportTutor.
  ///
  /// In fr, this message translates to:
  /// **'Signaler le tuteur'**
  String get tutoringReportTutor;

  /// No description provided for @tutoringReviewChooseRating.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une note avant d\'envoyer.'**
  String get tutoringReviewChooseRating;

  /// No description provided for @tutoringReviewCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (optionnel, 300 caractères max)'**
  String get tutoringReviewCommentHint;

  /// No description provided for @tutoringReviewSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get tutoringReviewSubmit;

  /// No description provided for @tutoringReviewThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get tutoringReviewThanks;

  /// No description provided for @tutoringSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tuteur trouvé pour ces critères.'**
  String get tutoringSearchEmpty;

  /// No description provided for @tutoringSearchLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les tuteurs.'**
  String get tutoringSearchLoadError;

  /// No description provided for @tutoringSearchStudent.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un élève'**
  String get tutoringSearchStudent;

  /// No description provided for @tutoringSearchTopicsHint.
  ///
  /// In fr, this message translates to:
  /// **'Sujets à travailler (ex. dérivées, dissertation)'**
  String get tutoringSearchTopicsHint;

  /// No description provided for @tutoringSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get tutoringSending;

  /// No description provided for @tutoringSession.
  ///
  /// In fr, this message translates to:
  /// **'Séance'**
  String get tutoringSession;

  /// No description provided for @tutoringSessionConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Séance confirmée !'**
  String get tutoringSessionConfirmed;

  /// No description provided for @tutoringSessionMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de séance'**
  String get tutoringSessionMode;

  /// No description provided for @tutoringShortfallInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Choisis Mobile Money ou recharge le portefeuille de l\'institution (écran Tutorat).'**
  String get tutoringShortfallInstitution;

  /// No description provided for @tutoringShortfallMine.
  ///
  /// In fr, this message translates to:
  /// **'Choisis Mobile Money.'**
  String get tutoringShortfallMine;

  /// No description provided for @tutoringShortfallParent.
  ///
  /// In fr, this message translates to:
  /// **'Choisis Mobile Money ou recharge ton portefeuille parent.'**
  String get tutoringShortfallParent;

  /// No description provided for @tutoringSlotGone.
  ///
  /// In fr, this message translates to:
  /// **'Ce créneau n\'est plus disponible.'**
  String get tutoringSlotGone;

  /// No description provided for @tutoringSoloPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix pour un élève'**
  String get tutoringSoloPrice;

  /// No description provided for @tutoringStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get tutoringStatusCancelled;

  /// No description provided for @tutoringStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Effectuée'**
  String get tutoringStatusCompleted;

  /// No description provided for @tutoringStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get tutoringStatusConfirmed;

  /// No description provided for @tutoringStatusDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Contestée'**
  String get tutoringStatusDisputed;

  /// No description provided for @tutoringStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get tutoringStatusExpired;

  /// No description provided for @tutoringStatusPendingPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours'**
  String get tutoringStatusPendingPayment;

  /// No description provided for @tutoringStatusPendingTutor.
  ///
  /// In fr, this message translates to:
  /// **'En attente du tuteur'**
  String get tutoringStatusPendingTutor;

  /// No description provided for @tutoringStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get tutoringStatusRejected;

  /// No description provided for @tutoringStepChooseSlot.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un créneau'**
  String get tutoringStepChooseSlot;

  /// No description provided for @tutoringStepPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get tutoringStepPayment;

  /// No description provided for @tutoringStepRecap.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get tutoringStepRecap;

  /// No description provided for @tutoringStepSlot.
  ///
  /// In fr, this message translates to:
  /// **'Créneau'**
  String get tutoringStepSlot;

  /// No description provided for @tutoringStillWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Toujours en attente'**
  String get tutoringStillWaiting;

  /// No description provided for @tutoringStudentFallback.
  ///
  /// In fr, this message translates to:
  /// **'Élève #{id}'**
  String tutoringStudentFallback(Object id);

  /// No description provided for @tutoringStudentsCountPrefix.
  ///
  /// In fr, this message translates to:
  /// **'{count} élève(s) : '**
  String tutoringStudentsCountPrefix(Object count);

  /// No description provided for @tutoringStudentsN.
  ///
  /// In fr, this message translates to:
  /// **'Élèves ({count})'**
  String tutoringStudentsN(Object count);

  /// No description provided for @tutoringSubjectEconomics.
  ///
  /// In fr, this message translates to:
  /// **'Économie'**
  String get tutoringSubjectEconomics;

  /// No description provided for @tutoringSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get tutoringSubjects;

  /// No description provided for @tutoringSubjectsLevels.
  ///
  /// In fr, this message translates to:
  /// **'Matières & niveaux'**
  String get tutoringSubjectsLevels;

  /// No description provided for @tutoringSubtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get tutoringSubtotal;

  /// No description provided for @tutoringTheTutor.
  ///
  /// In fr, this message translates to:
  /// **'le tuteur'**
  String get tutoringTheTutor;

  /// No description provided for @tutoringTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get tutoringTime;

  /// No description provided for @tutoringTopUp.
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get tutoringTopUp;

  /// No description provided for @tutoringTopics.
  ///
  /// In fr, this message translates to:
  /// **'Sujets'**
  String get tutoringTopics;

  /// No description provided for @tutoringTopicsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le tuteur les verra dans ta demande pour préparer la séance.'**
  String get tutoringTopicsHelp;

  /// No description provided for @tutoringTopicsOptional.
  ///
  /// In fr, this message translates to:
  /// **'Sujets à travailler (facultatif)'**
  String get tutoringTopicsOptional;

  /// No description provided for @tutoringTopicsPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex. équations du second degré'**
  String get tutoringTopicsPlaceholder;

  /// No description provided for @tutoringTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get tutoringTotal;

  /// No description provided for @tutoringTotalGroup.
  ///
  /// In fr, this message translates to:
  /// **'Total (groupe)'**
  String get tutoringTotalGroup;

  /// No description provided for @tutoringTrialFree.
  ///
  /// In fr, this message translates to:
  /// **'Séance d\'essai gratuite'**
  String get tutoringTrialFree;

  /// No description provided for @tutoringTrialPrice.
  ///
  /// In fr, this message translates to:
  /// **'Séance d\'essai : {amount} XAF'**
  String tutoringTrialPrice(Object amount);

  /// No description provided for @tutoringTutor.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur'**
  String get tutoringTutor;

  /// No description provided for @tutoringTutoring.
  ///
  /// In fr, this message translates to:
  /// **'Tutorat'**
  String get tutoringTutoring;

  /// No description provided for @tutoringUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get tutoringUnavailable;

  /// No description provided for @tutoringUnavailableParen.
  ///
  /// In fr, this message translates to:
  /// **'(indisponible)'**
  String get tutoringUnavailableParen;

  /// No description provided for @tutoringUnavailableShort.
  ///
  /// In fr, this message translates to:
  /// **'(indisp.)'**
  String get tutoringUnavailableShort;

  /// No description provided for @tutoringViewMySession.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma séance'**
  String get tutoringViewMySession;

  /// No description provided for @tutoringWaitingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation…'**
  String get tutoringWaitingConfirmation;

  /// No description provided for @tutoringWaitingUssd.
  ///
  /// In fr, this message translates to:
  /// **'Valide le paiement via le message USSD envoyé sur ton téléphone.'**
  String get tutoringWaitingUssd;

  /// No description provided for @tutoringWalletAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible : {amount} XAF'**
  String tutoringWalletAvailable(Object amount);

  /// No description provided for @tutoringWalletInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille de l\'institution'**
  String get tutoringWalletInstitution;

  /// No description provided for @tutoringWalletLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du solde…'**
  String get tutoringWalletLoading;

  /// No description provided for @tutoringWalletMine.
  ///
  /// In fr, this message translates to:
  /// **'Mon solde WinPlus'**
  String get tutoringWalletMine;

  /// No description provided for @tutoringWalletMineGroup.
  ///
  /// In fr, this message translates to:
  /// **'Mon solde WinPlus (je paie pour le groupe)'**
  String get tutoringWalletMineGroup;

  /// No description provided for @tutoringWalletMissing.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant : il manque {amount} XAF. {hint}'**
  String tutoringWalletMissing(Object amount, Object hint);

  /// No description provided for @tutoringWalletOk.
  ///
  /// In fr, this message translates to:
  /// **'Paiement immédiat et sans frais. Ta demande part tout de suite au tuteur.'**
  String get tutoringWalletOk;

  /// No description provided for @tutoringWalletParent.
  ///
  /// In fr, this message translates to:
  /// **'Mon portefeuille parent'**
  String get tutoringWalletParent;

  /// No description provided for @tutoringWalletUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Solde indisponible'**
  String get tutoringWalletUnavailable;

  /// No description provided for @tutoringWinplusBalance.
  ///
  /// In fr, this message translates to:
  /// **'solde WinPlus'**
  String get tutoringWinplusBalance;

  /// No description provided for @tutoringWithName.
  ///
  /// In fr, this message translates to:
  /// **'avec {name}'**
  String tutoringWithName(Object name);

  /// No description provided for @tutoringYourInstitution.
  ///
  /// In fr, this message translates to:
  /// **'ton institution'**
  String get tutoringYourInstitution;

  /// No description provided for @tutoringYourTutor.
  ///
  /// In fr, this message translates to:
  /// **'ton tuteur'**
  String get tutoringYourTutor;

  /// No description provided for @welcomeTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ta réussite, notre mission'**
  String get welcomeTagline;

  /// No description provided for @widgetKbOff.
  ///
  /// In fr, this message translates to:
  /// **' · désactivée. L\'activer cherche dans les cours et vos fichiers, mais consomme plus de tokens.'**
  String get widgetKbOff;

  /// No description provided for @widgetKbOn.
  ///
  /// In fr, this message translates to:
  /// **' · activée : chaque message consomme nettement plus de tokens.'**
  String get widgetKbOn;

  /// No description provided for @widgetKbTitle.
  ///
  /// In fr, this message translates to:
  /// **'Base de connaissance'**
  String get widgetKbTitle;

  /// No description provided for @widgetMemDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression échouée.'**
  String get widgetMemDeleteFailed;

  /// No description provided for @widgetMemDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get widgetMemDifficulty;

  /// No description provided for @widgetMemEmpty.
  ///
  /// In fr, this message translates to:
  /// **'WinAI n\'a pas encore mémorisé d\'informations. Continue à interagir !'**
  String get widgetMemEmpty;

  /// No description provided for @widgetMemExam.
  ///
  /// In fr, this message translates to:
  /// **'Examen'**
  String get widgetMemExam;

  /// No description provided for @widgetMemLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les mémoires.'**
  String get widgetMemLoadError;

  /// No description provided for @widgetMemMastered.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisé'**
  String get widgetMemMastered;

  /// No description provided for @widgetMemMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire'**
  String get widgetMemMemory;

  /// No description provided for @widgetMemMotivation.
  ///
  /// In fr, this message translates to:
  /// **'Motivation'**
  String get widgetMemMotivation;

  /// No description provided for @widgetMemPreference.
  ///
  /// In fr, this message translates to:
  /// **'Préférence'**
  String get widgetMemPreference;

  /// No description provided for @widgetMemRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get widgetMemRefresh;

  /// No description provided for @widgetMemSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que WinAI a retenu de toi'**
  String get widgetMemSubtitle;

  /// No description provided for @widgetOfflineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne  dernière mise à jour : {when}'**
  String widgetOfflineBanner(Object when);

  /// No description provided for @widgetOfflineUnknown.
  ///
  /// In fr, this message translates to:
  /// **'inconnue'**
  String get widgetOfflineUnknown;

  /// No description provided for @wrongCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get wrongCredentials;

  /// No description provided for @instMonthlyReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport mensuel par e-mail'**
  String get instMonthlyReportTitle;

  /// No description provided for @instMonthlyReportSub.
  ///
  /// In fr, this message translates to:
  /// **'Reçu par e-mail le 1er de chaque mois'**
  String get instMonthlyReportSub;

  /// No description provided for @instMonthlyReportMeta.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres du mois, devoirs, annonces, bulletins, élèves à relancer et plan d\'action WinAI.'**
  String get instMonthlyReportMeta;

  /// No description provided for @instMonthlyReportSendNow.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir maintenant'**
  String get instMonthlyReportSendNow;

  /// No description provided for @instMonthlyReportSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get instMonthlyReportSending;

  /// No description provided for @instMonthlyReportSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé : vérifiez votre boîte de réception (et les indésirables).'**
  String get instMonthlyReportSent;

  /// No description provided for @instMonthlyReportError.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi a échoué. Réessayez dans un instant.'**
  String get instMonthlyReportError;

  /// No description provided for @instMonthlyReportNoEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse e-mail sur ce compte.'**
  String get instMonthlyReportNoEmail;

  /// No description provided for @studentPdfLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Le document n\'a pas pu être chargé.'**
  String get studentPdfLoadError;

  /// No description provided for @studentPlayerTapToOpen.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour ouvrir le document'**
  String get studentPlayerTapToOpen;

  /// No description provided for @studentPlayerOpenOnWeb.
  ///
  /// In fr, this message translates to:
  /// **'Ce type de fichier s\'ouvre depuis le site winplus.cm.'**
  String get studentPlayerOpenOnWeb;

  /// No description provided for @studentCertCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get studentCertCopyLink;

  /// No description provided for @studentCertLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien de vérification copié.'**
  String get studentCertLinkCopied;

  /// No description provided for @mobileHomeForYou.
  ///
  /// In fr, this message translates to:
  /// **'Pour toi'**
  String get mobileHomeForYou;

  /// No description provided for @mobileHomeFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get mobileHomeFilters;

  /// No description provided for @mobileHomeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get mobileHomeSeeAll;

  /// No description provided for @mobileHomeQuick.
  ///
  /// In fr, this message translates to:
  /// **'Accès rapide'**
  String get mobileHomeQuick;

  /// No description provided for @mobileHomeAllShortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Tous les raccourcis'**
  String get mobileHomeAllShortcuts;

  /// No description provided for @mobileHomeStatsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get mobileHomeStatsDetail;

  /// No description provided for @mobileHomeStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes statistiques'**
  String get mobileHomeStatsTitle;

  /// No description provided for @mobileHomeClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get mobileHomeClose;

  /// No description provided for @mobileHomeEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'À faire maintenant'**
  String get mobileHomeEyebrow;

  /// No description provided for @mobileHomeSlide.
  ///
  /// In fr, this message translates to:
  /// **'Carte {n} sur {total}'**
  String mobileHomeSlide(int n, int total);

  /// No description provided for @mobileHomeSearchPaper.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une épreuve…'**
  String get mobileHomeSearchPaper;

  /// No description provided for @mobileHomeSearchStudent.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un élève…'**
  String get mobileHomeSearchStudent;

  /// No description provided for @mobileHomeStudentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ta séance du jour'**
  String get mobileHomeStudentTitle;

  /// No description provided for @mobileHomeStudentMeta.
  ///
  /// In fr, this message translates to:
  /// **'20 minutes sur tes points faibles.'**
  String get mobileHomeStudentMeta;

  /// No description provided for @mobileHomeStudentCta.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get mobileHomeStudentCta;

  /// No description provided for @mobileHomeResumeTag.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get mobileHomeResumeTag;

  /// No description provided for @mobileHomeResumeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprends là où tu en étais'**
  String get mobileHomeResumeTitle;

  /// No description provided for @mobileHomeResumeMeta.
  ///
  /// In fr, this message translates to:
  /// **'Tes épreuves et quiz commencés.'**
  String get mobileHomeResumeMeta;

  /// No description provided for @mobileHomeResumeCta.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get mobileHomeResumeCta;

  /// No description provided for @mobileHomeCoachTag.
  ///
  /// In fr, this message translates to:
  /// **'Coach d\'examen'**
  String get mobileHomeCoachTag;

  /// No description provided for @mobileHomeCoachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton plan jusqu\'au jour J'**
  String get mobileHomeCoachTitle;

  /// No description provided for @mobileHomeCoachMeta.
  ///
  /// In fr, this message translates to:
  /// **'Ton examen, ta date : on organise tout.'**
  String get mobileHomeCoachMeta;

  /// No description provided for @mobileHomeCoachCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get mobileHomeCoachCta;

  /// No description provided for @mobileHomePapersTag.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get mobileHomePapersTag;

  /// No description provided for @mobileHomePapersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Épreuves et corrigés'**
  String get mobileHomePapersTitle;

  /// No description provided for @mobileHomePapersMeta.
  ///
  /// In fr, this message translates to:
  /// **'BEPC, Probatoire, Bac, concours.'**
  String get mobileHomePapersMeta;

  /// No description provided for @mobileHomePapersCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get mobileHomePapersCta;

  /// No description provided for @mobileHomeQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get mobileHomeQuiz;

  /// No description provided for @mobileHomePapers.
  ///
  /// In fr, this message translates to:
  /// **'Épreuves'**
  String get mobileHomePapers;

  /// No description provided for @mobileHomeRevisions.
  ///
  /// In fr, this message translates to:
  /// **'Révisions'**
  String get mobileHomeRevisions;

  /// No description provided for @mobileHomeGroups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get mobileHomeGroups;

  /// No description provided for @mobileHomeLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Liez le compte de votre enfant'**
  String get mobileHomeLinkTitle;

  /// No description provided for @mobileHomeLinkMeta.
  ///
  /// In fr, this message translates to:
  /// **'Vous suivez ensuite ses révisions et ses résultats.'**
  String get mobileHomeLinkMeta;

  /// No description provided for @mobileHomeAddChild.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get mobileHomeAddChild;

  /// No description provided for @mobileHomeFollowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où en est {name} cette semaine'**
  String mobileHomeFollowTitle(String name);

  /// No description provided for @mobileHomeFollowMeta.
  ///
  /// In fr, this message translates to:
  /// **'Régularité, résultats, points à travailler.'**
  String get mobileHomeFollowMeta;

  /// No description provided for @mobileHomeFollowCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get mobileHomeFollowCta;

  /// No description provided for @mobileHomeYourChild.
  ///
  /// In fr, this message translates to:
  /// **'votre enfant'**
  String get mobileHomeYourChild;

  /// No description provided for @mobileHomeTutorTag.
  ///
  /// In fr, this message translates to:
  /// **'Cours particuliers'**
  String get mobileHomeTutorTag;

  /// No description provided for @mobileHomeTutorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un répétiteur près de chez vous'**
  String get mobileHomeTutorTitle;

  /// No description provided for @mobileHomeTutorMeta.
  ///
  /// In fr, this message translates to:
  /// **'Profils vérifiés, à domicile ou en ligne.'**
  String get mobileHomeTutorMeta;

  /// No description provided for @mobileHomeTutorCta.
  ///
  /// In fr, this message translates to:
  /// **'Trouver'**
  String get mobileHomeTutorCta;

  /// No description provided for @mobileHomeSheetTag.
  ///
  /// In fr, this message translates to:
  /// **'WinAI'**
  String get mobileHomeSheetTag;

  /// No description provided for @mobileHomeSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une fiche de révision sur mesure'**
  String get mobileHomeSheetTitle;

  /// No description provided for @mobileHomeSheetMeta.
  ///
  /// In fr, this message translates to:
  /// **'Sur la matière où votre enfant bloque.'**
  String get mobileHomeSheetMeta;

  /// No description provided for @mobileHomeSheetCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get mobileHomeSheetCta;

  /// No description provided for @mobileHomeSheetPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Prépare une fiche de révision sur la matière où mon enfant a le plus de difficultés.'**
  String get mobileHomeSheetPrompt;

  /// No description provided for @mobileHomeSuivi.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get mobileHomeSuivi;

  /// No description provided for @mobileHomeMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get mobileHomeMessages;

  /// No description provided for @mobileHomeAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get mobileHomeAdvice;

  /// No description provided for @mobileHomeSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get mobileHomeSubscription;

  /// No description provided for @mobileHomeBuy.
  ///
  /// In fr, this message translates to:
  /// **'Acheter'**
  String get mobileHomeBuy;

  /// No description provided for @mobileHomeAdviceCount.
  ///
  /// In fr, this message translates to:
  /// **'Conseils WinAI'**
  String get mobileHomeAdviceCount;

  /// No description provided for @mobileHomeChildrenAvg.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne des enfants'**
  String get mobileHomeChildrenAvg;

  /// No description provided for @mobileHomeCorrectTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} copie à corriger} other{{count} copies à corriger}}'**
  String mobileHomeCorrectTitle(int count);

  /// No description provided for @mobileHomeCorrectMeta.
  ///
  /// In fr, this message translates to:
  /// **'Vos élèves attendent leur note.'**
  String get mobileHomeCorrectMeta;

  /// No description provided for @mobileHomeCorrectCta.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get mobileHomeCorrectCta;

  /// No description provided for @mobileHomePublishTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez un nouveau contenu'**
  String get mobileHomePublishTitle;

  /// No description provided for @mobileHomePublishMeta.
  ///
  /// In fr, this message translates to:
  /// **'Vos élèves le retrouvent tout de suite.'**
  String get mobileHomePublishMeta;

  /// No description provided for @mobileHomePublishCta.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get mobileHomePublishCta;

  /// No description provided for @mobileHomeTeachTutorTag.
  ///
  /// In fr, this message translates to:
  /// **'Revenus en plus'**
  String get mobileHomeTeachTutorTag;

  /// No description provided for @mobileHomeTeachTutorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activez le mode répétiteur'**
  String get mobileHomeTeachTutorTitle;

  /// No description provided for @mobileHomeTeachTutorMeta.
  ///
  /// In fr, this message translates to:
  /// **'Proposez des cours particuliers.'**
  String get mobileHomeTeachTutorMeta;

  /// No description provided for @mobileHomeTeachTutorCta.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get mobileHomeTeachTutorCta;

  /// No description provided for @mobileHomeCoursesTag.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get mobileHomeCoursesTag;

  /// No description provided for @mobileHomeCoursesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez une formation complète'**
  String get mobileHomeCoursesTitle;

  /// No description provided for @mobileHomeCoursesMeta.
  ///
  /// In fr, this message translates to:
  /// **'Modules, quiz et examen final.'**
  String get mobileHomeCoursesMeta;

  /// No description provided for @mobileHomeCoursesCta.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get mobileHomeCoursesCta;

  /// No description provided for @mobileHomeClasses.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get mobileHomeClasses;

  /// No description provided for @mobileHomeCorrections.
  ///
  /// In fr, this message translates to:
  /// **'Corrections'**
  String get mobileHomeCorrections;

  /// No description provided for @mobileHomeSessions.
  ///
  /// In fr, this message translates to:
  /// **'Séances'**
  String get mobileHomeSessions;

  /// No description provided for @mobileHomeRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get mobileHomeRevenue;

  /// No description provided for @mobileHomeShare.
  ///
  /// In fr, this message translates to:
  /// **'Votre part'**
  String get mobileHomeShare;

  /// No description provided for @mobileHomeInstTitle.
  ///
  /// In fr, this message translates to:
  /// **'Élèves à accompagner'**
  String get mobileHomeInstTitle;

  /// No description provided for @mobileHomeInstMeta.
  ///
  /// In fr, this message translates to:
  /// **'Régularité ou résultats en baisse, classe par classe.'**
  String get mobileHomeInstMeta;

  /// No description provided for @mobileHomeInstCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get mobileHomeInstCta;

  /// No description provided for @mobileHomeReportTag.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get mobileHomeReportTag;

  /// No description provided for @mobileHomeReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le bilan de l\'établissement'**
  String get mobileHomeReportTitle;

  /// No description provided for @mobileHomeReportMeta.
  ///
  /// In fr, this message translates to:
  /// **'Un PDF prêt à partager.'**
  String get mobileHomeReportMeta;

  /// No description provided for @mobileHomeReportCta.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get mobileHomeReportCta;

  /// No description provided for @mobileHomePlanTag.
  ///
  /// In fr, this message translates to:
  /// **'WinAI'**
  String get mobileHomePlanTag;

  /// No description provided for @mobileHomePlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un plan d\'action pour vos classes'**
  String get mobileHomePlanTitle;

  /// No description provided for @mobileHomePlanMeta.
  ///
  /// In fr, this message translates to:
  /// **'Des pistes concrètes, classe par classe.'**
  String get mobileHomePlanMeta;

  /// No description provided for @mobileHomePlanCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get mobileHomePlanCta;

  /// No description provided for @mobileHomeDirectory.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire'**
  String get mobileHomeDirectory;

  /// No description provided for @mobileHomeAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Analyses'**
  String get mobileHomeAnalytics;

  /// No description provided for @mobileHomeLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence'**
  String get mobileHomeLicense;

  /// No description provided for @mobileHomeStatStudy.
  ///
  /// In fr, this message translates to:
  /// **'Temps d\'étude'**
  String get mobileHomeStatStudy;

  /// No description provided for @mobileHomeStatQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz cette semaine'**
  String get mobileHomeStatQuiz;

  /// No description provided for @mobileHomeStatStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série en cours'**
  String get mobileHomeStatStreak;

  /// No description provided for @mobileHomeStatChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants suivis'**
  String get mobileHomeStatChildren;

  /// No description provided for @mobileHomeStatCredits.
  ///
  /// In fr, this message translates to:
  /// **'Crédits disponibles'**
  String get mobileHomeStatCredits;

  /// No description provided for @mobileHomeStatActive.
  ///
  /// In fr, this message translates to:
  /// **'Élèves actifs'**
  String get mobileHomeStatActive;

  /// No description provided for @mobileHomeThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get mobileHomeThisWeek;

  /// No description provided for @mobileHomeDays.
  ///
  /// In fr, this message translates to:
  /// **'{n} j'**
  String mobileHomeDays(int n);

  /// No description provided for @mobileHomeAtRiskMeta.
  ///
  /// In fr, this message translates to:
  /// **'{n} élèves à suivre de près, classe par classe.'**
  String mobileHomeAtRiskMeta(int n);

  /// No description provided for @mobileCatalogCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun contenu} =1{1 contenu} other{{count} contenus}}'**
  String mobileCatalogCount(int count);

  /// No description provided for @mobileCatalogCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get mobileCatalogCart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
