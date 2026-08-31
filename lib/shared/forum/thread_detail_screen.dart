import 'package:flutter/material.dart';
import '../../services/forum_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';

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
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _loadPosts() async {
    try {
      final posts = await ForumService.instance.getPosts(widget.thread['id'] as int);
      if (mounted) setState(() { _posts = posts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ForumService.instance.reply(widget.thread['id'] as int, text);
      _replyCtrl.clear();
      await _loadPosts();
    } catch (_) {} finally {
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
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.thread['category'] ?? 'Thread', style: WinType.labelM(s.onMuted)),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _posts.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _ThreadHeader(thread: widget.thread, s: s);
                final post = _posts[i - 1] as Map<String, dynamic>;
                return _PostCard(post: post, s: s, onVote: _vote);
              },
            ),
        ),
        // Zone de réponse
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(top: BorderSide(color: s.outline, width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                maxLines: 3, minLines: 1,
                style: WinType.bodyM(s.onStrong),
                decoration: InputDecoration(
                  hintText: 'Votre réponse…',
                  hintStyle: WinType.bodyM(s.onFaint),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _sendReply,
              icon: _sending
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: s.primary))
                : Icon(Icons.send, color: s.primary),
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
        color: isAccepted ? WinColors.successBg : s.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted ? WinColors.success : s.outline,
          width: isAccepted ? 1.5 : 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(post['authorName'] ?? 'Anonyme', style: WinType.labelM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _RolePill(role: role, isVerified: isVerified),
          if (isAccepted) ...[const Spacer(), const Icon(Icons.check_circle, color: WinColors.success, size: 18)],
        ]),
        const SizedBox(height: 8),
        Text(post['content'] ?? '', style: WinType.bodyM(s.onSurface)),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: () => onVote(postId, 'up'),
            child: Row(children: [
              Icon(Icons.thumb_up_outlined, size: 16, color: s.primary),
              const SizedBox(width: 4),
              Text('${post['upvotes'] ?? 0}', style: WinType.labelM(s.primary)),
            ]),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onVote(postId, 'down'),
            child: Icon(Icons.thumb_down_outlined, size: 16, color: s.onFaint),
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
    final label = switch (role) {
      'teacher' => 'Prof',
      'institution' => 'Établissement',
      'parent' => 'Parent',
      _ => 'Élève',
    };
    final color = switch (role) {
      'teacher' => WinColors.teal400,
      'institution' => WinColors.success,
      'parent' => WinColors.warn,
      _ => const Color(0xFF6C8EBD),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        if (role == 'institution' && isVerified) ...[
          const SizedBox(width: 3),
          Icon(Icons.verified_rounded, size: 11, color: color),
        ],
      ]),
    );
  }
}
