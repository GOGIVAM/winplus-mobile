import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_catalog_screen.dart';
import 'course_player_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});
  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<MyEnrollment>? _enrollments;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _enrollments = null; _error = false; });
    try {
      final data = await CourseService.instance.myCourses();
      if (mounted) setState(() => _enrollments = data);
    } catch (_) {
      if (mounted) setState(() { _enrollments = []; _error = true; });
    }
  }

  void _goToCatalog() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CourseCatalogScreen()));

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text('Mes formations', style: WinType.archivo(size: 20, color: s.onStrong)),
        backgroundColor: s.surface,
        foregroundColor: s.onStrong,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.explore_outlined, size: 18, color: s.primary),
            label: Text('Catalogue', style: WinType.labelM(s.primary)),
            onPressed: _goToCatalog,
          ),
        ],
      ),
      body: _enrollments == null
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Impossible de charger vos formations.', style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  WinButton('Réessayer', onTap: _load),
                ]))
              : _enrollments!.isEmpty
                  ? _EmptyState(onExplore: _goToCatalog)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _enrollments!.length,
                        itemBuilder: (_, i) {
                          final e = _enrollments![i];
                          return _CourseCard(
                            enrollment: e,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CoursePlayerScreen(
                                courseId: e.courseId,
                                courseTitle: e.courseTitle,
                              )),
                            ).then((_) => _load()),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final MyEnrollment enrollment;
  final VoidCallback onTap;
  const _CourseCard({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final e = enrollment;
    final pct = e.progressPercent.clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WinCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: e.thumbnailUrl != null
                    ? Image.network(e.thumbnailUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ThumbPlaceholder())
                    : _ThumbPlaceholder(),
              ),
              if (e.isCompleted)
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    color: WinColors.teal600.withValues(alpha: 0.75),
                    child: const Icon(Icons.workspace_premium, size: 40, color: Colors.white),
                  ),
                ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (e.category != null)
                Text(e.category!.toUpperCase(),
                    style: WinType.labelS(s.primary).copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(e.courseTitle,
                  style: WinType.titleM(s.onStrong),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(e.instructorName, style: WinType.labelM(s.onMuted)),
              const SizedBox(height: 10),

              // Progress bar
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: s.outline2,
                    color: s.primary,
                  ),
                )),
                const SizedBox(width: 10),
                Text('${pct.toInt()}%',
                    style: WinType.labelM(s.primary).copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),

              Row(children: [
                Icon(Icons.play_circle_outline, size: 14, color: s.onMuted),
                const SizedBox(width: 4),
                Text('${e.lessonsCount} leçons', style: WinType.labelM(s.onMuted)),
                const SizedBox(width: 12),
                Icon(Icons.schedule_outlined, size: 14, color: s.onMuted),
                const SizedBox(width: 4),
                Text(e.durationStr, style: WinType.labelM(s.onMuted)),
              ]),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: e.isCompleted ? WinColors.teal100 : s.primary,
                    foregroundColor: e.isCompleted ? WinColors.teal700 : s.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(e.isCompleted ? Icons.replay : Icons.play_arrow, size: 18),
                  label: Text(
                    e.isCompleted ? 'Revoir' : pct > 0 ? 'Continuer' : 'Commencer',
                    style: WinType.titleM(e.isCompleted ? WinColors.teal700 : s.onPrimary),
                  ),
                  onPressed: onTap,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      color: s.outline2,
      child: Icon(Icons.play_lesson_outlined, size: 40, color: s.onFaint),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 72, color: s.onFaint),
          const SizedBox(height: 20),
          Text('Aucune formation en cours', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 8),
          Text(
            'Explorez notre catalogue et commencez à apprendre dès aujourd\'hui.',
            style: WinType.bodyM(s.onMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          WinButton('Explorer les formations', onTap: onExplore),
        ]),
      ),
    );
  }
}
