import 'l10n.dart';

/// Noms de classes en anglais (lot 10.6), miroir de
/// frontend/src/i18n/classLevels.ts et de
/// backend/scripts/10.6/classes_anglophones.sql.
///
/// En anglais, une classe du sous-système francophone s'affiche sous son
/// équivalent du sous-système anglophone camerounais, à année d'études égale
/// (MINESEC : 4 + 3 ans côté francophone, 5 + 2 ans côté anglophone) :
/// 6ème = Form 1 … 3ème = Form 4, Seconde = Form 5, Première = Lower Sixth,
/// Terminale = Upper Sixth ; SIL = Class 1 … CM2 = Class 6. Les lettres de
/// série et les examens (BEPC, Probatoire, BAC) ne changent pas.
///
/// SEUL L'AFFICHAGE CHANGE : les valeurs enregistrées et envoyées à l'API
/// restent françaises. Une valeur déjà anglaise ou inconnue est rendue telle
/// quelle.
class ClassLevels {
  ClassLevels._();

  static String _norm(String s) {
    const from = 'àâäéèêëîïôöùûüç';
    const to = 'aaaeeeeiioouuuc';
    final buf = StringBuffer();
    for (final ch in s.trim().toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString();
  }

  static const Map<String, String> _base = {
    '6eme': 'Form 1', '6e': 'Form 1', 'sixieme': 'Form 1',
    '5eme': 'Form 2', '5e': 'Form 2', 'cinquieme': 'Form 2',
    '4eme': 'Form 3', '4e': 'Form 3', 'quatrieme': 'Form 3',
    '3eme': 'Form 4', '3e': 'Form 4', 'troisieme': 'Form 4',
    'seconde': 'Form 5', '2nde': 'Form 5', '2de': 'Form 5',
    'premiere': 'Lower Sixth', '1ere': 'Lower Sixth', '1re': 'Lower Sixth',
    'terminale': 'Upper Sixth', 'tle': 'Upper Sixth',
    'sil': 'Class 1', 'cp': 'Class 2', 'ce1': 'Class 3', 'ce2': 'Class 4',
    'cm1': 'Class 5', 'cm2': 'Class 6',
  };

  static const Map<String, String> _technical = {
    '1ere annee (technique)': 'Form 1 (technical)',
    '2eme annee (technique)': 'Form 2 (technical)',
    '3eme annee (technique)': 'Form 3 (technical)',
    '4eme annee (cap)': 'Form 4 (technical, CAP)',
    'seconde technique': 'Form 5 (technical)',
    'premiere technique': 'Lower Sixth (technical)',
    'terminale technique (f, g, ti)': 'Upper Sixth (technical, F, G, TI)',
  };

  /// « Terminale C », « Tle C/D/TI » : la classe puis une série en capitales.
  static final RegExp _withSeries = RegExp(r'^(\S+)\s+([A-Z0-9][A-Z0-9 /,+&-]*)$');

  /// Équivalent anglophone d'une classe francophone, ou null.
  static String? anglophone(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final key = _norm(raw);
    final tech = _technical[key];
    if (tech != null) return tech;
    final base = _base[key];
    if (base != null) return base;
    final m = _withSeries.firstMatch(raw);
    if (m != null) {
      final cls = _base[_norm(m.group(1)!)];
      if (cls != null) return '$cls ${m.group(2)!.trim()}';
    }
    return null;
  }

  /// Texte affiché d'une classe : l'équivalent anglophone en anglais, sinon
  /// la valeur telle quelle.
  static String label(String? value) {
    if (value == null) return '';
    if (!L10n.isEn) return value;
    return anglophone(value) ?? value;
  }

  /// Option d'une liste qui propose les deux sous-systèmes côte à côte :
  /// en anglais, la classe francophone porte « (francophone) ».
  static String option(String value) {
    final en = L10n.isEn ? anglophone(value) : null;
    return en == null ? value : '$en (francophone)';
  }
}
