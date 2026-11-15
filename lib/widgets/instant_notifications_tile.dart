import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/background_notifications.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'win_widgets.dart';

/// Interrupteur « Notifications instantanées » (lot 2, Communs 2) : coupe ou
/// relance le service d'écoute et sa notification fixe. Désactivé, seule la
/// vérification de secours (environ 15 minutes) reste. Affiché seulement là
/// où le service existe (Android).
class InstantNotificationsTile extends StatefulWidget {
  const InstantNotificationsTile({super.key});

  @override
  State<InstantNotificationsTile> createState() =>
      _InstantNotificationsTileState();
}

class _InstantNotificationsTileState extends State<InstantNotificationsTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    BackgroundNotifications.isInstantEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    await BackgroundNotifications.setInstant(v);
  }

  @override
  Widget build(BuildContext context) {
    if (!BackgroundNotifications.supported) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    return WinCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.notifInstantTitle, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 4),
            Text(l.notifInstantHint, style: WinType.bodyS(s.onMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _enabled ?? true,
          activeTrackColor: s.primary,
          onChanged: _enabled == null ? null : _toggle,
        ),
      ]),
    );
  }
}
