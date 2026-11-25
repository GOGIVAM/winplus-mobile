import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_exams_service.dart';
import '../services/institution_service.dart';
import '../shared/bulletin_view.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Bulletins » de l'établissement (lot 7), comme InstitutionBulletins du
/// site : bulletins déjà partagés, et préparation d'un bulletin (élève,
/// période, aperçu calculé, appréciation proposée par WinAI, partage à
/// l'élève et à ses parents).
class InstitutionBulletinsScreen extends StatefulWidget {
  const InstitutionBulletinsScreen({super.key});

  @override
  State<InstitutionBulletinsScreen> createState() => _InstitutionBulletinsScreenState();
}

class _InstitutionBulletinsScreenState extends State<InstitutionBulletinsScreen> {
  final _svc = InstitutionExamsService.instance;
  List<BulletinSummary>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final items = await _svc.sharedBulletins();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  Future<void> _prepare() async {
    final shared = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const BulletinPrepareScreen()));
    if (shared == true) await _load();
  }

  Future<void> _delete(BulletinSummary b) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.bullDelete),
        content: Text(l.bullDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.bullDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteBulletin(b.id);
      if (mounted) await _load();
    } on InstitutionExamsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const WinLoading();
    } else if (items.isEmpty) {
      body = WinEmptyState(
        icon: PhosphorIconsRegular.scroll,
        title: l.bullEmptyTitle,
        message: l.bullEmptyText,
        actionLabel: l.bullPrepare,
        onAction: _prepare,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
          for (final b in items) bulletinTile(context, b, showStudent: true, onDelete: () => _delete(b)),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.bullTitle)),
      floatingActionButton: items == null || items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _prepare, icon: const Icon(PhosphorIconsRegular.plus), label: Text(l.bullPrepare)),
      body: SafeArea(child: body),
    );
  }
}

/// Préparer un bulletin : élève, période, aperçu, appréciation, partage.
class BulletinPrepareScreen extends StatefulWidget {
  const BulletinPrepareScreen({super.key});

  @override
  State<BulletinPrepareScreen> createState() => _BulletinPrepareScreenState();
}

class _BulletinPrepareScreenState extends State<BulletinPrepareScreen> {
  final _svc = InstitutionExamsService.instance;
  final _search = TextEditingController();
  final _label = TextEditingController();
  final _appreciation = TextEditingController();
  int? _institutionId;
  List<ApiInstitutionStudent> _results = const [];
  ApiInstitutionStudent? _student;
  late DateTime _from;
  late DateTime _to;
  BulletinData? _preview;
  bool _loadingPreview = false;
  bool _writing = false;
  bool _sharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 90));
    InstitutionService.instance.getMyInstitutionId().then((id) {
      if (mounted) setState(() => _institutionId = id);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _search.dispose();
    _label.dispose();
    _appreciation.dispose();
    super.dispose();
  }

  Future<void> _find(String q) async {
    final id = _institutionId;
    if (id == null || q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    try {
      final r = await InstitutionService.instance.getStudentDirectory(id, q: q.trim(), pageSize: 8);
      if (mounted) setState(() => _results = r);
    } catch (_) {}
  }

  Future<void> _pickDate(bool from) async {
    final d = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      if (from) {
        _from = d;
      } else {
        _to = d;
      }
      _preview = null;
    });
  }

  Future<void> _loadPreview() async {
    final st = _student;
    if (st == null) return;
    setState(() {
      _loadingPreview = true;
      _error = null;
    });
    try {
      final p = await _svc.preview(st.studentId, _from, _to);
      if (mounted) setState(() => _preview = p);
    } on InstitutionExamsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _write() async {
    final st = _student;
    if (st == null) return;
    setState(() => _writing = true);
    try {
      final text = await _svc.appreciation(st.studentId, _from, _to, _label.text.trim());
      if (mounted && text.isNotEmpty) _appreciation.text = text;
    } on InstitutionExamsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _share() async {
    final l = context.l10n;
    final st = _student;
    if (st == null) return;
    if (_label.text.trim().isEmpty) {
      setState(() => _error = l.bullNeedLabel);
      return;
    }
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      final parents = await _svc.share(st.studentId, _from, _to, _label.text, _appreciation.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.bullShared(parents))));
      Navigator.of(context).pop(true);
    } on InstitutionExamsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final st = _student;
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(t, style: WinType.labelM(s.onStrong)),
        );
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.bullPrepare)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          label(l.bullStudent),
          if (st != null)
            WinCard(
              child: Row(children: [
                Icon(PhosphorIconsRegular.student, color: s.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(st.fullName, style: WinType.titleS(s.onStrong)),
                    if ((st.group ?? '').isNotEmpty) Text(st.group!, style: WinType.labelM(s.onMuted)),
                  ]),
                ),
                IconButton(
                    tooltip: l.bullChangeStudent,
                    onPressed: () => setState(() {
                          _student = null;
                          _preview = null;
                        }),
                    icon: const Icon(PhosphorIconsRegular.x)),
              ]),
            )
          else ...[
            TextField(
              controller: _search,
              onChanged: _find,
              decoration: InputDecoration(
                hintText: l.bullSearchStudent,
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              ),
            ),
            for (final r in _results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.fullName),
                subtitle: Text([if ((r.group ?? '').isNotEmpty) r.group!, r.email].join(' · ')),
                onTap: () => setState(() {
                  _student = r;
                  _results = const [];
                  _preview = null;
                }),
              ),
          ],
          label(l.bullPeriodTitle),
          WinCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.calendarBlank),
                title: Text(l.bullFrom),
                trailing: Text(WinFormat.dateShort(_from)),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.calendarCheck),
                title: Text(l.bullTo),
                trailing: Text(WinFormat.dateShort(_to)),
                onTap: () => _pickDate(false),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          TextField(controller: _label, maxLength: 100, decoration: InputDecoration(hintText: l.bullLabelHint)),
          const SizedBox(height: 4),
          WinButton(l.bullPreview,
              block: true,
              variant: WinButtonVariant.outline,
              loading: _loadingPreview,
              onTap: st == null || _loadingPreview ? null : _loadPreview),
          if (_preview != null) ...[
            const SizedBox(height: 16),
            BulletinView(data: _preview!, periodLabel: _label.text.trim().isEmpty ? null : _label.text.trim()),
            label(l.bullAppreciation),
            TextField(controller: _appreciation, minLines: 3, maxLines: 8, decoration: InputDecoration(hintText: l.bullAppreciationHint)),
            const SizedBox(height: 8),
            WinButton(l.bullWriteWithWinai,
                block: true,
                variant: WinButtonVariant.ghost,
                icon: PhosphorIconsRegular.sparkle,
                loading: _writing,
                onTap: _writing ? null : _write),
            const SizedBox(height: 8),
            WinButton(l.bullShare,
                block: true, icon: PhosphorIconsRegular.paperPlaneTilt, loading: _sharing, onTap: _sharing ? null : _share),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            WinAlert(_error!, type: BadgeColor.error),
          ],
        ]),
      ),
    );
  }
}
