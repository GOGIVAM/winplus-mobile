import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/linking_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class MyLinksScreen extends StatefulWidget {
  const MyLinksScreen({super.key});
  @override
  State<MyLinksScreen> createState() => _MyLinksScreenState();
}

class _MyLinksScreenState extends State<MyLinksScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _pending = [];
  // Suivi 17.14 : rattachements à un établissement, à confirmer par l'élève.
  List<Map<String, dynamic>> _attachments = [];
  bool _loading = true;
  final Map<int, bool> _actioning = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        LinkingService.instance.getStudentLinks(),
        LinkingService.instance.getPendingInvitations(),
      ]);
      List<Map<String, dynamic>> attachments = [];
      try {
        attachments = await LinkingService.instance.getInstitutionAttachments();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _attachments = attachments;
          _data = results[0] as Map<String, dynamic>;
          _pending = results[1] as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _accept(int linkId) async {
    setState(() => _actioning[linkId] = true);
    try {
      await LinkingService.instance.acceptInvitation(linkId);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _actioning.remove(linkId));
      }
    }
  }

  Future<void> _respondAttachment(int id, bool accept) async {
    setState(() => _actioning[-id] = true);
    try {
      await LinkingService.instance.respondInstitutionAttachment(id, accept: accept);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.current.studentLinksActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _actioning.remove(-id));
    }
  }

  Future<void> _reject(int linkId) async {
    setState(() => _actioning[linkId] = true);
    try {
      await LinkingService.instance.rejectInvitation(linkId);
      if (mounted) {
        setState(() {
          _pending.removeWhere((p) => p['id'] == linkId);
          _actioning.remove(linkId);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actioning.remove(linkId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: s.onStrong),
            onPressed: () => Navigator.pop(context)),
        title: Text(context.l10n.studentLinksTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(
                  child: Text(context.l10n.studentLinksLoadError,
                      style: WinType.bodyM(s.onMuted)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_pending.isNotEmpty) ...[
                          Row(children: [
                            Text(context.l10n.studentLinksInvitations,
                                style: WinType.titleM(s.onStrong)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: s.primary,
                                  borderRadius:
                                      BorderRadius.circular(WinRadii.full)),
                              child: Text('${_pending.length}',
                                  style: WinType.labelM(s.onPrimary)
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          ..._pending.map((inv) {
                            final id = inv['id'] as int;
                            final name =
                                '${inv['firstName'] ?? ''} ${inv['lastName'] ?? ''}'
                                    .trim();
                            final actioning = _actioning[id] == true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WinCard(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            inv['avatarUrl'] != null
                                                ? NetworkImage(
                                                    inv['avatarUrl'] as String)
                                                : null,
                                        backgroundColor: s.surface2,
                                        child: inv['avatarUrl'] == null
                                            ? Icon(Icons.person,
                                                color: s.onFaint, size: 18)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                name.isEmpty
                                                    ? context.l10n.msgRoleUser
                                                    : name,
                                                style: WinType.bodyM(s.onStrong)
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                            Text(
                                                context.l10n.studentLinksTeacherPending,
                                                style:
                                                    WinType.labelM(s.onMuted)),
                                          ])),
                                    ]),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                          child: WinButton(
                                        context.l10n.commonAccept,
                                        small: true,
                                        loading: actioning,
                                        onTap: actioning
                                            ? null
                                            : () => _accept(id),
                                      )),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: WinButton(
                                        context.l10n.commonDecline,
                                        small: true,
                                        variant: WinButtonVariant.outline,
                                        onTap: actioning
                                            ? null
                                            : () => _reject(id),
                                      )),
                                    ]),
                                  ])),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                        if (_attachments.isNotEmpty) ...[
                          Text(context.l10n.studentLinksSchools, style: WinType.titleM(s.onStrong)),
                          const SizedBox(height: 4),
                          Text(
                              context.l10n.studentLinksSchoolsHint,
                              style: WinType.labelS(s.onFaint)),
                          const SizedBox(height: 8),
                          ..._attachments.map((a) {
                            final id = (a['id'] as num).toInt();
                            final status = a['status']?.toString() ?? 'pending';
                            final busy = _actioning[-id] == true;
                            final group = a['groupName']?.toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WinCard(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Icon(Icons.apartment_outlined, color: s.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(a['institutionName']?.toString() ?? context.l10n.roleInstitution,
                                        style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
                                    Text(
                                        [
                                          if (group != null && group.isNotEmpty) context.l10n.studentLinksClass(group),
                                          status == 'pending'
                                              ? context.l10n.studentLinksAttachPending
                                              : status == 'accepted'
                                                  ? context.l10n.studentLinksAttachAccepted
                                                  : context.l10n.studentLinksAttachRefused,
                                        ].join(' · '),
                                        style: WinType.labelM(s.onMuted)),
                                  ])),
                                ]),
                                const SizedBox(height: 10),
                                if (status == 'pending')
                                  Row(children: [
                                    Expanded(
                                        child: WinButton(context.l10n.commonAccept,
                                            small: true, loading: busy, onTap: busy ? null : () => _respondAttachment(id, true))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: WinButton(context.l10n.commonDecline,
                                            small: true,
                                            variant: WinButtonVariant.outline,
                                            onTap: busy ? null : () => _respondAttachment(id, false))),
                                  ])
                                else
                                  WinButton(status == 'accepted' ? context.l10n.studentLinksWithdraw : context.l10n.commonAccept,
                                      small: true,
                                      variant: WinButtonVariant.outline,
                                      loading: busy,
                                      onTap: busy ? null : () => _respondAttachment(id, status != 'accepted')),
                              ])),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                        _Section(
                            title: context.l10n.studentLinksParents,
                            items: (_data!['parents'] as List?) ?? [],
                            role: 'parent',
                            s: s),
                        _Section(
                            title: context.l10n.studentLinksTeachers,
                            items: (_data!['teachers'] as List?) ?? [],
                            role: 'teacher',
                            s: s),
                        if (_data!['institution'] != null) ...[
                          Text(context.l10n.roleInstitution,
                              style: WinType.titleM(s.onStrong)),
                          const SizedBox(height: 8),
                          _PersonCard(
                              person:
                                  _data!['institution'] as Map<String, dynamic>,
                              role: 'institution',
                              s: s),
                          const SizedBox(height: 20),
                        ],
                        if ((_data!['groups'] as List?)?.isNotEmpty ==
                            true) ...[
                          Text(context.l10n.studentLinksStudyGroups,
                              style: WinType.titleM(s.onStrong)),
                          const SizedBox(height: 8),
                          ...(_data!['groups'] as List).map((g) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: WinCard(
                                    child: Row(children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: s.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(WinRadii.sm)),
                                    child: Icon(Icons.groups_outlined,
                                        size: 20, color: s.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text((g as Map)['name'] ?? '',
                                          style: WinType.bodyM(s.onStrong)
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                  Icon(Icons.chevron_right,
                                      size: 18, color: s.onFaint),
                                ])),
                              )),
                          const SizedBox(height: 20),
                        ],
                      ]),
                ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List items;
  final String role;
  final WinScheme s;
  const _Section(
      {required this.title,
      required this.items,
      required this.role,
      required this.s});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 8),
      ...items.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PersonCard(
                person: p as Map<String, dynamic>, role: role, s: s),
          )),
      const SizedBox(height: 20),
    ]);
  }
}

class _PersonCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final String role;
  final WinScheme s;
  const _PersonCard(
      {required this.person, required this.role, required this.s});

  @override
  Widget build(BuildContext context) {
    final name =
        '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'.trim();
    return WinCard(
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: person['avatarUrl'] != null
              ? NetworkImage(person['avatarUrl'] as String)
              : null,
          backgroundColor: s.surface2,
          child: person['avatarUrl'] == null
              ? Icon(Icons.person, color: s.onFaint)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? context.l10n.msgRoleUser : name,
              style: WinType.bodyM(s.onStrong)
                  .copyWith(fontWeight: FontWeight.w600)),
          Text(
            role == 'teacher'
                ? (person['source'] == 'class'
                    ? context.l10n.studentLinksTeacherClass(person['className'] ?? '')
                    : context.l10n.roleTeacher)
                : ({
                      'parent': context.l10n.studentLinksRoleParent,
                      'institution': context.l10n.studentLinksRoleInstitution,
                    }[role] ??
                    role),
            style: WinType.labelM(s.onMuted),
          ),
        ])),
      ]),
    );
  }
}
