import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/auth_service.dart';

import '../helpers/faux_reseau.dart';

/// Lot 8 : la connexion refusée s'explique dans la langue de l'application
/// (le serveur répond en anglais : « Invalid email or password »).
void main() {
  late FauxReseau faux;
  setUp(() => faux = preparerEnvironnement());

  test('identifiants faux : message traduit, pas le texte anglais du serveur', () async {
    faux.repond('POST', '/auth/signin',
        {'error': 'Invalid email or password', 'errorCode': 'INVALID_CREDENTIALS'}, statut: 401);
    final r = await AuthService.instance.signIn('a@b.cm', 'x');
    expect(r.success, isFalse);
    expect(r.message, L10n.current.wrongCredentials);
  });

  test('codes du serveur et absence de reseau', () {
    final l = L10n.current;
    expect(AuthService.signInMessage(429, null), l.authErrTooManyAttempts);
    expect(AuthService.signInMessage(401, 'EMAIL_NOT_VERIFIED'), l.authErrEmailNotVerified);
    expect(AuthService.signInMessage(401, 'ACCOUNT_INACTIVE'), l.authErrAccountInactive);
    expect(AuthService.signInMessage(400, null), l.svcLoginFailed);
    expect(AuthService.signInMessage(null, null), l.authErrNetwork);
  });

  test('en anglais aussi', () async {
    L10n.locale = const Locale('en');
    faux.repond('POST', '/auth/signin', {'error': 'x'}, statut: 401);
    final r = await AuthService.instance.signIn('a@b.cm', 'x');
    expect(r.message, L10n.current.wrongCredentials);
  });
}
