import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/announcement_service.dart';
import '../services/institution_service.dart';
import '../shared/announcements_feed.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Annonces » de l'établissement (lot 7), comme InstitutionAnnouncements
/// du site : annonces envoyées (public, classe, destinataires, fin), création
/// (titre, message, public, type, classe, date de fin) et suppression. Les
/// destinataires reçoivent une notification ; « Urgent » est prioritaire.
class InstitutionAnnouncementsScreen extends StatefulWidget {
  const InstitutionAnnouncementsScreen({super.key});

  @override
  State<InstitutionAnnouncementsScreen> createState() => _InstitutionAnnouncementsScreenState();
}

class _InstitutionAnnouncementsScreenState extends State<InstitutionAnnouncementsScreen> {
  List<ApiSentAnnouncement>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final list = await AnnouncementService.instance.sent();
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  String _audience(AppLocalizations l, String a) => switch (a) {
        'students' => l.annAudienceStudents,
        'parents' => l.annAudienceParents,
        _ => l.annAudienceAll,
      };

  Future<void> _create() async {
    final count = await showWinBottomSheet<int>(
      context: context,
      title: context.l10n.annNew,
      child: const _AnnouncementForm(),
    );
    if (count == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.annSent(count))));
    _load();
  }

  Future<void> _delete(ApiSentAnnouncement a) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.annDeleteTitle),
        content: Text(l.annDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.commonDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AnnouncementService.instance.delete(a.id);
      if (mounted) setState(() => _items = _items?.where((x) => x.id != a.id).toList());
    } on AnnouncementException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? l.annDeleteError)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonLoadError)));
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
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          WinButton(l.annNew, block: true, icon: PhosphorIconsRegular.megaphone, onTap: _create),
          const SizedBox(height: 16),
          if (items.isEmpty)
            WinEmptyState(
                title: l.annSentEmpty, icon: PhosphorIconsRegular.megaphone)
          else
            for (final a in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WinCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(a.title, style: WinType.titleM(s.onStrong))),
                      const SizedBox(width: 8),
                      announcementTypeBadge(context, a.type),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        [
                          _audience(l, a.audience),
                          if ((a.groupName ?? '').isNotEmpty) a.groupName!,
                          l.annRecipients(a.recipientCount),
                          if (a.createdAt != null) WinFormat.dateShort(a.createdAt!),
                        ].join(' · '),
                        style: WinType.labelS(s.onMuted)),
                    const SizedBox(height: 8),
                    Text(a.content, maxLines: 4, overflow: TextOverflow.ellipsis, style: WinType.bodyM(s.onStrong)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: Text(
                            a.expiresAt == null
                                ? l.annNoEnd
                                : a.expired
                                    ? l.annExpired
                                    : l.annUntil(WinFormat.dateShort(a.expiresAt!)),
                            style: WinType.labelS(s.onFaint)),
                      ),
                      IconButton(
                        tooltip: l.commonDelete,
                        icon: const Icon(PhosphorIconsRegular.trash),
                        onPressed: () => _delete(a),
                      ),
                    ]),
                  ]),
                ),
              ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.annTitle)),
      body: SafeArea(child: body),
    );
  }
}

/// Formulaire de création ; se ferme avec le nombre de destinataires.
class _AnnouncementForm extends StatefulWidget {
  const _AnnouncementForm();

  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  String _audience = 'all';
  String _type = 'info';
  int? _groupId;
  DateTime? _until;
  List<ApiGroup> _groups = const [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Classes de l'établissement, pour viser une seule classe (facultatif).
    InstitutionService.instance.getGroups().then((g) {
      if (mounted) setState(() => _groups = g);
    }).catchError((Object e) {
      debugPrint('Annonces : classes indisponibles ($e)');
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _until ?? now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _until = DateTime(d.year, d.month, d.day, 23, 59));
  }

  Future<void> _send() async {
    final l = context.l10n;
    final title = _title.text.trim(), content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = l.annRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      final count = await AnnouncementService.instance.create(
        title: title,
        content: content,
        audience: _audience,
        type: _type,
        groupId: _groupId,
        expiresAt: _until,
      );
      navigator.pop(count);
    } on AnnouncementException catch (e) {
      if (mounted) setState(() => _error = e.message ?? l.annSendError);
    } catch (_) {
      if (mounted) setState(() => _error = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: WinType.titleM(s.onStrong)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      WinTextField(label: l.annFormTitle, controller: _title),
      const SizedBox(height: 12),
      TextField(
        controller: _content,
        minLines: 4,
        maxLines: 10,
        maxLength: 4000,
        decoration: InputDecoration(labelText: l.annFormContent, alignLabelWithHint: true),
      ),
      const SizedBox(height: 8),
      label(l.annFormAudience),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (v, t) in [('all', l.annAudienceAll), ('students', l.annAudienceStudents), ('parents', l.annAudienceParents)])
          WinChip(t, active: _audience == v, onTap: () => setState(() => _audience = v)),
      ]),
      const SizedBox(height: 16),
      label(l.annFormType),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (v, t) in [('info', l.annTypeInfo), ('important', l.annTypeImportant), ('urgent', l.annTypeUrgent)])
          WinChip(t, active: _type == v, onTap: () => setState(() => _type = v)),
      ]),
      if (_groups.isNotEmpty) ...[
        const SizedBox(height: 16),
        label(l.annFormClass),
        Wrap(spacing: 8, runSpacing: 8, children: [
          WinChip(l.annAllClasses, active: _groupId == null, onTap: () => setState(() => _groupId = null)),
          for (final g in _groups)
            WinChip(g.name, active: _groupId == g.id, onTap: () => setState(() => _groupId = g.id)),
        ]),
      ],
      const SizedBox(height: 16),
      label(l.annFormUntil),
      Row(children: [
        Expanded(
          child: Text(_until == null ? l.annNoEnd : l.annUntil(WinFormat.dateShort(_until!)),
              style: WinType.bodyM(s.onMuted)),
        ),
        if (_until != null)
          IconButton(
              tooltip: l.annRemoveEnd,
              icon: const Icon(PhosphorIconsRegular.x),
              onPressed: () => setState(() => _until = null)),
        TextButton(onPressed: _pickDate, child: Text(l.annChooseDate)),
      ]),
      if (_error != null) ...[
        const SizedBox(height: 8),
        WinAlert(_error!, type: BadgeColor.error),
      ],
      const SizedBox(height: 16),
      WinButton(l.annPublish,
          block: true, icon: PhosphorIconsRegular.paperPlaneTilt, loading: _busy, onTap: _busy ? null : _send),
      const SizedBox(height: 8),
    ]);
  }
}
