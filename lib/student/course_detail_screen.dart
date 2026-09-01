import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseDetail? _course;
  bool _loading = true;
  bool _enrolling = false;
  String? _error;
  final Set<int> _openSections = {0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await CourseService.instance.get(widget.courseId);
      if (mounted) setState(() { _course = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Formation introuvable.'; });
    }
  }

  Future<void> _enroll() async {
    final c = _course;
    if (c == null) return;
    setState(() => _enrolling = true);
    try {
      await CourseService.instance.enroll(c.id);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => CoursePlayerScreen(courseId: c.id, courseTitle: c.title),
      ));
    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur lors de l\'inscription.'; _enrolling = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (_loading) return Scaffold(backgroundColor: s.bg, body: const Center(child: CircularProgressIndicator()));
    if (_course == null) return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(backgroundColor: s.surface, foregroundColor: s.onStrong, elevation: 0),
      body: Center(child: Text(_error ?? 'Erreur', style: WinType.bodyM(s.onMuted))),
    );

    final c = _course!;
    final totalLessons = c.sections.fold(0, (a, s) => a + s.lessons.length);

    return Scaffold(
      backgroundColor: s.bg,
      body: CustomScrollView(slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: c.thumbnailUrl != null ? 220 : 120,
          pinned: true,
          backgroundColor: WinColors.ink900,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: c.thumbnailUrl != null
                ? Image.network(c.thumbnailUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: WinColors.ink900))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [WinColors.ink900, WinColors.ink700],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            title: Text(c.title,
                style: WinType.titleM(Colors.white).copyWith(shadows: [
                  const Shadow(color: Colors.black54, blurRadius: 4),
                ]),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category + level chips
            Wrap(spacing: 8, children: [
              if (c.category != null) WinBadge(c.category!),
              if (c.level != null) WinBadge(c.level!, color: BadgeColor.neutral),
            ]),
            const SizedBox(height: 12),

            // Stats row
            Row(children: [
              Icon(Icons.people_outline, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text('${c.enrolledCount} inscrits', style: WinType.labelM(s.onMuted)),
              const SizedBox(width: 12),
              Icon(Icons.schedule_outlined, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text(c.durationStr, style: WinType.labelM(s.onMuted)),
              const SizedBox(width: 12),
              Icon(Icons.play_circle_outline, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text('$totalLessons leçons', style: WinType.labelM(s.onMuted)),
            ]),

            if (c.avgRating > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                ...List.generate(5, (i) => Icon(
                  i < c.avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16, color: WinColors.gold,
                )),
                const SizedBox(width: 6),
                Text('${c.avgRating.toStringAsFixed(1)} (${c.reviewsCount} avis)',
                    style: WinType.labelM(s.onMuted)),
              ]),
            ],

            const SizedBox(height: 16),

            // Price + CTA
            WinCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                c.isFree ? 'Gratuit' : c.isIncludedInSub ? 'Inclus dans l\'abonnement Premium' : '${c.price.toInt()} XAF',
                style: WinType.archivo(size: 22, color: c.isFree || c.isIncludedInSub ? WinColors.teal600 : s.onStrong),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: WinType.bodyS(WinColors.error)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: s.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(c.isEnrolled ? Icons.play_arrow : Icons.school_outlined, size: 20),
                  label: Text(
                    c.isEnrolled ? 'Continuer la formation' : c.isFree ? 'Commencer gratuitement' : 'S\'inscrire',
                    style: WinType.titleM(s.onPrimary),
                  ),
                  onPressed: _enrolling ? null : () {
                    if (c.isEnrolled) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CoursePlayerScreen(courseId: c.id, courseTitle: c.title),
                      ));
                    } else {
                      _enroll();
                    }
                  },
                ),
              ),
              if (c.certificateEnabled) ...[
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.workspace_premium_outlined, size: 14, color: s.onMuted),
                  const SizedBox(width: 6),
                  Text('Certificat de réussite inclus', style: WinType.labelM(s.onMuted)),
                ]),
              ],
            ])),

            // Objectives
            if (c.objectives.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Ce que vous apprendrez', style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(child: Column(children: c.objectives.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_outline, size: 16, color: s.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(o, style: WinType.bodyM(s.onSurface))),
                ]),
              )).toList())),
            ],

            // Requirements
            if (c.requirements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Prérequis', style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(child: Column(children: c.requirements.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.arrow_right, size: 18, color: s.onMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r, style: WinType.bodyM(s.onSurface))),
                ]),
              )).toList())),
            ],

            // Description
            if (c.description != null && c.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Description', style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(child: Text(c.description!, style: WinType.bodyM(s.onSurface))),
            ],

            // Curriculum
            const SizedBox(height: 20),
            Text('Contenu', style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 4),
            Text('${c.sections.length} sections · $totalLessons leçons · ${c.durationStr}',
                style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 10),
            ...c.sections.asMap().entries.map((entry) {
              final i = entry.key;
              final sec = entry.value;
              final open = _openSections.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: s.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: s.cardBorder),
                ),
                child: Column(children: [
                  InkWell(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    onTap: () => setState(() {
                      if (open) { _openSections.remove(i); } else { _openSections.add(i); }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Expanded(child: Text(sec.title, style: WinType.titleM(s.onStrong))),
                        Text('${sec.lessons.length}', style: WinType.labelM(s.onMuted)),
                        const SizedBox(width: 4),
                        Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 20, color: s.onMuted),
                      ]),
                    ),
                  ),
                  if (open) ...sec.lessons.map((l) => _LessonRow(lesson: l)),
                ]),
              );
            }),

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final CourseLesson lesson;
  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.outline2)),
      ),
      child: Row(children: [
        Icon(
          lesson.isPreview ? Icons.play_circle_outline : Icons.lock_outline,
          size: 16,
          color: lesson.isPreview ? s.primary : s.onFaint,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(lesson.title, style: WinType.bodyM(s.onSurface))),
        if (lesson.isPreview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: WinColors.teal50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Aperçu', style: WinType.labelS(WinColors.teal600)),
          ),
        if (lesson.videoDurationSec > 0) ...[
          const SizedBox(width: 8),
          Text(lesson.durationStr, style: WinType.labelS(s.onMuted)),
        ],
      ]),
    );
  }
}
