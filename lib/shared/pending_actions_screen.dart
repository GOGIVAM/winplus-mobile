import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/outbox_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';

/// « En attente d'envoi » (lot 3) : les actions faites sans réseau, en
/// attente ou en échec, avec relance et suppression. Ouvert depuis le
/// bandeau des espaces.
class PendingActionsScreen extends StatefulWidget {
  const PendingActionsScreen({super.key});

  @override
  State<PendingActionsScreen> createState() => _PendingActionsScreenState();
}

class _PendingActionsScreenState extends State<PendingActionsScreen> {
  static String label(AppLocalizations l, String code) => switch (code) {
        'quiz_submit' => l.pendingLabelQuiz,
        'message_send' => l.pendingLabelMessage,
        'favorite_add' => l.pendingLabelFavoriteAdd,
        'favorite_remove' => l.pendingLabelFavoriteRemove,
        'goal_accept' => l.pendingLabelGoalAccept,
        'goal_refuse' => l.pendingLabelGoalRefuse,
        'notification_read' => l.pendingLabelNotificationRead,
        'alert_read' => l.pendingLabelAlertRead,
        'conversation_read' => l.pendingLabelConversationRead,
        'forum_reply' => l.pendingLabelForumReply,
        _ => l.pendingLabelOther,
      };

  Future<void> _retry(OutboxEntry e) async {
    await OutboxService.instance.retry(e.id);
    if (mounted) setState(() {});
  }

  Future<void> _delete(OutboxEntry e) async {
    await OutboxService.instance.remove(e.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(l.pendingTitle),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: OutboxService.instance.pending,
        builder: (context, _, __) {
          final entries = OutboxService.instance.entries;
          if (entries.isEmpty) {
            return WinEmptyState(
                title: l.pendingEmpty,
                icon: PhosphorIconsRegular.checkCircle);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(l.pendingIntro, style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 12),
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WinCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                                e.failed
                                    ? PhosphorIconsRegular.warningCircle
                                    : PhosphorIconsRegular.clock,
                                size: 18,
                                color: e.failed ? WinColors.error : s.onMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(label(l, e.label),
                                  style: WinType.titleM(s.onStrong)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                              '${WinFormat.dayMonthTime(e.createdAt)} · '
                              '${e.failed ? l.pendingFailed : l.pendingWaiting}',
                              style: WinType.bodyS(s.onMuted)),
                          if (e.error != null && e.error!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(e.error!,
                                style: WinType.bodyS(WinColors.error)),
                          ],
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (e.failed)
                              WinButton(l.pendingRetry,
                                  small: true, onTap: () => _retry(e)),
                            WinButton(l.pendingDelete,
                                small: true,
                                variant: WinButtonVariant.outline,
                                onTap: () => _delete(e)),
                          ]),
                        ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
