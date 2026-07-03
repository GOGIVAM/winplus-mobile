import 'package:flutter/material.dart';

/// WINPLUS — Palette de couleurs (transcription fidèle de la charte app_colors).
/// Jamais de blanc pur : les surfaces claires utilisent le crème.
class WinColors {
  WinColors._();

  // ---- INK (bleu-pétrole foncé, couleur d'ancrage) ----
  static const ink900 = Color(0xFF0F2A35);
  static const ink800 = Color(0xFF163844);
  static const ink700 = Color(0xFF1F4A5A);
  static const ink600 = Color(0xFF2F5E70);
  static const ink500 = Color(0xFF4E7280);
  static const ink400 = Color(0xFF6F8A95);
  static const ink300 = Color(0xFF97AAB2);
  static const ink200 = Color(0xFFC8D2D6);
  static const ink100 = Color(0xFFE4E9EB);
  static const ink50 = Color(0xFFF1F4F5);

  // ---- TEAL (couleur signature de la marque) ----
  static const teal700 = Color(0xFF1E8077);
  static const teal600 = Color(0xFF259A8E);
  static const teal500 = Color(0xFF33BBAF);
  static const teal400 = Color(0xFF6BCFC6);
  static const teal300 = Color(0xFF9CDED7);
  static const teal100 = Color(0xFFD6F1ED);
  static const teal50 = Color(0xFFEBF8F6);

  // ---- BLUE (secondaire) ----
  static const blue700 = Color(0xFF2C5E84);
  static const blue600 = Color(0xFF3471A0);
  static const blue500 = Color(0xFF3E7CAF);
  static const blue400 = Color(0xFF6498C2);
  static const blue100 = Color(0xFFDCE9F2);
  static const blue50 = Color(0xFFEEF4F9);

  // ---- CREAM (fonds clairs) ----
  static const cream50 = Color(0xFFFBF8F2);
  static const cream100 = Color(0xFFF6F0E4);
  static const cream200 = Color(0xFFEFE7D4);
  static const cream300 = Color(0xFFE5D9BF);
  static const border = Color(0xFFE8E0CE);

  // ---- SÉMANTIQUE ----
  static const success = Color(0xFF1F9D6E);
  static const successBg = Color(0xFFE2F4EB);
  static const warn = Color(0xFFC58423);
  static const warnBg = Color(0xFFFBEFD7);
  static const error = Color(0xFFB7423E);
  static const errorBg = Color(0xFFF8E1DF);
  static const gold = Color(0xFFB07A1A);
  static const goldBg = Color(0xFFF7ECD2);
}

/// Espacement sur une échelle de 4dp.
class WinSpacing {
  WinSpacing._();
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32, x4 = 48, x5 = 64;
}

/// Rayons de bordure.
class WinRadii {
  WinRadii._();
  static const double sm = 6, md = 10, lg = 16, xl = 24, full = 100;
}

/// Ombres « ink » (jamais de noir pur).
class WinShadows {
  WinShadows._();
  static const sm = [BoxShadow(color: Color(0x0F163844), blurRadius: 2, offset: Offset(0, 1))];
  static const md = [BoxShadow(color: Color(0x14163844), blurRadius: 12, offset: Offset(0, 4))];
  static const lg = [BoxShadow(color: Color(0x1F163844), blurRadius: 32, offset: Offset(0, 12))];
}
