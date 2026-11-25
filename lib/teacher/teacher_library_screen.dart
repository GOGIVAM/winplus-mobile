import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/models.dart' show fmtXaf;
import '../l10n/l10n.dart';
import '../services/library_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Ma bibliothèque » du professeur (lot 7), comme TeacherLibrary du site :
/// contenus achetés ou rangés, recherche, dossiers (créer, renommer,
/// supprimer), filtre « Annotés », ranger un contenu (dossier, tags, note) et
/// l'assigner à une classe.
class TeacherLibraryScreen extends StatefulWidget {
  const TeacherLibraryScreen({super.key});

  @override
  State<TeacherLibraryScreen> createState() => _TeacherLibraryScreenState();
}

/// Filtre courant : tout, annotés, ou un dossier.
const _all = -1;
const _annotated = -2;

class _TeacherLibraryScreenState extends State<TeacherLibraryScreen> {
  final _svc = LibraryService.instance;
  final _search = TextEditingController();
  Timer? _debounce;
  List<LibraryItem>? _items;
  List<LibraryFolder> _folders = const [];
  int _filter = _all;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final results = await Future.wait([
        _svc.items(
          q: _search.text,
          collectionId: _filter >= 0 ? _filter : null,
          annotatedOnly: _filter == _annotated,
        ),
        _svc.folders(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<LibraryItem>;
        _folders = results[1] as List<LibraryFolder>;
        // Dossier supprimé ailleurs : retour à « Tout ».
        if (_filter >= 0 && !_folders.any((f) => f.id == _filter)) _filter = _all;
      });
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _setFilter(int f) {
    setState(() => _filter = f);
    _load();
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _askName(String title, {String initial = ''}) => showDialog<String>(
        context: context,
        builder: (_) => _NameDialog(title: title, initial: initial),
      );

  Future<void> _createFolder() async {
    final l = context.l10n;
    final name = await _askName(l.libNewFolder);
    if (name == null || name.isEmpty) return;
    try {
      await _svc.createFolder(name);
      if (!mounted) return;
      _toast(l.libFolderCreated);
      await _load();
    } on LibraryException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _folderActions(LibraryFolder f) async {
    final l = context.l10n;
    final action = await showWinBottomSheet<String>(
      context: context,
      title: f.name,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(PhosphorIconsRegular.pencilSimple),
          title: Text(l.libRenameFolder),
          onTap: () => Navigator.pop(context, 'rename'),
        ),
        ListTile(
          leading: const Icon(PhosphorIconsRegular.trash),
          title: Text(l.libDeleteFolder),
          onTap: () => Navigator.pop(context, 'delete'),
        ),
      ]),
    );
    if (!mounted || action == null) return;
    try {
      if (action == 'rename') {
        final name = await _askName(l.libRenameFolder, initial: f.name);
        if (name == null || name.isEmpty || name == f.name) return;
        await _svc.renameFolder(f.id, name);
      } else {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l.libDeleteFolder),
            content: Text(l.libDeleteFolderConfirm(f.name)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonCancel)),
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.libDeleteFolder)),
            ],
          ),
        );
        if (ok != true) return;
        await _svc.deleteFolder(f.id);
      }
      if (mounted) await _load();
    } on LibraryException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _itemActions(LibraryItem item) async {
    final l = context.l10n;
    final action = await showWinBottomSheet<String>(
      context: context,
      title: item.title,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(PhosphorIconsRegular.folderSimple),
          title: Text(l.libOrganize),
          subtitle: Text(l.libOrganizeHint),
          onTap: () => Navigator.pop(context, 'organize'),
        ),
        ListTile(
          leading: const Icon(PhosphorIconsRegular.usersThree),
          title: Text(l.libAssignClass),
          onTap: () => Navigator.pop(context, 'class'),
        ),
      ]),
    );
    if (!mounted || action == null) return;
    if (action == 'organize') {
      await _organize(item);
    } else {
      await _assign(item);
    }
  }

  Future<void> _organize(LibraryItem item) async {
    final l = context.l10n;
    final result = await showWinBottomSheet<_Organized>(
      context: context,
      title: l.libOrganize,
      child: _OrganizeForm(item: item, folders: _folders),
    );
    if (result == null || !mounted) return;
    try {
      await _svc.organize(item.subjectId,
          collectionId: result.folderId, clearCollection: result.folderId == null, tags: result.tags, notes: result.notes);
      if (!mounted) return;
      _toast(l.libSaved);
      await _load();
    } on LibraryException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _assign(LibraryItem item) async {
    final l = context.l10n;
    List<LibraryClass> classes;
    try {
      classes = await _svc.classes();
    } on LibraryException catch (e) {
      if (mounted) _toast(e.message);
      return;
    }
    if (!mounted) return;
    if (classes.isEmpty) {
      _toast(l.libNoClass);
      return;
    }
    final klass = await showWinBottomSheet<LibraryClass>(
      context: context,
      title: l.libAssignClass,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l.libAssignHint, style: WinType.bodyS(WinTheme.of(context).onMuted)),
        ),
        for (final c in classes)
          ListTile(
            leading: const Icon(PhosphorIconsRegular.chalkboardTeacher),
            title: Text(c.name),
            onTap: () => Navigator.pop(context, c),
          ),
      ]),
    );
    if (klass == null || !mounted) return;
    try {
      final charged = await _svc.assignToClass(klass.id, item.subjectId);
      if (!mounted) return;
      _toast(charged > 0
          ? l.libAssignedCharged(klass.name, '${fmtXaf(charged.round())} XAF')
          : l.libAssigned(klass.name));
    } on LibraryException catch (e) {
      if (!mounted) return;
      _toast(e.status == 402 && e.requiredXaf != null
          ? l.libAssignNoBalance('${fmtXaf(e.requiredXaf!.round())} XAF', '${fmtXaf((e.balanceXaf ?? 0).round())} XAF')
          : e.message);
    }
  }

  Widget _filters(WinScheme s, AppLocalizations l) => SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          WinChip(l.libAll, active: _filter == _all, onTap: () => _setFilter(_all)),
          const SizedBox(width: 8),
          WinChip(l.libAnnotated,
              icon: PhosphorIconsRegular.tag, active: _filter == _annotated, onTap: () => _setFilter(_annotated)),
          for (final f in _folders) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: () => _folderActions(f),
              child: WinChip(f.name,
                  icon: PhosphorIconsRegular.folderSimple, active: _filter == f.id, onTap: () => _setFilter(f.id)),
            ),
          ],
          const SizedBox(width: 8),
          WinChip(l.libNewFolder, icon: PhosphorIconsRegular.plus, onTap: _createFolder),
        ]),
      );

  Widget _item(WinScheme s, AppLocalizations l, LibraryItem it) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: WinCard(
          onTap: () => _itemActions(it),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(it.title, style: WinType.titleS(s.onStrong))),
              const SizedBox(width: 8),
              WinBadge(it.source == 'purchased' ? l.libPurchased : l.libOrganized,
                  color: it.source == 'purchased' ? BadgeColor.blue : BadgeColor.teal),
            ]),
            if ((it.category ?? '').isNotEmpty || (it.collectionName ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                  [
                    if ((it.category ?? '').isNotEmpty) it.category!,
                    if ((it.collectionName ?? '').isNotEmpty) it.collectionName!,
                  ].join(' · '),
                  style: WinType.labelM(s.onMuted)),
            ],
            if (it.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [for (final t in it.tags) WinBadge(_tagLabel(l, t))]),
            ],
            if ((it.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(it.notes!.trim(), style: WinType.bodyS(s.onMuted), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget list;
    if (_error) {
      list = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      list = const WinLoading();
    } else if (items.isEmpty) {
      final filtered = _search.text.trim().isNotEmpty || _filter != _all;
      list = WinEmptyState(
        icon: PhosphorIconsRegular.books,
        title: filtered ? l.libNoMatch : l.libEmptyTitle,
        message: filtered ? null : l.libEmptyText,
      );
    } else {
      list = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [for (final it in items) _item(s, l, it)],
        ),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.libTitle)),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.libSearch,
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              ),
            ),
          ),
          _filters(s, l),
          const SizedBox(height: 8),
          Expanded(child: list),
        ]),
      ),
    );
  }
}

/// Libellé d'un tag : les tags proposés sont enregistrés en français.
String _tagLabel(AppLocalizations l, String tag) => switch (LibraryService.suggestedTags.indexOf(tag)) {
      0 => l.libTagReview,
      1 => l.libTagHard,
      2 => l.libTagMastered,
      3 => l.libTagToBuy,
      _ => tag,
    };

class _Organized {
  final int? folderId;
  final List<String> tags;
  final String notes;
  const _Organized(this.folderId, this.tags, this.notes);
}

/// Feuille « Ranger » : dossier, tags (proposés ou libres), note privée.
class _OrganizeForm extends StatefulWidget {
  final LibraryItem item;
  final List<LibraryFolder> folders;
  const _OrganizeForm({required this.item, required this.folders});

  @override
  State<_OrganizeForm> createState() => _OrganizeFormState();
}

class _OrganizeFormState extends State<_OrganizeForm> {
  late int? _folder = widget.folders.any((f) => f.id == widget.item.collectionId) ? widget.item.collectionId : null;
  late final List<String> _tags = [...widget.item.tags];
  late final _notes = TextEditingController(text: widget.item.notes ?? '');
  final _newTag = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    _newTag.dispose();
    super.dispose();
  }

  void _toggle(String t) => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t));

  void _addTag() {
    final t = _newTag.text.trim();
    if (t.isEmpty) return;
    if (!_tags.any((x) => x.toLowerCase() == t.toLowerCase()) && _tags.length < 10) setState(() => _tags.add(t));
    _newTag.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final free = _tags.where((t) => !LibraryService.suggestedTags.contains(t)).toList();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(l.libFolder, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          WinChip(l.libNoFolder, active: _folder == null, onTap: () => setState(() => _folder = null)),
          for (final f in widget.folders)
            WinChip(f.name, active: _folder == f.id, onTap: () => setState(() => _folder = f.id)),
        ]),
        const SizedBox(height: 14),
        Text(l.libTags, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final t in LibraryService.suggestedTags)
            WinChip(_tagLabel(l, t), active: _tags.contains(t), onTap: () => _toggle(t)),
          for (final t in free) WinChip(t, active: true, icon: PhosphorIconsRegular.x, onTap: () => _toggle(t)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _newTag,
              maxLength: 40,
              decoration: InputDecoration(hintText: l.libAddTag, counterText: ''),
              onSubmitted: (_) => _addTag(),
            ),
          ),
          IconButton(onPressed: _addTag, tooltip: l.libAddTag, icon: const Icon(PhosphorIconsRegular.plus)),
        ]),
        const SizedBox(height: 14),
        Text(l.libNotes, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 6),
        TextField(controller: _notes, maxLength: 300, maxLines: 3, decoration: InputDecoration(hintText: l.libNotesHint)),
        const SizedBox(height: 12),
        WinButton(l.libSave,
            block: true,
            onTap: () => Navigator.pop(context, _Organized(_folder, List.of(_tags), _notes.text.trim()))),
      ]),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _NameDialog({required this.title, this.initial = ''});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: context.l10n.libFolderName),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: Text(context.l10n.commonConfirm)),
        ],
      );
}
