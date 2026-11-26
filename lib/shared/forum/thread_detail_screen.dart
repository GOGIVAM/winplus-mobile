import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/forum_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import 'new_thread_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';
import '../../services/content_refusal.dart';

class ThreadDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ThreadDetailScreen({super.key, required this.thread});
  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final posts =
          await ForumService.instance.getPosts(widget.thread['id'] as int);
      if (mounted)
        setState(() {
          _posts = posts;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final sent =
          await ForumService.instance.reply(widget.thread['id'] as int, text);
      _replyCtrl.clear();
      // Hors ligne : la réponse attend le réseau (lot 3), on le dit.
      if (!sent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.pendingQueuedSnack)));
      }
      await _loadPosts();
    } catch (e) {
      // Filtre des messageries : le texte reste dans le champ, avec le
      // message du serveur. Avant, toute erreur était tue.
      final refused = ContentRefused.of(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(refused?.message ?? context.l10n.commonLoadError)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _vote(int postId, String type) async {
    try {
      await ForumService.instance.vote(postId, type);
      await _loadPosts();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            widget.thread['category'] == null
                ? l10n.forumThread
                : forumCategoryLabel(l10n, widget.thread['category'] as String),
            style: WinType.labelM(s.onMuted)),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const WinLoading()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _posts.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0)
                      return _ThreadHeader(thread: widget.thread, s: s);
                    final post = _posts[i - 1] as Map<String, dynamic>;
                    return _PostCard(post: post, s: s, onVote: _vote);
                  },
                ),
        ),
        // Zone de réponse  champ en pilule + bouton d'envoi circulaire,
        // même langage que le composer du chat WinAI.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(top: BorderSide(color: s.outline, width: 0.5)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: s.surface2,
                  borderRadius: BorderRadius.circular(WinRadii.full),
                  border: Border.all(color: s.outline),
                ),
                child: TextField(
                  controller: _replyCtrl,
                  maxLines: 4,
                  minLines: 1,
                  style: WinType.bodyM(s.onStrong),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.forumReplyHint,
                    hintStyle: WinType.bodyM(s.onFaint),
                    filled: false, border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendReply,
              child: Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: s.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: _sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: s.onPrimary))
                    : Icon(PhosphorIconsFill.paperPlaneRight, size: 18, color: s.onPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  final Map<String, dynamic> thread;
  final WinScheme s;
  const _ThreadHeader({required this.thread, required this.s});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(thread['title'] ?? '', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 8),
        Text(thread['content'] ?? '', style: WinType.bodyM(s.onSurface)),
        const SizedBox(height: 12),
        const Divider(),
      ]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final WinScheme s;
  final void Function(int, String) onVote;
  const _PostCard({required this.post, required this.s, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final isAccepted = post['isAccepted'] as bool? ?? false;
    final isVerified = post['isVerifiedInstitution'] as bool? ?? false;
    final role = post['authorRole'] as String? ?? '';
    final postId = post['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAccepted ? winTone(s, BadgeColor.success).bg : s.surface,
        borderRadius: BorderRadius.circular(WinRadii.lg),
        border: Border.all(
          color: isAccepted ? WinColors.success : s.outline,
          width: isAccepted ? 1.5 : 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(post['authorName'] ?? context.l10n.forumAnonymous,
              style: WinType.labelM(s.onStrong)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _RolePill(role: role, isVerified: isVerified),
          if (isAccepted) ...[
            const Spacer(),
            const Icon(PhosphorIconsFill.checkCircle, color: WinColors.success, size: 18)
          ],
        ]),
        const SizedBox(height: 8),
        Text(post['content'] ?? '', style: WinType.bodyM(s.onSurface)),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: () => onVote(postId, 'up'),
            child: Row(children: [
              Icon(PhosphorIconsRegular.thumbsUp, size: 16, color: s.primary),
              const SizedBox(width: 4),
              Text('${post['upvotes'] ?? 0}', style: WinType.labelM(s.primary)),
            ]),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onVote(postId, 'down'),
            child: Icon(PhosphorIconsRegular.thumbsDown, size: 16, color: s.onFaint),
          ),
        ]),
      ]),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  final bool isVerified;
  const _RolePill({required this.role, required this.isVerified});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (role) {
      'teacher' => l10n.forumRoleTeacher,
      'institution' => l10n.roleInstitution,
      'parent' => l10n.roleParent,
      _ => l10n.roleStudent,
    };
    final color = switch (role) {
      'teacher' => WinColors.teal400,
      'institution' => WinColors.success,
      'parent' => WinColors.warn,
      _ => WinColors.blue400,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(WinRadii.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        if (role == 'institution' && isVerified) ...[
          const SizedBox(width: 3),
          Icon(PhosphorIconsFill.sealCheck, size: 11, color: color),
        ],
      ]),
    );
  }
}
