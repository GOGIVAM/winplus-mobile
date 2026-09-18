import 'package:flutter/material.dart';
import 'win_widgets.dart';

const _offlineBannerMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

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

  static String _format(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_offlineBannerMonths[d.month - 1]} à $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final when = updatedAt == null ? 'inconnue' : _format(updatedAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WinAlert(
        'Hors ligne  dernière mise à jour : $when',
        type: BadgeColor.neutral,
        icon: Icons.wifi_off_outlined,
      ),
    );
  }
}
