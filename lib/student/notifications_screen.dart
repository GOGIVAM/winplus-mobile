import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ApiNotification>? _notifs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notifs = await UserService.instance.getNotifications();
      if (mounted) setState(() => _notifs = notifs);
    } catch (_) {
      if (mounted) setState(() => _notifs = []);
    }
  }

  Future<void> _markAllRead() async {
    final ok = await UserService.instance.markAllNotificationsRead();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _notifs = _notifs?.map((n) => n.copyWith(isRead: true)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de marquer les notifications comme lues. Réessaie.")),
      );
    }
  }

  Future<void> _openNotification(ApiNotification n) async {
    if (n.isRead) return;
    // Optimiste : l'UI se met à jour tout de suite, sans attendre le réseau.
    setState(() {
      _notifs = _notifs?.map((x) => x.id == n.id ? x.copyWith(isRead: true) : x).toList();
    });
    final ok = await UserService.instance.markNotificationRead(n.id);
    if (!ok && mounted) {
      // Échec réseau : on remet l'état réel plutôt que de laisser un faux "lu".
      setState(() {
        _notifs = _notifs?.map((x) => x.id == n.id ? x.copyWith(isRead: false) : x).toList();
      });
    }
  }

  Color _dotColor(String type, WinScheme s) => switch (type) {
        'ai' => s.primary,
        'achievement' => WinColors.gold,
        'success' => WinColors.success,
        'warning' || 'warn' => WinColors.warn,
        'error' => WinColors.error,
        _ => s.onFaint,
      };

  IconData _icon(String type) => switch (type) {
        'ai' => Icons.auto_awesome_outlined,
        'achievement' => Icons.emoji_events_outlined,
        'success' => Icons.check_circle_outline,
        'warning' || 'warn' => Icons.warning_amber_outlined,
        'error' => Icons.error_outline,
        _ => Icons.notifications_outlined,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: WinType.headlineS(s.onStrong)),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Tout lire',
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _buildBody(s),
    );
  }

  Widget _buildBody(WinScheme s) {
    if (_notifs == null) return const Center(child: CircularProgressIndicator());

    if (_notifs!.isEmpty || _notifs!.every((n) => n.isRead)) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, size: 64, color: s.onFaint),
        const SizedBox(height: 12),
        Text('Tout est à jour !', style: WinType.bodyM(s.onMuted)),
      ]));
    }

    final groups = <String, List<ApiNotification>>{};
    for (final n in _notifs!) {
      final diff = DateTime.now().difference(n.createdAt);
      final key = diff.inDays == 0
          ? "Aujourd'hui"
          : diff.inDays == 1
              ? 'Hier'
              : 'Il y a ${diff.inDays} jours';
      groups.putIfAbsent(key, () => []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: groups.entries.map((entry) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(entry.key,
                style: WinType.titleS(s.onFaint).copyWith(letterSpacing: 0.8)),
          ),
          ...entry.value.map((n) {
            final unread = !n.isRead;
            final color = _dotColor(n.type, s);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WinCard(
                bg: unread ? s.primaryContainer : null,
                onTap: () => _openNotification(n),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon(n.type), size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(n.title,
                          style: WinType.titleM(s.onStrong).copyWith(
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600))),
                      if (unread)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: s.primary, shape: BoxShape.circle),
                        ),
                    ]),
                    if (n.body != null) ...[
                      const SizedBox(height: 2),
                      Text(n.body!, style: WinType.bodyS(s.onMuted)),
                    ],
                    const SizedBox(height: 4),
                    Text(_relativeTime(n.createdAt), style: WinType.labelS(s.onFaint)),
                  ])),
                ]),
              ),
            );
          }),
        ],
      )).toList(),
    );
  }
}
