import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/class_levels.dart';
import 'package:winplus/l10n/l10n.dart';

void main() {
  setUp(() => L10n.locale = const Locale('fr'));
  tearDown(() => L10n.locale = const Locale('fr'));

  group('ClassLevels.anglophone', () {
    test('valeur absente, vide ou faite d\'espaces : aucun equivalent', () {
      expect(ClassLevels.anglophone(null), isNull);
      expect(ClassLevels.anglophone(''), isNull);
      expect(ClassLevels.anglophone('   '), isNull);
    });

    test('premier cycle : 6eme a 3eme donnent Form 1 a Form 4, avec ou sans accent', () {
      expect(ClassLevels.anglophone('6ème'), 'Form 1');
      expect(ClassLevels.anglophone('6eme'), 'Form 1');
      expect(ClassLevels.anglophone('5e'), 'Form 2');
      expect(ClassLevels.anglophone('Quatrième'), 'Form 3');
      expect(ClassLevels.anglophone('3ème'), 'Form 4');
    });

    test('second cycle : Seconde, Premiere, Terminale', () {
      expect(ClassLevels.anglophone('Seconde'), 'Form 5');
      expect(ClassLevels.anglophone('2nde'), 'Form 5');
      expect(ClassLevels.anglophone('Première'), 'Lower Sixth');
      expect(ClassLevels.anglophone('1ère'), 'Lower Sixth');
      expect(ClassLevels.anglophone('Terminale'), 'Upper Sixth');
      expect(ClassLevels.anglophone('Tle'), 'Upper Sixth');
    });

    test('primaire : SIL a CM2 donnent Class 1 a Class 6', () {
      expect(ClassLevels.anglophone('SIL'), 'Class 1');
      expect(ClassLevels.anglophone('CP'), 'Class 2');
      expect(ClassLevels.anglophone('CE1'), 'Class 3');
      expect(ClassLevels.anglophone('CE2'), 'Class 4');
      expect(ClassLevels.anglophone('CM1'), 'Class 5');
      expect(ClassLevels.anglophone('CM2'), 'Class 6');
    });

    test('la casse et les espaces autour sont ignores', () {
      expect(ClassLevels.anglophone('  TERMINALE  '), 'Upper Sixth');
      expect(ClassLevels.anglophone('seconde'), 'Form 5');
    });

    test('la serie en capitales est conservee apres la classe', () {
      expect(ClassLevels.anglophone('Terminale C'), 'Upper Sixth C');
      expect(ClassLevels.anglophone('Tle C/D/TI'), 'Upper Sixth C/D/TI');
      expect(ClassLevels.anglophone('1ère D'), 'Lower Sixth D');
    });

    test('une serie en minuscule n\'est pas reconnue', () {
      expect(ClassLevels.anglophone('Terminale c'), isNull);
    });

    test('classes techniques', () {
      expect(ClassLevels.anglophone('Seconde technique'), 'Form 5 (technical)');
      expect(ClassLevels.anglophone('1ère année (technique)'), 'Form 1 (technical)');
      expect(ClassLevels.anglophone('4ème année (CAP)'), 'Form 4 (technical, CAP)');
      expect(ClassLevels.anglophone('Terminale technique (F, G, TI)'), 'Upper Sixth (technical, F, G, TI)');
    });

    test('examens, valeurs deja anglaises et classes inconnues : aucun equivalent', () {
      expect(ClassLevels.anglophone('BEPC'), isNull);
      expect(ClassLevels.anglophone('BAC'), isNull);
      expect(ClassLevels.anglophone('Form 3'), isNull);
      expect(ClassLevels.anglophone('Licence 1'), isNull);
    });
  });

  group('ClassLevels.label', () {
    test('valeur absente : texte vide, dans les deux langues', () {
      expect(ClassLevels.label(null), '');
      L10n.locale = const Locale('en');
      expect(ClassLevels.label(null), '');
    });

    test('en francais, la valeur est rendue telle quelle', () {
      expect(ClassLevels.label('6ème'), '6ème');
      expect(ClassLevels.label('Terminale C'), 'Terminale C');
    });

    test('en anglais, la classe est convertie et le reste est inchange', () {
      L10n.locale = const Locale('en');
      expect(ClassLevels.label('6ème'), 'Form 1');
      expect(ClassLevels.label('Terminale C'), 'Upper Sixth C');
      expect(ClassLevels.label('BEPC'), 'BEPC');
    });
  });

  group('ClassLevels.option', () {
    test('en francais, l\'option est la valeur', () {
      expect(ClassLevels.option('6ème'), '6ème');
    });

    test('en anglais, la classe francophone porte la mention (francophone)', () {
      L10n.locale = const Locale('en');
      expect(ClassLevels.option('6ème'), 'Form 1 (francophone)');
      expect(ClassLevels.option('BEPC'), 'BEPC');
    });
  });
}
