import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class StudyGroup {
  final String id, name, subject;
  final int memberCount;
  final DateTime lastActivityAt;
  const StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.memberCount,
    required this.lastActivityAt,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});
  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  static final _mockGroups = [
    StudyGroup(
      id: 'g-001',
      name: 'BAC C Warriors',
      subject: 'Mathématiques',
      memberCount: 5,
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    StudyGroup(
      id: 'g-002',
      name: 'Chimie Élite',
      subject: 'Chimie',
      memberCount: 3,
      lastActivityAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StudyGroup(
      id: 'g-003',
      name: 'Physique Squad',
      subject: 'Physique',
      memberCount: 8,
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  final List<StudyGroup> _groups = List.from(_mockGroups);

  String _relTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes}min';
    if (d.inHours < 24) return 'il y a ${d.inHours}h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays}j';
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(
        onCreated: (group) => setState(() => _groups.insert(0, group)),
      ),
    );
  }

  void _showJoinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JoinGroupSheet(
        onResult: (msg, ok) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? null : Colors.red.shade700,
          ),
        ),
      ),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Classement ────────────────────────────────────────────
          WinSectionHeader('Classement de la semaine'),
          const SizedBox(height: 8),
          _Leaderboard(),
          const SizedBox(height: 20),

          // ── Mes groupes ───────────────────────────────────────────
          WinSectionHeader('Mes groupes'),
          ..._groups.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GroupCard(
                  group: g,
                  relTime: _relTime(g.lastActivityAt),
                  onTap: () => _showGroupDetail(context, g),
                ),
              )),
          const SizedBox(height: 16),

          // ── Badge plan ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: WinColors.gold.withValues(alpha: 0.15),
              border: Border.all(
                  color: WinColors.gold.withValues(alpha: 0.6), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.workspace_premium_outlined,
                  size: 18, color: WinColors.gold),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Plan Ultime  Groupes illimités',
                      style: WinType.labelM(WinColors.gold)
                          .copyWith(fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: 16),
          WinButton('+ Créer un groupe',
              block: true,
              variant: WinButtonVariant.outline,
              onTap: _showCreateSheet),
          const SizedBox(height: 10),
          WinButton('Rejoindre par code',
              block: true,
              variant: WinButtonVariant.ghost,
              onTap: _showJoinSheet),
        ],
      ),
    );
  }

  void _showGroupDetail(BuildContext context, StudyGroup g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GroupDetailSheet(group: g),
    );
  }
}

// ─── Group Card ──────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final StudyGroup group;
  final String relTime;
  final VoidCallback onTap;
  const _GroupCard(
      {required this.group, required this.relTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        Row(children: [
          WinChip(group.subject),
          const SizedBox(width: 10),
          Text('${group.memberCount} membres',
              style: WinType.labelM(s.onMuted)),
        ]),
        const SizedBox(height: 6),
        Text('Dernière activité : $relTime', style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 10),
        WinButton(
          'Voir →',
          small: true,
          variant: WinButtonVariant.outline,
          onTap: onTap,
        ),
      ]),
    );
  }
}

// ─── Create Sheet ─────────────────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  final void Function(StudyGroup) onCreated;
  const _CreateGroupSheet({required this.onCreated});
  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedSubject = 'Maths';
  static const _subjects = ['Maths', 'Chimie', 'Physique', 'Français'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le nom doit faire au moins 3 caractères.')),
      );
      return;
    }
    final group = StudyGroup(
      id: 'g-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      subject: _selectedSubject,
      memberCount: 1,
      lastActivityAt: DateTime.now(),
    );
    Navigator.pop(context);
    widget.onCreated(group);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: s.outline2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Créer un groupe',
                style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            WinTextField(
                icon: Icons.group,
                hint: 'Nom du groupe (min 3 chars)',
                controller: _nameCtrl),
            const SizedBox(height: 16),
            Text('Matière principale', style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _subjects
                  .map((sub) => WinChip(
                        sub,
                        active: _selectedSubject == sub,
                        onTap: () => setState(() => _selectedSubject = sub),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            WinButton('Créer', block: true, onTap: _submit),
          ]),
    );
  }
}

// ─── Leaderboard ─────────────────────────────────────────────────────────────

class _Leaderboard extends StatelessWidget {
  static final _entries = [
    (name: 'Kamga Ahmed', subject: 'math', hours: 24, score: 87, isMe: true),
    (name: 'Brenda Mbe', subject: 'chimie', hours: 21, score: 92, isMe: false),
    (name: 'Yann Talla', subject: 'pc', hours: 18, score: 79, isMe: false),
    (name: 'Aïcha Bello', subject: 'fr', hours: 16, score: 84, isMe: false),
    (name: 'Steve Nkeng', subject: 'math', hours: 14, score: 76, isMe: false),
  ];

  static const _medals = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: _entries.asMap().entries.map((e) {
          final rank = e.key;
          final entry = e.value;
          final subj = WinData.subjectById(entry.subject);
          final medal = rank < 3 ? _medals[rank] : null;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: entry.isMe ? s.primary.withValues(alpha: 0.06) : null,
              border: rank < _entries.length - 1
                  ? Border(bottom: BorderSide(color: s.outline, width: 0.8))
                  : null,
            ),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: medal != null
                    ? Icon(Icons.emoji_events, size: 20, color: medal)
                    : Text('${rank + 1}',
                        textAlign: TextAlign.center,
                        style: WinType.labelM(s.onFaint)),
              ),
              const SizedBox(width: 10),
              WinAvatar(entry.name,
                  size: 34, color: subj.color.withValues(alpha: 0.2)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(entry.name,
                        style: WinType.titleM(s.onStrong).copyWith(
                            fontWeight: entry.isMe
                                ? FontWeight.w700
                                : FontWeight.w500)),
                    Text('${entry.hours}h · ${entry.score}%',
                        style: WinType.labelS(s.onMuted)),
                  ])),
              if (entry.isMe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: s.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Moi',
                      style: WinType.labelS(s.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Group Detail Sheet ───────────────────────────────────────────────────────

class _GroupDetailSheet extends StatelessWidget {
  final StudyGroup group;
  const _GroupDetailSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final members = [
      (name: 'Kamga Ahmed', role: 'Admin', hours: 18),
      (name: 'Brenda Mbe', role: 'Membre', hours: 12),
      (name: 'Yann Talla', role: 'Membre', hours: 8),
    ];
    return Container(
      decoration: BoxDecoration(
          color: s.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: s.outline2,
                        borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Expanded(
                  child: Text(group.name,
                      style: WinType.archivo(size: 20, color: s.onStrong))),
              WinChip(group.subject),
            ]),
            const SizedBox(height: 4),
            Text('${group.memberCount} membres',
                style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 20),
            Text('Membres actifs', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 10),
            ...members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    WinAvatar(m.name, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(m.name, style: WinType.bodyM(s.onStrong)),
                          Text(m.role, style: WinType.labelS(s.onMuted)),
                        ])),
                    Text('${m.hours}h cette semaine',
                        style: WinType.labelM(s.primary)),
                  ]),
                )),
            const SizedBox(height: 16),
            WinButton('Envoyer un message au groupe',
                block: true,
                icon: Icons.chat_outlined,
                onTap: () => Navigator.pop(context)),
          ]),
    );
  }
}

// ─── Join Sheet ───────────────────────────────────────────────────────────────

class _JoinGroupSheet extends StatefulWidget {
  final void Function(String msg, bool ok) onResult;
  const _JoinGroupSheet({required this.onResult});
  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le code doit faire exactement 6 caractères.')),
      );
      return;
    }
    Navigator.pop(context);
    if (code == 'ABC123') {
      widget.onResult('Groupe rejoint avec succès !', true);
    } else {
      widget.onResult('Code invalide ou groupe introuvable.', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: s.outline2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Rejoindre par code',
                style: WinType.archivo(size: 20, color: s.onStrong)),
            const SizedBox(height: 20),
            WinTextField(
                icon: Icons.vpn_key,
                hint: 'Code à 6 caractères',
                controller: _codeCtrl),
            const SizedBox(height: 24),
            WinButton('Rejoindre', block: true, onTap: _submit),
          ]),
    );
  }
}
