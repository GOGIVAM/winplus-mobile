import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'win_colors.dart';

/// WINPLUS — Typographie.
/// Titres & chiffres : Fraunces (serif). UI & corps : Manrope (sans).
class WinType {
  WinType._();

  static TextStyle fraunces({double size = 16, FontWeight weight = FontWeight.w700, Color? color, double? height, double letterSpacing = -0.3}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  static TextStyle manrope({double size = 14, FontWeight weight = FontWeight.w400, Color? color, double? height, double letterSpacing = 0}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  // ---- Échelle (voir app_typography) ----
  static TextStyle displayL(Color c) => fraunces(size: 40, weight: FontWeight.w700, color: c, height: 1.0, letterSpacing: -0.8);
  static TextStyle displayM(Color c) => fraunces(size: 28, weight: FontWeight.w700, color: c, height: 1.1, letterSpacing: -0.5);
  static TextStyle displayS(Color c) => fraunces(size: 22, weight: FontWeight.w700, color: c, height: 1.15, letterSpacing: -0.4);
  static TextStyle headlineM(Color c) => manrope(size: 18, weight: FontWeight.w700, color: c, letterSpacing: -0.2);
  static TextStyle headlineS(Color c) => manrope(size: 16, weight: FontWeight.w600, color: c, letterSpacing: -0.1);
  static TextStyle titleL(Color c) => manrope(size: 16, weight: FontWeight.w600, color: c);
  static TextStyle titleM(Color c) => manrope(size: 14, weight: FontWeight.w600, color: c);
  static TextStyle titleS(Color c) => manrope(size: 12, weight: FontWeight.w600, color: c, letterSpacing: 0.8);
  static TextStyle bodyL(Color c) => manrope(size: 16, weight: FontWeight.w400, color: c, height: 1.55);
  static TextStyle bodyM(Color c) => manrope(size: 14, weight: FontWeight.w400, color: c, height: 1.55);
  static TextStyle bodyS(Color c) => manrope(size: 13, weight: FontWeight.w400, color: c, height: 1.5);
  static TextStyle labelM(Color c) => manrope(size: 12, weight: FontWeight.w500, color: c);
  static TextStyle labelS(Color c) => manrope(size: 11, weight: FontWeight.w500, color: c);
}
