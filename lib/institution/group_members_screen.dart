import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class GroupMembersScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  const GroupMembersScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<ApiGroupMember>? _members;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await InstitutionService.instance.getGroupMembers(widget.groupId);
    if (mounted) setState(() => _members = m);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final members = _members;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.groupName, style: WinType.titleM(s.onStrong)),
          if (members != null)
            Text('${members.length} élève${members.length > 1 ? 's' : ''}',
                style: WinType.labelS(s.onMuted)),
        ]),
      ),
      body: members == null
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? Center(child: Text('Aucun élève dans ce groupe.', style: WinType.bodyM(s.onMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final scoreColor = m.averageScore >= 70
                        ? WinColors.success
                        : m.averageScore >= 50
                            ? WinColors.warn
                            : WinColors.error;
                    return WinCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        WinAvatar(m.fullName, size: 40),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.fullName, style: WinType.titleM(s.onStrong)),
                          if (m.email != null)
                            Text(m.email!, style: WinType.labelS(s.onFaint)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${m.averageScore.round()}%',
                              style: WinType.archivo(size: 16, weight: FontWeight.w700, color: scoreColor)),
                          Text('moy.', style: WinType.labelS(s.onFaint)),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }
}
