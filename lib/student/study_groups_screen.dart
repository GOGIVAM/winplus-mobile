import 'package:flutter/material.dart';
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
/// Le classement hebdomadaire de l'ancien écran n'est pas repris : aucun
/// endpoint serveur ne le fournit, et créer une route dédiée pour ça sort du
/// périmètre de ce portage (décision §16.3 du suivi : réutiliser les
/// endpoints existants, pas en ajouter sans écart bloquant réel).
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
      if (mounted) setState(() { _groups = []; _error = "Vos groupes n'ont pas pu être chargés."; });
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
        title: const Text('Quitter ce groupe ?'),
        content: Text(group.isOwner
            ? 'Quitter « ${group.name} » ? Le groupe sera archivé pour tous ses membres.'
            : 'Quitter « ${group.name} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitter')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StudyGroupService.instance.leave(group.id);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = "Vous n'avez pas pu quitter ce groupe.");
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
        title: Text("Groupes d'étude", style: WinType.headlineS(s.onStrong)),
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
                WinSectionHeader('Mes groupes'),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Icon(Icons.groups_outlined, size: 28, color: s.onFaint),
                      const SizedBox(height: 8),
                      Text('Aucun groupe pour le moment.',
                          style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('Créez un groupe ou rejoignez celui d\'un camarade avec son code.',
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
                WinButton("+ Créer un groupe",
                    block: true, variant: WinButtonVariant.outline, onTap: _showCreateSheet),
                const SizedBox(height: 10),
                WinButton('Rejoindre par code',
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
          if (group.isOwner) const WinBadge('Propriétaire', color: BadgeColor.teal),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (group.subject != null) ...[WinChip(group.subject!), const SizedBox(width: 10)],
          Text('${group.memberCount} membre${group.memberCount != 1 ? 's' : ''}',
              style: WinType.labelM(s.onMuted)),
        ]),
        if (group.description != null && group.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(group.description!, style: WinType.labelM(s.onMuted)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          WinButton('Voir', small: true, variant: WinButtonVariant.outline, onTap: onTap),
          const SizedBox(width: 8),
          WinButton('Quitter', small: true, variant: WinButtonVariant.ghost, onTap: onLeave),
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
      setState(() => _error = 'Le nom doit contenir au moins 3 caractères.');
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
      if (mounted) setState(() { _busy = false; _error = "Le groupe n'a pas pu être créé."; });
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
            Text('Créer un groupe', style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            if (_error != null) ...[WinAlert(_error!, type: BadgeColor.error), const SizedBox(height: 12)],
            WinTextField(icon: Icons.group, hint: 'Nom du groupe (min 3 caractères)', controller: _nameCtrl),
            const SizedBox(height: 12),
            WinTextField(icon: Icons.menu_book_outlined, hint: 'Matière principale (optionnel)', controller: _subjectCtrl),
            const SizedBox(height: 24),
            WinButton(_busy ? 'Création…' : 'Créer', block: true, onTap: _busy ? null : _submit),
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
        const SnackBar(content: Text("Entrez le code d'invitation complet.")),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await StudyGroupService.instance.join(code);
      if (mounted) Navigator.pop(context);
      widget.onResult(
        res.alreadyMember ? 'Vous faites déjà partie de « ${res.name} ».' : 'Groupe « ${res.name} » rejoint avec succès !',
        true,
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      widget.onResult('Aucun groupe ne correspond à ce code.', false);
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
            Text('Rejoindre par code', style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            WinTextField(
                icon: Icons.vpn_key,
                hint: "Code d'invitation",
                controller: _codeCtrl),
            const SizedBox(height: 24),
            WinButton(_busy ? 'Envoi…' : 'Rejoindre', block: true, onTap: _busy ? null : _submit),
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
                    ? Text('Impossible de charger ce groupe.', style: WinType.bodyM(s.onMuted))
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
                  Text('${detail.members.length} membres', style: WinType.bodyS(s.onMuted)),
                  const SizedBox(width: 10),
                  WinButton(detail.joinCode, small: true, variant: WinButtonVariant.outline, onTap: () {}),
                ]),
                const SizedBox(height: 20),
                Text('Membres', style: WinType.titleM(s.onStrong)),
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
                                Text(m.fullName.isEmpty ? 'Membre' : m.fullName, style: WinType.bodyM(s.onStrong)),
                                Text(m.role == 'owner' ? 'Propriétaire' : 'Membre',
                                    style: WinType.labelS(s.onMuted)),
                              ])),
                        ]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
