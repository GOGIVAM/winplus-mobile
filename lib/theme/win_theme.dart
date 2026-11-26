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

  // Fond blanc partout (décision produit) : le crème est réservé au texte
  // clair sur fond sombre ; filets et surfaces secondaires en gris froid.
  static const light = WinScheme(
    dark: false,
    bg: Colors.white,
    surface: Colors.white,
    surface2: Color(0xFFF5F7F8),
    surface3: WinColors.ink50,
    onBg: WinColors.ink800,
    onSurface: WinColors.ink800,
    onStrong: WinColors.ink900,
    onMuted: WinColors.ink500,
    onFaint: WinColors.ink400,
    // Sarcelle fonce : texte blanc lisible dessus (5,6:1) et lisible en
    // texte ou lien sur blanc. Le sarcelle de marque (teal600, 3,4:1) reste
    // pour les aplats sans texte : progression, pastilles, illustrations.
    primary: WinColors.teal700,
    primaryStrong: WinColors.teal800,
    onPrimary: Colors.white,
    // Fond teinte unique des pastilles d'icone, tuiles et selections.
    primaryContainer: Color(0xFFE3F5F2),
    secondary: WinColors.blue500,
    outline: Color(0xFFE6EBED),
    outline2: WinColors.ink200,
    cardBg: Colors.white,
    cardBorder: Color(0xFFE6EBED),
    heroFrom: WinColors.teal900,
    heroTo: WinColors.teal850,
    chipBg: Colors.white,
    chipActiveBg: WinColors.teal900,
    chipActiveFg: Colors.white,
    navBg: Colors.white,
    skeleton: WinColors.ink100,
    inkCard: WinColors.teal900,
    inkCard2: WinColors.teal850,
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
      appBarTheme: AppBarTheme(
        backgroundColor: s.bg,
        foregroundColor: s.onStrong,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: WinType.archivo(
            size: 20, weight: FontWeight.w600, color: s.onStrong),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: s.outline2,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      // Message ephemere : flottant, arrondi, meme dessin partout (une
      // centaine d'ecrans en affichent sans style propre).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.dark ? s.surface3 : WinColors.ink900,
        contentTextStyle: WinType.bodyM(Colors.white),
        actionTextColor: WinColors.teal300,
        elevation: 2,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.dark ? s.primary : WinColors.teal600,
        linearTrackColor: s.outline,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: s.outline, thickness: 1, space: 1),
      // Boutons Material encore presents dans certains ecrans : memes
      // hauteur, rayon et couleurs que WinButton.
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: s.dark ? s.primary : WinColors.teal700,
        foregroundColor: s.onPrimary,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: WinType.titleM(s.onPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: s.dark ? s.primary : WinColors.teal700,
        foregroundColor: s.onPrimary,
        elevation: 0,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: WinType.titleM(s.onPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: s.onSurface,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: s.outline2),
        textStyle: WinType.titleM(s.onSurface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm)),
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: s.primaryStrong,
        minimumSize: const Size(48, 44),
        textStyle: WinType.titleM(s.primaryStrong),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm)),
      )),
      // Champs Material bruts : meme dessin que WinTextField.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        hintStyle: WinType.bodyM(s.onFaint),
        labelStyle: WinType.bodyM(s.onMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        // Un seul « border » qui suit l'etat du champ, et pas de
        // enabledBorder / focusedBorder : ils passaient devant le
        // « border: InputBorder.none » des champs qui dessinent leur propre
        // cadre (WinTextField) et leur ajoutaient un second cadre.
        border: MaterialStateOutlineInputBorder.resolveWith((states) {
          final side = states.contains(WidgetState.error)
              ? const BorderSide(color: WinColors.error)
              : states.contains(WidgetState.focused)
                  ? BorderSide(color: s.primary, width: 1.6)
                  : BorderSide(color: s.outline2);
          return OutlineInputBorder(
              borderRadius: BorderRadius.circular(WinRadii.sm),
              borderSide: side);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: WinType.headlineM(s.onStrong),
        contentTextStyle: WinType.bodyM(s.onSurface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.xl)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: s.onStrong,
        unselectedLabelColor: s.onMuted,
        labelStyle: WinType.titleM(s.onStrong),
        unselectedLabelStyle: WinType.bodyM(s.onMuted),
        indicatorColor: s.dark ? s.primary : WinColors.teal600,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: s.outline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected) ? Colors.white : s.onFaint),
        trackColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected)
                ? (s.dark ? s.primary : WinColors.teal600)
                : s.surface2),
        trackOutlineColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected) ? Colors.transparent : s.outline2),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.onMuted,
        titleTextStyle: WinType.bodyL(s.onStrong).copyWith(height: 1.3),
        subtitleTextStyle: WinType.bodyS(s.onMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
      ),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: s.onStrong,
      )),
      textTheme: TextTheme(
        bodyMedium: WinType.bodyM(s.onSurface),
        titleMedium: WinType.titleM(s.onStrong),
      ),
    );
