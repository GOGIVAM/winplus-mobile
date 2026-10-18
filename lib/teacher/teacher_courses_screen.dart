import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class _TeacherCourse {
  final int id;
  final String title;
  final String slug;
  final String status;
  final String category;
  final String level;
  final num price;
  final bool isFree;
  final int enrolledCount;
  final double avgRating;
  final int lessonsCount;
  final String createdAt;

  const _TeacherCourse({
    required this.id,
    required this.title,
    required this.slug,
    required this.status,
    required this.category,
    required this.level,
    required this.price,
    required this.isFree,
    required this.enrolledCount,
    required this.avgRating,
    required this.lessonsCount,
    required this.createdAt,
  });

  factory _TeacherCourse.fromJson(Map<String, dynamic> j) => _TeacherCourse(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        status: j['status'] as String? ?? 'draft',
        category: j['category'] as String? ?? '',
        level: j['level'] as String? ?? '',
        price: j['price'] as num? ?? 0,
        isFree: j['isFree'] as bool? ?? false,
        enrolledCount: (j['enrolledCount'] as num?)?.toInt() ?? 0,
        avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
        lessonsCount: (j['lessonsCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Status helpers
// ---------------------------------------------------------------------------

String _statusLabel(String status) => switch (status) {
      'draft' => 'Brouillon',
      'pending_review' => 'En révision',
      'published' => 'Publié',
      'archived' => 'Archivé',
      _ => status,
    };

BadgeColor _statusBadgeColor(String status) => switch (status) {
      'draft' => BadgeColor.neutral,
      'pending_review' => BadgeColor.warn,
      'published' => BadgeColor.success,
      'archived' => BadgeColor.error,
      _ => BadgeColor.neutral,
    };

Color _statusThumbnailColor(String status) => switch (status) {
      'draft' => WinColors.ink300,
      'pending_review' => WinColors.warn,
      'published' => WinColors.teal600,
      'archived' => WinColors.error,
      _ => WinColors.ink300,
    };

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  static const _filterAll = 'Tout';
  static const _filters = [
    _filterAll,
    'draft',
    'pending_review',
    'published',
    'archived',
  ];

  String _activeFilter = _filterAll;
  List<_TeacherCourse>? _courses;
  String? _error;
  // Lot 9.7b : formations publiées simultanément selon le plan.
  Map<String, dynamic>? _limit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _courses = null;
      _error = null;
    });
    ApiClient.instance.dio
        .get<dynamic>('/teacher/courses/publication-limit')
        .then((r) {
      if (mounted && r.data is Map<String, dynamic>) {
        setState(() => _limit = r.data as Map<String, dynamic>);
      }
    }).catchError((_) {});
    try {
      final response =
          await ApiClient.instance.dio.get<dynamic>('/teacher/courses');
      final data = response.data;
      final list = (data is List ? data : (data['data'] as List? ?? []));
      if (mounted) {
        setState(() {
          _courses = list
              .map((e) => _TeacherCourse.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les formations.';
          _courses = [];
        });
      }
    }
  }

  List<_TeacherCourse> get _filteredCourses {
    final all = _courses ?? [];
    if (_activeFilter == _filterAll) return all;
    return all.where((c) => c.status == _activeFilter).toList();
  }

  String _filterLabel(String f) => switch (f) {
        _filterAll => 'Tout',
        _ => _statusLabel(f),
      };

  /// Adresse de l'éditeur de formations du site (tableau de bord enseignant).
  static const _webCourseEditorUrl =
      'https://winplus.cm/professeur?view=formations';

  /// La création et l'édition d'une formation (leçons, vidéos, quiz) se font
  /// sur le site : l'application ne propose pas d'éditeur. On l'indique
  /// clairement, avec l'adresse à ouvrir, plutôt qu'une promesse.
  void _showCourseFab() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer une formation'),
        content: const Text(
            "La création et l'édition des formations se font sur le site WinPlus, "
            'depuis votre espace enseignant, avec le même compte :\n\n'
            '$_webCourseEditorUrl\n\n'
            'Vos formations apparaissent ensuite ici.'),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              await Clipboard.setData(
                  const ClipboardData(text: _webCourseEditorUrl));
              nav.pop();
              messenger.showSnackBar(const SnackBar(
                  content: Text('Lien copié : ouvrez-le dans votre navigateur.')));
            },
            child: const Text('Copier le lien'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCourseOptions(_TeacherCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseOptionsSheet(
        course: course,
        onRefresh: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes formations',
          style: WinType.archivo(size: 20, color: s.onStrong),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onMuted),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                return WinChip(
                  _filterLabel(f),
                  active: _activeFilter == f,
                  onTap: () => setState(() => _activeFilter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_limit != null) _LimitBanner(limit: _limit!),
          // List
          Expanded(child: _buildBody(s)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: s.primary,
        foregroundColor: s.onPrimary,
        onPressed: _showCourseFab,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(WinScheme s) {
    if (_courses == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 12),
              Text(_error!,
                  style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              WinButton('Réessayer',
                  variant: WinButtonVariant.outline,
                  icon: Icons.refresh,
                  onTap: _load),
            ],
          ),
        ),
      );
    }
    final items = _filteredCourses;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 12),
              Text(
                _activeFilter == _filterAll
                    ? 'Vous n\'avez pas encore de formation.'
                    : 'Aucune formation avec ce statut.',
                style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: s.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CourseCard(
          course: items[i],
          onTap: () => _showCourseOptions(items[i]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Course card
// ---------------------------------------------------------------------------

class _CourseCard extends StatelessWidget {
  final _TeacherCourse course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _statusThumbnailColor(course.status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WinRadii.md),
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 36,
                  color: _statusThumbnailColor(course.status),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: WinBadge(
                  _statusLabel(course.status),
                  color: _statusBadgeColor(course.status),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.titleM(s.onStrong),
                  ),
                  const SizedBox(height: 4),
                  if (course.category.isNotEmpty)
                    Text(
                      course.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WinType.labelS(s.onMuted),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.menu_book_outlined,
                        label:
                            '${course.lessonsCount} leçon${course.lessonsCount != 1 ? 's' : ''}',
                        color: s.onMuted,
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: Icons.people_outline,
                        label:
                            '${course.enrolledCount} inscrit${course.enrolledCount != 1 ? 's' : ''}',
                        color: s.onMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Icon(Icons.more_vert, size: 18, color: s.onFaint),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label, style: WinType.labelS(color)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Course options bottom sheet
// ---------------------------------------------------------------------------

class _CourseOptionsSheet extends StatefulWidget {
  final _TeacherCourse course;
  final VoidCallback onRefresh;

  const _CourseOptionsSheet({required this.course, required this.onRefresh});

  @override
  State<_CourseOptionsSheet> createState() => _CourseOptionsSheetState();
}

class _CourseOptionsSheetState extends State<_CourseOptionsSheet> {
  bool _loadingDetail = false;
  bool _deletePending = false;

  // ---- View detail --------------------------------------------------------

  Future<void> _viewDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final response = await ApiClient.instance.dio
          .get<dynamic>('/teacher/courses/${widget.course.id}');
      if (!mounted) return;
      Navigator.of(context).pop();
      _showDetailDialog(response.data as Map<String, dynamic>? ?? {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les détails.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final s = WinTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final title = data['title'] as String? ?? widget.course.title;
        final description = data['description'] as String? ?? '';
        final lessonsCount = (data['lessonsCount'] as num?)?.toInt() ??
            widget.course.lessonsCount;
        final enrolledCount = (data['enrolledCount'] as num?)?.toInt() ??
            widget.course.enrolledCount;
        final avgRating =
            (data['avgRating'] as num?)?.toDouble() ?? widget.course.avgRating;
        final status = data['status'] as String? ?? widget.course.status;
        return AlertDialog(
          backgroundColor: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WinRadii.lg)),
          title:
              Text(title, style: WinType.archivo(size: 18, color: s.onStrong)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                WinBadge(_statusLabel(status),
                    color: _statusBadgeColor(status)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(description, style: WinType.bodyM(s.onSurface)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.menu_book_outlined, size: 14, color: s.onMuted),
                  const SizedBox(width: 4),
                  Text('$lessonsCount leçon${lessonsCount != 1 ? 's' : ''}',
                      style: WinType.labelM(s.onMuted)),
                  const SizedBox(width: 14),
                  Icon(Icons.people_outline, size: 14, color: s.onMuted),
                  const SizedBox(width: 4),
                  Text('$enrolledCount inscrits',
                      style: WinType.labelM(s.onMuted)),
                  if (avgRating > 0) ...[
                    const SizedBox(width: 14),
                    const Icon(Icons.star_outline,
                        size: 14, color: WinColors.gold),
                    const SizedBox(width: 4),
                    Text(avgRating.toStringAsFixed(1),
                        style: WinType.labelM(s.onMuted)),
                  ],
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Fermer',
                  style: WinType.manrope(
                      size: 14, weight: FontWeight.w600, color: s.primary)),
            ),
          ],
        );
      },
    );
  }

  // ---- Submit for review ------------------------------------------------
  // La publication passe par la validation de l'équipe : POST /submit. Lot
  // 9.7b : le serveur applique la limite de formations publiées du plan
  // (teacher.max_published_courses) et renvoie un message clair si elle est
  // atteinte. L'ancien sélecteur « Modifier le statut » envoyait un statut
  // que le serveur ignorait, tout en affichant un succès.

  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio
          .post<dynamic>('/teacher/courses/${widget.course.id}/submit', data: {});
      widget.onRefresh();
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Formation soumise à validation.')));
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['error'] as String? : null;
      messenger.showSnackBar(SnackBar(
          content: Text(msg ?? "La formation n'a pas pu être soumise.")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---- Delete --------------------------------------------------------------

  void _confirmDelete() {
    Navigator.of(context).pop();
    final s = WinTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.lg)),
        title: Text('Supprimer la formation ?',
            style: WinType.archivo(size: 18, color: s.onStrong)),
        content: Text(
          'Cette action est irréversible. La formation « ${widget.course.title} » sera définitivement supprimée.',
          style: WinType.bodyM(s.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler',
                style: WinType.manrope(
                    size: 14, weight: FontWeight.w600, color: s.onMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteCourse();
            },
            child: Text('Supprimer',
                style: WinType.manrope(
                    size: 14, weight: FontWeight.w600, color: WinColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse() async {
    setState(() => _deletePending = true);
    try {
      await ApiClient.instance.dio
          .delete<dynamic>('/teacher/courses/${widget.course.id}');
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formation supprimée.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de supprimer la formation.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletePending = false);
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: s.outline,
                borderRadius: BorderRadius.circular(WinRadii.full),
              ),
            ),
          ),
          // Course header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.course.title,
                  style: WinType.archivo(size: 18, color: s.onStrong),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              WinBadge(
                _statusLabel(widget.course.status),
                color: _statusBadgeColor(widget.course.status),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Options
          _OptionTile(
            icon: Icons.visibility_outlined,
            label: 'Voir détails',
            loading: _loadingDetail,
            onTap: _loadingDetail ? null : _viewDetail,
            s: s,
          ),
          if (widget.course.status == 'draft' || widget.course.status == 'archived')
            _OptionTile(
              icon: Icons.send_outlined,
              label: 'Soumettre à validation',
              loading: _submitting,
              onTap: _submitting ? null : _submit,
              s: s,
            ),
          _OptionTile(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: WinColors.error,
            loading: _deletePending,
            onTap: _deletePending ? null : _confirmDelete,
            s: s,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool loading;
  final VoidCallback? onTap;
  final WinScheme s;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.s,
    this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? s.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                : Icon(icon, size: 22, color: fg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: WinType.manrope(
                    size: 15, weight: FontWeight.w500, color: fg),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: s.onFaint),
          ],
        ),
      ),
    );
  }
}

/// Lot 9.7b : « Formations publiées : X / max » (droit du plan).
class _LimitBanner extends StatelessWidget {
  final Map<String, dynamic> limit;
  const _LimitBanner({required this.limit});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final unlimited = limit['unlimited'] == true;
    final max = (limit['max'] as num?)?.toInt();
    final published = (limit['published'] as num?)?.toInt() ?? 0;
    final pending = (limit['pending'] as num?)?.toInt() ?? 0;
    final remaining = (limit['remaining'] as num?)?.toInt();
    final text = unlimited
        ? 'Votre plan permet de publier un nombre illimité de formations.'
        : 'Formations publiées : $published / ${max ?? 0}'
            '${pending > 0 ? ' · $pending en attente de validation' : ''}'
            '${remaining == 0 ? ' · limite de votre plan atteinte : passez à un plan supérieur pour en publier davantage.' : ''}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: remaining == 0 ? s.surface2 : s.surface,
          borderRadius: BorderRadius.circular(WinRadii.md),
          border: Border.all(color: s.outline)),
      child: Text(text, style: WinType.bodyS(s.onStrong)),
    );
  }
}
