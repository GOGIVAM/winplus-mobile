import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/subject_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'content_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _typeFilter = 'Tout';
  String _levelFilter = 'Tout';
  bool _loading = false;
  List<Content> _results = [];

  static const _types = ['Tout', 'Épreuve', 'Correction', 'Quiz', 'Livre', 'Pack'];
  static const _levels = ['Tout', 'BEPC', 'Probatoire', 'BAC', 'BTS', 'Concours'];

  static const _apiTypeMap = {
    'Épreuve': 'epreuve',
    'Correction': 'correction',
    'Quiz': 'quiz',
    'Livre': 'livre',
    'Pack': 'pack',
  };

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    try {
      final page = await SubjectService.instance.getAll(
        q: q.trim(),
        category: _typeFilter == 'Tout' ? null : _apiTypeMap[_typeFilter],
        level: _levelFilter == 'Tout' ? null : _levelFilter,
        pageSize: 30,
      );
      if (mounted) {
        setState(() {
          _results = page.items.map((s) => s.toContent()).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _results = []; _loading = false; });
    }
  }

  void _onChanged(String v) {
    setState(() => _query = v);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _query == v) _search(v);
    });
  }

  void _onFilterChanged() {
    if (_query.trim().isNotEmpty) _search(_query);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          style: WinType.manrope(size: 15, color: s.onStrong),
          decoration: InputDecoration(
            hintText: 'BAC C Maths, ENSP, SVT…',
            hintStyle: WinType.manrope(size: 15, color: s.onFaint),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 18, color: s.onFaint),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() { _query = ''; _results = []; });
                    })
                : null,
          ),
        ),
      ),
      body: Column(children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => WinChip(
              _types[i],
              active: _typeFilter == _types[i],
              onTap: () { setState(() => _typeFilter = _types[i]); _onFilterChanged(); },
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => WinChip(
              _levels[i],
              active: _levelFilter == _levels[i],
              onTap: () { setState(() => _levelFilter = _levels[i]); _onFilterChanged(); },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _query.trim().isEmpty
              ? _EmptyIdle()
              : _loading
                  ? _LoadingSkeleton()
                  : _results.isEmpty
                      ? _NoResults(_query)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ResultRow(_results[i]),
                        ),
        ),
      ]),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Content content;
  const _ResultRow(this.content);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(content.subjectId);
    return WinCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ContentDetailScreen(content: content))),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          color: subj.color.withValues(alpha: 0.12),
          child: Icon(subj.icon, size: 22, color: subj.color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 2),
          Text('${content.exam} · ${content.level} · ${content.year}',
              style: WinType.labelM(s.onMuted)),
        ])),
        const SizedBox(width: 8),
        Text(
          content.free ? 'Gratuit' : '${fmtXaf(content.price)} XAF',
          style: WinType.labelM(content.free ? WinColors.success : s.primary)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class _EmptyIdle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search, size: 64, color: s.onFaint),
      const SizedBox(height: 12),
      Text('Recherchez dans le catalogue', style: WinType.bodyM(s.onMuted)),
    ]));
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults(this.query);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off, size: 64, color: s.onFaint),
        const SizedBox(height: 12),
        Text('Aucun résultat pour « $query »',
            style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 68,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WinTheme.of(context).cardBg,
          border: Border.all(color: WinTheme.of(context).outline),
        ),
        child: const Row(children: [
          WinSkeleton(width: 44, height: 44),
          SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            WinSkeleton(height: 14),
            SizedBox(height: 6),
            WinSkeleton(width: 120, height: 11),
          ])),
        ]),
      ),
    );
  }
}
