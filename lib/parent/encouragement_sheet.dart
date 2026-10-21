import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

class EncouragementSheet extends StatefulWidget {
  final ApiChild child;
  final int? childScore;
  const EncouragementSheet({super.key, required this.child, this.childScore});

  static Future<void> show(BuildContext context, ApiChild child,
          {int? childScore}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            EncouragementSheet(child: child, childScore: childScore),
      );

  @override
  State<EncouragementSheet> createState() => _EncouragementSheetState();
}

class _EncouragementSheetState extends State<EncouragementSheet> {
  int? _selectedTemplate;
  final _ctrl = TextEditingController();
  bool _sending = false;

  List<(IconData, String)> get _templates {
    final name = widget.child.firstName;
    final l = L10n.current;
    final score =
        widget.childScore != null ? '${widget.childScore}%' : l.parentEncourageYourScore;
    return [
      (
        Icons.fitness_center_outlined,
        l.parentEncourageTpl1(name)
      ),
      (
        Icons.menu_book_outlined,
        l.parentEncourageTpl2(name)
      ),
      (
        Icons.track_changes_outlined,
        l.parentEncourageTpl3(name)
      ),
      (Icons.star_outline, l.parentEncourageTpl4(name, score)),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _message {
    if (_selectedTemplate != null) return _templates[_selectedTemplate!].$2;
    return _ctrl.text.trim();
  }

  /// Avant : le bouton fermait la feuille et affichait un succès factice
  /// sans jamais rien envoyer. Un encouragement est un message au sens
  /// plein, envoyé via la vraie messagerie DirectMessage.
  Future<void> _send() async {
    final message = _message;
    if (message.isEmpty) return;
    setState(() => _sending = true);
    try {
      await MessagingService.instance
          .startConversation(widget.child.id, firstMessage: message);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.current.parentEncourageSent(widget.child.firstName))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(L10n.current.parentEncourageSendError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final templates = _templates;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: s.outline,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                ),
              ),
            ),
            Text(context.l10n.parentEncourageTitle(widget.child.firstName),
                style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 4),
            Text(context.l10n.parentEncourageSub,
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 20),
            Text(context.l10n.parentEncourageChooseTemplate, style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 10),
            ...List.generate(templates.length, (i) {
              final t = templates[i];
              final selected = _selectedTemplate == i;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedTemplate = selected ? null : i;
                  if (!selected) _ctrl.clear();
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? s.primary : s.outline,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(WinRadii.md),
                    color: selected
                        ? s.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                  ),
                  child: Row(children: [
                    Icon(t.$1, size: 22, color: s.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t.$2,
                          style: WinType.bodyM(s.onStrong).copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 18, color: s.primary),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(context.l10n.parentEncourageOrWrite,
                style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Stack(
              children: [
                TextField(
                  controller: _ctrl,
                  onChanged: (_) => setState(() => _selectedTemplate = null),
                  maxLines: 3,
                  maxLength: 200,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                  decoration: InputDecoration(
                    hintText: context.l10n.parentEncourageHint,
                    hintStyle: WinType.bodyS(s.onFaint),
                    filled: true,
                    fillColor: s.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WinRadii.md),
                      borderSide: BorderSide(color: s.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WinRadii.md),
                      borderSide: BorderSide(color: s.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WinRadii.md),
                      borderSide: BorderSide(color: s.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctrl,
                    builder: (_, v, __) => Text(
                      '${v.text.length}/200',
                      style: WinType.labelS(s.onFaint),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            WinButton(
              context.l10n.commonSend,
              block: true,
              icon: Icons.send_outlined,
              loading: _sending,
              onTap: _message.isEmpty || _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
