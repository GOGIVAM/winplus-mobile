import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme/win_theme.dart';
import 'auth/splash_screen.dart';

void main() => runApp(const WinPlusApp());

class WinPlusApp extends StatefulWidget {
  const WinPlusApp({super.key});
  @override
  State<WinPlusApp> createState() => _WinPlusAppState();
}

class _WinPlusAppState extends State<WinPlusApp> {
  final WinAppState _state = WinAppState();

  @override
  Widget build(BuildContext context) {
    return WinAppScope(
      notifier: _state,
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
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
