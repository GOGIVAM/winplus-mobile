import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_detail_screen.dart';

/// Catalogue de formations  composition en grille 2 colonnes (image en
/// tête de carte, tag catégorie incrusté, titre + prix dessous) et rangée
/// de chips catégorie visible sous la recherche, à la manière du kit Funica
/// (grille produit + chips de catégorie), plutôt qu'une liste de tuiles
/// horizontales.
class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});
  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _searchCtrl = TextEditingController();

  List<CourseListItem>? _items;
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _category;
  String? _level;
  bool? _free;

  static const _levels = ['débutant', 'intermédiaire', 'avancé'];
  static const _categories = [
    'Mathématiques',
    'Physique',
    'Informatique',
    'Français',
    'Anglais',
    'Sciences'
  ];

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
    setState(() {
      _loading = true;
    });
    try {
      final result = await CourseService.instance.list(
        category: _category,
        level: _level,
        free: _free,
        page: page,
        pageSize: 12,
      );
      if (mounted)
        setState(() {
          _items = result.items;
          _page = page;
          _totalPages = result.totalPages;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _items = [];
          _loading = false;
        });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      _load();
      return;
    }
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text.trim() != q || !mounted) return;
      setState(() => _loading = true);
      try {
        final results = await CourseService.instance.search(q);
        if (mounted)
          setState(() {
            _items = results;
            _loading = false;
          });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _toggleCategory(String c) {
    setState(() => _category = _category == c ? null : c);
    _load();
  }

  void _showFilters() {
    final s = WinTheme.of(context);
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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: s.outline2,
                            borderRadius:
                                BorderRadius.circular(WinRadii.full)))),
                const SizedBox(height: 16),
                Text('Filtres', style: WinType.headlineS(s.onStrong)),
                const SizedBox(height: 16),
                Text('Niveau', style: WinType.labelM(s.onMuted)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _levels
                        .map((l) => WinChip(
                              l,
                              active: tmpLevel == l,
                              onTap: () => setInner(
                                  () => tmpLevel = tmpLevel == l ? null : l),
                            ))
                        .toList()),
                const SizedBox(height: 16),
                Text('Accès', style: WinType.labelM(s.onMuted)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final opt in [
                    (null, 'Tous'),
                    (true, 'Gratuit'),
                    (false, 'Payant'),
                  ])
                    WinChip(
                      opt.$2,
                      active: tmpFree == opt.$1,
                      onTap: () => setInner(() => tmpFree = opt.$1),
                    ),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: WinButton('Réinitialiser',
                          variant: WinButtonVariant.outline,
                          onTap: () => setInner(() {
                                tmpLevel = null;
                                tmpFree = null;
                              }))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: WinButton('Appliquer', onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _level = tmpLevel;
                      _free = tmpFree;
                    });
                    _load();
                  })),
                ]),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final hasFilter = _level != null || _free != null;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text('Formations',
            style: WinType.archivo(size: 20, color: s.onStrong)),
        backgroundColor: s.surface,
        foregroundColor: s.onStrong,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilter,
              backgroundColor: s.primary,
              child: Icon(Icons.tune_outlined,
                  color: hasFilter ? s.primary : s.onMuted),
            ),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(children: [
        // Recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: WinTextField(
            controller: _searchCtrl,
            hint: 'Rechercher une formation…',
            icon: Icons.search,
            suffixIcon: _searchCtrl.text.isNotEmpty ? Icons.close : null,
            onSuffixTap: () {
              _searchCtrl.clear();
              _load();
            },
          ),
        ),

        // Rangée de chips catégorie  visible, pas cachée dans un tiroir
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => WinChip(
              _categories[i],
              active: _category == _categories[i],
              onTap: () => _toggleCategory(_categories[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Grille produit (2 colonnes)
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_items == null || _items!.isEmpty)
                  ? Center(
                      child: Text('Aucune formation trouvée.',
                          style: WinType.bodyM(s.onMuted)))
                  : RefreshIndicator(
                      onRefresh: () => _load(page: _page),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.66,
                        ),
                        itemCount:
                            _items!.length + (_totalPages > _page ? 2 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _items!.length) {
                            if (i == _items!.length) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child: WinButton('Charger plus',
                                    small: true,
                                    variant: WinButtonVariant.outline,
                                    onTap: () => _load(page: _page + 1)),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return _CourseCard(
                            course: _items![i],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CourseDetailScreen(
                                        courseId: _items![i].id))),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

/// Carte produit style Funica : image plein cadre en tête («65% de la
/// hauteur), tag catégorie incrusté en haut à gauche de l'image, titre et
/// prix en bas.
class _CourseCard extends StatelessWidget {
  final CourseListItem course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = course;

    return WinCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: Stack(fit: StackFit.expand, children: [
            c.thumbnailUrl != null
                ? Image.network(c.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: s.outline2,
                        child: Icon(Icons.play_lesson_outlined,
                            size: 32, color: s.onFaint)))
                : Container(
                    color: s.outline2,
                    child: Icon(Icons.play_lesson_outlined,
                        size: 32, color: s.onFaint)),
            if (c.category != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(WinRadii.full),
                  ),
                  child: Text(c.category!,
                      style: WinType.labelS(Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: _priceTag(c),
            ),
          ]),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title,
                  style: WinType.titleM(s.onStrong),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(children: [
                Icon(Icons.schedule_outlined, size: 12, color: s.onMuted),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(c.durationStr,
                        style: WinType.labelS(s.onMuted),
                        overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _priceTag(CourseListItem c) {
    if (c.isFree)
      return _PriceBadge('Gratuit', WinColors.teal700, Colors.white);
    if (c.isIncludedInSub)
      return _PriceBadge('Premium', WinColors.teal700, Colors.white);
    return _PriceBadge(
        '${c.price.toInt()} XAF', WinColors.ink800, Colors.white);
  }
}

class _PriceBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _PriceBadge(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(WinRadii.full)),
        child: Text(label,
            style: WinType.labelS(fg).copyWith(fontWeight: FontWeight.w700)),
      );
}
