// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aiAskHint => 'Type your question…';

  @override
  String get authAccountActive => 'Your WinPlus account is now active.';

  @override
  String get authAlreadyAccount => 'Already have an account? ';

  @override
  String get authBackToLogin => 'Back to log in';

  @override
  String authBornOn(Object date) {
    return 'Born on $date';
  }

  @override
  String get authChooseProfile =>
      'Choose your profile for a personalised experience.';

  @override
  String get authChooseSecure => 'Choose a secure password.';

  @override
  String get authCodeIncorrect => 'Incorrect code. Check your email.';

  @override
  String get authCodeInvalid => 'Invalid code.';

  @override
  String get authCodeSentAddress =>
      'A 6-digit code has been sent to your address.';

  @override
  String get authCodeSentEmail => 'Code sent to your email';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authCreateMyAccount => 'Create my account';

  @override
  String get authDobOptional => 'Date of birth (optional)';

  @override
  String get authEmailAddress => 'Email address';

  @override
  String get authEmailHint => 'your@email.com';

  @override
  String get authEmailVerified => 'Email verified!';

  @override
  String get authErrNetwork => 'Network error.';

  @override
  String get authFeatInst1 => 'Centralised dashboard';

  @override
  String get authFeatInst2 => 'Multi-student licences';

  @override
  String get authFeatInst3 => 'Indicators for your students';

  @override
  String get authFeatParent1 => 'Follow your children\'s progress';

  @override
  String get authFeatParent3 => 'Buy content for them';

  @override
  String get authFeatStudent1 =>
      'Past papers and worked solutions to read in the app';

  @override
  String get authFeatStudent2 => 'Personalised AI quizzes';

  @override
  String get authFeatStudent3 => 'Certificates for your completed courses';

  @override
  String get authFeatTeacher1 => 'Publish and monetise your content';

  @override
  String get authFeatTeacher2 => 'Manage your classes';

  @override
  String get authFeatTeacher3 => 'Earnings from your sales and your sessions';

  @override
  String get authFillRequired => 'Please fill in all required fields.';

  @override
  String get authFinish => 'Finish';

  @override
  String get authFirstName => 'First name';

  @override
  String get authFollowCloseHint =>
      'Alerts as soon as something important happens.';

  @override
  String get authFollowCloseLabel => 'Close follow-up';

  @override
  String get authFollowMinimalHint => 'I will check the parent space myself.';

  @override
  String get authFollowMinimalLabel => 'The minimum';

  @override
  String get authFollowWeeklyHint =>
      'A summary of the week, with no alerts along the way.';

  @override
  String get authFollowWeeklyLabel => 'Weekly report';

  @override
  String get authForgotIntro =>
      'Enter your email address and we will send you a reset link.';

  @override
  String get authForgotNotReceived => 'Didn\'t receive the email?';

  @override
  String authForgotSent(Object email) {
    return 'Email sent to $email. Check your spam folder too.';
  }

  @override
  String get authForgotTitle => 'Forgot password';

  @override
  String get authGoToLogin => 'Go to log in';

  @override
  String get authGoogleSoon => 'Google sign-in coming soon!';

  @override
  String get authIAm => 'I am…';

  @override
  String get authLastName => 'Last name';

  @override
  String get authLogMeOut => 'Log out';

  @override
  String get authLvlEns => 'ENS Teacher Training';

  @override
  String get authLvlEssec => 'ESSEC Business';

  @override
  String get authLvlFmsb => 'FMSB Medicine';

  @override
  String get authLvlPrepa => 'Prep class';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authNext => 'Next';

  @override
  String get authOptConcours => 'Competitive exam';

  @override
  String get authOptEconomics => 'Economics';

  @override
  String get authOptLiterary => 'Literary';

  @override
  String get authOptOther => 'Other';

  @override
  String get authOptPolytechnique => 'Polytechnic';

  @override
  String get authOptScience => 'Science';

  @override
  String get authOptTechnical => 'Technical';

  @override
  String get authParentFollowHint =>
      'You can change this preference at any time.';

  @override
  String get authParentFollowTitle =>
      'How would you like to follow their schooling?';

  @override
  String get authParentGoalHint =>
      'In a few words: pass an exam, fill a gap, regain confidence…';

  @override
  String get authParentGoalPlaceholder =>
      'E.g. Help my son improve in maths before the BEPC';

  @override
  String get authParentGoalTitle => 'What is your goal for your child?';

  @override
  String get authPeriodicIntro =>
      'For your security, confirm your identity (every 20 days)';

  @override
  String get authPhoneOptional => 'Phone (optional)';

  @override
  String get authPhoneSoon => 'Phone login coming soon!';

  @override
  String get authPwdCriteria => 'The password does not meet the criteria.';

  @override
  String get authPwdUpdated => 'Password updated! You can now log in.';

  @override
  String get authResendCode => 'Resend code';

  @override
  String authResendCodeParen(Object seconds) {
    return 'Resend code (${seconds}s)';
  }

  @override
  String get authResendEmail => 'Resend the email';

  @override
  String authResendIn(Object seconds) {
    return 'Resend the code in ${seconds}s';
  }

  @override
  String get authReset => 'Reset';

  @override
  String get authRoleInstitutionDesc =>
      'High school, university or training center';

  @override
  String get authRoleInstitutionLabel => 'Institution';

  @override
  String get authRoleParentDesc => 'Track and support your children';

  @override
  String get authRoleParentLabel => 'Parent / Guardian';

  @override
  String get authRoleStudentDesc =>
      'From middle school to top-school entrance exams';

  @override
  String get authRoleStudentLabel => 'Student / Learner';

  @override
  String get authRoleTeacherDesc => 'Publish content and follow your learners';

  @override
  String get authRoleTeacherLabel => 'Teacher / Trainer';

  @override
  String get authRule8 => 'At least 8 characters';

  @override
  String get authRuleDigit => 'At least one number';

  @override
  String get authRuleMatch => 'The passwords match';

  @override
  String get authRuleUpper => 'At least one capital letter';

  @override
  String get authPhoneInvalid =>
      'Incomplete number: 9 digits (e.g. 6 90 12 34 56) or an international number starting with +.';

  @override
  String get authRuleLower => 'At least one lowercase letter';

  @override
  String get authRuleSpecial => 'At least one special character (- _ @ ! …)';

  @override
  String get authSendCode => 'Send the code';

  @override
  String get authSendLink => 'Send the link';

  @override
  String get authSignupFailed => 'Sign-up failed.';

  @override
  String get authSignupIntro => 'A few details to get started.';

  @override
  String get authSkip => 'Skip';

  @override
  String get authSkipStep => 'Skip this step';

  @override
  String get authStart => 'Start';

  @override
  String get authStepFollowUp => 'Follow-up';

  @override
  String get authStepGoal => 'Goal';

  @override
  String get authStepLevels => 'Levels';

  @override
  String get authStepStream => 'Stream';

  @override
  String get authStepSubjects => 'Subjects';

  @override
  String get authStudentGoalHint => 'The exam you want to prepare for.';

  @override
  String get authStudentGoalTitle => 'What is your goal?';

  @override
  String get authStudentLevelHint =>
      'WinAI adapts the content to your school level.';

  @override
  String get authStudentLevelTitle => 'What is your level?';

  @override
  String get authStudentStreamHint =>
      'To better target the available resources.';

  @override
  String get authStudentStreamTitle => 'What is your stream?';

  @override
  String get authSuccessInstitution =>
      'Manage your school from your dashboard.';

  @override
  String get authSuccessParent => 'You can now follow your children.';

  @override
  String get authSuccessStudent => 'Your profile is ready. Start revising!';

  @override
  String get authSuccessTeacher => 'Publish your first content!';

  @override
  String get authTeacherLevelsHint =>
      'Useful for placing your content and, later, your Tutor mode profile.';

  @override
  String get authTeacherLevelsTitle => 'Which levels do you cover?';

  @override
  String get authTeacherSubjectsHint =>
      'We adapt your teacher space and the WinAI suggestions to your subjects.';

  @override
  String get authTeacherSubjectsTitle => 'Which subjects do you teach?';

  @override
  String get authVerify => 'Verify';

  @override
  String get authVerifyEmailTitle => 'Email verification';

  @override
  String get authVerifyItsYou => 'Confirm that it\'s really you';

  @override
  String authWelcomeName(Object name) {
    return 'Welcome to WinPlus, $name!';
  }

  @override
  String get authWelcomeSlide1Subtitle =>
      'Past papers, worked solutions and quizzes, from the BEPC to the entrance exams of the top schools.';

  @override
  String get authWelcomeSlide1Title => 'All your papers, in one place';

  @override
  String get authWelcomeSlide2Subtitle =>
      'A learning assistant that spots your gaps and suggests a revision plan.';

  @override
  String get authWelcomeSlide2Title => 'WinAI by your side';

  @override
  String get authWelcomeSlide3Subtitle =>
      'Parents, teachers, students: everyone follows the student\'s progress.';

  @override
  String get authWelcomeSlide3Title => 'The whole family involved';

  @override
  String get authXpUnlocked => '+50 XP unlocked';

  @override
  String get authYouDefault => 'you';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonActive => 'Active';

  @override
  String get studentExamModuleTitle => 'End-of-module quiz';

  @override
  String get studentExamFinalTitle => 'Final exam';

  @override
  String studentExamFinalIntro(int score) {
    return 'The final exam covers the whole course: at least $score% to get the certificate.';
  }

  @override
  String get studentExamFinalLocked =>
      'Finish all the lessons to open the final exam.';

  @override
  String get studentExamStart => 'Start';

  @override
  String get studentExamRetry => 'Retake';

  @override
  String get studentExamLoading => 'Loading…';

  @override
  String get studentExamLoadFailed =>
      'Could not load the exam. Please try again in a moment.';

  @override
  String get studentExamPausedTitle => 'Revision break';

  @override
  String studentExamPausedBody(int failures, String date) {
    return '$failures failed attempts in a row: the exam reopens on $date. Use this time to fill the gaps with WinAI.';
  }

  @override
  String studentExamRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more attempts before a 24-hour revision break.',
      one: '1 more attempt before a 24-hour revision break.',
    );
    return '$_temp0';
  }

  @override
  String get studentExamWeakTitle => 'The questions you are struggling with';

  @override
  String get studentExamHelpTitle => 'WinAI helps you improve';

  @override
  String get studentExamAskWinAI => 'Revision plan';

  @override
  String get studentExamPractice => 'Practice quiz';

  @override
  String get studentExamStudySession => 'Study session';

  @override
  String get studentExamLessonsTitle => 'Lessons to review';

  @override
  String get studentExamNoWeakPoints =>
      '(no specific question: review the whole module)';

  @override
  String studentExamPlanPrompt(
      int failures, String exam, String course, String points) {
    return 'I failed the exam \"$exam\" of the course \"$course\" $failures times. The points I struggle with:\n$points\nSuggest a short revision plan: the lessons to review, study tips and a few exercises to fill these gaps.';
  }

  @override
  String studentExamPracticePrompt(String exam, String points) {
    return 'Prepare a practice quiz of 6 multiple-choice questions, with explained answers, for the exam \"$exam\", focused on these points:\n$points';
  }

  @override
  String get commonAll => 'All';

  @override
  String get studentSearchLangFr => 'French';

  @override
  String get studentSearchLangEn => 'English (GCE)';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDarkMode => 'Dark mode';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonDraft => 'Draft';

  @override
  String get commonDuration => 'Duration';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonFree => 'Free';

  @override
  String get commonLevel => 'Level';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonNetworkError => 'Network error';

  @override
  String get commonOnline => 'Online';

  @override
  String get commonPending => 'Pending';

  @override
  String get commonPublished => 'Published';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSubject => 'Subject';

  @override
  String get commonToday => 'Today';

  @override
  String get commonWinaiAlerts => 'WinAI alerts';

  @override
  String get commonWinaiMemory => 'WinAI memory';

  @override
  String get commonWinaiThinking => 'WinAI is thinking…';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get createAccount => 'Create an account';

  @override
  String get dataSubjectChemistry => 'Chemistry';

  @override
  String get dataSubjectComputing => 'Computer Science';

  @override
  String get dataSubjectComputingShort => 'CS';

  @override
  String get dataSubjectEnglish => 'English';

  @override
  String get dataSubjectFrench => 'French';

  @override
  String get dataSubjectHistGeo => 'History-Geography';

  @override
  String get dataSubjectHistGeoShort => 'Hist-Geo';

  @override
  String get dataSubjectMath => 'Mathematics';

  @override
  String get dataSubjectMathShort => 'Maths';

  @override
  String get dataSubjectPhilosophy => 'Philosophy';

  @override
  String get dataSubjectPhilosophyShort => 'Philo';

  @override
  String get dataSubjectPhysics => 'Physics';

  @override
  String get dataTypeBook => 'Book';

  @override
  String get dataTypeCorrection => 'Correction';

  @override
  String get dataTypePaper => 'Paper';

  @override
  String get email => 'Email';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String fmtDateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forumAll => 'All';

  @override
  String get forumAnonymous => 'Anonymous';

  @override
  String get forumCatDiscussions => 'Discussions';

  @override
  String get forumCatHelp => 'Help';

  @override
  String get forumCatQuestions => 'Questions';

  @override
  String get forumCatResources => 'Resources';

  @override
  String get forumCategory => 'Category';

  @override
  String get forumContentField => 'Content *';

  @override
  String get forumContentHint => 'Describe your question in detail…';

  @override
  String get forumEmptyCategory => 'No threads in this category.';

  @override
  String forumError(Object error) {
    return 'Error: $error';
  }

  @override
  String get forumNewThread => 'New thread';

  @override
  String get forumPublish => 'Publish';

  @override
  String get forumReplyHint => 'Your reply…';

  @override
  String get forumRoleTeacher => 'Teacher';

  @override
  String get forumSolved => 'Solved';

  @override
  String get forumThread => 'Thread';

  @override
  String get forumTitle => 'Forum';

  @override
  String get forumTitleField => 'Title *';

  @override
  String get forumTitleHint => 'Your question or topic…';

  @override
  String get instAccountAdmins => 'Administrators';

  @override
  String get instAccountBilling => 'Billing & receipts';

  @override
  String get instAccountGroups => 'Groups & classes';

  @override
  String get instAccountLicense => 'WinPlus licence: seats and renewal';

  @override
  String get instAccountReports => 'Exportable reports';

  @override
  String get instAccountSchool => 'School account';

  @override
  String get instAccountTutoring => 'Tutoring & wallet';

  @override
  String get instAiHint => 'Analysis, benchmark, action plan…';

  @override
  String get instAiSuggestion1 => 'Cohort analysis';

  @override
  String get instAiSuggestion3 => 'Priority action plan';

  @override
  String get instAiSuggestion4 => 'National benchmark';

  @override
  String get instAiTagline =>
      'Your analytical auditor & institutional strategist';

  @override
  String get instAnalyticsByGroup => 'Performance by group';

  @override
  String get instAnalyticsDownloadsMonth => 'Papers/month';

  @override
  String get instAnalyticsQuizMonth => 'Quizzes/month';

  @override
  String get instCatalogAssign => 'Assign';

  @override
  String get instCatalogLicenseInfo =>
      'School licence: content can be assigned to all your groups.';

  @override
  String instDashActiveStudents(Object pct) {
    return 'Active students$pct';
  }

  @override
  String get instDashActiveStudentsLower => 'active students';

  @override
  String get instDashAiPlan => 'AI action plan';

  @override
  String get instDashAlertsInfo =>
      'Analyse your groups\' performance and identify students at risk.';

  @override
  String get instDashDirectory => 'Directory';

  @override
  String get instDashNoLicense => 'No active licence';

  @override
  String get instDashQuickActions => 'Quick actions';

  @override
  String get instDashQuizMonth => 'Quizzes this month';

  @override
  String instDashStudentsCount(Object n) {
    return '$n students';
  }

  @override
  String instDashUrgent(Object n) {
    return '$n students need urgent attention';
  }

  @override
  String get instDirActive => 'Active';

  @override
  String get instDirAddError => 'Could not add this student';

  @override
  String get instDirAddSuccess => 'Student added successfully';

  @override
  String get instDirAvg => 'Avg.';

  @override
  String instDirCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'students',
      one: 'student',
    );
    return '$count $_temp0';
  }

  @override
  String get instDirEmailRequired => 'Email required';

  @override
  String get instDirGroup => 'Group';

  @override
  String get instDirNoInstitution => 'No school linked.';

  @override
  String get instDirNoStudent => 'No student found.';

  @override
  String get instDirSearchHint => 'Search by name or email…';

  @override
  String get instDirStudents => 'Students';

  @override
  String get instDirTitle => 'Student directory';

  @override
  String get instEndorseAction => 'Endorse';

  @override
  String get instEndorseBadge => 'Endorsed';

  @override
  String get instEndorseChangeDate => 'Change the date';

  @override
  String get instEndorseConfirm => 'Confirm the endorsement';

  @override
  String get instEndorseEmpty => 'No tutors linked to your school yet.';

  @override
  String get instEndorseHowHint =>
      'Interview, ID document seen in person, contract…';

  @override
  String get instEndorseHowLabel => 'How did you verify them?';

  @override
  String get instEndorseIntro =>
      'If your school has verified a tutor by its own means, endorse them: they will be able to offer in-person sessions. You can withdraw the endorsement at any time; removing the link also withdraws it.';

  @override
  String get instEndorseNotEndorsed => 'Not endorsed';

  @override
  String instEndorseOnDate(Object date) {
    return 'On $date';
  }

  @override
  String get instEndorseOtherRoute =>
      'Already verified for in-person lessons by another route';

  @override
  String get instEndorseReasonLabel => 'Reason (sent to the tutor)';

  @override
  String get instEndorseRevoke => 'Withdraw endorsement';

  @override
  String get instEndorseRevokeAction => 'Remove';

  @override
  String get instEndorseRevokeText =>
      'If they are not verified by another route, they will no longer be able to offer in-person sessions.';

  @override
  String get instEndorseRevokeTitle => 'Withdraw the endorsement?';

  @override
  String get instEndorseRevoked => 'Endorsement withdrawn.';

  @override
  String get instEndorseSaved => 'Endorsement saved.';

  @override
  String get instEndorseScreenTitle => 'Tutor endorsements';

  @override
  String get instEndorseSheetInfo =>
      'They will be able to offer in-person sessions, with the “Endorsed by: your school” badge.';

  @override
  String get instEndorseThisTutor => 'this tutor';

  @override
  String instEndorseTitle(Object name) {
    return 'Endorse $name';
  }

  @override
  String instEndorseVerifiedBy(Object name) {
    return 'Verified by $name';
  }

  @override
  String get instEndorseVerifierLabel => 'Verified by (name and role)';

  @override
  String get instGroupAddStudents => 'Add students';

  @override
  String get instGroupAssignInfo =>
      'Select content from the catalogue to assign it to this group.';

  @override
  String get instGroupAssignResources => 'Assign resources';

  @override
  String instGroupAssignTo(Object name) {
    return 'Assign to $name';
  }

  @override
  String get instGroupBrowseCatalog => 'Browse the catalogue';

  @override
  String get instGroupCreateError => 'Error while creating the group.';

  @override
  String get instGroupCreateSubmit => 'Create the group';

  @override
  String get instGroupCreated => 'Group created!';

  @override
  String instGroupCreatedSummary(Object name, Object count) {
    return '$name, $count student(s) added.';
  }

  @override
  String get instGroupLevelLabel => 'Level *';

  @override
  String get instGroupLevelLicence => 'Bachelor\'s degree';

  @override
  String get instGroupNameLabel => 'Group name *';

  @override
  String get instGroupNoMembers => 'No students in this group.';

  @override
  String get instGroupSearch => 'Search for a group…';

  @override
  String get instGroupSearchStudent => 'Search for a student…';

  @override
  String get instGroupSeeStudents => 'See students';

  @override
  String instGroupSelected(Object count) {
    return '$count selected';
  }

  @override
  String instLicenseAccount(Object id) {
    return 'Account $id';
  }

  @override
  String instLicenseAiBudget(Object value) {
    return 'School WinAI budget used: $value%';
  }

  @override
  String get instLicenseAutoRenew => 'Automatic renewal from the wallet';

  @override
  String instLicenseGridMin(Object min, Object perTeacher) {
    return 'Minimum $min seats, one teacher seat per $perTeacher students.';
  }

  @override
  String instLicenseGridPrices(Object tiers) {
    return 'Price incl. VAT per student per year: $tiers.';
  }

  @override
  String instLicenseGridTier(Object price, Object seats) {
    return '$price XAF from $seats seats';
  }

  @override
  String instLicenseHeading(Object status) {
    return 'Licence $status';
  }

  @override
  String get instLicenseNegotiated => 'Negotiated';

  @override
  String instLicensePastDue(Object date) {
    return 'Insufficient balance at renewal: top up the wallet before $date.';
  }

  @override
  String get instLicensePaymentFrom => 'Payment from the school\'s wallet.';

  @override
  String instLicensePeriod(Object start, Object end) {
    return 'From $start to $end';
  }

  @override
  String get instLicensePromo => 'Promo code';

  @override
  String get instLicensePurchase => 'Subscribe with the wallet';

  @override
  String get instLicensePurchaseError => 'Could not subscribe.';

  @override
  String instLicenseQuoteLine(Object price, Object teacherSeats, Object date) {
    return '$price XAF per student · $teacherSeats teacher seats · until $date';
  }

  @override
  String instLicenseQuoteTotal(Object amount) {
    return 'Total: $amount XAF incl. VAT';
  }

  @override
  String get instLicenseRelease => 'Release';

  @override
  String get instLicenseReleaseError => 'Could not release the seat.';

  @override
  String get instLicenseRenewWallet => 'Renew from the wallet';

  @override
  String get instLicenseSeatBenefits =>
      'Each seat gives the student the catalogue, the study plan, the guided session, Exam Coach and a WinAI bonus; a teacher seat unlocks the Pro plan tools and a 75% share of tutoring.';

  @override
  String get instLicenseSeatsInfo =>
      'A student seat is assigned when the student accepts their link to the school; a teacher seat when the teacher accepts the affiliation.';

  @override
  String get instLicenseSeatsTitle => 'Assigned seats';

  @override
  String get instLicenseStatusEnded => 'Ended';

  @override
  String get instLicenseStudentSeats => 'Student seats';

  @override
  String instLicenseStudentSeatsUsed(Object used, Object total) {
    return 'Student seats: $used / $total';
  }

  @override
  String get instLicenseSubscribeTitle => 'Subscribe to a licence';

  @override
  String instLicenseTeacherSeatsUsed(Object used, Object total) {
    return 'Teacher seats: $used / $total';
  }

  @override
  String get instLicenseTermQuarter => 'Term';

  @override
  String get instLicenseTermYear => 'School year';

  @override
  String get instLicenseTitle => 'WinPlus licence';

  @override
  String instLicenseTrial(Object days, Object seats) {
    return 'Free trial ($days days, $seats seats)';
  }

  @override
  String get instLicenseTrialError => 'Trial unavailable.';

  @override
  String get instLicenseUnavailable => 'Licence unavailable.';

  @override
  String get instLicenseUpdateError => 'Could not save the change.';

  @override
  String get instLicenseWait => 'Please wait…';

  @override
  String get instMySchool => 'My school';

  @override
  String get instPlanActionsDone => 'actions completed';

  @override
  String get instPlanDone => 'Done';

  @override
  String get instPlanEmpty =>
      'WinAI has not suggested any actions for this week.';

  @override
  String get instPlanForbidden =>
      'Your account does not have access to the school\'s action plan.';

  @override
  String instPlanImpact(Object impact) {
    return 'Expected impact: $impact';
  }

  @override
  String get instPlanMarkDone => 'Mark as done';

  @override
  String instPlanPriority(Object n) {
    return 'Priority $n';
  }

  @override
  String instPlanSummaryActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'priority actions',
      one: 'priority action',
      zero: 'priority actions',
    );
    return ', and recommends $count $_temp0.';
  }

  @override
  String instPlanSummaryAtRisk(Object n) {
    return ', $n of them in the critical zone';
  }

  @override
  String instPlanSummaryStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'students',
      one: 'student',
      zero: 'students',
    );
    return 'WinAI analysed $count $_temp0';
  }

  @override
  String get instPlanTitle => 'WinAI action plan';

  @override
  String get instPlanUnavailable =>
      'The WinAI action plan is unavailable for now.';

  @override
  String get instReportAtRiskSub => 'Students needing intervention';

  @override
  String get instReportAtRiskTitle => 'Students at risk report';

  @override
  String get instReportGeneratePdf => 'Generate PDF';

  @override
  String get instReportGenerated => 'Report generated!';

  @override
  String get instReportGenerating => 'Generating...';

  @override
  String get instReportGlobalSub => 'Overview of all students';

  @override
  String get instReportGlobalTitle => 'Overall performance report';

  @override
  String get instReportGroupSub => 'Comparison of classes, pass rates';

  @override
  String get instReportGroupTitle => 'Report by class';

  @override
  String get instReportIndividualSub => 'Detailed progress of one student';

  @override
  String get instReportIndividualTitle => 'Individual student report';

  @override
  String instReportReady(Object title) {
    return 'Your report \"$title\" is ready.';
  }

  @override
  String get instReportWait => 'Please wait...';

  @override
  String get instReportsTitle => 'Reports';

  @override
  String get instRiskActionPlan => 'Action plan';

  @override
  String get instRiskContact => 'Contact';

  @override
  String get instRiskCritical => 'Critical';

  @override
  String instRiskCriticalCount(Object n) {
    return '$n critical';
  }

  @override
  String get instRiskEmpty => 'No students in this category.';

  @override
  String instRiskInactiveFor(Object n) {
    return 'Inactive for ${n}d';
  }

  @override
  String get instRiskModerate => 'Moderate';

  @override
  String instRiskScore(Object n) {
    return 'Score: $n%';
  }

  @override
  String get instRiskTitle => 'Students at risk';

  @override
  String get instRiskWeakSubject => 'Weak subject ';

  @override
  String instStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'students',
      one: 'student',
      zero: 'students',
    );
    return '$count $_temp0';
  }

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageHint =>
      'The language of the app, e-mails and notifications.';

  @override
  String get legalCgu1Body =>
      'These Terms of Use govern access to and use of the WinPlus platform, an educational mobile application for students, parents and teachers in the Cameroonian school system.';

  @override
  String get legalCgu1Title => '1. Purpose';

  @override
  String get legalCgu2Body =>
      'WinPlus is open to anyone with a compatible device and an internet connection. Some features require creating an account. Registration is free for the basic plan.';

  @override
  String get legalCgu2Title => '2. Access to the platform';

  @override
  String get legalCgu3Body =>
      'You are responsible for keeping your login details confidential. Any activity carried out from your account is attributed to you. If your account is compromised, contact us immediately at support@winplus.cm.';

  @override
  String get legalCgu3Title => '3. User accounts';

  @override
  String get legalCgu4Body =>
      'The content published on WinPlus (papers, corrections, quizzes) is protected by copyright. Reproducing, redistributing or reselling it without permission is strictly prohibited.';

  @override
  String get legalCgu4Title => '4. Content and intellectual property';

  @override
  String get legalCgu5Body =>
      'Paid plans (Starter, Expert, Institution) are billed monthly via Mobile Money (MTN MoMo, Orange Money) or bank card. Prices are shown in CFA francs (XAF) and may change with 30 days\' notice.';

  @override
  String get legalCgu5Title => '5. Subscriptions and payments';

  @override
  String get legalCgu6Body =>
      'You can cancel your subscription at any time from your profile. Cancellation takes effect at the end of the current billing period. No partial refund is granted.';

  @override
  String get legalCgu6Title => '6. Cancellation';

  @override
  String get legalCgu7Body =>
      'WinPlus strives to keep the platform available 24/7, but cannot be held liable for service interruptions, data loss or inaccuracies in the content.';

  @override
  String get legalCgu7Title => '7. Liability';

  @override
  String get legalCgu8Body =>
      'These Terms of Use are governed by Cameroonian law. Any dispute will be brought before the competent courts of Yaoundé, Cameroon.';

  @override
  String get legalCgu8Title => '8. Governing law';

  @override
  String get legalCguTitle => 'Terms of Use';

  @override
  String get legalContactBody =>
      'For any question: support@winplus.cm\nWinPlus SAS, Yaoundé, Cameroon';

  @override
  String get legalContactTitle => 'Contact';

  @override
  String get legalLastUpdated => 'Last updated: 1 June 2025';

  @override
  String get legalPriv1Body =>
      'WinPlus collects the following data:\n• Identification data: last name, first name, email address\n• Browsing data: content viewed, quiz results\n• Payment data: sent directly to our providers (MTN, Orange)\n• Device data: model, operating system, advertising identifier';

  @override
  String get legalPriv1Title => '1. Data collected';

  @override
  String get legalPriv2Body =>
      'Your data is used to:\n• Provide and personalise the WinPlus services\n• Generate learning recommendations through WinAI\n• Process your payments and manage your subscription\n• Improve the platform through aggregated, anonymised analyses';

  @override
  String get legalPriv2Title => '2. Purposes of processing';

  @override
  String get legalPriv3Body =>
      'Processing is based on your consent (art. 4 of Cameroon law no. 2010/012 on electronic communications) and on the performance of the service contract formed by these Terms of Use.';

  @override
  String get legalPriv3Title => '3. Legal basis';

  @override
  String get legalPriv4Body =>
      'Your data is kept for the duration of your contractual relationship with WinPlus, plus 3 years for evidential purposes. Browsing data is anonymised after 13 months.';

  @override
  String get legalPriv4Title => '4. Data retention';

  @override
  String get legalPriv5Body =>
      'WinPlus does not sell your data. It may be shared with:\n• Our hosting providers (secure servers in Europe)\n• Our payment providers (MTN, Orange, Stripe)\n• The competent authorities where required by law';

  @override
  String get legalPriv5Title => '5. Data sharing';

  @override
  String get legalPriv6Body =>
      'In accordance with the applicable legislation, you have the rights of access, rectification, erasure, portability and objection. Exercise them by writing to privacy@winplus.cm.';

  @override
  String get legalPriv6Title => '6. Your rights';

  @override
  String get legalPriv7Body =>
      'The app uses anonymous identifiers to measure performance and improve the user experience. You can turn them off in your device settings.';

  @override
  String get legalPriv7Title => '7. Cookies and trackers';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get login => 'Log in';

  @override
  String get loginSubtitle => 'Log in to your WinPlus account.';

  @override
  String get loginTitle => 'Welcome back!';

  @override
  String msgDaysAgo(Object n) {
    return '${n}d ago';
  }

  @override
  String get msgEmpty => 'No conversations.';

  @override
  String get msgEmptyHint => 'Contact a teacher from a student\'s profile.';

  @override
  String get msgHint => 'Your message…';

  @override
  String msgHoursAgo(Object n) {
    return '${n}h ago';
  }

  @override
  String msgMinutesAgo(Object n) {
    return '$n min ago';
  }

  @override
  String get msgNow => 'now';

  @override
  String get msgRoleUser => 'User';

  @override
  String get msgStartConversation => 'Start the conversation.';

  @override
  String get msgTitle => 'Messages';

  @override
  String get noAccountYet => 'Don\'t have an account yet? ';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get parentAddChildEmailLabel => 'Child\'s email *';

  @override
  String get parentAddChildIntro =>
      'Enter the email address of your child\'s WinPlus account to link it to your parent space.';

  @override
  String get parentAddChildInvalidEmail => 'Please enter a valid email.';

  @override
  String get parentAddChildLink => 'Link the child';

  @override
  String get parentAddChildNoCatalog =>
      'Your plan does not open the catalogue to your children.';

  @override
  String get parentAddChildNotFound =>
      'No student found with this email, or already linked.';

  @override
  String parentAddChildPlanLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'children',
      one: 'child',
      zero: 'children',
    );
    return 'Your plan follows $count $_temp0, without the catalogue for them. A parent plan opens the catalogue and WinAI alerts.';
  }

  @override
  String get parentAddChildSuccess =>
      'Child successfully added to your account.';

  @override
  String get parentAddChildTitle => 'Add a child';

  @override
  String get parentAiHint => 'Ask your question about schooling…';

  @override
  String get parentAiSuggestion1 => 'My child is struggling';

  @override
  String get parentAiSuggestion2 => 'Home revision plan';

  @override
  String get parentAiSuggestion3 => 'Analyse their results';

  @override
  String get parentAiSuggestion4 => 'How can I motivate them?';

  @override
  String get parentAiTagline => 'Your warm family advisor';

  @override
  String get parentAlbumGoals => 'Goals for the year';

  @override
  String get parentAlbumIntensity => 'Busiest moments';

  @override
  String parentAlbumMeta(Object year, Object date) {
    return 'School year $year · updated on $date';
  }

  @override
  String parentAlbumNotGenerated(Object name) {
    return '$name\'s album has not been generated yet this year.';
  }

  @override
  String get parentAlbumProgress => 'Progress observed';

  @override
  String get parentAlbumReportCard => 'Report card';

  @override
  String get parentAlbumSubjects => 'Subjects studied';

  @override
  String parentAlbumTitle(Object name) {
    return '$name\'s year album';
  }

  @override
  String get parentAlbumTopContents => 'Most viewed content';

  @override
  String get parentAlertBadgeHigh => 'Alert';

  @override
  String get parentAlertBadgeInfo => 'Info';

  @override
  String get parentAlertBadgeMedium => 'Warning';

  @override
  String get parentAlertsAllGood => 'All is well for your children!';

  @override
  String get parentAlertsIntro =>
      'WinAI monitors your children\'s progress and alerts you in real time.';

  @override
  String get parentAlertsNone => 'No active alerts.';

  @override
  String get parentAlertsRecent => 'Recent alerts';

  @override
  String get parentAlertsSeeActivity => 'See activity';

  @override
  String get parentAlertsTip1Text =>
      'Encourage short, regular sessions rather than long, irregular ones. Retention is much better.';

  @override
  String get parentAlertsTip1Title => 'Short, regular sessions';

  @override
  String get parentAlertsTip2Text =>
      'Daily quizzes improve retention by 40% compared with passive reading.';

  @override
  String get parentAlertsTip2Title => 'Daily quizzes';

  @override
  String get parentAlertsTip3Text =>
      'Set a precise exam goal with your child, a concrete date and exam, to motivate them effectively.';

  @override
  String get parentAlertsTip3Title => 'A clear goal';

  @override
  String get parentAlertsTipsTitle => 'WinAI advice';

  @override
  String get parentBuyBalance => 'Available balance';

  @override
  String get parentBuyContentForChild => 'Buy content for a child';

  @override
  String parentBuyFor(Object name) {
    return 'Buy for $name';
  }

  @override
  String get parentBuyNoContent => 'No content available for now.';

  @override
  String get parentBuyNoSubscription =>
      'No active paid subscription: subscribe to get credits to spend on your children.';

  @override
  String parentBuyRecommended(Object name, Object level) {
    return 'Recommended content for $name$level';
  }

  @override
  String get parentBuyTitle => 'Buy for…';

  @override
  String get parentBuyWhichChild => 'For which child?';

  @override
  String get parentChildActivityWeek => 'Activity this week';

  @override
  String get parentChildAiWeek => 'AI/wk';

  @override
  String get parentChildAllGood => 'All is well!';

  @override
  String get parentChildAvgScore30 => 'Average score over 30 days';

  @override
  String get parentChildAvgScoreShort => 'Avg. score';

  @override
  String get parentChildBestSubject => 'Best subject';

  @override
  String parentChildCatalogFiltered(Object name) {
    return 'Catalogue filtered for $name';
  }

  @override
  String get parentChildDownloadsWeek => 'Papers/wk';

  @override
  String get parentChildEncourage => 'Encourage';

  @override
  String get parentChildGenerateQuiz => 'Generate a quiz';

  @override
  String get parentChildInactive => 'Inactive';

  @override
  String get parentChildLastQuiz => 'Last quiz';

  @override
  String get parentChildNoRecentActivity => 'No recent activity.';

  @override
  String get parentChildNoResults => 'No results yet this month.';

  @override
  String get parentChildQuizGenerating => 'Quiz being generated...';

  @override
  String get parentChildQuizWeek => 'Quizzes/wk';

  @override
  String get parentChildRecentActivity => 'Recent activity';

  @override
  String parentChildRegular(Object name) {
    return '$name is revising regularly.';
  }

  @override
  String get parentChildScoreBySubject => 'Average score by subject (30 days)';

  @override
  String get parentChildSeeResources => 'See resources';

  @override
  String get parentChildTabActivity => 'Activity';

  @override
  String get parentChildTabAlbum => 'Album';

  @override
  String get parentChildTabExamWatch => 'Exam watch';

  @override
  String get parentChildTabGoals => 'Goals';

  @override
  String get parentChildTabPortrait => 'Portrait';

  @override
  String get parentChildToWorkOn => 'To work on';

  @override
  String parentChildrenLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'children',
      one: 'child',
      zero: 'children',
    );
    return '$count $_temp0 max with your plan';
  }

  @override
  String get parentCoveredAll =>
      'Your plan covers all your linked children: there is nothing to choose.';

  @override
  String get parentCoveredBadge => 'Covered';

  @override
  String get parentCoveredCustom => 'Choice saved';

  @override
  String get parentCoveredDefault =>
      'By default, the children linked first are covered';

  @override
  String get parentCoveredLoadError => 'The information could not be loaded.';

  @override
  String get parentCoveredMore => 'Cover more children';

  @override
  String parentCoveredNextChange(Object date) {
    return 'next change possible on $date';
  }

  @override
  String get parentCoveredOnePerPeriod => 'one change per subscription period';

  @override
  String get parentCoveredSave => 'Save the choice';

  @override
  String get parentCoveredSaved =>
      'Your choice has been saved: it applies straight away.';

  @override
  String parentCoveredSubMany(Object max, Object total) {
    return 'Your plan covers $max children out of $total linked: catalogue, WinAI bonus and alerts.';
  }

  @override
  String parentCoveredSubOne(Object max, Object total) {
    return 'Your plan covers $max child out of $total linked: catalogue, WinAI bonus and alerts.';
  }

  @override
  String get parentCoveredTitle => 'Children covered';

  @override
  String parentCoveredUpTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'children',
      one: 'child',
      zero: 'children',
    );
    return 'Your plan covers up to $count $_temp0 and all your linked children are covered.';
  }

  @override
  String get parentDashAlertsAdvice => 'WinAI alerts & advice';

  @override
  String get parentDashBalance => 'Balance';

  @override
  String get parentDashChildrenFollowed => 'children followed';

  @override
  String get parentDashCreditsAvail => 'credits available';

  @override
  String parentDashCreditsDetail(Object allocation, Object topups) {
    return 'Including $allocation XAF of plan allowance and $topups XAF of top-ups';
  }

  @override
  String get parentDashCreditsTitle => 'Credits available';

  @override
  String get parentDashLoadingBalance => 'Loading balance…';

  @override
  String get parentDashNoChild =>
      'No children followed. Add a child from the Children tab.';

  @override
  String get parentDashNoCredits =>
      'No credits: credits are granted with an active parent subscription.';

  @override
  String parentDashPeriodEndIn(Object plan, Object days) {
    return '$plan plan · End of period in $days days';
  }

  @override
  String parentDashRenewalEvent(Object plan) {
    return 'End of period · $plan plan';
  }

  @override
  String get parentDashSeeSubscription => 'See subscription';

  @override
  String get parentDashUpcomingEvents => 'Upcoming events';

  @override
  String parentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
      zero: 'days',
    );
    return '$count $_temp0 ago';
  }

  @override
  String get parentEncourageChooseTemplate => 'Choose a template';

  @override
  String get parentEncourageHint => 'Your message...';

  @override
  String get parentEncourageOrWrite => 'Or write a personal message';

  @override
  String get parentEncourageSendError =>
      'The message could not be sent. Please try again.';

  @override
  String parentEncourageSent(Object name) {
    return 'Message sent to $name!';
  }

  @override
  String get parentEncourageSub => 'Choose a message or write your own';

  @override
  String parentEncourageTitle(Object name) {
    return 'Encourage $name';
  }

  @override
  String parentEncourageTpl1(Object name) {
    return 'Keep it up $name, I\'m proud of you!';
  }

  @override
  String parentEncourageTpl2(Object name) {
    return 'Don\'t forget to revise Chemistry tonight $name!';
  }

  @override
  String parentEncourageTpl3(Object name) {
    return '$name, you can do it, the BAC is coming!';
  }

  @override
  String parentEncourageTpl4(Object name, Object score) {
    return '$name, $score this week, that\'s excellent!';
  }

  @override
  String get parentEncourageYourScore => 'your score';

  @override
  String parentEventInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
      zero: 'days',
    );
    return 'in $count $_temp0';
  }

  @override
  String get parentEventToday => 'today';

  @override
  String get parentGoalActiveTitle => 'Active shared goals';

  @override
  String parentGoalDeadlineOn(Object date) {
    return 'Deadline: $date';
  }

  @override
  String get parentGoalFieldDescription => 'Description (optional)';

  @override
  String get parentGoalIntro =>
      'Your proposal is waiting for your child\'s agreement: they can accept it as it is, adjust it, or decline it.';

  @override
  String get parentGoalNoActive => 'No active shared goals for now.';

  @override
  String get parentGoalNoPending => 'No proposals awaiting a reply.';

  @override
  String get parentGoalPendingTitle => 'Pending proposals';

  @override
  String parentGoalProposeTo(Object name) {
    return 'Propose a goal to $name';
  }

  @override
  String get parentGoalSent => 'Proposal sent.';

  @override
  String get parentGoalSubmit => 'Propose the goal';

  @override
  String get parentGoalSubmitError =>
      'The proposal could not be sent. Please try again.';

  @override
  String get parentGoalTypeAcademic => 'School';

  @override
  String get parentGoalTypePersonal => 'Personal';

  @override
  String get parentGoalTypeSkill => 'Skill';

  @override
  String get parentNoSubscription => 'No subscription';

  @override
  String get parentPayStatusFailed => 'failed';

  @override
  String get parentPayStatusPending => 'pending';

  @override
  String get parentPayStatusRefundRequested => 'refund requested';

  @override
  String get parentPayStatusRefunded => 'refunded';

  @override
  String get parentPaymentsEmpty =>
      'No payments yet. Your purchases, subscriptions and top-ups will appear here.';

  @override
  String get parentPaymentsLoadError => 'The history could not be loaded.';

  @override
  String get parentPaymentsMonthSpent => 'SPENDING THIS MONTH';

  @override
  String get parentPaymentsTitle => 'Payments';

  @override
  String parentPlanName(Object plan) {
    return '$plan plan';
  }

  @override
  String get parentPortfolioAutonomy => 'Independence';

  @override
  String get parentPortfolioCuriosity => 'Curiosity';

  @override
  String parentPortfolioNoAutonomy(Object name) {
    return 'No independence data for $name yet.';
  }

  @override
  String parentPortfolioNoCuriosity(Object name) {
    return 'No curiosity data for $name yet.';
  }

  @override
  String parentPortfolioNoRegularity(Object name) {
    return 'No consistency data for $name yet.';
  }

  @override
  String parentPortfolioNotYet(Object name) {
    return '$name\'s portrait will be available after the first monthly calculation.';
  }

  @override
  String get parentPortfolioRegularity => 'Consistency';

  @override
  String parentPortfolioTitle(Object name) {
    return '$name\'s portrait';
  }

  @override
  String parentPortfolioUpdatedOn(Object date) {
    return 'Last updated on $date';
  }

  @override
  String get parentProfileCovered => 'Children covered by my plan';

  @override
  String get parentProfileCredits => 'Credits';

  @override
  String get parentProfileManageSub => 'Manage subscription';

  @override
  String get parentProfileMyAccount => 'My account';

  @override
  String get parentProfilePayments => 'Payments & history';

  @override
  String get parentProfileTutoring => 'Private lessons for my children';

  @override
  String get parentResourcesIntro =>
      'Based on your children\'s results, these resources will target their weak points.';

  @override
  String get parentResourcesRecommended => 'Recommended by WinAI';

  @override
  String get parentSubAiFree => 'WinAI usage of the free plan';

  @override
  String parentSubAiMultiplier(Object n) {
    return '${n}x more WinAI usage than the free plan';
  }

  @override
  String get parentSubAutoRenewOn => 'Automatic renewal turned on';

  @override
  String get parentSubBackToFree => 'You will go back to the free plan.';

  @override
  String get parentSubCancel => 'Cancel subscription';

  @override
  String get parentSubCancelChange => 'Cancel this change';

  @override
  String get parentSubCancelConfirmTitle => 'Cancel subscription?';

  @override
  String parentSubCancelledUntil(Object date) {
    return 'Cancelled: access until $date';
  }

  @override
  String get parentSubChangePlan => 'Change plan';

  @override
  String get parentSubChildrenFollowed => 'Children followed';

  @override
  String get parentSubDisableAutoRenew => 'Turn off automatic renewal';

  @override
  String get parentSubEnableAutoRenew => 'Renew automatically from my balance';

  @override
  String get parentSubFailed => 'Failed';

  @override
  String get parentSubIncludes => 'What your plan includes';

  @override
  String parentSubKeepAccessUntil(Object date) {
    return 'You keep access until $date, with no refund for the current period.';
  }

  @override
  String get parentSubLimitReached => 'Limit reached';

  @override
  String get parentSubLoadError => 'The subscription could not be loaded.';

  @override
  String get parentSubManualRenew => 'Manual renewal';

  @override
  String get parentSubMyChildren => 'My children';

  @override
  String get parentSubNoPayment => 'No payments recorded yet.';

  @override
  String get parentSubPaid => 'Paid';

  @override
  String get parentSubPaymentHistory => 'Payment history';

  @override
  String get parentSubPaymentPending => 'Payment pending';

  @override
  String parentSubPendingSwitch(Object plan) {
    return 'Switch to $plan scheduled for the renewal date.';
  }

  @override
  String parentSubPeriodUntil(Object date) {
    return 'Current period until $date';
  }

  @override
  String get parentSubRenewNow => 'Renew now';

  @override
  String get parentSubResume => 'Resume subscription';

  @override
  String get parentSubTitle => 'My subscription';

  @override
  String get parentSubTrial => 'Trial';

  @override
  String get parentWatchActivate => 'Turn on exam watch';

  @override
  String get parentWatchActivateError =>
      'Exam watch could not be turned on right now.';

  @override
  String get parentWatchBeforeExam => 'before the exam';

  @override
  String parentWatchCountdown(Object n) {
    return 'D-$n';
  }

  @override
  String get parentWatchDeactivate => 'Turn off exam watch';

  @override
  String get parentWatchDeactivateError =>
      'Exam watch could not be turned off right now.';

  @override
  String get parentWatchExamDate => 'Exam date';

  @override
  String parentWatchExamOn(Object date) {
    return 'Exam on $date';
  }

  @override
  String get parentWatchExamType => 'Exam type';

  @override
  String get parentWatchExamTypeHint => 'E.g. BEPC, BAC série C…';

  @override
  String get parentWatchFormRequired => 'Choose an exam type and a date.';

  @override
  String get parentWatchIntro =>
      'Closer follow-up during the exam period: WinAI adapts its advice and suggests relevant questions in the family assistant.';

  @override
  String get parentWatchSubmitError =>
      'Exam watch could not be turned on. Please try again.';

  @override
  String get parentWatchTitle => 'Exam watch';

  @override
  String get password => 'Password';

  @override
  String get roleInstitution => 'School';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleTutor => 'Tutor';

  @override
  String get shellTabAccount => 'Account';

  @override
  String get shellTabAnalytics => 'Analytics';

  @override
  String get shellTabCatalog => 'Catalog';

  @override
  String get shellTabChildren => 'Children';

  @override
  String get shellTabContent => 'Content';

  @override
  String get shellTabEarnings => 'Earnings';

  @override
  String get shellTabGroups => 'Groups';

  @override
  String get shellTabHome => 'Home';

  @override
  String get shellTabMe => 'Me';

  @override
  String get shellTabMessages => 'Messages';

  @override
  String get shellTabMySpace => 'My space';

  @override
  String get shellTabProfile => 'Profile';

  @override
  String get shellTabResources => 'Resources';

  @override
  String get shellTabSessions => 'Sessions';

  @override
  String get shellTabStudents => 'Students';

  @override
  String get shopAccountRequiredBody =>
      'Log in or create an account before paying: the content you buy is linked to your account and stays available on all your devices.';

  @override
  String get shopAccountRequiredTitle => 'An account is required to buy';

  @override
  String get shopAmount => 'Amount';

  @override
  String get shopApply => 'Apply';

  @override
  String get shopAwaitingConfirmation => 'Awaiting confirmation…';

  @override
  String get shopBackToCatalog => 'Back to the catalogue';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopBuyFromAccountBody =>
      'In-app payment is coming soon. In the meantime, buy this content from your account on winplus.cm with the same login details: it will then be available here.';

  @override
  String get shopBuyFromAccountTitle => 'Buy from your account';

  @override
  String get shopCartEmpty => 'Your cart is empty.';

  @override
  String get shopCartLoadFailed => 'Unable to load the cart.';

  @override
  String get shopCartRemoveFailed => 'Unable to remove this item.';

  @override
  String get shopCartTitle => 'My cart';

  @override
  String get shopCheckNow => 'Check now';

  @override
  String get shopCheckoutStepConfirm => 'Confirmation';

  @override
  String get shopCheckoutStepSummary => 'Summary & payment';

  @override
  String get shopContentAvailable => 'Your content is now available.';

  @override
  String get shopExploreCatalog => 'Explore the catalogue';

  @override
  String get shopInvalidPhone => 'Invalid phone number.';

  @override
  String get shopInvoiceLoadFailed => 'Unable to load the invoice.';

  @override
  String shopInvoiceTitle(Object number) {
    return 'Invoice $number';
  }

  @override
  String get shopItems => 'Items';

  @override
  String shopItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }

  @override
  String get shopMyOrders => 'My orders';

  @override
  String get shopNoOrders => 'No orders yet.';

  @override
  String get shopOrder => 'Order';

  @override
  String get shopOrderCancelled => 'Cancelled';

  @override
  String get shopOrderFailed => 'Failed';

  @override
  String get shopOrderPaid => 'Paid';

  @override
  String get shopOrderRefundRequested => 'Refund requested';

  @override
  String get shopOrderRefunded => 'Refunded';

  @override
  String shopPayAmount(Object amount) {
    return 'Pay $amount XAF';
  }

  @override
  String get shopPaymentConfirmed => 'Payment confirmed!';

  @override
  String get shopPaymentFailed => 'Payment failed';

  @override
  String get shopPaymentMethod => 'Payment method';

  @override
  String get shopPaymentNotConfirmed => 'The payment could not be confirmed.';

  @override
  String get shopPhoneNumber => 'Phone number';

  @override
  String get shopPlaceOrder => 'Place the order';

  @override
  String shopPromoApplied(Object amount) {
    return 'Discount applied: -$amount XAF';
  }

  @override
  String get shopPromoCode => 'Promo code';

  @override
  String shopReference(Object ref) {
    return 'Ref.: $ref';
  }

  @override
  String get shopRefundFailed => 'Unable to send the request.';

  @override
  String get shopRefundSent => 'Refund request sent.';

  @override
  String get shopRequestRefund => 'Request a refund';

  @override
  String get shopSeeMyOrders => 'See my orders';

  @override
  String get shopSlowPayment =>
      'The payment is taking longer than expected. You can check later in \"My orders\".';

  @override
  String get shopStillPending => 'Still pending';

  @override
  String shopSubjectFallback(Object id) {
    return 'Paper #$id';
  }

  @override
  String get shopSubtotal => 'Subtotal';

  @override
  String get shopTotal => 'Total';

  @override
  String get shopTotalTtc => 'Total incl. VAT';

  @override
  String get shopUnexpectedError => 'Unexpected error. Please try again.';

  @override
  String get shopUssdNotice =>
      'You will receive a USSD notification to confirm.';

  @override
  String get shopValidateUssd =>
      'Confirm the payment with the USSD message sent to your phone.';

  @override
  String get shopVatIncluded => 'of which VAT 19.25% included';

  @override
  String get shopViewInvoice => 'View the invoice';

  @override
  String studentAchBadgesUnlocked(Object unlocked, Object total) {
    return '$unlocked / $total badges unlocked';
  }

  @override
  String get studentAchCurrentStreak => 'Current streak';

  @override
  String get studentAchLocked => 'Locked';

  @override
  String get studentAchMyBadges => 'My badges';

  @override
  String studentAchStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consecutive days',
      one: '$count consecutive day',
    );
    return '$_temp0';
  }

  @override
  String get studentAchStreakLoadError =>
      'Couldn\'t load your real streak. The streak below may not be up to date.';

  @override
  String get studentAchTitle => 'Achievements';

  @override
  String get studentAchUnlocked => 'Unlocked';

  @override
  String get studentCatalogAccess => 'Access';

  @override
  String get studentCatalogAllAccess => 'All';

  @override
  String get studentCatalogApply => 'Apply';

  @override
  String get studentCatalogCatSciences => 'Sciences';

  @override
  String get studentCatalogEmpty => 'No courses found.';

  @override
  String get studentCatalogFilters => 'Filters';

  @override
  String get studentCatalogLevelAdvanced => 'advanced';

  @override
  String get studentCatalogLevelBeginner => 'beginner';

  @override
  String get studentCatalogLevelIntermediate => 'intermediate';

  @override
  String get studentCatalogLoadMore => 'Load more';

  @override
  String get studentCatalogPaid => 'Paid';

  @override
  String studentCatalogPriceTtc(Object amount) {
    return '$amount XAF incl. VAT';
  }

  @override
  String get studentCatalogReset => 'Reset';

  @override
  String get studentCatalogSearchHint => 'Search for a course…';

  @override
  String get studentCertCourses => 'Courses';

  @override
  String get studentCertDownloadPdf => 'Download PDF';

  @override
  String get studentCertEmpty => 'No certificates yet';

  @override
  String get studentCertEmptyHint =>
      'Complete quizzes and learning paths\nto earn your first certificates.';

  @override
  String studentCertIssuedOn(Object date) {
    return 'Issued on $date';
  }

  @override
  String get studentCertLoadError => 'Couldn\'t load the certificates.';

  @override
  String get studentCertMentionGood => 'Grade: Good';

  @override
  String get studentCertMentionVeryGood => 'Grade: Very good';

  @override
  String get studentCertPapersAndPaths => 'Papers and learning paths';

  @override
  String get studentCertPdfLoadError => 'The certificate couldn\'t be loaded.';

  @override
  String get studentCertSeePdf => 'See the certificate (PDF)';

  @override
  String get studentCertShare => 'Share';

  @override
  String get studentCertTitle => 'My Certificates';

  @override
  String studentCertVerificationCode(Object code) {
    return 'Verification code: $code';
  }

  @override
  String studentCoachCompletion(Object pct) {
    return '$pct% of the plan completed';
  }

  @override
  String studentCoachDaysLeft(Object days) {
    return '$days d left';
  }

  @override
  String get studentCoachDeleteBody => 'This action cannot be undone.';

  @override
  String get studentCoachDeletePlan => 'Delete the plan';

  @override
  String get studentCoachDeleteTitle => 'Delete this plan?';

  @override
  String get studentCoachExamDate => 'Exam date';

  @override
  String get studentCoachGenerate => 'Generate my plan with WinAI';

  @override
  String get studentCoachGenerateError =>
      'Couldn\'t generate the plan. Try again in a moment.';

  @override
  String get studentCoachGenerating => 'Generating…';

  @override
  String get studentCoachHoursPerDay => 'Study hours per day';

  @override
  String get studentCoachIntro =>
      'WinAI builds a day-by-day schedule suited to your exam date and your pace.';

  @override
  String get studentCoachLoadError =>
      'Couldn\'t load your plan. Check your connection.';

  @override
  String get studentCoachLocked =>
      'Available from the Standard plan.\nWinAI builds a schedule suited to your gaps.';

  @override
  String get studentCoachMarkToday => 'Mark today\'s session as done';

  @override
  String get studentCoachNoWeek => 'Schedule unavailable for this week.';

  @override
  String get studentCoachPickDate => 'Pick a date';

  @override
  String studentCoachReliability(Object value) {
    return 'Plan reliability: $value%';
  }

  @override
  String get studentCoachRest => 'Rest';

  @override
  String get studentCoachSeePlans => 'See the plans';

  @override
  String get studentCoachTargetExam => 'Target exam';

  @override
  String get studentCoachThisWeek => 'This week';

  @override
  String studentCoachTodayDay(Object day) {
    return 'Today · Day $day';
  }

  @override
  String get studentCoachTodayDone => 'Today\'s session completed';

  @override
  String get studentCourseBuy => 'Buy this course';

  @override
  String studentCourseBuyNote(Object amount) {
    return '$amount XAF incl. VAT (19.25% VAT included). Course sold on its own, lifetime access once the payment is confirmed.';
  }

  @override
  String get studentCourseCertIncluded => 'Certificate of completion included';

  @override
  String get studentCourseContent => 'Content';

  @override
  String get studentCourseContinue => 'Continue the course';

  @override
  String studentCourseCurriculumSummary(
      Object sections, Object lessons, Object duration) {
    return '$sections sections · $lessons lessons · $duration';
  }

  @override
  String get studentCourseEnrolError => 'Enrolment failed.';

  @override
  String studentCourseEnrolled(Object n) {
    return '$n enrolled';
  }

  @override
  String get studentCourseError => 'Error';

  @override
  String get studentCourseLeaveReview => 'Leave a review';

  @override
  String studentCourseLessons(Object n) {
    return '$n lessons';
  }

  @override
  String get studentCourseNoChild => 'No child is linked to your account.';

  @override
  String get studentCourseNoReviews => 'No reviews yet.';

  @override
  String get studentCourseNotFound => 'Course not found.';

  @override
  String get studentCourseObjectives => 'What you will learn';

  @override
  String get studentCourseOfferChild => 'Give to my child';

  @override
  String studentCourseOfferTitle(Object title, Object amount) {
    return 'Give “$title” ($amount XAF incl. VAT, charged to the wallet)';
  }

  @override
  String studentCourseOffered(Object name) {
    return 'Course given to $name: access granted.';
  }

  @override
  String get studentCoursePayBalance => 'Pay with my WinPlus balance';

  @override
  String get studentCoursePayMomo => 'Pay by Mobile Money';

  @override
  String get studentCoursePostReview => 'Post my review';

  @override
  String get studentCoursePreview => 'Preview';

  @override
  String get studentCoursePurchased =>
      'Course purchased: it is in “My courses”.';

  @override
  String get studentCoursePurchasedBadge => 'Purchased';

  @override
  String get studentCoursePurchasedStart => 'Purchased: start now';

  @override
  String get studentCourseRequirements => 'Requirements';

  @override
  String get studentCourseReviewHint => 'Share your experience (optional)…';

  @override
  String get studentCourseReviewSubmitError =>
      'Your review could not be submitted.';

  @override
  String get studentCourseReviewThanks => 'Thank you for your review!';

  @override
  String get studentCourseReviews => 'Reviews';

  @override
  String get studentCourseStartFree => 'Start for free';

  @override
  String get studentCourseVatNote =>
      'incl. VAT, 19.25% VAT included · not part of a subscription';

  @override
  String get studentCourseYours => 'Your course';

  @override
  String get studentDetailAddNote => 'Add a note';

  @override
  String get studentDetailAddNoteHint => 'Add a note…';

  @override
  String get studentDetailAddToCartError => 'Couldn\'t add to cart.';

  @override
  String studentDetailAddToCartPrice(Object price) {
    return 'Add to cart  $price XAF';
  }

  @override
  String get studentDetailAddedToCart => 'Added to cart.';

  @override
  String studentDetailBy(Object teacher) {
    return 'By $teacher';
  }

  @override
  String get studentDetailDefaultDescription => 'Quality educational content.';

  @override
  String get studentDetailDemoNoDocument =>
      'This demo content has no document to show.';

  @override
  String get studentDetailDemoNoSubject =>
      'This demo content has no real paper.';

  @override
  String get studentDetailMyNotes => 'My notes';

  @override
  String get studentDetailNoReviews => 'No reviews yet.';

  @override
  String get studentDetailOrSubscriptions => 'or explore the subscriptions';

  @override
  String studentDetailRatingCount(Object rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '$rating ($_temp0)';
  }

  @override
  String get studentDetailReadBook => 'Read the book';

  @override
  String get studentDetailReadInApp => 'Read in the app';

  @override
  String studentDetailReadPreview(Object pages) {
    return 'Read the preview ($pages pages)';
  }

  @override
  String studentDetailReviewsHeader(Object count) {
    return 'Reviews ($count)';
  }

  @override
  String get studentDetailSimilar => 'Similar content';

  @override
  String get studentDetailStartQuiz => 'Start the quiz';

  @override
  String get studentDetailTagHard => 'Hard';

  @override
  String get studentDetailTagMastered => 'Mastered';

  @override
  String get studentDetailTagToBuy => 'To buy';

  @override
  String get studentDetailTagToRevise => 'To revise';

  @override
  String get studentDetailVerified => 'Verified';

  @override
  String get studentDetailViewAnswers => 'View the answers';

  @override
  String get studentDetailViewCart => 'View cart';

  @override
  String studentDetailViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views',
      one: '$count view',
    );
    return '$_temp0';
  }

  @override
  String studentFavAddedOn(Object date) {
    return 'Added on $date';
  }

  @override
  String studentFavCount(Object count) {
    return '$count item(s) saved';
  }

  @override
  String get studentFavEmpty => 'No favourites yet';

  @override
  String get studentFavExplore => 'Explore the catalogue';

  @override
  String studentFavLimit(Object max) {
    return 'Your plan allows $max favourites. Upgrade to a higher plan to save more.';
  }

  @override
  String get studentFavLoadError => 'Unable to load your favourites.';

  @override
  String get studentFavTitle => 'My Favourites';

  @override
  String get studentGoalsAcceptError =>
      'This goal cannot be accepted right now.';

  @override
  String studentGoalsDeadlineOn(Object date) {
    return 'Deadline: $date';
  }

  @override
  String get studentGoalsFieldDeadline => 'Deadline';

  @override
  String get studentGoalsFieldTitle => 'Title';

  @override
  String get studentGoalsProposedBy => 'Suggested by one of your parents';

  @override
  String get studentGoalsRefuseConfirm => 'Decline for good?';

  @override
  String get studentGoalsRefuseError =>
      'This goal cannot be declined right now.';

  @override
  String get studentGoalsRequired => 'The title and the deadline are required.';

  @override
  String get studentGoalsSaveActivate => 'Save and activate';

  @override
  String get studentGoalsSaveError => 'Your changes cannot be saved right now.';

  @override
  String get studentGoalsTitle => 'Goals suggested by your parents';

  @override
  String studentGroupsAlreadyMember(Object name) {
    return 'You are already a member of “$name”.';
  }

  @override
  String get studentGroupsCodeIncomplete => 'Enter the full invitation code.';

  @override
  String get studentGroupsCodeNotFound => 'No group matches this code.';

  @override
  String get studentGroupsCreate => 'Create a group';

  @override
  String get studentGroupsCreateBtn => 'Create';

  @override
  String get studentGroupsCreateError => 'The group could not be created.';

  @override
  String get studentGroupsCreatePlus => '+ Create a group';

  @override
  String get studentGroupsCreating => 'Creating…';

  @override
  String get studentGroupsDetailLoadError => 'Couldn\'t load this group.';

  @override
  String get studentGroupsEmpty => 'No groups yet.';

  @override
  String get studentGroupsEmptyHint =>
      'Create a group or join a classmate\'s group with its code.';

  @override
  String get studentGroupsInviteCode => 'Invitation code';

  @override
  String get studentGroupsJoin => 'Join';

  @override
  String get studentGroupsJoinByCode => 'Join with a code';

  @override
  String studentGroupsJoined(Object name) {
    return 'You have joined “$name”!';
  }

  @override
  String get studentGroupsLeaderboard => 'Leaderboard (last 7 days)';

  @override
  String get studentGroupsLeaderboardUnavailable =>
      'Leaderboard unavailable right now.';

  @override
  String get studentGroupsLeave => 'Leave';

  @override
  String studentGroupsLeaveConfirm(Object name) {
    return 'Leave “$name”?';
  }

  @override
  String get studentGroupsLeaveError => 'You could not leave this group.';

  @override
  String studentGroupsLeaveOwner(Object name) {
    return 'Leave “$name”? The group will be archived for all its members.';
  }

  @override
  String get studentGroupsLeaveTitle => 'Leave this group?';

  @override
  String get studentGroupsLoadError => 'Your groups could not be loaded.';

  @override
  String get studentGroupsMember => 'Member';

  @override
  String studentGroupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get studentGroupsMembers => 'Members';

  @override
  String studentGroupsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get studentGroupsMine => 'My groups';

  @override
  String get studentGroupsNameHint => 'Group name (min 3 characters)';

  @override
  String get studentGroupsNameTooShort =>
      'The name must be at least 3 characters long.';

  @override
  String get studentGroupsNoActivity =>
      'Nobody has any activity yet this week.';

  @override
  String get studentGroupsOwner => 'Owner';

  @override
  String studentGroupsRankLine(Object quizzes, Object minutes) {
    return '$quizzes quizzes passed · $minutes min studied';
  }

  @override
  String get studentGroupsSending => 'Sending…';

  @override
  String get studentGroupsSubjectHint => 'Main subject (optional)';

  @override
  String get studentHistCatCourse => 'Course';

  @override
  String get studentHistCatDocument => 'Document';

  @override
  String get studentHistCatExercise => 'Exercise';

  @override
  String get studentHistCatPaper => 'Paper';

  @override
  String get studentHistCatSummary => 'Summary';

  @override
  String studentHistDaysAgo(Object n) {
    return '$n days ago';
  }

  @override
  String get studentHistEmpty => 'No documents viewed yet.';

  @override
  String get studentHistEmptyHint => 'Open papers from the catalogue.';

  @override
  String studentHistEmptyPeriod(Object period) {
    return 'No documents viewed over $period.';
  }

  @override
  String studentHistFileCount(int count, Object period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files · $period',
      one: '$count file · $period',
      zero: '$count file · $period',
    );
    return '$_temp0';
  }

  @override
  String get studentHistLoadError => 'Unable to load your history.';

  @override
  String get studentHistPeriod1y => '1 year';

  @override
  String get studentHistPeriod30d => '30d';

  @override
  String get studentHistPeriod7d => '7d';

  @override
  String get studentHistPeriod90d => '90d';

  @override
  String get studentHistTitle => 'Documents viewed';

  @override
  String get studentHomeAvgScore => 'average score';

  @override
  String get studentHomeBadges => 'Badges';

  @override
  String get studentHomeContinue => 'Pick up where you left off';

  @override
  String studentHomeDate(Object weekday, Object date) {
    return '$weekday, $date';
  }

  @override
  String get studentHomeDaysInARow => 'days in a row';

  @override
  String get studentHomeDaysLabel => 'days';

  @override
  String get studentHomeDownloads => 'My papers';

  @override
  String get studentHomeGoodAfternoon => 'Good afternoon';

  @override
  String get studentHomeGoodEvening => 'Good evening';

  @override
  String get studentHomeGoodMorning => 'Good morning';

  @override
  String get studentHomeInARow => ' in a row!';

  @override
  String get studentHomeOpenFailed =>
      'This content couldn\'t be opened. Try again later.';

  @override
  String get studentHomeQuizPerWeek => 'Quizzes / wk';

  @override
  String get studentHomeResume => 'Resume';

  @override
  String get studentHomeSee => 'View';

  @override
  String get studentHomeStreak => 'Streak';

  @override
  String studentHomeStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get studentHomeStudyPerWeek => 'Study / wk';

  @override
  String get studentHomeStudyThisWeek => 'of study this week';

  @override
  String get studentHomeTimeLogged => 'Time logged';

  @override
  String get studentHomeUpcomingExams => 'Upcoming exams';

  @override
  String get studentHomeUpgrade =>
      'With a subscription, the whole catalogue opens up and WinAI supports you more.';

  @override
  String get studentHubAccount => 'Account';

  @override
  String get studentHubBadgesSub => '14 unlocked';

  @override
  String get studentHubCertificates => 'My certificates';

  @override
  String get studentHubCertificatesSub => '2 signed';

  @override
  String get studentHubCommunity => 'Community';

  @override
  String get studentHubDefaultName => 'Student';

  @override
  String get studentHubFavorites => 'My favourites';

  @override
  String get studentHubFavoritesSub => 'Your saved content';

  @override
  String get studentHubForum => 'Community forum';

  @override
  String get studentHubForumSub => 'Questions & answers';

  @override
  String get studentHubGroups => 'My study groups';

  @override
  String get studentHubGroupsSub => '3 groups';

  @override
  String get studentHubHistory => 'Download history';

  @override
  String get studentHubLearning => 'Learning';

  @override
  String get studentHubLogoutBody =>
      'You\'ll be taken back to the welcome screen.';

  @override
  String get studentHubLogoutConfirm => 'Log out';

  @override
  String get studentHubLogoutTitle => 'Log out?';

  @override
  String get studentHubNetworkSub => 'Parents, teachers, school';

  @override
  String studentHubPlan(Object planName) {
    return 'Plan $planName';
  }

  @override
  String get studentHubPomodoroSub => '25 min focus · 5 min break';

  @override
  String get studentHubPrivacy => 'Privacy policy';

  @override
  String get studentHubProfileSettings => 'Profile settings';

  @override
  String get studentHubReports => 'My progress reports';

  @override
  String get studentHubRevisionQuiz => 'Revision quiz';

  @override
  String get studentHubRevisionQuizSub =>
      'Go back over the questions you missed';

  @override
  String get studentHubSoon => 'Coming soon!';

  @override
  String get studentHubSubscription => 'My subscription';

  @override
  String studentHubSubscriptionSub(Object planName) {
    return 'Plan $planName · Manage';
  }

  @override
  String get studentHubTerms => 'Terms of use';

  @override
  String get studentHubTutorPolicy => 'Tutoring policy';

  @override
  String get studentHubWinaiSub => 'Your learning assistant';

  @override
  String get studentLinksActionFailed =>
      'Couldn\'t complete the action, try again.';

  @override
  String get studentLinksAttachAccepted => 'link confirmed';

  @override
  String get studentLinksAttachPending => 'link awaiting your answer';

  @override
  String get studentLinksAttachRefused => 'link declined for private lessons';

  @override
  String studentLinksClass(Object group) {
    return 'Class $group';
  }

  @override
  String get studentLinksInvitations => 'Invitations received';

  @override
  String get studentLinksLoadError => 'Loading error';

  @override
  String get studentLinksParents => 'Parents';

  @override
  String get studentLinksRoleInstitution => 'school';

  @override
  String get studentLinksRoleParent => 'parent';

  @override
  String get studentLinksSchools => 'Schools';

  @override
  String get studentLinksSchoolsHint =>
      'By accepting, the school can book, pay for and assign private lessons for you. You can change your mind at any time.';

  @override
  String get studentLinksStudyGroups => 'Study groups';

  @override
  String studentLinksTeacherClass(Object className) {
    return 'Teacher · $className';
  }

  @override
  String get studentLinksTeacherPending => 'Teacher · invitation pending';

  @override
  String get studentLinksTeachers => 'Teachers';

  @override
  String get studentLinksTitle => 'My network';

  @override
  String get studentLinksWithdraw => 'Withdraw my consent';

  @override
  String get studentMyCoursesEmpty => 'No courses in progress';

  @override
  String get studentMyCoursesEmptyHint =>
      'Explore our catalogue and start learning today.';

  @override
  String get studentMyCoursesExplore => 'Explore courses';

  @override
  String get studentMyCoursesLoadError => 'Couldn\'t load your courses.';

  @override
  String get studentMyCoursesReplay => 'Watch again';

  @override
  String get studentMyCoursesStart => 'Start';

  @override
  String get studentMyCoursesTitle => 'My courses';

  @override
  String get studentNotifAllCaughtUp => 'You\'re all caught up!';

  @override
  String studentNotifHoursAgo(Object n) {
    return '${n}h ago';
  }

  @override
  String get studentNotifJustNow => 'Just now';

  @override
  String get studentNotifMarkFailed =>
      'Couldn\'t mark the notifications as read. Try again.';

  @override
  String studentNotifMinutesAgo(Object n) {
    return '$n min ago';
  }

  @override
  String get studentNotifReadAll => 'Mark all as read';

  @override
  String get studentNotifSeeMore => 'Show more';

  @override
  String get studentNotifTitle => 'Notifications';

  @override
  String get studentPlayerAttachedFile => 'Attached file';

  @override
  String get studentPlayerCertAvailable => 'Your certificate is available.';

  @override
  String get studentPlayerCertGenerating =>
      'Congratulations! Your certificate is being generated.';

  @override
  String get studentPlayerCourseDone => 'Course completed!';

  @override
  String get studentPlayerCurriculum => 'Curriculum';

  @override
  String get studentPlayerDone => 'Completed';

  @override
  String get studentPlayerDownloadFailed =>
      'Couldn\'t download. Try again later.';

  @override
  String get studentPlayerDownloadOffline => 'Download for offline';

  @override
  String get studentPlayerDownloaded =>
      'Lesson downloaded for offline viewing.';

  @override
  String get studentPlayerLessonDone => 'Lesson completed';

  @override
  String get studentPlayerMarkDone => 'Mark as completed';

  @override
  String get studentPlayerOfflinePlayback => 'Offline playback';

  @override
  String get studentPlayerOpenViewer => 'Open in the viewer (read online)';

  @override
  String get studentPlayerRemoveOffline => 'Remove offline copy';

  @override
  String get studentPlayerSelectLesson => 'Select a lesson.';

  @override
  String get studentPlayerTapToDownload => 'Tap to download';

  @override
  String get studentPlayerVideoUnavailable => 'Video unavailable right now.';

  @override
  String get studentProfile2fa => 'Two-factor authentication';

  @override
  String get studentProfile2faHint => 'An email code at each login.';

  @override
  String get studentProfileActiveSessions => 'Active sessions';

  @override
  String get studentProfileAnonStats => 'Anonymised statistics';

  @override
  String get studentProfileAnonStatsHint => 'Helps improve WinPlus.';

  @override
  String get studentProfileChange => 'Change';

  @override
  String get studentProfileChangePhoto => 'Change photo';

  @override
  String get studentProfileChangePwd => 'Change password';

  @override
  String get studentProfileCodeReceived => 'Code received by email';

  @override
  String studentProfileCodeSent(Object email) {
    return 'Code sent to $email. It expires after 15 minutes.';
  }

  @override
  String get studentProfileConfirmCode => 'Confirmation code';

  @override
  String get studentProfileCurrentPwd => 'Current password';

  @override
  String get studentProfileCurrentSession => 'Now · Current session';

  @override
  String get studentProfileDangerZone => 'Danger zone';

  @override
  String get studentProfileDeleteAccount => 'Delete my account';

  @override
  String get studentProfileDeleteBody =>
      'This action cannot be undone. All your data will be lost.';

  @override
  String get studentProfileDeleteTitle => 'Delete the account?';

  @override
  String get studentProfileDeleteWarning =>
      'Deleting your account cannot be undone.';

  @override
  String get studentProfileEmailAddress => 'Email address';

  @override
  String get studentProfileEmailChanged => 'Email address changed.';

  @override
  String studentProfileEmailCurrent(Object email) {
    return 'Current: $email';
  }

  @override
  String get studentProfileEmailInvalid => 'Invalid email address.';

  @override
  String get studentProfileEmailSame => 'This is already your current address.';

  @override
  String get studentProfileEnterCode => 'Enter the code received by email.';

  @override
  String get studentProfileFullName => 'Full name';

  @override
  String get studentProfileGetCode => 'Get a code';

  @override
  String get studentProfileLearningStyle => 'My learning style';

  @override
  String get studentProfileManageSub => 'Manage my subscription';

  @override
  String get studentProfileNewEmail => 'New email';

  @override
  String get studentProfileNewEmailAddress => 'New email address';

  @override
  String get studentProfileNotifAi => 'WinAI recommendations';

  @override
  String get studentProfileNotifAiSub => 'Personalised alerts and tips';

  @override
  String get studentProfileNotifCommunitySub => 'Answers to your questions';

  @override
  String get studentProfileNotifExam => 'Exam reminders';

  @override
  String get studentProfileNotifExamSub => 'Countdown to your exams';

  @override
  String get studentProfileNotifPromo => 'Offers and promotions';

  @override
  String get studentProfileNotifPromoSub => 'New content, promotions';

  @override
  String get studentProfileNotifQuiz => 'Quiz results';

  @override
  String get studentProfileNotifQuizSub => 'Get your scores after each quiz';

  @override
  String studentProfilePeriodEnd(Object date) {
    return 'Period ends on $date';
  }

  @override
  String get studentProfilePhone => 'Phone';

  @override
  String get studentProfilePwdChanged => 'Password changed.';

  @override
  String get studentProfilePwdMismatch => 'Passwords do not match.';

  @override
  String get studentProfilePwdWrong => 'Current password is incorrect.';

  @override
  String get studentProfileSaveChanges => 'Save changes';

  @override
  String get studentProfileTabPrivacy => 'Privacy';

  @override
  String get studentProfileTabSecurity => 'Security';

  @override
  String get studentProfileTitle => 'Profile';

  @override
  String get studentProfileUpdateError => 'Error while updating.';

  @override
  String get studentProfileUpdated => 'Profile updated.';

  @override
  String get studentProfileVisible => 'Visible profile';

  @override
  String get studentProfileVisibleHint => 'Visible to the WinPlus community.';

  @override
  String get studentQuizAvailable => 'Available quizzes';

  @override
  String get studentQuizBackToCatalog => 'Back to the catalogue';

  @override
  String get studentQuizCorrect => 'Correct';

  @override
  String studentQuizCounter(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get studentQuizExcellent => 'Excellent!';

  @override
  String get studentQuizFinish => 'Finish the quiz';

  @override
  String get studentQuizGoodWork => 'Good work';

  @override
  String get studentQuizIncorrect => 'Incorrect';

  @override
  String studentQuizMeta(Object count, Object minutes) {
    return '$count questions · $minutes min';
  }

  @override
  String get studentQuizMyQuizzes => 'My Quizzes';

  @override
  String get studentQuizNone => 'No quizzes available.';

  @override
  String get studentQuizNow => 'Now';

  @override
  String get studentQuizResults => 'Results';

  @override
  String get studentQuizRetake => 'Retake the quiz';

  @override
  String get studentQuizReview => 'Revision';

  @override
  String get studentQuizReviewAnswers => 'Review the answers';

  @override
  String get studentQuizToImprove => 'To improve';

  @override
  String get studentReportsAvgScore => 'Average score';

  @override
  String get studentReportsBestSubject => 'Best subject: Maths';

  @override
  String get studentReportsBySubject => 'Score by subject';

  @override
  String get studentReportsExportPdf => 'Export PDF';

  @override
  String get studentReportsPeriod30 => '30 days';

  @override
  String get studentReportsPeriod7 => '7 days';

  @override
  String get studentReportsPeriod90 => '90 days';

  @override
  String get studentReportsPlanRequired =>
      'Standard plan required for this period';

  @override
  String get studentReportsQuiz => 'Quiz';

  @override
  String get studentReportsQuizDone => 'Quizzes taken';

  @override
  String get studentReportsStandardOnly => 'Available with the Standard plan';

  @override
  String get studentReportsSuccessRate => 'Pass rate';

  @override
  String get studentReportsTitle => 'My reports';

  @override
  String get studentReportsToImprove => 'To improve: Chemistry';

  @override
  String studentReportsWeekShort(Object n) {
    return 'W$n';
  }

  @override
  String get studentReportsWeekly => 'Weekly progress';

  @override
  String get studentRevisionAll => 'All';

  @override
  String get studentRevisionBackToCatalog => 'Browse the catalogue again';

  @override
  String studentRevisionDaysAgo(Object n) {
    return '${n}d ago';
  }

  @override
  String get studentRevisionEmpty =>
      'No questions to revise!\nYou have mastered everything.';

  @override
  String studentRevisionHoursAgo(Object n) {
    return '${n}h ago';
  }

  @override
  String get studentRevisionLoadError => 'Couldn\'t load your mistakes.';

  @override
  String studentRevisionMinutesAgo(Object n) {
    return '$n min ago';
  }

  @override
  String get studentRevisionSubtitle => 'Questions you got wrong recently';

  @override
  String get studentRevisionYesterday => 'yesterday';

  @override
  String get studentSearchHint => 'BAC C Maths, ENSP, SVT…';

  @override
  String get studentSearchIdle => 'Search the catalogue';

  @override
  String studentSearchNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get studentSessionDone => 'Session complete!';

  @override
  String studentSessionDoneScore(Object pct, Object subject) {
    return 'Score: $pct% in $subject';
  }

  @override
  String get studentSessionFinish => 'End the session';

  @override
  String get studentSessionHistory => 'See my past sessions';

  @override
  String studentSessionHistoryLine(Object duration, Object score, Object date) {
    return '$duration min · $score · $date';
  }

  @override
  String get studentSessionIntro =>
      'Pick a subject and a duration. WinAI prepares a briefing, a progressive quiz and then a personalised summary.';

  @override
  String studentSessionMinutes(Object d) {
    return '$d min';
  }

  @override
  String get studentSessionNextQuestion => 'Next question';

  @override
  String get studentSessionNoHistory => 'No completed sessions yet.';

  @override
  String get studentSessionNoScore => 'no score';

  @override
  String get studentSessionNoSubjects => 'No subjects available right now.';

  @override
  String get studentSessionPickSubject => 'Pick a subject to get started.';

  @override
  String get studentSessionQuizError =>
      'Unable to generate the quiz. Try again in a moment.';

  @override
  String studentSessionScoreLine(Object correct, Object total, Object pct) {
    return '$correct/$total correct · $pct%';
  }

  @override
  String get studentSessionSeeSummary => 'See the summary';

  @override
  String get studentSessionStart => 'Start the session';

  @override
  String get studentSessionStartError =>
      'Unable to start the session. Please try again.';

  @override
  String get studentSessionStepBriefing => 'Briefing';

  @override
  String get studentSessionStepQuiz => 'Progressive quiz';

  @override
  String get studentSessionStepSummary => 'WinAI summary';

  @override
  String get studentSessionSummaryError =>
      'The summary couldn\'t be generated, but your answers have been saved.';

  @override
  String studentTabsAiFileAttached(Object name) {
    return 'Attached file: $name';
  }

  @override
  String get studentTabsAiFileReceived => 'File received! I\'m analysing it...';

  @override
  String get studentTabsAiHint => 'Ask WinAI your question…';

  @override
  String get studentTabsAiNoReply => 'Sorry, I couldn\'t answer. Try again.';

  @override
  String get studentTabsAiSuggest1 => 'Explain derivatives to me';

  @override
  String get studentTabsAiSuggest2 => 'BAC C revision plan';

  @override
  String get studentTabsAiSuggest3 => 'My weak subjects?';

  @override
  String get studentTabsAiSuggest4 => 'Generate a Chemistry quiz';

  @override
  String get studentTabsAiTagline => 'Your personal learning assistant';

  @override
  String get studentTabsAttachDocument => 'Document (PDF, Word…)';

  @override
  String get studentTabsAttachFile => 'Attach a file';

  @override
  String get studentTabsAttachImage => 'Image / Photo';

  @override
  String get studentTabsAttachVoice => 'Voice message';

  @override
  String get studentTabsAttachment => 'Attachment';

  @override
  String get studentTabsCatalogLoadError => 'Couldn\'t load the catalogue.';

  @override
  String get studentTabsCertificates => 'Certificates';

  @override
  String get studentTabsCourseCatalog => 'Course catalogue';

  @override
  String get studentTabsExamCoach => 'Exam Coach';

  @override
  String get studentTabsFavorites => 'Favourites';

  @override
  String get studentTabsFindTutor => 'Find a tutor';

  @override
  String get studentTabsFindTutorSub => 'Private lessons online or at home';

  @override
  String get studentTabsGuidedSession => 'Guided study session';

  @override
  String get studentTabsMyBookings => 'My bookings';

  @override
  String get studentTabsMyCart => 'My cart';

  @override
  String get studentTabsMyOrders => 'My orders';

  @override
  String get studentTabsNoContent => 'No content available.';

  @override
  String get studentTabsSearchHint => 'BAC C Maths 2023…';

  @override
  String get studentTabsStructuredCourses => 'Structured courses';

  @override
  String get studentTabsStructuredCoursesSub =>
      'Learn at your own pace · Certificates included';

  @override
  String get studentTabsStudyThisWeek => 'Study this week';

  @override
  String get studentTabsTypeBooks => 'Books';

  @override
  String get studentTabsTypeCorrections => 'Corrections';

  @override
  String get studentTabsTypePacks => 'Packs';

  @override
  String get studentTabsTypePapers => 'Papers';

  @override
  String get studentTabsVoiceSoon => 'Voice recording coming soon';

  @override
  String get studentVarkApplied => 'Style applied!';

  @override
  String get studentVarkApply => 'Apply my style';

  @override
  String get studentVarkApplying => 'Applying…';

  @override
  String get studentVarkAuditory => 'Auditory learner';

  @override
  String get studentVarkKinesthetic => 'Kinaesthetic learner';

  @override
  String get studentVarkMixed => 'Mixed profile';

  @override
  String get studentVarkQ1 => 'When you learn something new, you prefer…';

  @override
  String get studentVarkQ1A => 'Listening to a spoken explanation';

  @override
  String get studentVarkQ1K => 'Trying things out straight away in practice';

  @override
  String get studentVarkQ1R => 'Reading a detailed written lesson';

  @override
  String get studentVarkQ1V => 'Drawing a sketch or seeing a diagram';

  @override
  String get studentVarkQ2 => 'To memorise a maths formula…';

  @override
  String get studentVarkQ2A => 'Repeating it out loud several times';

  @override
  String get studentVarkQ2K => 'Solving exercises until it becomes automatic';

  @override
  String get studentVarkQ2R => 'Writing it out again and again in your notes';

  @override
  String get studentVarkQ2V => 'Picturing it as it is written';

  @override
  String get studentVarkQ3 => 'When you get stuck on a difficult exercise…';

  @override
  String get studentVarkQ3A => 'Talking it through with someone out loud';

  @override
  String get studentVarkQ3K =>
      'Starting the exercise again, trying the steps differently';

  @override
  String get studentVarkQ3R => 'Rereading your notes from the start';

  @override
  String get studentVarkQ3V => 'Looking for an illustrated example';

  @override
  String get studentVarkQ4 => 'In class, you remember things best when…';

  @override
  String get studentVarkQ4A => 'The teacher explains with spoken examples';

  @override
  String get studentVarkQ4K =>
      'There are practical exercises during the lesson';

  @override
  String get studentVarkQ4R => 'You have a well-organised lesson to read';

  @override
  String get studentVarkQ4V => 'The teacher draws on the board or shows slides';

  @override
  String get studentVarkQ5 => 'Your favourite way to revise…';

  @override
  String get studentVarkQ5A => 'Recording myself reciting out loud';

  @override
  String get studentVarkQ5K =>
      'Doing exercise after exercise and past papers with worked solutions';

  @override
  String get studentVarkQ5R => 'Writing short written summaries';

  @override
  String get studentVarkQ5V =>
      'Making revision cards with diagrams and colours';

  @override
  String get studentVarkQ6 =>
      'How do you know you have really understood something?';

  @override
  String get studentVarkQ6A => 'Explaining it clearly out loud to someone';

  @override
  String get studentVarkQ6K => 'Solving varied exercises without help';

  @override
  String get studentVarkQ6R => 'Writing a full summary from memory';

  @override
  String get studentVarkQ6V => 'Drawing it out without looking at your notes';

  @override
  String studentVarkQuestionCount(Object n, Object total) {
    return 'Question $n / $total';
  }

  @override
  String get studentVarkReadWrite => 'Reader / Writer';

  @override
  String get studentVarkSaved =>
      'This result is saved to your profile: WinAI and the generated content adapt to it, on the web as on mobile.';

  @override
  String get studentVarkTitle => 'My learning style';

  @override
  String get studentVarkVisual => 'Visual learner';

  @override
  String get studentViewerAddToCart => 'Add to cart';

  @override
  String studentViewerCorrectionTitle(Object title) {
    return 'Worked solution · $title';
  }

  @override
  String get studentViewerLoadFailed =>
      'Unable to load the document right now.';

  @override
  String get studentViewerNoAccess =>
      'This content isn\'t included in your access. Buy it or subscribe to view it.';

  @override
  String get studentViewerNoConnection =>
      'Can\'t connect. Check your network and try again.';

  @override
  String get studentViewerNoCorrection =>
      'The worked solution for this paper isn\'t available yet.';

  @override
  String get studentViewerNoDocument =>
      'This document isn\'t available right now.';

  @override
  String studentViewerPreviewFirst(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: 'Preview: first $pages pages',
      one: 'Preview: first $pages page',
      zero: 'Preview: first $pages page',
    );
    return '$_temp0';
  }

  @override
  String studentViewerPreviewOf(int pages, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: 'Preview: $pages pages of $total',
      one: 'Preview: $pages page of $total',
      zero: 'Preview: $pages page of $total',
    );
    return '$_temp0';
  }

  @override
  String get studentViewerReadOnly =>
      'Read only: no download, no sharing, no printing';

  @override
  String get studentViewerSessionExpired =>
      'Your session has expired. Log in again to view this document.';

  @override
  String get studentViewerSubscriptions => 'Subscriptions';

  @override
  String get studentViewerUnlockRest =>
      'The rest unlocks when you buy this content or with a subscription that includes the catalogue.';

  @override
  String get subActivate => 'Activate';

  @override
  String get subActivated => 'Subscription activated.';

  @override
  String get subAutoRenew => 'Renew with my balance when due';

  @override
  String get subAutoRenewHint =>
      '3 days of grace if the balance is short · cancel at any time';

  @override
  String get subBadgeCurrent => 'CURRENT';

  @override
  String get subBadgePopular => 'POPULAR';

  @override
  String get subChoosePlan => 'Choose this plan';

  @override
  String get subComputingPrice => 'Calculating the price…';

  @override
  String subDiscount(Object code) {
    return 'Discount $code';
  }

  @override
  String get subDueNow => 'To pay now';

  @override
  String get subEnterMomoNumber => 'Enter a Mobile Money number (9 digits).';

  @override
  String subFeatureAvailableFrom(Object feature, Object plan) {
    return '$feature is available from the $plan plan.';
  }

  @override
  String subFeatureOfPlan(Object plan) {
    return '$plan feature';
  }

  @override
  String get subFinalizeFailed => 'Unable to complete. Please try again.';

  @override
  String get subFooterTtc =>
      'Prices incl. VAT · access until the end of the paid period if you cancel';

  @override
  String subFromPerMonth(Object amount) {
    return 'From $amount XAF incl. VAT/month';
  }

  @override
  String get subInstitutionLicenseNote =>
      'Schools use a licence (student seats, school year): manage it from the Licence tab of your school space.';

  @override
  String get subLater => 'Later';

  @override
  String get subLoadError => 'Loading error';

  @override
  String get subMyBalance => 'My balance';

  @override
  String get subNotOffered => 'Not offered for this period';

  @override
  String get subOurPlans => 'Our plans';

  @override
  String get subPaymentInitiated =>
      'Payment started: confirm it on your phone. Your subscription is activated once it is confirmed.';

  @override
  String subPerUnitTtc(Object unit) {
    return ' XAF incl. VAT / $unit';
  }

  @override
  String get subPeriodMonthly => 'Monthly';

  @override
  String get subPeriodQuarterly => 'Quarterly';

  @override
  String subPeriodTtc(Object period) {
    return '$period · price incl. VAT';
  }

  @override
  String get subPeriodYearly => 'Yearly';

  @override
  String get subPleaseWait => 'Please wait…';

  @override
  String get subPricingFootnote =>
      'Prices incl. VAT · MTN Mobile Money, Orange Money or WinPlus balance · cancel at any time, access until the end of the paid period';

  @override
  String get subQuoteUnavailable => 'Quote unavailable.';

  @override
  String get subRenewOrChange => 'Renew or change period';

  @override
  String get subScheduleChange => 'Schedule the change';

  @override
  String get subSeePlans => 'See the plans';

  @override
  String get subStartTrial => 'Start the free trial';

  @override
  String get subUnitMonth => 'month';

  @override
  String get subUnitQuarter => 'quarter';

  @override
  String get subUnitYear => 'year';

  @override
  String get subUnusedPeriod => 'Unused current period';

  @override
  String get svcAssignmentActive => 'Active';

  @override
  String get svcAssignmentEnded => 'Ended';

  @override
  String get svcBalancePaymentFailed =>
      'The balance payment failed. Try again.';

  @override
  String svcBookedForOthers(Object names, Object payer) {
    return 'For: $names · paid by $payer.';
  }

  @override
  String svcBookedForYou(Object payer, Object group, Object count) {
    return 'Booked for you by $payer$group$count.';
  }

  @override
  String get svcCancelFailed => 'Unable to cancel.';

  @override
  String get svcCartAddCourseFailed =>
      'We couldn\'t add this course to your cart.';

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
  String get svcEndorseFailed => 'Unable to endorse.';

  @override
  String get svcEngStatusActive => 'In progress';

  @override
  String get svcEngStatusCancelled => 'Cancelled';

  @override
  String get svcEngStatusCompleted => 'Completed';

  @override
  String get svcEngStatusExpired => 'Expired (no reply)';

  @override
  String get svcEngStatusRejected => 'Declined by the tutor';

  @override
  String get svcGenericError => 'Something went wrong. Try again.';

  @override
  String get svcIdDocCni => 'National ID card';

  @override
  String get svcIdDocDrivingLicense => 'Driving licence';

  @override
  String get svcIdDocOther => 'Other official document';

  @override
  String get svcIdDocPassport => 'Passport';

  @override
  String get svcIdDocResidencePermit => 'Residence permit';

  @override
  String get svcInterviewCancelled => 'Cancelled';

  @override
  String get svcInterviewFailed => 'Inconclusive';

  @override
  String get svcInterviewNoShow => 'Absent';

  @override
  String get svcInterviewPassed => 'Passed';

  @override
  String get svcInterviewRequested => 'Requested';

  @override
  String get svcInterviewScheduled => 'Scheduled';

  @override
  String get svcInvalidCode => 'Invalid code';

  @override
  String get svcInvalidPromo => 'Invalid promo code.';

  @override
  String get svcLoginFailed => 'Unable to log in';

  @override
  String get svcMaterialDraft => 'Material in draft';

  @override
  String get svcMaterialShared => 'Material shared';

  @override
  String get svcMaterialSharedWithChanges =>
      'Material changed, not shared again';

  @override
  String get svcMoneyPartial => 'Partly refunded';

  @override
  String get svcMoneyUnpaid => 'Unpaid';

  @override
  String get svcOfflineAction => 'This action requires an internet connection.';

  @override
  String get svcOfflineFileMissing =>
      'Offline file not found (was it deleted by the system?).';

  @override
  String get svcOfflineNotSaved =>
      'This lesson has not been saved for offline use.';

  @override
  String get svcOfflinePlayNoAccount =>
      'Unable to play offline: no account logged in.';

  @override
  String get svcOfflineSaveNoAccount =>
      'Unable to save for offline use: no account logged in.';

  @override
  String get svcOrderCreateFailed => 'Unable to create the order.';

  @override
  String svcPartyCount(Object n) {
    return ' · $n students';
  }

  @override
  String svcPartyGroup(Object name) {
    return ' (group $name)';
  }

  @override
  String get svcPayerInstitution => 'School';

  @override
  String get svcPayerStudyGroup => 'Study group';

  @override
  String get svcPaymentInitFailed => 'Unable to start the payment.';

  @override
  String get svcPurchaseNotCompleted => 'The purchase could not be completed.';

  @override
  String svcRefundFeeDeducted(Object fee) {
    return 'Mobile Money fees of $fee XAF deducted';
  }

  @override
  String svcRefundFeesExceed(Object fee) {
    return 'No refund: the Mobile Money fees ($fee XAF) exceed the refundable share.';
  }

  @override
  String get svcRefundFull => ' (full refund)';

  @override
  String get svcRefundInstitutionWallet => 'the school wallet';

  @override
  String get svcRefundMyWallet => 'your WinPlus wallet';

  @override
  String svcRefundPartial(Object percent, Object fee) {
    return ' ($percent% under the tutor\'s policy$fee)';
  }

  @override
  String get svcRefundTooLate =>
      'No refund: cancellation too late under the tutor\'s policy.';

  @override
  String get svcRefundWhoPaid => 'the person who paid';

  @override
  String svcRefundedOn(Object amount, Object target, Object detail) {
    return '$amount XAF refunded to $target$detail.';
  }

  @override
  String svcRefundedTo(Object amount, Object name, Object detail) {
    return '$amount XAF refunded to $name$detail.';
  }

  @override
  String get svcReplySendFailed => 'Unable to send the reply.';

  @override
  String get svcReportFailed => 'Unable to send the report.';

  @override
  String get svcReportHarassment => 'Harassment or inappropriate remarks';

  @override
  String get svcReportIdentity => 'Not the person on the profile';

  @override
  String get svcReportInappropriate => 'Inappropriate behaviour';

  @override
  String get svcReportNoShow => 'Absent from the session';

  @override
  String get svcReportOffPlatform => 'Request for payment outside WinPlus';

  @override
  String get svcReportPoorQuality => 'Poor-quality session';

  @override
  String get svcReportSafety => 'Safety issue';

  @override
  String get svcRequestFailed => 'Unable to send the request.';

  @override
  String get svcReviewSendFailed => 'Unable to send the review.';

  @override
  String get svcSendFailed => 'Unable to send.';

  @override
  String get svcSessionStatusConfirmed => 'Scheduled';

  @override
  String get svcSignupFailed => 'Unable to sign up';

  @override
  String svcStudentFallback(Object id) {
    return 'Student #$id';
  }

  @override
  String get svcTopUpDone => 'Top-up done.';

  @override
  String get svcTutorsLoadFailed => 'Unable to load your tutors.';

  @override
  String get svcVerifEventIdentityApproved => 'ID document approved';

  @override
  String get svcVerifEventIdentityFilesPurged =>
      'Files deleted (limited retention)';

  @override
  String get svcVerifEventIdentityRejected => 'ID document rejected';

  @override
  String get svcVerifEventIdentitySubmitted => 'ID document uploaded';

  @override
  String get svcVerifEventIdentitySuperseded => 'Upload replaced';

  @override
  String get svcVerifEventInstitutionEndorsed => 'Endorsement from a school';

  @override
  String get svcVerifEventInstitutionRevoked => 'Endorsement withdrawn';

  @override
  String get svcVerifEventInterviewCancelled => 'Interview cancelled';

  @override
  String get svcVerifEventInterviewFailed => 'Interview inconclusive';

  @override
  String get svcVerifEventInterviewNoShow => 'Absent from the interview';

  @override
  String get svcVerifEventInterviewPassed => 'Interview passed';

  @override
  String get svcVerifEventInterviewRequested => 'Interview requested';

  @override
  String get svcVerifEventInterviewScheduled => 'Interview scheduled';

  @override
  String get svcVerifEventStatusUnverified => 'Verification withdrawn';

  @override
  String get svcVerifEventSuspensionLifted => 'Suspension lifted';

  @override
  String get svcVerifLoadFailed => 'Unable to load your verification.';

  @override
  String get svcVerifRouteInstitution => 'Endorsement from a school';

  @override
  String get svcVerifRouteInterview => 'Interview';

  @override
  String get svcWinaiLimit =>
      'You have reached your WinAI limit. Upgrade to a higher plan to continue.';

  @override
  String get svcWinaiUnavailable =>
      'WinAI is temporarily unavailable. Try again in a few minutes.';

  @override
  String get svcWithdrawFailed => 'Unable to withdraw.';

  @override
  String switchToLanguage(String lang) {
    return 'Switch to $lang';
  }

  @override
  String get teacherAiInputHint =>
      'Generate a quiz, a sheet, a worked solution…';

  @override
  String get teacherAiSuggestCorrection => 'Model worked solution';

  @override
  String get teacherAiSuggestQuiz => 'Upper Sixth C quiz (10 MCQs)';

  @override
  String get teacherAiSuggestSheet => 'Course sheet';

  @override
  String get teacherAiSuggestTitle => 'Optimise a title';

  @override
  String get teacherAiTagline => 'Your editorial & teaching assistant';

  @override
  String get teacherBookingAcceptError => 'Unable to accept this request.';

  @override
  String get teacherBookingAcceptMonth => 'Accept the month';

  @override
  String get teacherBookingAssignments => 'Assignments';

  @override
  String get teacherBookingAutoMaterial =>
      'WinAI material generated on acceptance';

  @override
  String get teacherBookingAutoMaterialHint =>
      'Counted towards your WinAI usage; you review it before sharing.';

  @override
  String teacherBookingBeneficiaries(Object count) {
    return '$count student(s):';
  }

  @override
  String get teacherBookingCompleteError => 'Unable to close this session.';

  @override
  String get teacherBookingConfirmedEmpty => 'No confirmed sessions for now.';

  @override
  String get teacherBookingDeclineEngagementMessage =>
      'The payer gets a full refund, session by session; if the month was paid by Mobile Money, the fees are deducted from your balance.';

  @override
  String get teacherBookingDeclineEngagementTitle =>
      'Decline the whole commitment';

  @override
  String get teacherBookingDeclineError => 'Unable to decline this request.';

  @override
  String get teacherBookingDeclineMessage =>
      'The person who paid (student, parent, school or group member) will get a full refund to their WinPlus wallet; if the session was paid by Mobile Money, the operator\'s fees will be deducted from your balance.';

  @override
  String get teacherBookingDeclineTitle => 'Decline the request';

  @override
  String get teacherBookingDeclined =>
      'Request declined: the payer is refunded to their wallet.';

  @override
  String teacherBookingDeclinedFee(Object amount) {
    return 'Request declined: the payer is refunded, $amount XAF of Mobile Money fees deducted from your balance.';
  }

  @override
  String get teacherBookingDetail => 'Details';

  @override
  String teacherBookingDiscount(Object percent) {
    return '($percent% discount)';
  }

  @override
  String teacherBookingDisputeReason(Object reason) {
    return 'Dispute reason: $reason';
  }

  @override
  String get teacherBookingEngagementAccepted =>
      'Commitment accepted: all the sessions in the month are confirmed.';

  @override
  String get teacherBookingEngagementRequests => 'Monthly commitment requests';

  @override
  String get teacherBookingExpiresSoon => 'Expires soon';

  @override
  String teacherBookingGroupSession(Object count) {
    return 'Group session · $count students';
  }

  @override
  String get teacherBookingHidePrice => 'Hide price details';

  @override
  String get teacherBookingMarkCompleted => 'Mark as completed';

  @override
  String teacherBookingMinutes(Object count) {
    return '$count min';
  }

  @override
  String teacherBookingMinutesToAnswer(Object count) {
    return '$count min to reply';
  }

  @override
  String get teacherBookingModeStudentHome => 'At home (student)';

  @override
  String teacherBookingPaidBy(Object payer) {
    return 'Paid by: $payer';
  }

  @override
  String teacherBookingPaidInAdvance(Object amount) {
    return '$amount XAF paid in advance';
  }

  @override
  String get teacherBookingPaidPerSession => 'paid out session by session';

  @override
  String teacherBookingParticipants(Object who, Object names) {
    return '$who: $names';
  }

  @override
  String get teacherBookingPendingEmpty => 'No pending requests for now.';

  @override
  String get teacherBookingPendingTitle => 'Pending requests';

  @override
  String get teacherBookingPrepareMaterial => 'Prepare the material with WinAI';

  @override
  String teacherBookingQuote(Object note) {
    return '\"$note\"';
  }

  @override
  String get teacherBookingReasonHint => 'Reason (optional)';

  @override
  String teacherBookingSessionsCount(Object count) {
    return '$count sessions';
  }

  @override
  String get teacherBookingSettingError => 'Unable to change the setting.';

  @override
  String get teacherBookingShowPrice => 'View price details';

  @override
  String get teacherBookingTheStudent => 'the student';

  @override
  String get teacherBookingTopics => 'Topics to work on';

  @override
  String get teacherBookingUpcomingTitle => 'Upcoming sessions / to close';

  @override
  String get teacherBookingViaAssignment => 'via an assignment';

  @override
  String get teacherClassAdd => 'Add';

  @override
  String get teacherClassAddStudent => 'Add a student';

  @override
  String get teacherClassAddStudentError => 'This student could not be added.';

  @override
  String get teacherClassAddStudentErrorDetail =>
      'This student could not be added (unknown email or already a member).';

  @override
  String get teacherClassAssignmentCreateError =>
      'The homework could not be created.';

  @override
  String get teacherClassAssignmentCreated =>
      'Homework created. Students have been notified.';

  @override
  String get teacherClassAssignmentTitle => 'Homework title';

  @override
  String get teacherClassAssignmentTitleHint => 'E.g. Homework no. 3';

  @override
  String get teacherClassAssignmentsLoadError =>
      'The homework could not be loaded.';

  @override
  String get teacherClassAssignmentsTab => 'Homework';

  @override
  String teacherClassCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scripts',
      one: '$count script',
    );
    return '$_temp0';
  }

  @override
  String get teacherClassCreateAssignment => 'Create the homework';

  @override
  String get teacherClassNewAssignment => 'New homework';

  @override
  String get teacherClassNoAssignments => 'No homework yet';

  @override
  String get teacherClassNoStudents => 'No students in this class';

  @override
  String get teacherClassNoStudentsHint =>
      'Add a student using their WinPlus email.';

  @override
  String get teacherClassReferenceHint => 'Your own answer key…';

  @override
  String get teacherClassReferenceLabel => 'Reference answer key (optional)';

  @override
  String get teacherClassRemove => 'Remove';

  @override
  String get teacherClassRemoveFromClass => 'Remove from the class';

  @override
  String teacherClassRemoveStudentBody(Object name, Object className) {
    return '$name will be removed from “$className”.';
  }

  @override
  String get teacherClassRemoveStudentError =>
      'This student could not be removed.';

  @override
  String get teacherClassRemoveStudentTitle => 'Remove this student?';

  @override
  String get teacherClassStatementHint => 'Paste the question…';

  @override
  String get teacherClassStatementLabel =>
      'Question (generates the WinAI marking scheme)';

  @override
  String get teacherClassStudentAdded => 'Student added.';

  @override
  String get teacherClassStudentEmailHint => 'student@example.cm';

  @override
  String get teacherClassStudentEmailLabel => 'Student\'s WinPlus email';

  @override
  String get teacherClassStudentsLoadError =>
      'The students could not be loaded.';

  @override
  String teacherClassToMark(Object count) {
    return '$count to mark';
  }

  @override
  String get teacherClassesActionFailed => 'This action failed.';

  @override
  String teacherClassesAverage(Object avg) {
    return '$avg% avg.';
  }

  @override
  String get teacherClassesCreate => 'Create a class';

  @override
  String get teacherClassesCreateError =>
      'This class could not be created (name already in use?).';

  @override
  String teacherClassesCreated(Object name) {
    return 'Class “$name” created.';
  }

  @override
  String teacherClassesDeactivateBody(Object name, Object count) {
    return '“$name” has $count student(s): it will be deactivated (not deleted) and removed from the list.';
  }

  @override
  String get teacherClassesDeactivateTitle => 'Deactivate the class?';

  @override
  String teacherClassesDeleteBody(Object name) {
    return 'Permanently delete “$name”?';
  }

  @override
  String get teacherClassesDeleteTitle => 'Delete the class?';

  @override
  String get teacherClassesHideInactive => 'Hide deactivated';

  @override
  String get teacherClassesInactive => 'Deactivated';

  @override
  String get teacherClassesLevelHint => 'E.g. Upper Sixth';

  @override
  String get teacherClassesLoadError => 'Your classes could not be loaded.';

  @override
  String get teacherClassesMyBookings => 'My student bookings';

  @override
  String get teacherClassesMyLinks => 'My direct links';

  @override
  String get teacherClassesName => 'Class name';

  @override
  String get teacherClassesNameHint => 'E.g. Upper Sixth C Maths';

  @override
  String get teacherClassesNone => 'No classes';

  @override
  String get teacherClassesNoneYet => 'No classes yet';

  @override
  String get teacherClassesReactivateError =>
      'This class could not be reactivated.';

  @override
  String get teacherClassesRequired => 'Name, level and year are required.';

  @override
  String get teacherClassesShowInactive => 'Show deactivated';

  @override
  String teacherClassesStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '$count student',
    );
    return '$_temp0';
  }

  @override
  String get teacherClassesTitle => 'My classes';

  @override
  String get teacherClassesYear => 'Academic year';

  @override
  String get teacherClassesYearHint => 'E.g. 2026-2027';

  @override
  String get teacherContentChangeStatus => 'Change status';

  @override
  String get teacherContentComingSoon => 'Coming soon';

  @override
  String get teacherContentCoursesBanner =>
      'Create and manage your structured courses';

  @override
  String teacherContentDeleteBody(Object title) {
    return '“$title” will be permanently deleted.';
  }

  @override
  String get teacherContentDeleteTitle => 'Delete?';

  @override
  String get teacherContentDownloadsShort => 'Downloads';

  @override
  String get teacherContentEditInfo => 'Edit details';

  @override
  String get teacherContentEmpty => 'No content.';

  @override
  String get teacherContentManage => 'Manage';

  @override
  String get teacherContentRating => 'Rating';

  @override
  String get teacherContentStats => 'Statistics';

  @override
  String get teacherContentStatusArchived => 'Archived';

  @override
  String teacherContentStatusChanged(Object status) {
    return 'Status changed: $status';
  }

  @override
  String get teacherContentStatusReview => 'Under review';

  @override
  String get teacherCorrectionCorrect => 'Mark';

  @override
  String get teacherCorrectionEmpty => 'No submissions';

  @override
  String get teacherCorrectionFeedbackHint =>
      'Comments and feedback for the student…';

  @override
  String get teacherCorrectionFilterMarked => 'Marked';

  @override
  String get teacherCorrectionGrade => 'Mark: ';

  @override
  String teacherCorrectionPendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get teacherCorrectionQueueTitle => 'Marking queue';

  @override
  String get teacherCorrectionSend => 'Send the marking';

  @override
  String get teacherCorrectionSendError => 'Error while sending.';

  @override
  String teacherCorrectionSent(Object name) {
    return 'Marking sent to $name.';
  }

  @override
  String teacherCorrectionSheetTitle(Object name) {
    return 'Mark: $name';
  }

  @override
  String get teacherCorrectionView => 'View the marking';

  @override
  String get teacherCoursesCopyLink => 'Copy link';

  @override
  String teacherCoursesCreateOnWeb(Object url) {
    return 'Courses are created and edited on the WinPlus website, from your teacher area, with the same account:\n\n$url\n\nYour courses then appear here.';
  }

  @override
  String get teacherCoursesCreateTitle => 'Create a course';

  @override
  String teacherCoursesDeleteBody(Object title) {
    return 'This cannot be undone. The course “$title” will be permanently deleted.';
  }

  @override
  String get teacherCoursesDeleteError => 'Unable to delete the course.';

  @override
  String get teacherCoursesDeleteTitle => 'Delete the course?';

  @override
  String get teacherCoursesDeleted => 'Course deleted.';

  @override
  String get teacherCoursesDetailError => 'Unable to load the details.';

  @override
  String get teacherCoursesEmptyAll => 'You don\'t have any courses yet.';

  @override
  String get teacherCoursesEmptyStatus => 'No course with this status.';

  @override
  String teacherCoursesEnrolled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enrolled',
      one: '$count enrolled',
    );
    return '$_temp0';
  }

  @override
  String teacherCoursesEnrolledMany(Object count) {
    return '$count enrolled';
  }

  @override
  String teacherCoursesLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '$count lesson',
    );
    return '$_temp0';
  }

  @override
  String teacherCoursesLimitPending(Object count) {
    return '$count waiting for approval';
  }

  @override
  String teacherCoursesLimitPublished(Object published, Object max) {
    return 'Published courses: $published / $max';
  }

  @override
  String get teacherCoursesLimitReached =>
      'your plan\'s limit is reached: move to a higher plan to publish more.';

  @override
  String get teacherCoursesLimitUnlimited =>
      'Your plan lets you publish an unlimited number of courses.';

  @override
  String get teacherCoursesLinkCopied =>
      'Link copied: open it in your browser.';

  @override
  String get teacherCoursesLoadError => 'We couldn\'t load the courses.';

  @override
  String get teacherCoursesSubmit => 'Submit for approval';

  @override
  String get teacherCoursesSubmitError => 'The course could not be submitted.';

  @override
  String get teacherCoursesSubmitted => 'Course submitted for approval.';

  @override
  String get teacherCoursesViewDetails => 'View details';

  @override
  String get teacherDashActiveStudents => 'Active students';

  @override
  String get teacherDashAvgRating => 'Average rating';

  @override
  String get teacherDashAvgShort => 'avg. rating';

  @override
  String get teacherDashDownloads => 'Downloads';

  @override
  String teacherDashDownloadsCount(Object count) {
    return '$count downloads';
  }

  @override
  String get teacherDashLast4Weeks => 'Last 4 weeks';

  @override
  String get teacherDashMonthRevenue => 'This month\'s revenue';

  @override
  String get teacherDashNoContent => 'No published content.';

  @override
  String get teacherDashOutOf5 => 'Out of 5';

  @override
  String teacherDashPlan(Object plan) {
    return '$plan PLAN';
  }

  @override
  String get teacherDashPublished => 'published';

  @override
  String get teacherDashPublishedContent => 'Published content';

  @override
  String get teacherDashRecentContent => 'Recent content';

  @override
  String get teacherDashShareLabel => 'Share on your sessions: ';

  @override
  String teacherDashShareValue(Object percent) {
    return '$percent% of your revenue';
  }

  @override
  String teacherDashThisMonth(Object amount) {
    return '$amount XAF this month';
  }

  @override
  String get teacherGroupApplyFlat => 'Fixed price';

  @override
  String get teacherGroupApplyPerStudent => 'Price per student';

  @override
  String teacherGroupBasedOn(Object count) {
    return '(based on $count tutors)';
  }

  @override
  String get teacherGroupEstimate => '(estimate)';

  @override
  String get teacherGroupFlatExample =>
      'E.g. 150%: an individual session at 6,000 XAF costs 9,000 XAF for the group, whatever the number of students.';

  @override
  String get teacherGroupFlatLabel => 'Group price (% of the individual price)';

  @override
  String teacherGroupFlatLine(Object percent) {
    return 'Or fixed price for the group: $percent% of the individual price';
  }

  @override
  String get teacherGroupIntro =>
      'A parent, a school or a study group can book for several students. A group session takes up your slot only once.';

  @override
  String get teacherGroupMaxSizeLabel => 'Maximum group size (students)';

  @override
  String teacherGroupMaxSizeLine(Object count) {
    return 'Maximum size: $count students';
  }

  @override
  String get teacherGroupMethodFlat => 'Fixed price for the group';

  @override
  String get teacherGroupMethodNone => 'Individual only';

  @override
  String get teacherGroupMethodPerStudent => 'Decreasing price per student';

  @override
  String teacherGroupPerStudentLine(Object count, Object percent) {
    return 'Price per student, from $count students: −$percent%';
  }

  @override
  String teacherGroupStudents(Object count) {
    return '$count students';
  }

  @override
  String get teacherGroupSubjectsFirst => 'Choose your subjects first.';

  @override
  String get teacherGroupSuggest => 'Suggest (WinAI)';

  @override
  String get teacherGroupSuggestError =>
      'WinAI could not suggest group settings right now.';

  @override
  String get teacherGroupSuggested => 'Settings suggested by WinAI';

  @override
  String get teacherGroupTierHint =>
      'Only the highest tier reached applies. Without a tier, each student pays the individual price.';

  @override
  String get teacherGroupTitle => 'Group sessions';

  @override
  String get teacherLinksInvite => 'Invite a student';

  @override
  String get teacherLinksInviteSent => 'Invitation sent!';

  @override
  String get teacherLinksLinkedTab => 'Linked';

  @override
  String get teacherLinksNoLinked => 'No linked students';

  @override
  String get teacherLinksNoPending => 'No pending invitations';

  @override
  String get teacherLinksSearchHint => 'Name, email or phone…';

  @override
  String get teacherLinksTitle => 'My student links';

  @override
  String get teacherPricingAddMod => '+ Add an adjustment';

  @override
  String get teacherPricingAddRate => '+ Add a rate';

  @override
  String get teacherPricingAddTier => 'Add a tier';

  @override
  String get teacherPricingAddTierPlus => '+ Add a tier';

  @override
  String get teacherPricingAllDay => 'All day';

  @override
  String get teacherPricingAllModes => 'All formats';

  @override
  String get teacherPricingBaseTitle => 'Base rate by subject and format';

  @override
  String get teacherPricingDurHint => 'Only the highest tier reached applies.';

  @override
  String get teacherPricingDurTitle => 'Duration-based discount';

  @override
  String get teacherPricingEnd => 'End';

  @override
  String get teacherPricingFrom => 'From ';

  @override
  String get teacherPricingGridIntro =>
      'Without a grid, your hourly rate applies everywhere. Sessions are charged pro rata in 30-minute blocks; the exact price is calculated by WinPlus and shown to the student before payment.';

  @override
  String get teacherPricingGridTitle => 'Rate grid (optional)';

  @override
  String get teacherPricingIgnore => 'Ignore';

  @override
  String get teacherPricingInPerson => 'In person';

  @override
  String get teacherPricingModExample =>
      'E.g. +20% in the evening, −10% in the morning.';

  @override
  String get teacherPricingModName => 'Name (e.g. Evening)';

  @override
  String get teacherPricingModTitle => 'Time-slot adjustment';

  @override
  String get teacherPricingRemoveMod => 'Delete this adjustment';

  @override
  String get teacherPricingRemoveRate => 'Delete this rate';

  @override
  String get teacherPricingRemoveTier => 'Delete this tier';

  @override
  String get teacherPricingSubjectsFirst =>
      'Choose your subjects first (step 1).';

  @override
  String get teacherPricingSuggest => 'Suggest a grid (WinAI)';

  @override
  String get teacherPricingSuggestError => 'WinAI could not suggest a grid.';

  @override
  String get teacherPricingSuggested => 'Grid suggested by WinAI';

  @override
  String get teacherProfileActivate => 'Activate';

  @override
  String get teacherProfileActivateError =>
      'Complete the essential fields before activating your profile.';

  @override
  String get teacherProfileActivated =>
      'Your tutor profile is visible in search!';

  @override
  String get teacherProfileActiveAfterSuspension =>
      'Active after the suspension is reviewed';

  @override
  String get teacherProfileActiveAfterVerification =>
      'Active after verification';

  @override
  String get teacherProfileAddZone => 'Add this area';

  @override
  String get teacherProfileAiSuggestion => 'WinAI suggestion';

  @override
  String get teacherProfileAiUnavailable => 'WinAI is unavailable for now.';

  @override
  String get teacherProfileAtMyHome => 'At my home';

  @override
  String get teacherProfileAtStudentHome => 'At the student\'s home';

  @override
  String get teacherProfileBackToEdit => 'Back to editing';

  @override
  String get teacherProfileBio => 'Short bio (300 characters max)';

  @override
  String get teacherProfileBlockedDefault =>
      'In-person lessons are reserved for verified tutors.';

  @override
  String get teacherProfileBookPreview => 'Book (preview  disabled)';

  @override
  String get teacherProfileChooseCity => 'Choose a city…';

  @override
  String get teacherProfileCityOrDistrictHint => 'City / district name';

  @override
  String get teacherProfileCompletion => 'Profile completeness';

  @override
  String get teacherProfileDiploma =>
      'Diploma (optional, “Diploma verified” badge, no effect on in-person lessons)';

  @override
  String get teacherProfileDistrictHint => 'District (optional)…';

  @override
  String teacherProfileDocStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String get teacherProfileDocUrlHint => 'URL of the uploaded document';

  @override
  String get teacherProfileFullRefund => 'Full refund if cancelled at least';

  @override
  String get teacherProfileGetVerified => 'Get verified';

  @override
  String get teacherProfileHourlyRate => 'Hourly rate (XAF)';

  @override
  String get teacherProfileHourlyRateHint => 'e.g. 3000';

  @override
  String teacherProfileHours(Object count) {
    return '$count h';
  }

  @override
  String get teacherProfileHoursBefore => 'h before';

  @override
  String get teacherProfileKeptSuspended =>
      'Your in-person choices stay saved and will become active again when the suspension is lifted.';

  @override
  String get teacherProfileKeptUnverified =>
      'Your in-person choices are saved and will become active as soon as you are verified.';

  @override
  String get teacherProfileLevelEnam => 'ENAM Public Administration';

  @override
  String get teacherProfileLevelsCovered => 'Levels covered';

  @override
  String get teacherProfileLoadError => 'Unable to load your tutor profile.';

  @override
  String get teacherProfileMaxPerWeek => 'Max sessions per week';

  @override
  String get teacherProfileModes => 'Lesson formats';

  @override
  String get teacherProfileMonthlyDesc =>
      'Same slots every week for 4 weeks, paid in advance; you are paid session by session.';

  @override
  String teacherProfileMonthlyDiscountHint(Object max) {
    return 'Monthly discount in % (0 to $max)';
  }

  @override
  String get teacherProfileMonthlyHint =>
      'Applied to the price of each session in the month, as calculated by your grid.';

  @override
  String get teacherProfileMonthlyToggle => 'Offer the monthly commitment';

  @override
  String get teacherProfileNeutralPlace => 'In person in a neutral place';

  @override
  String get teacherProfileNoRefund => 'No refund if less than';

  @override
  String get teacherProfileNoneF => 'None';

  @override
  String get teacherProfileNoneM => 'None';

  @override
  String get teacherProfileNotice => 'Minimum notice period';

  @override
  String get teacherProfileOnHoliday => 'On holiday';

  @override
  String get teacherProfileOnlineViaWinplus => 'Online via WinPlus';

  @override
  String get teacherProfileOtherCity => 'Other city';

  @override
  String get teacherProfilePartialRefund => 'After that, share refunded';

  @override
  String teacherProfilePolicyBounds(Object fullMin, Object fullMax,
      Object partialMin, Object partialMax, Object noMin, Object noMax) {
    return 'Limits set by WinPlus: full refund between $fullMin h and $fullMax h before, refunded share from $partialMin to $partialMax%, no refund below $noMin to $noMax h.';
  }

  @override
  String get teacherProfilePolicyIntro =>
      'What the student gets back if they cancel themselves (Mobile Money fees remain their responsibility).';

  @override
  String get teacherProfilePreview => 'View my profile as a student';

  @override
  String get teacherProfilePrevious => 'Previous';

  @override
  String get teacherProfileProTitle => 'Professional title';

  @override
  String get teacherProfileProTitleHint =>
      'e.g. Maths teacher  Upper Sixth C/D';

  @override
  String get teacherProfileRate => 'Rate';

  @override
  String teacherProfileRateSuggested(
      Object rate, Object low, Object high, Object explanation) {
    return '$rate XAF/h suggested ($low-$high). $explanation';
  }

  @override
  String get teacherProfileReviewsSoon => 'Reviews coming soon';

  @override
  String get teacherProfileSaveError => 'Error while saving.';

  @override
  String get teacherProfileSaving => 'Saving…';

  @override
  String get teacherProfileSpecCatchUp => 'Express catch-up';

  @override
  String get teacherProfileSpecContestPrep => 'Competitive exam preparation';

  @override
  String get teacherProfileSpecHoliday => 'Holiday classes';

  @override
  String get teacherProfileSpecSchoolSupport => 'School support';

  @override
  String get teacherProfileSpecialties => 'Specialities';

  @override
  String get teacherProfileStepSaved => 'Step saved.';

  @override
  String get teacherProfileStyle => 'Teaching style';

  @override
  String get teacherProfileStyleInteractive => 'Interactive';

  @override
  String get teacherProfileStyleMixed => 'Mixed';

  @override
  String get teacherProfileStyleStructured => 'Structured';

  @override
  String get teacherProfileSubjectsTaught => 'Subjects taught';

  @override
  String get teacherProfileTitle => 'Tutor mode';

  @override
  String get teacherProfileTrialOffered => 'Trial session offered';

  @override
  String get teacherProfileTrialPriceHint => 'Price (0 = free)';

  @override
  String get teacherProfileTrialToggle => 'Offer a trial session';

  @override
  String get teacherProfileUnlimited => 'Unlimited';

  @override
  String get teacherProfileUseRate => 'Use this rate';

  @override
  String get teacherProfileVerifOpen => 'Verified: in-person lessons open';

  @override
  String get teacherProfileVerifRoutes =>
      'ID document, interview or school endorsement';

  @override
  String get teacherProfileVerifSuspended =>
      'In-person suspended pending a review';

  @override
  String get teacherProfileVerification => 'In-person verification';

  @override
  String get teacherProfileVideo => 'Introduction video (optional)';

  @override
  String get teacherProfileWeeklySlots => 'Weekly slots (tap to activate)';

  @override
  String get teacherProfileZones => 'Areas covered';

  @override
  String get teacherPublishAmountHint => 'Amount in XAF (e.g. 500)';

  @override
  String get teacherPublishChooseFile => 'Choose a file';

  @override
  String get teacherPublishDescriptionHint =>
      'Describe the content (objectives, level, content…)';

  @override
  String get teacherPublishFileRequired => 'Please choose a file.';

  @override
  String get teacherPublishFreePrice => 'Set your price';

  @override
  String get teacherPublishFreePriceHint => 'Set your own price in XAF';

  @override
  String get teacherPublishNetworkError => 'Network error. Please try again.';

  @override
  String get teacherPublishReviewNote =>
      'Your content will be reviewed before it is published (24-48h)';

  @override
  String teacherPublishSizeBytes(Object size) {
    return '$size B';
  }

  @override
  String teacherPublishSizeKb(Object size) {
    return '$size KB';
  }

  @override
  String teacherPublishSizeMb(Object size) {
    return '$size MB';
  }

  @override
  String get teacherPublishSubmit => 'Publish for review';

  @override
  String get teacherPublishSubmitFailed =>
      'Submission failed. Please try again.';

  @override
  String get teacherPublishSubmitted => 'Content submitted for review!';

  @override
  String get teacherPublishSubscriptionOnly => 'Subscription only';

  @override
  String get teacherPublishSubscriptionOnlyHint =>
      'Available to all subscribers';

  @override
  String get teacherPublishTitle => 'Publish content';

  @override
  String get teacherPublishTitleHint => 'E.g. BAC C Mathematics 2024';

  @override
  String get teacherPublishTitleRequired => 'Please enter a title.';

  @override
  String get teacherPublishType => 'Type';

  @override
  String get teacherPublishTypePack => 'Pack';

  @override
  String get teacherPublishTypeSheet => 'Revision sheet';

  @override
  String get teacherPublishYear => 'Year';

  @override
  String get teacherPublishYearHint => 'E.g. 2024';

  @override
  String get teacherSession30Min => '30 min';

  @override
  String get teacherSession3h => '3h';

  @override
  String get teacherSessionCreateButton => 'Create the session';

  @override
  String get teacherSessionCreateError => 'Error while creating.';

  @override
  String get teacherSessionCreateTitle => 'Create a session';

  @override
  String get teacherSessionCreated => 'Session created!';

  @override
  String get teacherSessionCreatedHint =>
      'Registered students will receive a notification.';

  @override
  String get teacherSessionDateHint => '25 August 2026 at 2:00 pm';

  @override
  String get teacherSessionDateLabel => 'Date and time';

  @override
  String teacherSessionDuration(Object minutes) {
    return 'Duration: $minutes minutes';
  }

  @override
  String get teacherSessionLinkLabel => 'Session link (Zoom, Meet…)';

  @override
  String teacherSessionMaxStudents(Object count) {
    return 'Max students: $count';
  }

  @override
  String get teacherSessionTitleHint => 'Derivatives revision  BAC C';

  @override
  String get teacherSessionTitleLabel => 'Session title *';

  @override
  String get teacherSessionsDemo1 => 'Derivatives revision  Tle C';

  @override
  String get teacherSessionsDemo2 => 'Physics paper worked solution';

  @override
  String get teacherSessionsPlan => 'Schedule a session';

  @override
  String get teacherSessionsSoon => '● Soon';

  @override
  String teacherSessionsToday(Object weekday, Object date) {
    return 'Today, $weekday $date';
  }

  @override
  String get teacherSessionsViewDetails => 'View details';

  @override
  String get teacherVerifActive => 'Active';

  @override
  String get teacherVerifAttach => 'Attach my ID and selfie to the interview';

  @override
  String get teacherVerifAvailability => 'Your availability';

  @override
  String get teacherVerifAvailabilityHint =>
      'E.g.: Tuesday and Thursday after 5 pm';

  @override
  String get teacherVerifBack => 'Back (if needed)';

  @override
  String get teacherVerifCameraUnavailable =>
      'Camera unavailable: choose a photo of your face from your files instead.';

  @override
  String get teacherVerifCancelRequest => 'Cancel the request';

  @override
  String get teacherVerifCancelled => 'Request cancelled.';

  @override
  String get teacherVerifChoose => 'Choose';

  @override
  String get teacherVerifCityHint => 'Douala, Yaoundé…';

  @override
  String get teacherVerifDocType => 'ID type';

  @override
  String get teacherVerifFile => 'File';

  @override
  String teacherVerifFileLine(Object label, Object fileName) {
    return '$label: $fileName';
  }

  @override
  String get teacherVerifFileTooBig => 'File too large (8 MB maximum).';

  @override
  String get teacherVerifFront => 'Front of the ID';

  @override
  String get teacherVerifHistory => 'History';

  @override
  String get teacherVerifIdentityOk => 'Your ID has been approved.';

  @override
  String get teacherVerifIdentityText =>
      'An administrator compares the photo on your ID with your face.';

  @override
  String get teacherVerifIdentityTitle => 'ID document and selfie';

  @override
  String get teacherVerifInactiveLink => '(link inactive)';

  @override
  String get teacherVerifInstitutionText =>
      'If you are linked to a school on WinPlus, it can endorse you after verifying you by its own means. If the link or the endorsement is removed, this route no longer applies.';

  @override
  String get teacherVerifInstitutionTitle => 'Endorsement from your school';

  @override
  String get teacherVerifInterviewText =>
      'By video call or in person. The interview does not replace ID: have your ID ready, it is added to the file with a selfie.';

  @override
  String get teacherVerifInterviewTitle => 'Interview with an agent';

  @override
  String get teacherVerifIntro =>
      'Sessions at the student\'s home, at your home or in a neutral place are reserved for verified tutors. Choose one of the three routes: one is enough. The diploma remains an optional badge.';

  @override
  String teacherVerifLastInterview(Object reason) {
    return 'Last interview: $reason';
  }

  @override
  String teacherVerifLink(Object url) {
    return 'Link: $url';
  }

  @override
  String get teacherVerifMeeting => 'In person';

  @override
  String get teacherVerifMeetingCity => 'Meeting city';

  @override
  String get teacherVerifMessage => 'Message (optional)';

  @override
  String get teacherVerifNeedFiles =>
      'Add at least the front of your ID and a selfie.';

  @override
  String get teacherVerifNoEndorsement =>
      'No endorsement yet. Ask your linked school (Network) to endorse you.';

  @override
  String get teacherVerifPassed => 'Interview passed.';

  @override
  String get teacherVerifPassedNeedIdentity =>
      'Your ID and selfie still need to be approved to open in-person lessons.';

  @override
  String teacherVerifPendingSince(Object date) {
    return 'Being verified since $date.';
  }

  @override
  String get teacherVerifPhotoTooBig => 'Photo too large (8 MB maximum).';

  @override
  String teacherVerifPlace(Object place) {
    return 'Place: $place';
  }

  @override
  String teacherVerifReasonSuffix(Object reason) {
    return ': $reason';
  }

  @override
  String teacherVerifRejected(Object reason) {
    return 'Rejected: $reason. You can send new documents.';
  }

  @override
  String get teacherVerifRequestInterview => 'Request an interview';

  @override
  String get teacherVerifRequested =>
      'Request sent. A WinPlus agent will suggest a date.';

  @override
  String teacherVerifRequestedOn(Object date) {
    return 'Request sent on $date. An agent will suggest a date.';
  }

  @override
  String get teacherVerifRetake => 'Retake';

  @override
  String teacherVerifRetention(Object approved, Object rejected) {
    return 'Private files, seen only by the WinPlus team, never shown on your profile. Deleted $approved days after approval ($rejected days after a rejection); only the decision is kept.';
  }

  @override
  String teacherVerifRevoked(Object name, Object date) {
    return 'Endorsement from $name withdrawn on $date';
  }

  @override
  String teacherVerifRoutesValidated(Object routes) {
    return 'Route(s) approved: $routes';
  }

  @override
  String teacherVerifScheduledOn(Object date) {
    return 'Scheduled for $date';
  }

  @override
  String get teacherVerifSelfie => 'Selfie (your face)';

  @override
  String get teacherVerifSent =>
      'Documents sent. The WinPlus team will compare them.';

  @override
  String get teacherVerifSubmit => 'Send for verification';

  @override
  String get teacherVerifSuspended => 'In-person suspended';

  @override
  String get teacherVerifSuspendedBanner =>
      'Following reports, your in-person sessions are suspended while a member of the WinPlus team reviews the situation. Your online sessions remain possible.';

  @override
  String get teacherVerifTake => 'Take';

  @override
  String get teacherVerifTitle => 'In-person verification';

  @override
  String get teacherVerifValidated => 'Approved';

  @override
  String teacherVerifVerifiedBy(Object name) {
    return 'verified by $name';
  }

  @override
  String get teacherVerifVideo => 'Video call';

  @override
  String get timerBackToWork => 'Back to work!';

  @override
  String get timerBreakDone => 'Break over!';

  @override
  String timerDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pomodoros',
      one: '$count pomodoro',
      zero: '$count pomodoros',
    );
    return 'Well done! You have completed $_temp0 today.';
  }

  @override
  String get timerModeLongBreak => 'Long break';

  @override
  String get timerModePomodoro => 'Pomodoro';

  @override
  String get timerModeShortBreak => 'Short break';

  @override
  String get timerNewPomodoro => 'New pomodoro';

  @override
  String get timerPomodoroDone => 'Pomodoro complete!';

  @override
  String get timerReset => 'Reset';

  @override
  String get timerTip =>
      '25 min of focus + 5 min of break = 1 pomodoro. After 4 pomodoros, take a long 15-min break.';

  @override
  String get timerTitle => 'Pomodoro timer';

  @override
  String timerTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pomodoros today',
      one: '$count pomodoro today',
      zero: '$count pomodoros today',
    );
    return '$_temp0';
  }

  @override
  String get tutoringActionFailed => 'Action not possible.';

  @override
  String get tutoringAddTopic => 'Add this topic';

  @override
  String get tutoringAllClasses => 'All classes';

  @override
  String get tutoringAllLevels => 'All levels';

  @override
  String get tutoringAllSubjects => 'All subjects';

  @override
  String get tutoringAnotherTopic => 'Another topic…';

  @override
  String tutoringAssignAllClass(Object name) {
    return 'The whole class $name';
  }

  @override
  String get tutoringAssignChildrenLabel => 'Beneficiary children';

  @override
  String get tutoringAssignChooseChild => 'Choose at least one child.';

  @override
  String get tutoringAssignChooseStudents => 'Choose students or a class.';

  @override
  String get tutoringAssignChooseTutor => 'Choose a tutor.';

  @override
  String get tutoringAssignError => 'Unable to create the assignment.';

  @override
  String get tutoringAssignIntro =>
      'The tutor receives the request and accepts or declines it. The assignment books nothing: it highlights the tutor and preselects the students for one-click booking.';

  @override
  String get tutoringAssignNoChild =>
      'No linked child (the link must be accepted by the child).';

  @override
  String get tutoringAssignNoStudent =>
      'No active student with a confirmed link in your school.';

  @override
  String get tutoringAssignNoTutor => 'No tutor found.';

  @override
  String get tutoringAssignNoWholeClass => 'No whole class';

  @override
  String get tutoringAssignNoteHint =>
      'A note for the tutor (goals, frequency…)';

  @override
  String tutoringAssignPending(Object count) {
    return '$count linked student(s) have not yet confirmed their link: they do not appear here until they accept it from their account.';
  }

  @override
  String tutoringAssignResponse(Object note) {
    return 'Reply: “$note”';
  }

  @override
  String get tutoringAssignStudentsLabel => 'Beneficiary students';

  @override
  String get tutoringAssignSubjectHint => 'Subject (e.g. Mathematics)';

  @override
  String get tutoringAssignSubmit => 'Send the assignment';

  @override
  String get tutoringAssignTutor => 'Assign a tutor';

  @override
  String tutoringAssignedBy(Object name) {
    return 'assigned by $name';
  }

  @override
  String get tutoringAssignedLabel => 'Assigned:';

  @override
  String get tutoringAssignedTitle => 'Your assigned tutors';

  @override
  String get tutoringAssignedTutor => 'Assigned tutor';

  @override
  String get tutoringAssignedTutors => 'Assigned tutors';

  @override
  String get tutoringAvailability14 => 'Availability (next 14 days)';

  @override
  String get tutoringAvailableSlots => 'Available slots';

  @override
  String get tutoringAvailableSoon => 'Available within 48 hours';

  @override
  String tutoringBalanceNotCover(Object hint) {
    return 'The balance does not cover the price of this session. $hint';
  }

  @override
  String tutoringBaseRate(Object rate) {
    return 'Base rate: $rate XAF / h';
  }

  @override
  String get tutoringBook => 'Book';

  @override
  String get tutoringBookMonthly => 'Book monthly';

  @override
  String get tutoringBookSession => 'Book a session';

  @override
  String get tutoringBookedSessions => 'Booked sessions';

  @override
  String get tutoringBookingCancelled => 'Booking cancelled';

  @override
  String get tutoringBookingCreateError => 'Error while creating the booking.';

  @override
  String get tutoringBookingsDisputeError => 'Unable to send the report.';

  @override
  String get tutoringBookingsDisputeSent => 'Your report has been sent.';

  @override
  String get tutoringBookingsEmpty => 'No bookings yet.';

  @override
  String get tutoringBookingsLoadError => 'Unable to load your bookings.';

  @override
  String get tutoringBookingsTitle => 'My bookings';

  @override
  String get tutoringCalendarError => 'Unable to load availability.';

  @override
  String get tutoringCancellationPolicy => 'Cancellation policy';

  @override
  String get tutoringCheckNow => 'Check now';

  @override
  String get tutoringChooseDay => 'Choose a day';

  @override
  String tutoringClassName(Object name) {
    return 'Class $name';
  }

  @override
  String get tutoringDate => 'Date';

  @override
  String get tutoringDefaultName => 'WinPlus tutor';

  @override
  String get tutoringDiplomaVerified => 'Diploma verified';

  @override
  String get tutoringDispute => 'Dispute';

  @override
  String tutoringDisputeSentReason(Object reason) {
    return 'Report sent: $reason';
  }

  @override
  String get tutoringDisputeSession => 'Dispute the session';

  @override
  String tutoringDisputeUntil(Object date, Object time, Object hours) {
    return 'A problem? You can dispute until $date at $time ($hours h after the session). After that, the payment is released to the tutor.';
  }

  @override
  String get tutoringDurationHint =>
      'In 30-minute blocks, up to the end of the free period.';

  @override
  String get tutoringEndAssignment => 'End';

  @override
  String tutoringEndorsedBy(Object name) {
    return 'Endorsed by: $name';
  }

  @override
  String tutoringEndsAt(Object time) {
    return '· ends at $time';
  }

  @override
  String get tutoringEngAccept => 'Accept the commitment';

  @override
  String get tutoringEngAccepted =>
      'Commitment accepted: the sessions are confirmed.';

  @override
  String get tutoringEngAddSlot => 'Add a slot';

  @override
  String tutoringEngAutoFailed(Object reason) {
    return 'Automatic renewal not possible: $reason';
  }

  @override
  String get tutoringEngAutoOff => 'Automatic renewal turned off.';

  @override
  String get tutoringEngAutoOn => 'Automatic renewal turned on.';

  @override
  String get tutoringEngAutoRenew =>
      'Renew automatically every month from the balance';

  @override
  String tutoringEngAutoRenewAt(Object date) {
    return 'Attempt on $date, if the slots are still free and the balance is sufficient.';
  }

  @override
  String get tutoringEngAutoRenewHelp =>
      'Same slots. The attempt takes place 3 days before the end, after a reminder 7 days before; if the balance is not enough or a slot is no longer free, nothing is charged and you are notified.';

  @override
  String get tutoringEngAutoRenewIf =>
      'If the slots are still free and the balance is sufficient.';

  @override
  String get tutoringEngAutoRenewTitle => 'Automatic renewal from the balance';

  @override
  String get tutoringEngAutoRenewWalletOnly =>
      'Automatic renewal is only possible with payment from your balance.';

  @override
  String get tutoringEngAutoWalletOnly =>
      'Automatic renewal is only possible for a commitment paid from your balance.';

  @override
  String get tutoringEngCancel => 'Cancel the commitment';

  @override
  String get tutoringEngCancelPayerConfirm =>
      'Cancel? Past sessions remain due; each upcoming session is refunded according to the tutor\'s policy.';

  @override
  String get tutoringEngCancelSession => 'Cancel this session';

  @override
  String tutoringEngCancelSessionConfirm(Object date) {
    return 'Cancel only the session on $date?';
  }

  @override
  String get tutoringEngCancelTutorConfirm =>
      'Cancel? Upcoming sessions are fully refunded to the payer.';

  @override
  String get tutoringEngCancelled => 'Commitment cancelled, refunds credited.';

  @override
  String get tutoringEngCreateError => 'Unable to create the commitment.';

  @override
  String get tutoringEngDay => 'Day';

  @override
  String get tutoringEngDeclineConfirm =>
      'Decline the commitment? The payer is fully refunded.';

  @override
  String get tutoringEngDeclined =>
      'Commitment declined: the payer is refunded.';

  @override
  String tutoringEngDiscountNote(Object percent, Object amount) {
    return 'Monthly discount $percent% ($amount XAF). ';
  }

  @override
  String get tutoringEngDisputePrompt => 'Why are you disputing this session?';

  @override
  String tutoringEngDisputeUntil(Object date) {
    return 'dispute possible until $date';
  }

  @override
  String get tutoringEngDisputed =>
      'Session disputed: support will review it. The other sessions are not blocked.';

  @override
  String get tutoringEngEditSlots => 'Change the slots';

  @override
  String get tutoringEngExplainProblem => 'Explain the problem';

  @override
  String tutoringEngFeesNote(Object amount) {
    return ' Mobile Money fees deducted from refunds: $amount XAF.';
  }

  @override
  String get tutoringEngFirstDay => 'First day';

  @override
  String get tutoringEngHeld => 'Held';

  @override
  String get tutoringEngIntro =>
      'The same slots every week for 4 weeks, paid in advance';

  @override
  String tutoringEngIntroDiscount(Object percent) {
    return ', with a $percent% monthly discount';
  }

  @override
  String get tutoringEngIntroEnd =>
      '. The tutor is paid session by session, after each completed session.';

  @override
  String get tutoringEngMarkedCompleted => 'Session marked as completed.';

  @override
  String get tutoringEngMmSent => 'Payment request sent to your phone.';

  @override
  String get tutoringEngMomoChip => 'Mobile Money (MTN MoMo or Orange Money)';

  @override
  String get tutoringEngMoneyFlow =>
      'The money is paid to the tutor session by session, after each session that is completed and not disputed.';

  @override
  String tutoringEngMonthlyDiscount(Object percent) {
    return 'Monthly discount ($percent%)';
  }

  @override
  String get tutoringEngNotFound => 'Commitment not found.';

  @override
  String get tutoringEngNotOffered =>
      'This tutor does not offer the monthly commitment.';

  @override
  String get tutoringEngPaidAdvance => 'Paid in advance';

  @override
  String tutoringEngPaidByLine(Object subject, Object payer, Object method) {
    return '$subject · paid by $payer · $method';
  }

  @override
  String get tutoringEngPayMonth => 'Pay for the month';

  @override
  String get tutoringEngPaymentNotConfirmed => 'Payment not confirmed';

  @override
  String get tutoringEngPaymentPending => 'Payment awaiting confirmation';

  @override
  String get tutoringEngPaymentReceived =>
      'Payment received, awaiting the tutor';

  @override
  String tutoringEngPerMonth(Object count) {
    return '$count sessions over the month, checked against the tutor\'s calendar.';
  }

  @override
  String get tutoringEngPhoneFormat =>
      'Mobile Money number: 9 digits (e.g. 670000000).';

  @override
  String get tutoringEngQuoteError => 'Unable to calculate the quote.';

  @override
  String get tutoringEngQuoteHelp =>
      'The tutor accepts or declines the whole commitment; if they decline or do not reply, everything is refunded. The money stays held and is only paid to the tutor session by session. If you cancel, the policy above applies to each upcoming session.';

  @override
  String tutoringEngQuoteRange(Object from, Object to, Object count) {
    return 'From $from to $to · $count sessions';
  }

  @override
  String tutoringEngQuoteStudents(Object count) {
    return ' · $count students';
  }

  @override
  String get tutoringEngQuoteUnavailable => 'Quote unavailable.';

  @override
  String tutoringEngRangeSummary(Object from, Object to, Object slots) {
    return 'From $from to $to · $slots';
  }

  @override
  String tutoringEngReason(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String tutoringEngRefundedAmount(Object amount) {
    return '$amount XAF refunded';
  }

  @override
  String get tutoringEngRefundedTile => 'Refunded';

  @override
  String get tutoringEngReleased => 'Paid to the tutor';

  @override
  String get tutoringEngRemoveSlot => 'Remove this slot';

  @override
  String get tutoringEngRenewMm => 'Renew by Mobile Money';

  @override
  String get tutoringEngRenewWallet => 'Renew (pay from balance)';

  @override
  String get tutoringEngRenewal => 'Renewal';

  @override
  String get tutoringEngRenewedWallet =>
      'Next month booked and paid from your balance.';

  @override
  String tutoringEngReplyBefore(Object date) {
    return 'Reply before $date';
  }

  @override
  String tutoringEngSameSlots(Object date) {
    return 'Same slots from $date. Manual by default; reminder 7 days before the end.';
  }

  @override
  String get tutoringEngSeeEngagement => 'View the commitment';

  @override
  String get tutoringEngSeeNextMonth => 'View the next month';

  @override
  String get tutoringEngSeeQuote => 'View the quote for the month';

  @override
  String get tutoringEngSessionCancelled => 'Session cancelled.';

  @override
  String tutoringEngSessions(Object done, Object total) {
    return 'Sessions ($done completed out of $total)';
  }

  @override
  String get tutoringEngSomeUnavailable =>
      'Some sessions are not available: change the day, the time or the start date.';

  @override
  String get tutoringEngStagePayment => 'Advance payment';

  @override
  String get tutoringEngStagePlan => 'Monthly commitment';

  @override
  String get tutoringEngStageQuote => 'Quote for the month';

  @override
  String get tutoringEngStageSuccess => 'Commitment paid';

  @override
  String get tutoringEngStart => 'Start';

  @override
  String get tutoringEngSubtotal => 'Subtotal (tutor\'s grid)';

  @override
  String tutoringEngSuccessText(Object count, Object from, Object to) {
    return '$count sessions from $from to $to. The tutor must accept the whole commitment; if they decline or do not reply in time, everything is refunded to the payer\'s WinPlus wallet.';
  }

  @override
  String tutoringEngTileTotal(Object amount, Object done, Object total) {
    return '$amount XAF · $done/$total sessions completed';
  }

  @override
  String get tutoringEngTotalAdvance => 'Total paid in advance';

  @override
  String get tutoringEngValidateOnPhone => 'Confirm the payment on your phone';

  @override
  String tutoringEngWalletMissing(Object amount) {
    return 'Insufficient balance: $amount XAF missing.';
  }

  @override
  String get tutoringEngWalletShort =>
      'The balance does not cover the month\'s total. Choose Mobile Money or top up the wallet.';

  @override
  String get tutoringEngWeeklySlots => 'Weekly slots';

  @override
  String tutoringEngWith(Object name) {
    return 'With $name';
  }

  @override
  String get tutoringEngagementsTitle => 'Monthly commitments';

  @override
  String get tutoringEveryDay => 'every day';

  @override
  String get tutoringFilterInPerson => 'In person (verified)';

  @override
  String get tutoringFilterNeutralPlace => 'Neutral place';

  @override
  String get tutoringFilterStudentHome => 'At my home';

  @override
  String get tutoringForMe => 'For me';

  @override
  String get tutoringForStudentsTitle => 'Tutoring for my students';

  @override
  String get tutoringForWhomGroupHelp =>
      'You pay for the group session (your balance or Mobile Money) and receive any refund.';

  @override
  String tutoringForWhomInstitutionHelp(Object count) {
    return '$count student(s) selected. Paid from the school wallet or Mobile Money.';
  }

  @override
  String tutoringForWhomMaxGroup(Object count) {
    return 'This tutor accepts at most $count students per session.';
  }

  @override
  String get tutoringForWhomNoChild =>
      'No child linked to your account (the link must be accepted by the child).';

  @override
  String get tutoringForWhomNoGroup =>
      'This tutor does not offer group sessions: choose a single student.';

  @override
  String tutoringForWhomNoStudent(Object name) {
    return 'No active student linked to $name.';
  }

  @override
  String get tutoringForWhomParentHelp =>
      'You pay with your parent wallet or Mobile Money; your children see the session in their space.';

  @override
  String tutoringForWhomPendingConfirmation(Object count) {
    return '$count linked student(s) do not appear: they must first confirm their link to the school from their account (My network).';
  }

  @override
  String get tutoringForWhomTitle => 'Who is it for?';

  @override
  String get tutoringFrom => 'from';

  @override
  String tutoringFromDuration(Object duration, Object percent) {
    return 'From $duration: −$percent%';
  }

  @override
  String tutoringGroupDiscount(Object percent) {
    return 'Group price: −$percent% per student';
  }

  @override
  String get tutoringGroupEachPays =>
      'Each student pays the price of a one-to-one session.';

  @override
  String tutoringGroupFlat(Object count) {
    return 'Fixed group price ($count students)';
  }

  @override
  String tutoringGroupFlatHint(Object percent, Object amount) {
    return '$percent% of the individual price · ≈ $amount XAF per student';
  }

  @override
  String tutoringGroupFlatSummary(Object percent) {
    return 'Fixed price for the group: $percent% of the price of a one-to-one session.';
  }

  @override
  String tutoringGroupFromSize(Object count, Object percent) {
    return 'From $count students: −$percent% per student';
  }

  @override
  String tutoringGroupName(Object name) {
    return 'Group: $name';
  }

  @override
  String tutoringGroupUpTo(Object count) {
    return 'Group sessions for up to $count students.';
  }

  @override
  String get tutoringInPersonPossible => 'In person possible';

  @override
  String get tutoringInPersonVerified => 'Verified for in-person lessons';

  @override
  String get tutoringInstitutionWalletHelp =>
      'Shared by all the school\'s accounts: it is topped up by Mobile Money, pays for sessions and receives refunds. It cannot be withdrawn to Mobile Money.';

  @override
  String get tutoringIntroVideo => 'Introduction video';

  @override
  String get tutoringLeaveReview => 'Leave a review';

  @override
  String get tutoringLevels => 'Levels';

  @override
  String tutoringLongSession(Object percent) {
    return 'Long session (−$percent%)';
  }

  @override
  String get tutoringMatAddExercise => 'Add an exercise';

  @override
  String get tutoringMatAddPart => 'Add a part';

  @override
  String get tutoringMatAddQuestion => 'Add a question';

  @override
  String tutoringMatAnswerLine(Object title, Object answer) {
    return '$title: $answer';
  }

  @override
  String get tutoringMatAnswersSent => 'Answers sent to your tutor.';

  @override
  String get tutoringMatChanged => 'Changed since sharing';

  @override
  String get tutoringMatCourse => 'Lesson';

  @override
  String get tutoringMatDraftSaved => 'Draft saved.';

  @override
  String get tutoringMatEasy => 'Easy';

  @override
  String get tutoringMatEditTitle => 'Edit the material';

  @override
  String tutoringMatExample(Object text) {
    return 'Example: $text';
  }

  @override
  String tutoringMatExerciseN(Object n) {
    return 'Exercise $n';
  }

  @override
  String get tutoringMatExercises => 'Exercises';

  @override
  String get tutoringMatExercisesSubmitted => 'Exercises submitted';

  @override
  String tutoringMatFieldAnswer(Object id) {
    return 'Answer $id';
  }

  @override
  String get tutoringMatFieldContent => 'Content';

  @override
  String get tutoringMatFieldExample => 'Example (optional)';

  @override
  String get tutoringMatFieldExplanation => 'Explanation';

  @override
  String get tutoringMatFieldHints => 'Hints (one per line)';

  @override
  String get tutoringMatFieldKeyPoints => 'Key points (one per line)';

  @override
  String get tutoringMatFieldObjectives => 'Objectives (one per line)';

  @override
  String get tutoringMatFieldPartTitle => 'Part title';

  @override
  String get tutoringMatFieldSolution =>
      'Worked solution (visible after the student answers)';

  @override
  String get tutoringMatFieldStatement => 'Question text';

  @override
  String get tutoringMatFieldTitle => 'Title';

  @override
  String get tutoringMatGenerate => 'Generate with WinAI';

  @override
  String get tutoringMatGenerateHelp =>
      'WinAI prepares a lesson, a quiz and exercises from the session topics. The generation is counted against your WinAI usage; nothing is sent to the students before you share.';

  @override
  String get tutoringMatGenerated =>
      'Material generated: review it before sharing.';

  @override
  String tutoringMatGroupPrefix(Object count) {
    return 'Group ($count students): ';
  }

  @override
  String get tutoringMatHard => 'Hard';

  @override
  String get tutoringMatHints => 'Hints';

  @override
  String get tutoringMatInstructionsHint =>
      'Instructions for WinAI (optional): “more exercises”, “simpler level”…';

  @override
  String get tutoringMatMedium => 'Medium';

  @override
  String get tutoringMatNoAnswer => 'No answers yet.';

  @override
  String get tutoringMatNotFound => 'Material not found.';

  @override
  String get tutoringMatNotShared =>
      'The tutor has not shared any material for this session yet.';

  @override
  String tutoringMatNotYet(Object names) {
    return 'Not answered yet: $names';
  }

  @override
  String get tutoringMatObjectives => 'Objectives';

  @override
  String get tutoringMatOutdated => 'Answers to a previous version';

  @override
  String tutoringMatPart(Object n) {
    return 'Part $n';
  }

  @override
  String tutoringMatQuizCount(Object count) {
    return 'Quiz ($count questions)';
  }

  @override
  String get tutoringMatReadOnly =>
      'View only: the students answer the quiz and exercises in their own account.';

  @override
  String get tutoringMatRegenerate => 'Regenerate';

  @override
  String get tutoringMatRegenerateConfirm =>
      'Regenerating replaces your current draft (the shared version stays visible until the next share). Continue?';

  @override
  String get tutoringMatResults => 'Results';

  @override
  String get tutoringMatSaveDraft => 'Save the draft';

  @override
  String get tutoringMatShare => 'Share with the students';

  @override
  String get tutoringMatShareNew => 'Share the new version';

  @override
  String get tutoringMatShared => 'Shared';

  @override
  String get tutoringMatSharedToast =>
      'Material shared with the students and the payer.';

  @override
  String tutoringMatSolution(Object solution) {
    return 'Worked solution: $solution';
  }

  @override
  String get tutoringMatStudentAnswers => 'Students\' answers';

  @override
  String get tutoringMatStudentPrefix => 'Student: ';

  @override
  String get tutoringMatSubmit => 'Send my answers';

  @override
  String get tutoringMatSummary => 'Key takeaways';

  @override
  String tutoringMatUnanswered(Object count) {
    return '$count unanswered question(s). Send anyway? You will no longer be able to change your answers.';
  }

  @override
  String tutoringMatYourAnswer(Object answer) {
    return 'Your answer: $answer';
  }

  @override
  String get tutoringMatYourAnswerHint => 'Your answer…';

  @override
  String get tutoringMaterial => 'Session material';

  @override
  String get tutoringMaterialFull => 'Material, quiz and exercises';

  @override
  String get tutoringMe => 'Me';

  @override
  String get tutoringMode => 'Mode';

  @override
  String get tutoringModeAll => 'all formats';

  @override
  String get tutoringModeInPerson => 'in person';

  @override
  String get tutoringModeNeutralPlace => 'Neutral place';

  @override
  String get tutoringModeOnlineLower => 'online';

  @override
  String get tutoringModeStudentHome => 'At home';

  @override
  String get tutoringModeStudentHomeMine => 'At home (my place)';

  @override
  String get tutoringModeTutorHome => 'At the tutor\'s';

  @override
  String tutoringModifierLine(Object label, Object when, Object adjust) {
    return '$label ($when): $adjust';
  }

  @override
  String get tutoringMomoHint => 'MTN MoMo or Orange Money';

  @override
  String get tutoringMomoNumber => 'Mobile Money number';

  @override
  String get tutoringMonthly => 'Monthly';

  @override
  String get tutoringMonthlyText =>
      'Same slots every week for 4 weeks, paid in advance and paid to the tutor session by session.';

  @override
  String get tutoringMustAccept =>
      'The tutor must accept your request. You will be notified as soon as they reply, and fully refunded to your WinPlus wallet if they decline or do not reply in time.';

  @override
  String tutoringMyRating(Object rating) {
    return 'Your rating: $rating/5';
  }

  @override
  String get tutoringNoAssignment => 'No assignments yet.';

  @override
  String get tutoringNoModeConfigured =>
      'This tutor has not set up a session mode yet.';

  @override
  String get tutoringNoReviewsYet => 'No reviews yet';

  @override
  String get tutoringNoSlotAvailable => 'No slots available for now.';

  @override
  String get tutoringNoSlotThatDay => 'No slots that day.';

  @override
  String get tutoringNotSpecified => 'Not specified';

  @override
  String get tutoringOnlineOnly => 'Online only';

  @override
  String get tutoringPay => 'Pay';

  @override
  String tutoringPayAmount(Object amount) {
    return 'Pay $amount XAF';
  }

  @override
  String get tutoringPayMethod => 'Payment method';

  @override
  String get tutoringPayNow => 'Pay now';

  @override
  String get tutoringPayWithBalance => 'Pay with my balance';

  @override
  String get tutoringPayWithInstitutionWallet => 'Pay with the school wallet';

  @override
  String get tutoringPayWithParentWallet => 'Pay with my parent wallet';

  @override
  String get tutoringPaymentNotConfirmed =>
      'The payment could not be confirmed.';

  @override
  String get tutoringPaymentReceivedAwaiting =>
      'Payment received, awaiting the tutor';

  @override
  String get tutoringPaymentSlow =>
      'The payment is taking longer than expected. You can check later in \"My sessions\".';

  @override
  String get tutoringPerHour => '/ hour';

  @override
  String tutoringPerStudentLine(Object count, Object amount) {
    return '$count students × $amount XAF';
  }

  @override
  String tutoringPercent(Object value) {
    return '$value%';
  }

  @override
  String get tutoringPhoneHint =>
      'Cameroon number without country code (e.g. 670000000).';

  @override
  String get tutoringPhoneInvalid => 'Invalid phone number.';

  @override
  String get tutoringPolicyCardTitle => 'This tutor\'s cancellation policy';

  @override
  String tutoringPolicyDispute(Object hours) {
    return 'After the session, you have $hours h to dispute it.';
  }

  @override
  String get tutoringPolicyFactDispute => 'to dispute a session';

  @override
  String get tutoringPolicyFactFee =>
      'Mobile Money fees if you cancel yourself';

  @override
  String get tutoringPolicyFactImmediate => 'Immediate';

  @override
  String get tutoringPolicyFactRefund => 'refund to the wallet';

  @override
  String tutoringPolicyFull(Object hours) {
    return 'Full refund if you cancel at least $hours h before the session.';
  }

  @override
  String get tutoringPolicyIntro =>
      'The rules that apply to all private tutoring sessions booked on WinPlus.';

  @override
  String get tutoringPolicyLoadError => 'The policy could not be loaded.';

  @override
  String tutoringPolicyNone(Object hours) {
    return 'No refund if less than $hours h before.';
  }

  @override
  String tutoringPolicyPartial(Object percent, Object min, Object max) {
    return '$percent% refunded between $min h and $max h before.';
  }

  @override
  String get tutoringPolicyRead => 'Read the tutoring policy';

  @override
  String get tutoringPolicyTutorCancels =>
      'If the tutor cancels, declines or does not reply: full refund.';

  @override
  String get tutoringPolicyUntilStart =>
      'Refund possible until the session starts.';

  @override
  String tutoringPolicyVersion(Object date) {
    return 'Version of $date.';
  }

  @override
  String get tutoringPolicyWallet =>
      'Refunds paid immediately into your WinPlus wallet.';

  @override
  String tutoringPolicyWalletFee(Object fee) {
    return 'Refunds paid immediately into your WinPlus wallet. If you cancel a session paid by Mobile Money, $fee% operator fees are deducted; no fees for a payment from your balance.';
  }

  @override
  String get tutoringPrice => 'Price';

  @override
  String get tutoringPriceUnavailable => 'Price unavailable.';

  @override
  String get tutoringPrivateLessons => 'Private lessons';

  @override
  String get tutoringProfileLoadError => 'Unable to load this profile.';

  @override
  String get tutoringProrata => 'Billed pro rata in 30-minute blocks.';

  @override
  String get tutoringQuoteError => 'Unable to calculate the price.';

  @override
  String tutoringRateFrom(Object amount) {
    return 'from $amount XAF/h';
  }

  @override
  String tutoringRateLine(Object subject, Object mode, Object rate) {
    return '$subject · $mode: $rate XAF / h';
  }

  @override
  String get tutoringRateNa => 'Rate N/A';

  @override
  String get tutoringRateNotGiven => 'Rate not given';

  @override
  String get tutoringRatesPackages => 'Rates & packages';

  @override
  String tutoringRatingReviews(Object rating, Object count) {
    return '$rating/5 ($count reviews)';
  }

  @override
  String get tutoringReasonOptional => 'Reason (optional)';

  @override
  String tutoringRechargeAmount(Object amount) {
    return 'Amount (minimum $amount FCFA)';
  }

  @override
  String get tutoringRechargeConfirmOnPhone =>
      'Confirm the payment on your phone; the balance updates as soon as it is confirmed.';

  @override
  String get tutoringRechargeConfirmed =>
      'Top-up confirmed: the school\'s balance is up to date.';

  @override
  String get tutoringRechargeFailed =>
      'The top-up did not go through: no amount was charged.';

  @override
  String get tutoringRechargePending =>
      'Top-up awaiting confirmation on the phone…';

  @override
  String get tutoringRechargePhone => 'Number (6XXXXXXXX)';

  @override
  String get tutoringRechargeStartError => 'The top-up could not be started.';

  @override
  String get tutoringRechargeStillPending =>
      'Top-up still pending: pull down to refresh the balance later.';

  @override
  String get tutoringRechargeTitle => 'Top up the wallet';

  @override
  String tutoringReference(Object ref) {
    return 'Ref.: $ref';
  }

  @override
  String get tutoringReportChooseReason => 'Choose a reason.';

  @override
  String get tutoringReportDescribe =>
      'Describe what happened (at least 10 characters).';

  @override
  String get tutoringReportDescriptionOptional => 'Description (optional)';

  @override
  String get tutoringReportIntro =>
      'Your report is sent to the WinPlus team, who will review it. The tutor does not see who reported them. For a refund, use “Dispute the session” instead.';

  @override
  String tutoringReportName(Object name) {
    return 'Report $name';
  }

  @override
  String get tutoringReportPlaceholder => 'What happened, when, how.';

  @override
  String get tutoringReportProblem => 'Report a problem';

  @override
  String get tutoringReportProblemHint =>
      'Describe the problem you had during this session.';

  @override
  String get tutoringReportProblemPlaceholder =>
      'E.g. the tutor didn\'t show up…';

  @override
  String get tutoringReportReason => 'Reason';

  @override
  String get tutoringReportSentTeam => 'Tutor report sent to the WinPlus team.';

  @override
  String get tutoringReportSubmit => 'Send the report';

  @override
  String get tutoringReportTutor => 'Report the tutor';

  @override
  String get tutoringReviewChooseRating => 'Choose a rating before sending.';

  @override
  String get tutoringReviewCommentHint =>
      'Comment (optional, 300 characters max)';

  @override
  String get tutoringReviewSubmit => 'Send my review';

  @override
  String get tutoringReviewThanks => 'Thank you for your review!';

  @override
  String get tutoringSearchEmpty => 'No tutor found for these criteria.';

  @override
  String get tutoringSearchLoadError => 'Unable to load the tutors.';

  @override
  String get tutoringSearchStudent => 'Search for a student';

  @override
  String get tutoringSearchTopicsHint =>
      'Topics to work on (e.g. derivatives, essay writing)';

  @override
  String get tutoringSending => 'Sending…';

  @override
  String get tutoringSession => 'Session';

  @override
  String get tutoringSessionConfirmed => 'Session confirmed!';

  @override
  String get tutoringSessionMode => 'Session mode';

  @override
  String get tutoringShortfallInstitution =>
      'Choose Mobile Money or top up the school wallet (Tutoring screen).';

  @override
  String get tutoringShortfallMine => 'Choose Mobile Money.';

  @override
  String get tutoringShortfallParent =>
      'Choose Mobile Money or top up your parent wallet.';

  @override
  String get tutoringSlotGone => 'This slot is no longer available.';

  @override
  String get tutoringSoloPrice => 'Price for one student';

  @override
  String get tutoringStatusCancelled => 'Cancelled';

  @override
  String get tutoringStatusCompleted => 'Completed';

  @override
  String get tutoringStatusConfirmed => 'Confirmed';

  @override
  String get tutoringStatusDisputed => 'Disputed';

  @override
  String get tutoringStatusExpired => 'Expired';

  @override
  String get tutoringStatusPendingPayment => 'Payment in progress';

  @override
  String get tutoringStatusPendingTutor => 'Awaiting the tutor';

  @override
  String get tutoringStatusRejected => 'Declined';

  @override
  String get tutoringStepChooseSlot => 'Choose a slot';

  @override
  String get tutoringStepPayment => 'Payment';

  @override
  String get tutoringStepRecap => 'Summary';

  @override
  String get tutoringStepSlot => 'Slot';

  @override
  String get tutoringStillWaiting => 'Still pending';

  @override
  String tutoringStudentFallback(Object id) {
    return 'Student #$id';
  }

  @override
  String tutoringStudentsCountPrefix(Object count) {
    return '$count student(s): ';
  }

  @override
  String tutoringStudentsN(Object count) {
    return 'Students ($count)';
  }

  @override
  String get tutoringSubjectEconomics => 'Economics';

  @override
  String get tutoringSubjects => 'Subjects';

  @override
  String get tutoringSubjectsLevels => 'Subjects & levels';

  @override
  String get tutoringSubtotal => 'Subtotal';

  @override
  String get tutoringTheTutor => 'the tutor';

  @override
  String get tutoringTime => 'Time';

  @override
  String get tutoringTopUp => 'Top up';

  @override
  String get tutoringTopics => 'Topics';

  @override
  String get tutoringTopicsHelp =>
      'The tutor will see them in your request to prepare the session.';

  @override
  String get tutoringTopicsOptional => 'Topics to work on (optional)';

  @override
  String get tutoringTopicsPlaceholder => 'e.g. quadratic equations';

  @override
  String get tutoringTotal => 'Total';

  @override
  String get tutoringTotalGroup => 'Total (group)';

  @override
  String get tutoringTrialFree => 'Free trial session';

  @override
  String tutoringTrialPrice(Object amount) {
    return 'Trial session: $amount XAF';
  }

  @override
  String get tutoringTutor => 'Tutor';

  @override
  String get tutoringTutoring => 'Tutoring';

  @override
  String get tutoringUnavailable => 'Unavailable';

  @override
  String get tutoringUnavailableParen => '(unavailable)';

  @override
  String get tutoringUnavailableShort => '(unavail.)';

  @override
  String get tutoringViewMySession => 'View my session';

  @override
  String get tutoringWaitingConfirmation => 'Awaiting confirmation…';

  @override
  String get tutoringWaitingUssd =>
      'Confirm the payment through the USSD message sent to your phone.';

  @override
  String tutoringWalletAvailable(Object amount) {
    return 'Available: $amount XAF';
  }

  @override
  String get tutoringWalletInstitution => 'School wallet';

  @override
  String get tutoringWalletLoading => 'Reading balance…';

  @override
  String get tutoringWalletMine => 'My WinPlus balance';

  @override
  String get tutoringWalletMineGroup =>
      'My WinPlus balance (I pay for the group)';

  @override
  String tutoringWalletMissing(Object amount, Object hint) {
    return 'Insufficient balance: $amount XAF missing. $hint';
  }

  @override
  String get tutoringWalletOk =>
      'Instant payment with no fees. Your request goes straight to the tutor.';

  @override
  String get tutoringWalletParent => 'My parent wallet';

  @override
  String get tutoringWalletUnavailable => 'Balance unavailable';

  @override
  String get tutoringWinplusBalance => 'WinPlus balance';

  @override
  String tutoringWithName(Object name) {
    return 'with $name';
  }

  @override
  String get tutoringYourInstitution => 'your school';

  @override
  String get tutoringYourTutor => 'your tutor';

  @override
  String get welcomeTagline => 'Your success, our mission';

  @override
  String get widgetKbOff =>
      ' · off. Turning it on searches the courses and your files, but uses more tokens.';

  @override
  String get widgetKbOn => ' · on: each message uses noticeably more tokens.';

  @override
  String get widgetKbTitle => 'Knowledge base';

  @override
  String get widgetMemDeleteFailed => 'Deletion failed.';

  @override
  String get widgetMemDifficulty => 'Difficulty';

  @override
  String get widgetMemEmpty =>
      'WinAI hasn\'t remembered anything yet. Keep interacting!';

  @override
  String get widgetMemExam => 'Exam';

  @override
  String get widgetMemLoadError => 'Unable to load memories.';

  @override
  String get widgetMemMastered => 'Mastered';

  @override
  String get widgetMemMemory => 'Memory';

  @override
  String get widgetMemMotivation => 'Motivation';

  @override
  String get widgetMemPreference => 'Preference';

  @override
  String get widgetMemRefresh => 'Refresh';

  @override
  String get widgetMemSubtitle => 'What WinAI has remembered about you';

  @override
  String widgetOfflineBanner(Object when) {
    return 'Offline, last updated: $when';
  }

  @override
  String get widgetOfflineUnknown => 'unknown';

  @override
  String get wrongCredentials => 'Incorrect email or password.';

  @override
  String get instMonthlyReportTitle => 'Monthly report by email';

  @override
  String get instMonthlyReportSub => 'Sent by email on the 1st of each month';

  @override
  String get instMonthlyReportMeta =>
      'The month\'s figures, homework, announcements, report cards, students to follow up and the WinAI action plan.';

  @override
  String get instMonthlyReportSendNow => 'Get it now';

  @override
  String get instMonthlyReportSending => 'Sending…';

  @override
  String get instMonthlyReportSent =>
      'Sent: check your inbox (and your spam folder).';

  @override
  String get instMonthlyReportError => 'Sending failed. Try again in a moment.';

  @override
  String get instMonthlyReportNoEmail =>
      'There is no email address on this account.';

  @override
  String get studentPdfLoadError => 'The document couldn\'t be loaded.';

  @override
  String get studentPlayerTapToOpen => 'Tap to open the document';

  @override
  String get studentPlayerOpenOnWeb =>
      'This type of file opens on the winplus.cm website.';

  @override
  String get studentCertCopyLink => 'Copy link';

  @override
  String get studentCertLinkCopied => 'Verification link copied.';

  @override
  String get mobileHomeForYou => 'For you';

  @override
  String get mobileHomeFilters => 'Filters';

  @override
  String get mobileHomeSeeAll => 'See all';

  @override
  String get mobileHomeQuick => 'Quick access';

  @override
  String get mobileHomeAllShortcuts => 'All shortcuts';

  @override
  String get mobileHomeStatsDetail => 'See details';

  @override
  String get mobileHomeStatsTitle => 'My statistics';

  @override
  String get mobileHomeClose => 'Close';

  @override
  String get mobileHomeEyebrow => 'To do now';

  @override
  String mobileHomeSlide(int n, int total) {
    return 'Card $n of $total';
  }

  @override
  String get mobileHomeSearchPaper => 'Search for a paper…';

  @override
  String get mobileHomeSearchStudent => 'Search for a student…';

  @override
  String get mobileHomeStudentTitle => 'Your session for today';

  @override
  String get mobileHomeStudentMeta => '20 minutes on your weak spots.';

  @override
  String get mobileHomeStudentCta => 'Start';

  @override
  String get mobileHomeResumeTag => 'In progress';

  @override
  String get mobileHomeResumeTitle => 'Pick up where you left off';

  @override
  String get mobileHomeResumeMeta => 'The papers and quizzes you started.';

  @override
  String get mobileHomeResumeCta => 'Resume';

  @override
  String get mobileHomeCoachTag => 'Exam coach';

  @override
  String get mobileHomeCoachTitle => 'Your plan up to exam day';

  @override
  String get mobileHomeCoachMeta => 'Your exam, your date: we plan everything.';

  @override
  String get mobileHomeCoachCta => 'Create';

  @override
  String get mobileHomePapersTag => 'New';

  @override
  String get mobileHomePapersTitle => 'Past papers and answers';

  @override
  String get mobileHomePapersMeta => 'BEPC, Probatoire, Bac, entrance exams.';

  @override
  String get mobileHomePapersCta => 'See';

  @override
  String get mobileHomeQuiz => 'Quizzes';

  @override
  String get mobileHomePapers => 'Papers';

  @override
  String get mobileHomeRevisions => 'Revision';

  @override
  String get mobileHomeGroups => 'Groups';

  @override
  String get mobileHomeLinkTitle => 'Link your child\'s account';

  @override
  String get mobileHomeLinkMeta =>
      'You can then follow their revision and results.';

  @override
  String get mobileHomeAddChild => 'Add';

  @override
  String mobileHomeFollowTitle(String name) {
    return 'How $name is doing this week';
  }

  @override
  String get mobileHomeFollowMeta => 'Consistency, results, points to work on.';

  @override
  String get mobileHomeFollowCta => 'See';

  @override
  String get mobileHomeYourChild => 'your child';

  @override
  String get mobileHomeTutorTag => 'Private lessons';

  @override
  String get mobileHomeTutorTitle => 'A tutor near you';

  @override
  String get mobileHomeTutorMeta => 'Verified profiles, at home or online.';

  @override
  String get mobileHomeTutorCta => 'Find';

  @override
  String get mobileHomeSheetTag => 'WinAI';

  @override
  String get mobileHomeSheetTitle => 'A tailor-made revision sheet';

  @override
  String get mobileHomeSheetMeta => 'On the subject your child is stuck on.';

  @override
  String get mobileHomeSheetCta => 'Create';

  @override
  String get mobileHomeSheetPrompt =>
      'Prepare a revision sheet on the subject my child struggles with most.';

  @override
  String get mobileHomeSuivi => 'Progress';

  @override
  String get mobileHomeMessages => 'Messages';

  @override
  String get mobileHomeAdvice => 'Advice';

  @override
  String get mobileHomeSubscription => 'Subscription';

  @override
  String get mobileHomeBuy => 'Buy';

  @override
  String get mobileHomeAdviceCount => 'WinAI advice';

  @override
  String get mobileHomeChildrenAvg => 'Children\'s average';

  @override
  String mobileHomeCorrectTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count papers to mark',
      one: '$count paper to mark',
    );
    return '$_temp0';
  }

  @override
  String get mobileHomeCorrectMeta =>
      'Your students are waiting for their mark.';

  @override
  String get mobileHomeCorrectCta => 'Mark';

  @override
  String get mobileHomePublishTitle => 'Share new content';

  @override
  String get mobileHomePublishMeta => 'Your students find it straight away.';

  @override
  String get mobileHomePublishCta => 'Publish';

  @override
  String get mobileHomeTeachTutorTag => 'Extra income';

  @override
  String get mobileHomeTeachTutorTitle => 'Turn on tutor mode';

  @override
  String get mobileHomeTeachTutorMeta => 'Offer private lessons.';

  @override
  String get mobileHomeTeachTutorCta => 'Turn on';

  @override
  String get mobileHomeCoursesTag => 'Courses';

  @override
  String get mobileHomeCoursesTitle => 'Build a full course';

  @override
  String get mobileHomeCoursesMeta => 'Modules, quizzes and a final exam.';

  @override
  String get mobileHomeCoursesCta => 'Open';

  @override
  String get mobileHomeClasses => 'Classes';

  @override
  String get mobileHomeCorrections => 'Marking';

  @override
  String get mobileHomeSessions => 'Sessions';

  @override
  String get mobileHomeRevenue => 'Earnings';

  @override
  String get mobileHomeShare => 'Your share';

  @override
  String get mobileHomeInstTitle => 'Students who need support';

  @override
  String get mobileHomeInstMeta =>
      'Falling consistency or results, class by class.';

  @override
  String get mobileHomeInstCta => 'See';

  @override
  String get mobileHomeReportTag => 'Report';

  @override
  String get mobileHomeReportTitle => 'Your school\'s report';

  @override
  String get mobileHomeReportMeta => 'A PDF ready to share.';

  @override
  String get mobileHomeReportCta => 'Export';

  @override
  String get mobileHomePlanTag => 'WinAI';

  @override
  String get mobileHomePlanTitle => 'An action plan for your classes';

  @override
  String get mobileHomePlanMeta => 'Concrete steps, class by class.';

  @override
  String get mobileHomePlanCta => 'Create';

  @override
  String get mobileHomeDirectory => 'Directory';

  @override
  String get mobileHomeAnalytics => 'Analytics';

  @override
  String get mobileHomeLicense => 'Licence';

  @override
  String get mobileHomeStatStudy => 'Study time';

  @override
  String get mobileHomeStatQuiz => 'Quizzes this week';

  @override
  String get mobileHomeStatStreak => 'Current streak';

  @override
  String get mobileHomeStatChildren => 'Children followed';

  @override
  String get mobileHomeStatCredits => 'Available credits';

  @override
  String get mobileHomeStatActive => 'Active students';

  @override
  String get mobileHomeThisWeek => 'This week';

  @override
  String mobileHomeDays(int n) {
    return '$n d';
  }

  @override
  String mobileHomeAtRiskMeta(int n) {
    return '$n students to watch closely, class by class.';
  }
}
