import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/theme/win_colors.dart';
import 'package:winplus/theme/win_motion.dart';
import 'package:winplus/theme/win_theme.dart';

import '../helpers/faux_reseau.dart';

void main() {
  // Aucune requete vers Google Fonts pendant les tests (voir faux_reseau.dart).
  setUpAll(preparerEnvironnement);

  group('WinColors', () {
    test('couleurs d\'ancrage de la charte', () {
      expect(WinColors.ink900, const Color(0xFF0F2A35));
      expect(WinColors.teal500, const Color(0xFF33BBAF));
      expect(WinColors.blue500, const Color(0xFF3E7CAF));
      expect(WinColors.cream50, const Color(0xFFFBF8F2));
    });

    // Le fond de l'application est blanc comme le site (09e0b59) ; les tons
    // creme de la palette restent, eux, distincts du blanc.
    test('les tons creme de la palette ne sont pas du blanc pur', () {
      for (final c in [WinColors.cream50, WinColors.cream100, WinColors.cream200, WinColors.cream300, WinColors.border]) {
        expect(c, isNot(Colors.white));
      }
    });

    test('toutes les couleurs de la palette sont opaques', () {
      for (final c in [
        WinColors.ink900, WinColors.ink50, WinColors.teal700, WinColors.teal50, WinColors.blue700, WinColors.blue50,
        WinColors.success, WinColors.warn, WinColors.error, WinColors.gold, WinColors.successBg, WinColors.errorBg,
      ]) {
        expect(c.a, 1.0);
      }
    });
  });

  group('Echelles d\'espacement et de rayons', () {
    test('espacement sur une echelle de 4 dp croissante', () {
      final v = [WinSpacing.xs, WinSpacing.sm, WinSpacing.md, WinSpacing.lg, WinSpacing.xl, WinSpacing.xxl, WinSpacing.xxxl, WinSpacing.x4, WinSpacing.x5];
      expect(v, [4, 8, 12, 16, 20, 24, 32, 48, 64]);
      for (final x in v) {
        expect(x % 4, 0);
      }
    });

    test('rayons croissants, le dernier est une pilule', () {
      expect([WinRadii.sm, WinRadii.md, WinRadii.lg, WinRadii.xl, WinRadii.full], [12, 16, 20, 28, 100]);
    });

    test('ombres : une par niveau, le flou augmente avec le niveau', () {
      expect(WinShadows.sm, hasLength(1));
      expect(WinShadows.md, hasLength(1));
      expect(WinShadows.lg, hasLength(1));
      expect(WinShadows.sm.single.blurRadius, lessThan(WinShadows.md.single.blurRadius));
      expect(WinShadows.md.single.blurRadius, lessThan(WinShadows.lg.single.blurRadius));
    });
  });

  group('WinScheme', () {
    test('le schema clair n\'est pas sombre, fond blanc et sarcelle', () {
      expect(WinScheme.light.dark, isFalse);
      expect(WinScheme.light.bg, Colors.white);
      expect(WinScheme.light.primary, WinColors.teal600);
    });

    test('le schema sombre est sombre, avec un teal plus clair', () {
      expect(WinScheme.dark_.dark, isTrue);
      expect(WinScheme.dark_.primary, WinColors.teal400);
      expect(WinScheme.dark_.bg.computeLuminance(), lessThan(WinScheme.light.bg.computeLuminance()));
    });

    test('le texte reste plus fonce que le fond en clair et plus clair en sombre', () {
      expect(WinScheme.light.onBg.computeLuminance(), lessThan(WinScheme.light.bg.computeLuminance()));
      expect(WinScheme.dark_.onBg.computeLuminance(), greaterThan(WinScheme.dark_.bg.computeLuminance()));
    });
  });

  group('winMaterialTheme', () {
    test('theme clair : Material 3, fond et couleurs issus du schema', () {
      final t = sansErreurDePolice(() => winMaterialTheme(WinScheme.light));
      expect(t.useMaterial3, isTrue);
      expect(t.scaffoldBackgroundColor, WinScheme.light.bg);
      expect(t.colorScheme.brightness, Brightness.light);
      expect(t.colorScheme.primary, WinScheme.light.primary);
      expect(t.colorScheme.onPrimary, WinScheme.light.onPrimary);
      expect(t.colorScheme.error, WinColors.error);
    });

    test('theme sombre : luminosite sombre et fond du schema sombre', () {
      final t = sansErreurDePolice(() => winMaterialTheme(WinScheme.dark_));
      expect(t.colorScheme.brightness, Brightness.dark);
      expect(t.scaffoldBackgroundColor, WinScheme.dark_.bg);
      expect(t.colorScheme.primary, WinScheme.dark_.primary);
    });
  });

  group('Mouvement', () {
    test('durees croissantes', () {
      expect(WinDurations.fast, lessThan(WinDurations.base));
      expect(WinDurations.base, lessThan(WinDurations.slow));
      expect(WinDurations.fast, const Duration(milliseconds: 140));
      expect(WinDurations.stagger, const Duration(milliseconds: 40));
    });
  });
}
