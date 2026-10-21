import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'win_widgets.dart';

/// Bannière discrète affichée quand un écran sert des données en cache
/// (Hive) plutôt qu'en temps réel  remplace le pattern "écran vide + bouton
/// Réessayer" partout où une donnée déjà vue peut être réaffichée telle
/// quelle en attendant le retour du réseau.
///
/// Formatage de date à la main (pas intl.DateFormat) : le reste de l'app
/// (student_home.dart, parent_tabs.dart, download_history_screen.dart)
/// utilise déjà ce même procédé plutôt que DateFormat(locale), qui exige une
/// initialisation de données de locale absente de ce projet.
class OfflineBanner extends StatelessWidget {
  final DateTime? updatedAt;
  const OfflineBanner({super.key, required this.updatedAt});

  // Lot 10.11 : « 5 janvier à 14:05 » / « January 5 at 14:05 ».
  static String _format(DateTime d) => WinFormat.dayMonthTime(d);

  @override
  Widget build(BuildContext context) {
    final when = updatedAt == null
        ? context.l10n.widgetOfflineUnknown
        : _format(updatedAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WinAlert(
        context.l10n.widgetOfflineBanner(when),
        type: BadgeColor.neutral,
        icon: Icons.wifi_off_outlined,
      ),
    );
  }
}
