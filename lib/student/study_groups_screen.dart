import 'package:flutter/material.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});
  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  String _tab = 'Mes groupes';
  final _codeCtrl = TextEditingController();

  static const _myGroups = [
    (name: 'BAC C - Révision Maths', members: 8, subject: 'Mathématiques', lastActivity: 'il y a 30 min'),
    (name: 'Pack ENSP 2026', members: 12, subject: 'Sciences', lastActivity: 'hier'),
  ];

  static const _suggested = [
    (name: 'Chimie Terminale D', members: 5, subject: 'Chimie', lastActivity: '2h'),
    (name: 'Prépa BAC A Français', members: 7, subject: 'Français', lastActivity: '3h'),
  ];

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Groupes d'étude", style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: ['Mes groupes', 'Rejoindre'].map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WinChip(t, active: _tab == t, onTap: () => setState(() => _tab = t)),
          )).toList()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _tab == 'Mes groupes' ? _buildMyGroups(s) : _buildJoin(s),
        ),
      ]),
    );
  }

  Widget _buildMyGroups(WinScheme s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ..._myGroups.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GroupCard(
            name: g.name,
            members: g.members,
            subject: g.subject,
            lastActivity: g.lastActivity,
            joined: true,
          ),
        )),
        const SizedBox(height: 8),
        WinButton(
          '+ Créer un groupe',
          variant: WinButtonVariant.outline,
          block: true,
          icon: Icons.add,
          onTap: _showCreateSheet,
        ),
      ],
    );
  }

  Widget _buildJoin(WinScheme s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        WinTextField(
          controller: _codeCtrl,
          icon: Icons.tag,
          hint: 'Code du groupe…',
        ),
        const SizedBox(height: 12),
        WinButton(
          'Rejoindre',
          block: true,
          icon: Icons.login_outlined,
          onTap: () {
            if (_codeCtrl.text.trim().isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Groupe rejoint !')),
            );
            _codeCtrl.clear();
          },
        ),
        const SizedBox(height: 24),
        Text('Groupes recommandés', style: WinType.archivo(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ..._suggested.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GroupCard(
            name: g.name,
            members: g.members,
            subject: g.subject,
            lastActivity: g.lastActivity,
            joined: false,
          ),
        )),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String name, subject, lastActivity;
  final int members;
  final bool joined;
  const _GroupCard({
    required this.name,
    required this.members,
    required this.subject,
    required this.lastActivity,
    required this.joined,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WinType.titleM(s.onStrong)),
          ),
          Text('$members membres', style: WinType.labelM(s.onMuted)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          WinChip(subject),
          const Spacer(),
          Text(lastActivity, style: WinType.labelM(s.onFaint)),
        ]),
        const SizedBox(height: 10),
        WinButton(
          joined ? 'Ouvrir' : 'Rejoindre',
          variant: joined ? WinButtonVariant.outline : WinButtonVariant.accent,
          small: true,
          icon: joined ? Icons.open_in_new_outlined : Icons.add,
        ),
      ]),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  String _subject = 'Mathématiques';
  static const _subjects = ['Mathématiques', 'Physique', 'Chimie', 'SVT', 'Français', 'Anglais'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(width: 40, height: 4, color: s.outline2,
              margin: const EdgeInsets.only(bottom: 24)),
        ),
        Text('Créer un groupe', style: WinType.archivo(size: 20, color: s.onStrong)),
        const SizedBox(height: 20),
        WinTextField(controller: _nameCtrl, label: 'Nom du groupe', hint: 'ex: BAC C Maths 2026'),
        const SizedBox(height: 16),
        Text('Matière', style: WinType.manrope(size: 13, weight: FontWeight.w500, color: s.onStrong)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.outline, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _subject,
              isExpanded: true,
              style: WinType.manrope(size: 15, color: s.onStrong),
              items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
              onChanged: (v) { if (v != null) setState(() => _subject = v); },
            ),
          ),
        ),
        const SizedBox(height: 24),
        WinButton(
          'Créer',
          block: true,
          icon: Icons.group_add_outlined,
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Groupe créé !')),
            );
          },
        ),
      ]),
    );
  }
}
