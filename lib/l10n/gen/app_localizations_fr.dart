// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeTagline => 'Ta réussite, notre mission';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get login => 'Se connecter';

  @override
  String get loginTitle => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connecte-toi à ton compte WinPlus.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithPhone => 'Continuer avec le téléphone';

  @override
  String get noAccountYet => 'Pas encore de compte ? ';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String get wrongCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get language => 'Langue';

  @override
  String switchToLanguage(String lang) {
    return 'Passer en $lang';
  }
}
