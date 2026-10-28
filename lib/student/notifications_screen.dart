import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
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
  static const _page = 20;
  static const _maxLimit = 100;

  List<ApiNotification>? _notifs;
  int _total = 0;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await UserService.instance.getNotificationsPage(limit: _page);
      if (mounted) {
        setState(() {
          _notifs = page.items;
          _total = page.total;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notifs = []);
    }
  }

  /// Suite de la liste depuis le serveur (avant, seules les 20 premières
  /// étaient visibles). Jusqu'à 100, la première page est relue en plus
  /// grand : l'ordre « non lues d'abord » bouge quand on lit, une page 2
  /// décalée ferait des trous ou des doublons.
  Future<void> _loadMore() async {
    final current = _notifs ?? [];
    if (_loadingMore || current.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final NotificationPage page;
      List<ApiNotification> merged;
      if (current.length + _page <= _maxLimit) {
        page = await UserService.instance
            .getNotificationsPage(limit: current.length + _page);
        merged = page.items;
      } else {
        page = await UserService.instance.getNotificationsPage(
            page: current.length ~/ _maxLimit + 1, limit: _maxLimit);
        final seen = current.map((n) => n.id).toSet();
        merged = [...current, ...page.items.where((n) => !seen.contains(n.id))];
      }
      if (mounted) {
        setState(() {
          _notifs = merged;
          _total = page.total;
        });
      }
    } catch (_) {
      // Hors ligne : la liste déjà affichée reste.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
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
        SnackBar(
            content: Text(
                L10n.current.studentNotifMarkFailed)),
      );
    }
  }

  Future<void> _openNotification(ApiNotification n) async {
    if (n.isRead) return;
    // Optimiste : la carte et le badge changent tout de suite, le serveur
    // donne ensuite le compte exact.
    setState(() {
      _notifs = _notifs
          ?.map((x) => x.id == n.id ? x.copyWith(isRead: true) : x)
          .toList();
    });
    final ok = await UserService.instance.markNotificationRead(n.id);
    if (!ok && mounted) {
      // Échec réseau : on remet l'état réel plutôt que de laisser un faux "lu".
      setState(() {
        _notifs = _notifs
            ?.map((x) => x.id == n.id ? x.copyWith(isRead: false) : x)
            .toList();
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
        'ai' => winAIIconData,
        'achievement' => Icons.emoji_events_outlined,
        'success' => Icons.check_circle_outline,
        'warning' || 'warn' => Icons.warning_amber_outlined,
        'error' => Icons.error_outline,
        _ => Icons.notifications_outlined,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.l10n.studentNotifJustNow;
    if (diff.inMinutes < 60) return context.l10n.studentNotifMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.studentNotifHoursAgo(diff.inHours);
    if (diff.inDays == 1) return context.l10n.commonYesterday;
    return context.l10n.studentHistDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.studentNotifTitle, style: WinType.headlineS(s.onStrong)),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(context.l10n.studentNotifReadAll,
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _buildBody(s),
    );
  }

  Widget _buildBody(WinScheme s) {
    if (_notifs == null)
      return const Center(child: CircularProgressIndicator());

    // Les notifications lues restent listées (avant, une liste entièrement
    // lue disparaissait derrière « Tout est à jour ! »).
    if (_notifs!.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, size: 64, color: s.onFaint),
        const SizedBox(height: 12),
        Text(context.l10n.studentNotifAllCaughtUp, style: WinType.bodyM(s.onMuted)),
      ]));
    }

    final groups = <String, List<ApiNotification>>{};
    for (final n in _notifs!) {
      final diff = DateTime.now().difference(n.createdAt);
      final key = diff.inDays == 0
          ? context.l10n.commonToday
          : diff.inDays == 1
              ? context.l10n.commonYesterday
              : context.l10n.studentHistDaysAgo(diff.inDays);
      groups.putIfAbsent(key, () => []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        ...groups.entries
          .map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key,
                        style: WinType.titleS(s.onFaint)
                            .copyWith(letterSpacing: 0.8)),
                  ),
                  ...entry.value.map((n) {
                    final unread = !n.isRead;
                    final color = _dotColor(n.type, s);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: WinCard(
                        bg: unread ? s.primaryContainer : null,
                        onTap: () => _openNotification(n),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    winIcon(_icon(n.type), size: 20, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(n.title,
                                              style: WinType.titleM(s.onStrong)
                                                  .copyWith(
                                                      fontWeight: unread
                                                          ? FontWeight.w700
                                                          : FontWeight.w600))),
                                      if (unread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: s.primary,
                                              shape: BoxShape.circle),
                                        ),
                                    ]),
                                    if (n.body != null) ...[
                                      const SizedBox(height: 2),
                                      Text(n.body!,
                                          style: WinType.bodyS(s.onMuted)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(_relativeTime(n.createdAt),
                                        style: WinType.labelS(s.onFaint)),
                                  ])),
                            ]),
                      ),
                    );
                  }),
                ],
              )),
        if (_notifs!.length < _total)
          Center(
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator())
                : TextButton(
                    onPressed: _loadMore,
                    child: Text(context.l10n.studentNotifSeeMore,
                        style: WinType.labelM(s.primary)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
          ),
      ],
    );
  }
}
