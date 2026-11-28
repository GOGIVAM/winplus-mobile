import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/two_factor_service.dart';
import 'package:winplus/shell/two_factor_settings_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(f);
  await tester.tap(f);
  await reseau(tester);
}

// PNG 1x1 transparent.
const _qr = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const _codes = ['AAAA1111', 'BBBB2222', 'CCCC3333', 'DDDD4444', 'EEEE5555', 'FFFF6666', 'GGGG7777', 'HHHH8888'];

/// Reglages de la double authentification (contrat de winplus-api 2a006d2).
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('TwoFactorService', () {
    test('status, enable, verify, disable, backup-codes : champs et corps du contrat', () async {
      faux.repond('GET', '/users/2fa/status',
          {'isEnabled': true, 'method': 'totp', 'enabledAt': '2026-11-28T10:00:00Z', 'backupCodesCount': 6, 'pendingSetup': false});
      final st = await TwoFactorService.instance.status();
      expect(st.isEnabled, isTrue);
      expect(st.backupCodesCount, 6);
      expect(st.enabledAt, DateTime.utc(2026, 11, 28, 10));

      faux.repond('POST', '/users/2fa/enable',
          {'qrCode': _qr, 'secret': 'ABCDEFGH', 'secretGrouped': 'ABCD EFGH', 'otpauthUrl': 'otpauth://totp/WinPlus:ada?secret=ABCDEFGH'});
      final setup = await TwoFactorService.instance.enable();
      expect(setup.secretGrouped, 'ABCD EFGH');
      expect(setup.otpauthUrl, startsWith('otpauth://'));
      expect(setup.qrPng, isNotNull);

      faux.repond('POST', '/users/2fa/verify', {'success': true, 'backupCodes': _codes});
      expect(await TwoFactorService.instance.verify(' 123456 '), _codes);
      expect(faux.recues('POST', '/users/2fa/verify').single.data, {'code': '123456'});

      faux.repond('POST', '/users/2fa/disable', {'success': true});
      await TwoFactorService.instance.disable(password: 'secret', code: '654321');
      expect(faux.recues('POST', '/users/2fa/disable').single.data, {'password': 'secret', 'code': '654321'});
      await TwoFactorService.instance.disable(password: '', code: 'AAAA1111');
      expect(faux.recues('POST', '/users/2fa/disable').last.data, {'code': 'AAAA1111'});

      faux.repond('POST', '/users/2fa/backup-codes', {'success': true, 'backupCodes': _codes});
      expect(await TwoFactorService.instance.newBackupCodes('111111'), hasLength(8));
    });

    test('refus : message du serveur et code ; hors ligne : erreur reseau', () async {
      faux.repond('POST', '/users/2fa/verify',
          {'success': false, 'code': 'code_invalide', 'error': 'code_invalide', 'message': 'Code incorrect.'},
          statut: 400);
      await expectLater(
          TwoFactorService.instance.verify('000000'),
          throwsA(isA<TwoFactorException>()
              .having((e) => e.message, 'message', 'Code incorrect.')
              .having((e) => e.code, 'code', 'code_invalide')));
      faux.coupure('GET', '/users/2fa/status');
      await expectLater(TwoFactorService.instance.status(),
          throwsA(isA<TwoFactorException>().having((e) => e.message, 'message', L10n.current.commonNetworkError)));
    });
  });

  group('TwoFactorSettingsScreen', () {
    testWidgets('activation : cle et lien, premier code, codes de secours montres une fois, puis statut active', (tester) async {
      faux.repond('GET', '/users/2fa/status', {'isEnabled': false, 'backupCodesCount': 0});
      faux.repond('POST', '/users/2fa/enable',
          {'qrCode': _qr, 'secret': 'ABCDEFGH', 'secretGrouped': 'ABCD EFGH', 'otpauthUrl': 'otpauth://totp/x'});
      faux.repond('POST', '/users/2fa/verify', {'success': true, 'backupCodes': _codes});
      await monterEcran(tester, const TwoFactorSettingsScreen());
      final l = L10n.current;
      expect(find.text(l.twoFaDisabled), findsOneWidget);
      await _toucher(tester, _bouton(l.twoFaEnable));
      expect(find.text('ABCD EFGH'), findsOneWidget);
      expect(_bouton(l.twoFaOpenApp), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '123456');
      faux.repond('GET', '/users/2fa/status', {'isEnabled': true, 'backupCodesCount': 8});
      await _toucher(tester, _bouton(l.twoFaConfirm));
      expect(find.text('AAAA1111'), findsOneWidget);
      expect(find.text(l.twoFaBackupHint), findsOneWidget);
      expect(faux.recues('POST', '/users/2fa/verify').single.data, {'code': '123456'});
      await _toucher(tester, _bouton(l.twoFaDone));
      expect(find.text(l.twoFaBackupLeft(8)), findsOneWidget);
      expect(find.text('AAAA1111'), findsNothing);
    });

    testWidgets('premier code faux : message du serveur, on reste sur l activation', (tester) async {
      faux.repond('GET', '/users/2fa/status', {'isEnabled': false});
      faux.repond('POST', '/users/2fa/enable', {'secret': 'ABCDEFGH', 'secretGrouped': 'ABCD EFGH'});
      faux.repond('POST', '/users/2fa/verify', {'success': false, 'code': 'code_invalide', 'message': 'Code incorrect.'}, statut: 400);
      await monterEcran(tester, const TwoFactorSettingsScreen());
      await _toucher(tester, _bouton(L10n.current.twoFaEnable));
      await tester.enterText(find.byType(TextField).last, '000000');
      await _toucher(tester, _bouton(L10n.current.twoFaConfirm));
      expect(find.text('Code incorrect.'), findsOneWidget);
      expect(find.text('ABCD EFGH'), findsOneWidget);
    });

    testWidgets('activee : desactivation avec mot de passe et code, puis statut desactive', (tester) async {
      faux.repond('GET', '/users/2fa/status', {'isEnabled': true, 'backupCodesCount': 5});
      faux.repond('POST', '/users/2fa/disable', {'success': true});
      await monterEcran(tester, const TwoFactorSettingsScreen());
      final l = L10n.current;
      expect(find.text(l.twoFaBackupLeft(5)), findsOneWidget);
      await tester.tap(_bouton(l.twoFaDisable));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 300));
      final champs = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(champs.at(0), 'secret');
      await tester.enterText(champs.at(1), '654321');
      faux.repond('GET', '/users/2fa/status', {'isEnabled': false});
      await tester.tap(find.text(l.commonConfirm));
      await reseau(tester);
      expect(faux.recues('POST', '/users/2fa/disable').single.data, {'password': 'secret', 'code': '654321'});
      expect(find.text(l.twoFaDisabled), findsOneWidget);
    });

    testWidgets('statut en panne : erreur et bouton Reessayer', (tester) async {
      faux.repond('GET', '/users/2fa/status', {}, statut: 500);
      await monterEcran(tester, const TwoFactorSettingsScreen());
      expect(find.text(L10n.current.commonLoadError), findsOneWidget);
    });
  });
}
