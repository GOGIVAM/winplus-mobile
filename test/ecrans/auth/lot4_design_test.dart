import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/login_screen.dart';
import 'package:winplus/auth/role_screen.dart';
import 'package:winplus/auth/signup_screen.dart';
import 'package:winplus/auth/forgot_password_screen.dart';
import 'package:winplus/auth/reset_password_screen.dart';
import 'package:winplus/auth/verify_code_screen.dart';
import 'package:winplus/auth/complete_profile_screen.dart';
import 'package:winplus/auth/onboarding_success_screen.dart';
import 'package:winplus/auth/email_verified_screen.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/theme/win_theme.dart';
import 'package:winplus/widgets/win_widgets.dart';
import 'package:winplus/widgets/win_screen.dart';
import 'package:winplus/widgets/win_mascot.dart';
import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

void main() {
  setUpAll(() async {
    await initialiserDates();
    // Local review can load the real fonts; normal tests remain network-free.
    if (Platform.environment['LOT4_FONTS'] case final String folder) {
      for (final weight in [400, 500, 600, 700, 800, 900]) {
        final bytes = await File('$folder/Archivo_$weight.ttf').readAsBytes();
        await (FontLoader(weight == 400 ? 'Archivo_regular' : 'Archivo_$weight')
              ..addFont(Future.value(ByteData.sublistView(bytes))))
            .load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  setUp(preparerEnvironnement);
  const pages = <String, Widget>{
    'connexion': LoginScreen(),
    'roles': RoleScreen(),
    'inscription': SignupScreen(role: WinRole.student),
    'oubli': ForgotPasswordScreen(),
    'nouveau-mot-de-passe': ResetPasswordScreen(token: 'test'),
    'code': VerifyCodeScreen(email: 'eleve@example.test'),
    'profil': CompleteProfileScreen(),
    'succes': OnboardingSuccessScreen(firstName: 'Ada'),
    'adresse-verifiee': EmailVerifiedScreen(),
  };
  for (final dark in [false, true]) {
    for (final locale in ['fr', 'en']) {
      for (final width in [320.0, 390.0, 768.0]) {
        for (final entry in pages.entries) {
          testWidgets(
              '${entry.key} $locale ${dark ? "sombre" : "clair"} $width texte 2x',
              (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final scheme = dark ? WinScheme.dark_ : WinScheme.light;
            await monter(
                tester,
                WinTheme(
                    scheme: scheme,
                    child: MaterialApp(
                      theme: winMaterialTheme(scheme),
                      locale: Locale(locale),
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(2),
                              disableAnimations: true),
                          child: child!),
                      home: entry.value,
                    )));
            await reseau(tester);
            expect(tester.takeException(), isNull);
            // Building the whole scrollable content checks off-screen overflow too.
            await monter(tester, const SizedBox());
          });
        }
      }
    }
  }

  testWidgets(
      'champ : hauteur 54, sans icone gauche, action de 44 et saisie preservée',
      (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    var suffix = false;
    await monterEcran(
        tester,
        WinAuthFrame(children: [
          WinTextField(
            label: 'Mot de passe',
            icon: Icons.lock_outline,
            controller: ctrl,
            suffixIcon: Icons.visibility_outlined,
            onSuffixTap: () => suffix = true,
          )
        ]));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    final action = find.widgetWithIcon(IconButton, Icons.visibility_outlined);
    expect(tester.getSize(action).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    final fieldBox = find.ancestor(
        of: find.byType(TextField),
        matching: find.byWidgetPredicate(
            (w) => w is Container && w.constraints?.minHeight == 54));
    expect(tester.getSize(fieldBox).height, greaterThanOrEqualTo(54));
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(action);
    expect(ctrl.text, 'secret');
    expect(suffix, isTrue);
  });

  testWidgets(
      'animations reduites : mascotte, points et squelette ne planifient pas d images',
      (tester) async {
    await monter(
        tester,
        ecran(const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
                body: Column(children: [
              WinMascot(),
              WinLoadingDots(),
              WinSkeleton()
            ])))));
    await reseau(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('formulaire reste accessible avec clavier sur 320 px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
    await monter(tester, ecran(const SignupScreen(role: WinRole.student)));
    await reseau(tester);
    final action =
        find.widgetWithText(WinButton, L10n.current.authCreateMyAccount);
    await tester.ensureVisible(action);
    await pomper(tester);
    final rect = tester.getRect(action);
    expect(rect.top, greaterThanOrEqualTo(60));
    expect(rect.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  // Optional local review artifacts. No golden acceptance without a web comparison.
  if (Platform.environment['LOT4_CAPTURES'] case final String folder) {
    for (final entry in pages.entries) {
      testWidgets('capture ${entry.key}', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await monter(
            tester, ecran(RepaintBoundary(key: key, child: entry.value)));
        await reseau(tester);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final picture = await boundary.toImage();
          final bytes =
              await picture.toByteData(format: ui.ImageByteFormat.png);
          await Directory(folder).create(recursive: true);
          await File('$folder/${entry.key}-390.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
        await monter(tester, const SizedBox());
      });
    }
  }
}
