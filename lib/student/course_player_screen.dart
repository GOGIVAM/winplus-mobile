import '../l10n/l10n.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/course_offline_service.dart';
import '../services/course_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import 'course_exam_panel.dart';
import 'document_viewer_screen.dart';
import '../widgets/remote_pdf_screen.dart';
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
  // Examen final ouvert à la place d'une leçon (parité web, 2026-10-26).
  bool _finalMode = false;

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
      // Toutes les leçons terminées et examen final à passer : on l'ouvre.
      final pending = data.allLessons.where((l) => !l.isCompleted);
      final fe = data.finalExam;
      if (widget.initialLessonId == null && pending.isEmpty && fe != null && fe.available && !fe.passed) {
        setState(() => _finalMode = true);
        return;
      }
      // Navigate to first incomplete or specified lesson
      final lessonId = widget.initialLessonId ??
          (pending.isNotEmpty ? pending.first.id : data.allLessons.first.id);
      _loadLesson(lessonId);
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Après une tentative d'examen : progression, leçons cochées et examen final relus.
  Future<void> _refreshCurriculum() async {
    try {
      final data = await CourseService.instance.getCurriculum(widget.courseId);
      if (!mounted) return;
      final wasCompleted = _courseCompleted;
      setState(() {
        _curriculum = data;
        _progressPercent = data.progressPercent;
        _courseCompleted = data.completedAt != null;
      });
      if (_finalMode && (data.finalExam?.passed ?? false)) {
        try { await CourseService.instance.generateMyCertificate(widget.courseId); } catch (_) {}
        if (mounted) _showCompletionDialog();
      } else if (!wasCompleted && _courseCompleted) {
        _showCompletionDialog();
      }
    } catch (_) {}
  }

  /// Quiz de module : la leçon est validée par le serveur si le quiz est réussi.
  Future<void> _afterModuleQuiz() async {
    final l = _lesson;
    if (l == null) return;
    try {
      await CourseService.instance.saveProgress(widget.courseId, l.id,
          watchTimeSec: 0, lastPositionSec: 0, isCompleted: true);
    } catch (_) {
      // Quiz non réussi : la leçon reste à faire (refus 409 attendu).
    }
    await _refreshCurriculum();
  }

  void _openFinalExam() => setState(() {
        _finalMode = true;
        _sidebarOpen = false;
      });

  Future<void> _loadLesson(int lessonId) async {
    setState(() {
      _finalMode = false;
      _loadingLesson = true;
      _currentLessonId = lessonId;
    });
    try {
      final lesson =
          await CourseService.instance.getLesson(widget.courseId, lessonId);
      if (mounted)
        setState(() {
          _lesson = lesson;
          _loadingLesson = false;
        });
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
          id: l.id,
          title: l.title,
          lessonType: l.lessonType,
          description: l.description,
          videoUrl: l.videoUrl,
          videoDurationSec: l.videoDurationSec,
          articleContent: l.articleContent,
          fileUrl: l.fileUrl,
          fileName: l.fileName,
          isPreview: l.isPreview,
          isCompleted: true,
          lastPositionSec: 0,
          sourceSubjectId: l.sourceSubjectId,
          quizId: l.quizId,
        );
        _curriculum = _curriculum == null
            ? null
            : CourseCurriculum(
                courseId: _curriculum!.courseId,
                title: _curriculum!.title,
                progressPercent: result.progressPercent,
                completedAt: result.courseCompleted
                    ? DateTime.now().toIso8601String()
                    : _curriculum!.completedAt,
                certificateUrl: _curriculum!.certificateUrl,
                finalExam: _curriculum!.finalExam,
                sections: _curriculum!.sections
                    .map((sec) => CurriculumSection(
                          id: sec.id,
                          title: sec.title,
                          position: sec.position,
                          lessons: sec.lessons
                              .map((ll) => ll.id == l.id
                                  ? CurriculumLesson(
                                      id: ll.id,
                                      title: ll.title,
                                      lessonType: ll.lessonType,
                                      videoDurationSec: ll.videoDurationSec,
                                      position: ll.position,
                                      isPreview: ll.isPreview,
                                      isCompleted: true,
                                      lastPositionSec: 0)
                                  : ll)
                              .toList(),
                        ))
                    .toList(),
              );
      });
      if (result.courseCompleted) _showCompletionDialog();
    } on CourseActionRefused catch (e) {
      // Lot 9.7b (F12) : complétion refusée par le serveur (vidéo pas assez
      // regardée, quiz non réussi, leçon ouverte depuis trop peu de temps).
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {}
  }

  void _showCompletionDialog() {
    final s = WinTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: s.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.xl)),
        title: Column(children: [
          const Icon(Icons.workspace_premium, size: 56, color: WinColors.gold),
          const SizedBox(height: 12),
          Text(context.l10n.studentPlayerCourseDone,
              style: WinType.headlineS(s.onStrong),
              textAlign: TextAlign.center),
        ]),
        content: Text(
            context.l10n.studentPlayerCertGenerating,
            style: WinType.bodyM(s.onMuted),
            textAlign: TextAlign.center),
        actions: [
          Center(
              child: WinButton(context.l10n.commonClose, onTap: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  List<CurriculumLesson> get _allLessons => _curriculum?.allLessons ?? [];

  CurriculumLesson? get _prevLesson {
    final idx = _allLessons.indexWhere((l) => l.id == _currentLessonId);
    return idx > 0 ? _allLessons[idx - 1] : null;
  }

  CurriculumLesson? get _nextLesson {
    final idx = _allLessons.indexWhere((l) => l.id == _currentLessonId);
    return idx >= 0 && idx < _allLessons.length - 1
        ? _allLessons[idx + 1]
        : null;
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
              style: WinType.labelM(Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (_lesson != null)
            Text(_lesson!.title,
                style: WinType.titleM(Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WinRadii.full),
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
            tooltip: context.l10n.studentPlayerCurriculum,
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
        ],
      ),
      body: _loadingCurr
          ? const Center(
              child: CircularProgressIndicator(color: WinColors.teal400))
          : Column(children: [
              Expanded(
                  child: _sidebarOpen
                      ? _CurriculumPanel(
                          curriculum: _curriculum!,
                          currentLessonId: _finalMode ? null : _currentLessonId,
                          finalSelected: _finalMode,
                          onSelect: (id) {
                            setState(() => _sidebarOpen = false);
                            _loadLesson(id);
                          },
                          onFinalExam: _openFinalExam,
                        )
                      : _finalMode && _curriculum?.finalExam != null
                          ? SingleChildScrollView(
                              child: CourseExamPanel(
                                key: ValueKey('final_${_curriculum!.finalExam!.quizId}'),
                                courseId: widget.courseId,
                                quizId: _curriculum!.finalExam!.quizId,
                                isFinal: true,
                                passScore: _curriculum!.finalExam!.passScore,
                                onAttempted: _refreshCurriculum,
                                onOpenLesson: _loadLesson,
                              ),
                            )
                          : _LessonView(
                              courseId: widget.courseId,
                              lesson: _lesson,
                              loading: _loadingLesson,
                              courseCompleted: _courseCompleted,
                              onMarkComplete: _markComplete,
                              onQuizAttempted: _afterModuleQuiz,
                              onOpenLesson: _loadLesson,
                            )),

              // Bottom nav bar
              _BottomNav(
                prev: _prevLesson,
                next: _nextLesson,
                isCompleted: _lesson?.isCompleted ?? false,
                onPrev: () {
                  if (_prevLesson != null) _loadLesson(_prevLesson!.id);
                },
                onNext: () {
                  if (_nextLesson != null) _loadLesson(_nextLesson!.id);
                },
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
  final bool finalSelected;
  final void Function(int) onSelect;
  final VoidCallback onFinalExam;

  const _CurriculumPanel({
    required this.curriculum,
    required this.currentLessonId,
    required this.finalSelected,
    required this.onSelect,
    required this.onFinalExam,
  });

  @override
  Widget build(BuildContext context) {
    final fe = curriculum.finalExam;
    return Container(
      color: const Color(0xFF1E293B),
      child: ListView.builder(
        itemCount: curriculum.sections.length + (fe != null ? 1 : 0),
        itemBuilder: (_, si) {
          if (si == curriculum.sections.length && fe != null) {
            // Examen final : après toutes les leçons.
            return InkWell(
              onTap: fe.available ? onFinalExam : null,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                color: finalSelected
                    ? WinColors.teal600.withValues(alpha: 0.15)
                    : Colors.transparent,
                child: Row(children: [
                  Icon(
                    fe.passed
                        ? Icons.check_circle
                        : (fe.available ? Icons.workspace_premium : Icons.lock_outline),
                    size: 18,
                    color: fe.passed ? WinColors.teal400 : (fe.available ? WinColors.gold : Colors.white38),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.l10n.studentExamFinalTitle,
                        style: WinType.bodyM(fe.available ? Colors.white : Colors.white38)),
                    if (!fe.available)
                      Text(context.l10n.studentExamFinalLocked, style: WinType.labelS(Colors.white38)),
                  ])),
                ]),
              ),
            );
          }
          final sec = curriculum.sections[si];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: active
                          ? WinColors.teal600.withValues(alpha: 0.15)
                          : Colors.transparent,
                      child: Row(children: [
                        Icon(
                          l.isCompleted
                              ? Icons.check_circle
                              : (active
                                  ? Icons.play_circle
                                  : Icons.radio_button_unchecked),
                          size: 18,
                          color: l.isCompleted
                              ? WinColors.teal400
                              : (active ? Colors.white : Colors.white38),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(l.title,
                                style: WinType.bodyM(
                                    active ? Colors.white : Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis)),
                        if (l.lessonType == 'video' && l.videoDurationSec > 0)
                          Text(l.durationStr,
                              style: WinType.labelS(Colors.white38)),
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
  final int courseId;
  final LessonContent? lesson;
  final bool loading;
  final bool courseCompleted;
  final VoidCallback onMarkComplete;
  final Future<void> Function() onQuizAttempted;
  final void Function(int lessonId) onOpenLesson;

  const _LessonView({
    required this.courseId,
    required this.lesson,
    required this.loading,
    required this.courseCompleted,
    required this.onMarkComplete,
    required this.onQuizAttempted,
    required this.onOpenLesson,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: WinColors.teal400));
    }
    if (lesson == null) {
      return Center(
          child: Text(context.l10n.studentPlayerSelectLesson,
              style: WinType.bodyM(Colors.white38)));
    }

    final l = lesson!;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Module 27 (lot 8) : lecture vidéo réelle depuis l'URL présignée à
        // durée limitée renvoyée par le serveur (plus de placeholder), avec
        // option de téléchargement hors-ligne chiffré lié au compte.
        if (l.lessonType == 'video' && l.videoUrl != null)
          _LessonVideoPlayer(
            key: ValueKey('video_${courseId}_${l.id}'),
            courseId: courseId,
            lessonId: l.id,
            lessonTitle: l.title,
            videoUrl: l.videoUrl!,
            durationSec: l.videoDurationSec,
          ),

        // Quiz de fin de module : joué dans l'application, avec la pause de
        // révision et les propositions de WinAI après un échec.
        if (l.lessonType == 'quiz' && l.quizId != null)
          CourseExamPanel(
            key: ValueKey('quiz_${courseId}_${l.id}'),
            courseId: courseId,
            quizId: l.quizId!,
            isFinal: false,
            onAttempted: onQuizAttempted,
            onOpenLesson: onOpenLesson,
          ),

        // Article content
        if (l.lessonType == 'article' && l.articleContent != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(WinRadii.lg),
            ),
            child: Text(l.articleContent!,
                style: WinType.bodyM(Colors.white).copyWith(height: 1.7)),
          ),

        // Lot 9.7b (F13, 18.21) : épreuve ou livre du catalogue ajouté à la
        // formation : jamais téléchargé, ouvert dans la visionneuse sécurisée
        // (filigrane nominatif), accès par l'inscription à la formation.
        if (l.sourceSubjectId != null)
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                WinPageRoute(
                  builder: (_) => DocumentViewerScreen(
                    subjectId: l.sourceSubjectId!,
                    title: l.title,
                    courseId: courseId,
                  ),
                )),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(WinRadii.lg),
                border: Border.all(
                    color: WinColors.teal600.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.menu_book_outlined,
                    color: WinColors.teal400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.title, style: WinType.titleM(Colors.white)),
                      Text(context.l10n.studentPlayerOpenViewer,
                          style: WinType.labelS(Colors.white54)),
                    ])),
                const Icon(Icons.visibility_outlined, color: WinColors.teal400),
              ]),
            ),
          ),

        // Pièce jointe du professeur (lot 10.6) : un PDF s'ouvre dans
        // l'application depuis le lien du serveur (le web propose le même
        // fichier en téléchargement) ; un autre format, que l'application ne
        // sait pas afficher, est signalé comme consultable sur le site.
        // Jamais une épreuve du catalogue (sourceSubjectId, sans fileUrl).
        if (l.lessonType == 'file' && l.fileUrl != null && !l.viewerOnly)
          Builder(builder: (context) {
            final isPdf = _isPdfAttachment(l);
            return GestureDetector(
              onTap: isPdf
                  ? () => Navigator.push(
                      context,
                      WinPageRoute(
                        builder: (_) => RemotePdfScreen(
                            title: l.fileName ?? l.title, url: l.fileUrl!),
                      ))
                  : null,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(WinRadii.lg),
                  border: Border.all(
                      color: WinColors.teal600.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.attach_file,
                      color: WinColors.teal400, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(l.fileName ?? context.l10n.studentPlayerAttachedFile,
                            style: WinType.titleM(Colors.white)),
                        Text(
                            isPdf
                                ? context.l10n.studentPlayerTapToOpen
                                : context.l10n.studentPlayerOpenOnWeb,
                            style: WinType.labelS(Colors.white54)),
                      ])),
                  if (isPdf)
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: WinColors.teal400),
                ]),
              ),
            );
          }),

        // Lesson info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(l.title, style: WinType.headlineS(Colors.white))),
              if (l.isCompleted)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 16, color: WinColors.teal400),
                  const SizedBox(width: 4),
                  Text(context.l10n.studentPlayerDone, style: WinType.labelM(WinColors.teal400)),
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
                  borderRadius: BorderRadius.circular(WinRadii.lg),
                ),
                child: Row(children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(context.l10n.studentPlayerCourseDone,
                            style: WinType.titleM(Colors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(context.l10n.studentPlayerCertAvailable,
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

/// Module 27 (lot 8) : lecteur vidéo réel (video_player), en ligne via l'URL
/// présignée à durée limitée du serveur, ou hors-ligne depuis la copie
/// chiffrée locale si la leçon a été téléchargée (CourseOfflineService).
/// Bouton de téléchargement/suppression intégré.
class _LessonVideoPlayer extends StatefulWidget {
  final int courseId;
  final int lessonId;
  final String lessonTitle;
  final String videoUrl;
  final int durationSec;
  const _LessonVideoPlayer({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    required this.videoUrl,
    required this.durationSec,
  });

  @override
  State<_LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<_LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _initError = false;
  bool _isOffline = false;
  bool _downloaded = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkOfflineThenInit();
  }

  @override
  void didUpdateWidget(_LessonVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.lessonId != widget.lessonId || old.courseId != widget.courseId) {
      _controller?.dispose();
      _controller = null;
      _initializing = true;
      _initError = false;
      _checkOfflineThenInit();
    }
  }

  Future<void> _checkOfflineThenInit() async {
    final downloaded = await CourseOfflineService.instance
        .isDownloaded(widget.courseId, widget.lessonId);
    if (mounted) setState(() => _downloaded = downloaded);
    await _initController(preferOffline: downloaded);
  }

  Future<void> _initController({required bool preferOffline}) async {
    try {
      VideoPlayerController controller;
      if (preferOffline) {
        final path = await CourseOfflineService.instance
            .decryptForPlayback(widget.courseId, widget.lessonId);
        controller = VideoPlayerController.file(File(path));
        _isOffline = true;
      } else {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        _isOffline = false;
      }
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = true;
        });
      }
    }
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      await CourseOfflineService.instance.downloadLesson(
        courseId: widget.courseId,
        lessonId: widget.lessonId,
        title: widget.lessonTitle,
        videoUrl: widget.videoUrl,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloaded = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.studentPlayerDownloaded)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.current.studentPlayerDownloadFailed)));
    }
  }

  Future<void> _deleteOffline() async {
    await CourseOfflineService.instance
        .deleteLesson(widget.courseId, widget.lessonId);
    if (!mounted) return;
    setState(() => _downloaded = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: _buildVideoArea(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          if (_isOffline)
            const Icon(Icons.offline_pin, size: 16, color: WinColors.teal400),
          if (_isOffline) const SizedBox(width: 4),
          if (_isOffline)
            Text(context.l10n.studentPlayerOfflinePlayback,
                style: WinType.labelS(WinColors.teal400)),
          const Spacer(),
          if (_downloading)
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                color: WinColors.teal400,
                backgroundColor: Colors.white12,
              ),
            )
          else if (_downloaded)
            TextButton.icon(
              onPressed: _deleteOffline,
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.white70),
              label: Text(context.l10n.studentPlayerRemoveOffline,
                  style: WinType.labelS(Colors.white70)),
            )
          else
            TextButton.icon(
              onPressed: _download,
              icon: const Icon(Icons.download_outlined,
                  size: 16, color: WinColors.teal400),
              label: Text(context.l10n.studentPlayerDownloadOffline,
                  style: WinType.labelS(WinColors.teal400)),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildVideoArea() {
    if (_initializing) {
      return const Center(
          child: CircularProgressIndicator(color: WinColors.teal400));
    }
    if (_initError || _controller == null) {
      return Center(
          child: Text(context.l10n.studentPlayerVideoUnavailable,
              style: WinType.bodyM(Colors.white38)));
    }
    final c = _controller!;
    return GestureDetector(
      onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
      child: Stack(alignment: Alignment.center, children: [
        VideoPlayer(c),
        if (!c.value.isPlaying)
          Container(
            decoration: const BoxDecoration(
                color: Colors.black26, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow, size: 56, color: Colors.white),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                  playedColor: WinColors.teal400,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10)),
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
                color: prev != null ? Colors.white70 : Colors.white24,
                size: 28),
          ),
          // Mark complete
          Expanded(
            child: isCompleted
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: WinColors.teal400),
                    const SizedBox(width: 6),
                    Text(context.l10n.studentPlayerLessonDone,
                        style: WinType.labelM(WinColors.teal400)),
                  ])
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: WinColors.teal600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(WinRadii.full)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(context.l10n.studentPlayerMarkDone,
                        style: WinType.labelM(Colors.white)),
                    onPressed: onComplete,
                  ),
          ),
          // Next
          IconButton(
            onPressed: next != null ? onNext : null,
            icon: Icon(Icons.skip_next_rounded,
                color: next != null ? Colors.white70 : Colors.white24,
                size: 28),
          ),
        ]),
      ),
    );
  }
}

/// Pièce jointe au format PDF (nom du fichier, sinon chemin du lien présigné).
bool _isPdfAttachment(LessonContent l) {
  final name = (l.fileName ?? '').toLowerCase();
  if (name.endsWith('.pdf')) return true;
  final path = Uri.tryParse(l.fileUrl ?? '')?.path.toLowerCase() ?? '';
  return path.endsWith('.pdf');
}