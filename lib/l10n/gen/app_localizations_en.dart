// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTagline => 'Your success, our mission';

  @override
  String get createAccount => 'Create an account';

  @override
  String get login => 'Log in';

  @override
  String get loginTitle => 'Welcome back!';

  @override
  String get loginSubtitle => 'Log in to your WinPlus account.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get noAccountYet => 'Don\'t have an account yet? ';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get wrongCredentials => 'Incorrect email or password.';

  @override
  String get language => 'Language';

  @override
  String switchToLanguage(String lang) {
    return 'Switch to $lang';
  }
}
