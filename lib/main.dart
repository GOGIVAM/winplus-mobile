import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_state.dart';
import 'l10n/gen/app_localizations.dart';
import 'theme/win_theme.dart';
import 'auth/splash_screen.dart';
import 'shared/subscription/subscription_notifier.dart';

void main() => runApp(const WinPlusApp());

class WinPlusApp extends StatefulWidget {
  const WinPlusApp({super.key});
  @override
  State<WinPlusApp> createState() => _WinPlusAppState();
}

class _WinPlusAppState extends State<WinPlusApp> {
  final WinAppState _state = WinAppState();
  final SubscriptionNotifier _sub = SubscriptionNotifier();

  @override
  void initState() {
    super.initState();
    _sub.loadFromApi();
    _state.loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    return WinAppScope(
      notifier: _state,
      child: SubscriptionScope(
        notifier: _sub,
        child: AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            final scheme = _state.dark ? WinScheme.dark_ : WinScheme.light;
            return WinTheme(
              scheme: scheme,
              child: MaterialApp(
                title: 'WinPlus',
                debugShowCheckedModeBanner: false,
                theme: winMaterialTheme(scheme),
                locale: _state.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SplashScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
