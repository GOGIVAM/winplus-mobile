import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';

import '../helpers/faux_reseau.dart';

// Date figee : lundi 5 janvier 2026, 14:05. Aucune lecture de l'horloge.
final DateTime _date = DateTime(2026, 1, 5, 14, 5);

void main() {
  setUpAll(initialiserDates);
  setUp(() => L10n.locale = const Locale('fr'));
  tearDown(() => L10n.locale = const Locale('fr'));

  group('L10n', () {
    test('la langue par defaut est le francais', () {
      expect(L10n.code, 'fr');
      expect(L10n.isEn, isFalse);
    });

    test('changer la langue met a jour le code et les traductions', () {
      L10n.locale = const Locale('en');
      expect(L10n.code, 'en');
      expect(L10n.isEn, isTrue);
      expect(L10n.current.commonFree, 'Free');
    });

    test('traductions francaises hors arbre de widgets', () {
      expect(L10n.current.commonFree, 'Gratuit');
      expect(L10n.current.fmtDateAtTime('5 janvier', '14:05'), '5 janvier à 14:05');
    });
  });

  group('WinFormat.number et xaf', () {
    test('francais : separateur de milliers espace', () {
      expect(WinFormat.number(0), '0');
      expect(WinFormat.number(999), '999');
      expect(WinFormat.number(1000), '1 000');
      expect(WinFormat.number(1234567), '1 234 567');
    });

    test('anglais : separateur de milliers virgule', () {
      L10n.locale = const Locale('en');
      expect(WinFormat.number(1000), '1,000');
      expect(WinFormat.number(1234567), '1,234,567');
    });

    test('les negatifs gardent leur signe et le groupement', () {
      expect(WinFormat.number(-1500), '-1 500');
      expect(WinFormat.number(-999), '-999');
    });

    test('les decimaux sont arrondis a l\'entier', () {
      expect(WinFormat.number(1234.6), '1 235');
      expect(WinFormat.number(1234.4), '1 234');
    });

    test('montant en XAF', () {
      expect(WinFormat.xaf(8000), '8 000 XAF');
      L10n.locale = const Locale('en');
      expect(WinFormat.xaf(8000), '8,000 XAF');
    });
  });

  group('WinFormat : heures et dates', () {
    test('l\'heure est sur 24 h avec zero devant, dans les deux langues', () {
      expect(WinFormat.time(_date), '14:05');
      expect(WinFormat.time(DateTime(2026, 1, 5, 9, 3)), '09:03');
      L10n.locale = const Locale('en');
      expect(WinFormat.time(_date), '14:05');
    });

    test('dates en francais', () {
      expect(WinFormat.date(_date), '5 janvier 2026');
      expect(WinFormat.dateShort(_date), '5 janv. 2026');
      expect(WinFormat.dayMonth(_date), '5 janvier');
      expect(WinFormat.dayMonthShort(_date), '5 janv.');
      expect(WinFormat.dateNumeric(_date), '05/01/2026');
    });

    test('dates en anglais', () {
      L10n.locale = const Locale('en');
      expect(WinFormat.date(_date), 'January 5, 2026');
      expect(WinFormat.dateShort(_date), 'Jan 5, 2026');
      expect(WinFormat.dayMonth(_date), 'January 5');
      expect(WinFormat.dayMonthShort(_date), 'Jan 5');
    });

    test('date et heure combinees', () {
      expect(WinFormat.dayMonthTime(_date), '5 janvier à 14:05');
      expect(WinFormat.dateTime(_date), '5 janvier 2026 à 14:05');
      L10n.locale = const Locale('en');
      expect(WinFormat.dayMonthTime(_date), 'January 5 at 14:05');
      expect(WinFormat.dateTime(_date), 'January 5, 2026 at 14:05');
    });
  });

  group('WinFormat : mois et jours', () {
    test('noms de mois', () {
      expect(WinFormat.monthName(1), 'janvier');
      expect(WinFormat.monthName(12), 'décembre');
      expect(WinFormat.monthShort(1), 'janv.');
      L10n.locale = const Locale('en');
      expect(WinFormat.monthName(1), 'January');
      expect(WinFormat.monthShort(1), 'Jan');
    });

    test('noms de jours : 1 = lundi, 7 = dimanche', () {
      expect(WinFormat.weekday(1), 'lundi');
      expect(WinFormat.weekday(7), 'dimanche');
      expect(WinFormat.weekdayShort(1), 'lun.');
      L10n.locale = const Locale('en');
      expect(WinFormat.weekday(1), 'Monday');
      expect(WinFormat.weekdayShort(3), 'Wed');
    });

    test('jours avec majuscule, sans point', () {
      expect(WinFormat.weekdayShortCap(1), 'Lun');
      expect(WinFormat.weekdayCap(2), 'Mardi');
      L10n.locale = const Locale('en');
      expect(WinFormat.weekdayShortCap(3), 'Wed');
      expect(WinFormat.weekdayCap(5), 'Friday');
    });
  });

  // Lot 1 (26/11) : notes sur 20, taux, durees et avis.
  group('WinFormat : notes, taux, durees, avis', () {
    test('note sur 20 en francais : virgule, decimale seulement si utile', () {
      expect(WinFormat.grade20(50), '10/20');
      expect(WinFormat.grade20(62.5), '12,5/20');
      expect(WinFormat.grade20(100), '20/20');
      expect(WinFormat.grade20(0), '0/20');
      expect(WinFormat.grade20(63), '12,6/20');
      expect(WinFormat.grade20(null), '–');
      expect(WinFormat.gradeValue(62.5), '12,5');
    });

    test('note sur 20 en anglais : point decimal', () {
      L10n.locale = const Locale('en');
      expect(WinFormat.grade20(50), '10/20');
      expect(WinFormat.grade20(62.5), '12.5/20');
      expect(WinFormat.grade20(null), '–');
    });

    test('taux : espace insecable en francais, colle en anglais', () {
      expect(WinFormat.percent(16), '16 %');
      expect(WinFormat.percent(15.6), '16 %');
      expect(WinFormat.percent(null), '–');
      L10n.locale = const Locale('en');
      expect(WinFormat.percent(16), '16%');
    });

    test('duree : minutes, heures, heures et minutes ; vide si nulle', () {
      expect(WinFormat.duration(45), '45 min');
      expect(WinFormat.duration(120), '2 h');
      expect(WinFormat.duration(90), '1 h 30');
      expect(WinFormat.duration(65), '1 h 05');
      expect(WinFormat.duration(0), '');
      expect(WinFormat.duration(null), '');
      L10n.locale = const Locale('en');
      expect(WinFormat.duration(45), '45 min');
      expect(WinFormat.duration(120), '2 h');
      expect(WinFormat.duration(90), '1 h 30');
    });

    test('note d\'avis sur 5 et decimale seule', () {
      expect(WinFormat.rating5(4.5), '4,5/5');
      expect(WinFormat.rating5(4), '4/5');
      expect(WinFormat.decimal(3.96), '4');
      L10n.locale = const Locale('en');
      expect(WinFormat.rating5(4.5), '4.5/5');
    });

    test('montant : separateur de milliers', () {
      expect(WinFormat.xaf(3500), '3 500 XAF');
      L10n.locale = const Locale('en');
      expect(WinFormat.xaf(3500), '3,500 XAF');
    });
  });
}
