import 'package:flutter/material.dart';
import '../../services/messaging_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<ApiConversation>? _convos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await MessagingService.instance.getConversations();
      if (mounted) setState(() => _convos = data);
    } catch (_) {
      if (mounted) setState(() => _convos = []);
    }
  }

  String _roleLabel(String role) => switch (role) {
        'teacher' => 'Professeur',
        'parent' => 'Parent',
        'institution' => 'Établissement',
        _ => 'Utilisateur',
      };

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
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
        title: Text('Messages', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() => _convos = null); _load(); },
          ),
        ],
      ),
      body: _convos == null
          ? const Center(child: CircularProgressIndicator())
          : _convos!.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Aucune conversation.', style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 8),
                  Text('Contactez un professeur depuis la fiche d\'un élève.',
                      style: WinType.bodyS(s.onFaint), textAlign: TextAlign.center),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _convos!.length,
                  separatorBuilder: (_, __) => Divider(color: s.outline, height: 1),
                  itemBuilder: (_, i) {
                    final c = _convos![i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Stack(children: [
                        WinAvatar(c.participantName, size: 46),
                        if (c.unreadCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(
                                  color: WinColors.error, shape: BoxShape.circle),
                              child: Center(
                                child: Text('${c.unreadCount}',
                                    style: WinType.labelS(WinColors.cream50)
                                        .copyWith(fontSize: 10)),
                              ),
                            ),
                          ),
                      ]),
                      title: Row(children: [
                        Expanded(child: Text(c.participantName,
                            style: WinType.titleM(s.onStrong)
                                .copyWith(fontWeight: c.unreadCount > 0
                                    ? FontWeight.w700 : FontWeight.w500))),
                        Text(_relativeTime(c.lastMessageAt),
                            style: WinType.labelS(s.onFaint)),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        WinBadge(_roleLabel(c.participantRole)),
                        const SizedBox(height: 2),
                        if (c.lastMessage != null)
                          Text(c.lastMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WinType.bodyS(c.unreadCount > 0
                                  ? s.onStrong : s.onMuted)),
                      ]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ConversationScreen(conversation: c))).then((_) => _load()),
                    );
                  },
                ),
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
      final data = await MessagingService.instance.getMessages(widget.conversation.id);
      if (mounted) {
        setState(() => _messages = data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _messages = []);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _sending = true);
    final ok = await MessagingService.instance.sendMessage(widget.conversation.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _load();
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
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
        title: Row(children: [
          WinAvatar(widget.conversation.participantName, size: 34),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.conversation.participantName,
                style: WinType.titleM(s.onStrong)),
            Text(widget.conversation.participantRole == 'teacher' ? 'Professeur' : 'Parent',
                style: WinType.labelS(s.onMuted)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _messages == null
              ? const Center(child: CircularProgressIndicator())
              : _messages!.isEmpty
                  ? Center(child: Text('Commencez la conversation.', style: WinType.bodyM(s.onMuted)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages!.length,
                      itemBuilder: (_, i) {
                        final m = _messages![i];
                        return Align(
                          alignment: m.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: m.isFromMe
                                ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                                decoration: BoxDecoration(
                                  color: m.isFromMe ? WinColors.ink800 : s.cardBg,
                                  border: m.isFromMe ? null : Border.all(color: s.cardBorder),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(m.isFromMe ? 18 : 4),
                                    bottomRight: Radius.circular(m.isFromMe ? 4 : 18),
                                  ),
                                ),
                                child: Text(m.content,
                                    style: WinType.bodyM(m.isFromMe ? WinColors.cream50 : s.onSurface)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                                child: Text(_timeLabel(m.sentAt), style: WinType.labelS(s.onFaint)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(top: BorderSide(color: s.outline)),
          ),
          child: Row(children: [
            Expanded(child: WinTextField(
              hint: 'Votre message…',
              controller: _ctrl,
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _sending ? s.outline : s.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _sending
                    ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                    : Icon(Icons.send, size: 20, color: s.onPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
