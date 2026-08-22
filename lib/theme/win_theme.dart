import 'package:flutter/material.dart';
import 'win_colors.dart';
import 'win_typography.dart';

/// WINPLUS  Rôles de couleur sémantiques résolus selon le thème (clair/sombre).
/// Le mode sombre est un charcoal neutre type WhatsApp (jamais vert), teal en accent.
class WinScheme {
  final bool dark;
  final Color bg, surface, surface2, surface3;
  final Color onBg, onSurface, onStrong, onMuted, onFaint;
  final Color primary, primaryStrong, onPrimary, primaryContainer, secondary;
  final Color outline, outline2, cardBg, cardBorder, heroFrom, heroTo;
  final Color chipBg,
      chipActiveBg,
      chipActiveFg,
      navBg,
      skeleton,
      inkCard,
      inkCard2;

  const WinScheme({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.onBg,
    required this.onSurface,
    required this.onStrong,
    required this.onMuted,
    required this.onFaint,
    required this.primary,
    required this.primaryStrong,
    required this.onPrimary,
    required this.primaryContainer,
    required this.secondary,
    required this.outline,
    required this.outline2,
    required this.cardBg,
    required this.cardBorder,
    required this.heroFrom,
    required this.heroTo,
    required this.chipBg,
    required this.chipActiveBg,
    required this.chipActiveFg,
    required this.navBg,
    required this.skeleton,
    required this.inkCard,
    required this.inkCard2,
  });

  static const light = WinScheme(
    dark: false,
    bg: WinColors.cream50,
    surface: WinColors.cream50,
    surface2: WinColors.cream100,
    surface3: WinColors.cream200,
    onBg: WinColors.ink800,
    onSurface: WinColors.ink800,
    onStrong: WinColors.ink900,
    onMuted: WinColors.ink500,
    onFaint: WinColors.ink400,
    primary: WinColors.teal500,
    primaryStrong: WinColors.teal600,
    onPrimary: WinColors.ink900,
    primaryContainer: WinColors.teal100,
    secondary: WinColors.blue500,
    outline: WinColors.border,
    outline2: WinColors.ink200,
    cardBg: WinColors.cream50,
    cardBorder: WinColors.border,
    heroFrom: WinColors.ink800,
    heroTo: WinColors.ink700,
    chipBg: WinColors.cream50,
    chipActiveBg: WinColors.ink800,
    chipActiveFg: WinColors.cream50,
    navBg: WinColors.cream50,
    skeleton: WinColors.ink100,
    inkCard: WinColors.ink800,
    inkCard2: WinColors.ink700,
  );

  // Charcoal neutre type WhatsApp.
  static const dark_ = WinScheme(
    dark: true,
    bg: Color(0xFF121617),
    surface: Color(0xFF1D2223),
    surface2: Color(0xFF262C2D),
    surface3: Color(0xFF313839),
    onBg: Color(0xFFE9ECEC),
    onSurface: Color(0xFFE9ECEC),
    onStrong: Colors.white,
    onMuted: Color(0xFF9AA2A4),
    onFaint: Color(0xFF6F7779),
    primary: WinColors.teal400,
    primaryStrong: WinColors.teal500,
    onPrimary: Color(0xFF06201D),
    primaryContainer: Color(0xFF243130),
    secondary: WinColors.blue400,
    outline: Color(0xFF2C3334),
    outline2: Color(0xFF3A4143),
    cardBg: Color(0xFF1A1F20),
    cardBorder: Color(0xFF2B3132),
    heroFrom: Color(0xFF242A2B),
    heroTo: Color(0xFF161A1B),
    chipBg: Color(0xFF1D2223),
    chipActiveBg: WinColors.teal500,
    chipActiveFg: Color(0xFF06201D),
    navBg: Color(0xFF121617),
    skeleton: Color(0xFF262C2D),
    inkCard: Color(0xFF222829),
    inkCard2: Color(0xFF2C3334),
  );
}

class WinTheme extends InheritedWidget {
  final WinScheme scheme;
  const WinTheme({super.key, required this.scheme, required super.child});

  static WinScheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WinTheme>()!.scheme;

  @override
  bool updateShouldNotify(WinTheme oldWidget) =>
      oldWidget.scheme.dark != scheme.dark;
}

ThemeData winMaterialTheme(WinScheme s) => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: s.bg,
      colorScheme: ColorScheme(
        brightness: s.dark ? Brightness.dark : Brightness.light,
        primary: s.primary,
        onPrimary: s.onPrimary,
        secondary: s.secondary,
        onSecondary: Colors.white,
        error: WinColors.error,
        onError: Colors.white,
        surface: s.surface,
        onSurface: s.onSurface,
      ),
      splashFactory: InkRipple.splashFactory,
      textTheme: TextTheme(
        bodyMedium: WinType.bodyM(s.onSurface),
        titleMedium: WinType.titleM(s.onStrong),
      ),
    );
