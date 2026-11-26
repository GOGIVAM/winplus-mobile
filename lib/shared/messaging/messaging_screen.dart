import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../theme/win_motion.dart';
import '../../services/messaging_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/win_screen.dart';
import '../../services/content_refusal.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<ApiConversation>? _convos;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await MessagingService.instance.getConversations();
      if (mounted) {
        setState(() {
          _convos = data;
          _error = false;
        });
      }
    } catch (_) {
      // Panne au premier chargement : erreur et Réessayer, pas « aucune
      // conversation ». Un rechargement raté garde la liste affichée.
      if (mounted && _convos == null) setState(() => _error = true);
    }
  }

  void _retry() {
    setState(() {
      _error = false;
      _convos = null;
    });
    _load();
  }

  String _roleLabel(String role) => switch (role) {
        // Lot 8 : un élève s'affichait « Utilisateur ».
        'student' => context.l10n.roleStudent,
        'teacher' => context.l10n.roleTeacher,
        'parent' => context.l10n.roleParent,
        'institution' => context.l10n.roleInstitution,
        _ => context.l10n.msgRoleUser,
      };

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    final l10n = context.l10n;
    if (diff.inMinutes < 1) return l10n.msgNow;
    if (diff.inMinutes < 60) return l10n.msgMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.msgHoursAgo(diff.inHours);
    return l10n.msgDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    // Onglet de la barre du bas : la coque porte déjà le titre « Messages » ;
    // un second titre avec une flèche de retour sans effet s'y ajoutait.
    // Ouverte par-dessus une page (établissement), la barre reste.
    final inTab = !(ModalRoute.of(context)?.canPop ?? false);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: inTab
          ? null
          : AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.msgTitle),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.arrowClockwise, color: s.onStrong),
            onPressed: () {
              setState(() => _convos = null);
              _load();
            },
          ),
        ],
      ),
      body: _error
          ? WinErrorState(message: context.l10n.commonLoadError, onRetry: _retry)
          : _convos == null
          ? const WinLoading()
          : _convos!.isEmpty
              ? WinEmptyState(
                  icon: PhosphorIconsRegular.chatCircle,
                  title: context.l10n.msgEmpty,
                  message: context.l10n.msgEmptyHint)
              : RefreshIndicator(onRefresh: _load, child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _convos!.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: s.outline, height: 1),
                  itemBuilder: (_, i) {
                    final c = _convos![i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Stack(children: [
                        WinAvatar(c.participantName, size: 46),
                        if (c.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: WinColors.error,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${c.unreadCount}',
                                    style: WinType.labelS(WinColors.cream50)
                                        .copyWith(fontSize: 10)),
                              ),
                            ),
                          ),
                      ]),
                      title: Row(children: [
                        Expanded(
                            child: Text(c.participantName,
                                style: WinType.titleM(s.onStrong).copyWith(
                                    fontWeight: c.unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.w500))),
                        Text(_relativeTime(c.lastMessageAt),
                            style: WinType.labelS(s.onFaint)),
                      ]),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WinBadge(_roleLabel(c.participantRole)),
                            const SizedBox(height: 2),
                            if (c.lastMessage != null)
                              Text(c.lastMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: WinType.bodyS(c.unreadCount > 0
                                      ? s.onStrong
                                      : s.onMuted)),
                          ]),
                      onTap: () => Navigator.push(
                              context,
                              WinPageRoute(
                                  builder: (_) =>
                                      ConversationScreen(conversation: c)))
                          .then((_) => _load()),
                    );
                  },
                )),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final ApiConversation conversation;
  const ConversationScreen({super.key, required this.conversation});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  List<ApiMessage>? _messages;
  bool _error = false;
  final _ctrl = TextEditingController();
  bool _sending = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    MessagingService.instance.markRead(widget.conversation.id);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data =
          await MessagingService.instance.getMessages(widget.conversation.id);
      if (mounted) {
        setState(() => _messages = data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (_) {
      // Même règle que la liste : erreur au premier chargement seulement.
      if (mounted && _messages == null) setState(() => _error = true);
    }
  }

  void _retry() {
    setState(() {
      _error = false;
      _messages = null;
    });
    _load();
  }

  /// Message auquel on répond (aperçu au-dessus de la saisie).
  ApiMessage? _replyTo;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final replyTo = _replyTo?.id;
    setState(() {
      _sending = true;
      _replyTo = null;
    });
    // Envoyé immédiatement si en ligne, mis en file sinon (jamais perdu)
    // voir MessagingService.sendMessageQueueable.
    final bool ok;
    try {
      ok = await MessagingService.instance
          .sendMessageQueueable(widget.conversation.id, text, replyTo: replyTo);
    } on ContentRefused catch (r) {
      // Filtre des messageries : le texte revient dans le champ pour être
      // corrigé, avec le message du serveur.
      if (!mounted) return;
      _ctrl.text = text;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _load();
  }

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  /// Appui long : réactions rapides et « Répondre ».
  Future<void> _actions(ApiMessage m) async {
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.msgActions, style: WinType.titleM(WinTheme.of(ctx).onStrong)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final e in _emojis)
                IconButton(
                  tooltip: e,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _react(m, e);
                  },
                  icon: Text(e, style: const TextStyle(fontSize: 26)),
                ),
            ]),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.arrowBendUpLeft),
              title: Text(l.msgReply),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = m);
              },
            ),
          ]),
        ),
      ),
    );
  }

  /// Ajoute, change ou retire ma réaction, tout de suite à l'écran ; si le
  /// serveur refuse, l'état précédent revient avec un message.
  Future<void> _react(ApiMessage m, String emoji) async {
    final before = m.reactions;
    final old = m.myReaction;
    final next = [
      ...before.where((r) => !r.isMine),
      if (old != emoji) ApiReaction(emoji: emoji, isMine: true),
    ];
    _replaceMessage(m.id, (x) => x.withReactions(next));
    try {
      final server = await MessagingService.instance.react(m.id, emoji);
      _replaceMessage(m.id, (x) => x.withReactions(server));
    } catch (_) {
      _replaceMessage(m.id, (x) => x.withReactions(before));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.msgReactError)));
      }
    }
  }

  void _replaceMessage(int id, ApiMessage Function(ApiMessage) f) {
    if (!mounted || _messages == null) return;
    setState(() {
      _messages = [for (final x in _messages!) x.id == id ? f(x) : x];
    });
  }

  String _who(bool fromMe) =>
      fromMe ? context.l10n.msgYou : widget.conversation.participantName;

  Widget _bubble(WinScheme s, ApiMessage m) {
    final mine = m.isFromMe;
    // Réactions groupées par emoji, avec leur nombre ; la mienne en avant.
    final counts = <String, int>{};
    for (final r in m.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final myEmoji = m.myReaction;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: m.isDeleted ? null : () => _actions(m),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: mine ? s.primaryContainer : s.cardBg,
                border: mine ? null : Border.all(color: s.cardBorder),
                borderRadius: BorderRadius.circular(WinRadii.lg),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (m.replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: s.surface2,
                      borderRadius: BorderRadius.circular(WinRadii.sm),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_who(m.replyTo!.isFromMe), style: WinType.labelS(s.onMuted)),
                      Text(m.replyTo!.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WinType.bodyS(s.onMuted)),
                    ]),
                  ),
                Text(m.isDeleted ? context.l10n.msgDeleted : m.content,
                    style: WinType.bodyM(m.isDeleted ? s.onFaint : s.onStrong)
                        .copyWith(fontStyle: m.isDeleted ? FontStyle.italic : null)),
              ]),
            ),
          ),
          if (counts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(spacing: 6, children: [
                for (final e in counts.entries)
                  WinChip('${e.key} ${e.value}',
                      active: e.key == myEmoji, onTap: () => _react(m, e.key)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(_timeLabel(m.sentAt), style: WinType.labelS(s.onFaint)),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime sent) {
    // Heure du serveur en UTC : ramenée à l'heure du téléphone (lot 8).
    final dt = sent.toLocal();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          WinAvatar(widget.conversation.participantName, size: 34),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.conversation.participantName,
                style: WinType.titleM(s.onStrong)),
            Text(
                widget.conversation.participantRole == 'teacher'
                    ? context.l10n.roleTeacher
                    : context.l10n.roleParent,
                style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _error
              ? WinErrorState(message: context.l10n.commonLoadError, onRetry: _retry)
              : _messages == null
              ? const WinLoading()
              : _messages!.isEmpty
                  ? WinEmptyState(
                      icon: PhosphorIconsRegular.chatCircleDots,
                      title: context.l10n.msgStartConversation)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages!.length,
                      itemBuilder: (_, i) => _bubble(s, _messages![i]),
                    ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(top: BorderSide(color: s.outline)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Réponse en cours : le message cité, et de quoi l'annuler.
            if (_replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                decoration: BoxDecoration(
                  color: s.surface2,
                  borderRadius: BorderRadius.circular(WinRadii.sm),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(context.l10n.msgReplyingTo(_who(_replyTo!.isFromMe)),
                          style: WinType.labelS(s.onMuted)),
                      Text(_replyTo!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WinType.bodyS(s.onStrong)),
                    ]),
                  ),
                  IconButton(
                    tooltip: context.l10n.msgCancelReply,
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ]),
              ),
            Row(children: [
            Expanded(
                child: WinTextField(
              hint: context.l10n.msgHint,
              controller: _ctrl,
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _sending ? s.outline : s.primary,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)))
                    : Icon(PhosphorIconsFill.paperPlaneRight, size: 20, color: s.onPrimary),
              ),
            ),
          ]),
          ]),
        ),
      ]),
    );
  }
}
