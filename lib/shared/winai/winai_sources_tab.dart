import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/winai_sources_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';

/// Onglet « Sources » de WinAI : les fichiers de l'utilisateur (téléversés,
/// analysés par le serveur, supprimables) et les contenus WinPlus auxquels
/// il a accès (épreuves, formations, erreurs de quiz). Ce qui est coché ici
/// limite la discussion et les outils de l'atelier à ces sources.
class WinAISourcesTab extends StatefulWidget {
  /// Sources cochées, par clé « type:id ».
  final Map<String, WinAISourceRef> selected;
  final ValueChanged<Map<String, WinAISourceRef>> onChanged;
  const WinAISourcesTab(
      {super.key, required this.selected, required this.onChanged});

  @override
  State<WinAISourcesTab> createState() => _WinAISourcesTabState();
}

class _WinAISourcesTabState extends State<WinAISourcesTab>
    with AutomaticKeepAliveClientMixin {
  WinAISourcesData? _data;
  String? _error;
  bool _uploading = false;
  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _data = null;
        _error = null;
      });
    }
    try {
      final d = await WinAISourcesService.instance.load();
      if (!mounted) return;
      setState(() => _data = d);
      // Un fichier en cours d'analyse : on relit toutes les 5 s jusqu'à ce
      // qu'il soit prêt (ou en échec).
      _poll?.cancel();
      if (d.documents.any((x) => x.pending)) {
        _poll = Timer(const Duration(seconds: 5), () => _load(silent: true));
      }
    } on WinAISourceException catch (e) {
      if (mounted && !silent) setState(() => _error = e.message);
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _error = L10n.current.commonLoadError);
      }
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _add() async {
    final usage = _data?.usage ?? const WinAISourceUsage();
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf', 'docx', 'txt', 'md', 'png', 'jpg', 'jpeg', 'webp' // ignore: require_trailing_commas
        ],
        withData: true);
    final file = picked?.files.isNotEmpty == true ? picked!.files.first : null;
    final bytes = file?.bytes;
    if (!mounted || file == null || bytes == null) return;
    if (bytes.length > usage.maxFileBytes) {
      _toast(context.l10n.winaiSourcesTooBig(_size(usage.maxFileBytes)));
      return;
    }
    setState(() => _uploading = true);
    try {
      await WinAISourcesService.instance.upload(bytes, file.name);
      await _load(silent: true);
    } on WinAISourceException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(WinAIDocument doc) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(l.winaiSourcesDeleteTitle),
              content: Text(l.winaiSourcesDeleteBody(doc.title)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l.commonCancel)),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l.commonDelete)),
              ],
            ));
    if (ok != true) return;
    try {
      await WinAISourcesService.instance.delete(doc.id);
      final next = Map<String, WinAISourceRef>.of(widget.selected)
        ..remove(doc.ref.key);
      widget.onChanged(next);
      await _load(silent: true);
    } on WinAISourceException catch (e) {
      _toast(e.message);
    }
  }

  void _toggle(WinAISourceRef ref) {
    final max = _data?.usage.maxPerMessage ?? 10;
    final next = Map<String, WinAISourceRef>.of(widget.selected);
    if (next.containsKey(ref.key)) {
      next.remove(ref.key);
    } else {
      if (next.length >= max) {
        _toast(context.l10n.winaiSourcesMax(max));
        return;
      }
      next[ref.key] = ref;
    }
    widget.onChanged(next);
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb >= 10 ? mb.round() : mb.toStringAsFixed(1)} ${L10n.isEn ? 'MB' : 'Mo'}';
    }
    return '${(bytes / 1024).ceil()} ${L10n.isEn ? 'KB' : 'Ko'}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = WinTheme.of(context);
    final l = context.l10n;
    if (_error != null) {
      return WinErrorState(message: _error!, onRetry: _load);
    }
    final d = _data;
    if (d == null) return const WinLoading();

    Widget title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(t, style: WinType.titleL(s.onStrong)));

    final u = d.usage;
    final filesLabel = u.maxFiles < 0
        ? l.winaiSourcesUsageUnlimited(u.files)
        : l.winaiSourcesUsage(u.files, u.maxFiles);
    final volumeLabel = u.maxBytes < 0
        ? _size(u.bytes)
        : '${_size(u.bytes)} / ${_size(u.maxBytes)}';
    final full = u.maxFiles >= 0 && u.files >= u.maxFiles;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l.winaiSourcesHint, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 18),
          title(l.winaiSourcesMine),
          WinCard(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(filesLabel,
                            style: WinType.titleM(s.onStrong))),
                    Text(volumeLabel, style: WinType.labelM(s.onMuted)),
                  ]),
                  if (u.maxBytes > 0) ...[
                    const SizedBox(height: 8),
                    WinProgressBar((u.bytes * 100 / u.maxBytes).clamp(0, 100)),
                  ],
                  const SizedBox(height: 12),
                  WinButton(l.winaiSourcesAdd,
                      block: true,
                      variant: WinButtonVariant.outline,
                      icon: PhosphorIconsRegular.uploadSimple,
                      loading: _uploading,
                      onTap: full || _uploading ? null : _add),
                  const SizedBox(height: 8),
                  Text(l.winaiSourcesFormats(_size(u.maxFileBytes)),
                      style: WinType.labelM(s.onMuted)),
                ]),
          ),
          if (d.documents.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Group(children: [
              for (final doc in d.documents)
                _SourceLine(
                  title: doc.title,
                  detail: doc.pending
                      ? l.winaiSourcesPending
                      : doc.failed
                          ? (doc.error ?? l.winaiSourcesFailed)
                          : '${doc.fileName} · ${_size(doc.sizeBytes)}',
                  checked: widget.selected.containsKey(doc.ref.key),
                  enabled: doc.ready,
                  busy: doc.pending,
                  failed: doc.failed,
                  onChanged: () => _toggle(doc.ref),
                  onDelete: () => _delete(doc),
                ),
            ]),
          ],
          if (d.quizMistakes != null) ...[
            const SizedBox(height: 18),
            title(l.winaiSourcesProgress),
            _Group(children: [
              _SourceLine(
                title: d.quizMistakes!.title,
                detail: d.quizMistakes!.detail,
                checked: widget.selected.containsKey(d.quizMistakes!.key),
                onChanged: () => _toggle(d.quizMistakes!),
              ),
            ]),
          ],
          if (d.exams.isNotEmpty) ...[
            const SizedBox(height: 18),
            title(l.winaiSourcesExams),
            _Group(children: [
              for (final e in d.exams)
                _SourceLine(
                    title: e.title,
                    detail: e.detail,
                    checked: widget.selected.containsKey(e.key),
                    onChanged: () => _toggle(e)),
            ]),
          ],
          if (d.courses.isNotEmpty) ...[
            const SizedBox(height: 18),
            title(l.winaiSourcesCourses),
            _Group(children: [
              for (final c in d.courses)
                _SourceLine(
                    title: c.title,
                    detail: c.detail,
                    checked: widget.selected.containsKey(c.key),
                    onChanged: () => _toggle(c)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: s.outline, indent: 52),
          children[i],
        ],
      ]),
    );
  }
}

/// Une source à cocher : case, titre, détail, et la corbeille pour un fichier
/// de l'utilisateur.
class _SourceLine extends StatelessWidget {
  final String title;
  final String? detail;
  final bool checked, enabled, busy, failed;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;
  const _SourceLine({
    required this.title,
    required this.checked,
    required this.onChanged,
    this.detail,
    this.enabled = true,
    this.busy = false,
    this.failed = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return InkWell(
      onTap: enabled ? onChanged : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(children: [
          SizedBox(
            width: 48,
            child: busy
                ? const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : failed
                    ? const Icon(PhosphorIconsRegular.warningCircle,
                        size: 22, color: WinColors.error)
                    : Checkbox(
                        value: checked,
                        onChanged: enabled ? (_) => onChanged() : null),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.titleM(s.onStrong)),
                    if (detail != null && detail!.isNotEmpty)
                      Text(detail!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WinType.labelM(
                              failed ? WinColors.error : s.onMuted)),
                  ]),
            ),
          ),
          if (onDelete != null)
            IconButton(
                tooltip: context.l10n.commonDelete,
                icon: Icon(PhosphorIconsRegular.trash,
                    size: 20, color: s.onMuted),
                onPressed: onDelete)
          else
            const SizedBox(width: 12),
        ]),
      ),
    );
  }
}
