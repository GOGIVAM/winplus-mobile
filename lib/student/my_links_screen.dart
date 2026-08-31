import 'package:flutter/material.dart';
import '../services/linking_service.dart';
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
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await LinkingService.instance.getStudentLinks();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text('Mon réseau', style: WinType.headlineS(s.onStrong)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _data == null
          ? Center(child: Text('Erreur de chargement', style: WinType.bodyM(s.onMuted)))
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Section(title: 'Parents', items: (_data!['parents'] as List?) ?? [], role: 'parent', s: s),
              _Section(title: 'Professeurs', items: (_data!['teachers'] as List?) ?? [], role: 'teacher', s: s),
              if (_data!['institution'] != null) ...[
                Text('Établissement', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                _PersonCard(person: _data!['institution'] as Map<String, dynamic>, role: 'institution', s: s),
                const SizedBox(height: 20),
              ],
              if ((_data!['groups'] as List?)?.isNotEmpty == true) ...[
                Text('Groupes d\'étude', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                ...(_data!['groups'] as List).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WinCard(child: Text((g as Map)['name'] ?? '', style: WinType.bodyM(s.onStrong))),
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
  const _Section({required this.title, required this.items, required this.role, required this.s});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 8),
      ...items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _PersonCard(person: p as Map<String, dynamic>, role: role, s: s),
      )),
      const SizedBox(height: 20),
    ]);
  }
}

class _PersonCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final String role;
  final WinScheme s;
  const _PersonCard({required this.person, required this.role, required this.s});

  @override
  Widget build(BuildContext context) {
    final name = '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'.trim();
    return WinCard(
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: person['avatarUrl'] != null ? NetworkImage(person['avatarUrl'] as String) : null,
          backgroundColor: s.surface2,
          child: person['avatarUrl'] == null ? Icon(Icons.person, color: s.onFaint) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? 'Utilisateur' : name, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
          Text(
            role == 'teacher'
              ? (person['source'] == 'class' ? 'Professeur · ${person['className'] ?? ''}' : 'Professeur')
              : role,
            style: WinType.labelM(s.onMuted),
          ),
        ])),
      ]),
    );
  }
}
