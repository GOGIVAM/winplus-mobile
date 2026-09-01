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
  List<dynamic> _pending = [];
  bool _loading = true;
  final Map<int, bool> _actioning = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        LinkingService.instance.getStudentLinks(),
        LinkingService.instance.getPendingInvitations(),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as Map<String, dynamic>;
          _pending = results[1] as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  Future<void> _accept(int linkId) async {
    setState(() => _actioning[linkId] = true);
    try {
      await LinkingService.instance.acceptInvitation(linkId);
      await _load();
    } catch (_) {
      if (mounted) { setState(() => _actioning.remove(linkId)); }
    }
  }

  Future<void> _reject(int linkId) async {
    setState(() => _actioning[linkId] = true);
    try {
      await LinkingService.instance.rejectInvitation(linkId);
      if (mounted) { setState(() { _pending.removeWhere((p) => p['id'] == linkId); _actioning.remove(linkId); }); }
    } catch (_) {
      if (mounted) { setState(() => _actioning.remove(linkId)); }
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
              if (_pending.isNotEmpty) ...[
                Row(children: [
                  Text('Invitations reçues', style: WinType.titleM(s.onStrong)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_pending.length}', style: WinType.labelM(s.onPrimary).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),
                ..._pending.map((inv) {
                  final id = inv['id'] as int;
                  final name = '${inv['firstName'] ?? ''} ${inv['lastName'] ?? ''}'.trim();
                  final actioning = _actioning[id] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WinCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: inv['avatarUrl'] != null ? NetworkImage(inv['avatarUrl'] as String) : null,
                          backgroundColor: s.surface2,
                          child: inv['avatarUrl'] == null ? Icon(Icons.person, color: s.onFaint, size: 18) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name.isEmpty ? 'Utilisateur' : name, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
                          Text('Professeur · invitation en attente', style: WinType.labelM(s.onMuted)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: FilledButton(
                          onPressed: actioning ? null : () => _accept(id),
                          style: FilledButton.styleFrom(backgroundColor: s.primary, foregroundColor: s.onPrimary, padding: const EdgeInsets.symmetric(vertical: 8)),
                          child: actioning ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Accepter'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(
                          onPressed: actioning ? null : () => _reject(id),
                          style: OutlinedButton.styleFrom(foregroundColor: s.onMuted, side: BorderSide(color: s.outline), padding: const EdgeInsets.symmetric(vertical: 8)),
                          child: const Text('Refuser'),
                        )),
                      ]),
                    ])),
                  );
                }),
                const SizedBox(height: 20),
              ],
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
