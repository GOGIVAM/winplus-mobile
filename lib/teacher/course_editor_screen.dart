import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/models.dart' show fmtXaf;
import '../l10n/l10n.dart';
import '../services/course_editor_service.dart';
import '../services/library_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import 'course_stats_screen.dart';

String _levelLabel(AppLocalizations l, String v) => switch (v) {
      'intermediaire' => l.tcourseLevelMid,
      'avance' => l.tcourseLevelHigh,
      _ => l.tcourseLevelBase,
    };

String _typeLabel(AppLocalizations l, String v) => switch (v) {
      'article' => l.tcourseTypeArticle,
      'file' || 'Fichier' => l.tcourseTypeFile,
      'quiz' => l.tcourseTypeQuiz,
      _ => l.tcourseTypeVideo,
    };

IconData _typeIcon(String v) => switch (v) {
      'article' => PhosphorIconsRegular.article,
      'file' || 'Fichier' => PhosphorIconsRegular.filePdf,
      'quiz' => PhosphorIconsRegular.exam,
      _ => PhosphorIconsRegular.playCircle,
    };

List<String> _lines(String text) => text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> _confirm(BuildContext context, String title, String text, String action) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ],
      ),
    ) ==
    true;

/// Informations d'une formation : création (course null) ou modification.
/// La création renvoie l'identifiant de la formation créée.
class CourseInfoScreen extends StatefulWidget {
  final EditorCourse? course;
  const CourseInfoScreen({super.key, this.course});

  @override
  State<CourseInfoScreen> createState() => _CourseInfoScreenState();
}

class _CourseInfoScreenState extends State<CourseInfoScreen> {
  final _svc = CourseEditorService.instance;
  late final _title = TextEditingController(text: widget.course?.title ?? '');
  late final _short = TextEditingController(text: widget.course?.shortDescription ?? '');
  late final _description = TextEditingController(text: widget.course?.description ?? '');
  late final _price = TextEditingController(
      text: widget.course == null || widget.course!.price == 0 ? '' : widget.course!.price.round().toString());
  late final _objectives = TextEditingController(text: (widget.course?.objectives ?? const []).join('\n'));
  late final _requirements = TextEditingController(text: (widget.course?.requirements ?? const []).join('\n'));
  late final _thumbnail = TextEditingController(text: widget.course?.thumbnailUrl ?? '');
  late final _preview = TextEditingController(text: widget.course?.previewVideoUrl ?? '');
  late String _level = widget.course?.level ?? 'debutant';
  late String? _category = widget.course?.category;
  late String _language = widget.course?.language ?? 'fr';
  late bool _free = widget.course?.isFree ?? false;
  late bool _certificate = widget.course?.certificateEnabled ?? true;
  bool _saving = false;
  String? _error;

  bool get _creating => widget.course == null;

  @override
  void dispose() {
    for (final c in [_title, _short, _description, _price, _objectives, _requirements, _thumbnail, _preview]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final price = num.tryParse(_price.text.trim().replaceAll(' ', '')) ?? 0;
    String? error;
    if (_title.text.trim().length < 3) {
      error = l.tcourseNeedTitle;
    } else if (!_free && price <= 0) {
      error = l.tcourseNeedPrice;
    }
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      if (_creating) {
        final id = await _svc.create(
          title: _title.text,
          shortDescription: _short.text,
          description: _description.text,
          level: _level,
          category: _category,
          language: _language,
          price: _free ? 0 : price,
          isFree: _free,
        );
        if (mounted) Navigator.of(context).pop(id);
      } else {
        await _svc.update(widget.course!.id,
            title: _title.text,
            shortDescription: _short.text,
            description: _description.text,
            thumbnailUrl: _thumbnail.text,
            previewVideoUrl: _preview.text,
            language: _language,
            level: _level,
            category: _category,
            price: _free ? 0 : price,
            isFree: _free,
            objectives: _lines(_objectives.text),
            requirements: _lines(_requirements.text),
            certificateEnabled: _certificate);
        if (mounted) Navigator.of(context).pop(widget.course!.id);
      }
    } on CourseEditorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(t, style: WinType.labelM(s.onStrong)),
        );
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(_creating ? l.tcourseCreate : l.tcourseEditInfo)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          if (_creating) Text(l.tcourseCreateIntro, style: WinType.bodyM(s.onMuted)),
          label(l.tcourseTitleLabel),
          TextField(controller: _title, maxLength: 200, decoration: InputDecoration(hintText: l.tcourseTitleHint)),
          label(l.tcourseShortLabel),
          TextField(controller: _short, maxLength: 300, maxLines: 2, decoration: InputDecoration(hintText: l.tcourseShortHint)),
          label(l.tcourseDescriptionLabel),
          TextField(controller: _description, minLines: 3, maxLines: 8),
          label(l.tcourseLevel),
          Wrap(spacing: 8, children: [
            for (final v in CourseEditorService.levels)
              WinChip(_levelLabel(l, v), active: _level == v, onTap: () => setState(() => _level = v)),
          ]),
          label(l.tcourseCategory),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final c in CourseEditorService.categories)
              WinChip(c, active: _category == c, onTap: () => setState(() => _category = c)),
          ]),
          label(l.tcourseLanguage),
          Wrap(spacing: 8, children: [
            WinChip(l.tcourseLangFr, active: _language == 'fr', onTap: () => setState(() => _language = 'fr')),
            WinChip(l.tcourseLangEn, active: _language == 'en', onTap: () => setState(() => _language = 'en')),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tcourseFree),
            value: _free,
            onChanged: (v) => setState(() => _free = v),
          ),
          if (!_free)
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.tcoursePrice, suffixText: 'XAF', helperText: l.tcoursePriceHelp),
            ),
          if (!_creating) ...[
            label(l.tcourseObjectives),
            TextField(controller: _objectives, minLines: 3, maxLines: 8, decoration: InputDecoration(hintText: l.tcourseOnePerLine)),
            label(l.tcourseRequirements),
            TextField(controller: _requirements, minLines: 2, maxLines: 6, decoration: InputDecoration(hintText: l.tcourseOnePerLine)),
            label(l.tcourseThumbnail),
            TextField(controller: _thumbnail, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://')),
            label(l.tcoursePreviewVideo),
            TextField(controller: _preview, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.tcourseCertificate),
              value: _certificate,
              onChanged: (v) => setState(() => _certificate = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 12),
          WinButton(_creating ? l.tcourseCreateAction : l.tcourseSave,
              block: true, loading: _saving, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

/// Éditeur d'une formation : informations, programme (sections et leçons),
/// ordre, syllabus WinAI, soumission à la validation.
class CourseEditorScreen extends StatefulWidget {
  final int courseId;
  const CourseEditorScreen({super.key, required this.courseId});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _svc = CourseEditorService.instance;
  EditorCourse? _course;
  bool _error = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final c = await _svc.course(widget.courseId);
      if (mounted) setState(() => _course = c);
    } catch (_) {
      if (mounted && _course == null) setState(() => _error = true);
    }
  }

  /// Action serveur puis rechargement ; le refus du serveur est affiché.
  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (done != null) _toast(context, done);
      await _load();
    } on CourseEditorException catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editInfo() async {
    final c = _course;
    if (c == null) return;
    final saved = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => CourseInfoScreen(course: c)));
    if (saved != null) await _load();
  }

  Future<void> _sectionForm({EditorSection? section}) async {
    final res = await showWinBottomSheet<_SectionResult>(
      context: context,
      title: section == null ? context.l10n.tcourseAddSection : context.l10n.tcourseEditSection,
      child: _SectionForm(section: section),
    );
    if (res == null) return;
    await _run(() => section == null
        ? _svc.addSection(widget.courseId, res.title,
            description: res.description, rule: res.rule, delayDays: res.delayDays, minScore: res.minScore)
        : _svc.updateSection(widget.courseId, section.id, res.title,
            description: res.description, rule: res.rule, delayDays: res.delayDays, minScore: res.minScore));
  }

  Future<void> _moveSection(int index, int delta) async {
    final ids = _course!.sections.map((s) => s.id).toList();
    final j = index + delta;
    if (j < 0 || j >= ids.length) return;
    final t = ids[index];
    ids[index] = ids[j];
    ids[j] = t;
    await _run(() => _svc.reorderSections(widget.courseId, ids));
  }

  Future<void> _moveLesson(EditorSection section, int index, int delta) async {
    final ids = section.lessons.map((x) => x.id).toList();
    final j = index + delta;
    if (j < 0 || j >= ids.length) return;
    final t = ids[index];
    ids[index] = ids[j];
    ids[j] = t;
    await _run(() => _svc.reorderLessons(widget.courseId, section.id, ids));
  }

  Future<void> _sectionMenu(EditorSection section, int index) async {
    final l = context.l10n;
    final last = index == (_course?.sections.length ?? 1) - 1;
    final action = await showWinBottomSheet<String>(
      context: context,
      title: section.title,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(PhosphorIconsRegular.pencilSimple),
            title: Text(l.tcourseEditSection),
            onTap: () => Navigator.pop(context, 'edit')),
        if (index > 0)
          ListTile(
              leading: const Icon(PhosphorIconsRegular.arrowUp),
              title: Text(l.tcourseMoveUp),
              onTap: () => Navigator.pop(context, 'up')),
        if (!last)
          ListTile(
              leading: const Icon(PhosphorIconsRegular.arrowDown),
              title: Text(l.tcourseMoveDown),
              onTap: () => Navigator.pop(context, 'down')),
        ListTile(
            leading: const Icon(PhosphorIconsRegular.trash, color: WinColors.error),
            title: Text(l.tcourseDeleteSection),
            onTap: () => Navigator.pop(context, 'delete')),
      ]),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _sectionForm(section: section);
      case 'up':
        await _moveSection(index, -1);
      case 'down':
        await _moveSection(index, 1);
      case 'delete':
        if (await _confirm(context, l.tcourseDeleteSection, l.tcourseDeleteSectionConfirm(section.title), l.commonDelete)) {
          await _run(() => _svc.deleteSection(widget.courseId, section.id));
        }
    }
  }

  Future<void> _addLesson(EditorSection section) async {
    final l = context.l10n;
    final choice = await showWinBottomSheet<String>(
      context: context,
      title: l.tcourseAddLesson,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final t in CourseEditorService.lessonTypes)
          ListTile(leading: Icon(_typeIcon(t)), title: Text(_typeLabel(l, t)), onTap: () => Navigator.pop(context, t)),
        ListTile(
          leading: const Icon(PhosphorIconsRegular.books),
          title: Text(l.tcourseFromLibrary),
          subtitle: Text(l.tcourseFromLibraryHint),
          onTap: () => Navigator.pop(context, 'library'),
        ),
      ]),
    );
    if (!mounted || choice == null) return;
    if (choice == 'library') {
      await _addFromLibrary(section);
      return;
    }
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => LessonFormScreen(courseId: widget.courseId, sectionId: section.id, type: choice)));
    if (saved == true) await _load();
  }

  Future<void> _addFromLibrary(EditorSection section) async {
    final l = context.l10n;
    List<LibraryItem> items;
    try {
      items = await LibraryService.instance.items();
    } on LibraryException catch (e) {
      if (mounted) _toast(context, e.message);
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      _toast(context, l.tcourseLibraryEmpty);
      return;
    }
    final picked = await showWinBottomSheet<LibraryItem>(
      context: context,
      title: l.tcourseFromLibrary,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: ListView(shrinkWrap: true, children: [
          for (final it in items)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.fileText),
              title: Text(it.title),
              subtitle: (it.category ?? '').isEmpty ? null : Text(it.category!),
              onTap: () => Navigator.pop(context, it),
            ),
        ]),
      ),
    );
    if (picked == null) return;
    await _run(() => _svc.addLessonFromSubject(widget.courseId, section.id, picked.subjectId), done: l.tcourseLessonAdded);
  }

  Future<void> _lessonMenu(EditorSection section, EditorLesson lesson, int index) async {
    final l = context.l10n;
    final action = await showWinBottomSheet<String>(
      context: context,
      title: lesson.title,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (lesson.type != 'Fichier' && lesson.type != 'quiz')
          ListTile(
              leading: const Icon(PhosphorIconsRegular.pencilSimple),
              title: Text(l.tcourseEditLesson),
              onTap: () => Navigator.pop(context, 'edit')),
        if (index > 0)
          ListTile(
              leading: const Icon(PhosphorIconsRegular.arrowUp),
              title: Text(l.tcourseMoveUp),
              onTap: () => Navigator.pop(context, 'up')),
        if (index < section.lessons.length - 1)
          ListTile(
              leading: const Icon(PhosphorIconsRegular.arrowDown),
              title: Text(l.tcourseMoveDown),
              onTap: () => Navigator.pop(context, 'down')),
        ListTile(
            leading: const Icon(PhosphorIconsRegular.trash, color: WinColors.error),
            title: Text(l.tcourseDeleteLesson),
            onTap: () => Navigator.pop(context, 'delete')),
      ]),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
            builder: (_) =>
                LessonFormScreen(courseId: widget.courseId, sectionId: section.id, type: lesson.type, lesson: lesson)));
        if (saved == true) await _load();
      case 'up':
        await _moveLesson(section, index, -1);
      case 'down':
        await _moveLesson(section, index, 1);
      case 'delete':
        if (await _confirm(context, l.tcourseDeleteLesson, l.tcourseDeleteLessonConfirm(lesson.title), l.commonDelete)) {
          await _run(() => _svc.deleteLesson(widget.courseId, section.id, lesson.id));
        }
    }
  }

  Future<void> _syllabus() async {
    final c = _course;
    if (c == null) return;
    final imported = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => SyllabusScreen(course: c)));
    if (imported == true) await _load();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (!await _confirm(context, l.tcourseSubmit, l.tcourseSubmitConfirm, l.tcourseSubmit)) return;
    await _run(() => _svc.submit(widget.courseId), done: l.tcourseSubmitted);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final c = _course;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (c == null) {
      body = const WinLoading();
    } else {
      final editable = c.editable && !_busy;
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          if (!c.editable) WinAlert(l.tcoursePending, type: BadgeColor.blue),
          if (c.status == 'rejected' && (c.rejectionReason ?? '').isNotEmpty)
            WinAlert(l.tcourseRejected(c.rejectionReason!), type: BadgeColor.error),
          const SizedBox(height: 8),
          WinCard(
            onTap: editable ? _editInfo : null,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        _levelLabel(l, c.level),
                        if ((c.category ?? '').isNotEmpty) c.category!,
                        c.isFree ? l.tcourseFree : '${fmtXaf(c.price.round())} XAF',
                      ].join(' · '),
                      style: WinType.labelM(s.onMuted)),
                  Text(l.tcourseCounts(c.sections.length, c.lessonsCount), style: WinType.labelM(s.onMuted)),
                ]),
              ),
              if (editable) Icon(PhosphorIconsRegular.pencilSimple, color: s.onMuted),
            ]),
          ),
          // Lot 7 : suivi des leçons, points et classement.
          if (c.status == 'published')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CourseStatsScreen(courseId: c.id, title: c.title))),
                icon: const Icon(PhosphorIconsRegular.chartLineUp),
                label: Text(l.cstatOpen),
              ),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text(l.tcourseProgramme, style: WinType.titleM(s.onStrong))),
            if (editable)
              TextButton.icon(
                  onPressed: () => _sectionForm(),
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: Text(l.tcourseAddSection)),
          ]),
          if (c.sections.isEmpty) ...[
            Text(l.tcourseNoSection, style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 10),
            if (editable)
              WinButton(l.tcourseSyllabus,
                  block: true, variant: WinButtonVariant.outline, icon: PhosphorIconsRegular.sparkle, onTap: _syllabus),
          ],
          for (var i = 0; i < c.sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WinCard(
                padding: EdgeInsets.zero,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(c.sections[i].title, style: WinType.titleS(s.onStrong)),
                    subtitle: c.sections[i].unlockRule == 'immediate'
                        ? null
                        : Text(c.sections[i].unlockRule == 'delay_days'
                            ? l.tcourseUnlockAfter(c.sections[i].delayDays ?? 0)
                            : l.tcourseUnlockScore(c.sections[i].minScore ?? 0)),
                    trailing: editable
                        ? IconButton(
                            tooltip: l.tcourseSectionActions,
                            onPressed: () => _sectionMenu(c.sections[i], i),
                            icon: const Icon(PhosphorIconsBold.dotsThreeVertical))
                        : null,
                  ),
                  for (var j = 0; j < c.sections[i].lessons.length; j++)
                    ListTile(
                      dense: true,
                      leading: Icon(_typeIcon(c.sections[i].lessons[j].type), color: s.primary),
                      title: Text(c.sections[i].lessons[j].title),
                      subtitle: Text([
                        _typeLabel(l, c.sections[i].lessons[j].type),
                        if (!c.sections[i].lessons[j].isPublished) l.tcourseDraftLesson,
                        if (c.sections[i].lessons[j].isPreview) l.tcoursePreviewLesson,
                      ].join(' · ')),
                      onTap: editable ? () => _lessonMenu(c.sections[i], c.sections[i].lessons[j], j) : null,
                    ),
                  if (editable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: TextButton.icon(
                          onPressed: () => _addLesson(c.sections[i]),
                          icon: const Icon(PhosphorIconsRegular.plus),
                          label: Text(l.tcourseAddLesson)),
                    ),
                ]),
              ),
            ),
          if ((c.status == 'draft' || c.status == 'archived' || c.status == 'rejected') && c.sections.isNotEmpty) ...[
            const SizedBox(height: 20),
            if (c.publishedLessons == 0) Text(l.tcourseNeedLesson, style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 6),
            WinButton(l.tcourseSubmit,
                block: true,
                icon: PhosphorIconsRegular.paperPlaneRight,
                loading: _busy,
                onTap: _busy || c.publishedLessons == 0 ? null : _submit),
          ],
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.tcourseEditor)),
      body: SafeArea(child: body),
    );
  }
}

class _SectionResult {
  final String title;
  final String? description;
  final String rule;
  final int? delayDays;
  final int? minScore;
  const _SectionResult(this.title, this.description, this.rule, this.delayDays, this.minScore);
}

class _SectionForm extends StatefulWidget {
  final EditorSection? section;
  const _SectionForm({this.section});

  @override
  State<_SectionForm> createState() => _SectionFormState();
}

class _SectionFormState extends State<_SectionForm> {
  late final _title = TextEditingController(text: widget.section?.title ?? '');
  late final _description = TextEditingController(text: widget.section?.description ?? '');
  late final _days = TextEditingController(text: '${widget.section?.delayDays ?? 7}');
  late final _score = TextEditingController(text: '${widget.section?.minScore ?? 50}');
  late String _rule = widget.section?.unlockRule ?? 'immediate';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _days.dispose();
    _score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _title, maxLength: 200, decoration: InputDecoration(labelText: l.tcourseSectionTitle)),
        TextField(controller: _description, maxLines: 2, decoration: InputDecoration(labelText: l.tcourseSectionDescription)),
        const SizedBox(height: 12),
        Text(l.tcourseUnlock, style: WinType.labelM(WinTheme.of(context).onStrong)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          WinChip(l.tcourseUnlockNow, active: _rule == 'immediate', onTap: () => setState(() => _rule = 'immediate')),
          WinChip(l.tcourseUnlockDelay, active: _rule == 'delay_days', onTap: () => setState(() => _rule = 'delay_days')),
          WinChip(l.tcourseUnlockMinScore, active: _rule == 'min_score', onTap: () => setState(() => _rule = 'min_score')),
        ]),
        if (_rule == 'delay_days')
          TextField(controller: _days, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.tcourseDays)),
        if (_rule == 'min_score')
          TextField(controller: _score, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.tcourseMinScore, suffixText: '%')),
        const SizedBox(height: 12),
        WinButton(l.tcourseSave, block: true, onTap: () {
          if (_title.text.trim().isEmpty) return;
          Navigator.pop(
              context,
              _SectionResult(_title.text.trim(), _description.text.trim(), _rule,
                  int.tryParse(_days.text.trim()), int.tryParse(_score.text.trim())?.clamp(0, 100)));
        }),
      ]),
    );
  }
}

/// Leçon vidéo, article ou fichier : ajout ou modification.
class LessonFormScreen extends StatefulWidget {
  final int courseId;
  final int sectionId;
  final String type;
  final EditorLesson? lesson;
  const LessonFormScreen({super.key, required this.courseId, required this.sectionId, required this.type, this.lesson});

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _svc = CourseEditorService.instance;
  late final _title = TextEditingController(text: widget.lesson?.title ?? '');
  late final _description = TextEditingController(text: widget.lesson?.description ?? '');
  late final _url = TextEditingController(
      text: widget.type == 'file' ? (widget.lesson?.fileUrl ?? '') : (widget.lesson?.videoUrl ?? ''));
  late final _fileName = TextEditingController(text: widget.lesson?.fileName ?? '');
  late final _minutes = TextEditingController(
      text: (widget.lesson?.videoDurationSec ?? 0) > 0 ? '${(widget.lesson!.videoDurationSec / 60).round()}' : '');
  late final _article = TextEditingController(text: widget.lesson?.articleContent ?? '');
  late bool _preview = widget.lesson?.isPreview ?? false;
  late bool _published = widget.lesson?.isPublished ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _description, _url, _fileName, _minutes, _article]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final t = widget.type;
    final url = _url.text.trim();
    String? error;
    if (_title.text.trim().isEmpty) {
      error = l.tcourseNeedLessonTitle;
    } else if ((t == 'video' || t == 'file') && !(Uri.tryParse(url)?.hasScheme ?? false)) {
      error = l.tcourseNeedUrl;
    } else if (t == 'article' && _article.text.trim().isEmpty) {
      error = l.tcourseNeedArticle;
    }
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    final minutes = int.tryParse(_minutes.text.trim());
    try {
      if (widget.lesson == null) {
        await _svc.addLesson(widget.courseId, widget.sectionId,
            title: _title.text,
            type: t,
            description: _description.text,
            videoUrl: url,
            videoDurationSec: minutes == null ? null : minutes * 60,
            articleContent: _article.text,
            fileUrl: url,
            fileName: _fileName.text,
            isPreview: _preview,
            isPublished: _published);
      } else {
        await _svc.updateLesson(widget.courseId, widget.sectionId, widget.lesson!.id,
            title: _title.text,
            type: t,
            description: _description.text,
            videoUrl: url,
            videoDurationSec: minutes == null ? null : minutes * 60,
            articleContent: _article.text,
            fileUrl: url,
            fileName: _fileName.text,
            isPreview: _preview,
            isPublished: _published);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CourseEditorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final t = widget.type;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(_typeLabel(l, t))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          TextField(controller: _title, maxLength: 200, decoration: InputDecoration(labelText: l.tcourseLessonTitle)),
          TextField(controller: _description, maxLines: 2, decoration: InputDecoration(labelText: l.tcourseLessonDescription)),
          const SizedBox(height: 8),
          if (t == 'video') ...[
            TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: l.tcourseVideoUrl, helperText: l.tcourseVideoUrlHelp)),
            TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.tcourseVideoMinutes, suffixText: 'min')),
          ],
          if (t == 'file') ...[
            TextField(controller: _url, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l.tcourseFileUrl)),
            TextField(controller: _fileName, decoration: InputDecoration(labelText: l.tcourseFileName)),
          ],
          if (t == 'article')
            TextField(
                controller: _article,
                minLines: 8,
                maxLines: 24,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(labelText: l.tcourseArticle, alignLabelWithHint: true)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tcoursePublishedLesson),
            subtitle: Text(l.tcoursePublishedLessonHelp),
            value: _published,
            onChanged: (v) => setState(() => _published = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tcourseFreePreview),
            subtitle: Text(l.tcourseFreePreviewHelp),
            value: _preview,
            onChanged: (v) => setState(() => _preview = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 12),
          WinButton(l.tcourseSave, block: true, loading: _saving, onTap: _saving ? null : _save),
        ]),
      ),
    );
  }
}

/// Programme proposé par WinAI : matière, niveau, nombre de semaines,
/// objectifs ; aperçu des semaines puis import comme sections.
class SyllabusScreen extends StatefulWidget {
  final EditorCourse course;
  const SyllabusScreen({super.key, required this.course});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final _svc = CourseEditorService.instance;
  late final _subject = TextEditingController(text: widget.course.category ?? widget.course.title);
  final _objectives = TextEditingController();
  final _exams = TextEditingController();
  late String _level = widget.course.level;
  int _weeks = 6;
  List<SyllabusWeek>? _result;
  bool _generating = false;
  bool _importing = false;
  String? _error;
  bool _quota = false;

  @override
  void dispose() {
    _subject.dispose();
    _objectives.dispose();
    _exams.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l = context.l10n;
    if (_subject.text.trim().isEmpty) {
      setState(() => _error = l.tcourseNeedSubject);
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _quota = false;
    });
    try {
      final weeks = await _svc.generateSyllabus(
        subject: _subject.text,
        level: _level,
        weeks: _weeks,
        objectives: _lines(_objectives.text),
        targetExams: _lines(_exams.text),
      );
      if (mounted) setState(() => _result = weeks);
    } on CourseEditorException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _quota = e.isQuota;
        });
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _import() async {
    final weeks = _result;
    if (weeks == null || weeks.isEmpty) return;
    setState(() => _importing = true);
    try {
      await _svc.importSyllabus(widget.course.id, weeks);
      if (!mounted) return;
      _toast(context, context.l10n.tcourseSyllabusImported(weeks.length));
      Navigator.of(context).pop(true);
    } on CourseEditorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final weeks = _result;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.tcourseSyllabus)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.tcourseSyllabusIntro, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          TextField(controller: _subject, decoration: InputDecoration(labelText: l.tcourseSubject)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final v in CourseEditorService.levels)
              WinChip(_levelLabel(l, v), active: _level == v, onTap: () => setState(() => _level = v)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(l.tcourseWeeks(_weeks), style: WinType.labelM(s.onStrong))),
            IconButton(
                tooltip: l.tcourseFewerWeeks,
                onPressed: _weeks > 1 ? () => setState(() => _weeks--) : null,
                icon: const Icon(PhosphorIconsRegular.minus)),
            IconButton(
                tooltip: l.tcourseMoreWeeks,
                onPressed: _weeks < 24 ? () => setState(() => _weeks++) : null,
                icon: const Icon(PhosphorIconsRegular.plus)),
          ]),
          TextField(controller: _objectives, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: l.tcourseObjectives, hintText: l.tcourseOnePerLine)),
          TextField(controller: _exams, minLines: 1, maxLines: 3, decoration: InputDecoration(labelText: l.tcourseTargetExams, hintText: l.tcourseOnePerLine)),
          const SizedBox(height: 12),
          WinButton(weeks == null ? l.tcourseGenerate : l.tcourseRegenerate,
              block: true,
              variant: weeks == null ? WinButtonVariant.accent : WinButtonVariant.outline,
              icon: PhosphorIconsRegular.sparkle,
              loading: _generating,
              onTap: _generating ? null : _generate),
          if (_error != null) ...[
            const SizedBox(height: 10),
            WinAlert(_error!, type: _quota ? BadgeColor.warn : BadgeColor.error),
          ],
          if (weeks != null) ...[
            const SizedBox(height: 16),
            for (final w in weeks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WinCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.tcourseWeekTitle(w.week, w.title), style: WinType.titleS(s.onStrong)),
                    if (w.concepts.isNotEmpty) Text(w.concepts.join(', '), style: WinType.bodyS(s.onMuted)),
                    if (w.activities.isNotEmpty)
                      Text(l.tcourseActivities(w.activities.join(', ')), style: WinType.bodyS(s.onMuted)),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            WinButton(l.tcourseImport(weeks.length),
                block: true, loading: _importing, onTap: _importing || weeks.isEmpty ? null : _import),
          ],
        ]),
      ),
    );
  }
}
