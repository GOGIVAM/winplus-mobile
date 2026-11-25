import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/course_offline_service.dart';
import '../../services/http_cache.dart';
import '../../services/session_manager.dart';
import '../../shell/more_screen.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';

/// « Mes téléchargements » (lot 3 du plan mobile) : ce que l'application
/// garde sur le téléphone pour le compte connecté, la place que ça prend, et
/// de quoi la libérer.
/// - Leçons de formation enregistrées (chiffrées, CourseOfflineService) :
///   suppression une par une ou toutes.
/// - Pages gardées pour le mode hors ligne (HttpCache) : vidage.
/// Épreuves et corrigés ne se téléchargent pas (module 44) : rien à lister.
class MyDownloadsScreen extends StatefulWidget {
  const MyDownloadsScreen({super.key});

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen> {
  List<OfflineLesson>? _lessons;
  ({int entries, int bytes}) _cache = (entries: 0, bytes: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await CourseOfflineService.instance.lessonsForCurrentUser();
    final cache = await HttpCache.instance.statsForUser(await SessionManager.getUserId());
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _cache = cache;
    });
  }


  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  void _freed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.dlFreed)));
  }

  Future<void> _deleteLesson(OfflineLesson lesson) async {
    final l = context.l10n;
    if (!await _confirm(l.dlDeleteLessonTitle, l.dlDeleteLessonBody, l.commonDelete)) return;
    await CourseOfflineService.instance.deleteLesson(lesson.courseId, lesson.lessonId);
    await _load();
    _freed();
  }

  Future<void> _deleteAll(int bytes) async {
    final l = context.l10n;
    if (!await _confirm(l.dlDeleteAllTitle, l.dlDeleteAllBody(formatSize(bytes)), l.dlDeleteAll)) return;
    await CourseOfflineService.instance.deleteAllForCurrentUser();
    await _load();
    _freed();
  }

  Future<void> _clearCache() async {
    final l = context.l10n;
    if (!await _confirm(l.dlCacheClearTitle, l.dlCacheClearBody, l.dlCacheClear)) return;
    await HttpCache.instance.clearForUser(await SessionManager.getUserId());
    await _load();
    _freed();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final lessons = _lessons;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.dlTitle)),
      body: SafeArea(
        child: lessons == null
            ? const WinLoading()
            : _content(s, l, lessons),
      ),
    );
  }

  Widget _content(WinScheme s, AppLocalizations l, List<OfflineLesson> lessons) {
    final lessonBytes = lessons.fold<int>(0, (t, x) => t + x.sizeBytes);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Text(l.dlTotal(formatSize(lessonBytes + _cache.bytes)), style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text(l.dlLessonsTitle, style: WinType.titleM(s.onStrong))),
          if (lessons.isNotEmpty)
            TextButton(onPressed: () => _deleteAll(lessonBytes), child: Text(l.dlDeleteAll)),
        ]),
        const SizedBox(height: 8),
        if (lessons.isEmpty)
          Text(l.dlLessonsEmpty, style: WinType.bodyM(s.onMuted))
        else
          MoreGroup(children: [
            for (final x in lessons)
              MoreLine(
                icon: PhosphorIconsRegular.filmStrip,
                label: x.title.isEmpty ? '#${x.lessonId}' : x.title,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatSize(x.sizeBytes), style: WinType.labelM(s.onMuted)),
                  IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(PhosphorIconsRegular.trash),
                    onPressed: () => _deleteLesson(x),
                  ),
                ]),
              ),
          ]),
        const SizedBox(height: 24),
        Text(l.dlCacheTitle, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        MoreGroup(children: [
          MoreLine(
            icon: PhosphorIconsRegular.database,
            label: _cache.entries == 0
                ? l.dlCacheEmpty
                : l.dlCacheBody(_cache.entries, formatSize(_cache.bytes)),
            trailing: _cache.entries == 0
                ? const SizedBox.shrink()
                : TextButton(onPressed: _clearCache, child: Text(l.dlCacheClear)),
          ),
        ]),
      ]),
    );
  }
}

/// Taille lisible (Ko, Mo, Go ; KB, MB, GB en anglais).
String formatSize(int bytes) {
  final en = L10n.code == 'en';
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ${en ? 'GB' : 'Go'}';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${en ? 'MB' : 'Mo'}';
  }
  return '${(bytes / 1024).ceil()} ${en ? 'KB' : 'Ko'}';
}