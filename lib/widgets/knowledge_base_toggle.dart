import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../services/chatbot_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Lot 9.7b (décision 18.21) : interrupteur du mode « base de connaissance »
/// du chat WinAI. Désactivé par défaut ; activé, WinAI cherche aussi dans les
/// cours de WinPlus et dans les fichiers de l'utilisateur, ce qui consomme
/// nettement plus de tokens. L'état est partagé par tous les écrans de chat
/// (ChatbotService.knowledgeBase) et envoyé avec chaque message.
class KnowledgeBaseToggle extends StatelessWidget {
  const KnowledgeBaseToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    return ValueListenableBuilder<bool>(
      valueListenable: ChatbotService.instance.knowledgeBase,
      builder: (context, on, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch(
                  value: on,
                  onChanged: (v) => ChatbotService.instance.knowledgeBase.value = v,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                toggled: on,
                label: l10n.widgetKbTitle,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: l10n.widgetKbTitle,
                        style: WinType.labelM(s.onSurface)),
                    TextSpan(
                      text: on ? l10n.widgetKbOn : l10n.widgetKbOff,
                      style: WinType.bodyS(on ? WinColors.warn : s.onMuted),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
