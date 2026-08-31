import 'package:flutter/material.dart';
import '../../services/forum_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'thread_detail_screen.dart';
import 'new_thread_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  static const _categories = ['all', 'Questions', 'Discussions', 'Ressources', 'Aide'];
  String _category = 'all';
  List<dynamic> _threads = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _page = 1; _hasMore = true; _threads = []; _loading = true; _error = null; });
    }
    try {
      final data = await ForumService.instance.getThreads(
        category: _category == 'all' ? null : _category,
        page: _page,
      );
      final newThreads = (data['threads'] as List?) ?? [];
      final total = data['total'] as int? ?? 0;
      if (mounted) {
        setState(() {
          _threads = reset ? newThreads : [..._threads, ...newThreads];
          _hasMore = _threads.length < total;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() { _loadingMore = true; _page++; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        title: Text('Forum', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: s.primary),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewThreadScreen()))
              .then((_) => _load(reset: true)),
          ),
        ],
      ),
      body: Column(children: [
        // Filtres catégories
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = cat == _category;
              return GestureDetector(
                onTap: () { setState(() => _category = cat); _load(reset: true); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? s.primary : s.surface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat == 'all' ? 'Tous' : cat,
                    style: WinType.labelM(selected ? Colors.white : s.onMuted),
                  ),
                ),
              );
            },
          ),
        ),
        // Liste des threads
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Text(_error!, style: WinType.bodyM(WinColors.error)))
              : _threads.isEmpty
                ? Center(child: Text('Aucun thread dans cette catégorie.', style: WinType.bodyM(s.onMuted)))
                : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) _loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _threads.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == _threads.length) return const Center(child: CircularProgressIndicator());
                      final t = _threads[i] as Map<String, dynamic>;
                      return _ThreadCard(thread: t, onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ThreadDetailScreen(thread: t)));
                      });
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final Map<String, dynamic> thread;
  final VoidCallback onTap;
  const _ThreadCard({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final role = thread['authorRole'] as String? ?? '';
    final isVerified = thread['isVerifiedInstitution'] as bool? ?? false;
    final isSolved = thread['isSolved'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(thread['title'] ?? '', style: WinType.titleM(s.onStrong))),
            if (isSolved) const SizedBox(width: 8),
            if (isSolved) WinBadge('Résolu', color: BadgeColor.success),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _RoleBadge(role: role, isVerified: isVerified),
            const SizedBox(width: 8),
            Text(thread['authorName'] ?? '', style: WinType.labelM(s.onMuted)),
            const Spacer(),
            Icon(Icons.chat_bubble_outline, size: 13, color: s.onFaint),
            const SizedBox(width: 4),
            Text('${thread['repliesCount'] ?? 0}', style: WinType.labelM(s.onFaint)),
            const SizedBox(width: 12),
            Icon(Icons.thumb_up_outlined, size: 13, color: s.onFaint),
            const SizedBox(width: 4),
            Text('${thread['upvotes'] ?? 0}', style: WinType.labelM(s.onFaint)),
          ]),
        ]),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final bool isVerified;
  const _RoleBadge({required this.role, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'teacher' => 'Prof',
      'institution' => isVerified ? 'Établissement ✓' : 'Établissement',
      'parent' => 'Parent',
      _ => 'Élève',
    };
    final color = switch (role) {
      'teacher' => BadgeColor.teal,
      'institution' => BadgeColor.success,
      'parent' => BadgeColor.warn,
      _ => BadgeColor.blue,
    };
    return WinBadge(label, color: color);
  }
}
