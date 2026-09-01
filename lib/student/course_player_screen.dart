import 'dart:async';
import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class CoursePlayerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final int? initialLessonId;

  const CoursePlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.initialLessonId,
  });

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  CourseCurriculum? _curriculum;
  LessonContent? _lesson;
  bool _loadingCurr = true;
  bool _loadingLesson = false;
  bool _sidebarOpen = false;
  double _progressPercent = 0;
  bool _courseCompleted = false;
  int? _currentLessonId;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurriculum() async {
    try {
      final data = await CourseService.instance.getCurriculum(widget.courseId);
      if (!mounted) return;
      setState(() {
        _curriculum = data;
        _progressPercent = data.progressPercent;
        _courseCompleted = data.completedAt != null;
        _loadingCurr = false;
      });
      // Navigate to first incomplete or specified lesson
      final lessonId = widget.initialLessonId ??
          data.allLessons.firstWhere((l) => !l.isCompleted,
              orElse: () => data.allLessons.first).id;
      _loadLesson(lessonId);
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadLesson(int lessonId) async {
    setState(() { _loadingLesson = true; _currentLessonId = lessonId; });
    try {
      final lesson = await CourseService.instance.getLesson(widget.courseId, lessonId);
      if (mounted) setState(() { _lesson = lesson; _loadingLesson = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLesson = false);
    }
  }

  Future<void> _markComplete() async {
    final l = _lesson;
    if (l == null) return;
    try {
      final result = await CourseService.instance.saveProgress(
        widget.courseId,
        l.id,
        watchTimeSec: l.videoDurationSec,
        lastPositionSec: 0,
        isCompleted: true,
      );
      if (!mounted) return;
      setState(() {
        _progressPercent = result.progressPercent;
        _courseCompleted = result.courseCompleted;
        _lesson = LessonContent(
          id: l.id, title: l.title, lessonType: l.lessonType,
          description: l.description, videoUrl: l.videoUrl,
          videoDurationSec: l.videoDurationSec, articleContent: l.articleContent,
          fileUrl: l.fileUrl, fileName: l.fileName,
          isPreview: l.isPreview, isCompleted: true, lastPositionSec: 0,
        );
        _curriculum = _curriculum == null ? null : CourseCurriculum(
          courseId: _curriculum!.courseId,
          title: _curriculum!.title,
          progressPercent: result.progressPercent,
          completedAt: result.courseCompleted ? DateTime.now().toIso8601String() : _curriculum!.completedAt,
          certificateUrl: _curriculum!.certificateUrl,
          sections: _curriculum!.sections.map((sec) => CurriculumSection(
            id: sec.id, title: sec.title, position: sec.position,
            lessons: sec.lessons.map((ll) => ll.id == l.id
                ? CurriculumLesson(
                    id: ll.id, title: ll.title, lessonType: ll.lessonType,
                    videoDurationSec: ll.videoDurationSec, position: ll.position,
                    isPreview: ll.isPreview, isCompleted: true, lastPositionSec: 0)
                : ll).toList(),
          )).toList(),
        );
      });
      if (result.courseCompleted) _showCompletionDialog();
    } catch (_) {}
  }

  void _showCompletionDialog() {
    final s = WinTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: s.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          const Icon(Icons.workspace_premium, size: 56, color: WinColors.gold),
          const SizedBox(height: 12),
          Text('Formation terminée !', style: WinType.headlineS(s.onStrong), textAlign: TextAlign.center),
        ]),
        content: Text('Félicitations ! Votre certificat est en cours de génération.',
            style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
        actions: [
          Center(child: WinButton('Fermer', onTap: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  List<CurriculumLesson> get _allLessons =>
      _curriculum?.allLessons ?? [];

  CurriculumLesson? get _prevLesson {
    final idx = _allLessons.indexWhere((l) => l.id == _currentLessonId);
    return idx > 0 ? _allLessons[idx - 1] : null;
  }

  CurriculumLesson? get _nextLesson {
    final idx = _allLessons.indexWhere((l) => l.id == _currentLessonId);
    return idx >= 0 && idx < _allLessons.length - 1 ? _allLessons[idx + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.courseTitle,
              style: WinType.labelM(Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_lesson != null)
            Text(_lesson!.title,
                style: WinType.titleM(Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _progressPercent / 100,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    color: WinColors.teal400,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('${_progressPercent.toInt()}%',
                  style: WinType.labelS(Colors.white70)),
            ]),
          ),
          // Curriculum toggle
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Curriculum',
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
        ],
      ),
      body: _loadingCurr
          ? const Center(child: CircularProgressIndicator(color: WinColors.teal400))
          : Column(children: [
              Expanded(child: _sidebarOpen ? _CurriculumPanel(
                curriculum: _curriculum!,
                currentLessonId: _currentLessonId,
                onSelect: (id) {
                  setState(() => _sidebarOpen = false);
                  _loadLesson(id);
                },
              ) : _LessonView(
                lesson: _lesson,
                loading: _loadingLesson,
                courseCompleted: _courseCompleted,
                onMarkComplete: _markComplete,
              )),

              // Bottom nav bar
              _BottomNav(
                prev: _prevLesson,
                next: _nextLesson,
                isCompleted: _lesson?.isCompleted ?? false,
                onPrev: () { if (_prevLesson != null) _loadLesson(_prevLesson!.id); },
                onNext: () { if (_nextLesson != null) _loadLesson(_nextLesson!.id); },
                onComplete: _markComplete,
              ),
            ]),
    );
  }
}

// ─── Curriculum sidebar ───────────────────────────────────────────────────────

class _CurriculumPanel extends StatelessWidget {
  final CourseCurriculum curriculum;
  final int? currentLessonId;
  final void Function(int) onSelect;

  const _CurriculumPanel({
    required this.curriculum,
    required this.currentLessonId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      child: ListView.builder(
        itemCount: curriculum.sections.length,
        itemBuilder: (_, si) {
          final sec = curriculum.sections[si];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(sec.title,
                  style: WinType.labelM(Colors.white38).copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            ...sec.lessons.map((l) {
              final active = l.id == currentLessonId;
              return InkWell(
                onTap: () => onSelect(l.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: active ? WinColors.teal600.withValues(alpha: 0.15) : Colors.transparent,
                  child: Row(children: [
                    Icon(
                      l.isCompleted ? Icons.check_circle : (active ? Icons.play_circle : Icons.radio_button_unchecked),
                      size: 18,
                      color: l.isCompleted ? WinColors.teal400 : (active ? Colors.white : Colors.white38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.title,
                        style: WinType.bodyM(active ? Colors.white : Colors.white70),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (l.lessonType == 'video' && l.videoDurationSec > 0)
                      Text(l.durationStr, style: WinType.labelS(Colors.white38)),
                  ]),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

// ─── Lesson content view ──────────────────────────────────────────────────────

class _LessonView extends StatelessWidget {
  final LessonContent? lesson;
  final bool loading;
  final bool courseCompleted;
  final VoidCallback onMarkComplete;

  const _LessonView({
    required this.lesson,
    required this.loading,
    required this.courseCompleted,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: WinColors.teal400));
    }
    if (lesson == null) {
      return Center(child: Text('Sélectionnez une leçon.',
          style: WinType.bodyM(Colors.white38)));
    }

    final l = lesson!;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Video placeholder (real implementation needs video_player package)
        if (l.lessonType == 'video' && l.videoUrl != null)
          _VideoPlaceholder(videoUrl: l.videoUrl!, durationSec: l.videoDurationSec),

        // Article content
        if (l.lessonType == 'article' && l.articleContent != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l.articleContent!,
                style: WinType.bodyM(Colors.white).copyWith(height: 1.7)),
          ),

        // File download
        if (l.lessonType == 'file' && l.fileUrl != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WinColors.teal600.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.attach_file, color: WinColors.teal400, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.fileName ?? 'Fichier joint',
                    style: WinType.titleM(Colors.white)),
                Text('Appuyez pour télécharger', style: WinType.labelS(Colors.white54)),
              ])),
              const Icon(Icons.download_outlined, color: WinColors.teal400),
            ]),
          ),

        // Lesson info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l.title,
                  style: WinType.headlineS(Colors.white))),
              if (l.isCompleted)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 16, color: WinColors.teal400),
                  const SizedBox(width: 4),
                  Text('Terminé', style: WinType.labelM(WinColors.teal400)),
                ]),
            ]),
            if (l.description != null && l.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.description!, style: WinType.bodyM(Colors.white60)),
            ],
            if (courseCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [WinColors.teal700, WinColors.teal600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Formation terminée !',
                        style: WinType.titleM(Colors.white).copyWith(fontWeight: FontWeight.w700)),
                    Text('Votre certificat est disponible.',
                        style: WinType.labelM(Colors.white70)),
                  ])),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String videoUrl;
  final int durationSec;
  const _VideoPlaceholder({required this.videoUrl, required this.durationSec});

  @override
  Widget build(BuildContext context) {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return Container(
      width: double.infinity,
      height: 210,
      color: Colors.black,
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.play_circle_filled, size: 64, color: Colors.white.withValues(alpha: 0.85)),
        Positioned(
          bottom: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$m:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── Bottom navigation bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final CurriculumLesson? prev;
  final CurriculumLesson? next;
  final bool isCompleted;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const _BottomNav({
    required this.prev,
    required this.next,
    required this.isCompleted,
    required this.onPrev,
    required this.onNext,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Prev
          IconButton(
            onPressed: prev != null ? onPrev : null,
            icon: Icon(Icons.skip_previous_rounded,
                color: prev != null ? Colors.white70 : Colors.white24, size: 28),
          ),
          // Mark complete
          Expanded(
            child: isCompleted
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle, size: 16, color: WinColors.teal400),
                    const SizedBox(width: 6),
                    Text('Leçon terminée', style: WinType.labelM(WinColors.teal400)),
                  ])
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: WinColors.teal600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Marquer terminé', style: WinType.labelM(Colors.white)),
                    onPressed: onComplete,
                  ),
          ),
          // Next
          IconButton(
            onPressed: next != null ? onNext : null,
            icon: Icon(Icons.skip_next_rounded,
                color: next != null ? Colors.white70 : Colors.white24, size: 28),
          ),
        ]),
      ),
    );
  }
}
