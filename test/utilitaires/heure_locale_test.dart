import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';

import '../helpers/faux_reseau.dart';

/// Lot 8 : les heures du serveur arrivent en UTC (« …Z ») et s'affichent à
/// l'heure du téléphone (avant : un message de 19:06 affiché 18:06).
void main() {
  setUpAll(initialiserDates);
  setUp(preparerEnvironnement);

  test('une heure UTC est affichee a l\'heure locale', () {
    final utc = DateTime.parse('2026-11-26T18:06:40Z');
    final local = utc.toLocal();
    String deux(int n) => n.toString().padLeft(2, '0');
    expect(WinFormat.time(utc), '${deux(local.hour)}:${deux(local.minute)}');
    expect(WinFormat.time(utc), WinFormat.time(local));
    expect(WinFormat.dayMonth(utc), WinFormat.dayMonth(local));
  });
}
