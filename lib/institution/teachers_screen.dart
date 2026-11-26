import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_service.dart';
import '../services/institution_teachers_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// « Enseignants » de l'établissement (lot 7), comme InstitutionTeachers du
/// site : demandes reçues, enseignants affiliés (contenus, quiz, classes),
/// affecter à une classe ou retirer, invitations envoyées, inviter.
class InstitutionTeachersScreen extends StatefulWidget {
  const InstitutionTeachersScreen({super.key});

  @override
  State<InstitutionTeachersScreen> createState() => _InstitutionTeachersScreenState();
}

class _InstitutionTeachersScreenState extends State<InstitutionTeachersScreen> {
  final _svc = InstitutionTeachersService.instance;
  InstitutionTeachersData? _data;
  List<ApiGroup> _groups = const [];
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
      final d = await _svc.load();
      List<ApiGroup> groups = _groups;
      try {
        groups = await InstitutionService.instance.getGroups();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _data = d;
          _groups = groups;
        });
      }
    } catch (_) {
      if (mounted && _data == null) setState(() => _error = true);
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } on InstitutionTeachersException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String text, String action) async =>
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

  Future<void> _assign(InstitutionTeacher t) async {
    final l = context.l10n;
    final taken = t.classes.map((c) => c.$1).toSet();
    final free = _groups.where((g) => !taken.contains(g.id)).toList();
    if (free.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.teachNoClassLeft)));
      return;
    }
    final g = await showWinBottomSheet<ApiGroup>(
      context: context,
      title: l.teachAssignTo(t.name),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: ListView(shrinkWrap: true, children: [
          for (final g in free)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.chalkboardTeacher),
              title: Text(g.name),
              subtitle: g.level.isEmpty ? null : Text(g.level),
              onTap: () => Navigator.pop(context, g),
            ),
        ]),
      ),
    );
    if (g == null) return;
    await _run(() => _svc.assign(g.id, t.id), l.teachAssigned(t.name, g.name));
  }

  Future<void> _unassign(InstitutionTeacher t, (int, String) c) async {
    final l = context.l10n;
    if (!await _confirm(l.teachUnassign, l.teachUnassignConfirm(t.name, c.$2), l.teachUnassign)) return;
    await _run(() => _svc.unassign(c.$1, t.id), l.teachUnassigned);
  }

  Future<void> _revoke(InstitutionTeacher t) async {
    final l = context.l10n;
    if (!await _confirm(l.teachRevoke, l.teachRevokeConfirm(t.name), l.teachRevoke)) return;
    await _run(() => _svc.revoke(t.linkId), l.teachRevoked);
  }

  Future<void> _invite() async {
    final hit = await showWinBottomSheet<TeacherHit>(
      context: context,
      title: context.l10n.teachInvite,
      child: const _TeacherSearch(),
    );
    if (hit == null || !mounted) return;
    await _run(() => _svc.invite(hit.id), context.l10n.teachInvited(hit.name));
  }

  Widget _request(WinScheme s, AppLocalizations l, AffiliationRequest r, {required bool received}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: WinType.titleS(s.onStrong)),
            if ((r.email ?? '').isNotEmpty) Text(r.email!, style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            if (received)
              Row(children: [
                Expanded(
                    child: WinButton(l.teachAccept,
                        small: true, onTap: _busy ? null : () => _run(() => _svc.accept(r.linkId), l.teachAccepted(r.name)))),
                const SizedBox(width: 8),
                Expanded(
                    child: WinButton(l.teachDecline,
                        small: true,
                        variant: WinButtonVariant.outline,
                        onTap: _busy ? null : () => _run(() => _svc.reject(r.linkId), l.teachDeclined))),
              ])
            else
              WinButton(l.teachCancelInvite,
                  small: true,
                  variant: WinButtonVariant.ghost,
                  onTap: _busy ? null : () => _run(() => _svc.revoke(r.linkId), l.teachInviteCancelled)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = _data;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (d == null) {
      body = const WinLoading();
    } else if (d.teachers.isEmpty && d.received.isEmpty && d.sent.isEmpty) {
      body = WinEmptyState(
        icon: PhosphorIconsRegular.chalkboardTeacher,
        title: l.teachEmptyTitle,
        message: l.teachEmptyText,
        actionLabel: l.teachInvite,
        onAction: _invite,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
          if (d.received.isNotEmpty) ...[
            Text(l.teachReceived(d.received.length), style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            for (final r in d.received) _request(s, l, r, received: true),
            const SizedBox(height: 12),
          ],
          Text(l.teachAffiliated(d.teachers.length), style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          if (d.teachers.isEmpty) Text(l.teachNoneYet, style: WinType.bodyM(s.onMuted)),
          for (final t in d.teachers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WinCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.name, style: WinType.titleS(s.onStrong)),
                        if ((t.email ?? '').isNotEmpty) Text(t.email!, style: WinType.labelM(s.onMuted)),
                      ]),
                    ),
                    IconButton(
                        tooltip: l.teachRevoke,
                        onPressed: _busy ? null : () => _revoke(t),
                        icon: const Icon(PhosphorIconsRegular.userMinus, color: WinColors.error)),
                  ]),
                  Text(l.teachStats(t.contents, t.published, t.quizzes), style: WinType.labelM(s.onMuted)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final c in t.classes)
                      WinChip(c.$2, icon: PhosphorIconsRegular.x, onTap: _busy ? null : () => _unassign(t, c)),
                    WinChip(l.teachAssign, icon: PhosphorIconsRegular.plus, onTap: _busy ? null : () => _assign(t)),
                  ]),
                ]),
              ),
            ),
          if (d.sent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.teachSent(d.sent.length), style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            for (final r in d.sent) _request(s, l, r, received: false),
          ],
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.teachTitle)),
      floatingActionButton: d == null || (d.teachers.isEmpty && d.received.isEmpty && d.sent.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _invite, icon: const Icon(PhosphorIconsRegular.userPlus), label: Text(l.teachInvite)),
      body: SafeArea(child: body),
    );
  }
}

class _TeacherSearch extends StatefulWidget {
  const _TeacherSearch();

  @override
  State<_TeacherSearch> createState() => _TeacherSearchState();
}

class _TeacherSearchState extends State<_TeacherSearch> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<TeacherHit> _hits = const [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final h = await InstitutionTeachersService.instance.search(q);
        if (mounted) {
          setState(() {
            _hits = h;
            _searched = q.trim().length >= 2;
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _q,
          autofocus: true,
          onChanged: _search,
          decoration: InputDecoration(hintText: l.teachSearch, prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass)),
        ),
        if (_searched && _hits.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(l.teachNoResult)),
        for (final h in _hits)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(PhosphorIconsRegular.chalkboardTeacher),
            title: Text(h.name),
            subtitle: (h.email ?? '').isEmpty ? null : Text(h.email!),
            onTap: () => Navigator.pop(context, h),
          ),
      ]),
    );
  }
}
