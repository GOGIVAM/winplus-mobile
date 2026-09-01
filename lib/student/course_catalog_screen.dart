import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_detail_screen.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});
  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _searchCtrl = TextEditingController();

  List<CourseListItem>? _items;
  bool _loading = true;
  bool _searching = false;
  int _page = 1;
  int _totalPages = 1;
  String? _category;
  String? _level;
  bool? _free;

  static const _levels = ['débutant', 'intermédiaire', 'avancé'];
  static const _categories = ['Mathématiques', 'Physique', 'Informatique', 'Français', 'Anglais', 'Sciences'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; });
    try {
      final result = await CourseService.instance.list(
        category: _category,
        level: _level,
        free: _free,
        page: page,
        pageSize: 12,
      );
      if (mounted) setState(() {
        _items = result.items;
        _page = page;
        _totalPages = result.totalPages;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _items = []; _loading = false; });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) { _load(); return; }
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text.trim() != q || !mounted) return;
      setState(() => _searching = true);
      try {
        final results = await CourseService.instance.search(q);
        if (mounted) setState(() { _items = results; _searching = false; });
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _showFilters() {
    final s = WinTheme.of(context);
    String? tmpCat = _category;
    String? tmpLevel = _level;
    bool? tmpFree = _free;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Container(
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: s.outline2, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Filtres', style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 16),
            Text('Niveau', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _levels.map((l) => FilterChip(
              label: Text(l, style: WinType.labelM(tmpLevel == l ? WinColors.teal700 : s.onStrong)),
              selected: tmpLevel == l,
              onSelected: (v) => setInner(() => tmpLevel = v ? l : null),
              selectedColor: WinColors.teal50,
              checkmarkColor: WinColors.teal600,
              backgroundColor: s.surface2,
              side: BorderSide(color: tmpLevel == l ? WinColors.teal400 : s.outline),
            )).toList()),
            const SizedBox(height: 12),
            Text('Catégorie', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: _categories.map((c) => FilterChip(
              label: Text(c, style: WinType.labelM(tmpCat == c ? WinColors.teal700 : s.onStrong)),
              selected: tmpCat == c,
              onSelected: (v) => setInner(() => tmpCat = v ? c : null),
              selectedColor: WinColors.teal50,
              checkmarkColor: WinColors.teal600,
              backgroundColor: s.surface2,
              side: BorderSide(color: tmpCat == c ? WinColors.teal400 : s.outline),
            )).toList()),
            const SizedBox(height: 12),
            Text('Accès', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Row(children: [
              for (final opt in [
                (null, 'Tous'),
                (true, 'Gratuit'),
                (false, 'Payant'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opt.$2, style: WinType.labelM(tmpFree == opt.$1 ? WinColors.teal700 : s.onStrong)),
                    selected: tmpFree == opt.$1,
                    onSelected: (_) => setInner(() => tmpFree = opt.$1),
                    selectedColor: WinColors.teal50,
                    backgroundColor: s.surface2,
                    side: BorderSide(color: tmpFree == opt.$1 ? WinColors.teal400 : s.outline),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () {
                  setInner(() { tmpCat = null; tmpLevel = null; tmpFree = null; });
                },
                child: Text('Réinitialiser', style: WinType.labelM(s.onMuted)),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: s.primary),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() { _category = tmpCat; _level = tmpLevel; _free = tmpFree; });
                  _load();
                },
                child: Text('Appliquer', style: WinType.labelM(s.onPrimary)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final hasFilter = _category != null || _level != null || _free != null;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text('Formations', style: WinType.archivo(size: 20, color: s.onStrong)),
        backgroundColor: s.surface,
        foregroundColor: s.onStrong,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilter,
              backgroundColor: s.primary,
              child: Icon(Icons.tune_outlined, color: hasFilter ? s.primary : s.onMuted),
            ),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher une formation…',
              hintStyle: WinType.bodyM(s.onFaint),
              prefixIcon: Icon(Icons.search, color: s.onMuted, size: 20),
              suffixIcon: _searching
                  ? Padding(padding: const EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: s.primary)))
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, color: s.onMuted, size: 18),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
              filled: true,
              fillColor: s.surface2,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: WinType.bodyM(s.onStrong),
          ),
        ),

        // List / Grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_items == null || _items!.isEmpty)
                  ? Center(child: Text('Aucune formation trouvée.', style: WinType.bodyM(s.onMuted)))
                  : RefreshIndicator(
                      onRefresh: () => _load(page: _page),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _items!.length + (_totalPages > _page ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _items!.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: WinButton('Charger plus', onTap: () => _load(page: _page + 1)),
                            );
                          }
                          return _CourseTile(
                            course: _items![i],
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: _items![i].id))),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final CourseListItem course;
  final VoidCallback onTap;
  const _CourseTile({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = course;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: s.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.cardBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: SizedBox(
              width: 110, height: 82,
              child: c.thumbnailUrl != null
                  ? Image.network(c.thumbnailUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: s.outline2,
                          child: Icon(Icons.play_lesson_outlined, color: s.onFaint)))
                  : Container(color: s.outline2,
                      child: Icon(Icons.play_lesson_outlined, color: s.onFaint)),
            ),
          ),
          // Info
          Expanded(child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (c.category != null)
                Text(c.category!.toUpperCase(),
                    style: WinType.labelS(s.primary).copyWith(letterSpacing: 0.4)),
              Text(c.title, style: WinType.titleM(s.onStrong), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_outlined, size: 12, color: s.onMuted),
                const SizedBox(width: 3),
                Text(c.durationStr, style: WinType.labelS(s.onMuted)),
                const SizedBox(width: 8),
                Icon(Icons.play_circle_outline, size: 12, color: s.onMuted),
                const SizedBox(width: 3),
                Text('${c.lessonsCount} leçons', style: WinType.labelS(s.onMuted)),
              ]),
              const SizedBox(height: 4),
              // Price badge
              c.isFree
                  ? _PriceBadge('Gratuit', WinColors.teal600, WinColors.teal50)
                  : c.isIncludedInSub
                      ? _PriceBadge('Premium', WinColors.teal700, WinColors.teal50)
                      : Text('${c.price.toInt()} XAF',
                          style: WinType.labelM(s.onStrong).copyWith(fontWeight: FontWeight.w700)),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _PriceBadge(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: WinType.labelS(fg).copyWith(fontWeight: FontWeight.w700)),
      );
}
