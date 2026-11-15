import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/connectivity_service.dart';
import '../services/http_cache.dart';
import '../services/outbox_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';

/// Bandeau des quatre espaces (lot 3), sous la barre du haut, donc sur tous
/// les écrans de la coquille :
/// - hors ligne, ou serveur injoignable alors que le réseau est là ;
/// - date des données affichées quand elles viennent du cache ;
/// - nombre d'actions en attente d'envoi.
/// Rien n'est affiché quand tout est à jour et que rien n'attend.
class OfflineStrip extends StatefulWidget {
  const OfflineStrip({super.key});

  @override
  State<OfflineStrip> createState() => _OfflineStripState();
}

class _OfflineStripState extends State<OfflineStrip> {
  bool _online = ConnectivityService.instance.isOnline;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: HttpCache.instance.servedFromCacheSince,
      builder: (context, since, _) => ValueListenableBuilder<int>(
        valueListenable: OutboxService.instance.pending,
        builder: (context, pending, _) {
          final l = context.l10n;
          final parts = <String>[
            if (!_online)
              l.offlineStripOffline
            else if (since != null)
              l.offlineStripServerDown,
            if (since != null) l.offlineStripDataOf(WinFormat.dayMonthTime(since)),
            if (pending > 0) l.offlineStripPending(pending),
          ];
          final show = parts.isNotEmpty;
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: !show
                ? const SizedBox(width: double.infinity)
                : Semantics(
                    liveRegion: true,
                    child: Container(
                      width: double.infinity,
                      color: WinColors.teal900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(children: [
                        Icon(
                            _online
                                ? Icons.cloud_off_outlined
                                : Icons.wifi_off_outlined,
                            size: 16,
                            color: WinColors.cream50),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(parts.join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: WinType.labelM(WinColors.cream50)),
                        ),
                      ]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
