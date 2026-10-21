import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Lot 10.11 : accès court aux traductions depuis un widget
/// (`context.l10n.cle`).
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Langue courante de l'application, pour le code sans BuildContext
/// (services, messages d'erreur, formats). Tenue à jour par WinAppState.
class L10n {
  L10n._();
  static Locale locale = const Locale('fr');

  /// 'fr' ou 'en'.
  static String get code => locale.languageCode;
  static bool get isEn => code == 'en';

  /// Traductions de la langue courante, hors arbre de widgets.
  static AppLocalizations get current => lookupAppLocalizations(locale);
}

/// Formats de date et de montant adaptés à la langue (lot 10.11).
/// En français, ils reproduisent exactement les formats écrits à la main
/// qui existaient avant (ex. « 5 janvier 2026 », « lun. », « 8 000 »).
class WinFormat {
  WinFormat._();

  static String get _l => L10n.code;

  /// « 5 janvier 2026 » / « January 5, 2026 ».
  static String date(DateTime d) => DateFormat.yMMMMd(_l).format(d);

  /// « 5 janv. 2026 » / « Jan 5, 2026 ».
  static String dateShort(DateTime d) => DateFormat.yMMMd(_l).format(d);

  /// « 5 janvier » / « January 5 ».
  static String dayMonth(DateTime d) => DateFormat.MMMMd(_l).format(d);

  /// « 5 janv. » / « Jan 5 ».
  static String dayMonthShort(DateTime d) => DateFormat.MMMd(_l).format(d);

  /// « 14:05 » dans les deux langues (horaire scolaire sur 24 h).
  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  /// « 5 janvier à 14:05 » / « January 5 at 14:05 ».
  static String dayMonthTime(DateTime d) =>
      L10n.current.fmtDateAtTime(dayMonth(d), time(d));

  /// « 5 janvier 2026 à 14:05 » / « January 5, 2026 at 14:05 ».
  static String dateTime(DateTime d) =>
      L10n.current.fmtDateAtTime(date(d), time(d));

  /// « 05/01/2026 » / « 01/05/2026 ».
  static String dateNumeric(DateTime d) => DateFormat.yMd(_l).format(d);

  /// Nom du mois (1 = janvier) : « janvier » / « January ».
  static String monthName(int month) =>
      DateFormat.MMMM(_l).format(DateTime(2024, month, 1));

  /// Mois abrégé : « janv. » / « Jan ».
  static String monthShort(int month) =>
      DateFormat.MMM(_l).format(DateTime(2024, month, 1));

  /// Jour de la semaine (DateTime.monday = 1 … sunday = 7) :
  /// « lundi » / « Monday ».
  static String weekday(int weekday) =>
      DateFormat.EEEE(_l).format(_dayOf(weekday));

  /// Jour abrégé : « lun. » / « Mon ».
  static String weekdayShort(int weekday) =>
      DateFormat.E(_l).format(_dayOf(weekday));

  /// Jour abrégé avec majuscule et sans point : « Lun » / « Mon ».
  static String weekdayShortCap(int weekday) {
    final s = weekdayShort(weekday).replaceAll('.', '');
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  /// Jour complet avec majuscule : « Lundi » / « Monday ».
  static String weekdayCap(int weekday) {
    final s = WinFormat.weekday(weekday);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  // 1er janvier 2024 est un lundi.
  static DateTime _dayOf(int weekday) => DateTime(2024, 1, weekday);

  /// Entier groupé par milliers : « 8 000 » (espace) / « 8,000 ».
  static String number(num n) {
    final s = n.round().abs().toString();
    final sep = L10n.isEn ? ',' : ' ';
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(sep);
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Montant TTC en XAF : « 8 000 XAF » / « 8,000 XAF ».
  static String xaf(num n) => '${number(n)} XAF';
}
