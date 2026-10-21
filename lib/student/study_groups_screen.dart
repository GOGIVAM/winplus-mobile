import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/study_group_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Module 24 (lot 8, rattrapage 16.3) : groupes d'étude réels
/// (StudyGroupsController.cs, mêmes endpoints que le web
/// student/StudyGroups.tsx), remplace l'écran 100% simulé (classement
/// fictif, code d'invitation "ABC123" codé en dur, groupes locaux).
///
/// Classement hebdomadaire réel ajouté après coup (GET
/// /api/study-groups/{id}/leaderboard), calculé sur l'activité des 7
/// derniers jours à partir de données déjà en base (quiz réussis, minutes
/// étudiées) -- plus de classement fictif.
class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});
  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  List<ApiStudyGroup>? _groups;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await StudyGroupService.instance.getMine();
      if (mounted) setState(() { _groups = groups; _error = null; });
    } catch (_) {
      if (mounted) setState(() { _groups = []; _error = L10n.current.studentGroupsLoadError; });
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(onCreated: _load),
    );
  }

  void _showJoinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JoinGroupSheet(
        onResult: (msg, ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: ok ? null : Colors.red.shade700),
          );
          if (ok) _load();
        },
      ),
    );
  }

  Future<void> _leave(ApiStudyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.studentGroupsLeaveTitle),
        content: Text(group.isOwner
            ? context.l10n.studentGroupsLeaveOwner(group.name)
            : context.l10n.studentGroupsLeaveConfirm(group.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.studentGroupsLeave)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StudyGroupService.instance.leave(group.id);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = L10n.current.studentGroupsLeaveError);
    }
  }

  void _openDetail(ApiStudyGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GroupDetailSheet(groupId: group.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final groups = _groups;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.studentLinksStudyGroups, style: WinType.headlineS(s.onStrong)),
      ),
      body: groups == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (_error != null) ...[
                  WinAlert(_error!, type: BadgeColor.warn),
                  const SizedBox(height: 12),
                ],
                WinSectionHeader(context.l10n.studentGroupsMine),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Icon(Icons.groups_outlined, size: 28, color: s.onFaint),
                      const SizedBox(height: 8),
                      Text(context.l10n.studentGroupsEmpty,
                          style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(context.l10n.studentGroupsEmptyHint,
                          style: WinType.labelS(s.onFaint), textAlign: TextAlign.center),
                    ]),
                  )
                else
                  ...groups.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GroupCard(
                          group: g,
                          onTap: () => _openDetail(g),
                          onLeave: () => _leave(g),
                        ),
                      )),
                const SizedBox(height: 16),
                WinButton(context.l10n.studentGroupsCreatePlus,
                    block: true, variant: WinButtonVariant.outline, onTap: _showCreateSheet),
                const SizedBox(height: 10),
                WinButton(context.l10n.studentGroupsJoinByCode,
                    block: true, variant: WinButtonVariant.ghost, onTap: _showJoinSheet),
              ],
            ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ApiStudyGroup group;
  final VoidCallback onTap;
  final VoidCallback onLeave;
  const _GroupCard({required this.group, required this.onTap, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(group.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.titleM(s.onStrong))),
          if (group.isOwner) WinBadge(context.l10n.studentGroupsOwner, color: BadgeColor.teal),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (group.subject != null) ...[WinChip(group.subject!), const SizedBox(width: 10)],
          Text(context.l10n.studentGroupsMemberCount(group.memberCount),
              style: WinType.labelM(s.onMuted)),
        ]),
        if (group.description != null && group.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(group.description!, style: WinType.labelM(s.onMuted)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          WinButton(context.l10n.studentHomeSee, small: true, variant: WinButtonVariant.outline, onTap: onTap),
          const SizedBox(width: 8),
          WinButton(context.l10n.studentGroupsLeave, small: true, variant: WinButtonVariant.ghost, onTap: onLeave),
        ]),
      ]),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateGroupSheet({required this.onCreated});
  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 3) {
      setState(() => _error = context.l10n.studentGroupsNameTooShort);
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await StudyGroupService.instance.create(
        name: name,
        subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = L10n.current.studentGroupsCreateError; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: s.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: s.outline2, borderRadius: BorderRadius.circular(WinRadii.full)),
              ),
            ),
            Text(context.l10n.studentGroupsCreate, style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            if (_error != null) ...[WinAlert(_error!, type: BadgeColor.error), const SizedBox(height: 12)],
            WinTextField(icon: Icons.group, hint: context.l10n.studentGroupsNameHint, controller: _nameCtrl),
            const SizedBox(height: 12),
            WinTextField(icon: Icons.menu_book_outlined, hint: context.l10n.studentGroupsSubjectHint, controller: _subjectCtrl),
            const SizedBox(height: 24),
            WinButton(_busy ? context.l10n.studentGroupsCreating : context.l10n.studentGroupsCreateBtn, block: true, onTap: _busy ? null : _submit),
          ]),
    );
  }
}

class _JoinGroupSheet extends StatefulWidget {
  final void Function(String msg, bool ok) onResult;
  const _JoinGroupSheet({required this.onResult});
  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.studentGroupsCodeIncomplete)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await StudyGroupService.instance.join(code);
      if (mounted) Navigator.pop(context);
      widget.onResult(
        res.alreadyMember ? L10n.current.studentGroupsAlreadyMember(res.name) : L10n.current.studentGroupsJoined(res.name),
        true,
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      widget.onResult(L10n.current.studentGroupsCodeNotFound, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: s.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: s.outline2, borderRadius: BorderRadius.circular(WinRadii.full)),
              ),
            ),
            Text(context.l10n.studentGroupsJoinByCode, style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            WinTextField(
                icon: Icons.vpn_key,
                hint: context.l10n.studentGroupsInviteCode,
                controller: _codeCtrl),
            const SizedBox(height: 24),
            WinButton(_busy ? context.l10n.studentGroupsSending : context.l10n.studentGroupsJoin, block: true, onTap: _busy ? null : _submit),
          ]),
    );
  }
}

class _GroupDetailSheet extends StatefulWidget {
  final int groupId;
  const _GroupDetailSheet({required this.groupId});
  @override
  State<_GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends State<_GroupDetailSheet> {
  ApiStudyGroupDetail? _detail;
  ApiStudyGroupLeaderboard? _leaderboard;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await StudyGroupService.instance.getOne(widget.groupId);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      return;
    }
    try {
      final lb = await StudyGroupService.instance.getLeaderboard(widget.groupId);
      if (mounted) setState(() => _leaderboard = lb);
    } catch (_) {
      // Classement non bloquant : la fiche groupe reste utilisable sans lui.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final detail = _detail;
    return Container(
      decoration: BoxDecoration(
          color: s.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: detail == null
          ? SizedBox(
              height: 160,
              child: Center(
                child: _error
                    ? Text(context.l10n.studentGroupsDetailLoadError, style: WinType.bodyM(s.onMuted))
                    : const CircularProgressIndicator(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: s.outline2, borderRadius: BorderRadius.circular(WinRadii.full)))),
                Row(children: [
                  Expanded(child: Text(detail.name, style: WinType.archivo(size: 20, color: s.onStrong))),
                  if (detail.subject != null) WinChip(detail.subject!),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(context.l10n.studentGroupsMembersCount(detail.members.length), style: WinType.bodyS(s.onMuted)),
                  const SizedBox(width: 10),
                  WinButton(detail.joinCode, small: true, variant: WinButtonVariant.outline, onTap: () {}),
                ]),
                const SizedBox(height: 20),
                Text(context.l10n.studentGroupsMembers, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: detail.members.length,
                    itemBuilder: (_, i) {
                      final m = detail.members[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          WinAvatar(m.fullName.isEmpty ? '?' : m.fullName, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(m.fullName.isEmpty ? context.l10n.studentGroupsMember : m.fullName, style: WinType.bodyM(s.onStrong)),
                                Text(m.role == 'owner' ? context.l10n.studentGroupsOwner : context.l10n.studentGroupsMember,
                                    style: WinType.labelS(s.onMuted)),
                              ])),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(context.l10n.studentGroupsLeaderboard, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 10),
                if (_leaderboard == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(context.l10n.studentGroupsLeaderboardUnavailable,
                        style: WinType.labelM(s.onFaint)),
                  )
                else if (_leaderboard!.ranking.every((r) => r.points == 0))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(context.l10n.studentGroupsNoActivity,
                        style: WinType.labelM(s.onFaint)),
                  )
                else
                  ..._leaderboard!.ranking.take(10).toList().asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final r = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        SizedBox(
                          width: 24,
                          child: Text('$rank', style: WinType.labelM(s.onMuted)),
                        ),
                        WinAvatar(r.fullName.isEmpty ? '?' : r.fullName, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.fullName.isEmpty ? context.l10n.studentGroupsMember : r.fullName,
                                  style: WinType.bodyM(s.onStrong)),
                              Text(context.l10n.studentGroupsRankLine(r.quizzesPassed, r.studyMinutes),
                                  style: WinType.labelS(s.onMuted)),
                            ],
                          ),
                        ),
                        Text('${r.points} pts', style: WinType.titleM(s.onStrong)),
                      ]),
                    );
                  }),
              ],
            ),
    );
  }
}
