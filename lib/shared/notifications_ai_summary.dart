import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Résumé des notifications non lues par WinAI (lot 7), comme
/// NotificationAISummary du site : à partir de 3 non lues, quelques lignes
/// en tête de la liste ; « Masquer » le retire jusqu'au prochain lancement.
class NotificationsAiSummary extends StatefulWidget {
  final List<ApiNotification> unread;
  const NotificationsAiSummary({super.key, required this.unread});

  static const minUnread = 3;

  /// Masqué pour la session de l'application (comme sessionStorage sur le site).
  static bool dismissed = false;

  @override
  State<NotificationsAiSummary> createState() => _NotificationsAiSummaryState();
}

class _NotificationsAiSummaryState extends State<NotificationsAiSummary> {
  String? _summary;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!NotificationsAiSummary.dismissed && widget.unread.length >= NotificationsAiSummary.minUnread) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.post('/ai/summarize-notifications', data: {
        'notifications': [
          for (final n in widget.unread)
            {'title': n.title, 'message': n.body ?? '', 'type': n.type, 'createdAt': n.createdAt.toUtc().toIso8601String()},
        ],
      });
      final body = res.data;
      final map = body is Map ? body : const {};
      final data = map['data'] is Map ? map['data'] as Map : const {};
      final text = map['summary'] ?? data['summary'] ?? map['message'];
      if (mounted && text is String && text.trim().isNotEmpty) setState(() => _summary = text.trim());
    } catch (_) {
      // Résumé facultatif : sans WinAI, la liste reste là.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (NotificationsAiSummary.dismissed || (!_loading && _summary == null)) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: WinColors.teal50,
          border: Border.all(color: WinColors.teal100),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(PhosphorIconsRegular.sparkle, color: WinColors.teal700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.notifSummaryTitle(widget.unread.length), style: WinType.labelM(WinColors.teal700)),
              const SizedBox(height: 4),
              if (_summary == null)
                const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: LinearProgressIndicator(minHeight: 2))
              else
                Text(_summary!, style: WinType.bodyS(s.onStrong)),
            ]),
          ),
          IconButton(
            tooltip: l.notifSummaryHide,
            onPressed: () => setState(() => NotificationsAiSummary.dismissed = true),
            icon: Icon(PhosphorIconsRegular.x, size: 18, color: s.onMuted),
          ),
        ]),
      ),
    );
  }
}
